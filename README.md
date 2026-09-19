# claude-plugins

idnotbe's Claude Code plugin marketplace.

> **Marketplace name**: `idnotbe` | **License**: MIT | **Author**: [idnotbe](https://github.com/idnotbe)

## What this is

`idnotbe/claude-plugins` is a **Claude Code plugin marketplace hub** that lists
every plugin published under the `idnotbe` brand. Add the hub once and the whole
catalog becomes installable from inside Claude Code via the `@idnotbe`
namespace -- you do not have to remember (or maintain) per-plugin install URLs.

This repository is **not itself a plugin**. There is no
`.claude-plugin/plugin.json` at the repo root, no skills, no hooks, no commands,
no runtime code. The single
behavior-bearing artifact is `.claude-plugin/marketplace.json`. Claude Code's
plugin loader reads that manifest, resolves each entry's `source.url` to its
upstream repo, and clones the upstream repo to perform the actual install.

## Install (recommended path)

Run these commands inside Claude Code:

```
/plugin marketplace add idnotbe/claude-plugins
/plugin install <plugin>@idnotbe
```

For the three standardized skill plugins, the equivalent terminal commands are:

```sh
claude plugin marketplace add idnotbe/claude-plugins
claude plugin install deep-inquiry@idnotbe
claude plugin install skill-quality-builder@idnotbe
claude plugin install vibe-check@idnotbe
```

Invoke plugin skills as `/deep-inquiry:deep-inquiry`,
`/skill-quality-builder:skill-quality-builder`, or `/vibe-check:vibe-check`.
The commands work with compatible Claude Code installations on Windows and
Linux. A local CLI install does not install into a remote Claude account or
workspace; use that surface's available administrator/plugin controls.

The first command registers this hub repo as a marketplace under the local name
`idnotbe`. The subsequent `install` commands resolve `<plugin>` against the hub
catalog and pull each plugin from its upstream repo. Restart your Claude Code
session if the new plugins do not appear immediately.

## Migration notes

If you previously installed `vibe-check` or `claude-code-guardian` via the legacy
per-plugin marketplace path (`/plugin marketplace add idnotbe/vibe-check` or
`/plugin marketplace add idnotbe/claude-code-guardian`), the upstream
`.claude-plugin/marketplace.json` files have been removed in favor of the hub.
Use the command sequence below to switch your local registration to the hub
install path. The two upstreams previously registered under different
marketplace `name` aliases (`vibe-check` and `idnotbe-security`); the
`/plugin marketplace remove` command takes the alias, not the `owner/repo`
form.

```
# Existing standalone install via claude-code-guardian:
/plugin marketplace remove idnotbe-security
/plugin marketplace add idnotbe/claude-plugins
/plugin install claude-code-guardian@idnotbe
```

```
# Existing standalone install via vibe-check:
/plugin marketplace remove vibe-check
/plugin marketplace add idnotbe/claude-plugins
/plugin install vibe-check@idnotbe
```

## Catalog

Sorted alphabetically by name. Descriptions match the registered upstream plugin descriptions.

| Plugin | Description | Upstream |
|--------|-------------|----------|
| `claude-code-guardian` | Hook-based security guardrails for Claude Code's `--dangerously-skip-permissions` mode. Blocks destructive commands, protects secrets, and auto-commits safety checkpoints. | [idnotbe/claude-code-guardian](https://github.com/idnotbe/claude-code-guardian) |
| `deep-inquiry` | Investigate problems beyond familiar answers while preserving the user objective. | [idnotbe/deep-inquiry](https://github.com/idnotbe/deep-inquiry) |
| `deepscan` | Deep multi-file analysis plugin for complex tasks where standard context windows fail. Orchestrates parallel sub-agents for security, architecture, and performance analysis. | [idnotbe/deepscan](https://github.com/idnotbe/deepscan) |
| `humanizer` | This skill transforms English text to sound naturally human and less stereotypically AI-written | [idnotbe/humanizer](https://github.com/idnotbe/humanizer) |
| `prd-creator` | Creates Product Requirements Documents (PRD) through interactive conversation. Guides users through Epic/Feature/Story structure with progressive disclosure. | [idnotbe/prd-creator](https://github.com/idnotbe/prd-creator) |
| `skill-quality-builder` | Create, improve, and audit reusable Agent Skills with explicit validation and evaluation. | [idnotbe/skill-quality-builder](https://github.com/idnotbe/skill-quality-builder) |
| `vibe-check` | Assess whether the next action should proceed, be adjusted, or stop. | [idnotbe/vibe-check](https://github.com/idnotbe/vibe-check) |

## Standalone skills and OpenAI plugins

The three standardized skill repositories each retain one canonical bundle at
`.agents/skills/<name>/`. Both host manifests reference it without copying or
symlinking the skill. Their standalone installation also supports both hosts:

```sh
npx skills@latest add idnotbe/deep-inquiry --skill deep-inquiry --agent codex claude-code --copy
npx skills@latest add idnotbe/skill-quality-builder --skill skill-quality-builder --agent codex claude-code --copy
npx skills@latest add idnotbe/vibe-check --skill vibe-check --agent codex claude-code --copy
```

Use Node.js LTS (CI uses 24), npm and Git. Add `--global` for user scope or select
only one agent. Windows PowerShell can use `npx.cmd` when `npx.ps1` is blocked;
do not weaken execution policy. Prefer one installation mode per host/scope to
avoid duplicates. Each source repository's INSTALL.md explains prerequisites,
manual import, updates and rollback.

For ChatGPT/Codex plugins, use the separate
[OpenAI catalog](https://github.com/idnotbe/chatgpt-plugins). It has a distinct
marketplace name and does not collide with this hub. Both catalogs preserve the
bare-URL/default-branch policy: they are not reproducible commit pins. Record the
actual source revision and installation evidence; review source changes before
merging releases and bump both source manifest versions together.

## What this repo IS / IS NOT

**IS**:

- A Claude Code marketplace manifest (`.claude-plugin/marketplace.json`).
- A registry record cataloging every `idnotbe`-owned plugin.
- A documentation surface (this README + `docs/` + `ARCHITECTURE.md`) explaining
  the catalog and the policies that protect it.

**IS NOT**:

- A plugin. No `plugin.json` at the repo root.
- A host for plugin source code. Each plugin lives in its own upstream repo.
- A proxy or mirror. Claude Code clones each upstream directly when installing.

## Adding a plugin to the catalog

The full per-plugin onboarding workflow lives in
[`action-plans/0002-onboard-additional-plugins.md`](action-plans/0002-onboard-additional-plugins.md).
That plan covers the inclusion criteria (idnotbe-owned upstream, working
`plugin.json`, unique name) and the per-addition workflow (insert at the
alphabetically correct position, update README + `docs/architecture/components.md`,
run both validators). Plan 0007 additionally records the cross-host skill rollout.

## Plugin lifecycle / deprecation

Plugin entries are not silently removed. To deprecate a plugin
(REQ-PLUGIN-ENTRY-006 in [`docs/requirements/functional.md`](docs/requirements/functional.md)):

1. Prefix the entry's `description` with the literal token `[DEPRECATED]`.
2. Keep the entry in the manifest for at least one subsequent hub revision so
   that re-syncing users see the deprecation signal at least once.
3. Only after that grace period may the entry be removed.

Renames follow the same flow: add a deprecation entry under the old name
pointing at the new name, in addition to adding the new-name entry.

## Validation

The existing two layers remain required: `claude plugin validate .` for the
first-party schema and `bash tests/validate_marketplace.sh` for hub policy
(ADR-006). The latter still enforces the exact identity, bare idnotbe URLs,
unique/alphabetically ordered entries and absence of inline executable fields.
No existing policy check is removed or weakened.

New cross-platform tests complement these checks:

```sh
python -B -m unittest discover -s tests -p test_catalog.py -v
python -B tools/check_catalog.py
python -B tools/check_catalog.py --smoke --report temp/catalog-report.json
```

Python 3.10+ is required for maintenance checks, not catalog runtime. The explicit
`--smoke` mode needs Git, Node/npm, current Claude Code and network access. Native
Windows/Linux CI installs all three skills directly from GitHub for both agent
directories, compares every file against a recorded source checkout, confirms
that the three repos use identical distribution tooling, validates this hub with
Claude's strict validator and installs its three external Git plugins. The
existing shell policy validator also runs on Linux. Other catalog plugins are
preserved, not installed or modified by this evaluation.

Inspect the actual exact-commit CI results and JSON artifact. Configuration is
not a passing test. GUI/workspace import, natural triggering and model behavior
remain `not_run`; installation success is not evidence of improved model quality.
The OpenAI sibling uses the same checker for development-only Codex native
plugin read/install verification, not as a production client API recipe.

## Repo structure

```
claude-plugins/
  .claude-plugin/marketplace.json  # The single behavior-bearing artifact
  .github/workflows/catalog.yml   # Native Windows/Linux installation checks
  tools/check_catalog.py          # Explicit maintenance-only checks
  tests/                         # Existing shell policy and new Python regressions
  docs/requirements/             # Stable REQ-* requirements
  docs/architecture/             # Architecture overview, components, ADRs
  action-plans/                  # Execution plans and completed-plan archive
  README.md
  ARCHITECTURE.md
  CLAUDE.md
  LICENSE
```

## License

MIT License -- see [LICENSE](LICENSE). Upstream plugins retain their own licenses;
the catalog license does not relicense their content.

## Author

Maintained by [idnotbe](https://github.com/idnotbe). Issues and contributions
welcome via the GitHub repo at
[idnotbe/claude-plugins](https://github.com/idnotbe/claude-plugins).
