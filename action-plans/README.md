# Action Plans

Execution plan management directory for the `idnotbe/claude-plugins` marketplace hub repo.

## Structure

- Root `.md` files = active plans (`not-started`, `active`, `blocked`)
- `_done/` = completed plans (move here when all steps are `[v]`)
- `_ref/` = reference / historical documents (long-lived background, not actionable)

## Frontmatter Rules

All plan files must have YAML frontmatter at the top:

```yaml
---
status: not-started    # not-started | active | blocked | done | superseded
progress: "Not started"  # Current progress (free text)
---
```

## Status Values

- **not-started**: Work has not begun
- **active**: Currently in progress
- **blocked**: Waiting on unresolved external dependencies (upstream plugin repo, schema change, etc.)
- **done**: Completed -> **must** move the file to `_done/`
- **superseded**: Replaced by a newer plan (see "Superseded Plans" below). Plan file stays where it is; `superseded_by` frontmatter field names the replacement.

## Action Plan File Structure

Action plan files contain ordered actions (`Phase 0`, `Phase 1`, ..., `Phase F-1`, `Phase F`).

Each step must have a progress checkmark:

- `[v]` = done
- `[ ]` = not started
- `[/]` = in progress

Example:

```markdown
## Phase 1: Add plugin entry to manifest
- [v] Insert entry at correct alphabetical position in `.claude-plugin/marketplace.json`
- [/] Update README catalog list
- [ ] Update `docs/architecture/components.md` Section 2
```

When all steps are marked `[v]`, the entire plan is done. Update frontmatter to `status: done` and move the file to `_done/`.

## Lifecycle (Full Execution Protocol)

Every action plan follows this **mandatory multi-phase lifecycle**. Unless explicitly classified as a **Lightweight plan** (see below), skipping any phase is a blocking error.

> **Phase order is always: Phase 0 -> Phase 1..N (execution) -> Phase F-1 (docs sync gate) -> Phase F (commit & push).** Phase F-1 is the final docs-sync gate; Phase F is the mechanical closing step (status flip + move file + commit + push). Nothing runs after Phase F. The `F-1` / `F` naming is a countdown -- read "F minus one" as "the gate one phase before final."

### Phase 0: Docs-Plan Alignment (GATE -- must complete before any plan execution)

1. **Read current docs**: `README.md`, `ARCHITECTURE.md`, `CLAUDE.md`, `.claude-plugin/marketplace.json`, `tests/`, `docs/requirements/`, `docs/architecture/` -- requirements, architecture, ADRs, validator contract.
2. **Diff against plan**: Compare docs requirements/architecture with plan goals. Produce a **gap list**:
   - New requirements (not in docs)
   - Changed requirements (docs and plan conflict)
   - Removed requirements (plan deprecates)
3. **Impact assessment**: Per gap, estimate change scope, affected documents/systems, and risk.
4. **Draft planned doc changes** in `temp/{plan-name}-phase0-drafts.md`. Do NOT mutate live docs at this stage -- keep all proposed content in working memory (`temp/`) until Phase F-1 finalization. If the plan has no documentation impact, record "No documentation impact" in the alignment doc -- a separate drafts file is not required.
5. Write gap list and impact assessment to `temp/{plan-name}-phase0-alignment.md`.
6. **Gate check**: Alignment doc must exist (and drafts, if documentation changes are planned) before Phase 1.

### Phase 1--N: Execution

- Standard lifecycle: `status: active`, update progress, mark `[v]/[/]/[ ]` per step.
- If changes affect **another active plan**, add: `> WARNING -- IMPACT: {this-plan-name} changed {document/workstream}. Review required.`
- Use `temp/` as **working memory**: intermediate analysis, eligibility surveys, validator dry-run output, shared docs.
- If `.claude-plugin/marketplace.json` or `tests/validate_marketplace.sh` is touched, run `claude plugin validate .` AND `bash tests/validate_marketplace.sh` before closing the phase.

> **Blocked plans**: Plans with `status: blocked` should document: (a) unblock condition, (b) next review date. Plans blocked >90 days should be reviewed for archival or dependency resolution.

### Phase F-1: Docs Sync (GATE -- must complete before commit)

1. **Apply planned doc changes**: Integrate content from `temp/{plan-name}-phase0-drafts.md` (and any execution-phase updates) into live docs (`README.md`, `ARCHITECTURE.md`, `CLAUDE.md`, `docs/requirements/*`, `docs/architecture/*`).
2. **Docs-plan consistency**: Verify all live docs match the completed plan state exactly.
3. **Catalog sync**: If a `marketplace.json` plugin entry was added/removed/renamed, update the README catalog list AND `docs/architecture/components.md` Section 2 accordingly.
4. **Validator alignment**: If `marketplace.json` schema-affecting fields were added/removed (new metadata fields, new source forms, new collision rules), update `tests/validate_marketplace.sh` checks AND the corresponding `REQ-*` entries in `docs/requirements/functional.md`.
5. **Cross-plan check**: Confirm changes don't break other active plans' assumptions; update if needed.
6. **Staleness check**: If the plan was blocked or dormant for >2 weeks, re-verify `temp/` drafts against current live docs before applying.
7. **Final validation**: Run `claude plugin validate .` AND `bash tests/validate_marketplace.sh` -- both must exit 0.

### Phase F: Commit & Push (GATE -- final)

1. Frontmatter -> `status: done`, update `progress` to final summary. Move plan file to `_done/`.
2. `git add` -- only the changed files (docs + manifest + plan file + supporting artifacts). Avoid `git add -A` / `git add .` to prevent staging sensitive files.
3. `git commit` -- message includes plan name and completed phases.
4. `git push` -- push to remote (only when explicitly authorized by the user).

### Lifecycle Summary

```
Phase 0: Docs-Plan Alignment  -->  Gap list + Impact + Drafts in temp/
    |
Phase 1-N: Execution           -->  Manifest/doc changes + temp/ working memory
    |
Phase F-1: Docs Sync           -->  Apply drafts to live docs, run both validators
    |
Phase F: Commit & Push          -->  status: done, move to _done/, git commit & push
```

> **Migration**: This lifecycle applies to NEW plans created after this README. Existing active plans adopt the lifecycle at their next major phase boundary or when restarted. Legacy plans are not retroactively non-compliant.

## Lightweight Plans

Some changes do not need the full lifecycle. A plan qualifies as **Lightweight** when ALL of the following hold:

- Touches at most one live doc (e.g., a README typo fix, a single sentence in `docs/architecture/decisions.md`).
- Does NOT modify `.claude-plugin/marketplace.json` schema-affecting fields.
- Does NOT modify `tests/validate_marketplace.sh` checks.
- Does NOT add, remove, or rename a plugin entry in the catalog.
- Does NOT introduce or remove a `REQ-*` in `docs/requirements/functional.md`.

For Lightweight plans:

- Phase 0 may be abbreviated to a one-paragraph alignment note inside the plan file itself (no separate `temp/{plan-name}-phase0-alignment.md` required).
- A single verification round suffices in Phase F-1.
- The full Phase F-1 docs-sync gate is still required if any doc was edited.

The executing agent classifies the plan; if uncertain, default to full lifecycle. Lightweight classification MUST be declared in the plan body (`## Classification: Lightweight` with a one-line justification) so reviewers can spot it.

## Naming Convention

Plan files use `NNNN-kebab-case-title.md`:

- `NNNN` is a 4-digit zero-padded monotonic counter, never reused.
- Counter increases across both root and `_done/` -- check both directories before picking the next number.
- Title is short kebab-case describing the goal (`onboard-additional-plugins`, not `add-stuff`).

Examples:

- `0001-bootstrap-hub-repo.md`
- `0002-onboard-additional-plugins.md`
- `0003-deprecate-plugin-entry.md`

## Cross-Plan Impact Warning Convention

If executing a plan changes a document, manifest field, or workstream that another **active** plan depends on, the executing plan MUST add a top-level callout in the affected step:

```markdown
> WARNING -- IMPACT: {this-plan-name} changed {document/workstream}.
> Affected plan: {other-plan-name}. Review required before merging.
```

Examples of impactful changes worth flagging:

- Adding a new `REQ-*` that another in-flight plan was assuming did not exist.
- Renaming a plugin entry while another plan is mid-onboard.
- Changing the `marketplace.json` schema (e.g., adopting a new source form).

## Dormant / Blocked Plan Hygiene

Blocked plans MUST document, inside the plan body:

- **Unblock condition**: the specific external event needed (e.g., "upstream `idnotbe/agntpod` publishes a `.claude-plugin/plugin.json`").
- **Next review date**: ISO date when this plan should be re-evaluated even if no signal arrives.

Plans that have been dormant (no progress update) for **>90 days** must be reviewed:

- If still relevant, refresh `progress`, push the next review date forward, document why.
- If no longer relevant, move the file to `_ref/` with a final `progress` note explaining why it was shelved.

## Superseded Plans

A plan that has been replaced by a newer plan (rather than completed in the normal sense) MUST record that fact instead of being silently abandoned.

- Add `superseded_by: 00NN-replacement-title` to the frontmatter when applicable, naming the replacement plan.
- Frontmatter `status` MAY change to `superseded` (a new status value reserved for this case). The plan file STAYS WHERE IT IS -- if it had reached `_done/`, it stays in `_done/`; if it was active in the root, it stays in the root with `status: superseded`.
- Do NOT delete the document. It is kept for traceability so a future reader can follow the chain from the original intent to the replacement.

Example frontmatter for a superseded plan:

```yaml
---
status: superseded
superseded_by: 0017-onboard-pipelined-plugins
progress: "Superseded 2026-06-10 by 0017; see that plan for the revised approach."
---
```

## Multi-Commit / Multi-PR Plans

A single plan MAY span multiple ordered commits or pull requests when the work is too large to land atomically (e.g., a schema migration that staged across three releases). When this happens:

- List each PR URL in the `progress` field as it lands, with the most recent at the bottom.
- Update commit log references in the plan body (e.g., a "Commit log" subsection at the end) so a reader can reconstruct the order without combing git history.
- The plan does not move to `_done/` until the FINAL commit/PR in the sequence has merged and Phase F-1 has been re-run against the final state. Intermediate commits may pass partial Phase F-1 checks scoped to what they touch, but the full gate runs once at the end.

## temp/ as Working Memory

`temp/` serves as action plan execution **working memory**:

- Phase 0 alignment docs, gap lists, impact assessments, doc-change drafts.
- Per-plugin eligibility surveys (e.g., `temp/{repo-name}-eligibility.md`).
- Validator dry-run output, JSON-schema diffs.
- Intermediate artifacts, comparative analyses, review notes.

> `temp/` files may be cleaned after plan completion; move to `_ref/` if worth preserving.

## When NOT to Write a Plan

Not every change needs an action plan. Skip the plan and just do the work for:

- Pure typo / grammar fixes inside a single file.
- Reverting a commit that was made within the same session.
- Editing files inside `temp/` (working memory by definition).
- Local-only experiments that will not be committed.

Write a plan if the change touches `marketplace.json`, any file under `docs/`, `tests/validate_marketplace.sh`, or coordinates work across more than one of: README, ARCHITECTURE, manifest, validator. When in doubt, write the plan -- the cost of an unnecessary plan is much lower than the cost of an undocumented schema change.

## Reading Order for New Contributors

A new contributor opening this directory should read in this order:

1. This `README.md` (lifecycle and conventions).
2. `0001-bootstrap-hub-repo.md` (in the root while bootstrap is still in flight; will be in `_done/` after Phase F lands) -- shows the lifecycle applied to a real plan.
3. The newest active plan in the root -- shows the lifecycle applied to in-flight work.
4. `docs/requirements/functional.md` -- the `REQ-*` IDs that all plans cite.

## Lifecycle Summary (short form)

1. Create new plan -> add file to root with frontmatter (next monotonic `NNNN`).
2. Phase 0 -> alignment doc + drafts in `temp/{plan-name}-phase0-*.md`.
3. Phase 1--N -> `status: active`, execute, update `[v]/[/]/[ ]` per step.
4. Phase F-1 -> apply drafts to live docs, run `claude plugin validate .` and `bash tests/validate_marketplace.sh`.
5. Phase F -> `status: done`, move to `_done/`, commit, push (if authorized).
6. Archive as reference (optional) -> move to `_ref/`.
