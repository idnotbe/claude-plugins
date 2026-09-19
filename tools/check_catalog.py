"""Catalog policy checks and explicit, isolated real-host installation evaluation.

Python 3.10+, standard library. No model request, credential, hook or MCP execution.
Codex preview API calls are development-only tests, not a production client API.
"""
from __future__ import annotations
import argparse
from contextlib import contextmanager
import hashlib
import json
import os
from pathlib import Path
import queue
import re
import shutil
import subprocess
import sys
import tempfile
import threading
import time

NAMES = ('deep-inquiry', 'skill-quality-builder', 'vibe-check')
PATHS = {'claude': '.claude-plugin/marketplace.json', 'codex': '.agents/plugins/marketplace.json'}
SHARED = ('tools/distribution.py', 'tests/test_distribution.py', '.github/workflows/distribution.yml')
FORBIDDEN = {'commands', 'hooks', 'mcpServers', 'lspServers', 'agents', 'skills', 'setup', 'strict'}


def require(condition, message):
    if not condition:
        raise ValueError(message)


def validate(data, host):
    expected = 'idnotbe' if host == 'claude' else 'idnotbe-chatgpt-plugins'
    require(isinstance(data, dict) and data.get('name') == expected, 'Wrong marketplace identity')
    entries = data.get('plugins')
    require(isinstance(entries, list) and bool(entries), 'Missing plugins array')
    names = [entry.get('name') for entry in entries if isinstance(entry, dict)]
    require(len(names) == len(entries) and all(isinstance(n, str) for n in names), 'Invalid plugin names')
    require(names == sorted(names, key=str.casefold) and len(set(names)) == len(names), 'Unsorted/duplicate names')
    require(set(NAMES) <= set(names), 'Missing standardized skill plugin')
    for entry in entries:
        require(not FORBIDDEN.intersection(entry), 'Catalog must not inline executable components')
        name, source = entry['name'], entry.get('source')
        require(isinstance(source, dict) and set(source) == {'source', 'url'}, 'Expected bare URL source')
        require(source['source'] == 'url' and isinstance(source['url'], str)
                and bool(re.fullmatch(r'https://github\.com/idnotbe/[a-zA-Z0-9_.-]+\.git', source['url'])),
                'Invalid upstream URL')
        if name in NAMES:
            require(source['url'] == f'https://github.com/idnotbe/{name}.git', 'Wrong skill upstream')
        if host == 'claude':
            require(isinstance(entry.get('description'), str) and bool(entry['description'].strip()), 'Missing description')
        else:
            require(entry.get('policy') == {'installation': 'AVAILABLE', 'authentication': 'ON_INSTALL'}, 'Wrong install policy')
    if host == 'claude':
        require(data.get('owner', {}).get('name') == 'idnotbe', 'Wrong catalog owner')
        require(bool(data.get('description')), 'Missing catalog description')
    else:
        require(set(names) == set(NAMES), 'Unexpected OpenAI plugin')
        require(bool(data.get('interface', {}).get('displayName')), 'Missing catalog display name')
    return {entry['name']: entry for entry in entries if entry['name'] in NAMES}


def inventory(root):
    require(root.is_dir() and not root.is_symlink(), f'Missing or linked bundle: {root}')
    result = {}
    for path in sorted(root.rglob('*')):
        require(not path.is_symlink(), f'Unexpected symlink: {path}')
        if path.is_file():
            result[path.relative_to(root).as_posix()] = hashlib.sha256(path.read_bytes()).hexdigest()
    require('SKILL.md' in result, 'Missing installed entrypoint')
    return result


def market_paths(value, name):
    """Find the named marketplace in the actual host response, never guess a path."""
    found = []
    if isinstance(value, dict):
        if value.get('name') == name and isinstance(value.get('path'), str):
            found.append(value['path'])
        for child in value.values():
            found.extend(market_paths(child, name))
    elif isinstance(value, list):
        for child in value:
            found.extend(market_paths(child, name))
    return found


def tracked_blobs(output):
    """Compare repository content, independent of Windows checkout EOL conversion."""
    values = output.splitlines()
    require(len(values) == len(SHARED) and all(re.fullmatch(r'[0-9a-f]{40}', v) for v in values),
            'Invalid tracked distribution blob identities')
    return dict(zip(SHARED, values))


def loaded_skill(detail, name):
    """Plugin skills are namespace-qualified by the native Codex loader."""
    require(detail['summary']['installed'] and detail['summary']['enabled'], 'Codex plugin not installed/enabled')
    require(not detail['apps'] and not detail['mcpServers'] and not detail['hooks'], 'Unexpected executable plugin components')
    skills = detail['skills']
    require(len(skills) == 1 and skills[0]['name'] == f'{name}:{name}',
            f'Unexpected Codex skill names: {[s.get("name") for s in skills]}')
    require(skills[0]['enabled'] and isinstance(skills[0].get('path'), str), 'Codex skill disabled or missing path')
    return skills[0]


@contextmanager
def app_server(executable, env, cwd):
    process = subprocess.Popen([executable, '--enable', 'plugins', 'app-server'],
                               cwd=cwd, env=env, stdin=subprocess.PIPE,
                               stdout=subprocess.PIPE, stderr=subprocess.DEVNULL,
                               text=True, encoding='utf-8', bufsize=1)
    messages = queue.Queue()
    def receive():
        try:
            for line in process.stdout:
                messages.put(json.loads(line))
        except (ValueError, OSError) as exc:
            messages.put(exc)
        finally:
            messages.put(None)
    reader = threading.Thread(target=receive, daemon=True)
    reader.start()
    sequence = 0
    def call(method, params):
        nonlocal sequence
        sequence += 1
        process.stdin.write(json.dumps({'id': sequence, 'method': method, 'params': params}) + '\n')
        process.stdin.flush()
        deadline = time.monotonic() + 180
        while True:
            try:
                item = messages.get(timeout=max(0.01, deadline - time.monotonic()))
            except queue.Empty as exc:
                raise TimeoutError(f'Codex {method} timed out') from exc
            require(item is not None, f'Codex exited during {method}')
            if isinstance(item, Exception):
                raise item
            if item.get('id') == sequence:
                require('error' not in item, f'Codex {method}: {item.get("error")}')
                return item['result']
            require('id' not in item, 'Unexpected Codex server request/response')
            require(time.monotonic() < deadline, f'Codex {method} notification timeout')
    try:
        call('initialize', {'clientInfo': {'name': 'catalog_evaluation', 'title': 'Catalog Evaluation', 'version': '1.0.0'},
                            'capabilities': {'experimentalApi': True}})
        process.stdin.write(json.dumps({'method': 'initialized', 'params': {}}) + '\n')
        process.stdin.flush()
        yield call
    finally:
        process.stdin.close()
        try:
            process.wait(timeout=15)
        except subprocess.TimeoutExpired:
            process.terminate()
            try:
                process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                process.kill()
                process.wait(timeout=5)
        reader.join(timeout=5)
        process.stdout.close()


def smoke(root, host, data, entries, report):
    commands = ('git', 'npx', 'claude' if host == 'claude' else 'codex')
    executables = {c: ((shutil.which(c + '.cmd') if os.name == 'nt' else None) or shutil.which(c)) for c in commands}
    require(all(executables.values()), 'Install Git, Node/npm and the selected official host CLI')
    with tempfile.TemporaryDirectory(prefix='catalog evaluation ') as temporary:
        scratch = Path(temporary)
        home, project = scratch / 'home', scratch / 'project with spaces'
        for path in (home / '.claude', home / '.codex', project):
            path.mkdir(parents=True)
        env = dict(os.environ, HOME=str(home), USERPROFILE=str(home),
                   CLAUDE_CONFIG_DIR=str(home / '.claude'), CODEX_HOME=str(home / '.codex'),
                   XDG_CONFIG_HOME=str(home / '.config'), DISABLE_TELEMETRY='1', DO_NOT_TRACK='1', CI='1')
        for key in ('OPENAI_API_KEY', 'ANTHROPIC_API_KEY', 'CLAUDE_CODE_OAUTH_TOKEN', 'GH_TOKEN', 'GITHUB_TOKEN'):
            env.pop(key, None)
        def run(command, *args):
            result = subprocess.run([executables[command], *args], cwd=project, env=env,
                                    text=True, encoding='utf-8', errors='replace',
                                    stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=240)
            print(result.stdout, flush=True)
            require(result.returncode == 0, f'{command} {args}: exit {result.returncode}')
            return result.stdout.strip()
        cli = 'claude' if host == 'claude' else 'codex'
        report['versions'] = {'skills': run('npx', '--yes', 'skills@latest', '--version'), cli: run(cli, '--version')}
        snapshots, shared = {}, {}
        for name in NAMES:
            source = scratch / name
            run('git', 'clone', '--depth', '1', entries[name]['source']['url'], str(source))
            sha = run('git', '-C', str(source), 'rev-parse', 'HEAD')
            require(bool(re.fullmatch(r'[0-9a-f]{40}', sha)), 'Invalid checked source SHA')
            manifests = [json.loads((source / p / 'plugin.json').read_text(encoding='utf-8'))
                         for p in ('.claude-plugin', '.codex-plugin')]
            require(manifests[0] == manifests[1] and manifests[0]['name'] == name
                    and manifests[0]['skills'] == './.agents/skills/', 'Source manifest mismatch')
            expected = inventory(source / '.agents/skills' / name)
            snapshots[name] = expected
            report['sources'][name] = {'sha': sha, 'version': manifests[0]['version'], 'inventory': expected}
            shared[name] = tracked_blobs(run('git', '-C', str(source), 'rev-parse',
                                             *[f'HEAD:{p}' for p in SHARED]))
            report['sources'][name]['distribution_git_blobs'] = shared[name]
            run('npx', '--yes', 'skills@latest', 'add', f'idnotbe/{name}', '--skill', name,
                '--agent', 'codex', 'claude-code', '--copy', '--yes')
            for folder in ('.agents', '.claude'):
                require(inventory(project / folder / 'skills' / name) == expected, f'Remote skills install drift: {name}/{folder}')
            report['checks'].append(f'{name}:remote-skills-both-hosts')
        require(all(value == shared[NAMES[0]] for value in shared.values()), 'Distribution tooling differs across skill repos')
        report['checks'].append('cross-repository-distribution-standard')
        # Plugin tests use a clean project, so standalone copies cannot mask loading failures.
        plugin_project = scratch / 'plugin-only project'
        plugin_project.mkdir()
        if host == 'claude':
            run('claude', 'plugin', 'validate', str(root), '--strict')
            run('claude', 'plugin', 'marketplace', 'add', str(root))
            for name in NAMES:
                run('claude', 'plugin', 'install', f'{name}@{data["name"]}')
                registry = json.loads((home / '.claude/plugins/installed_plugins.json').read_text(encoding='utf-8'))
                records = registry['plugins'][f'{name}@{data["name"]}']
                require(bool(records), 'Missing Claude install record')
                installed = Path(records[0]['installPath'])
                require(inventory(installed / '.agents/skills' / name) == snapshots[name], f'Claude plugin drift: {name}')
                report['checks'].append(f'{name}:claude-remote-plugin-install')
        else:
            run('codex', 'plugin', 'marketplace', 'add', str(root))
            require(data['name'] in run('codex', 'plugin', 'marketplace', 'list'), 'Codex catalog not registered')
            with app_server(executables['codex'], env, plugin_project) as call:
                listing = call('plugin/list', {'cwds': [str(plugin_project)], 'marketplaceKinds': ['local']})
                paths = market_paths(listing, data['name'])
                require(len(paths) == 1, f'Expected one registered Codex marketplace, found {paths}; response={listing}')
                for name in NAMES:
                    params = {'marketplacePath': paths[0], 'pluginName': name}
                    call('plugin/read', params)
                    result = call('plugin/install', params)
                    require(result['appsNeedingAuth'] == [], 'Skills-only plugin unexpectedly requires app authentication')
                    detail = call('plugin/read', params)['plugin']
                    skill = loaded_skill(detail, name)
                    skill_path = Path(skill['path'])
                    require(inventory(skill_path.parent) == snapshots[name], f'Codex plugin bundle drift: {name}')
                    report['checks'].append(f'{name}:codex-preview-read-install-integrity')
            report['codex_api_status'] = 'development_only_not_a_production_client'


def main():
    for stream in (sys.stdout, sys.stderr):
        if hasattr(stream, 'reconfigure'):
            stream.reconfigure(encoding='utf-8')
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--root', type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument('--smoke', action='store_true')
    parser.add_argument('--report', type=Path)
    args = parser.parse_args()
    report = {'scope': 'catalog_installation_not_model_effectiveness', 'sources': {}, 'checks': [],
              'platform': sys.platform, 'catalog_revision': os.environ.get('GITHUB_SHA'),
              'gui_installation': 'not_run', 'chatgpt_web_workspace_import': 'not_run', 'model_behavior': 'not_run'}
    try:
        root = args.root.resolve()
        hosts = [h for h, p in PATHS.items() if (root / p).is_file()]
        require(len(hosts) == 1, 'Expected one host catalog per repository')
        host = hosts[0]
        require(not any((root / p).exists() for p in ('plugin.json', '.claude-plugin/plugin.json', '.codex-plugin/plugin.json')), 'Hub must not be a plugin')
        data = json.loads((root / PATHS[host]).read_text(encoding='utf-8'))
        entries = validate(data, host)
        report.update(host=host, catalog=data['name'])
        report['checks'].append('catalog-policy')
        if args.smoke:
            smoke(root, host, data, entries, report)
        report['status'] = 'pass'
    except (ValueError, OSError, KeyError, TypeError, subprocess.SubprocessError) as exc:
        report.update(status='fail', error=str(exc))
    text = json.dumps(report, indent=2)
    print(text)
    if args.report:
        args.report.parent.mkdir(parents=True, exist_ok=True)
        args.report.write_text(text + '\n', encoding='utf-8')
    return 0 if report['status'] == 'pass' else 1


if __name__ == '__main__':
    raise SystemExit(main())
