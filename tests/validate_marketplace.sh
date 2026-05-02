#!/usr/bin/env bash

# claude-plugins marketplace hub validator
#
# Enforces hub-specific policy that the built-in `claude plugin validate .`
# does NOT cover. See docs/architecture/components.md Section 6b for the
# CHECK-N catalog and docs/requirements/functional.md for the REQ-* mapping.
#
# Exit codes:
#   0 -- all checks passed (any CHECK-9 SKIP without --with-network is fine)
#   1 -- one or more checks failed
#   2 -- tooling error (jq missing, manifest unreadable, etc.)

set -u
set -o pipefail
# NOTE: deliberately not using `set -e` -- a failed assertion must let the
# script continue and report every failure, not abort on the first one.

# ----- Locate repo root via script location (CWD-independent, symlink-safe) --
# Resolve the script's physical path so invoking through a symlink still
# computes the correct repo root. macOS lacks `readlink -f`, so fall back to
# a portable `cd -P` resolution chain.
resolve_script_path() {
    local src="$1"
    # Follow symlinks until we hit a real file.
    while [ -L "$src" ]; do
        local dir
        dir="$(cd -P "$(dirname "$src")" && pwd)"
        src="$(readlink "$src")"
        # If the symlink target is relative, resolve it against the link's dir.
        case "$src" in
            /*) ;;
            *) src="$dir/$src" ;;
        esac
    done
    cd -P "$(dirname "$src")" && pwd
}

SCRIPT_DIR="$(resolve_script_path "${BASH_SOURCE[0]}")"
REPO_ROOT="$(cd -P "$SCRIPT_DIR/.." && pwd)"
MANIFEST="$REPO_ROOT/.claude-plugin/marketplace.json"
ROOT_PLUGIN_JSON="$REPO_ROOT/.claude-plugin/plugin.json"

# ----- Flags -----------------------------------------------------------------
WITH_NETWORK=0
VERBOSE=0

usage() {
    cat <<'EOF'
Usage: validate_marketplace.sh [OPTIONS]

Validates .claude-plugin/marketplace.json against hub-specific policy.

Options:
  -h, --help            Show this help and exit
  -v, --verbose         Print extra diagnostic info per check
      --with-network    Enable CHECK-9 (fetch upstream plugin.json over network)

Checks:
  CHECK-0   marketplace.json parses as JSON
  CHECK-1   marketplace name == "idnotbe"
  CHECK-2   description present and non-empty
  CHECK-3   owner.name == "idnotbe"
  CHECK-4   plugins is a non-empty array
  CHECK-5   <repo-root>/.claude-plugin/plugin.json does NOT exist
  CHECK-6   every plugin entry has name, description, source (source must be object)
  CHECK-7   every source is bare url form pointing at github.com/idnotbe/*.git
  CHECK-8   plugin name values are unique within the array
  CHECK-9   each plugin name matches upstream plugin.json name (network)
  CHECK-10  vibe-check + claude-code-guardian listed AND list is sorted
  CHECK-11  if root version is present, it is a non-empty string
  CHECK-12  $schema == "https://json.schemastore.org/claude-code-marketplace.json"
  CHECK-13  no plugin entry contains commands/hooks/mcpServers/lspServers/
            agents/skills/setup/strict

Exit codes:
  0   all checks passed
  1   one or more checks failed
  2   tooling error (jq missing, manifest unreadable)
EOF
}

while [ $# -gt 0 ]; do
    case "$1" in
        -h|--help) usage; exit 0 ;;
        -v|--verbose) VERBOSE=1 ;;
        --with-network) WITH_NETWORK=1 ;;
        *) echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
    esac
    shift
done

# ----- Color setup -----------------------------------------------------------
# Disable color if NO_COLOR is set (https://no-color.org) or stdout is not a tty.
if [ -n "${NO_COLOR:-}" ] || [ ! -t 1 ]; then
    RED=''; GREEN=''; YELLOW=''; BOLD=''; NC=''
else
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BOLD='\033[1m'
    NC='\033[0m'
fi

# ----- Counters --------------------------------------------------------------
PASS=0
FAIL=0
SKIP=0

pass() {
    # $1 = CHECK id, $2 = description
    printf "${GREEN}[PASS]${NC} %s: %s\n" "$1" "$2"
    PASS=$((PASS + 1))
}

fail() {
    # $1 = CHECK id, $2 = description, $3 = failure detail
    printf "${RED}[FAIL]${NC} %s: %s -- %s\n" "$1" "$2" "$3"
    FAIL=$((FAIL + 1))
}

skip() {
    # $1 = CHECK id, $2 = reason
    printf "${YELLOW}[SKIP]${NC} %s: %s\n" "$1" "$2"
    SKIP=$((SKIP + 1))
}

verbose() {
    [ "$VERBOSE" -eq 1 ] && printf "       %s\n" "$1"
}

tooling_error() {
    printf "${RED}[ERROR]${NC} %s\n" "$1" >&2
    exit 2
}

# ----- Tooling preflight -----------------------------------------------------
if ! command -v jq >/dev/null 2>&1; then
    tooling_error "jq not found in PATH. Install jq (https://jqlang.github.io/jq/) and re-run."
fi

if [ ! -r "$MANIFEST" ]; then
    tooling_error "Manifest not readable at $MANIFEST"
fi

# ----- Banner ----------------------------------------------------------------
printf "${BOLD}========================================${NC}\n"
printf "${BOLD}claude-plugins Marketplace Validation${NC}\n"
printf "${BOLD}========================================${NC}\n"
printf "Manifest: %s\n" "$MANIFEST"
printf "Repo root: %s\n" "$REPO_ROOT"
[ "$VERBOSE" -eq 1 ] && printf "Verbose: on\n"
[ "$WITH_NETWORK" -eq 1 ] && printf "Network checks: enabled\n"
printf "\n"

# ----- Helper: run jq -e and report any non-zero as failure -----------------
# Usage: jq_assert <jq-filter> <manifest>
# Returns: 0 if filter is truthy, non-zero otherwise. Captures stderr.
jq_assert() {
    local filter="$1"
    local file="$2"
    jq -e "$filter" "$file" >/dev/null 2>&1
}

# ============================================================================
# CHECK-0: marketplace.json parses as JSON
# ============================================================================
# Uses jq's parser as the single dependency -- no python3 fallback. If jq is
# absent the script already exited at the tooling preflight above.
# REQ-HYGIENE-001
JQ_PARSE_ERR=""
# `jq -e .` (not `jq empty`) is required: `jq empty` returns 0 on an empty
# or whitespace-only file because it has zero JSON values to validate. `jq -e .`
# returns non-zero whenever there is no top-level JSON value, including empty
# files, whitespace, or `null`.
if jq -e . "$MANIFEST" >/dev/null 2>&1; then
    pass "CHECK-0" "marketplace.json parses as JSON"
    verbose "jq parse succeeded"
else
    JQ_PARSE_ERR="$(jq -e . "$MANIFEST" 2>&1 || true)"
    [ -z "$JQ_PARSE_ERR" ] && JQ_PARSE_ERR="file is empty or contains no JSON value"
    fail "CHECK-0" "marketplace.json parses as JSON" "jq parse error: $JQ_PARSE_ERR"
    # If the file does not parse, almost every later check will also fail in
    # confusing ways. Stop early to avoid noise.
    printf "\n${RED}Aborting: manifest does not parse as JSON.${NC}\n"
    exit 1
fi

# ============================================================================
# CHECK-1: marketplace name == "idnotbe"
# REQ-MANIFEST-001
# ============================================================================
NAME_TYPE="$(jq -r '.name | type' "$MANIFEST" 2>/dev/null || echo "error")"
NAME_VALUE="$(jq -r '.name // ""' "$MANIFEST" 2>/dev/null || echo "")"
if [ "$NAME_TYPE" = "string" ] && [ "$NAME_VALUE" = "idnotbe" ]; then
    pass "CHECK-1" "marketplace name == \"idnotbe\""
else
    fail "CHECK-1" "marketplace name == \"idnotbe\"" "type=$NAME_TYPE value=\"$NAME_VALUE\""
fi

# ============================================================================
# CHECK-2: description present and non-empty
# REQ-MANIFEST-002
# ============================================================================
DESC_TYPE="$(jq -r '.description | type' "$MANIFEST" 2>/dev/null || echo "error")"
DESC_VALUE="$(jq -r '.description // ""' "$MANIFEST" 2>/dev/null || echo "")"
if [ "$DESC_TYPE" = "string" ] && [ -n "$DESC_VALUE" ]; then
    pass "CHECK-2" "description present and non-empty"
    verbose "description: \"$DESC_VALUE\""
else
    fail "CHECK-2" "description present and non-empty" "type=$DESC_TYPE value=\"$DESC_VALUE\""
fi

# ============================================================================
# CHECK-3: owner.name == "idnotbe"
# REQ-MANIFEST-003
# ============================================================================
OWNER_NAME="$(jq -r '.owner.name // ""' "$MANIFEST" 2>/dev/null || echo "")"
if [ "$OWNER_NAME" = "idnotbe" ]; then
    pass "CHECK-3" "owner.name == \"idnotbe\""
else
    fail "CHECK-3" "owner.name == \"idnotbe\"" "got: \"$OWNER_NAME\""
fi

# ============================================================================
# CHECK-4: plugins is a non-empty array
# REQ-MANIFEST-004
# ============================================================================
# Track CHECK-4 status so per-plugin checks (6/7/8/10/13) can short-circuit
# with [SKIP] rather than running and leaking jq errors on malformed input.
CHECK4_OK=0
PLUGINS_TYPE="$(jq -r '.plugins | type' "$MANIFEST" 2>/dev/null || echo "error")"
PLUGINS_LEN="$(jq -r 'if (.plugins | type) == "array" then (.plugins | length) else -1 end' "$MANIFEST" 2>/dev/null || echo "-1")"
if [ "$PLUGINS_TYPE" = "array" ] && [ "$PLUGINS_LEN" -gt 0 ]; then
    pass "CHECK-4" "plugins is a non-empty array"
    verbose "plugins.length = $PLUGINS_LEN"
    CHECK4_OK=1
else
    fail "CHECK-4" "plugins is a non-empty array" "type=$PLUGINS_TYPE length=$PLUGINS_LEN"
fi

# ============================================================================
# CHECK-5: <repo-root>/.claude-plugin/plugin.json does NOT exist
# REQ-MANIFEST-005 -- hub is not a plugin
# ============================================================================
if [ ! -e "$ROOT_PLUGIN_JSON" ]; then
    pass "CHECK-5" "no <repo-root>/.claude-plugin/plugin.json (hub is not a plugin)"
else
    fail "CHECK-5" "no <repo-root>/.claude-plugin/plugin.json (hub is not a plugin)" \
         "found: $ROOT_PLUGIN_JSON"
fi

# ============================================================================
# CHECK-6: every plugin entry has name (string, non-empty),
#          description (string, non-empty), source (OBJECT)
# REQ-PLUGIN-ENTRY-001
# ============================================================================
if [ "$CHECK4_OK" -ne 1 ]; then
    skip "CHECK-6" "skipped (depends on CHECK-4)"
else
    # Returns indices of entries missing/wrong-typed for any of the three
    # required fields. Critically, .source MUST be an object (not a string,
    # number, array, etc.) -- otherwise CHECK-7 would silently false-pass on
    # field-access errors.
    MISSING_FIELDS_INDICES="$(jq -r '
        [
            .plugins
            | to_entries[]
            | select(
                ((.value | has("name")) | not)
                or ((.value.name | type) != "string")
                or ((.value.name | length) == 0)
                or ((.value | has("description")) | not)
                or ((.value.description | type) != "string")
                or ((.value.description | length) == 0)
                or ((.value | has("source")) | not)
                or ((.value.source | type) != "object")
            )
            | .key
        ] | join(",")
    ' "$MANIFEST" 2>/dev/null)"
    JQ_RC="${PIPESTATUS[0]}"
    if [ "$JQ_RC" -ne 0 ]; then
        fail "CHECK-6" "every plugin entry has name, description, source (source must be object)" \
             "jq query failed (exit $JQ_RC)"
    elif [ -z "$MISSING_FIELDS_INDICES" ]; then
        pass "CHECK-6" "every plugin entry has name, description, source (source is object)"
    else
        fail "CHECK-6" "every plugin entry has name, description, source (source must be object)" \
             "missing-or-wrong-type at indices: $MISSING_FIELDS_INDICES"
    fi
fi

# ============================================================================
# CHECK-7: every source.source == "url", source.url matches the idnotbe
#          GitHub pattern, and source has no ref/sha
# REQ-PLUGIN-ENTRY-002 + ADR-002
# ============================================================================
if [ "$CHECK4_OK" -ne 1 ]; then
    skip "CHECK-7" "skipped (depends on CHECK-4)"
else
    # Single jq -e assertion: every plugin entry's .source must be an object,
    # have .source == "url" (string), have .url matching the idnotbe pattern,
    # and must NOT contain ref or sha. jq -e returns non-zero on false/null,
    # which we treat as FAIL. Any jq parse/runtime error also yields non-zero.
    if jq -e --arg re '^https://github\.com/idnotbe/[^/]+\.git$' '
        (.plugins | type) == "array"
        and (
            .plugins
            | all(
                (.source | type) == "object"
                and (.source.source | type) == "string"
                and (.source.source) == "url"
                and (.source.url | type) == "string"
                and (.source.url | test($re))
                and ((.source | has("ref") or has("sha")) | not)
            )
        )
    ' "$MANIFEST" >/dev/null 2>&1; then
        pass "CHECK-7" "every source is bare url form pointing at github.com/idnotbe/*.git"
    else
        # Build a human-readable failure detail by enumerating offenders.
        # Each offender check is wrapped in 2>/dev/null and || echo so a jq
        # error never propagates as success.
        BAD_SOURCE_TYPE="$(jq -r '
            [.plugins // [] | to_entries[]
             | select((.value.source | type) != "object" or ((.value.source.source // "") != "url"))
             | "\(.key):\(.value.name // "<unnamed>"):type=\(.value.source | type)"
            ] | join(" | ")
        ' "$MANIFEST" 2>/dev/null || echo "<jq-error>")"

        BAD_SOURCE_URL="$(jq -r --arg re '^https://github\.com/idnotbe/[^/]+\.git$' '
            [.plugins // [] | to_entries[]
             | select((.value.source | type) == "object")
             | select((.value.source.url | type) != "string" or ((.value.source.url // "") | test($re) | not))
             | "\(.key):\(.value.name // "<unnamed>"):url=\(.value.source.url // "<missing>")"
            ] | join(" | ")
        ' "$MANIFEST" 2>/dev/null || echo "<jq-error>")"

        BAD_PIN="$(jq -r '
            [.plugins // [] | to_entries[]
             | select((.value.source | type) == "object")
             | select((.value.source | has("ref")) or (.value.source | has("sha")))
             | "\(.key):\(.value.name // "<unnamed>")"
            ] | join(" | ")
        ' "$MANIFEST" 2>/dev/null || echo "<jq-error>")"

        CHECK7_FAILS=""
        [ -n "$BAD_SOURCE_TYPE" ] && CHECK7_FAILS="$CHECK7_FAILS bad-source-type-or-source-field[$BAD_SOURCE_TYPE]"
        [ -n "$BAD_SOURCE_URL" ] && CHECK7_FAILS="$CHECK7_FAILS bad-url[$BAD_SOURCE_URL]"
        [ -n "$BAD_PIN" ] && CHECK7_FAILS="$CHECK7_FAILS contains-ref-or-sha[$BAD_PIN]"
        [ -z "$CHECK7_FAILS" ] && CHECK7_FAILS="(detail unavailable; jq -e returned non-zero)"

        fail "CHECK-7" "every source is bare url form pointing at github.com/idnotbe/*.git" \
             "$CHECK7_FAILS"
    fi
fi

# ============================================================================
# CHECK-8: plugin name values are unique within the array
# REQ-PLUGIN-ENTRY-003
# ============================================================================
if [ "$CHECK4_OK" -ne 1 ]; then
    skip "CHECK-8" "skipped (depends on CHECK-4)"
else
    DUPES="$(jq -r '
        [.plugins[] | (.name // "<unnamed>") | tostring]
        | group_by(.)
        | map(select(length > 1) | .[0])
        | join(",")
    ' "$MANIFEST" 2>/dev/null)"
    JQ_RC="${PIPESTATUS[0]}"
    if [ "$JQ_RC" -ne 0 ]; then
        fail "CHECK-8" "plugin name values are unique" "jq query failed (exit $JQ_RC)"
    elif [ -z "$DUPES" ]; then
        pass "CHECK-8" "plugin name values are unique"
    else
        fail "CHECK-8" "plugin name values are unique" "duplicate names: $DUPES"
    fi
fi

# ============================================================================
# CHECK-9 (optional, network): each plugin name matches upstream plugin.json name
# REQ-PLUGIN-ENTRY-004
# ============================================================================
if [ "$CHECK4_OK" -ne 1 ]; then
    skip "CHECK-9" "skipped (depends on CHECK-4)"
elif [ "$WITH_NETWORK" -ne 1 ]; then
    skip "CHECK-9" "network check disabled (re-run with --with-network to enable)"
else
    if ! command -v curl >/dev/null 2>&1; then
        skip "CHECK-9" "curl not available; cannot fetch upstream plugin.json"
    else
        # For each plugin entry, derive the raw GitHub URL for the upstream
        # plugin.json on the default branch (HEAD), fetch it, and compare names.
        # We use the github.com/<owner>/<repo>/raw/HEAD/.claude-plugin/plugin.json
        # form so we don't need to know the default branch name in advance.
        CHECK9_BAD=""
        CHECK9_NETERR=""
        # Iterate over indices to keep the loop POSIX-portable.
        N="$PLUGINS_LEN"
        i=0
        while [ "$i" -lt "$N" ]; do
            PNAME="$(jq -r ".plugins[$i].name // \"\"" "$MANIFEST" 2>/dev/null || echo "")"
            PURL="$(jq -r ".plugins[$i].source.url // \"\"" "$MANIFEST" 2>/dev/null || echo "")"
            if [ -z "$PURL" ]; then
                CHECK9_NETERR="$CHECK9_NETERR ${PNAME:-<unnamed>}(no-url)"
                i=$((i + 1))
                continue
            fi
            # Strip trailing .git and prefix to derive raw URL.
            REPO_PATH="$(printf "%s" "$PURL" | sed -E 's#^https://github\.com/##; s#\.git$##')"
            RAW_URL="https://raw.githubusercontent.com/$REPO_PATH/HEAD/.claude-plugin/plugin.json"
            verbose "CHECK-9: fetching $RAW_URL"
            UPSTREAM_JSON="$(curl -sSfL --max-time 15 "$RAW_URL" 2>/dev/null || true)"
            if [ -z "$UPSTREAM_JSON" ]; then
                CHECK9_NETERR="$CHECK9_NETERR $PNAME(fetch-failed)"
            else
                UPSTREAM_NAME="$(printf "%s" "$UPSTREAM_JSON" | jq -r '.name // ""' 2>/dev/null || echo "")"
                if [ "$UPSTREAM_NAME" != "$PNAME" ]; then
                    CHECK9_BAD="$CHECK9_BAD $PNAME(upstream=\"$UPSTREAM_NAME\")"
                fi
            fi
            i=$((i + 1))
        done
        if [ -n "$CHECK9_BAD" ]; then
            fail "CHECK-9" "each plugin name matches upstream plugin.json name" \
                 "mismatches:$CHECK9_BAD${CHECK9_NETERR:+; net-errors:$CHECK9_NETERR}"
        elif [ -n "$CHECK9_NETERR" ]; then
            skip "CHECK-9" "could not fetch upstream plugin.json for:$CHECK9_NETERR"
        else
            pass "CHECK-9" "each plugin name matches upstream plugin.json name"
        fi
    fi
fi

# ============================================================================
# CHECK-10: vibe-check + claude-code-guardian present AND list is
#           case-insensitive sorted by name
# REQ-PLUGIN-ENTRY-005
# ============================================================================
if [ "$CHECK4_OK" -ne 1 ]; then
    skip "CHECK-10" "skipped (depends on CHECK-4)"
else
    # Validate every name is a string FIRST. Sorting by ascii_downcase on a
    # null/number raises a jq error otherwise; we want a clean per-check FAIL.
    NON_STRING_NAMES="$(jq -r '
        [.plugins | to_entries[]
         | select((.value.name | type) != "string")
         | "\(.key):type=\(.value.name | type)"
        ] | join(" | ")
    ' "$MANIFEST" 2>/dev/null)"
    JQ_RC="${PIPESTATUS[0]}"

    if [ "$JQ_RC" -ne 0 ]; then
        fail "CHECK-10" "vibe-check + claude-code-guardian present AND list is sorted" \
             "jq pre-check failed (exit $JQ_RC)"
    elif [ -n "$NON_STRING_NAMES" ]; then
        fail "CHECK-10" "vibe-check + claude-code-guardian present AND list is sorted" \
             "non-string names at: $NON_STRING_NAMES"
    else
        NAMES_CSV="$(jq -r '[.plugins[].name] | join(",")' "$MANIFEST" 2>/dev/null || echo "")"
        HAS_VIBE_CHECK="$(jq -r '[.plugins[].name] | index("vibe-check") | tostring' "$MANIFEST" 2>/dev/null || echo "null")"
        HAS_GUARDIAN="$(jq -r '[.plugins[].name] | index("claude-code-guardian") | tostring' "$MANIFEST" 2>/dev/null || echo "null")"

        # Case-insensitive sort comparison via jq.
        SORTED_OK="$(jq -r '
            ([.plugins[].name]) as $orig
            | ($orig | map(ascii_downcase) | sort) as $sorted_lc
            | ($orig | map(ascii_downcase)) as $orig_lc
            | if $orig_lc == $sorted_lc then "yes" else "no" end
        ' "$MANIFEST" 2>/dev/null || echo "no")"

        CHECK10_FAILS=""
        [ "$HAS_VIBE_CHECK" = "null" ] && CHECK10_FAILS="$CHECK10_FAILS missing-vibe-check"
        [ "$HAS_GUARDIAN" = "null" ] && CHECK10_FAILS="$CHECK10_FAILS missing-claude-code-guardian"
        [ "$SORTED_OK" != "yes" ] && CHECK10_FAILS="$CHECK10_FAILS not-case-insensitive-sorted[$NAMES_CSV]"

        if [ -z "$CHECK10_FAILS" ]; then
            pass "CHECK-10" "vibe-check + claude-code-guardian present AND list is sorted"
            verbose "names: $NAMES_CSV"
        else
            fail "CHECK-10" "vibe-check + claude-code-guardian present AND list is sorted" \
                 "$CHECK10_FAILS"
        fi
    fi
fi

# ============================================================================
# CHECK-11: if root version is present, it is a non-empty string
# REQ-VERSION-001
# ============================================================================
HAS_VERSION="$(jq -r 'has("version") | tostring' "$MANIFEST" 2>/dev/null || echo "false")"
if [ "$HAS_VERSION" = "false" ]; then
    pass "CHECK-11" "root version absent (allowed)"
else
    VERSION_TYPE="$(jq -r '.version | type' "$MANIFEST" 2>/dev/null || echo "error")"
    VERSION_VALUE="$(jq -r '.version // ""' "$MANIFEST" 2>/dev/null || echo "")"
    if [ "$VERSION_TYPE" = "string" ] && [ -n "$VERSION_VALUE" ]; then
        pass "CHECK-11" "root version present and non-empty string"
        verbose "version: \"$VERSION_VALUE\""
    else
        fail "CHECK-11" "if root version is present, it is a non-empty string" \
             "type=$VERSION_TYPE value=\"$VERSION_VALUE\""
    fi
fi

# ============================================================================
# CHECK-12: $schema is present and equals the documented URL
# REQ-MANIFEST-006
# ============================================================================
EXPECTED_SCHEMA="https://json.schemastore.org/claude-code-marketplace.json"
SCHEMA_VALUE="$(jq -r '."$schema" // ""' "$MANIFEST" 2>/dev/null || echo "")"
if [ "$SCHEMA_VALUE" = "$EXPECTED_SCHEMA" ]; then
    pass "CHECK-12" "\$schema == \"$EXPECTED_SCHEMA\""
else
    fail "CHECK-12" "\$schema == \"$EXPECTED_SCHEMA\"" "got: \"$SCHEMA_VALUE\""
fi

# ============================================================================
# CHECK-13: no plugin entry contains forbidden inline component fields
# REQ-HYGIENE-002
# ============================================================================
if [ "$CHECK4_OK" -ne 1 ]; then
    skip "CHECK-13" "skipped (depends on CHECK-4)"
else
    # Forbidden: commands, hooks, mcpServers, lspServers, agents, skills, setup, strict
    FORBIDDEN_FIELDS='["commands","hooks","mcpServers","lspServers","agents","skills","setup","strict"]'
    VIOLATIONS="$(jq -r --argjson forbidden "$FORBIDDEN_FIELDS" '
        [
            .plugins
            | to_entries[]
            | . as $p
            | $forbidden[]
            | . as $field
            | select($p.value | type == "object")
            | select($p.value | has($field))
            | "\($p.key):\($p.value.name // "<unnamed>"):\($field)"
        ] | join(" | ")
    ' "$MANIFEST" 2>/dev/null)"
    JQ_RC="${PIPESTATUS[0]}"
    if [ "$JQ_RC" -ne 0 ]; then
        fail "CHECK-13" "no plugin entry contains forbidden inline component fields" \
             "jq query failed (exit $JQ_RC)"
    elif [ -z "$VIOLATIONS" ]; then
        pass "CHECK-13" "no plugin entry contains forbidden inline component fields"
    else
        fail "CHECK-13" "no plugin entry contains forbidden inline component fields" \
             "$VIOLATIONS"
    fi
fi

# ============================================================================
# Summary
# ============================================================================
printf "\n${BOLD}========================================${NC}\n"
printf "${BOLD}Validation Summary${NC}\n"
printf "${BOLD}========================================${NC}\n"
printf "${GREEN}%d passed${NC}, ${RED}%d failed${NC}, ${YELLOW}%d skipped${NC}\n" \
       "$PASS" "$FAIL" "$SKIP"
printf "\n"

if [ "$FAIL" -eq 0 ]; then
    printf "${GREEN}All required checks passed.${NC}\n"
    exit 0
else
    printf "${RED}One or more checks failed. Review output above.${NC}\n"
    exit 1
fi
