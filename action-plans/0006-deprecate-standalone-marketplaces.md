---
status: not-started
progress: "Not started. Will deprecate the standalone .claude-plugin/marketplace.json files in idnotbe/claude-code-guardian and idnotbe/vibe-check. Hub at idnotbe/claude-plugins becomes single source of truth."
---

# 0006 -- Deprecate Standalone Marketplace Manifests

End the dual-install-path policy. The hub at `idnotbe/claude-plugins` becomes the single source of truth for installing any `idnotbe`-owned plugin. The two upstream repos (`claude-code-guardian`, `vibe-check`) drop their standalone `.claude-plugin/marketplace.json` files. ADR-004 is superseded by a new ADR-007 (per standard ADR convention: ADR-004's `Status` flips to `Superseded by ADR-007` and a callout line is added under its heading; its body content remains verbatim as the historical record). REQ-INSTALL-FLOW-002 is rewritten to match.

## Goal

Make the hub the only documented install path. Concretely:

- Remove `.claude-plugin/marketplace.json` from `idnotbe/claude-code-guardian` and `idnotbe/vibe-check`.
- Record the policy reversal as ADR-007 in `docs/architecture/decisions.md`. ADR-004's body (Context / Decision / Consequences / Alternatives considered / Linked) is preserved verbatim as a historical record. Two edits are PERMITTED on ADR-004: (i) flip its `Status` field per the standard ADR convention from `Accepted` to `Superseded by ADR-007 (<date>)`, and (ii) add a single `> Superseded by: ADR-007 (<date>).` callout line immediately under the `## ADR-004:` heading. Either, both, or just (ii) is acceptable; the choice is recorded in Phase 0 drafts.
- Rewrite REQ-INSTALL-FLOW-002 in `docs/requirements/functional.md` to a single-path-only requirement, with the previous text quoted under ADR-007's "Context" so the historical record is preserved.
- Add a short "Migration notes" section to the hub `README.md` walking users from the old per-plugin install path to the hub path.
- Both validators continue to pass after the change (the hub manifest itself is not modified by this plan).

## Background

ADR-004 (Phase 6 of the original hub bootstrap) decided to KEEP the per-plugin `marketplace.json` files in each upstream so existing users would not break. That decision was made before the hub catalog had been validated end-to-end. Since then, all five plugins have been onboarded and verified through the hub:

- `claude-code-guardian` (hub commit `ac71ba1`)
- `deepscan` (`73a4e08`)
- `humanizer` (`9a17589`)
- `prd-creator` (`5f79c3e`)
- `vibe-check` (`35721c3`, hub at `56fa09a`)

Keeping two install paths now imposes a recurring drift cost (two manifests per plugin describing the same thing, with no automated cross-check) and a documentation cost (every install instruction must hedge between the two paths). The simplification is to retire the standalone path and make the hub canonical. ADR-004's "manual cross-repo discipline" trade-off is exactly the cost we are eliminating.

## Inclusion / Pre-conditions

Verify all of the following before starting Phase 1:

- [ ] Hub manifest `.claude-plugin/marketplace.json` lists all five current plugins (`claude-code-guardian`, `deepscan`, `humanizer`, `prd-creator`, `vibe-check`) in alphabetical order. Both layers of validation pass: `claude plugin validate .` exit 0 AND `bash tests/validate_marketplace.sh` exit 0.
- [ ] All five upstream READMEs document the hub install pattern (`/plugin marketplace add idnotbe/claude-plugins` + `/plugin install <name>@idnotbe`). This was already completed during the per-plugin onboarding plans (0003--0005 plus 0001's bootstrap pair); re-confirm at Phase 0.
- [ ] Both deletion targets currently exist: `/home/idnotbe/projects/claude-code-guardian/.claude-plugin/marketplace.json` AND `/home/idnotbe/projects/vibe-check/.claude-plugin/marketplace.json`. (If either is already absent, the corresponding sub-step in Phase 2 or Phase 3 becomes a no-op; mark accordingly.)

## Scope

### In scope

1. **ADR-007**: New ADR appended at the end of `docs/architecture/decisions.md`. Records the supersede decision, trade-offs, and references to the executing phases of this plan.
2. **ADR-004 supersede annotations**: Two annotation edits are PERMITTED on ADR-004 (per standard ADR convention): (i) flip its `Status` field from `Accepted` to `Superseded by ADR-007 (<commit-date>)`; (ii) add exactly one callout line at the top of ADR-004 (immediately after its title): `> Superseded by: ADR-007 (<commit-date>).`. Both, either, or just (ii) is acceptable -- Phase 0 drafts records the choice. ADR-004's `Context`, `Decision`, `Consequences`, `Alternatives considered`, and `Linked` body sections are NOT edited. The historical record (the original rationale, trade-offs, and constraints) stands verbatim.
3. **REQ-INSTALL-FLOW-002 rewrite**: Replace the body of REQ-INSTALL-FLOW-002 in `docs/requirements/functional.md` with a single-path-only statement. The previous text is preserved as a quoted block in ADR-007's "Context" section, not in the requirements file.
3a. **REQ-INSTALL-FLOW-003 rewrite**: Replace the body of REQ-INSTALL-FLOW-003 in `docs/requirements/functional.md` (currently at line ~106 of `functional.md`). The current text mandates "explicitly preserving the single-plugin path as a still-supported alternative", which directly contradicts ADR-007's supersede. Rewrite to a hub-only recommendation; exact replacement body is fixed in Phase 0 drafts.
3b. **Hub docs surfaces consistency sweep**: Several hub docs surfaces still describe the legacy single-plugin install path or the dual-path policy as live. Update `docs/requirements/overview.md` (line ~17 -- "Each upstream plugin repository: continues to own its own `plugin.json` and (optionally) its own `marketplace.json` for the single-plugin install path." plus line ~35 "Out of Scope: Removing the per-plugin `marketplace.json` files from upstream repositories. Both install paths are supported deliberately." plus line ~42 "The hub never collides with the per-plugin `marketplace.json` install path..."), `docs/requirements/functional.md` REQ-COLLISION-002 (lines 122--125 -- the rule presupposes upstream `marketplace.json` files exist, which is no longer the case post-ADR-007), `docs/architecture/overview.md` (line ~12 -- "(optionally) its own `.claude-plugin/marketplace.json` for the single-plugin install path"), and `docs/architecture/components.md` Section 2 vibe-check entry (line ~57 -- "and a per-plugin `marketplace.json` (single-plugin install path; that file's marketplace `name` is `vibe-check`).") AND Section 5 "Dual install paths" (lines ~99--113, the entire section) AND Section 7 README description (line ~153 -- "notes the single-plugin path as a still-supported alternative (REQ-INSTALL-FLOW-003)"). Each location: remove or reframe the standalone-path mention. Exact before/after text captured in Phase 0 drafts.
3c. **Hub README dual-install cleanup (full sweep)**: The hub `README.md` carries multiple traces of the dual-install policy that all need cleanup in lockstep, not just the obvious "Alternative" section. Required cleanup locations (Phase 0 drafts records the exact line ranges and the exact treatment per location):
   - "Alternative: single-plugin install" section (~line 55--76) -- pure deletion vs. one-paragraph migration-pointer rewrite. Phase 0 selects.
   - "Adding a plugin to the catalog" section (~line 92, specifically the parenthesized inclusion criteria phrase "no `name: idnotbe` collision in the upstream marketplace") -- the upstream `marketplace.json` no longer exists post-ADR-007, so this collision check is meaningless as a forward-looking criterion. Reframe or remove the parenthesized clause.
   - Any other standalone-path references found by `grep -n "marketplace add idnotbe/vibe-check\|marketplace add idnotbe/claude-code-guardian\|marketplace add idnotbe-security\|@vibe-check\|@idnotbe-security\|single-plugin install\|standalone marketplace\|per-plugin marketplace" README.md` -- each hit recorded in the drafts map with its disposition.
   - The new "Migration notes" section is added in addition to (not as a replacement for) these cleanups.
4. **claude-code-guardian cleanup**: `git rm` of `.claude-plugin/marketplace.json` in that repo. Review the `KNOWN-ISSUES.md` PV-04 entry (the assumption "`.claude-plugin/marketplace.json` enables self-hosted marketplace installation" is now historical because the file is being removed). Decide between marking the entry as `RESOLVED` (preferred for traceability) or removing it outright; record the decision and rationale in `temp/0006-...-phase0-alignment.md`.
5. **vibe-check cleanup**: `git rm --ignore-unmatch` of `.claude-plugin/marketplace.json` in that repo. Remove or rewrite the standalone-marketplace annotations across the 5 enumerated locations introduced during the Phase 6 hub onboarding:
   - `README.md` line 71 (file-tree comment for `marketplace.json`).
   - `CLAUDE.md` line 13 (file-tree comment for `marketplace.json`).
   - `docs/architecture/components.md` lines ~64--70 (note about the legacy direct-install route) and the cross-link near line 88.
   - `docs/architecture/decisions.md` ADR-004 section (lines ~127--165) -- update to reflect supersede, but the file is currently untracked (see Risks).
   - `docs/requirements/non-functional-and-constraints.md` lines ~14--15.
6. **Hub README "Migration notes"**: A short new section on `README.md` (one paragraph + one fenced code block with the migrate-from-old-path command sequence). Targeted at users who installed a plugin via `/plugin marketplace add idnotbe/<plugin>` before this change and now need to switch to the hub path.
7. **Two-layer validators**: Re-run both validators after the documentation changes land. The hub manifest is unchanged, so both should still exit 0; the goal is to confirm no validator regression was introduced by the doc edits.
8. **`tests/test_scenarios.md` updates**: Rewrite or remove Scenario 2 ("Single-plugin install path coexistence", lines ~46--70) and Scenario 3 ("Marketplace name collision", lines ~76--99). Both scenarios depend on the legacy single-plugin install path being live (Scenario 2 is the affirmative test for that path; Scenario 3 step 8 also exercises per-plugin marketplaces `vibe-check` and `idnotbe-security`). Phase 0 drafts captures the exact disposition per scenario: rewrite-to-verify-deprecation-effects (e.g. Scenario 2 becomes "verify the standalone path is gone"; Scenario 3 may shrink to a hub-only collision test) vs. outright removal. The Coverage map at the bottom of the file is also updated accordingly.
9. **`action-plans/0002-onboard-additional-plugins.md` Inclusion Criteria update**: 0002's Inclusion Criteria section currently includes a row that requires the candidate plugin's upstream `marketplace.json` to NOT use `name: "idnotbe"` (REQ-COLLISION-002 collision check). Post-ADR-007, the canonical hub policy is that upstreams DO NOT ship a standalone `marketplace.json` at all. Update 0002's Inclusion Criteria: drop the upstream-marketplace-collision row (or reframe to a stricter "candidate's upstream MUST NOT ship a standalone `.claude-plugin/marketplace.json`" forward-looking criterion). Phase 0 drafts records the exact row-edit text. This is a template change that affects every future onboarding plan derived from 0002.

### Out of scope

- **New validator CHECK to forbid standalone `marketplace.json` files in catalog plugins**: A natural follow-on, but requires either upstream-fetch capability in the validator (currently absent by design) or a coordinated convention. Tracked separately; do NOT add to `tests/validate_marketplace.sh` in this plan.
- **GitHub Releases, CHANGELOG infrastructure, or maintainer broadcast (Slack, mailing list, etc.)**: User communication for this change is limited to the hub README "Migration notes" section. Anything heavier (a tagged release, a pinned issue, an email) is a separate workstream.
- **Dropping the per-plugin `plugin.json`**: Out of scope. The upstream `plugin.json` is what Claude Code's loader resolves to actually install the plugin, so it stays. Only the standalone `marketplace.json` (which advertises the upstream as its own one-plugin marketplace) is being removed.

## Phases

### Phase 0: Docs-Plan Alignment (GATE -- must complete before any execution)

- [ ] Read current state of: hub `README.md`, hub `docs/architecture/decisions.md` (full), hub `docs/requirements/functional.md` REQ-INSTALL-FLOW-* and REQ-COLLISION-*, both upstreams' `marketplace.json` files, both upstreams' `README.md`, vibe-check `docs/` (note current tracking state -- see Risks), and `claude-code-guardian/KNOWN-ISSUES.md`. Build a complete picture of every mention of "ADR-004", "legacy direct-install", "standalone marketplace", "single-plugin install path", or "per-plugin marketplace.json" across all three repos.
- [ ] Write `temp/0006-deprecate-standalone-marketplaces-phase0-alignment.md`:
  - Gap list: every doc location citing ADR-004 or the dual-path policy.
  - Impact assessment per gap: what changes, what stays, why.
  - Idempotency analysis per phase step: ADR-007 insertion is non-idempotent (skip if a record with that ID is already present); ADR-004 supersede line addition is non-idempotent (skip if line already exists); REQ-INSTALL-FLOW-002 rewrite is non-idempotent (compare existing body against the new draft before replacing); `git rm` of an absent file is idempotent under `git rm --ignore-unmatch`; KNOWN-ISSUES.md PV-04 mark/remove is non-idempotent.
- [ ] Write `temp/0006-deprecate-standalone-marketplaces-phase0-drafts.md`. The drafts file MUST contain, at minimum, the following enumerated deliverables (one section per bullet, headers explicit):
  - **ADR-007 full body** -- Status / Context / Decision / Consequences / Alternatives considered / Linked. Insertable verbatim at the bottom of `docs/architecture/decisions.md` with no further wordsmithing in Phase 1.
  - **ADR-004 supersede annotations** -- record the chosen treatment: (i) `Status` field flip from `Accepted` to `Superseded by ADR-007 (<commit-date>)` (RECOMMENDED -- matches standard ADR convention); AND/OR (ii) the exact callout line text (e.g. `> Superseded by: ADR-007 (<commit-date>).`) and its insertion point (immediately under the `## ADR-004:` heading line). At least (ii) is required so the supersede is visible at the top of the entry; (i) is OPTIONAL but RECOMMENDED.
  - **REQ-INSTALL-FLOW-002 rewrite** -- before-block (current text quoted) AND after-block (new single-path-only body, including the "Rationale:" and "Verified by:" lines).
  - **REQ-INSTALL-FLOW-003 rewrite** (per Fix #1) -- before-block (current text quoted; note the "still-supported alternative" clause that is being removed) AND after-block (new hub-only body, including "Rationale:" and "Verified by:" lines).
  - **Hub docs surfaces consistency sweep map** (per Fix #1, item 3b) -- one sub-bullet per location, EACH with (a) the current line-or-range, (b) the exact text to remove, (c) the exact text (if any) to keep or substitute. The required locations:
    - `docs/requirements/overview.md` line ~17 (Stakeholders item: per-plugin marketplace.json mention).
    - `docs/requirements/overview.md` line ~35 (Out of Scope: "Removing the per-plugin `marketplace.json` files... Both install paths are supported deliberately." -- needs reframing; the hub now requires removal).
    - `docs/requirements/overview.md` line ~42 (Success Criteria item 3 referencing per-plugin install path).
    - `docs/requirements/functional.md` REQ-COLLISION-002 (lines 122--125) -- the rule presupposes upstream `marketplace.json` exists. Decide: rewrite to a "no longer applicable post-ADR-007" historical note, or simplify to "any future upstream `marketplace.json` MUST NOT use `name: idnotbe`" forward-only form. Phase 0 selects.
    - `docs/architecture/overview.md` line ~12 (Spokes paragraph -- single-plugin install path mention).
    - `docs/architecture/components.md` Section 2 vibe-check entry line ~57 (per-plugin marketplace.json mention).
    - `docs/architecture/components.md` Section 5 "Dual install paths -- a deliberate architecture choice" lines ~99--113 -- entire section. Decide: pure deletion vs. rewrite to a "Historical: dual install paths (superseded by ADR-007)" archival section. Phase 0 selects.
    - `docs/architecture/components.md` Section 7 line ~153 README description (single-plugin path as still-supported alternative).
  - **Hub README "Migration notes" section** -- full text: heading level (e.g. `## Migration notes`), single paragraph explaining the supersede event and target audience (users who installed via `/plugin marketplace add idnotbe/<plugin>` before this change), AND a fenced code block containing the exact migration command sequence. CRITICAL: `/plugin marketplace remove` takes the registered marketplace `name` (an alias), not the `owner/repo` form. The two upstreams use distinct marketplace names: `claude-code-guardian` upstream registers as `idnotbe-security`; `vibe-check` upstream registers as `vibe-check`. The exact code blocks:

    ```
    # Existing standalone install via claude-code-guardian:
    /plugin marketplace remove idnotbe-security
    /plugin marketplace add idnotbe/claude-plugins
    /plugin install claude-code-guardian@idnotbe

    # Existing standalone install via vibe-check:
    /plugin marketplace remove vibe-check
    /plugin marketplace add idnotbe/claude-plugins
    /plugin install vibe-check@idnotbe
    ```

    Provide one block per affected upstream marketplace name (`idnotbe-security`, `vibe-check`).
  - **Hub README cleanup map** (per Fix #4) -- consolidates every README edit triggered by ADR-007 in a single saturating list. EACH entry records (a) the line range, (b) the current text, (c) the exact replacement text or "DELETE verbatim". Required entries:
    - "Migration notes" section insertion -- target heading level, target insertion point relative to existing sections, full body (paragraph + fenced code block per affected upstream).
    - "Alternative: single-plugin install" section (~line 55--76) -- pure deletion vs. rewrite to a hub-only "Migration pointer" section.
    - "Adding a plugin to the catalog" section (~line 92) -- specifically the parenthesized inclusion criteria phrase "no `name: idnotbe` collision in the upstream marketplace". The upstream `marketplace.json` no longer exists post-ADR-007, so this clause is meaningless; reframe (e.g. drop the parenthetical, or replace with "unique plugin name in the hub catalog") or remove.
    - Any other standalone-path references -- the raw output of `grep -n "marketplace add idnotbe/vibe-check\|marketplace add idnotbe/claude-code-guardian\|marketplace add idnotbe-security\|@vibe-check\|@idnotbe-security\|single-plugin install\|standalone marketplace\|per-plugin marketplace" README.md` is included verbatim in the drafts file, with a per-line disposition. Phase 1 has nothing to invent.
  - **claude-code-guardian `KNOWN-ISSUES.md` PV-04 treatment** -- explicit decision: mark `RESOLVED` with a one-line note pointing at hub plan 0006, OR delete the entry outright. Include the exact new text (or "DELETE entire PV-04 section, lines NN--MM").
  - **claude-code-guardian internal-docs cleanup map** (per Fix #3) -- explicit list of EVERY file/line in `idnotbe/claude-code-guardian` that references the standalone marketplace path. At minimum: `.claude-plugin/marketplace.json` itself (the deletion target), README install hints if any (mention "marketplace add idnotbe/claude-code-guardian" or "marketplace add idnotbe-security" or "@idnotbe-security"), `KNOWN-ISSUES.md` PV-04 (covered separately above; cross-link here), and any other docs/comments. Each location MUST record: (a) what to remove (b) what to keep or rewrite. Built from `grep -rn "marketplace add idnotbe/claude-code-guardian\|marketplace add idnotbe-security\|@idnotbe-security\|standalone marketplace\|legacy direct-install" .` plus a follow-up review of any stale ADR or plan-file mentions in the upstream `action-plans/` tree. The list MUST be saturating (every grep hit is either listed or explicitly marked "no edit -- historical/in `_done/`"); Phase 2 has nothing to invent.
  - **vibe-check internal-docs cleanup map** -- one sub-bullet per file location, EACH with (a) the current line-or-range, (b) the exact text to remove, (c) the exact text (if any) to keep or substitute:
    - `vibe-check/README.md` line 71 (file-tree row for `marketplace.json`).
    - `vibe-check/CLAUDE.md` line 13 (file-tree row for `marketplace.json`).
    - `vibe-check/docs/architecture/components.md` lines ~64--70 (legacy direct-install note) and ~88 (cross-link).
    - `vibe-check/docs/architecture/decisions.md` ADR-004 section, lines ~127--165 (the upstream's own ADR-004; mirrors the hub's supersede semantics).
    - `vibe-check/docs/requirements/non-functional-and-constraints.md` lines ~14--15 (legacy direct-install retention clause).
  - **vibe-check `docs/` git-staging strategy** -- explicit decision for Phase 3: at the time of writing, `vibe-check/docs/` is git-untracked. Decide between (i) including `docs/` in this plan's vibe-check commit (commits the docs tree alongside the cleanup), or (ii) editing `docs/` in the working tree only and explicitly excluding it from `git add`. Record the decision in this drafts file so Phase 3 does not improvise.
  - **`action-plans/0002-onboard-additional-plugins.md` Inclusion Criteria update** (per Fix #5) -- before-block (current row text quoted, including the row's wording about "no `name: idnotbe` collision in the candidate's upstream `marketplace.json`") AND after-block (either DELETE the row outright with surrounding rows preserved, OR rewrite to "candidate's upstream MUST NOT ship a `.claude-plugin/marketplace.json`" forward-only). Include the exact line range from `action-plans/0002-onboard-additional-plugins.md` (~line 22) so Phase 1 has nothing to invent.
  - **`tests/test_scenarios.md` Scenario 2 + Scenario 3 disposition** (per Fix #2) -- explicit decision per scenario: REWRITE (with the exact new body, including Steps / Expected / Verifies sections) OR DELETE (with the exact line range to remove). Scenario 2 currently affirms the dual-install coexistence (lines ~46--70); the natural rewrite verifies the standalone path is GONE (e.g. attempting `/plugin marketplace add idnotbe/vibe-check` after Phase 2/3 land returns no manifest). Scenario 3 currently exercises `vibe-check` and `idnotbe-security` per-plugin marketplaces in step 8 (lines ~76--99); the natural rewrite shrinks to a hub-only `name: "idnotbe"` collision test using two fixtures that both declare that name. Also update the Coverage map at the bottom of `test_scenarios.md` to match the new scenario set.
  - **Per-upstream grep results** -- the raw `grep -rn` output across each upstream repo showing every line cited in the location maps above; serves as the verification anchor for "we caught every annotation".
- [ ] **User gate (recommended)**: pause for explicit user review of the ADR-007 body and the new REQ-INSTALL-FLOW-002 text before starting Phase 1. The supersede is structurally significant; a written-then-approved draft is safer than an in-flight draft.

### Phase 1: Hub-side ADR + REQ amendment

- [ ] Append ADR-007 to `docs/architecture/decisions.md` using the body drafted in Phase 0. Maintain the existing ADR layout conventions (status, context, decision, consequences, alternatives, linked). If a heading `## ADR-007:` already exists in the file (idempotent re-run -- e.g. Phase 1 was partially run earlier), skip this step.
- [ ] Apply the ADR-004 supersede annotations per Phase 0 drafts: at minimum, add the callout line (`> Superseded by: ADR-007 (<commit-date>).`) immediately under the `## ADR-004:` heading; if Phase 0 also chose to flip `Status`, replace `Accepted` with `Superseded by ADR-007 (<commit-date>)`. Do NOT modify ADR-004's Context / Decision / Consequences / Alternatives considered / Linked body sections. If the callout line already exists (idempotent re-run), skip; if Status already reads `Superseded by ADR-007`, skip the flip.
- [ ] Replace the body of REQ-INSTALL-FLOW-002 in `docs/requirements/functional.md` with the new single-path text from Phase 0 drafts. Compare current text vs. the Phase 0 drafts target before writing; if already matches (idempotent re-run), skip.
- [ ] Replace the body of REQ-INSTALL-FLOW-003 in `docs/requirements/functional.md` with the new hub-only text from Phase 0 drafts. (Old body's "still-supported alternative" clause is gone post-ADR-007.) If the body already matches the Phase 0 drafts target verbatim, skip (idempotent re-run).
- [ ] Apply the hub docs surfaces consistency sweep edits (Scope item 3b) per Phase 0 drafts map: `docs/requirements/overview.md` (3 locations: stakeholders, out-of-scope, success criteria), `docs/requirements/functional.md` REQ-COLLISION-002, `docs/architecture/overview.md` (spokes paragraph), `docs/architecture/components.md` (Section 2 vibe-check entry + Section 5 dual-install-paths section + Section 7 README description). Each edit applies the exact before/after text from the drafts map; no improvisation. For each location: if current text already matches the drafts target (e.g. the sweep was partially run earlier), skip that single edit (idempotent re-run).
- [ ] Apply the `tests/test_scenarios.md` Scenario 2 + Scenario 3 disposition (Scope item 8) per Phase 0 drafts: rewrite or delete each scenario per the recorded decision, and update the Coverage map at the bottom of `test_scenarios.md` accordingly. If the file already matches the Phase 0 drafts target (idempotent re-run), skip.
- [ ] Apply the `action-plans/0002-onboard-additional-plugins.md` Inclusion Criteria update (Scope item 9) per Phase 0 drafts: edit the upstream-marketplace collision row at ~line 22 per the drafts decision (DELETE row vs. reframe to "no standalone `marketplace.json` in upstream"). If the row already matches the drafts target (idempotent re-run), skip.
- [ ] Apply the hub README cleanup per Phase 0 drafts map (Migration notes insert + "Alternative: single-plugin install" section treatment + "Adding a plugin to the catalog" collision-rule clause reframe + any other standalone references found by the drafts grep). Each edit applies the exact text from the drafts map; no improvisation. For each individual edit: if current text already matches the drafts target (idempotent re-run), skip just that edit. Specifically, if the Migration notes section already exists with the drafts-target body, skip the Migration notes insert.
- [ ] Run `claude plugin validate .` -- exit 0 expected (manifest unchanged).
- [ ] Run `bash tests/validate_marketplace.sh` -- exit 0 expected (manifest unchanged).

### Phase 2: claude-code-guardian upstream cleanup

- [ ] In `/home/idnotbe/projects/claude-code-guardian/`, run `git rm --ignore-unmatch .claude-plugin/marketplace.json` (the `--ignore-unmatch` flag is what makes this step idempotent; matches the Phase 0 idempotency analysis).
- [ ] Update `KNOWN-ISSUES.md` PV-04 entry per the decision recorded in Phase 0 alignment doc (mark `RESOLVED` with a short note pointing at hub plan 0006, OR delete the entry; consistency with Phase 0 decision is what matters).
- [ ] Apply the claude-code-guardian internal-docs cleanup per Phase 0 drafts map (no improvisation): each location is (a) what to remove (b) what to keep/rewrite, fixed in the drafts file. Then re-run `grep -rn "marketplace add idnotbe/claude-code-guardian\|marketplace add idnotbe-security\|@idnotbe-security\|standalone marketplace\|legacy direct-install" .` as a verification anchor only -- expected to return 0 hits (or only hits the drafts map explicitly marked "no edit -- historical / `_done/`"). Any new hit not in the drafts map blocks the phase: stop and update the drafts map first; do not patch ad-hoc.
- [ ] Stage explicit files (no `git add -A`).

### Phase 3: vibe-check upstream cleanup

- [ ] At Phase 3 entry, re-check `git ls-files docs/` in `/home/idnotbe/projects/vibe-check/`. If `docs/` is still untracked (currently the case), keep working-tree edits in sync with the supersede but DO NOT stage `docs/` for commit -- the docs tree's eventual commit is owned by a separate workstream. This phase only commits the file deletion and the in-tracked-files edits (`README.md`, `CLAUDE.md`).
- [ ] `git rm --ignore-unmatch /home/idnotbe/projects/vibe-check/.claude-plugin/marketplace.json` (the `--ignore-unmatch` flag is what makes this step idempotent; matches the Phase 0 idempotency analysis).
- [ ] `README.md` line 71: remove the file-tree row entirely (since the file no longer exists). Adjust surrounding tree formatting.
- [ ] `CLAUDE.md` line 13: same treatment as above.
- [ ] `docs/architecture/components.md` lines ~64--70 and ~88: rewrite to remove "legacy direct-install path retained per ADR-004" wording. The legacy retention is now a contradiction since ADR-004 is itself superseded; the only documented install path is the hub path.
- [ ] `docs/architecture/decisions.md` ADR-004 section (~lines 127--165): note that this is the upstream's own ADR-004 (not the hub's). Mirror the supersede semantics: add a one-line supersede header naming the hub's ADR-007 OR rewrite to a single-path policy. Phase 0 alignment doc selects between the two; do not improvise here.
- [ ] `docs/requirements/non-functional-and-constraints.md` lines ~14--15: remove the "legacy direct-install route, retained for backward compatibility per ADR-004" clause. Reduce to a single sentence pointing at the hub install flow.
- [ ] Stage explicit files (no `git add -A`). If `docs/` is untracked, verify with `git diff --cached` that no `docs/*` paths were accidentally staged.

### Phase 4: Validators + smoke verify

- [ ] In the hub repo, run `claude plugin validate .` -- exit 0 expected.
- [ ] In the hub repo, run `bash tests/validate_marketplace.sh` -- exit 0 expected. (Confirm CHECK-13 still passes; the hub manifest was never touched.)
- [ ] (Optional, deferred-OK) Smoke test from a clean Claude Code session: `/plugin marketplace add idnotbe/claude-plugins`, then `/plugin install vibe-check@idnotbe` and `/plugin install claude-code-guardian@idnotbe`. Confirm both install through the hub path now that the standalone manifests are gone. If not feasible inside the executing session, flag for user-side verification and proceed.

### Phase F-1: Docs Sync Gate

- [ ] Confirm the hub catalog (5 plugins) is unchanged. The hub manifest, the README catalog list, and `docs/architecture/components.md` Section 2 must all still match exactly (no entry adds, removes, or rewrites in this plan).
- [ ] Confirm internal consistency of the supersede chain: ADR-007 references ADR-004; ADR-004's supersede header points at ADR-007; REQ-INSTALL-FLOW-002 AND REQ-INSTALL-FLOW-003 bodies both match ADR-007's decision (no remaining "still-supported alternative" / dual-path wording); the hub README's "Install" section, "Migration notes" section, AND the former "Alternative: single-plugin install" section (now removed or rewritten) are all internally consistent with ADR-007 and with REQ-INSTALL-FLOW-002/003.
- [ ] Confirm the 5-location hub docs sweep is internally consistent with ADR-007: re-read each location post-edit -- `docs/requirements/overview.md` (stakeholders + out-of-scope + success criteria), `docs/requirements/functional.md` REQ-COLLISION-002, `docs/architecture/overview.md` (spokes paragraph), `docs/architecture/components.md` Section 2 vibe-check entry + Section 5 + Section 7 -- and verify none of them still describes the standalone install path as live or the dual-path policy as the current policy.
- [ ] Confirm `tests/test_scenarios.md` Scenarios 2 and 3 + Coverage map are consistent with ADR-007: no remaining test step exercises the legacy `/plugin marketplace add idnotbe/<plugin>` path as a still-supported install (other than as an explicit verify-deprecation step, if Phase 0 chose the rewrite disposition).
- [ ] In both upstreams: `grep -rn "marketplace add idnotbe/claude-code-guardian\|marketplace add idnotbe/vibe-check\|standalone marketplace\|legacy direct-install\|ADR-004 (KEEP\|backward compat" .` -- 0 results expected (modulo the upstreams' own historical ADR-004 documents, which retain a supersede header but should not still describe the standalone path as live).
- [ ] Confirm the hub README "Migration notes" section exists and renders correctly.
- [ ] Idempotency re-check: ADR-007 insertion (non-idempotent -- guard against duplicate insertion if Phase 1 is re-run); supersede-line addition (non-idempotent -- guard against double line); REQ rewrite (non-idempotent -- compare body); README Migration notes (non-idempotent -- guard against duplicate section); file deletion (idempotent under `git rm --ignore-unmatch`); KNOWN-ISSUES PV-04 (non-idempotent -- already-RESOLVED entry should be left as is, not double-marked).
- [ ] Re-run `claude plugin validate .` AND `bash tests/validate_marketplace.sh` -- both exit 0.

### Phase F: Commit & Push (GATE -- final, multi-commit / multi-PR)

This plan touches three repositories. Each repo gets its own commit and its own push (and, if the user authorizes a PR-based workflow, its own PR). Per `action-plans/README.md` "Multi-Commit / Multi-PR Plans", each PR URL is appended to `progress` as it lands.

- [ ] **Hub repo commit** (`idnotbe/claude-plugins`): stage `docs/architecture/decisions.md` (ADR-007 + ADR-004 supersede line), `docs/requirements/functional.md` (REQ-INSTALL-FLOW-002 rewrite + REQ-INSTALL-FLOW-003 rewrite), `README.md` (Migration notes section added + "Alternative: single-plugin install" section removed/rewritten), and the plan file itself. Commit with a message naming the plan number and the supersede event.
- [ ] **claude-code-guardian commit**: stage `.claude-plugin/marketplace.json` (deletion) and `KNOWN-ISSUES.md` (PV-04 update). Commit referencing hub plan 0006.
- [ ] **vibe-check commit**: stage `.claude-plugin/marketplace.json` (deletion), `README.md` (file-tree update), `CLAUDE.md` (file-tree update). DO NOT stage `docs/` while it remains untracked. Commit referencing hub plan 0006.
- [ ] For each repo, request explicit user authorization before `git push`. Push hub first, then upstream repos.
- [ ] Update plan frontmatter to `status: done`, write final `progress` summary listing all three commit SHAs (and PR URLs if applicable), then `mv action-plans/0006-deprecate-standalone-marketplaces.md action-plans/_done/`.

## Risks

- **User-facing breakage**: Existing installations made via `/plugin marketplace add idnotbe/<plugin>` will fail their next `marketplace update` once the upstream `marketplace.json` is gone. The hub README "Migration notes" section is the documented mitigation. Without it, those users get a 404 with no in-product hint about how to recover.
- **Loss of ADR-004 historical record**: Mitigated by the no-edit policy on ADR-004's body (Context / Decision / Consequences / Alternatives considered / Linked sections). Future readers can still trace the original rationale for the dual-path decision. Two annotation edits (the `Status` flip from `Accepted` to `Superseded by ADR-007` per standard ADR convention, and the supersede callout line under the heading) are explicitly PERMITTED -- they advertise the supersede without altering the historical reasoning.
- **vibe-check `docs/` tracked-state assumption**: As of plan authoring, `docs/` in vibe-check is git-untracked. If by Phase 3 the docs tree has been independently committed, the working-tree edits to `docs/architecture/{components.md,decisions.md}` and `docs/requirements/non-functional-and-constraints.md` MUST be staged in this plan's vibe-check commit instead of being skipped. Phase 3's entry-step re-check prevents this from being decided implicitly.
- **CHECK-13 false sense of security**: The hub's CHECK-13 forbids inline-component fields in hub entries; it does NOT detect standalone `marketplace.json` files in upstream repos. After this plan, nothing structurally prevents an upstream from re-adding its own `marketplace.json`. Adding such a check is out of scope (see "Out of scope" above) and should be tracked as a follow-on plan.
- **External links / SEO indexed stale install instructions**: Blog posts, README forks, social-media posts, and search-engine cached pages may still reference the legacy `/plugin marketplace add idnotbe/claude-code-guardian` or `/plugin marketplace add idnotbe/vibe-check` paths. Users following those stale instructions will hit a 404 at the upstream once Phase 2/3 lands. Mitigation: the hub README "Migration notes" section is the canonical pointer for migrators; the deletion-target upstream repos remain reachable (only the `.claude-plugin/marketplace.json` file is removed, not the repo), so a `marketplace add` against them will fail with a "no manifest" error rather than a network 404, which is at least a clear signal. We cannot retroactively update third-party content.

## Notes

- This is a multi-commit / multi-PR plan per `action-plans/README.md`. The plan does NOT move to `_done/` until all three commits have landed and Phase F-1 has been re-run against the final state.
- ADR-007's full body is defined in `temp/0006-...-phase0-drafts.md` (not in this plan body). This plan body cites the draft location only.
- Cross-plan impact: HIGH. 0002 (`action-plans/0002-onboard-additional-plugins.md`) is the standing onboarding template, not in-flight, but its Inclusion Criteria currently presupposes upstream `marketplace.json` files exist (REQ-COLLISION-002 collision check). Post-ADR-007, that criterion is meaningless; this plan updates 0002's Inclusion Criteria as part of Phase 1 (Scope item 9). The change affects every future onboarding plan derived from 0002. No other action-plan in `action-plans/` (root or `_done/`) depends on the standalone install path; verified by `grep -rn` during Phase 0.
- Follow-up worth opening once this plan closes: a new validator CHECK that, given a list of catalog plugins, verifies (offline-acceptable: via a maintainer-run periodic sweep, not as part of the per-commit two-layer gate) that none of the upstream repos has re-introduced a `.claude-plugin/marketplace.json`. Tracked here as a known follow-on, NOT executed in this plan.
