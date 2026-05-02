# Components

This document describes each artifact in the `idnotbe/claude-plugins` hub repository as a component: its purpose, location, contract, dependencies, and change risk. For the high-level system context, see `./overview.md`. For decision history, see `./decisions.md`.

The hub has fewer components than a typical plugin repo because it is metadata-only.

---

## 1. marketplace.json -- the only behavior-bearing artifact

- **Purpose**: The single source of truth for the catalog. Lists every plugin under the `idnotbe` namespace, with the URL Claude Code should resolve when installing each one.
- **Location**: `/.claude-plugin/marketplace.json`
- **Contract -- Root fields**:
  - `$schema: "https://json.schemastore.org/claude-code-marketplace.json"` -- enables editor autocomplete + validation. Required by the hub. (REQ-MANIFEST-006)
  - `name: "idnotbe"` -- the marketplace identity. Drives the `@idnotbe` install suffix. (REQ-MANIFEST-001)
  - `description` -- one-line catalog blurb. (REQ-MANIFEST-002)
  - `owner.name: "idnotbe"` and `owner.url` -- provenance/contact metadata only; the install namespace comes from the marketplace `name`, not from `owner.name`. (REQ-MANIFEST-003)
  - `plugins[]` -- the catalog. (REQ-MANIFEST-004)
  - `version` -- OPTIONAL maintainer-facing change marker. The schema permits it; the hub does not require it. (REQ-VERSION-001)
- **Contract -- Each `plugins[]` entry**:
  - `name` -- plugin identifier within the catalog. MUST equal the upstream `plugin.json`'s `name`. (REQ-PLUGIN-ENTRY-001, REQ-PLUGIN-ENTRY-004)
  - `description` -- one-to-three sentence catalog blurb.
  - `source` -- `{ "source": "url", "url": "https://github.com/idnotbe/<repo>.git" }`. v1 uses bare `url` form only -- no `ref`, no `sha`. (REQ-PLUGIN-ENTRY-002, ADR-002)
  - Optional metadata: `category`, `tags`, `author`, `homepage`, `keywords`, `version`. The hub does NOT require `version`; omitting it lets Claude Code track the upstream by git SHA on each pull, which is the intended behavior for the bare-URL model. Setting `version` is treated as an opt-in pin (REQ-PLUGIN-ENTRY-001, ADR-002).
  - Forbidden by hub policy (even though the schema permits them): `commands`, `hooks`, `mcpServers`, `lspServers`, `agents`, `skills`, `setup`, `strict`. Plugin behavior -- including any installation-time side effects from `setup` -- MUST be defined in the upstream repo's `plugin.json`, not inlined into the hub manifest. (REQ-HYGIENE-002)
- **Dependencies**: None at runtime. Claude Code's plugin loader is the only consumer.
- **Change risk**: HIGH for the `name` field (REQ-MANIFEST-001) and any `plugins[i].name` value (REQ-PLUGIN-ENTRY-003), because both are referenced in user-typed `/plugin install` commands. MEDIUM for `source.url` values (changing the upstream URL silently breaks installs). LOW for `description` updates and adding/removing optional metadata.

---

## 2. plugin entries -- one per installable plugin

Each entry in `plugins[]` is a logical component. The initial catalog (REQ-PLUGIN-ENTRY-005) contains, in the same alphabetical order used by the manifest:

- **`claude-code-guardian`**
  - `source`: `https://github.com/idnotbe/claude-code-guardian.git`
  - Upstream owns its own `plugin.json`, hooks, scripts, and a per-plugin `marketplace.json`. The upstream's marketplace `name` is `"idnotbe-security"` (an empirical fact, not a hub-imposed convention; it differs from `"idnotbe"` so it does not collide with the hub -- see REQ-COLLISION-002).
  - Hub-side responsibility: `name` + `description` + `source` URL only.

- **`deepscan`**
  - `source`: `https://github.com/idnotbe/deepscan.git`
  - Upstream owns its own `plugin.json` (with `skills` field declared at the manifest level), `.claude/skills/deepscan/`, and supporting docs. The upstream `skills` field is permitted by the marketplace.json schema and does NOT trigger CHECK-13, which scopes only to entries inside the hub's `marketplace.json`.
  - Hub-side responsibility: `name` + `description` + `source` URL + `category` + `tags` + `homepage` only. No upstream `version` is mirrored -- bare-URL tracking by git SHA is intentional (ADR-002).

- **`humanizer`**
  - `source`: `https://github.com/idnotbe/humanizer.git`
  - Upstream owns its own `plugin.json` (metadata-only at the manifest level; no inline `skills` array) and ships its skill under the standard `skills/` directory layout. The upstream visibility was flipped from private to public before this entry was added to the catalog.
  - Hub-side responsibility: `name` + `description` + `source` URL + `category` + `tags` + `homepage` only. Tags are DERIVED (upstream declares no `keywords`); see `temp/0004-onboard-humanizer-phase0-drafts.md` for the derivation rationale. No upstream `version` is mirrored -- bare-URL tracking by git SHA is intentional (ADR-002).

- **`vibe-check`**
  - `source`: `https://github.com/idnotbe/vibe-check.git`
  - Upstream owns `plugin.json`, `SKILL.md`, `validate_skill.sh`, and a per-plugin `marketplace.json` (single-plugin install path; that file's marketplace `name` is `"vibe-check"`).
  - Same hub-side responsibility: `name`, `description`, and the `source` URL. No upstream `version` is mirrored -- bare-URL tracking by git SHA is intentional (ADR-002).

Future plugins are added by inserting a new entry at the position dictated by alphabetical order on `name` (case-insensitive). The list is sorted, not append-only -- this keeps merge conflicts deterministic and removes any implied ranking. Deprecation follows REQ-PLUGIN-ENTRY-006: prefix the description with `[DEPRECATED]` and keep the entry for at least one revision before removal.

---

## 3. Source resolution -- handled by Claude Code, not by the hub

The hub does not implement source resolution. Claude Code's plugin loader handles it. Documenting the resolver's behavior here is informational, so that hub maintainers know which `source` shapes the schema admits.

The current marketplace.json schema permits **five** plugin source forms:

| # | Source form | Shape | Behavior |
|---|-------------|-------|----------|
| 1 | Relative path | `"./plugins/foo"` (string, not object) | Resolves relative to the `marketplace.json` directory. Used by monorepo layouts (Anthropic's `claude-plugins-official`). |
| 2 | GitHub shorthand | `{ "source": "github", "repo": "owner/name", "ref": "...", "sha": "..." }` | Equivalent to the URL form for `https://github.com/owner/name.git`. `ref` and `sha` are optional pins. |
| 3 | URL (whole repo) | `{ "source": "url", "url": "...", "ref": "...", "sha": "..." }` | Clones the URL, checks out the default branch (or the optional `ref`/`sha`), loads `.claude-plugin/plugin.json` at the repo root. |
| 4 | Git subdir | `{ "source": "git-subdir", "url": "...", "path": "...", "ref": "...", "sha": "..." }` | Clones the repo, checks out at `ref`/`sha`, then loads `plugin.json` from `path/`. |
| 5 | npm | `{ "source": "npm", "package": "..." }` | Resolves through the npm registry. |

**Hub policy (v1)**: This hub uses form #3 (`url`) **bare** -- no `ref`, no `sha` -- for every entry: `{ "source": "url", "url": "https://github.com/idnotbe/<repo>.git" }`. Any pinning (sha or ref) is deferred (ADR-002). Forms #1, #2, #4, #5 are documented above so future hub maintainers know what the schema admits, but this hub does not use them in v1.

---

## 4. Registry collision table -- a constraint, not a file

The user's local Claude Code stores added marketplaces in `~/.claude/plugins/known_marketplaces.json`, keyed by marketplace `name`. Two marketplaces with the same `name` collide.

| Source                                                | Marketplace `name`     | Collides with hub?                |
|-------------------------------------------------------|------------------------|-----------------------------------|
| `idnotbe/claude-plugins` (this hub)                   | `"idnotbe"`            | --                                |
| `idnotbe/vibe-check` (per-plugin)                     | `"vibe-check"`         | No (different name)               |
| `idnotbe/claude-code-guardian` (per-plugin)           | `"idnotbe-security"`   | No (different name)               |
| Hypothetical other marketplace using `name: "idnotbe"`| `"idnotbe"`            | YES -- forbidden by REQ-COLLISION-001 |

Note: the `claude-code-guardian` upstream uses `"idnotbe-security"` (not `"claude-code-guardian"`) as its marketplace name. This is an empirical observation, not a hub-imposed rule. REQ-COLLISION-002's only requirement is "MUST NOT be `"idnotbe"`"; using the plugin name is RECOMMENDED for clarity but not required. Both observed upstreams satisfy the no-collision constraint.

The "no other marketplace under `idnotbe`" rule is a process commitment enforced at PR review of any new `idnotbe`-owned marketplace; it cannot be enforced by a validator inside this repo (the conflicting marketplace would be in a different repo).

---

## 5. Dual install paths -- a deliberate architecture choice

Two install paths coexist for any plugin `<P>` owned by `idnotbe`:

1. **Hub path (recommended)**:
   `/plugin marketplace add idnotbe/claude-plugins`
   `/plugin install <P>@idnotbe`

2. **Single-plugin path (still supported)**:
   `/plugin marketplace add idnotbe/<P>`
   `/plugin install <P>@<upstream-marketplace-name>` -- where `<upstream-marketplace-name>` is whatever the upstream's `.claude-plugin/marketplace.json` declares as its `name`. It is NOT necessarily `<P>`. Per REQ-COLLISION-002, the only constraint is "MUST NOT be `idnotbe`"; using the plugin name itself is RECOMMENDED but not required. Concrete v1 examples:
   - `vibe-check`: `/plugin marketplace add idnotbe/vibe-check` then `/plugin install vibe-check@vibe-check` (upstream marketplace `name` is `"vibe-check"`).
   - `claude-code-guardian`: `/plugin marketplace add idnotbe/claude-code-guardian` then `/plugin install claude-code-guardian@idnotbe-security` (upstream marketplace `name` is `"idnotbe-security"`).

Both are real and intentional. The hub does not require upstream repos to delete their per-plugin `marketplace.json`. The trade-off is that the same plugin can show up in a user's catalog under two different `@<marketplace>` namespaces if they added both paths -- this is documented in the README, not enforced by code. See ADR-004.

---

## 6. Validation -- two layers (built-in baseline + hub-specific layer)

Validation happens in two layers. The built-in is the floor; the hub-specific script only adds checks the built-in does not perform.

### 6a. Built-in baseline: `claude plugin validate .`

- **What it is**: A first-party command shipped with Claude Code (also exposed as the slash command `/plugin validate .`). It validates `.claude-plugin/marketplace.json` against the marketplace schema.
- **What it covers**: JSON well-formedness, schema conformance (every field has the right type/shape), required-field presence per the schema, `source` form validity for each entry.
- **Why it is the baseline**: It tracks the schema that Claude Code actually loads against. Anything that breaks here will also break for users on install.
- **How the hub uses it**: It is the first check. Maintainers MUST run it before merging any change to `marketplace.json`. The hub's CI (planned, not present in v1) will run it in front of the hub-specific layer.

### 6b. Hub-specific layer: `tests/validate_marketplace.sh` (planned)

- **Purpose**: Layer hub-specific *policy* checks on top of the built-in's *schema* checks. The built-in cannot enforce that this hub's `name` is the literal string `"idnotbe"`, that every source URL points at `github.com/idnotbe/*.git`, or that no plugin entry inlines `commands`/`hooks`/`mcpServers` -- because the schema permits all of those things in general. The hub-specific layer is the only place those policies live.
- **Status**: Planned. Will be authored in Phase 4. Modeled on `idnotbe/vibe-check`'s `validate_skill.sh` (POSIX shell, no Node).
- **Planned checks** (cited from `functional.md`):
  - CHECK-0: `marketplace.json` parses as JSON. (Cheap re-check; built-in also covers this.)
  - CHECK-1: marketplace `name` exactly equals the literal `"idnotbe"`. (Hub policy; built-in only checks the field is a string.)
  - CHECK-2: `description` present and non-empty.
  - CHECK-3: `owner.name` equals `"idnotbe"`.
  - CHECK-4: `plugins` is a non-empty array.
  - CHECK-5: `<repo-root>/.claude-plugin/plugin.json` does NOT exist (hub-is-not-a-plugin negative check; REQ-MANIFEST-005).
  - CHECK-6: every plugin entry has `name`, `description`, `source`, AND `source` is an object (not a string or other JSON type). The object-type assertion is required so that CHECK-7's `.source.url` access cannot silently misfire on a malformed entry. Matches REQ-PLUGIN-ENTRY-001.
  - CHECK-7: every `source.source` equals `"url"`, `source.url` matches `^https://github\.com/idnotbe/[^/]+\.git$`, and `source` contains neither `ref` nor `sha` (hub policy: bare `url` form pointing at `idnotbe`-owned repos only, no pinning; REQ-PLUGIN-ENTRY-002 + ADR-002).
  - CHECK-8: plugin `name` values are unique within the array.
  - CHECK-9 (optional, network-bound): each plugin entry's `name` matches the upstream `plugin.json`'s `name`.
  - CHECK-10: `vibe-check` and `claude-code-guardian` are both listed AND the full `[entry.name for entry in plugins]` list equals its case-insensitive sorted form (REQ-PLUGIN-ENTRY-005 v1 catalog + ordering assertion).
  - CHECK-11: if `version` is present on the marketplace root, it is a non-empty string. Absence is allowed (REQ-VERSION-001).
  - CHECK-12: `$schema` is present and equals `"https://json.schemastore.org/claude-code-marketplace.json"` (REQ-MANIFEST-006).
  - CHECK-13: no plugin entry contains any of `commands`, `hooks`, `mcpServers`, `lspServers`, `agents`, `skills`, `setup`, `strict` (REQ-HYGIENE-002 hub policy; the schema allows them but the hub forbids inlining, including the install-time `setup` script field).
- **Dependencies**: POSIX bash + `jq` only. CHECK-0 uses `jq -e .` for parse validation (rejects empty files and non-JSON content); no `python3` fallback ships in v1. If `jq` is missing, the validator exits 2 with a clear tooling-error message.

---

## 7. README.md and docs/ -- documentation surfaces

- **README.md** -- end-user surface. Documents the hub install path, lists the catalog, and notes the single-plugin path as a still-supported alternative (REQ-INSTALL-FLOW-003).
- **docs/requirements/** and **docs/architecture/** -- contributor surface. The files you are reading now.
- **Change risk**: LOW. Adding a new plugin requires inserting one entry at the correct alphabetical position in `marketplace.json` and inserting a matching catalog row at the same alphabetical position in `README.md` (REQ-PLUGIN-ENTRY-005). The rest of the documentation is structural and stable.
