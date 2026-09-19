---
status: active
progress: Source repositories merged after native CI; catalog implementation is ready for its own pre-merge verification.
---

# 0007 - Standardize skill distribution across both catalogs

## Authority and objective

The user explicitly requested changes, commits, pushes and merges for deep-inquiry,
skill-quality-builder and vibe-check, including use of this Claude hub and the
separate ChatGPT/Codex hub. This authorization includes the associated publishing
PRs. No release tag, package publication, credential change or forced push is needed.

## Phase 0 - Align with existing contracts

Preserve the marketplace name `idnotbe`, the bare-URL/default-branch policy
(ADR-002), metadata-only entries, alphabetical ordering, existing shell validator,
and unrelated plugins. The OpenAI hub uses `idnotbe-chatgpt-plugins`, not this
hub's identity. No REQ or ADR identifier changes.

The three source PRs have merged after their existing and new native installer CI:

- deep-inquiry #5: `8af27a41ed7a1efae86b3a1ec5087aa9a9e4b1dd`
- skill-quality-builder #8: `5b21c130c076304ce909379db1c52e9bb5b63276`
- vibe-check #8: `1b63dc74dd406e07dcbb170260489a6ef9334a26`

## Phase 1 - Reuse rather than copy

Add deep-inquiry and skill-quality-builder entries; update vibe-check's description
to its current plugin manifest. Preserve every other entry. Each source keeps one
canonical `.agents/skills/<name>/` bundle, referenced by matching Claude and OpenAI
compatibility manifests. The hubs carry references only.

## Phase 2 - Cross-platform verification

The shared catalog checker has eight local regression tests, including negative
policy mutations, actual returned-path handling, namespaced Codex skills and Git
object identity independent of Windows checkout line endings. Source integration
failures already exposed and corrected strict fixture metadata and Windows stdout
encoding issues; catalog trials exposed two checker assumptions, not missing
source bundles, and those now have regressions.

Run the existing shell policy check on Linux and Claude's strict first-party
validator on both native operating systems. Run real GitHub-source skills installs
for both agents and all three skills, inspect every installed file, compare the
three source repos' distribution code, and install each external Claude plugin.
The OpenAI catalog separately runs the same checker through development-only native
Codex plugin read/install APIs. Never treat a configured workflow as a passing run.

The editing container has no working Git/npm network route. Static tests run
locally; external installation checks run on the publication PR before merge.
Do not claim those networked trials passed before the branch was published.

## Phase F-1 - Review and documentation sync

Keep README, the catalog enumeration in components.md, and current maintenance
instructions aligned. Inspect the final diff and confirm unrelated entry values,
licenses, policy checks, and upstream evaluation results are preserved. All new
content is English. Record exact source and catalog revisions in CI artifacts.
GUI/workspace imports and authenticated model performance remain not_run.

## Phase F - Publish and close

Merge only after successful native Windows/Linux catalog jobs and final diff
review. Record exact-commit evidence in the PR review, archive this plan with
status done after the verification gate, and merge with an expected-head guard.
