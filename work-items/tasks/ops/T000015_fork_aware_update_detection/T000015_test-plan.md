---
type: test-plan
parent: T000015
title: "fork-aware-update-detection — Test Plan"
date: 2026-05-09
author: chjiang
status: Draft
---

<!-- Scope: ONE fix (defect) or ONE task. Cases must be concrete and reproducible.
     For broader coverage of a user story, use TEST-SPEC.md instead.
     For defects, the test cases are regression cases for the specific bug. -->

## Scope

Modify `scripts/skills-update-check` to add an `upstream/main` fallback before the existing `origin/main` fetch + show steps. If `origin/main` is not a tracking ref, try `upstream/main` instead. Same comparison logic; different remote name. Silent when both remotes are absent.

Files modified:
- `scripts/skills-update-check` (4-6 line fallback inserted before the fetch step; same logic mirrored where the script reads `{remote}/main:VERSION`).

## Regression Test Cases

| # | Test Case | Steps | Expected Result | Status |
|---|-----------|-------|-----------------|--------|
| 1 | `origin/main` only — existing behavior unchanged | 1. In a clone where `origin/main` exists. 2. Bump remote VERSION on origin. 3. Invoke a skill preamble (e.g., `/personal-workflow check`). | Banner emits `SKILLS_UPGRADE_AVAILABLE <old> <new>`. No error output. | Pending |
| 2 | Fork with `upstream/main` only — banner emits | 1. Add `upstream` remote pointing to canonical repo. 2. Remove `origin/main` tracking ref (or use a fork without it). 3. Bump remote VERSION on upstream. 4. Invoke a skill preamble. | Banner emits using `upstream/main` as the source of truth. No error output. | Pending |
| 3 | Both remotes absent — silent no-op | 1. In a clone with neither `origin/main` nor `upstream/main` resolvable. 2. Invoke a skill preamble. | No banner, no stderr spam, exit 0. | Pending |
| 4 | Both remotes present — `origin/main` wins | 1. Both remotes configured and reachable. 2. Bump remote VERSION on origin only. 3. Invoke a skill preamble. | Banner emits using `origin/main` (preferred). `upstream/main` not consulted. | Pending |

## Verification Steps

<!-- How was the fix verified beyond the test cases above? -->

- [ ] `./scripts/validate.sh` passes post-change.
- [ ] `./scripts/test.sh` passes post-change (full repo test suite).
- [ ] Manual smoke from a fork checkout confirms banner emits via `upstream/main`.
- [ ] No new stderr noise when both remotes are missing (verified via `2>&1 | wc -l` against silent baseline).

## Environments Tested

| Environment | Build | Result |
|------------|-------|--------|
| macOS Darwin 25.3.0 / zsh / git 2.x | feat/personal-pipeline | Pending |
