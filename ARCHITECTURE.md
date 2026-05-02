# claude-plugins -- Architecture

Top-level architecture narrative for the `idnotbe/claude-plugins` marketplace
hub. This file is the contributor entry point. The detailed design lives under
`docs/architecture/`; this file summarizes and points at it.

## Overview

`idnotbe/claude-plugins` is a **hub-and-spoke** Claude Code plugin marketplace.
The hub repository (this one) holds a single static manifest at
`.claude-plugin/marketplace.json` listing every plugin published under the
`idnotbe` brand. Each plugin lives in its own upstream repository under
`github.com/idnotbe/*` (the "spokes"). The hub never vendors, mirrors, or
modifies a spoke -- it only references each spoke by URL. When a user runs
`/plugin install <name>@idnotbe`, Claude Code's plugin loader resolves the
hub's manifest entry, clones the upstream spoke, and loads its
`.claude-plugin/plugin.json` to perform the actual install.

There is no runtime, no executable code, no plugin source, and no
`.claude-plugin/plugin.json` at the hub repo root. The hub is metadata only.

## Repository layout

```
claude-plugins/
  .claude-plugin/
    marketplace.json         # The hub's only behavior-bearing artifact
  docs/
    requirements/
      overview.md            # Mission, scope, stakeholders, success criteria
      functional.md          # Numbered REQ-* requirements with rationale
    architecture/
      overview.md            # Hub-and-spoke model, install-flow diagram
      components.md          # Per-component contract (manifest, entries, etc.)
      decisions.md           # ADR-001..006 (lock-in records)
  action-plans/              # Execution plans (lifecycle directory)
    README.md                # Plan lifecycle, status frontmatter, phases
    0001-bootstrap-hub-repo.md
    0002-onboard-additional-plugins.md
    _done/                   # Completed plans
    _ref/                    # Reference / historical
  tests/
    validate_marketplace.sh  # Hub-policy validator (Phase 4)
    test_scenarios.md        # Manual install/collision scenarios (Phase 4)
  README.md                  # User-facing docs and install path
  ARCHITECTURE.md            # This file
  CLAUDE.md                  # Project instructions for Claude Code agents
  LICENSE                    # MIT License
  .gitignore                 # Git ignore rules
```

## Architecture documents

This file is a summary. The long form lives under `docs/architecture/`:

- [`docs/architecture/overview.md`](docs/architecture/overview.md) -- the
  hub-and-spoke model, why-not-monorepo rationale, install-flow ASCII diagram,
  and the trust-boundary statement.
- [`docs/architecture/components.md`](docs/architecture/components.md) -- per-
  component description: the manifest contract, plugin entries (initial
  catalog), source-resolution table (5 forms), the registry collision table,
  dual install paths, and the two-layer validation model.
- [`docs/architecture/decisions.md`](docs/architecture/decisions.md) -- six
  ADR-lite records (ADR-001 through ADR-006) recording each significant choice
  with context, decision, consequences, and alternatives considered.

Numbered requirements (`REQ-MANIFEST-*`, `REQ-PLUGIN-ENTRY-*`,
`REQ-INSTALL-FLOW-*`, `REQ-COLLISION-*`, `REQ-HYGIENE-*`, `REQ-VERSION-*`) live
in [`docs/requirements/functional.md`](docs/requirements/functional.md). Every
ADR cites the REQ IDs it supports.

## Key decisions

Seven ADRs lock in the architecture. Each is one paragraph in
[`docs/architecture/decisions.md`](docs/architecture/decisions.md); the gist:

- **[ADR-001](docs/architecture/decisions.md#adr-001-marketplace-name-field-is-idnotbe-not-idnotbe-plugins)**
  -- Marketplace `name` is the literal `"idnotbe"`. Drives the `@idnotbe`
  install suffix. Mirrors Cloudflare's `"cloudflare"` single-word brand.
- **[ADR-002](docs/architecture/decisions.md#adr-002-v1-plugin-sources-use-bare-url-form-no-sha-pin)**
  -- v1 plugin sources use the bare `url` form (no `ref`, no `sha`). Tracks the
  upstream's default branch by git SHA on each pull. Sha-pinning is a known
  future option.
- **[ADR-003](docs/architecture/decisions.md#adr-003-no-pluginjson-at-the-hub-repo-root----the-hub-is-not-itself-a-plugin)**
  -- No `plugin.json` at the hub repo root. The hub is a registry, not an
  installable artifact. Validator asserts this absence as a load-bearing
  invariant.
- **[ADR-004](docs/architecture/decisions.md#adr-004-dual-install-paths----both-hub-and-per-plugin-marketplacejson-remain-valid)**
  -- Both install paths coexist: hub (`<plugin>@idnotbe`) is recommended;
  per-plugin (`<plugin>@<plugin-marketplace>`) remains supported. No upstream
  repo is required to delete its own `marketplace.json`. (Superseded by ADR-007.)
- **[ADR-005](docs/architecture/decisions.md#adr-005-catalog-scope-at-v1----vibe-check-and-claude-code-guardian-only)**
  -- v1 catalog is exactly `vibe-check` and `claude-code-guardian`. Other
  candidate repos under `/home/idnotbe/projects/*` are out of scope until they
  pass the inclusion criteria in `action-plans/0002-onboard-additional-plugins.md`.
- **[ADR-006](docs/architecture/decisions.md#adr-006-two-layer-validation----claude-plugin-validate--baseline--hub-specific-shell-layer)**
  -- Two-layer validation: built-in `claude plugin validate .` baseline +
  custom `tests/validate_marketplace.sh` for hub-only policy.
- **[ADR-007](docs/architecture/decisions.md#adr-007-hub-is-the-single-install-path----supersedes-adr-004-dual-install-paths)**
  -- Hub is the single install path -- supersedes ADR-004 (dual install paths).
  Per-plugin `marketplace.json` files are removed; the hub at `idnotbe/claude-plugins`
  becomes the sole documented install path for any `idnotbe`-owned plugin.

## Source resolution model

Source resolution is done by Claude Code, not by the hub. The hub manifest only
declares which form each entry uses. The schema permits five forms:

| # | Form | Shape | Behavior |
|---|------|-------|----------|
| 1 | Relative path | `"./plugins/foo"` (string) | Resolves relative to `marketplace.json` directory. Used by monorepo layouts. |
| 2 | GitHub shorthand | `{ "source": "github", "repo": "owner/name", "ref"?, "sha"? }` | Equivalent to URL form for `https://github.com/owner/name.git`. |
| 3 | URL (whole repo) | `{ "source": "url", "url": "...", "ref"?, "sha"? }` | Clones URL, checks out default branch (or pinned `ref`/`sha`), loads `.claude-plugin/plugin.json`. |
| 4 | Git subdir | `{ "source": "git-subdir", "url": "...", "path": "...", "ref"?, "sha"? }` | Clones, checks out, then loads `plugin.json` from `path/`. |
| 5 | npm | `{ "source": "npm", "package": "..." }` | Resolves through the npm registry. |

**Hub policy (v1)**: every entry uses **form #3 bare** -- no `ref`, no `sha`:
`{ "source": "url", "url": "https://github.com/idnotbe/<repo>.git" }`. Any
pinning is deferred (ADR-002). Forms #1/#2/#4/#5 are documented for future
hub maintainers; this hub does not use them. See
[`docs/architecture/components.md`](docs/architecture/components.md) Section 3
for the canonical version of this table.

## Hub policy summary

Hub-only policy that goes beyond what the marketplace schema enforces:

- **Marketplace name is exactly `"idnotbe"`.** Not `"idnotbe-plugins"`. Drives
  `@idnotbe` install UX. (REQ-MANIFEST-001 / ADR-001)
- **Every plugin source URL is `^https://github\.com/idnotbe/[^/]+\.git$`.**
  Only `idnotbe`-owned upstreams. (REQ-PLUGIN-ENTRY-002 / ADR-002)
- **Bare URL only -- no `ref`, no `sha`.** Sha-pinning is a known future option,
  not a v1 policy. (REQ-PLUGIN-ENTRY-002 / ADR-002)
- **Plugin entries are metadata-only.** No inline `commands`, `hooks`,
  `mcpServers`, `lspServers`, `agents`, `skills`, `setup`, `strict` -- even
  though the schema permits them. Plugin behavior lives in each upstream's own
  `plugin.json`. (REQ-HYGIENE-002)
- **No `plugin.json` at the repo root.** The hub is not a plugin. (REQ-MANIFEST-005 / ADR-003)
- **`plugins[]` is sorted alphabetically (case-insensitive) by `name`.**
  Deterministic merge conflicts; no implied ranking. (REQ-PLUGIN-ENTRY-005)
- **`$schema` declared at the manifest root.** Enables editor autocomplete and
  inline validation. (REQ-MANIFEST-006)

Each policy line is enforced at the hub level because the platform-side
validator does not enforce it -- the schema is more permissive than this hub.

## Validation model (two-layer)

Per [ADR-006](docs/architecture/decisions.md#adr-006-two-layer-validation----claude-plugin-validate--baseline--hub-specific-shell-layer):

**Layer 1 -- Built-in baseline**: `claude plugin validate .` (also `/plugin
validate .`). Tracks the schema Claude Code's loader actually loads against.
Covers JSON well-formedness, schema conformance, required-field presence per
schema, source-form validity. Anything that breaks here will also break for
users on install. This is the floor.

**Layer 2 -- Hub-specific**: `tests/validate_marketplace.sh` (Phase 4 of
`action-plans/0001-bootstrap-hub-repo.md`). Implements CHECK-0 through
CHECK-13 -- the hub-only policy checks listed above. Modeled on
`idnotbe/vibe-check`'s `validate_skill.sh` (POSIX shell, no Node). Exits 0 on
success, 1 on failure.

Both must pass before any change to `marketplace.json` is merged. CI to wrap
both is a documented follow-up; out of scope for v1.

## Process

Every change to this repo follows the lifecycle in
[`action-plans/README.md`](action-plans/README.md): a plan with YAML
frontmatter (`status: not-started | active | blocked | done | superseded`),
phases (Phase 0 docs alignment, Phase 1..N execution, Phase F-1 docs sync gate,
Phase F commit & push), and a `_done/` move when complete.

Two starter plans live in `action-plans/`:

- [`0001-bootstrap-hub-repo.md`](action-plans/0001-bootstrap-hub-repo.md) --
  the bootstrap plan that brings the hub from empty directory to published
  repo. Active during initial setup; moves to `_done/` when Phase F lands.
- [`0002-onboard-additional-plugins.md`](action-plans/0002-onboard-additional-plugins.md)
  -- the repeatable per-plugin onboarding workflow with inclusion criteria,
  candidate inventory, and the per-addition phase checklist. Forked once per
  plugin added.

`temp/` is working memory: phase-0 alignment docs, eligibility surveys,
validator dry-run output. It is not committed by default (see `.gitignore`).
