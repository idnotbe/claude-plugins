# claude-plugins -- Functional Requirements

This document enumerates the functional behaviors the `idnotbe/claude-plugins` marketplace hub MUST exhibit. Each requirement has a stable ID, a normative statement, a rationale, and a "Verified by" line pointing at the planned validator check (in `tests/validate_marketplace.sh`) and/or the relevant section of `.claude-plugin/marketplace.json`. Requirements trace back to the scope statements in `overview.md`.

The hub is a static manifest only -- there is no runtime to test. "MUST" therefore means the manifest contains the documented field and the validator (where applicable) protects that surface. Where a validator check does not yet exist, the line cites `tests/validate_marketplace.sh:CHECK-N`.

---

## 1. Manifest Identity

The marketplace identity controls how Claude Code namespaces the hub's plugins in the `@<owner>` install syntax.

**REQ-MANIFEST-001 -- Marketplace name field**
The `marketplace.json` root MUST contain a `name` field whose value is exactly `"idnotbe"`.
- Rationale: This name is the `@idnotbe` suffix users type in `/plugin install <plugin>@idnotbe`. Matches Cloudflare's `"cloudflare"` pattern (single-word brand, no `-plugins` suffix). See ADR-001.
- Verified by: `tests/validate_marketplace.sh:CHECK-1`; `.claude-plugin/marketplace.json` root `name` field.

**REQ-MANIFEST-002 -- Marketplace description**
The `marketplace.json` root MUST contain a non-empty `description` field describing the catalog (one short sentence).
- Rationale: Surfaced in marketplace discovery UIs; missing description gives users no signal about what the hub contains.
- Verified by: `tests/validate_marketplace.sh:CHECK-2`.

**REQ-MANIFEST-003 -- Owner block**
The `marketplace.json` root MUST contain an `owner` object with `owner.name = "idnotbe"` and SHOULD include `owner.url` pointing at the GitHub profile `https://github.com/idnotbe`.
- Rationale: Provenance and contact metadata only -- it tells consumers who maintains the catalog. The `@idnotbe` install namespace is bound exclusively by the marketplace root `name` field (REQ-MANIFEST-001), not by `owner.name`. The two strings happen to match here, but they serve different purposes.
- Verified by: `tests/validate_marketplace.sh:CHECK-3`.

**REQ-MANIFEST-004 -- Plugins array**
The `marketplace.json` root MUST contain a `plugins` array with at least one entry.
- Rationale: An empty hub serves no purpose.
- Verified by: `tests/validate_marketplace.sh:CHECK-4`.

**REQ-MANIFEST-005 -- Hub repo root is not a plugin**
The hub repository's root `.claude-plugin/` directory MUST NOT contain a `plugin.json` file. That is, `<repo-root>/.claude-plugin/plugin.json` MUST NOT exist. The hub is a marketplace registry, not an installable plugin. (This requirement does not forbid `plugin.json` files inside subdirectories such as future fixtures, examples, or vendored test inputs -- only the repo-root location is restricted, because that is the path Claude Code's loader treats as the hub-as-plugin advertisement.)
- Rationale: Anthropic's `claude-plugins-official` repository confirms this layout: a hub has `.claude-plugin/marketplace.json` only. Putting a `plugin.json` at the repo root would invite Claude Code to also treat the hub itself as a plugin, polluting the catalog with a self-reference. See ADR-003.
- Verified by: `tests/validate_marketplace.sh:CHECK-5` asserts `<repo-root>/.claude-plugin/plugin.json` does not exist.

**REQ-MANIFEST-006 -- `$schema` declaration**
The `marketplace.json` root MUST contain a `$schema` field whose value is `"https://json.schemastore.org/claude-code-marketplace.json"`.
- Rationale: Current Claude Code documentation explicitly recommends declaring the marketplace schema URL so that JSON-aware editors (VS Code, etc.) provide autocomplete, type checking, and inline validation while editing the manifest. Cost is one extra line; payoff is real-time validation of every edit before it ever reaches a validator run or a user.
- Verified by: `tests/validate_marketplace.sh:CHECK-12` asserts the `$schema` field is present and equals the documented URL; `claude plugin validate .` (built-in baseline) covers the schema-conformance side.

---

## 2. Plugin Entry Contract

Each entry in the `plugins[]` array represents one installable plugin in the catalog.

**REQ-PLUGIN-ENTRY-001 -- Required and optional fields per entry**
Every plugin entry MUST contain:
- `name` (string, unique within the array)
- `description` (non-empty string, one to three sentences)
- `source` (object, see REQ-PLUGIN-ENTRY-002)

Every plugin entry MAY also contain the metadata fields permitted by the marketplace schema: `category`, `tags`, `author`, `homepage`, `keywords`, `version`. The hub does NOT require `version`.
- Rationale: `name` + `source` are the minimum Claude Code needs to resolve and install the plugin. `description` is what the user sees in `/plugin install`. `version` is intentionally optional in the hub: omitting it lets Claude Code track the upstream by git SHA on each pull, which is exactly what the bare-`url` source form (REQ-PLUGIN-ENTRY-002, ADR-002) is designed for. If a future entry sets `version` explicitly, that is treated as an opt-in pin -- a deliberate freeze point -- not as a required mirror of the upstream's `plugin.json.version`. Mirroring upstream `version` on every release would be manual drift work without behavioral payoff.
- Verified by: `tests/validate_marketplace.sh:CHECK-6` asserts `name`, `description`, `source` are present on every entry; absence of `version` is allowed.

**REQ-PLUGIN-ENTRY-002 -- Source form (v1: bare URL, idnotbe-owned)**
Every plugin entry's `source` field MUST use the `url` source form, MUST point at a `github.com/idnotbe/*.git` URL, and MUST NOT include `ref` or `sha`:
- `{ "source": "url", "url": "https://github.com/idnotbe/<repo>.git" }`
- Rationale: Each plugin lives in its own upstream repository under `idnotbe`. The bare `url` form is whole-repo, follows the default branch, and requires no per-release maintenance. The schema permits four other source forms (`github` shorthand, `git-subdir`, `npm`, relative path) and permits `ref`/`sha` pins on `url` and `github`; this hub deliberately uses none of them in v1. Pinning is a known future option (see ADR-002).
- Verified by: `tests/validate_marketplace.sh:CHECK-7` asserts every `source.source == "url"`, `source.url` matches `^https://github\.com/idnotbe/[^/]+\.git$`, and `source` does not contain `ref` or `sha`.

**REQ-PLUGIN-ENTRY-003 -- Plugin name uniqueness within the hub**
Plugin entry `name` values MUST be unique within the `plugins[]` array of a single `marketplace.json`.
- Rationale: Claude Code's `/plugin install <name>@idnotbe` resolves `<name>` within the marketplace; two entries with the same `name` would create an unresolvable lookup.
- Verified by: `tests/validate_marketplace.sh:CHECK-8`.

**REQ-PLUGIN-ENTRY-004 -- Plugin name must equal upstream `plugin.json` name**
Each plugin entry's `name` MUST equal the `name` field of the same plugin's upstream `.claude-plugin/plugin.json`.
- Rationale: A divergent name causes Claude Code to install a plugin under one name in the catalog and load it under a different name from the upstream `plugin.json`, breaking subsequent `/plugin` commands that reference the catalog name.
- Verified by: `tests/validate_marketplace.sh:CHECK-9` -- if the validator can fetch the upstream `plugin.json` over the network, otherwise this is a manual-review item documented in the README.

**REQ-PLUGIN-ENTRY-005 -- Initial catalog and entry ordering**
The `plugins[]` array at hub launch MUST contain entries for `vibe-check` and `claude-code-guardian`. Entries MUST be kept sorted alphabetically by `name` (case-insensitive ASCII). Adding a new plugin means inserting a new entry at the position dictated by alphabetical order; no other changes are required.
- Rationale: These are the two `idnotbe`-owned plugins that exist as of v1. Other repositories under `/home/idnotbe/projects/*` may become plugin candidates; they are out of scope for v1 and are not listed. Alphabetical ordering (rather than chronological append-only) is chosen to make the manifest easy to scan, to make merge conflicts deterministic when two PRs add different plugins, and to avoid implying any priority or quality ranking from list position.
- Verified by: `tests/validate_marketplace.sh:CHECK-10` asserts both names are present AND that `[entry.name for entry in plugins]` equals its sorted-by-lowercase form.

**REQ-PLUGIN-ENTRY-006 -- Deprecation and removal policy**
A plugin entry MUST NOT be silently removed from the catalog while users may reasonably still depend on it. To deprecate a plugin, the maintainer MUST:
1. Prefix the entry's `description` with the literal token `[DEPRECATED]` (and optionally append a one-sentence reason or replacement pointer).
2. Keep the entry in the manifest for at least one subsequent hub revision after the deprecation prefix is added, so that a user re-syncing the marketplace sees the deprecation signal at least once.
3. Only after that grace period MAY the entry be removed.

Renames (upstream repo renamed) follow the same flow: add a deprecation entry under the old name pointing at the new name, in addition to adding the new-name entry.
- Rationale: Hub users who already installed a plugin via `<name>@idnotbe` have no other way to learn that the plugin is going away if the catalog quietly drops it. The `[DEPRECATED]` prefix surfaces in `/plugin install` listings; the grace period gives users a window to migrate. Cost is one extra revision per removal; payoff is no orphaned installs.
- Verified by: Process check at PR review time. `tests/validate_marketplace.sh` does not (and cannot reliably) enforce grace-period semantics; this is a maintainer commitment documented in the README "Plugin lifecycle" section.

---

## 3. Install Flow

These requirements describe the user-observable install paths the hub MUST support and MUST NOT break.

**REQ-INSTALL-FLOW-001 -- Hub install path**
A user who runs `/plugin marketplace add idnotbe/claude-plugins` MUST be able to subsequently run `/plugin install <name>@idnotbe` for any `<name>` listed in `REQ-PLUGIN-ENTRY-005`.
- Rationale: This is the entire reason the hub exists.
- Verified by: `tests/test_scenarios.md` (manual, planned).

**REQ-INSTALL-FLOW-002 -- Hub is the only install path**
The hub at `idnotbe/claude-plugins` is the single documented install path for any `idnotbe`-owned plugin. Upstream plugin repositories MUST NOT ship a `.claude-plugin/marketplace.json`. Users install any plugin via `/plugin marketplace add idnotbe/claude-plugins` followed by `/plugin install <name>@idnotbe`.
- Rationale: A single install path eliminates manual cross-repo manifest sync (the cost recorded in ADR-004's "Negative" consequences) and removes the documentation hedge between two paths. See ADR-007, which supersedes ADR-004. The previous dual-path body is preserved in ADR-007's Context section as the historical record.
- Verified by: `tests/test_scenarios.md` Scenario 2 (negative test: the legacy single-plugin path is gone).

**REQ-INSTALL-FLOW-003 -- Hub install is the canonical README entry point**
The hub README MUST document the hub install path as the canonical (and only) entry point: `/plugin marketplace add idnotbe/claude-plugins` followed by `/plugin install <name>@idnotbe`. The README MUST NOT describe a per-plugin install path as a still-supported alternative; it MAY include a "Migration notes" section pointing legacy users at the hub path.
- Rationale: Documentation tracks the policy: post-ADR-007, there is no per-plugin alternative to recommend. Listing one would contradict the supersede.
- Verified by: `README.md` "Install (recommended path)" section + `README.md` "Migration notes" section.

---

## 4. Marketplace Name Collision

The user's `~/.claude/plugins/known_marketplaces.json` is keyed by marketplace `name`. Two locally added marketplaces sharing a `name` collide.

**REQ-COLLISION-001 -- `name` collision risk**
Because the hub's marketplace `name` is `"idnotbe"` (REQ-MANIFEST-001), any other marketplace the user adds with `name: "idnotbe"` will collide in `~/.claude/plugins/known_marketplaces.json`. The hub project MUST NOT publish or recommend any other marketplace under the `"idnotbe"` name.
- Rationale: Ownership of the `"idnotbe"` marketplace name is reserved for the hub. Per-plugin upstream `marketplace.json` files (e.g. `idnotbe/vibe-check`, `idnotbe/claude-code-guardian`) currently use distinct names (see REQ-COLLISION-002 for the actual policy and observed values), so they do not collide with the hub.
- Verified by: Convention; checked at PR review time. `tests/validate_marketplace.sh:CHECK-1` enforces the `"idnotbe"` name on this hub; the converse (no other marketplace claims it) is a process commitment.

**REQ-COLLISION-002 -- Future upstream `marketplace.json` files MUST NOT use `"idnotbe"`**
Per ADR-007, no `idnotbe`-owned upstream plugin repository ships a `.claude-plugin/marketplace.json` today. Any future upstream `marketplace.json` (whether re-introduced or added by a new policy) MUST NOT set `name: "idnotbe"`. The `"idnotbe"` marketplace name is reserved by REQ-COLLISION-001 for the hub at `idnotbe/claude-plugins` only.
- Rationale: The collision-avoidance constraint outlives the dual-path policy. Even though no per-plugin marketplaces exist post-ADR-007, the hub still owns the `"idnotbe"` marketplace name, and any future addition under that brand would collide. The requirement keeps a stable anchor for the collision-table row in `docs/architecture/components.md` Section 4 and for ADR-001's "Linked" reference.
- Verified by: Process check at PR review time; structural validation is impossible without upstream-fetch capability (out of scope for the v1 validator). A maintainer-run periodic sweep is tracked as a follow-on plan.

---

## 5. Manifest Hygiene

**REQ-HYGIENE-001 -- JSON parses cleanly**
`.claude-plugin/marketplace.json` MUST be valid JSON (no trailing commas, no comments).
- Rationale: Claude Code's loader rejects invalid JSON; the catalog becomes unusable.
- Verified by: `tests/validate_marketplace.sh:CHECK-0` uses jq's parser (no python3 dependency); jq is the script's single tool dependency.

**REQ-HYGIENE-002 -- Hub plugin entries are metadata-only (hub policy)**
Each plugin entry in `.claude-plugin/marketplace.json` MUST contain ONLY the metadata fields needed to identify and resolve the plugin: `name`, `description`, `source`, and the optional metadata `category`, `tags`, `author`, `homepage`, `keywords`, `version`. Plugin entries in this hub MUST NOT inline any of the executable or installation-side-effect fields that the marketplace.json schema otherwise permits, specifically: `commands`, `hooks`, `mcpServers`, `lspServers`, `agents`, `skills`, `setup`, or `strict`.
- Rationale: The marketplace schema *does* permit these fields directly inside a plugin entry (so a marketplace entry can in principle define commands, hooks, or run a `setup` script on install). The hub's policy is stricter than the schema: each plugin's behavior -- including any installation-time side effects -- must be defined in its own upstream repo's `plugin.json`, not duplicated or inlined into the hub manifest. This keeps the hub purely declarative, preserves single-source-of-truth for plugin behavior, ensures the hub itself never executes code on a user's machine, and matches the "no runtime code" property in `overview.md` "Out of Scope". This is hub-specific policy, not a platform constraint -- which is why a custom validator check is required (the built-in `claude plugin validate .` will accept inline component fields because the schema allows them).
- Verified by: `tests/validate_marketplace.sh:CHECK-13` walks each `plugins[]` entry and asserts none of `commands`, `hooks`, `mcpServers`, `lspServers`, `agents`, `skills`, `setup`, `strict` is present.

**REQ-HYGIENE-003 -- All committed content in English**
All committed text in this repository (manifest descriptions, README, docs) MUST be in English.
- Rationale: Mirrors the `idnotbe/vibe-check` convention; keeps the repo maintainable by external contributors.
- Verified by: Manual review.

---

## 6. Versioning of the Hub Itself

**REQ-VERSION-001 -- Hub `version` field is optional**
The marketplace.json root MAY carry a `version` field. The schema permits it, and Anthropic's own marketplace manifests use it. The hub does not require it.
- Rationale: The hub has no compiled artifact and no semver-meaningful behavior of its own, so a hub-level `version` is not load-bearing. It can still be useful as a maintainer-facing change marker. The trade-off accepted: optional, low-cost; if adopted, the maintainer SHOULD bump it on every manifest change so that downstream tools watching the field have a meaningful signal.
- Verified by: `tests/validate_marketplace.sh:CHECK-11` -- if `version` is present, asserts it is a non-empty string (does not require a specific format). If absent, no check fires.

---

## 7. Document Map and Stable IDs

| ID prefix          | Subject                                                | Section |
|--------------------|--------------------------------------------------------|---------|
| REQ-MANIFEST-*     | Marketplace identity (name, owner, plugins, $schema)   | 1       |
| REQ-PLUGIN-ENTRY-* | Per-plugin entry shape, source form, uniqueness        | 2       |
| REQ-INSTALL-FLOW-* | User install paths (hub-only per ADR-007)              | 3       |
| REQ-COLLISION-*    | Marketplace-name collision constraints                 | 4       |
| REQ-HYGIENE-*      | JSON validity, hub policy on inline components, English| 5       |
| REQ-VERSION-*      | Hub-level versioning policy                            | 6       |

These IDs are stable. Architecture decisions in `../architecture/decisions.md` link back to them.
