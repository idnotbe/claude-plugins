---
status: done
progress: Implementation and native Windows/Linux installation checks passed; publishing PR retains final exact-head merge evidence.
---

# 0007 - Standardize skill distribution across both catalogs

## Authority and objective

The user explicitly requested changes, commits, pushes and merges for deep-inquiry,
skill-quality-builder and vibe-check, including use of this Claude hub and the
separate ChatGPT/Codex hub. This authorization includes the associated publishing
PRs. No release tag, package publication, credential change or forced push is needed.

## Phase 0 - Align with existing contracts

Preserved the marketplace name `idnotbe`, the bare-URL/default-branch policy
(ADR-002), metadata-only entries, alphabetical ordering, existing shell validator,
and unrelated plugins. The OpenAI hub uses `idnotbe-chatgpt-plugins`, not this
hub's identity. No REQ or ADR identifier changes.

The three source PRs merged after their existing and new native installer CI:

- deep-inquiry #5: `8af27a41ed7a1efae86b3a1ec5087aa9a9e4b1dd`
- skill-quality-builder #8: `5b21c130c076304ce909379db1c52e9bb5b63276`
- vibe-check #8: `1b63dc74dd406e07dcbb170260489a6ef9334a26`

## Phase 1 - Reuse rather than copy

Added deep-inquiry and skill-quality-builder entries; updated vibe-check's
description to its current plugin manifest. Preserved every other entry. Each
source keeps one canonical `.agents/skills/<name>/` bundle, referenced by matching
Claude and OpenAI compatibility manifests. The hubs carry references only.

## Phase 2 - Cross-platform verification

The shared catalog checker has eight local regression tests, including negative
policy mutations, actual returned-path handling, namespaced Codex skills and Git
object identity independent of Windows checkout line endings. Source integration
failures exposed and corrected strict fixture metadata and Windows stdout
encoding issues; catalog trials exposed two checker assumptions, not missing
source bundles, and those now have regressions.

Claude catalog run `35437573020` passed on native Windows and Linux for source
head `2107e9199eb3d389dabc5a49334c23227f1eefd3`. It ran the existing shell policy
check on Linux, Claude's strict first-party validator on both systems, real
GitHub-source skills installs for both agents and all three skills, installed-file
integrity, shared distribution-code identity, and installation of each external
Claude plugin. Other catalog plugins were not installed or modified.

The OpenAI catalog run `35437411903` passed both native operating systems for
head `9a4aacde42fe25c30c06a5d9b787377aa27478a5`. Both downloaded JSON reports
showed all eight recorded checks passing, including native Codex plugin install,
enabled state, namespace-qualified skill discovery and full bundle integrity.
The OpenAI hub PR #1 merged as `7abf99ecf217f3fd8c78a01b9c674e9e9a18f2d3`.

The editing container had no working Git/npm network route. Static tests ran
locally; external installation checks ran on publication PRs before merge. These
networked trials are not claimed to have passed before branch publication.

## Phase F-1 - Review and documentation sync

Updated README, the catalog enumeration in components.md and current maintenance
instructions. Preserved unrelated entries, licenses, existing policy checks and
upstream evaluation results. All new content is English. CI artifacts record
actual source and catalog revisions. GUI/workspace imports and authenticated
model performance remain not_run.

## Phase F - Publish and close

This archive change is documentation-only after the implementation's successful
native checks. The final documentation commit must also pass the existing workflow
before merge. The publishing PR review records that exact final head and run, and
merge uses an expected-head guard. No model-effectiveness result is inferred from
installation checks, and the Codex preview API is a development-only test surface.
