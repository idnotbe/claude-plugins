# claude-plugins -- Claude Code Plugin Marketplace Hub

## What This Is

A Claude Code **marketplace hub** for the `idnotbe` brand. The repo holds a
single static manifest at `.claude-plugin/marketplace.json` that lists every
plugin published by `idnotbe`. Users add the hub once
(`/plugin marketplace add idnotbe/claude-plugins`), then install any catalog
entry via `/plugin install <name>@idnotbe`.

This repository is **NOT itself a plugin**. There is no `.claude-plugin/plugin.json`
at the repo root. There is no installed runtime code, no skills, no hooks,
no commands. The hub is metadata only -- supporting files (validators, README,
docs) describe or protect the manifest but do not run inside Claude Code.

## Repo Structure

    .claude-plugin/marketplace.json     # The single behavior-bearing artifact
    .github/workflows/catalog.yml      # Native Windows/Linux installation CI
    tools/check_catalog.py             # Maintenance-only catalog checks
    tests/test_catalog.py              # Cross-platform checker regressions
    docs/requirements/overview.md       # Mission, scope, success criteria
    docs/requirements/functional.md     # REQ-* numbered requirements
    docs/architecture/overview.md       # Hub-and-spoke model, install-flow diagram
    docs/architecture/components.md     # Per-component contract + source-forms table
    docs/architecture/decisions.md      # ADR decision records
    action-plans/README.md              # Lifecycle, frontmatter, phases
    action-plans/0002-onboard-additional-plugins.md
    action-plans/_done/                 # Completed plans, including 0007
    action-plans/_ref/                  # Reference / historical
    tests/validate_marketplace.sh       # Existing hub-policy validator
    tests/test_scenarios.md             # Manual install/collision scenarios
    README.md                           # User-facing entry point
    ARCHITECTURE.md                     # Top-level architecture narrative
    CLAUDE.md                           # This file -- project instructions
    LICENSE                             # MIT License
    .gitignore                          # Git ignore rules
    temp/                               # Working memory (NOT committed)

## Key Facts

1. **No runtime dependencies.** The hub does not execute code. It makes no
   outbound API calls and requires no environment variables.
2. **No `plugin.json` at the repo root.** The hub is a marketplace, not a
   plugin (REQ-MANIFEST-005, ADR-003). Subdirectory `plugin.json` files inside
   future fixtures or examples are allowed -- the rule is scoped to the repo
   root because that is the path Claude Code's loader treats as the
   hub-as-plugin advertisement.
3. **Marketplace `name` is exactly `"idnotbe"`.** Drives the `@idnotbe`
   install suffix users type (REQ-MANIFEST-001, ADR-001). Not
   `"idnotbe-plugins"`. Not anything else.
4. **Plugin sources use the bare `url` form only.**
   `{ "source": "url", "url": "https://github.com/idnotbe/<repo>.git" }` --
   no `ref`, no `sha`. Tracks the upstream's default branch by git SHA on each
   pull (REQ-PLUGIN-ENTRY-002, ADR-002). Sha-pinning is a known future option,
   not a v1 policy.
5. **`plugins[]` is sorted alphabetically (case-insensitive) by `name`.**
   Adding a new plugin means inserting at the position dictated by alphabetical
   order, not appending (REQ-PLUGIN-ENTRY-005). Deterministic merge conflicts;
   no implied ranking from list position.
6. **Plugin entries are metadata-only.** No inline `commands`, `hooks`,
   `mcpServers`, `lspServers`, `agents`, `skills`, `setup`, `strict` -- even
   though the schema permits them. Plugin behavior lives in each upstream's
   own `plugin.json` (REQ-HYGIENE-002).
7. **Two-layer validation.** Built-in `claude plugin validate .` (baseline
   schema check) + custom `tests/validate_marketplace.sh` (hub-only policy).
   Both must exit 0 before any manifest change is committed (ADR-006).
   Native installation CI adds evidence; it does not replace either layer.

## Testing

Two layers, per ADR-006. Run both before merging any change to
`.claude-plugin/marketplace.json` or `tests/validate_marketplace.sh`.

### Layer 1 -- Built-in baseline

    claude plugin validate .

(Also exposed inside Claude Code as the slash command `/plugin validate .`.)
Validates JSON well-formedness and schema conformance against the marketplace
schema. Exit code 0 on success, non-zero on failure. Integration CI uses the
strict form on native Windows and Linux.

### Layer 2 -- Hub-specific

    bash tests/validate_marketplace.sh

Implemented and preserved from the original hub. Implements CHECK-0 through
CHECK-13: literal `name == "idnotbe"`, source-URL pattern, no inline component
fields, alphabetical ordering, `$schema` presence, etc. Exit code 0 on success,
1 on failure, and 2 for missing tooling. Bash and jq are required.

### Cross-platform installation evaluation

    python -B -m unittest discover -s tests -p test_catalog.py -v
    python -B tools/check_catalog.py
    python -B tools/check_catalog.py --smoke --report temp/catalog-report.json

The first two commands are local structural/regression checks. The explicit
`--smoke` command needs Git, Node/npm and the official Claude Code CLI and uses
network access in a disposable home. It installs only the three standardized
skill plugins, checks actual installed files and records exact versions and
source revisions. No model turn or credential is needed. Keep GUI/workspace and
model-effectiveness observations separate; missing observations stay not_run.

### Test File Status

| File | Status | Notes |
|------|--------|-------|
| `tests/validate_marketplace.sh` | Implemented | Original hub-policy checks; preserved. |
| `tests/test_scenarios.md` | Present | Manual install/collision scenario guidance. |
| `tests/test_catalog.py` | Implemented | Eight cross-platform checker regressions. |
| `.github/workflows/catalog.yml` | Implemented | Native Windows/Linux real installation checks. Inspect exact-run results. |

## When Editing marketplace.json

After ANY change to `.claude-plugin/marketplace.json`, run through this
checklist before committing:

- [ ] Update `README.md` catalog list (add/remove/rename row, keep alphabetical).
- [ ] Update `docs/architecture/components.md` Section 2 (catalog enumeration).
- [ ] Confirm the entry uses ONLY metadata fields: `name`, `description`,
      `source`, optionally `category`, `tags`, `author`, `homepage`, `keywords`,
      `version`. No inline `commands`, `hooks`, `mcpServers`, `lspServers`,
      `agents`, `skills`, `setup`, `strict`.
- [ ] Confirm `source` is bare-URL form -- no `ref`, no `sha`.
- [ ] Confirm `plugins[]` is alphabetically sorted by `name` (case-insensitive).
- [ ] Run `claude plugin validate .` -- exit code 0.
- [ ] Run `bash tests/validate_marketplace.sh` -- exit code 0.
- [ ] If you added/removed a `REQ-*` in `docs/requirements/functional.md`, update
      the corresponding validator check ID and re-run both layers.
- [ ] Follow the action-plan lifecycle: every manifest change should be paired
      with a plan file under `action-plans/` (Phase F-1 docs sync gate runs
      this checklist as its body).
- [ ] Before merge, inspect the actual native CI results and installation report
      for the exact head. A configured workflow is not a passing run.

## Development Guidelines

- **Keep `marketplace.json` stable.** It is the "API" of this hub. Plugin
  `name` and `source.url` are referenced in user-typed commands -- treat
  changes to those values as breaking.
- **No Node.js runtime tooling in the hub.** The existing policy validator
  remains Bash and jq. Node/npm is used only by explicit installation evaluation
  to run the upstream skills and host CLIs. The additional checker uses Python
  3.10+ standard library; no npm package, model client or runtime dependency is
  shipped by the catalog.
- **All committed content in English** (REQ-HYGIENE-003). Mirrors the
  `idnotbe/vibe-check` convention; keeps the repo maintainable for external
  contributors. Manifest descriptions, README, ARCHITECTURE, CLAUDE.md, all
  `docs/`, all `action-plans/`, all commit messages -- English only.
- **Do not host plugin source here.** Plugin code, skills, hooks, commands,
  agents, scripts -- all of those live in upstream spoke repos. The hub holds
  metadata pointing AT them, never the artifacts themselves.
- **Do not add a root-level `plugin.json`.** REQ-MANIFEST-005 and validator
  CHECK-5 explicitly assert its absence. The hub is a registry, not
  an installable artifact (ADR-003).
- **Preserve the docs hierarchy.** `README.md` is user-facing; `ARCHITECTURE.md`
  summarizes; `docs/architecture/*` is the long form; `docs/requirements/*`
  carries the numbered REQ-* IDs that ADRs and validator checks cite. ADRs and
  REQs are stable IDs -- do not renumber existing entries.
- **Standardized skills use one source bundle.** deep-inquiry,
  skill-quality-builder and vibe-check each expose `.agents/skills/<name>/`
  through matching Claude/OpenAI compatibility manifests. The separate OpenAI
  catalog uses `idnotbe-chatgpt-plugins`; never reuse this hub's marketplace name.

## Autonomy

Default = autonomous execution. Report results in 1-2 sentences. Request confirmation only for items under "Confirmation required" below.

**Decision rule** — both must hold to execute autonomously:
1. **Reversible from local state** with a short, well-known sequence (`git revert`, `git restore`, `git mv` back, etc.) — not requiring conflict resolution or reflog archaeology.
2. **No external side effects already in flight** — nothing that has notified humans, triggered CI someone watches, or could already have been pulled/consumed.

If either fails, confirm.

**Pre-authorized (execute without confirmation)** — within this repo, when the decision rule holds:
- File edit/create/delete (tracked), `git add/commit/push` (including `origin/main`)
- Local branch/tag operations, `git revert`, `git restore`
- Running tests, validators, builds; moving action-plans and updating status
- Delegating to subagents; calling `pal mcp clink`, `vibe-check`

**Confirmation required** — irreversible, history-rewriting, destructive, or external blast radius:
- `git push --force` / `--force-with-lease` (especially on shared branches)
- History rewrites on already-pushed commits: `git commit --amend`, `git rebase -i`, `git reset --hard` on shared history
- Workspace destruction outside git's safety net: `git clean -fd`, `rm -rf` on untracked files/directories, direct edits inside `.git/`
- Remote-ref deletion: `git push --delete`, deleting unmerged branches
- Creating/commenting on GitHub PRs/issues, sending external messages or email
- Release tags, `npm publish`, deploys, cost-incurring operations
- Bypassing hooks (`--no-verify` etc.), modifying `git config`
- Anything the user explicitly reserved decision authority over **in this conversation** (plan text alone does not count)

**Default for unlisted operations**: if it touches only local tracked state and is reversible per the decision rule, treat as Pre-authorized. If it rewrites history, deletes untracked work, or has external reach, treat as Confirmation required. When genuinely ambiguous, confirm once and remember the answer for the rest of the session.

## Action Plans

Execution plan files live in `action-plans/`. Each file has YAML frontmatter
managing status:

- `status`: `not-started` | `active` | `blocked` | `done` | `superseded`
- `progress`: free-text current state

**Rules:**

- Update `status` and `progress` when starting/finishing work on a plan.
- Move completed plans (`status: done`) to `action-plans/_done/`.
- `action-plans/_ref/` is for reference / historical documents that are not
  actionable.
- Naming: `NNNN-kebab-case-title.md`. `NNNN` is a 4-digit zero-padded monotonic
  counter, never reused; check both root and `_done/` before picking the next
  number.
- Lifecycle: Phase 0 (docs alignment gate) -> Phase 1..N (execution) -> Phase
  F-1 (docs sync gate, run both validators) -> Phase F (commit & push, move
  file to `_done/`). See `action-plans/README.md` for the full lifecycle and
  the Lightweight-classification carve-out.
- Plans that touch `marketplace.json`, `tests/validate_marketplace.sh`, or any
  REQ-* MUST follow the full lifecycle. Pure typo fixes inside a single doc
  may skip the plan.
- `temp/` is working memory for active plans (Phase 0 alignment docs,
  eligibility surveys, validator dry-run output). It is git-ignored.

**Plan authoring — autonomy principles:**
- Default is **end-to-end autonomous execution**. Do not insert any pause / checkpoint / review / sign-off / approval / surface-to-user step — regardless of wording — unless it cites the exact "Confirmation required" bullet it maps to.
- commit/push are reversible — never gate them.
- Each gated step must include a citation comment naming the matching bullet, e.g. `# Gate: Confirmation required → "git push --force on shared branches"`. No citation = remove the gate.
- When auditing existing plans, apply the same citation test: any gate without a valid citation is removed before execution proceeds.

## Continuous Verification

Plan 0007 added `.github/workflows/catalog.yml` for native Ubuntu and Windows.
It preserves the existing shell policy validator on Linux, runs the first-party
strict Claude validator on both systems, and evaluates actual remote skill and
plugin installation with exact-revision evidence. All maintenance code remains
outside the installed plugin sources. Current public host CLIs are intentionally
used to detect compatibility drift; their versions are recorded in the report.

Inspect the actual run conclusion and artifact before merge. Do not bypass a
failed gate, relabel missing observations as passes, or infer model effectiveness
from packaging success. The OpenAI sibling uses the same maintenance checker for
development-only Codex plugin API tests; it is not a production client recipe.

## English-only Policy

Per REQ-HYGIENE-003, all committed text in this repository -- manifest
descriptions, README, ARCHITECTURE, CLAUDE.md, `docs/`, `action-plans/`, commit
messages -- MUST be in English. Comments in non-committed working memory
(`temp/`) are exempt; everything that lands in the repo is English.
