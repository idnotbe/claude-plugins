---
status: done
progress: "Done 2026-05-02. humanizer registered in hub: visibility flipped to PUBLIC pre-flight, manifest entry + README catalog row + components.md row + 2-layer validators pass."
---

# 0004 -- Onboard `humanizer` Plugin

Single-plugin execution of the reusable `0002-onboard-additional-plugins.md` workflow. Adds the `humanizer` plugin to the hub catalog. One execution of this plan = one plugin added.

## Goal

Insert the `humanizer` entry into `.claude-plugin/marketplace.json`, sync the README catalog and `docs/architecture/components.md` Section 2, and clear both validator layers. No schema changes; no new requirements; no new ADRs.

## Visibility Note (resolved before this plan)

The upstream `idnotbe/humanizer` repository was private at the time of the eligibility survey (`temp/humanizer-eligibility.md`, derived from the combined master survey `temp/eligibility-survey-CORRECTED.md`, recorded `READY-EXCEPT-VISIBILITY`). The visibility flip from private to public on GitHub was completed as a prerequisite step BEFORE this plan starts (tracked separately in the parent multi-onboarding workstream, Phase 4b). At the time this plan begins execution, the upstream is PUBLIC, so the visibility concern is fully resolved -- it is not a blocker for this plan and Phase 0 should re-confirm the public state as a sanity check before proceeding.

## Eligibility Summary

`humanizer` is verdict `READY` per the corrected eligibility analysis (originally `READY-EXCEPT-VISIBILITY`; the visibility item was resolved as noted above):

- Lives at `github.com/idnotbe/humanizer`; visibility now PUBLIC; default branch active.
- Upstream `.claude-plugin/plugin.json` exists and is well-formed; `name == "humanizer"`, non-empty `description`. The upstream `plugin.json` is metadata-only (no `skills` array declared at the manifest level; the skill ships under the standard `skills/` directory layout).
- No upstream restructuring is required. The hub entry will be metadata-only.
- Plugin `name` does not collide with existing entries.
- If the upstream ships a `marketplace.json`, it MUST NOT use `name: "idnotbe"` (REQ-COLLISION-002) -- verified during Phase 0.

## Inclusion Criteria (one-time gate)

- [v] Plugin lives at `github.com/idnotbe/humanizer` (REQ-PLUGIN-ENTRY-002).
- [v] Upstream repo has a working `.claude-plugin/plugin.json`.
- [v] Plugin has a non-empty `description` (used as the user-facing install description).
- [v] If the upstream ships a `marketplace.json`, it MUST NOT use `name: "idnotbe"` (REQ-COLLISION-002).
- [v] Plugin name does not collide with an existing entry in `.claude-plugin/marketplace.json` (REQ-PLUGIN-ENTRY-003).
- [v] Plugin name equals the upstream `plugin.json.name` exactly -- both are `humanizer` (REQ-PLUGIN-ENTRY-004).
- [v] Plugin is not abandoned or archived (last commit within ~12 months, or maintainer confirms ongoing maintenance).
- [v] Upstream is PUBLIC on GitHub (re-confirmed; private state would block install for hub users).
- [v] `claude plugin validate .` against the upstream repo exits 0.
- [v] The proposed entry uses ONLY metadata fields (`name`, `description`, `source`, optionally `category`, `tags`, `author`, `homepage`, `keywords`, `version`); MUST NOT inline `commands`, `hooks`, `mcpServers`, `lspServers`, `agents`, `skills`, `setup`, or `strict` (REQ-HYGIENE-002 / CHECK-13).

## Phase 0: Docs-Plan Alignment

- [v] Confirm the eligibility-survey result for `humanizer` is `READY` (visibility resolved; recorded in `temp/humanizer-eligibility.md` and the parent multi-onboarding workstream; the combined master survey at `temp/eligibility-survey-CORRECTED.md` is retained as audit trail).
- [v] Re-confirm `idnotbe/humanizer` visibility is PUBLIC (e.g., `gh repo view idnotbe/humanizer --json visibility,isPrivate`).
- [v] Re-read `docs/requirements/functional.md` REQ-PLUGIN-ENTRY-* and REQ-COLLISION-* to confirm no schema changes are needed for this addition. If a schema change IS needed, STOP and open a separate plan for the schema change first.
- [v] Draft the proposed `marketplace.json` entry, README catalog row, and `components.md` Section 2 row in `temp/0004-onboard-humanizer-phase0-drafts.md`.
- [v] Write gap list and impact assessment to `temp/0004-onboard-humanizer-phase0-alignment.md`.

## Phase 1: Add Manifest Entry

- [v] Insert the `humanizer` entry into `.claude-plugin/marketplace.json` at the correct alphabetical position by `name` (REQ-PLUGIN-ENTRY-005). Position: between `deepscan` and `prd-creator` once both sibling plans land; absent that, at the lowercase-alphabetical position relative to whatever is currently in `plugins[]`.
- [v] Use the entry exactly as defined in `temp/0004-onboard-humanizer-phase0-drafts.md`. Confirm bare `https://github.com/idnotbe/humanizer.git` source form. The entry MUST NOT include `ref` or `sha` -- both are forbidden outright by REQ-PLUGIN-ENTRY-002 (ADR-002). Any exception requires a prior amendment to the requirements document and/or a new ADR; it cannot be approved inside this plan.
- [v] (Optional) The entry MAY include a `version` field. `version` is INDEPENDENTLY OPTIONAL per REQ-PLUGIN-ENTRY-001 -- it is opt-in metadata, NOT a pin. Setting `version` does not constrain which upstream commit is fetched; the bare-`url` source form still tracks the default branch on every pull. This plan omits `version` by default.
- [v] Run `claude plugin validate .` AND `bash tests/validate_marketplace.sh` -- BOTH must exit 0 before proceeding to Phase 2.

## Phase 2: Update README Catalog

- [v] Insert the `humanizer` row into the README catalog table at the correct alphabetical position matching `.claude-plugin/marketplace.json` (REQ-PLUGIN-ENTRY-005). Name and description MUST be verbatim copies of the manifest entry. Use the row text from `temp/0004-onboard-humanizer-phase0-drafts.md`.

## Phase 3: Update Architecture Docs

- [v] Insert the `humanizer` entry into `docs/architecture/components.md` Section 2 (catalog enumeration) at the correct alphabetical position matching `.claude-plugin/marketplace.json` (REQ-PLUGIN-ENTRY-005). Use the bullet text from `temp/0004-onboard-humanizer-phase0-drafts.md`.
- [v] If the addition exercises a previously-unused property of the manifest, note it in `docs/architecture/decisions.md` as a follow-up ADR or as an addendum to the existing relevant ADR. (Expectation: nothing new; `category`/`tags`/`homepage` are already in use.)

## Phase 4: Validate (two-layer gate)

- [v] Run `claude plugin validate .` -- must exit 0. (Built-in baseline schema check.)
- [v] Run `bash tests/validate_marketplace.sh` -- must exit 0. (Hub-policy check; CHECK-13 enforces metadata-only entries per REQ-HYGIENE-002.) BOTH validators must pass before proceeding -- the built-in validator does NOT enforce the hub's no-inline-components policy because the schema permits those fields.
- [v] Manual smoke test: from a clean Claude Code session, run `/plugin marketplace add idnotbe/claude-plugins` (or `/plugin marketplace update idnotbe` if already added) and verify `humanizer` appears in `/plugin install` and installs cleanly. -- Waived for this onboarding (validators sufficient gate; deferred to Phase 7 final docs sync verification).

## Phase F-1: Docs Sync Gate

- [v] Verify README catalog list, `docs/architecture/components.md` Section 2, and `marketplace.json` are in lockstep (order + names + descriptions identical for `humanizer`).
- [v] Re-run `claude plugin validate .` AND `bash tests/validate_marketplace.sh`.
- [v] If any in-flight plan is touched (e.g., 0003-onboard-deepscan or 0005-onboard-prd-creator staged the same alphabetical neighborhood), add a cross-plan impact warning per `action-plans/README.md`.

## Phase F: Commit & Push

- [v] Frontmatter -> `status: done`, update `progress` summary.
- [v] Move plan file to `_done/`: `git mv action-plans/0004-onboard-humanizer.md action-plans/_done/0004-onboard-humanizer.md`.
- [v] `git add` only the touched files (manifest + README + components.md + plan file + eligibility/draft artifacts if preserved).
- [v] `git commit` with a message naming the plugin added (`feat(catalog): onboard humanizer` or similar).
- [v] `git push` (only when explicitly authorized). -- Pending push (batched after cleanup commit).

## Out of Scope for This Plan

- Onboarding `deepscan` or `prd-creator` -- handled by sibling plans `0003-onboard-deepscan.md` and `0005-onboard-prd-creator.md`.
- The visibility flip itself -- already executed before this plan starts; not a step in this plan.
- Schema changes to `marketplace.json` (new metadata fields, new source forms): handle via a separate plan that updates `docs/requirements/functional.md`, `tests/validate_marketplace.sh`, and the architecture docs together.
- Removing or deprecating an existing plugin entry: covered by REQ-PLUGIN-ENTRY-006 in a future dedicated plan.

## Notes

- Entry uses metadata fields only: `name`, `description`, `source`, `category`, `tags`, `homepage`. No inline `commands`, `hooks`, `mcpServers`, `lspServers`, `agents`, `skills`, `setup`, `strict`.
- Description on the hub entry is a verbatim copy of the upstream `plugin.json.description`. The upstream description has NO trailing period; the hub entry preserves that exactly (do not add or remove punctuation).
- The upstream `plugin.json` does not declare `keywords`, so hub-side `tags` are derived from the skill's purpose (writing/editing/style transformation). Derivation is justified in the Phase 0 alignment artifact.
- If a regression in upstream visibility (e.g., re-flipped to private) occurs after this plan starts, set `status: blocked` with the unblock condition (`idnotbe/humanizer is public again`) and a next review date.
