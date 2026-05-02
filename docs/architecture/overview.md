# Architecture Overview

## Elevator Pitch

`idnotbe/claude-plugins` is a **Claude Code plugin marketplace hub**. Its only behavior-bearing deliverable is a single static JSON document, `.claude-plugin/marketplace.json`, that lists every plugin published under the `idnotbe` brand. There is no runtime, no executable code, no plugin source, and no `.claude-plugin/plugin.json` at the repository root. Claude Code's built-in plugin loader is the only consumer; it reads the manifest, resolves each plugin entry's `source` to an upstream Git repository, and installs the plugin from there. (Supporting files exist: a hub-specific structural validator, a README, and these design documents -- they describe or protect the manifest but do not run inside Claude Code.)

## Hub-and-Spoke Model

The architecture is hub-and-spoke:

- **Hub (this repo)**: `github.com/idnotbe/claude-plugins` -- holds `.claude-plugin/marketplace.json` only.
- **Spokes (per-plugin repos)**: `github.com/idnotbe/vibe-check`, `github.com/idnotbe/claude-code-guardian`, and any future `idnotbe`-owned plugin repos. Each spoke owns its own `.claude-plugin/plugin.json` and (optionally) its own `.claude-plugin/marketplace.json` for the single-plugin install path.

The hub does not vendor, mirror, fork, or modify any spoke. It only references them by URL. When a user runs `/plugin install vibe-check@idnotbe`, Claude Code reads the hub's manifest, finds the `vibe-check` entry, resolves `source.url` to `https://github.com/idnotbe/vibe-check.git`, clones that repo, and loads the upstream `plugin.json` as the source of truth for the actual install.

## Why Not a Monorepo

A monorepo (one repository containing all plugins as subdirectories, like Anthropic's `claude-plugins-official`) was considered and rejected for v1. The reasons:

1. The two existing plugins (`vibe-check`, `claude-code-guardian`) already exist as independent repositories with their own commit histories, issues, and per-plugin `marketplace.json`. Folding them into a monorepo would either lose that history or require git-subtree merges that complicate ongoing maintenance.
2. Plugin authors who want to install a single plugin via `/plugin marketplace add idnotbe/<plugin>` depend on the per-plugin repo continuing to exist. A monorepo would force that path to become `git-subdir`-resolution, which is heavier than the current bare-`url` form.
3. The hub-and-spoke model lets each plugin evolve at its own cadence. A breaking change in one plugin's `plugin.json` schema affects only that spoke, not the hub manifest.

The trade-off accepted in exchange: the hub manifest must be updated (one new entry) whenever a new plugin is published. This is a single-line edit and a commit.

## Interaction with the Claude Code Plugin Loader

The boundary between this repo and Claude Code is purely declarative. Claude Code does the work; the hub provides the data:

```
+-------------------+        +------------------------+        +--------------------------+
| User runs         |  --->  | Claude Code loader     |  --->  | github.com/idnotbe/      |
| /plugin install   |        | reads hub manifest,    |        | claude-plugins/          |
| <name>@idnotbe    |        | finds entry by name,   |        | .claude-plugin/          |
+-------------------+        | resolves source.url    |        | marketplace.json         |
                             +------------------------+        +--------------------------+
                                       |
                                       v
                             +------------------------+        +--------------------------+
                             | Claude Code clones     |  --->  | github.com/idnotbe/      |
                             | the upstream spoke     |        | <plugin>/                |
                             | and loads its          |        | .claude-plugin/          |
                             | plugin.json            |        | plugin.json              |
                             +------------------------+        +--------------------------+
```

Everything to the left of the spoke clone is hub responsibility. Everything to the right is upstream-plugin responsibility. The hub never touches the spoke's code, never participates in the install transaction beyond providing the URL, and never sees any user input.

## Trust Boundaries and Surface Area

The hub's outbound effect surface is intentionally empty:

- **No executable content.** `marketplace.json` has no script, hook, command, or environment-variable field.
- **No filesystem writes.** The hub does not run.
- **No outbound calls of its own.** Claude Code makes the `git clone` when resolving `source.url`; the hub does not.
- **No secrets.** No API keys, no env var references.

The only thing that could break the hub's promises is a malformed or hostile `marketplace.json` entry pointing at a malicious URL. This is mitigated by two layers of validation:

1. **Built-in baseline**: Claude Code's `claude plugin validate .` (also available as the `/plugin validate .` slash command) checks schema conformance and structural validity. This is the floor that any marketplace.json must clear.
2. **Hub-specific layer**: The planned `tests/validate_marketplace.sh` adds policy checks the built-in validator does not perform: marketplace `name` is exactly `"idnotbe"`, every plugin source URL points at `github.com/idnotbe/*.git`, no plugin entry inlines executable component fields (`commands`, `hooks`, `mcpServers`, etc. -- see REQ-HYGIENE-002), and the `$schema` declaration is present and correct.

Both also rest on the social fact that all entries point at `github.com/idnotbe/*` repositories owned by the same author who maintains the hub.

## Pointers

| Topic | Location |
|-------|----------|
| Component-by-component description | `./components.md` |
| Architecture decisions (ADR-lite) | `./decisions.md` |
| Functional requirements (REQ-* IDs) | `../requirements/functional.md` |
| Mission, scope, success criteria | `../requirements/overview.md` |
