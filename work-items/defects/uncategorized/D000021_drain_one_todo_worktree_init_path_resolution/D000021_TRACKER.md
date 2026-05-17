---
name: "drain-one-todo worktree-init path resolution"
type: defect
id: "D000021"
status: active
created: "2026-05-17"
updated: "2026-05-17"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "claude/wonderful-raman-afec8b"
blocked_by: ""
auto_scaffolded: true
promoted_from_draft: ".inbox/drain_one_todo_worktree_init_path_resolution"
---

<!-- Auto-scaffolded by /CJ_goal_investigate: zero-match fragment "drain-one-todo
     worktree-init path resolution" captured as draft .inbox/drain_one_todo_worktree_init_path_resolution,
     promoted to D000021 after /investigate populated a root cause (Iron-Law
     gate passed). Domain defaulted to 'uncategorized' (pipeline v1.1 contract;
     domain inference deferred to v1.2) — `mv` to a more specific subdir
     (e.g. skills/ or ops/) if desired. -->

## Lifecycle

### Phase 1: Track

1. Document reproduction steps in the Log section
2. Working branch: `claude/wonderful-raman-afec8b`
3. Scaffold required docs: D000021_RCA.md + D000021_test-plan.md
4. Run `/investigate` to diagnose root cause — done (dispatched by /CJ_goal_investigate)
5. Log initial symptoms and hypotheses

**Gates:**
- [x] Reproduction steps documented
- [x] Working branch created (`branch` field populated)
- [x] Required docs scaffolded (RCA + test-plan)
- [x] Root cause identified (or best hypothesis logged)

### Phase 2: Implement

**Gates:**
- [x] Fix committed
- [x] RCA doc updated
- [x] Todos section reflects remaining work (no stale items)

### Phase 3: Ship

**Gates:**
- [ ] `/CJ_personal-workflow check` — validation passed
- [ ] Test-plan verified (regression scenarios passing)
- [ ] `/ship` — PR created
- [ ] `/land-and-deploy` — merged and deployed

## Reproduction Steps

1. Deploy skills via `scripts/skills-deploy install` (puts `drain-one-todo.sh`
   at `~/.claude/skills/CJ_goal_todo_fix/scripts/`).
2. Invoke `/CJ_goal_todo_fix` drain mode so the orchestrator runs the deployed
   `~/.claude/skills/CJ_goal_todo_fix/scripts/drain-one-todo.sh dispatch <heading>`.
3. In the dispatch path, the pre-fix
   `$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)/scripts/cj-worktree-init.sh`
   resolves to `~/.claude/scripts/cj-worktree-init.sh`, which does not exist
   (`skills-deploy` never deploys repo-root `scripts/` there).
4. The `[ -x "$_WT_HELPER" ]` guard is false → the per-TODO worktree is never
   created → drain silently runs every drained TODO in-place on the current
   branch (the exact collision F000025/S000054 exists to prevent).

Deterministic repro: `tests/drain-one-todo-worktree-resolve.test.sh` Case 2
(simulated deployed layout — FAILS pre-fix: no `cj-todo-*` worktree created).

## Todos

- [x] Root-cause the path-resolution divergence (drain vs single-TODO mode).
- [x] Apply convention-aligned fix (manifest `.source` primary, BASH_SOURCE fallback).
- [x] Add regression test proving FAIL pre-fix / PASS post-fix.
- [x] Wire the regression test into `scripts/test.sh`.
- [ ] `/ship` + `/land-and-deploy` (driven by /CJ_goal_investigate chain).

## Log

- 2026-05-17: Created (auto-scaffolded from draft). Symptom: `scripts/cj-worktree-init.sh`
  unreachable from `drain-one-todo.sh` when `/CJ_goal_todo_fix` runs from the
  deployed `~/.claude/` location; drain mode silently skips per-iteration
  worktree creation and runs every drained TODO in-place, defeating
  F000025/S000054 collision-avoidance and causing `/ship` Gate #2 branch
  collisions across drained TODOs. Root-caused by `/investigate` (dispatched
  by `/CJ_goal_investigate`).

## PRs

<!-- PR link added at /ship time. -->

## Files

- `skills/CJ_goal_todo_fix/scripts/drain-one-todo.sh` — helper resolution now
  reads `~/.claude/.skills-templates.json` `.source` (workbench convention),
  BASH_SOURCE-relative path retained as in-repo / no-manifest fallback.
- `tests/drain-one-todo-worktree-resolve.test.sh` — new 2-case regression test
  (static convention assertion + behavioral deployed-layout worktree check).
- `scripts/test.sh` — wired the new regression test into the suite after the
  F000025 block.

## Insights

- **Single divergent site.** `todo_fix.sh` (single-TODO mode), the single-TODO
  `SKILL.md` preamble, and the F000009 update-check preamble all already
  resolve repo-root scripts via `~/.claude/.skills-templates.json` `.source`.
  `drain-one-todo.sh` was the lone consumer using a BASH_SOURCE-relative
  `../../..` path — correct only for the in-repo checkout, broken post-deploy.
- **Silent failure mode.** The `[ -x ]` guard turned an unreachable helper into
  a no-op rather than an error, so drain *appeared* to work while silently
  losing worktree isolation — exactly the class of bug that surfaces only as a
  downstream `/ship` Gate #2 branch collision.
- **Convention-aligned fix preferred over new deploy surface.** Option (a)
  (teach `skills-deploy` to deploy repo-root `scripts/`) was rejected: it adds
  a deployment surface that contradicts the documented "scripts stay in the
  clone; resolve via `.source`" workbench convention. Option (b) keeps the
  blast radius at one resolution block.

## Journal

- [auto-scaffolded] 2026-05-17: /CJ_goal_investigate captured fragment
  "drain-one-todo worktree-init path resolution" as draft
  .inbox/drain_one_todo_worktree_init_path_resolution, then promoted to D000021
  after /investigate populated the root cause. Domain defaulted to
  'uncategorized'; `mv` to a more specific subdir if desired.
- [decision] 2026-05-17: Adopted option (b) (manifest `.source` resolution with
  BASH_SOURCE in-repo fallback) over option (a) (new `skills-deploy` deploy
  surface) — smallest blast radius, aligns with the established workbench
  script-resolution convention.
- [impl] 2026-05-17: 3-file fix — `drain-one-todo.sh` resolution block,
  new `tests/drain-one-todo-worktree-resolve.test.sh`, `scripts/test.sh` wiring.
- [smoke-pass] 2026-05-17: New regression test PASS post-fix, FAIL (both cases)
  pre-fix (revert-proven). `./scripts/validate.sh` PASS (0 errors/0 warnings).
  `tests/cj-worktree-init.test.sh` 5/5 green. The single `test-deploy.sh`
  suite failure is pre-existing + orthogonal (stale global-deploy version
  artifact 4.6.10 vs 4.6.7, proven via `git stash`).
- 2026-05-17 [qa-smoke] 1 (regression Case 1): green — `tests/drain-one-todo-worktree-resolve.test.sh` Case 1 OK (manifest-`.source` resolution present)
- 2026-05-17 [qa-smoke] 2 (regression Case 2): green — same test Case 2 OK (deployed-layout drain created a real per-iteration `cj-todo-*` worktree); Failures: 0, RESULT: PASS, exit=0
- 2026-05-17 [qa-smoke-manual] 3 (revert proof): pending human verification — destructive (reverts the fix); already revert-proven by /investigate (FAIL pre-fix / PASS post-fix), not re-run in QA to keep the working tree intact
- 2026-05-17 [qa-smoke] 4 (fallback unchanged): green — `tests/cj-worktree-init.test.sh` 5/5 OK (in-repo / no-manifest BASH_SOURCE fallback behavior preserved)
- 2026-05-17 [qa-smoke-summary] green: 3/3 non-manual rows green (1 manual row pending). `./scripts/validate.sh` PASS (0 errors / 0 warnings).
- 2026-05-17 [qa-pass] D000021 (defect): green smoke from test-plan rows (4 rows; 3 automated green, 1 manual revert-proof deferred). No qa-owned Phase 2 gates per template; Phase 3 `Test-plan verified` gate awaits /ship-time inference.
