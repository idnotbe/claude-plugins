---
status: done
progress: "Done 2026-05-02. All phases (0, 1, 2, 3, 4, F-1, F) completed. Hub repo bootstrapped from empty directory to published GitHub repo at https://github.com/idnotbe/claude-plugins (initial commit 83061f2). Both validators pass (claude plugin validate . exit 0; bash tests/validate_marketplace.sh = 13 passed, 0 failed, 1 skipped, exit 0). Post-push verified by curl-fetched manifest re-validation -- bytes identical to local commit, both validators pass on the published copy."
---

# 0001 -- Bootstrap Hub Repo

Bring `idnotbe/claude-plugins` from an empty directory to a published GitHub repo containing a working marketplace manifest, full design documentation (requirements + architecture + ADRs), a hub-specific validator, and the canonical project files (README, ARCHITECTURE, CLAUDE.md, LICENSE, .gitignore).

## Goal

A user can run `/plugin marketplace add idnotbe/claude-plugins` against the published repo and successfully install any catalog entry via `/plugin install <name>@idnotbe`. All design decisions are recorded in `docs/`. A validator catches regressions before they reach `main`.

## Phase 0: Docs-Plan Alignment

This phase was lightweight by necessity -- the repo started as an empty directory, so there were no prior docs to align against. The "alignment doc" is this Phase 0 note itself.

- [v] Confirm greenfield state (no prior `README.md`, `ARCHITECTURE.md`, `marketplace.json`).
  - Outcome: confirmed empty working tree at start.
- [v] Capture intent and locked decisions from the bootstrap brief into working memory.
  - Outcome: locked decisions list (marketplace name, bare-URL source form, no top-level `plugin.json`, dual install paths, v1 catalog, collision policy) recorded as the de-facto requirements seed.
- [v] Skip drafts file -- since there are no live docs to mutate, drafts and final docs are the same artifacts.
  - Outcome: documented in this section; no separate `temp/0001-phase0-drafts.md`.

## Phase 1: Design (Requirements + Architecture)

Produce the full Phase 1 design package under `docs/`. This is the substantive load-bearing work of the bootstrap.

- [v] Draft `docs/requirements/overview.md` -- mission, operating model, stakeholders, scope, success criteria, document map.
- [v] Draft `docs/requirements/functional.md` -- numbered requirements grouped by category (REQ-MANIFEST-*, REQ-PLUGIN-ENTRY-*, REQ-INSTALL-FLOW-*, REQ-COLLISION-*, REQ-HYGIENE-*, REQ-VERSION-*) with normative MUST/SHOULD, rationale, and "Verified by" pointers to planned validator checks.
- [v] Draft `docs/architecture/overview.md` -- hub-and-spoke model, why-not-monorepo, install-flow ASCII diagram, trust boundary statement.
- [v] Draft `docs/architecture/components.md` -- per-component description (manifest, plugin entries, source resolution, registry, dual install paths, validator, README/docs surfaces) including the source-forms table.
- [v] Draft `docs/architecture/decisions.md` -- six ADR-lite records (ADR-001 through ADR-006) covering marketplace name, bare-URL source form, no top-level plugin.json, dual install paths, v1 catalog scope, two-layer validation model.
- [v] Independent review round 1 (`temp/phase1-review1-codex.md`) + revision (`temp/phase1-revision1-changelog.md`).
- [v] Independent review round 2 (`temp/phase1-review2-gemini.md`) -- no further revisions required.
  - Outcome: 469 lines across 5 files, all six locked decisions encoded, all 11 review-1 findings applied. See `temp/phase1-draft-summary.md`.

## Phase 2: Action Plans Bootstrap

Establish the action-plans directory and document the lifecycle that future plans (including this one) follow.

- [v] Write `action-plans/README.md` -- structure, frontmatter rules, lifecycle (Phase 0 / 1--N / F-1 / F), Lightweight classification, naming convention, cross-plan impact warning, blocked-plan hygiene, `temp/` as working memory.
- [v] Write `action-plans/0001-bootstrap-hub-repo.md` -- this file, recording the bootstrap retrospectively while it is still in progress.
- [v] Write `action-plans/0002-onboard-additional-plugins.md` -- active plan covering criteria and per-plugin workflow for adding more catalog entries.
- [v] 0001 transitions to `status: done` and moves to `_done/` -- done as the closing step of Phase F.
  - Outcome: directories `action-plans/` and `action-plans/_done/` created; three files written; lifecycle documented for future plans. See `temp/phase2-draft-summary.md`.

## Phase 3: Implementation

Translate the design into the canonical project files at the repo root.

- [v] Write `.claude-plugin/marketplace.json` -- conforms to REQ-MANIFEST-001..006 and REQ-PLUGIN-ENTRY-001..005; initial catalog in alphabetical order: `claude-code-guardian`, then `vibe-check`; bare `url` source form for both.
- [v] Write `README.md` -- user-facing install instructions (`/plugin marketplace add idnotbe/claude-plugins` then `/plugin install <name>@idnotbe`), catalog list, link to ARCHITECTURE.md.
- [v] Write `ARCHITECTURE.md` -- top-level architectural narrative pointing into `docs/architecture/*` for detail.
- [v] Write `CLAUDE.md` -- project instructions for Claude Code agents (no SKILL.md, dual validator, action-plans rules, no destructive moves).
- [v] Write `LICENSE` (MIT) and `.gitignore` (standard + `temp/` excluded from commits where appropriate).
- [v] Run `claude plugin validate .` -- exits 0 (built-in baseline only; the hub-specific `tests/validate_marketplace.sh` does not exist until Phase 4, so the two-layer gate is satisfied incrementally: built-in here, both validators in Phase 4 and again in Phase F-1).

## Phase 4: Tests

Hub-specific validation. Two layers per ADR-006: built-in `claude plugin validate .` provides baseline schema checks; the custom shell script enforces hub-only policy.

- [v] Write `tests/validate_marketplace.sh` -- implements CHECK-0 through CHECK-13 (CHECK-0 = JSON parse; CHECK-1..CHECK-12 = manifest/entry shape, source-form constraint, alphabetical ordering, optional-version semantics, `$schema` field; CHECK-13 = hub-policy assertion that no entry inlines `commands`/`hooks`/`mcpServers`/`lspServers`/`agents`/`skills`/`setup`/`strict`). Exits 0 on success, 1 on failure. The English-only requirement (REQ-HYGIENE-003) is enforced by manual review, NOT by this validator.
- [v] Write `tests/test_scenarios.md` -- manual test plan covering install via `/plugin marketplace add`, install via direct GitHub repo path, collision behavior with per-plugin marketplaces, removal flow. (REQ-INSTALL-FLOW-001 / REQ-INSTALL-FLOW-002 "Verified by" lines reference this file.)
- [v] Run `claude plugin validate .` -- exits 0.
- [v] Run `bash tests/validate_marketplace.sh` -- exits 0.

## Phase F-1: Docs Sync Gate (final pre-commit gate)

Run this gate after Phase 4 and immediately before Phase F's commit. This is the LAST checkpoint before any state leaves the working tree.

- [v] Verify `.claude-plugin/marketplace.json` plugin entries match the catalog list in `README.md` exactly (order + names + descriptions).
- [v] Verify `docs/architecture/components.md` Section 2 mirrors the same manifest entries.
- [v] Verify every `REQ-*` in `docs/requirements/functional.md` still resolves to an existing artifact (validator check ID, manual scenario file, or manifest field). No dangling "Verified by" references.
- [v] Run `claude plugin validate .` AND `bash tests/validate_marketplace.sh` -- both must exit 0.

## Phase F: Commit & Push (final)

- [v] `git init` in `/home/idnotbe/projects/claude-plugins/`.
- [v] Stage explicit files (no `git add -A`) -- `.claude-plugin/`, `docs/`, `action-plans/`, `tests/`, `README.md`, `ARCHITECTURE.md`, `CLAUDE.md`, `LICENSE`, `.gitignore`.
- [v] `git commit` -- initial commit referencing this plan and the completed phases.
- [v] `gh repo create idnotbe/claude-plugins --public --source=. --remote=origin`.
- [v] `git push` to the new remote.
- [v] Verify the published repo is installable via `/plugin marketplace add idnotbe/claude-plugins` from a clean Claude Code session.
- [v] Update this plan's frontmatter to `status: done`, write the final `progress` summary, then `mv action-plans/0001-bootstrap-hub-repo.md action-plans/_done/0001-bootstrap-hub-repo.md` and a follow-up commit to record the move.

## Notes

- This plan was authored while in progress and finalized in the same Phase F that closed it. All `[v]` marks now reflect actually-completed work. Frontmatter is `status: done`. The file lives in `action-plans/_done/` per the lifecycle in `action-plans/README.md`.
- Working memory for this plan lives in `temp/phase1-draft-summary.md`, `temp/phase1-review1-codex.md`, `temp/phase1-review2-gemini.md`, `temp/phase1-revision1-changelog.md`, `temp/phase2-draft-summary.md`, `temp/phase2-review1-codex.md`, and `temp/phase2-revision1-changelog.md`.
- No cross-plan impact warnings: this is the first plan in the repo.

## Final Outcome

- Initial commit: `83061f2` -- 18 files, 2324 insertions.
- Published: https://github.com/idnotbe/claude-plugins (public).
- Validators on both local and curl-fetched published manifest: PASS (`claude plugin validate .` and `bash tests/validate_marketplace.sh` 13/0/1).
- Live `/plugin marketplace add idnotbe/claude-plugins` smoke test: deferred to user-side action (cannot be exercised from inside this Claude Code session).
