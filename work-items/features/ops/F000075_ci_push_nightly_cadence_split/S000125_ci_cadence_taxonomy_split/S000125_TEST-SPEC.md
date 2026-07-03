---
type: test-spec
parent: S000125
feature: F000075
title: "CI cadence taxonomy split (V2) + Windows nightly move — Test Specification"
version: 1
status: Draft
date: 2026-07-03
author: chang
spec: SPEC.md
reviewers: []
---

<!-- Scope: ENTIRE user story. Smoke + E2E together cover every SPEC P0 AC.
     Soft cap 5 rows/tier — the rows below are chosen to prove the story works,
     not to enumerate every check. AC column maps to SPEC # story numbers. -->

## Smoke Tests

<!-- Automated regression. Fast, deterministic, runnable from a script or CI. -->

| # | Tag | AC | Check | What It Validates | Script/Command |
|---|-----|-----|-------|-------------------|----------------|
| S1 | core | AC-1 | Seed byte-identity + validate on V2 | The two taxonomy copies are byte-identical and the merged registry validates under V2 | `cmp -s <(bash scripts/test-spec.sh --seed) spec/test-spec.md && bash scripts/test-spec.sh --validate` |
| S2 | core | AC-2, AC-4 | `--list-categories` shows the V2 rows | `validate`/`suite`/`test-deploy`/`windows` resolve under `CI-push` and `windows-deploy` under `CI-nightly` | `bash scripts/test-spec.sh --list-categories` |
| S3 | resilience | AC-3, AC-2 | `--check-structure` derives folders from declared categories | Required `tests/<category>/` + `docs/tests/<category>/` are checked only for DISTINCT declared categories (fixture with a category subset requires no empty extra folder) | `bash scripts/test-spec.sh --check-structure` (+ the derive-from-declared fixture case in `tests/test-spec.test.sh`) |
| S4 | usability | AC-6 | Runner selects the V2 categories | `--category CI-push` and `--category CI-nightly` each yield a correct plan; the V1 enum-rejection message is updated | `bash scripts/test-run.sh --category CI-push --dry-run` and `--category CI-nightly --dry-run` (+ the negative enum test in `tests/test-run.test.sh`) |
| S5 | integration | AC-5 | Doc-spec registry ⇔ on-disk after the rename | No orphaned/undeclared `docs/tests/` paths; the lowercase `docs/tests/ci.md` family render is untouched | `bash scripts/validate.sh` (Check 15/15a; Checks 24/26/28 stay green) |

<!-- Full-suite green (`bash scripts/test.sh`) + shellcheck clean are covered by
     the E2E walkthrough (E1) below, since they are the ship-gate the maintainer
     runs before /ship, not a single structural smoke check. -->

## E2E Tests

<!-- Manual end-to-end verification, run after implementing and before /ship. -->

| # | Tag | AC | Scenario | Steps (as a real user would) | Expected Outcome | Rubric |
|---|-----|-----|----------|------------------------------|------------------|--------|
| E1 | core | AC-1, AC-2, AC-3, AC-4, AC-5, AC-6, AC-9 | Full contract + suite green under V2 | Run `bash scripts/validate.sh`, then `bash scripts/test.sh`, then shellcheck on changed scripts | All three pass with no findings; the V2 taxonomy is live end to end | PASS iff validate.sh green, test.sh green (incl. `tests/test-spec.test.sh` + `tests/test-run.test.sh`), shellcheck clean |
| E2 | usability | AC-6 | Operator selects a cadence via `/CJ_test_run` | Invoke `/CJ_test_run --category CI-push` then `--category CI-nightly` (dry-run) and read the plans | Each plan lists exactly that cadence's tests, honoring cost tiers; no "outside taxonomy" error | PASS iff `CI-push` plan = {validate, suite, test-deploy, windows} and `CI-nightly` plan = {windows-deploy} |
| E3 | core post-ship | AC-7 | The real workflows fire on the right cadence | After merge: open a PR and confirm `windows.yml` runs only `windows-smoke.sh` (no `test-deploy.sh` step); then `gh workflow run windows-nightly.yml` and confirm it runs `test-deploy.sh` on `windows-latest` | PR shows only the fast Windows smoke; the nightly workflow runs the deploy suite on Windows on dispatch | PASS iff the PR check set excludes the Windows `test-deploy` step AND the dispatched nightly run executes `test-deploy.sh` on `windows-latest` |
| E4 | observability | AC-8 | Docs describe V2 | Read `skills/CJ_test_audit/{SKILL,USAGE}.md`, `skills/CJ_test_run/{SKILL,USAGE}.md`, and `CLAUDE.md` | All describe `{workflow, CI-push, CI-nightly}` + `--category CI-push\|CI-nightly` + the nightly Windows workflow | PASS iff no doc still says the V1 closed set `{workflow, CI}` for the category taxonomy |

<!-- E3 is tagged `post-ship`: windows.yml's trimmed trigger set and the new
     windows-nightly.yml workflow are only observable on remote refs AFTER the PR
     merges (a PR's own checks + `gh workflow run` against a workflow that does
     not exist on remote until merge). /CJ_qa-work-item Step 4 filters this row
     from the E2E subagent dispatch and records [qa-e2e-deferred]. -->

## Coverage Gaps

<!-- What is explicitly NOT tested and why. -->

| Gap | Why Not Tested | Risk Accepted |
|-----|----------------|---------------|
| A real `windows-latest` run of `windows-deploy` locally | The `categories:` axis has no `platform:` field, so `--category CI-nightly` runs `test-deploy.sh` on the LOCAL platform, not real Windows | A native-Windows-only `test-deploy` regression is caught by the nightly workflow (E3), not by a local `--category CI-nightly` run; documented in the two per-test docs |
| Consumer-repo seed upgrade to V2 | No downstream consumer repo is exercised in this suite | The derive-from-declared `--check-structure` logic (S3) is the guard that a consumer declaring only a category subset is not forced to create empty folders; behavior on a real consumer is verified only by that unit-level fixture |
| Nightly cron actually firing on schedule | GitHub's scheduler cannot be triggered on demand in a test | `workflow_dispatch` (E3) exercises the same job body; only the cron trigger itself is unverified, and it mirrors the existing `eval-nightly.yml` pattern |
