"""Regression checks for catalog policy and evidence validation."""
import copy
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest

spec = importlib.util.spec_from_file_location('catalog', Path(__file__).resolve().parents[1] / 'tools/check_catalog.py')
catalog = importlib.util.module_from_spec(spec)
spec.loader.exec_module(catalog)


def fixture(host):
    plugins = [{'name': n, 'description': 'Test skill.', 'source': {'source': 'url', 'url': f'https://github.com/idnotbe/{n}.git'}} for n in catalog.NAMES]
    data = {'name': 'idnotbe', 'owner': {'name': 'idnotbe'}, 'description': 'Test catalog.', 'plugins': plugins}
    if host == 'codex':
        data.update(name='idnotbe-chatgpt-plugins', interface={'displayName': 'Test Catalog'})
        for plugin in plugins:
            plugin['policy'] = {'installation': 'AVAILABLE', 'authentication': 'ON_INSTALL'}
    return data


class CatalogTests(unittest.TestCase):
    def test_both_host_contracts(self):
        for host in ('claude', 'codex'):
            self.assertEqual(set(catalog.validate(fixture(host), host)), set(catalog.NAMES))

    def test_mutations_are_rejected(self):
        base = fixture('claude')
        mutations = [
            lambda x: x.update(name='wrong'),
            lambda x: x['plugins'].pop(),
            lambda x: x['plugins'].reverse(),
            lambda x: x['plugins'].append(copy.deepcopy(x['plugins'][-1])),
            lambda x: x['plugins'][0].update(source='./other'),
            lambda x: x['plugins'][0]['source'].update(sha='0' * 40),
            lambda x: x['plugins'][0]['source'].update(url='https://github.com/other/deep-inquiry.git'),
            lambda x: x['plugins'][0].update(skills='./unreviewed'),
            lambda x: x['plugins'][0].update(description=''),
        ]
        for mutation in mutations:
            data = copy.deepcopy(base)
            mutation(data)
            with self.subTest(data=data), self.assertRaises(ValueError):
                catalog.validate(data, 'claude')

    def test_legacy_claude_entries_are_allowed(self):
        data = fixture('claude')
        data['plugins'].append({'name': 'other-plugin', 'description': 'Existing plugin.', 'source': {'source': 'url', 'url': 'https://github.com/idnotbe/other-plugin.git'}})
        data['plugins'].sort(key=lambda p: p['name'])
        self.assertEqual(set(catalog.validate(data, 'claude')), set(catalog.NAMES))

    def test_wrong_codex_policy_rejected(self):
        data = fixture('codex')
        data['plugins'][0]['policy']['installation'] = 'NOT_AVAILABLE'
        with self.assertRaises(ValueError):
            catalog.validate(data, 'codex')

    def test_discovery_uses_returned_path(self):
        response = {'marketplaces': [{'name': 'target', 'path': '/actual path', 'plugins': []}]}
        self.assertEqual(catalog.market_paths(response, 'target'), ['/actual path'])
        self.assertEqual(catalog.market_paths(response, 'unknown'), [])

    def test_tracked_content_identity_validation(self):
        values = ['a' * 40, 'b' * 40, 'c' * 40]
        expected = dict(zip(catalog.SHARED, values))
        self.assertEqual(catalog.tracked_blobs('\n'.join(values)), expected)
        self.assertEqual(catalog.tracked_blobs('\r\n'.join(values)), expected)
        for invalid in ('', 'a' * 40, '\n'.join(values + ['d' * 40]), 'bad\nbad\nbad'):
            with self.subTest(invalid=invalid), self.assertRaises(ValueError):
                catalog.tracked_blobs(invalid)

    def test_codex_plugin_skill_namespace_and_state(self):
        detail = {'summary': {'installed': True, 'enabled': True}, 'apps': [],
                  'mcpServers': [], 'hooks': [],
                  'skills': [{'name': 'deep-inquiry:deep-inquiry', 'enabled': True, 'path': '/plugin/SKILL.md'}]}
        self.assertEqual(catalog.loaded_skill(detail, 'deep-inquiry')['path'], '/plugin/SKILL.md')
        for name in ('deep-inquiry', 'other:deep-inquiry', 'deep-inquiry:other'):
            changed = copy.deepcopy(detail)
            changed['skills'][0]['name'] = name
            with self.subTest(name=name), self.assertRaises(ValueError):
                catalog.loaded_skill(changed, 'deep-inquiry')
        for mutate in (lambda x: x['skills'].append(copy.deepcopy(x['skills'][0])),
                       lambda x: x['skills'][0].update(enabled=False),
                       lambda x: x['summary'].update(installed=False),
                       lambda x: x['hooks'].append('unexpected')):
            changed = copy.deepcopy(detail)
            mutate(changed)
            with self.assertRaises(ValueError):
                catalog.loaded_skill(changed, 'deep-inquiry')

    def test_missing_and_modified_bundle_detected(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            with self.assertRaises(ValueError):
                catalog.inventory(root)
            (root / 'SKILL.md').write_text('Original', encoding='utf-8')
            before = catalog.inventory(root)
            (root / 'SKILL.md').write_text('Changed', encoding='utf-8')
            self.assertNotEqual(before, catalog.inventory(root))


if __name__ == '__main__':
    unittest.main()
