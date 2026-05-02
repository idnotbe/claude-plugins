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

Concrete examples for the current catalog:

```
/plugin install vibe-check@idnotbe
/plugin install claude-code-guardian@idnotbe
```

The first command registers this hub repo as a marketplace under the local name
`idnotbe`. The subsequent `install` commands resolve `<plugin>` against the hub
catalog and pull each plugin from its upstream repo. Restart your Claude Code
session if the new plugins do not appear immediately.

## Catalog

Sorted alphabetically by name. Descriptions match each upstream `plugin.json`'s
`description` field verbatim.

| Plugin | Description | Upstream |
|--------|-------------|----------|
| `claude-code-guardian` | Hook-based security guardrails for Claude Code's `--dangerously-skip-permissions` mode. Blocks destructive commands, protects secrets, and auto-commits safety checkpoints. | [idnotbe/claude-code-guardian](https://github.com/idnotbe/claude-code-guardian) |
| `deepscan` | Deep multi-file analysis plugin for complex tasks where standard context windows fail. Orchestrates parallel sub-agents for security, architecture, and performance analysis. | [idnotbe/deepscan](https://github.com/idnotbe/deepscan) |
| `vibe-check` | Metacognitive sanity checks for agent plans. Use before irreversible actions, when uncertainty is high, or when complexity is escalating. | [idnotbe/vibe-check](https://github.com/idnotbe/vibe-check) |

## Alternative: single-plugin install

Each upstream plugin repo also ships its own `marketplace.json`, so the
pre-existing single-plugin install path still works:

```
/plugin marketplace add idnotbe/vibe-check
/plugin install vibe-check@vibe-check
```

```
/plugin marketplace add idnotbe/claude-code-guardian
/plugin install claude-code-guardian@idnotbe-security
```

Note the trailing namespace differs: the upstream marketplaces use the names
`vibe-check` and `idnotbe-security` (NOT `idnotbe`), so they do not collide with
this hub. You can safely have both the hub and a per-plugin marketplace
registered at the same time -- the same plugin will appear under two distinct
`@<marketplace>` namespaces in your local catalog. The hub path is recommended
going forward; the per-plugin path is preserved for users who installed via that
path before the hub existed.

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
`plugin.json`, unique name, no `name: "idnotbe"` collision in the upstream
marketplace) and the per-addition workflow (insert at the alphabetically correct
position, update README + `docs/architecture/components.md`, run both
validators).

One execution of that plan = one plugin added.

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

Validation has two layers (per ADR-006 in
[`docs/architecture/decisions.md`](docs/architecture/decisions.md)):

1. **Built-in baseline** -- Claude Code's `claude plugin validate .` (also
   exposed as the `/plugin validate .` slash command). Validates JSON
   well-formedness and schema conformance against the marketplace schema. This
   is the floor that any change to `marketplace.json` must clear before merging.
2. **Hub-specific layer** -- `tests/validate_marketplace.sh` (Phase 4 of
   [`action-plans/0001-bootstrap-hub-repo.md`](action-plans/0001-bootstrap-hub-repo.md)).
   Layers on policy checks the built-in cannot enforce because they are stricter
   than the schema: literal `name == "idnotbe"`, every source URL matches
   `^https://github\.com/idnotbe/[^/]+\.git$`, no plugin entry inlines
   executable component fields (`commands`, `hooks`, `mcpServers`, `lspServers`,
   `agents`, `skills`, `setup`, `strict`), `$schema` is the documented URL,
   alphabetical ordering of `plugins[]` by `name`.

Both must exit 0 before any change to the manifest is committed.

## Repo structure

```
claude-plugins/
  .claude-plugin/
    marketplace.json         # The single behavior-bearing artifact
  docs/
    requirements/            # REQ-* requirements (mission, contract, hygiene)
    architecture/            # Architecture overview, components, ADRs
  action-plans/              # Execution plans (lifecycle: not-started/active/done)
    _done/                   # Completed plans
    _ref/                    # Reference / historical documents
  tests/                     # validate_marketplace.sh + manual scenarios (Phase 4)
  README.md                  # This file
  ARCHITECTURE.md            # Top-level architecture narrative
  CLAUDE.md                  # Claude Code project instructions
  LICENSE                    # MIT License
  .gitignore                 # Git ignore rules
```

## License

MIT License -- see [LICENSE](LICENSE).

## Author

Maintained by [idnotbe](https://github.com/idnotbe). Issues and contributions
welcome via the GitHub repo at
[idnotbe/claude-plugins](https://github.com/idnotbe/claude-plugins).
