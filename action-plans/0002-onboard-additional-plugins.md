---
status: not-started
progress: "Not started. Triggered when a new idnotbe plugin candidate is identified."
---

# 0002 -- Onboard Additional Plugins

A repeatable, gated process for adding new `idnotbe`-owned plugins to the hub catalog after launch. One execution of this plan = one plugin added.

## Goal

Define the inclusion criteria and per-plugin workflow so the catalog grows safely:

- No half-broken or non-installable entries land in `marketplace.json`.
- Every addition is verified against the same checklist, not ad-hoc judgement.
- Docs (`README.md`, `docs/architecture/components.md`) and validator (`tests/validate_marketplace.sh`) stay in sync with the manifest after every addition.
- The action is reversible: if eligibility fails, the plugin is shelved with a written explanation in `temp/{repo-name}-eligibility.md`, not silently dropped.

## Inclusion Criteria

Every box MUST be checked before adding a plugin to the catalog. If any box fails, document the failure in `temp/{repo-name}-eligibility.md` and either:

- (a) Block the plan with `status: blocked`, an unblock condition, and a next review date; OR
- (b) Reject and move on -- record the rejection in the eligibility doc.

- [ ] Plugin lives at `github.com/idnotbe/<repo>` (REQ-PLUGIN-ENTRY-002 -- only `idnotbe`-owned URLs).
- [ ] Upstream repo has a working `.claude-plugin/plugin.json` (the v1 hub does not require an upstream `marketplace.json`, but it does require `plugin.json` so Claude Code can resolve metadata).
- [ ] Plugin has a non-empty `description` (used as the user-facing install description).
- [ ] Upstream MUST NOT ship a `.claude-plugin/marketplace.json` (per ADR-007). If the candidate's upstream currently ships one, the onboarding plan must include a removal step before Phase 1 (manifest-add); otherwise re-introducing a per-plugin marketplace would contradict ADR-007.
- [ ] Plugin name does not collide with an existing entry in `.claude-plugin/marketplace.json` (REQ-PLUGIN-ENTRY-003).
- [ ] Plugin name equals the upstream `plugin.json.name` exactly (REQ-PLUGIN-ENTRY-004).
- [ ] Plugin is not abandoned or archived (last commit within ~12 months, or maintainer confirms ongoing maintenance).
- [ ] `claude plugin validate .` against the upstream repo exits 0.
- [ ] The proposed entry uses ONLY metadata fields (`name`, `description`, `source`, optionally `category`, `tags`, `author`, `homepage`, `keywords`, `version`); MUST NOT inline `commands`, `hooks`, `mcpServers`, `lspServers`, `agents`, `skills`, `setup`, or `strict` (REQ-HYGIENE-002 / CHECK-13).

## Candidate Inventory

Known `idnotbe` repos under `/home/idnotbe/projects/`. Default status is `unknown` because no eligibility survey has been run yet. Update each row when a survey lands in `temp/{repo-name}-eligibility.md`.

| Candidate repo        | Status         | Notes                                                 |
|-----------------------|----------------|-------------------------------------------------------|
| `agntpod`             | unknown        | Pending eligibility survey.                           |
| `citizen-agents`      | unknown        | Pending eligibility survey.                           |
| `claude-memory`       | unknown        | Pending eligibility survey.                           |
| `deepscan`            | unknown        | Pending eligibility survey.                           |
| `fractal-wave`        | unknown        | Pending eligibility survey.                           |
| `humanizer`           | unknown        | Pending eligibility survey.                           |
| `marketing-daemon`    | unknown        | Pending eligibility survey.                           |
| `moderation-daemon`   | unknown        | Pending eligibility survey.                           |
| `ops`                 | unknown        | Pending eligibility survey.                           |
| `p-brand`             | unknown        | Pending eligibility survey.                           |
| `prd-creator`         | unknown        | Pending eligibility survey.                           |

Status legend:

- **unknown** -- not yet surveyed.
- **candidate** -- survey passed all inclusion criteria; queued for onboarding.
- **not-a-plugin** -- repo is not a Claude Code plugin (no `.claude-plugin/plugin.json`); excluded permanently.
- **pending-review** -- survey raised a soft concern (abandoned, missing description, etc.); needs a human decision.

## Workflow Per Addition

One execution of this plan = one plugin added. If onboarding multiple plugins, fork this plan into `0003-onboard-<repo-1>.md`, `0004-onboard-<repo-2>.md`, etc. -- do NOT batch them in a single plan, because each addition needs its own validator run and docs-sync gate.

### Phase 0: Docs-Plan Alignment

- [ ] Run inclusion-criteria survey for the candidate repo. Write findings to `temp/{repo-name}-eligibility.md` (one row per criterion, pass/fail/notes).
- [ ] Re-read `docs/requirements/functional.md` REQ-PLUGIN-ENTRY-* and REQ-COLLISION-* to confirm no schema changes are needed for this addition. If a schema change IS needed (e.g., a new source form), STOP and open a separate plan for the schema change first.
- [ ] Draft the proposed `marketplace.json` entry, README catalog row, and `components.md` Section 2 row in `temp/{plan-name}-phase0-drafts.md`.

### Phase 1: Add Manifest Entry

- [ ] Insert the new entry into `.claude-plugin/marketplace.json` at the correct alphabetical position by `name` (REQ-PLUGIN-ENTRY-005).
- [ ] Confirm the entry uses the bare `https://github.com/idnotbe/<repo>.git` source form. The entry MUST NOT include `ref` or `sha` -- both are forbidden outright by REQ-PLUGIN-ENTRY-002 (ADR-002). Any exception requires a prior amendment to the requirements document and/or a new ADR; it cannot be approved inside this plan.
- [ ] (Optional) The entry MAY include a `version` field. `version` is INDEPENDENTLY OPTIONAL per REQ-PLUGIN-ENTRY-001 -- it is opt-in metadata, NOT a pin. Setting `version` does not constrain which upstream commit is fetched; the bare-`url` source form still tracks the default branch on every pull. Use `version` only as a maintainer-facing change marker if you want one; omit it otherwise.
- [ ] Run `claude plugin validate .` AND `bash tests/validate_marketplace.sh` -- BOTH must exit 0 before proceeding to Phase 2 (lifecycle rule: any phase that touches `marketplace.json` must clear the two-layer gate before closing).

### Phase 2: Update README Catalog

- [ ] Insert the new plugin into the README catalog list at the correct alphabetical position matching `.claude-plugin/marketplace.json` (REQ-PLUGIN-ENTRY-005). Name and description MUST be verbatim copies of the manifest entry.

### Phase 3: Update Architecture Docs

- [ ] Insert the new entry into `docs/architecture/components.md` Section 2 (catalog enumeration) at the correct alphabetical position matching `.claude-plugin/marketplace.json` (REQ-PLUGIN-ENTRY-005).
- [ ] If the addition exercises a previously-unused property of the manifest (e.g., first plugin to use a non-trivial `keywords` field), note it in `docs/architecture/decisions.md` as a follow-up ADR or as an addendum to the existing relevant ADR.

### Phase 4: Validate (two-layer gate)

- [ ] Run `claude plugin validate .` -- must exit 0. (Built-in baseline schema check.)
- [ ] Run `bash tests/validate_marketplace.sh` -- must exit 0. (Hub-policy check; CHECK-13 enforces metadata-only entries per REQ-HYGIENE-002.) BOTH validators must pass before proceeding -- the built-in validator does NOT enforce the hub's no-inline-components policy because the schema permits those fields.
- [ ] Manual smoke test: from a clean Claude Code session, run `/plugin marketplace add idnotbe/claude-plugins` (or `/plugin marketplace update idnotbe` if already added) and verify the new plugin appears in `/plugin install` and installs cleanly.

### Phase F-1: Docs Sync Gate

- [ ] Verify README catalog list, `docs/architecture/components.md` Section 2, and `marketplace.json` are in lockstep (order + names + descriptions identical).
- [ ] Re-run `claude plugin validate .` AND `bash tests/validate_marketplace.sh`.
- [ ] If any in-flight plan is touched (e.g., another onboarding plan staged the same repo), add a cross-plan impact warning per `action-plans/README.md`.

### Phase F: Commit & Push

- [ ] Frontmatter -> `status: done`, update `progress` summary.
- [ ] Move plan file to `_done/`.
- [ ] `git add` only the touched files (manifest + README + components.md + plan file + eligibility doc if preserved).
- [ ] `git commit` with a message naming the plugin added.
- [ ] `git push` (only when explicitly authorized).

## Out of Scope for This Plan

- **Removing or deprecating an existing plugin entry**: covered by REQ-PLUGIN-ENTRY-006. When that situation first arises, open a separate plan (e.g., `00NN-deprecate-<plugin>.md`) -- the rollback semantics, user-communication, and validator-update steps are different enough to warrant their own checklist.
- **Renaming an existing plugin entry**: also out of scope; will be handled by a future dedicated plan when first needed (the rename touches REQ-PLUGIN-ENTRY-003 / -004 simultaneously and breaks existing user installs).
- **Onboarding non-`idnotbe` plugins**: prohibited in v1 by REQ-PLUGIN-ENTRY-002. A future scope expansion would require an ADR amendment first.
- **Schema changes to `marketplace.json`** (new metadata fields, new source forms): handle via a separate plan that updates `docs/requirements/functional.md`, `tests/validate_marketplace.sh`, and the architecture docs together.

## Notes

- This plan is reusable in shape but should be forked per plugin (one plan = one plugin) to keep the audit trail per addition clean.
- If a candidate's eligibility survey takes longer than expected (e.g., upstream needs a `plugin.json` written first), set `status: blocked` with the unblock condition (`upstream <repo> publishes .claude-plugin/plugin.json`) and a next review date.
