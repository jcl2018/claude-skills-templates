---
type: test-spec
parent: S000079
feature: F000044
title: "Symlink-free copy-mode install — Test Specification"
version: 1
status: Draft
date: 2026-06-03
author: chjiang
spec: SPEC.md
reviewers: []
---

<!-- Scope: ENTIRE user story. Smoke + E2E together cover every SPEC P0 AC. -->

## Smoke Tests

<!-- Automated regression. Fast, deterministic. Soft cap: 5 rows. -->

| # | Tag | AC | Check | What It Validates | Script/Command |
|---|-----|-----|-------|-------------------|----------------|
| S1 | core | AC-1 | Force copy-mode install into a temp HOME on Linux/macOS; assert installed files are regular files (not symlinks) and the command exits 0 | Copy-mode install works — catches Git-Bash install breakage on a platform that can't natively reproduce it | `HOME=$tmp SKILLS_DEPLOY_FORCE_COPY=1 skills-deploy install; for f in $tmp/.claude/skills/**/*.md; do [ ! -L "$f" ] && [ -f "$f" ]; done` |
| S2 | core | AC-3 | Run `doctor` after a copy-mode install and after a symlink-mode install | Doctor passes both modes — catches doctor false-failures | `skills-deploy doctor  # expect PASS after each mode` |
| S3 | resilience | AC-5 | After a copy install, read the manifest entry for a skill and assert `install_kind=copy` + a non-empty `source_checksum` | Manifest records mode + checksum — catches missing verification data | `jq -e '.skills[0].install_kind=="copy" and (.skills[0].source_checksum\|length>0)' $tmp/.claude/.skills-templates.json` |
| S4 | core | AC-2, AC-4 | `_can_symlink()` probe selects the right mode; `remove`/`relink` operate on the recorded mode | Catches wrong mode selection and mode-blind lifecycle ops | force each mode, assert probe result, then run `skills-deploy remove` + `relink` and re-check |
| S5 | observability | AC-6 | `test-deploy.sh` exercises copy-mode install, symlink-mode install, and a doctor case for each | Catches missing both-mode test coverage | run `scripts/test-deploy.sh`; assert both-mode cases present and green |

<!-- Tag vocabulary: core, resilience, observability, usability, security, integration. -->

## E2E Tests

<!-- Manual end-to-end verification, run after implementing and before /ship. Soft cap: 5 rows. -->

| # | Tag | AC | Scenario | Steps (as a real user would) | Expected Outcome | Rubric |
|---|-----|-----|----------|------------------------------|------------------|--------|
| E1 | core post-ship | AC-1 | Git Bash user installs skills | On Windows Git Bash, run `skills-deploy install` then `skills-deploy doctor` | Both succeed; skills present as copies; doctor green | Pass if both exit 0 (post-ship: requires Git Bash, verified via windows-latest CI from S000080) |

<!-- E1 carries the literal `post-ship` token: it is only verifiable on real Git
     Bash, which does not exist on the macOS dev host or the default CI runner.
     /CJ_qa-work-item Step 4 filters it out of the E2E subagent dispatch and
     records [qa-e2e-deferred]; the live check is the windows-latest CI job
     delivered by S000080. -->

## Coverage Gaps

| Gap | Why Not Tested | Risk Accepted |
|-----|----------------|---------------|
| Real Git Bash `ln -s`-copies behavior | Only the capability probe is unit-tested locally; the dev host and default CI runner are POSIX with working symlinks | windows-latest CI (S000080) is the live check |
| Concurrent install races | Out of scope for this story | Accepted — interleaved installs into the same HOME are not a supported flow |
