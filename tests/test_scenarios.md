# Manual Test Scenarios

Scenarios that the automated `tests/validate_marketplace.sh` cannot exercise. These cover real install paths, marketplace registration semantics, and policy commitments enforced by process rather than code.

Run these before any release of the hub manifest, and any time `marketplace.json` changes a `name`, an entry's `name`, or a `source.url`.

Conventions used below:
- "Clean session" means `~/.claude/plugins/known_marketplaces.json` has no `idnotbe` entry (or any fixture-introduced `idnotbe` collision-test entry) — back up and remove before starting.
- "Expected" lines describe the observable Claude Code behavior or filesystem state at that step.
- "Verifies" cites the REQ-* IDs (see `docs/requirements/functional.md`) that the scenario covers.

---

## 1. Hub install path

**Setup**
- Clean session.
- Internet access; GitHub reachable.
- A working Claude Code CLI with the `/plugin` command available.

**Steps**
1. Run `/plugin marketplace add idnotbe/claude-plugins`.
2. Run `/plugin marketplace list`.
3. Run `/plugin install vibe-check@idnotbe`.
4. In a fresh prompt, list available skills (e.g. via `/help` or whatever skills enumeration the local CLI surfaces).
5. Run `/plugin install claude-code-guardian@idnotbe`.
6. Trigger any command Guardian's `PreToolUse` block list catches (consult the installed plugin's docs for the current list).
7. Run `/plugin uninstall vibe-check`.
8. Re-list available skills (same command as step 4).

**Expected (specific success signals)**
- Step 1: shell exit code is 0; the file `~/.claude/plugins/known_marketplaces.json` exists and contains the substring `"idnotbe"` as a marketplace key (`jq -e '.marketplaces | has("idnotbe")' ~/.claude/plugins/known_marketplaces.json` returns 0).
- Step 2: `/plugin marketplace list` stdout contains the exact substring `idnotbe`.
- Step 3: shell exit code is 0; the directory `~/.claude/plugins/vibe-check/` exists.
- Step 4: skill list output stdout contains the exact substring `vibe-check`.
- Step 5: shell exit code is 0; the directory `~/.claude/plugins/claude-code-guardian/` exists.
- Step 6: the matching tool call is blocked (e.g. `[BLOCKED]`-style refusal in tool output) or the user is prompted to confirm; the underlying command does NOT execute silently.
- Step 7: shell exit code is 0; the directory `~/.claude/plugins/vibe-check/` no longer exists.
- Step 8: skill list output stdout does NOT contain the substring `vibe-check`.

**Verifies**: REQ-INSTALL-FLOW-001, REQ-MANIFEST-001, REQ-MANIFEST-004, REQ-PLUGIN-ENTRY-001, REQ-PLUGIN-ENTRY-002.

---

## 2. Standalone marketplace path is removed (negative)

This is a negative test that demonstrates the supersede recorded in ADR-007 (2026-05-03): the legacy single-plugin install path no longer resolves to a marketplace manifest at either upstream.

**Setup**
- Clean session.
- Internet access; GitHub reachable.

**Steps**
1. Run `/plugin marketplace add idnotbe/vibe-check`.
2. Run `/plugin marketplace add idnotbe/claude-code-guardian`.
3. Inspect `~/.claude/plugins/known_marketplaces.json`.

**Expected (specific success signals)**
- Step 1: shell exit code is non-zero AND/OR Claude Code reports a missing-manifest error (the upstream repo `idnotbe/vibe-check` no longer ships `.claude-plugin/marketplace.json`). The exact wording of the error is CLI-version dependent; the load-bearing assertion is that the marketplace IS NOT registered. Verify with `jq -e '.marketplaces | has("vibe-check") | not' ~/.claude/plugins/known_marketplaces.json` -- expected exit 0.
- Step 2: same shape as step 1 against `idnotbe/claude-code-guardian` (upstream marketplace name `idnotbe-security`). Verify with `jq -e '.marketplaces | has("idnotbe-security") | not' ~/.claude/plugins/known_marketplaces.json` -- expected exit 0.
- Step 3: neither `vibe-check` nor `idnotbe-security` appears as a marketplace key. The user's only path forward is the hub: `/plugin marketplace add idnotbe/claude-plugins` (covered by Scenario 1).

**Verifies**: REQ-INSTALL-FLOW-002 (rewritten by hub plan 0006: hub is the only install path).

---

## 3. Marketplace name collision (hub-only, fixture-only)

This is a negative test that demonstrates the constraint protected by REQ-COLLISION-001 using two local fixtures that both declare `name: "idnotbe"`. Per ADR-007, no `idnotbe`-owned upstream marketplace exists, so the test does not exercise any live per-plugin marketplaces.

**Setup**
- Clean session.
- Two local fixture manifests (or two different local repos) that both declare `name: "idnotbe"` at the marketplace root.

**Steps**
1. Inspect `~/.claude/plugins/known_marketplaces.json` (`jq 'keys' ~/.claude/plugins/known_marketplaces.json`).
2. Run `/plugin marketplace add <fixture-A>` where fixture A's manifest has `name: "idnotbe"`.
3. Run `jq '.marketplaces.idnotbe' ~/.claude/plugins/known_marketplaces.json`.
4. Run `/plugin marketplace add <fixture-B>` where fixture B's manifest also has `name: "idnotbe"`.
5. Re-run `jq '.marketplaces | keys[] | select(. == "idnotbe")' ~/.claude/plugins/known_marketplaces.json | wc -l`.
6. Run `/plugin marketplace remove idnotbe`.
7. Re-run `jq -e '.marketplaces | has("idnotbe") | not' ~/.claude/plugins/known_marketplaces.json`.

**Expected (specific success signals)**
- Step 1: the file's top-level structure is an object whose keys are marketplace names (not repo URLs).
- Step 3: jq returns a non-null object pointing at fixture A's source.
- Step 5: the `wc -l` output is exactly `1` — there is only ever one `"idnotbe"` slot. The second `add` either silently overwrote the first registration or failed with non-zero exit; either is acceptable, but two slots is NOT.
- Step 7: jq exits 0, confirming the single `idnotbe` slot was removed by a single `remove` call.

**Verifies**: REQ-COLLISION-001.

---

## 4. Update / re-pull behavior (bare-URL semantics)

**Setup**
- Clean session.
- A scratch upstream plugin you control, registered in the hub manifest with bare-URL `source` (no `ref`, no `sha`). Or, simulate by temporarily forking an `idnotbe` plugin and pointing the manifest at the fork for the duration of the test.
- Internet access.

**Steps**
1. Add the hub: `/plugin marketplace add idnotbe/claude-plugins`.
2. Install the scratch plugin: `/plugin install <name>@idnotbe`.
3. Capture the installed commit SHA: `SHA1="$(git -C ~/.claude/plugins/<plugin> rev-parse HEAD)"`.
4. Push a new commit to the upstream plugin's default branch and capture its SHA as `UPSTREAM_NEW`.
5. Run `/plugin marketplace update idnotbe`.
6. Capture the new cached SHA: `SHA2="$(git -C ~/.claude/plugins/<plugin> rev-parse HEAD)"`.

**Expected (specific success signals)**
- Step 2: shell exit code is 0; `~/.claude/plugins/<plugin>/.git/HEAD` exists.
- Step 5: shell exit code is 0.
- Step 6: `SHA2 != SHA1` AND `SHA2 == UPSTREAM_NEW` (test with `[ "$SHA2" != "$SHA1" ] && [ "$SHA2" = "$UPSTREAM_NEW" ] && echo OK`). No version bump in `marketplace.json` was required because the entry uses the bare-URL form (REQ-PLUGIN-ENTRY-002, ADR-002): bare URL means "track default branch."

**Verifies**: REQ-PLUGIN-ENTRY-002, ADR-002.

---

## 5. Deprecation flow

**Setup**
- A working hub install in your test session (per Scenario 1).
- A plugin entry you are willing to mark deprecated (use a fixture or a sandbox manifest, not a live plugin).

**Steps**
1. Edit the chosen plugin entry in `marketplace.json` so its `description` begins with the literal token `[DEPRECATED]` (optionally followed by a one-sentence reason or replacement pointer).
2. Commit and push the change.
3. Run `/plugin marketplace update idnotbe`.
4. List the catalog (`/plugin install` with no argument, or whatever catalog-listing form the local CLI provides) and capture the output.
5. Attempt `/plugin install <deprecated-name>@idnotbe`.
6. Wait at least one subsequent revision before removing the entry entirely. ("Revision" here means the next time the hub manifest is updated for any reason; the policy is a grace period, not a fixed time interval.)

**Expected (specific success signals)**
- Step 3: shell exit code is 0.
- Step 4: captured stdout for the deprecated entry's row contains the exact literal substring `[DEPRECATED]`.
- Step 5: install still resolves (shell exit code 0; `~/.claude/plugins/<deprecated-name>/` exists). The entry remains installable during the grace period — only the description signal changes.

**Verifies**: REQ-PLUGIN-ENTRY-006.

---

## 6. Hub-not-a-plugin (negative)

**Setup**
- A clone of `idnotbe/claude-plugins` at the latest commit.
- A clean Claude Code session.

**Steps**
1. From the repo root, run `ls .claude-plugin/`.
2. Run `bash tests/validate_marketplace.sh`.
3. Add the hub: `/plugin marketplace add idnotbe/claude-plugins`.
4. Attempt `/plugin install claude-plugins@idnotbe` (the hub's repo name, deliberately wrong as a plugin name).

**Expected (specific success signals)**
- Step 1: output contains `marketplace.json` and does NOT contain `plugin.json`. Equivalently: `[ ! -e .claude-plugin/plugin.json ] && echo OK` prints `OK`.
- Step 2: shell exit code is 0; validator stdout contains the exact line prefix `[PASS] CHECK-5:`.
- Step 3: shell exit code is 0.
- Step 4: install fails — shell exit code is non-zero AND `~/.claude/plugins/claude-plugins/` does NOT exist. The hub itself MUST NOT be installable as a plugin via its own catalog.

**Verifies**: REQ-MANIFEST-005.

---

## Coverage map

| Scenario                                | Primary REQ-*               |
|-----------------------------------------|-----------------------------|
| 1. Hub install path                     | REQ-INSTALL-FLOW-001        |
| 2. Standalone path removed (negative)   | REQ-INSTALL-FLOW-002        |
| 3. Hub `name` collision (fixture-only)  | REQ-COLLISION-001           |
| 4. Update / re-pull (bare-URL)          | REQ-PLUGIN-ENTRY-002, ADR-002 |
| 5. Deprecation flow                     | REQ-PLUGIN-ENTRY-006        |
| 6. Hub-not-a-plugin                     | REQ-MANIFEST-005            |

Scenarios that the automated validator already covers (CHECK-0 through CHECK-13 in `validate_marketplace.sh`) are intentionally NOT duplicated here.
