---
type: test-plan
parent: T000020
title: "Add /qa discoverability pointer to /CJ_personal-pipeline final summary — Test Plan"
date: 2026-05-11
author: chjiang
status: Draft
---

<!-- Scope: ONE fix (defect) or ONE task. Cases must be concrete and reproducible.
     For broader coverage of a user story, use TEST-SPEC.md instead.
     For defects, the test cases are regression cases for the specific bug. -->

## Scope

This task adds a single documentation line to `skills/CJ_personal-pipeline/pipeline.md` Step 9.3 (`### 9.3 Print summary`), surfacing `/qa` (a gstack skill) as a follow-up option inside the existing `Next:` block of the printed end-of-run summary. Files/components modified:

- `skills/CJ_personal-pipeline/pipeline.md` — one line added inside the existing `Next:` block in Step 9.3, on its own line after the existing `/ship` row, with matching two-space indent and column alignment
- `VERSION` — bumped per workbench convention (handled by `/ship`)
- `CHANGELOG.md` — new entry (handled by `/ship`)

The change is purely text/discoverability — no functional behavior changes, no schema changes, no new runtime dependencies. The workbench remains portable (no hard gstack dependency from `/CJ_personal-pipeline`'s runtime path; `skills-deploy install` continues to work standalone). The contract for QA: `validate.sh` and `test.sh` must continue to exit 0 unchanged, the new line must be present at the correct location in `pipeline.md`, and the next `/CJ_personal-pipeline` invocation must print the new line inside its end-of-run `Next:` block.

## Regression Test Cases

| # | Test Case | Steps | Expected Result | Status |
|---|-----------|-------|-----------------|--------|
| 1 | New line present at correct location | `grep -n '^  /qa' skills/CJ_personal-pipeline/pipeline.md` | Exactly one match. Line content: `  /qa                                  # if work-item touched a web app — visual / E2E polish`. Match line number falls inside the Step 9.3 `Next:` block (verify by inspecting surrounding context — line appears between the `Next:` header and the closing fence/blank line of that block). | Pending |
| 2 | Existing `/ship` line unchanged | `grep -n '^  /ship' skills/CJ_personal-pipeline/pipeline.md` | Exactly one match. The existing `/ship` row's text, indentation, and column alignment are byte-identical to pre-change. | Pending |
| 3 | `/qa` line immediately follows `/ship` line | `awk '/^  \/ship/{getline next_line; print next_line}' skills/CJ_personal-pipeline/pipeline.md` | Output is the `/qa  ...` line. The `/qa` row sits directly under `/ship` with no intervening blank line or other content. | Pending |
| 4 | `validate.sh` exits 0 | `cd $REPO && ./scripts/validate.sh; echo "exit=$?"` | `exit=0`. All error checks still pass. No new violations introduced by the edit. | Pending |
| 5 | `test.sh` full suite exits 0 | `cd $REPO && ./scripts/test.sh; echo "exit=$?"` | `exit=0`. Full suite (including `test-deploy.sh`) remains green. | Pending |
| 6 | No new gstack runtime dependency in `skills-deploy install` | `cd /tmp && rm -rf claude-skills-templates-test && git clone $REPO claude-skills-templates-test && cd claude-skills-templates-test && ./scripts/skills-deploy install --dry-run` (or equivalent isolated-temp test path) | Install plan succeeds end-to-end with no reference to gstack as a required dependency. The new line in `pipeline.md` is text-only and does not affect deployment behavior. | Pending |
| 7 | Diff is one-line edit only (no scope creep) | `git diff main -- skills/CJ_personal-pipeline/pipeline.md \| diffstat` (or `git diff main -- skills/CJ_personal-pipeline/pipeline.md \| grep -c '^+'` minus the diff header lines) | One added line, zero removed lines, zero modified lines. Total `+` lines (excluding `+++` header) = 1. | Pending |
| 8 | Next `/CJ_personal-pipeline` invocation prints the new line | After merge + redeploy via F000009 update-check flow (`git pull --ff-only && skills-deploy install --from-upgrade <old>`), run `/CJ_personal-pipeline <some-design-doc>` against any work-item; capture Step 9.3 output. | The end-of-run `Next:` block includes the `/qa` line directly under the existing `/ship` line, with the inline conditional comment intact. | Pending (Phase 3, post-deploy) |
| 9 | Workbench-portability invariant preserved | After deploy, on a machine without gstack: `cd $REPO && ./scripts/skills-deploy install` then attempt to invoke `/CJ_personal-pipeline` against a small work-item. | Install succeeds. `/CJ_personal-pipeline` runs to completion. The `/qa` line is printed in the `Next:` block (as text), but no error occurs from /qa being absent on the machine. The line is a pointer, not a runtime invocation. | Pending (Phase 3, post-deploy) |
| 10 | No drift in `/CJ_personal-pipeline` contract | After merge: `diff -u <pre-PR pipeline.md> <post-PR pipeline.md> \| grep -E '^[+-]' \| grep -v '^[+-]  /qa'` | All non-`/qa`-line diffs are limited to the single added line. No other section, gate, AUQ block, or contract clause is modified. /CJ_personal-pipeline remains web-app-agnostic by default. | Pending |

## Verification Steps

<!-- How was the fix verified beyond the test cases above? -->

- [ ] Local `./scripts/validate.sh` exits 0
- [ ] Local `./scripts/test.sh` exits 0 (full suite)
- [ ] `grep -n '/qa' skills/CJ_personal-pipeline/pipeline.md` shows the new line at the expected location
- [ ] `git diff main -- skills/CJ_personal-pipeline/pipeline.md` shows exactly one added line (no removals, no other modifications)
- [ ] Pre-ship `./scripts/check-version-queue.sh` confirms next free VERSION slot
- [ ] CI run on PR is green (GitHub Actions)
- [ ] Post-deploy: invoke `/CJ_personal-pipeline` on a real work-item; confirm the `/qa` line appears in the end-of-run `Next:` block at the expected location (deferred until F000009 update-check flow propagates the new pipeline.md to `~/.claude/`)
- [ ] Post-deploy: confirm `skills-deploy install` continues to succeed on a machine without gstack installed (workbench-portability invariant)

## Environments Tested

| Environment | Build | Result |
|------------|-------|--------|
| macOS Darwin 25.3.0 (local dev) | claude/epic-williams-a2c0c2 | Pending |
| GitHub Actions CI (Ubuntu) | PR build | Pending |
