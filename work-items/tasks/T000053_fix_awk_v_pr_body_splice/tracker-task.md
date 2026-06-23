---
name: "Fix the awk -v multi-line PR-body splice in the cj_goal pipelines"
type: task
id: "T000053"
status: active
created: "2026-06-22"
updated: "2026-06-22"
parent: ""
repo: "claude-skills-templates"
branch: "todo/T000053-awk-pr-body-splice"
blocked_by: ""
---

## Lifecycle

### Phase 1: Track
- [x] Scope read (TODOS row P2/S)
- [x] Working branch created (`todo/T000053-awk-pr-body-splice` off origin/main v6.0.81)
- [x] Required docs scaffolded (test-plan)
- [x] Files section populated

### Phase 2: Implement
- [x] Core changes made (4 pipeline.md splices + task T000044 path reconcile)
- [x] Files section updated with changed files

### Phase 3: Ship
- [x] `validate.sh` passes (0 errors, 0 warnings; portability FINDINGS=0; Check 24 green)
- [x] Test-plan verified (TC1–6 + functional splice regression all PASS; `scripts/test.sh` Failures: 0)
- [ ] `/ship` — PR created
- [ ] `/land-and-deploy` — merged and deployed

## Todos

- [ ] Replace the `awk -v v="$_INSERT"` multi-line PR-body splice with temp-file
      composition + `gh pr edit --body-file` + a post-edit line-count sanity
      assert (re-fetch body, floor-check, retry once, best-effort/never-halt) in:
  - `skills/CJ_goal_feature/pipeline.md` (Step 4.6 — `$PR_NUMBER`)
  - `skills/CJ_goal_defect/pipeline.md` (Step 9.5 — `$PR_URL`)
  - `skills/CJ_goal_task/pipeline.md` (Step 6.6 — `$PR_NUMBER`)
- [ ] Reconcile the `/CJ_goal_task` scratch-path mismatch (T000044): task
      Step 6.6 reads `.cj-goal-task/registered-doc-verdicts.md` but the shared
      producer writes the LITERAL `.cj-goal-feature/registered-doc-verdicts.md`.
- [ ] Verify each replacement bash block shellchecks cleanly when extracted.
- [ ] Confirm `skills/CJ_goal_todo_fix/SKILL.md` Step 5.6 prose stays accurate
      (it delegates to the feature/defect splice — no own awk block to fix).

## Log

- 2026-06-22: Created from TODOS.md P2 row via `/CJ_goal_todo_fix` (sensitive-surface
  gate cleared by operator — full-chain build authorized). Built in a fresh
  `cj-todo-*` worktree off origin/main (the Conductor branch carried a redundant
  unmerged T000051 DONE-mark commit + a stale VERSION, so a clean base was used).
- 2026-06-22: Implemented the temp-file + `--body-file` + post-edit floor/retry
  splice in all FOUR `pipeline.md` files (feature/defect/task/todo_fix), replacing
  the BSD-awk-fragile `awk -v v="$_INSERT"`/`"$_VERDICTS"` wiper. Reconciled the
  task registered-doc read path to the producer's literal `.cj-goal-feature/`
  (T000044). QA green: grep TC1–5, shellcheck CLEAN ×4, functional regression
  (insert/no-wipe/idempotent/append) PASS, `validate.sh` PASS, `test.sh` Failures: 0.

## PRs

## Files

- `skills/CJ_goal_feature/pipeline.md` (Step 4.6 splice; `$PR_NUMBER`)
- `skills/CJ_goal_defect/pipeline.md` (Step 9.5 splice; `$PR_URL`)
- `skills/CJ_goal_task/pipeline.md` (Step 6.6 splice; `$PR_NUMBER`; + T000044 read-path reconcile)
- `skills/CJ_goal_todo_fix/pipeline.md` (Step 5.6 splice; `$PR_URL`; registered-doc-only `$_VERDICTS` variant — the genuine "fourth pipeline"; `SKILL.md` is prose-only)
- `work-items/tasks/T000053_fix_awk_v_pr_body_splice/` (tracker + test-plan)

NOTE: the TODO row named "`skills/CJ_goal_todo_fix` Step 5.6"; on inspection the
executable splice lives in `CJ_goal_todo_fix/pipeline.md` (not `SKILL.md`, which
is prose that references the shared splice). All four `pipeline.md` files carried
the `awk -v` wiper.

## Insights

- The bug: BSD awk (macOS default) rejects a newline in a `-v` value
  (`newline in string`); the failed command substitution yields an empty/partial
  body, and the subsequent `gh pr edit --body "$_NEW_BODY"` then REPLACES the PR
  body with it (a wipe). Hit live on PR #259 (F000059).
- Only 3 pipeline files carry the executable splice block; `CJ_goal_todo_fix`'s
  Step 5.6 is prose that reuses the feature/defect implementation, so the
  "four pipelines" framing maps to 3 code edits + 1 prose verification.
- The first awk (strip existing `### Registered-doc requirements` / `### Portability`
  blocks) takes NO `-v` arg and is safe — only the SECOND awk (`-v v="$_INSERT"`)
  is the wiper. The fix swaps just the insertion path to a file-fed approach.

## Journal

<!-- Source: TODOS.md ### cj_goal PR-body verdict splice uses `awk -v` with a multi-line payload — wipes the PR body on macOS (P2, S) -->
