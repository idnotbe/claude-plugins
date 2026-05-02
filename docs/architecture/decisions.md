# Architecture Decisions (ADR-lite)

Lightweight Architecture Decision Records for the `idnotbe/claude-plugins` marketplace hub. Each ADR captures one significant choice, why it was made, and what it costs. For the broader architecture context, see `./overview.md` and `./components.md`. REQ IDs cited below refer to `../requirements/functional.md`.

---

## ADR-001: Marketplace name field is `"idnotbe"` (not `"idnotbe-plugins"`)

- **Status**: Accepted (2026-05-02)
- **Context**: The `marketplace.json` root `name` field controls how Claude Code namespaces the catalog's plugins -- users type `/plugin install <plugin>@<marketplace-name>`. Two naming conventions were considered:
  1. **Single-word brand**: `name: "idnotbe"` -- mirrors Cloudflare's official marketplace, which uses `name: "cloudflare"`. CLI UX becomes `vibe-check@idnotbe`.
  2. **Suffix-explicit**: `name: "idnotbe-plugins"` or `name: "claude-plugins-official"` -- mirrors Anthropic's pattern. CLI UX becomes `vibe-check@idnotbe-plugins`.
- **Decision**: Use `name: "idnotbe"`. The `-plugins` suffix is redundant once the user is in a `/plugin` command context, and the single-word brand reads more cleanly at the install site.
- **Consequences**:
  - Positive: Cleaner CLI UX (`vibe-check@idnotbe`); aligns with Cloudflare's pattern; easier to type and to recommend in documentation.
  - Negative: The marketplace `name` becomes a globally identifying brand -- if `idnotbe` ever publishes a *second* marketplace, that one cannot also be `"idnotbe"` (REQ-COLLISION-001). The single-marketplace-per-brand commitment is acceptable in practice because the hub is designed to host all `idnotbe` plugins.
  - Negative: Loses the namespace-explicitness of the suffix style. A user reading `@idnotbe` in a doc has to know `idnotbe` refers to the marketplace, not the GitHub user, even though they happen to share the same string.
- **Alternatives considered**: `"idnotbe-plugins"` (explicit but redundant), `"claude-plugins-official"`-style (mismatched -- Anthropic uses this because they are *the* official source, not appropriate for a personal hub).
- **Linked**: REQ-MANIFEST-001, REQ-COLLISION-001.

---

## ADR-002: v1 plugin sources use bare `url` form (no sha pin)

- **Status**: Accepted (2026-05-02)
- **Context**: Each `plugins[i].source` entry can pin to a specific commit (`sha`) or float on a branch (`url` form, follows default branch). Pinning gives reproducibility but requires manual bumps every time an upstream plugin releases. Floating gives auto-pickup of upstream updates but makes hub-mediated installs as stable as the upstream's default branch.
- **Decision**: Use the bare `url` form for every entry in v1: `{ "source": "url", "url": "https://github.com/idnotbe/<repo>.git" }`. The hub does not pin to commits.
- **Consequences**:
  - Positive: Hub maintenance is near-zero. New plugin releases propagate to hub users automatically without a hub commit.
  - Positive: Catalog stays in sync with what the plugin author intends to be the current version. With `version` omitted on plugin entries (the hub default -- see REQ-PLUGIN-ENTRY-001), Claude Code falls back to git SHA tracking on the upstream's default branch, which is exactly the behavior the bare-URL model is built to enable. There is no manual version-bump drift to manage.
  - Negative: A regression in an upstream plugin's default branch immediately reaches hub users with no quarantine window. This is the v1 trade-off; the hub trusts each upstream's release discipline.
  - Negative: No structural rollback point inside the hub. If a future entry needs a freeze (e.g. quarantine a known-bad release), the hub maintainer would have to opt in to setting `ref` or `sha` on that one entry, deviating from the bare-URL norm.
- **Alternatives considered**:
  - **Sha-pinning every entry** (`{ "source": "url", "url": "...", "sha": "<sha>" }` -- the `url` form supports `sha` directly): considered, rejected for v1, marked as a known future option to revisit if a regression in an upstream plugin breaks hub users.
  - **Tag-pinning** (`ref: "v1.2.3"`): would require coordination with each upstream's tag discipline; deferred for the same reason.
- **Linked**: REQ-PLUGIN-ENTRY-001 (version optionality), REQ-PLUGIN-ENTRY-002 (bare `url` form).

---

## ADR-003: No `plugin.json` at the hub repo root -- the hub is not itself a plugin

- **Status**: Accepted (2026-05-02)
- **Context**: A repository can simultaneously be a marketplace (via `.claude-plugin/marketplace.json`) and a plugin (via `.claude-plugin/plugin.json`). For a personal hub, the question is whether the hub repo should *also* publish itself as an installable plugin -- e.g. one that registers a `/plugins-list@idnotbe` command listing the catalog.
- **Decision**: Ship only `.claude-plugin/marketplace.json`. No `plugin.json` at the **repository root** (i.e. `<repo-root>/.claude-plugin/plugin.json` MUST NOT exist). The hub is a registry record, not an installable artifact. This restriction is scoped to the repo root because that is the path Claude Code's loader treats as the hub-as-plugin advertisement; subdirectory `plugin.json` files in future fixtures, examples, or vendored test inputs are not forbidden.
- **Consequences**:
  - Positive: Single responsibility -- the hub repo's only job is to catalog. No competing identity as both "the marketplace" and "a plugin in the marketplace".
  - Positive: Matches Anthropic's `claude-plugins-official` layout, which has `.claude-plugin/marketplace.json` only. Following the established Anthropic pattern reduces the chance of incompatibility with future Claude Code loader changes.
  - Positive: Validator can assert `<repo-root>/.claude-plugin/plugin.json` DOES NOT exist (REQ-MANIFEST-005, planned CHECK-5), making this a structurally enforced invariant for the load-bearing path.
  - Positive: Leaves headroom for fixtures and examples (e.g. a future `tests/fixtures/example-plugin/.claude-plugin/plugin.json`) without having to weaken the rule.
  - Negative: Loses the option to bundle a hub-management slash command with the hub itself. If such a command is ever wanted, it would need to be its own plugin entry in the catalog (e.g. `idnotbe/claude-plugins-tool`).
- **Alternatives considered**: Ship a `plugin.json` that registers a `/idnotbe-catalog` command -- rejected as scope creep.
- **Linked**: REQ-MANIFEST-005.

---

## ADR-004: Dual install paths -- both hub and per-plugin `marketplace.json` remain valid

- **Status**: Accepted (2026-05-02)
- **Context**: Before the hub existed, each plugin under `idnotbe` shipped its own `.claude-plugin/marketplace.json` so that users could install it via `/plugin marketplace add idnotbe/<plugin>`. The hub creates a second install path: `/plugin marketplace add idnotbe/claude-plugins` followed by `/plugin install <plugin>@idnotbe`. The question is whether to keep both, deprecate one, or unify on the hub.
- **Decision**: Keep both. The hub is the recommended path going forward (and the README documents it as such), but the per-plugin path is preserved for users who installed via that path before the hub existed and for users who want to opt into a single plugin without taking the whole catalog.
- **Consequences**:
  - Positive: Zero-breakage migration. Existing users of `idnotbe/vibe-check` as a marketplace are not forced to switch.
  - Positive: Per-plugin onboarding remains an option for users who specifically want one plugin.
  - Negative: The same plugin can appear in a user's local catalog under two `@<marketplace>` names if the user added both marketplaces. This is harmless (no install conflict, because the marketplace names differ -- the hub uses `"idnotbe"`, while observed upstreams use `"vibe-check"` and `"idnotbe-security"`) but can be confusing. The README addresses this explicitly.
  - Negative: Two manifests describe the same plugin (the hub entry and the upstream `marketplace.json`). Keeping their `name` and `description` values consistent is a manual cross-repo discipline. There is no automated check today. Note: hub plugin entries do not mirror upstream `version` (REQ-PLUGIN-ENTRY-001), so version-drift is not an additional source of inconsistency here.
- **Alternatives considered**:
  - **Remove per-plugin `marketplace.json` from each upstream**: rejected -- breaks existing installs.
  - **Make the hub the only path, deprecate per-plugin `marketplace.json` files in a deprecation window**: deferred; revisit if the manual-sync burden becomes a real problem.
- **Linked**: REQ-INSTALL-FLOW-002, REQ-INSTALL-FLOW-003, REQ-COLLISION-002.

---

## ADR-005: Catalog scope at v1 -- `vibe-check` and `claude-code-guardian` only

- **Status**: Accepted (2026-05-02)
- **Context**: The author (`idnotbe`) maintains other repositories under `/home/idnotbe/projects/*` that may be plugin-shaped or could become plugins later. The hub launch needs to fix a clear v1 scope so the catalog is not a moving target while design is finalized.
- **Decision**: At hub launch, the catalog contains exactly two entries: `vibe-check` and `claude-code-guardian`. These are the two plugins that already ship a `plugin.json` and are publicly installable. Other repositories under `/home/idnotbe/projects/*` are noted as future candidates but are explicitly out of scope for v1.
- **Consequences**:
  - Positive: Predictable launch surface. Validator `CHECK-10` asserts both names are present (REQ-PLUGIN-ENTRY-005).
  - Positive: Adding a future plugin is a single-line append; the v1 boundary does not constrain growth.
  - Negative: Users who have been waiting for one of the not-yet-listed candidates have to wait until that plugin is independently ready (its own `plugin.json`, `marketplace.json`, repo, etc.) before it appears in the hub.
- **Alternatives considered**: Wait until more plugins are ready and launch with three or four -- rejected; v1 should ship with what exists today.
- **Linked**: REQ-PLUGIN-ENTRY-005.

---

## ADR-006: Two-layer validation -- `claude plugin validate .` baseline + hub-specific shell layer

- **Status**: Accepted (2026-05-02)
- **Context**: Validation of the manifest needs to cover two different concerns: (1) is the JSON well-formed and schema-valid for Claude Code's loader? and (2) does it conform to this hub's stricter local policy (literal `name == "idnotbe"`, all source URLs under `github.com/idnotbe/*.git`, no inline executable component fields, etc.)? Earlier draft anchored everything on a custom shell validator and did not mention the built-in `claude plugin validate .` command at all, which under-specifies the strategy.
- **Decision**: Adopt a two-layer model.
  - **Layer 1 (baseline, built-in)**: `claude plugin validate .` (also `/plugin validate .`) is the required first check for every manifest change. It tracks the schema Claude Code actually loads against, so any failure here is a guaranteed user-facing break.
  - **Layer 2 (hub-specific, custom)**: `tests/validate_marketplace.sh` (planned, Phase 4) layers on policy checks the built-in cannot perform because they are stricter than the schema: literal `name == "idnotbe"`, source URLs match `^https://github\.com/idnotbe/[^/]+\.git$`, no plugin entry inlines `commands`/`hooks`/`mcpServers`/`lspServers`/`agents`/`skills`/`strict`, `$schema` is the documented URL, the v1 catalog contains both expected entries.
- **Consequences**:
  - Positive: Each layer has a single, clear responsibility. Schema correctness is owned by the platform; hub policy is owned by hub maintainers.
  - Positive: The custom validator stays small. It only adds checks the built-in does not perform; it does not re-implement schema validation.
  - Positive: Future schema changes in Claude Code automatically flow through the baseline layer without hub maintenance.
  - Negative: Two commands to run instead of one. Mitigated by wrapping both in a future CI workflow (out of scope for v1).
  - Negative: Some overlap is unavoidable (e.g. JSON parse-validity is checked by both); accepted as defense in depth.
- **Alternatives considered**:
  - **Custom validator only**: rejected -- ignores the platform's built-in baseline, would need to re-implement schema validation, would drift from the schema over time.
  - **Built-in only**: rejected -- cannot enforce the hub-specific stricter policies (literal name, URL pattern, no inline components).
- **Linked**: REQ-MANIFEST-001 (literal name), REQ-MANIFEST-006 ($schema), REQ-PLUGIN-ENTRY-002 (URL form), REQ-HYGIENE-002 (no inline components).
