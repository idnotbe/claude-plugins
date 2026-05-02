# claude-plugins -- Requirements Overview

## Mission

`idnotbe/claude-plugins` is a **Claude Code plugin marketplace hub** owned by GitHub user `idnotbe`. It is a single static manifest repository whose only behavior-bearing artifact is `.claude-plugin/marketplace.json`, listing every plugin published under the `idnotbe` brand. (Supporting files exist -- a structural validator, README, and these design docs -- but they describe or protect the manifest; they do not run inside Claude Code.) Its job is to be the canonical entry point: a user runs `/plugin marketplace add idnotbe/claude-plugins` once, then `/plugin install <name>@idnotbe` for any plugin in the catalog without having to remember per-plugin install URLs.

This repository is **not itself a plugin**. It contains no `.claude-plugin/plugin.json` at the repo root, no skills, no hooks, no commands, and no runtime code. It is a registry record consumed by Claude Code's plugin loader.

## Operating Model (informative)

The hub is hub-and-spoke. The hub repository (`idnotbe/claude-plugins`) holds the marketplace manifest. Each plugin lives in its own upstream repository (e.g. `idnotbe/vibe-check`, `idnotbe/claude-code-guardian`). The marketplace.json `plugins[*].source` field uses the bare `url` form to point at each upstream repo's default branch, so when a user installs a plugin via the hub, Claude Code resolves the URL, clones the upstream repo, and loads its `.claude-plugin/plugin.json` from there.

## Stakeholders

- **End users of `idnotbe` plugins**: install once, get the whole catalog.
- **The plugin author (`idnotbe`)**: maintains the catalog by adding entries to one manifest file rather than communicating per-plugin install instructions.
- **Each upstream plugin repository**: continues to own its own `plugin.json`. The hub does not modify or replace those files.

## Scope

### In Scope

- A single marketplace manifest at `.claude-plugin/marketplace.json` listing all `idnotbe`-owned plugins.
- An `owner.name = "idnotbe"` and a marketplace `name = "idnotbe"` so that users invoke installs as `<plugin>@idnotbe`.
- Initial catalog entries for `vibe-check` and `claude-code-guardian`, each pointing at its upstream repo via the `url` source form.
- Validation in two layers: (1) Claude Code's built-in `claude plugin validate .` (also `/plugin validate .`) is the baseline schema/structure check; (2) a planned hub-specific shell validator (`tests/validate_marketplace.sh`) layers on policy checks the built-in does not perform (e.g. marketplace `name == "idnotbe"` literal, every plugin source URL points at `github.com/idnotbe/*.git`, no inline `commands`/`hooks`/`mcpServers` in plugin entries).
- README documenting the install flow and listing the catalog.

### Out of Scope

- A `.claude-plugin/plugin.json` at the repository root. This repo is not itself a plugin. (Subdirectory `plugin.json` files inside future fixtures or examples are not forbidden -- only the repo-root location is.)
- Any plugin source code, skills, hooks, commands, agents, or assets. The hub holds metadata only.
- Hosting or proxying the upstream plugin repositories. Each plugin remains independently installable from its own repo.
- Sha-pinning plugin sources in v1. The manifest tracks each upstream's default branch by using the bare `url` form. Sha-pinning is a known future option (see `architecture/decisions.md` ADR-002).
- A CI/CD pipeline at hub launch. Validator runs locally; CI is a documented follow-up.

## Success Criteria

1. A user can run `/plugin marketplace add idnotbe/claude-plugins` and see all listed plugins in their `/plugin install` catalog under the `@idnotbe` namespace.
2. Adding a new plugin to the catalog is a single edit (one new entry in the `plugins` array) plus a commit.
3. The hub uniquely owns the `"idnotbe"` marketplace name: no other `idnotbe`-owned source publishes under that name (REQ-COLLISION-001 in `functional.md`).
4. Both the built-in `claude plugin validate .` and the hub-specific `tests/validate_marketplace.sh` pass on every change to `marketplace.json`.

## Document Map

- `overview.md` (this file) -- mission, scope, stakeholders, success criteria.
- `functional.md` -- detailed requirements with `REQ-*-NNN` IDs grouped by category.
- `../architecture/overview.md` -- the hub-and-spoke model and how Claude Code's loader consumes the manifest.
- `../architecture/components.md` -- per-component description (manifest, plugin entries, source resolution, dual install paths).
- `../architecture/decisions.md` -- ADR-style records of the locked decisions.
