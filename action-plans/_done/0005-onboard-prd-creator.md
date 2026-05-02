---
status: done
progress: "Done 2026-05-02. prd-creator registered in hub: manifest entry + README catalog row + components.md row + 2-layer validators pass."
---

# 0005 -- Onboard `prd-creator` Plugin

Single-plugin execution of the reusable `0002-onboard-additional-plugins.md` workflow. Adds the `prd-creator` plugin to the hub catalog. One execution of this plan = one plugin added.

## Goal

Insert the `prd-creator` entry into `.claude-plugin/marketplace.json`, sync the README catalog and `docs/architecture/components.md` Section 2, and clear both validator layers. No schema changes; no new requirements; no new ADRs.

## Eligibility Summary

`prd-creator` is verdict `READY` per `temp/prd-creator-eligibility.md` (derived from `temp/eligibility-survey-CORRECTED.md`, the combined survey produced before 0002 was forked into per-plugin plans):

- Lives at `github.com/idnotbe/prd-creator`; visibility PUBLIC; default branch active.
- Upstream `.claude-plugin/plugin.json` exists and is well-formed; `name == "prd-creator"`, non-empty `description`, declares `skills`/`keywords`/`homepage`.
- The upstream's `skills` field is permitted by the marketplace.json schema and is NOT a violation of REQ-HYGIENE-002 -- that requirement scopes only to entries inside the hub's `marketplace.json`, not to upstream `plugin.json`. Validator `CHECK-13` walks `plugins[]` in the hub manifest, not upstream files (see corrected eligibility analysis).
- No upstream restructuring is required. The hub entry will be metadata-only.
- Plugin `name` does not collide with existing entries.
- If the upstream ships a `marketplace.json`, it MUST NOT use `name: "idnotbe"` (REQ-COLLISION-002) -- verified during Phase 0.

## Inclusion Criteria (one-time gate)

- [v] Plugin lives at `github.com/idnotbe/prd-creator` (REQ-PLUGIN-ENTRY-002).
- [v] Upstream repo has a working `.claude-plugin/plugin.json`.
- [v] Plugin has a non-empty `description` (used as the user-facing install description).
- [v] If the upstream ships a `marketplace.json`, it MUST NOT use `name: "idnotbe"` (REQ-COLLISION-002).
- [v] Plugin name does not collide with an existing entry in `.claude-plugin/marketplace.json` (REQ-PLUGIN-ENTRY-003).
- [v] Plugin name equals the upstream `plugin.json.name` exactly -- both are `prd-creator` (REQ-PLUGIN-ENTRY-004).
- [v] Plugin is not abandoned or archived (last commit within ~12 months, or maintainer confirms ongoing maintenance).
- [v] `claude plugin validate .` against the upstream repo exits 0.
- [v] The proposed entry uses ONLY metadata fields (`name`, `description`, `source`, optionally `category`, `tags`, `author`, `homepage`, `keywords`, `version`); MUST NOT inline `commands`, `hooks`, `mcpServers`, `lspServers`, `agents`, `skills`, `setup`, or `strict` (REQ-HYGIENE-002 / CHECK-13).

## Phase 0: Docs-Plan Alignment

- [v] Confirm the eligibility-survey result for `prd-creator` is `READY` (recorded in `temp/prd-creator-eligibility.md`; the combined master survey at `temp/eligibility-survey-CORRECTED.md` is retained as audit trail).
- [v] Re-read `docs/requirements/functional.md` REQ-PLUGIN-ENTRY-* and REQ-COLLISION-* to confirm no schema changes are needed for this addition. If a schema change IS needed (e.g., a new source form), STOP and open a separate plan for the schema change first.
- [v] Draft the proposed `marketplace.json` entry, README catalog row, and `components.md` Section 2 row in `temp/0005-onboard-prd-creator-phase0-drafts.md`.
- [v] Write gap list and impact assessment to `temp/0005-onboard-prd-creator-phase0-alignment.md`.

## Phase 1: Add Manifest Entry

- [v] Insert the `prd-creator` entry into `.claude-plugin/marketplace.json` at the correct alphabetical position by `name` (REQ-PLUGIN-ENTRY-005). Position: between `humanizer` and `vibe-check` once `humanizer` lands; absent that, at the lowercase-alphabetical position relative to whatever is currently in `plugins[]`.
- [v] Use the entry exactly as defined in `temp/0005-onboard-prd-creator-phase0-drafts.md`. Confirm bare `https://github.com/idnotbe/prd-creator.git` source form. The entry MUST NOT include `ref` or `sha` -- both are forbidden outright by REQ-PLUGIN-ENTRY-002 (ADR-002). Any exception requires a prior amendment to the requirements document and/or a new ADR; it cannot be approved inside this plan.
- [v] (Optional) The entry MAY include a `version` field. `version` is INDEPENDENTLY OPTIONAL per REQ-PLUGIN-ENTRY-001 -- it is opt-in metadata, NOT a pin. Setting `version` does not constrain which upstream commit is fetched; the bare-`url` source form still tracks the default branch on every pull. This plan omits `version` by default.
- [v] Run `claude plugin validate .` AND `bash tests/validate_marketplace.sh` -- BOTH must exit 0 before proceeding to Phase 2.

## Phase 2: Update README Catalog

- [v] Insert the `prd-creator` row into the README catalog table at the correct alphabetical position matching `.claude-plugin/marketplace.json` (REQ-PLUGIN-ENTRY-005). Name and description MUST be verbatim copies of the manifest entry. Use the row text from `temp/0005-onboard-prd-creator-phase0-drafts.md`.

## Phase 3: Update Architecture Docs

- [v] Insert the `prd-creator` entry into `docs/architecture/components.md` Section 2 (catalog enumeration) at the correct alphabetical position matching `.claude-plugin/marketplace.json` (REQ-PLUGIN-ENTRY-005). Use the bullet text from `temp/0005-onboard-prd-creator-phase0-drafts.md`.
- [v] If the addition exercises a previously-unused property of the manifest (e.g., first plugin to use a non-trivial `keywords` field), note it in `docs/architecture/decisions.md` as a follow-up ADR or as an addendum to the existing relevant ADR. (Expectation: nothing new; `category`/`tags`/`homepage` are already in use by both v1 entries.)

## Phase 4: Validate (two-layer gate)

- [v] Run `claude plugin validate .` -- must exit 0. (Built-in baseline schema check.)
- [v] Run `bash tests/validate_marketplace.sh` -- must exit 0. (Hub-policy check; CHECK-13 enforces metadata-only entries per REQ-HYGIENE-002.) BOTH validators must pass before proceeding -- the built-in validator does NOT enforce the hub's no-inline-components policy because the schema permits those fields.
- [v] Manual smoke test: from a clean Claude Code session, run `/plugin marketplace add idnotbe/claude-plugins` (or `/plugin marketplace update idnotbe` if already added) and verify `prd-creator` appears in `/plugin install` and installs cleanly.

## Phase F-1: Docs Sync Gate

- [v] Verify README catalog list, `docs/architecture/components.md` Section 2, and `marketplace.json` are in lockstep (order + names + descriptions identical for `prd-creator`).
- [v] Re-run `claude plugin validate .` AND `bash tests/validate_marketplace.sh`.
- [v] If any in-flight plan is touched (e.g., 0003-onboard-deepscan or 0004-onboard-humanizer staged the same alphabetical neighborhood), add a cross-plan impact warning per `action-plans/README.md`.

## Phase F: Commit & Push

- [ ] Frontmatter -> `status: done`, update `progress` summary.
- [ ] Move plan file to `_done/`: `git mv action-plans/0005-onboard-prd-creator.md action-plans/_done/0005-onboard-prd-creator.md`.
- [ ] `git add` only the touched files (manifest + README + components.md + plan file + eligibility/draft artifacts if preserved).
- [ ] `git commit` with a message naming the plugin added (`feat(catalog): onboard prd-creator` or similar).
- [ ] `git push` (only when explicitly authorized).

## Out of Scope for This Plan

- Onboarding `deepscan` or `humanizer` -- handled by sibling plans `0003-onboard-deepscan.md` and `0004-onboard-humanizer.md`.
- Schema changes to `marketplace.json` (new metadata fields, new source forms): handle via a separate plan that updates `docs/requirements/functional.md`, `tests/validate_marketplace.sh`, and the architecture docs together.
- Removing or deprecating an existing plugin entry: covered by REQ-PLUGIN-ENTRY-006 in a future dedicated plan.

## Notes

- Entry uses metadata fields only: `name`, `description`, `source`, `category`, `tags`, `homepage`. No inline `commands`, `hooks`, `mcpServers`, `lspServers`, `agents`, `skills`, `setup`, `strict`.
- Description on the hub entry is a verbatim copy of the upstream `plugin.json.description`.
- If the eligibility check unexpectedly fails (e.g., the upstream is force-pushed and `plugin.json` disappears), set `status: blocked` with the unblock condition (`upstream idnotbe/prd-creator re-publishes .claude-plugin/plugin.json`) and a next review date.
