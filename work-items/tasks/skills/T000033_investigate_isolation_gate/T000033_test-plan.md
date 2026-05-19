---
type: test-plan
parent: T000033
title: "Isolation gate before /CJ_goal_investigate subagent dispatch — Test Plan"
date: 2026-05-19
author: chjiang
status: Draft
---

<!-- Scope: ONE task — add a read-only `--assert-isolated` verdict mode to the
     shared cj-worktree-init.sh and wire it as an enforced isolation gate before
     /CJ_goal_investigate's source-writing subagent dispatch. Cases are concrete
     and reproducible. -->

## Scope

The fix changes three surfaces (all workbench-only, no downstream-consumer surface):

- `scripts/cj-worktree-init.sh` — new `--assert-isolated` read-only verdict mode (single self-contained ordered-ladder block inserted after the `emit_json` definition at `:84`, before the Step 1 `--no-worktree` block at `:86`; gated by `if [ "$ASSERT_ISOLATED" = "1" ]`, `exit`s unconditionally). The existing 5 mutating states + exit codes stay byte-unchanged.
- `skills/CJ_goal_investigate/pipeline.md` — Step 5 isolation gate (first ```bash``` block of `## Step 5`, before the `ROLE:` template): 2-level helper-path re-resolution, `RESUME_ROW` hard idempotency guard, exact gate argv, helper-unreachable→HALT, draft-aware `resume_cmd`, C7 terminal block, `[investigate-not-isolated]` halt-taxonomy row.
- `skills/CJ_goal_investigate/SKILL.md` — matching `[investigate-not-isolated]` / `halted_at_investigate_not_isolated` halt-taxonomy row.
- `tests/cj-worktree-init.test.sh` (+ possibly `scripts/test.sh`) — 8 verdict cases + pipeline.md grep regression assertion.

Out of scope (deferred): wiring `--assert-isolated` into `/CJ_goal_run` + `/CJ_goal_todo_fix` (tracked TODOS.md follow-up, Open Q #2); reconciling the pre-existing inconsistent halt-count strings across SKILL.md/pipeline.md (Open Q #3).

## Regression Test Cases

| # | Test Case | Steps | Expected Result | Status |
|---|-----------|-------|-----------------|--------|
| 1 | Verdict: inside a linked worktree | `cd` into a linked git worktree (git-dir != git-common-dir); run `cj-worktree-init.sh --caller investigate --assert-isolated` | `state=isolated`, exit 0 | Pending |
| 2 | Verdict: clean `main`, no worktree | On primary checkout, `main` branch, clean tree; run the gate | `state=not_isolated`, exit ≠0 | Pending |
| 3 | Verdict: dirty tree on a feature branch | On a non-main branch with an uncommitted/staged change; run the gate | `state=dirty`, exit ≠0 (dirty checked BEFORE branch rule) | Pending |
| 4 | Verdict: clean feature branch | On a non-main/master branch, clean tree, primary checkout; run the gate | `state=isolated`, exit 0 | Pending |
| 5 | Verdict: `--no-worktree` + clean (escape hatch) | Clean checkout, pass `--no-worktree`; run the gate | `state=isolated`, exit 0, override recorded in `note` | Pending |
| 6 | Verdict: `--no-worktree` + dirty (hatch is NOT a bypass) | Dirty tree, pass `--no-worktree`; run the gate | `state=dirty`, exit ≠0 (dirty wins over the override — proves gap #3 not reopened) | Pending |
| 7 | Verdict: not a git repo | Run the gate from a non-git directory | `state=not_a_repo`, exit ≠0 | Pending |
| 8 | Verdict: detached HEAD on primary checkout | Detached HEAD (empty `$BRANCH`), not in a worktree, primary checkout; run the gate | `state=not_isolated`, exit ≠0 | Pending |
| 9 | Existing mutating states unchanged (regression) | Run the existing `cj-worktree-init.sh` mutating paths (no `--assert-isolated`) used by SKILL.md actor | All 5 existing states + exit codes byte-identical to pre-change behavior | Pending |
| 10 | pipeline.md Step 5 gate present (static grep) | `grep` pipeline.md `## Step 5` block | Contains the `--assert-isolated` gate invocation AND the draft-aware `resume_cmd` | Pending |
| 11 | Halt journal entry on non-zero verdict | Drive `/CJ_goal_investigate` Step 5 with a `not_isolated`/`dirty` verdict | Journal entry appended with `[investigate-not-isolated]`, `next_action=`, draft-aware `resume_cmd=`, `raw_output_path=N/A`; C7 block emitted; `exit 1` → `end_state=halted_at_investigate_not_isolated`; subagent provably NOT dispatched | Pending |
| 12 | Draft-aware resume_cmd (no broken empty `$DEFECT_ID`) | Trigger the Step 5 halt on the `IS_DRAFT=1` path | `resume_cmd=/CJ_goal_investigate "$DRAFT_FRAGMENT"` (NOT an empty-`$DEFECT_ID` broken command) | Pending |
| 13 | Workbench self-dev: repo-local helper resolves, no false-halt | Run `/CJ_goal_investigate` inside this repo with NO deployed `$HOME/.claude/.skills-templates.json`, repo-local `scripts/cj-worktree-init.sh` present, isolation-sufficient | Helper resolved via repo-local fallback; gate verdicts `isolated`; no false-halt | Pending |
| 14 | Idempotency: resume Rows 2/3/4/5 unaffected | Drive a legitimate resume (RESUME_ROW != 1) through the pipeline | Step 5 gate skipped via the hard `RESUME_ROW` guard; no false halt on legitimate resume | Pending |
| 15 | D000024-class scenario now HALTs | Simulate helper genuinely unreachable on `main` (both 2-level probe paths absent) | Step 5 gate → `state=helper_unreachable`, HALT (no silent in-place source write) | Pending |
| 16 | `--dry-run` / `--quiet` not forwarded to the gate | Invoke `/CJ_goal_investigate --dry-run` and (separately) `--quiet` | Gate argv pinned to `--caller investigate --assert-isolated` (+ `--no-worktree` iff operator passed it); `--dry-run`/`--quiet`/`--force-create` never forwarded; `--dry-run` still exits upstream at Step 3.5 | Pending |
| 17 | `--no-worktree` marker-file wiring (P1 regression — /ship pre-landing review) | static grep `pipeline.md` via `tests/cj-worktree-init.test.sh` | Step 1 parses `--no-worktree)`→`NO_WORKTREE=1` + persists RUN_ID-scoped `.operator-no-worktree` marker (same fence as RUN_ID); Step 5.0 re-reads it via model-carried RUN_ID; the dead `${NO_WORKTREE:-0}` shell-var conditional is ABSENT | Pass |

## Verification Steps

<!-- How was the fix verified beyond the test cases above? -->

- [x] Local build / lint succeeds (`./scripts/validate.sh` green — 0 err/0 warn)
- [x] Full test suite passes (`./scripts/test.sh` green — 0 failures)
- [x] `tests/cj-worktree-init.test.sh` — all 8 `--assert-isolated` verdict cases (a, b, c, d, e1, e2, f, g) pass (run directly, 13/13)
- [x] pipeline.md-side grep regression assertions pass — TWO now: Step 5.0 gate + draft-aware `resume_cmd`, AND the `--no-worktree` marker-file wiring (P1 fix)
- [x] Manual: verdict block confirmed AFTER `emit_json` end (live file: `emit_json` closes at `cj-worktree-init.sh:89`, NOT the design's stale cited `:84`) and BEFORE the `--no-worktree`/opted_out block (`:187-192`); re-grepped against the live file at /ship time
- [x] Manual: `set -euo pipefail` safety — runtime `--assert-isolated` returns valid JSON with no exit-127 (`emit_json` reachable); probes use the same `2>/dev/null` guard pair as the existing dirty check
- [x] Manual: existing 5 mutating states + exit codes byte-unchanged (cj-worktree-init.test.sh cases 1–5: created/detected/opted_out/created/failed-interactive/skipped-quiet all pass)
- [x] `/CJ_personal-workflow check` — no MISSING/DRIFT on the work-item (faithful Directory-Mode check run at post-scaffold + post-implement gates)

## Environments Tested

| Environment | Build | Result |
|------------|-------|--------|
| macOS (workbench, zsh) | claude/unruffled-chaplygin-3af3c7 | Pending |
