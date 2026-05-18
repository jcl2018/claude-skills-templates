---
name: "drain-one-todo silent in-place scaffold when worktree helper unavailable"
type: defect
id: "D000024"
status: active
created: "2026-05-18"
updated: "2026-05-18"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "claude/serene-bhabha-13ca63"
blocked_by: ""
auto_scaffolded: true
promoted_from_draft: ".inbox/drain_silent_fallthrough_inplace_scaffold"
---

<!-- Auto-scaffolded by /CJ_goal_investigate: zero-match fragment "drain-one-todo.sh
     silently scaffolds a drained TODO into the current (possibly dirty) branch
     when cj-worktree-init.sh is unavailable, instead of halting loudly" captured
     as draft .inbox/drain_silent_fallthrough_inplace_scaffold, promoted to
     D000024 after /investigate populated a root cause (Iron-Law gate passed).
     Domain defaulted to 'uncategorized' (pipeline v1.1 contract; domain
     inference deferred to v1.2) — `mv` to a more specific subdir if desired.
     Distinct root cause from D000021 (path resolution, PR #158, v4.6.11). -->

## Lifecycle

### Phase 1: Track

1. Document reproduction steps in the Log section
2. Working branch: `claude/serene-bhabha-13ca63`
3. Scaffold required docs: D000024_RCA.md + D000024_test-plan.md
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

1. Simulated deployed / helper-unavailable layout: `~/.claude/.skills-templates.json`
   with no usable `.source`, `cj-worktree-init.sh` unreachable everywhere, and
   the run dir not a git repo (so the `BASH_SOURCE`-relative in-repo fallback
   also fails) — i.e. `$_WT_HELPER` resolves empty.
2. Invoke drain dispatch: `drain-one-todo.sh dispatch <heading> <session>`
   (the path `/CJ_goal_todo_fix --max-drain N` and `/CJ_goal_run` Phase 5 use).
3. **Pre-fix observe:** the `if [ -x "$_WT_HELPER" ]` guard at
   `drain-one-todo.sh:226` is false; lines 246-248 are pure comments with no
   code; execution silently falls through and delegates to `todo_fix.sh`,
   scaffolding the drained TODO into the CURRENT (possibly dirty / unrelated)
   branch — destroying F000025/S000054 per-TODO worktree isolation. Operator
   hit exactly this in production: a scaffold dispatched into uncommitted WIP
   on `fix/option-cost-per-share` (a downstream consumer repo, since cleaned up;
   out of scope for this workbench defect).

Deterministic repro: `tests/drain-one-todo-helper-unavailable.test.sh` Case 2
(deployed layout + unreachable helper — FAILS pre-fix: dispatch exits 0,
`todo_fix.sh` delegated tripwire fires; PASSES post-fix: exit 2, halted RESULT,
tripwire never fires).

## Todos

- [x] Root-cause the silent-fallthrough (distinct from D000021 path resolution).
- [x] Apply fail-loud halt when worktree helper unreachable in drain context.
- [x] Add regression test proving FAIL pre-fix / PASS post-fix (no in-place scaffold).
- [x] Wire the regression test into `scripts/test.sh` (after the D000021 block).
- [ ] `/ship` + `/land-and-deploy` (driven by /CJ_goal_investigate chain).

## Log

- 2026-05-18: Created (auto-scaffolded from draft). Symptom: in drain mode, when
  `cj-worktree-init.sh` is unavailable, `drain-one-todo.sh` silently dispatched
  the first scaffold into the current dirty branch (operator hit: scaffold
  landed in uncommitted WIP on unrelated branch `fix/option-cost-per-share`),
  destroying F000025/S000054 per-TODO worktree isolation, instead of halting
  the drain iteration. Distinct root cause from D000021 (path resolution, PR
  #158, v4.6.11) — D000021's RCA Insights explicitly flagged this "silent
  failure mode" as scoped out. Root-caused by `/investigate` (dispatched by
  `/CJ_goal_investigate`).

## PRs

<!-- PR link added at /ship time. -->

## Files

- `skills/CJ_goal_todo_fix/scripts/drain-one-todo.sh` — replaced the silent
  comment-only fallthrough (old lines 246-248) with a fail-loud guard
  `if [ ! -x "$_WT_HELPER" ]`: release lock, stderr diagnostic,
  `RESULT: STATUS=halted; ... REASON=worktree-helper-unavailable`, `exit 2` —
  structurally consistent with the adjacent `worktree-cd-failed` and
  `todo_fix.sh-not-found` halts. Reachable-but-non-created states
  (failed/detected/skipped/opted_out) still degrade gracefully (distinct from
  "unreachable").
- `tests/drain-one-todo-helper-unavailable.test.sh` — new 2-case regression
  test (Case 1 static: fail-loud guard present; Case 2 behavioral: deployed
  layout + unreachable helper → non-zero exit + halted RESULT +
  `todo_fix.sh` tripwire never fires).
- `scripts/test.sh` — wired the new regression test into the suite after the
  D000021 block.

## Insights

- **D000021 fixed the path, not the silence.** D000021 (PR #158) corrected
  *how* `cj-worktree-init.sh` is located (manifest `.source` primary). This
  defect is the orthogonal *what-if-it-is-still-unreachable* half: the
  `[ -x ]` guard turning an unreachable helper into a silent no-op that runs
  the scaffold in-place. D000021's own RCA Insights named this exact failure
  mode and deliberately scoped it out — confirming a distinct root cause, not
  a regression.
- **Fail-loud only where isolation is load-bearing.** The halt is DRAIN-context
  only (`drain-one-todo.sh dispatch` is invoked solely by the drain loop).
  Single-TODO mode has its own SKILL.md worktree preamble and never reaches
  this block, so its graceful degradation is intentionally untouched. The
  reachable-but-non-created states (detected = already isolated by a Conductor
  worktree; opted_out = `--no-worktree`) still continue without `cd` because
  the helper actually ran and made a deliberate decision.

## Journal

- [auto-scaffolded] 2026-05-18: /CJ_goal_investigate captured fragment
  "drain-one-todo.sh silently scaffolds a drained TODO into the current
  (possibly dirty) branch when cj-worktree-init.sh is unavailable, instead of
  halting loudly" as draft .inbox/drain_silent_fallthrough_inplace_scaffold,
  then promoted to D000024 after /investigate populated the root cause. Domain
  defaulted to 'uncategorized'; `mv` to a more specific subdir if desired.
- [decision] 2026-05-18: Operator premise gate — framed as a NEW defect
  (D000024), not a re-open of the merged/shipped D000021; scope confirmed
  workbench-only (`drain-one-todo.sh` hardening); downstream
  `fix/option-cost-per-share` consumer-repo WIP explicitly out of scope.
- [impl] 2026-05-18: 3-file fix (≤5 blast radius) — `drain-one-todo.sh`
  fail-loud guard, new `tests/drain-one-todo-helper-unavailable.test.sh`,
  `scripts/test.sh` wiring.
- [smoke-pass] 2026-05-18: Orchestrator independently verified (not trusting
  subagent): new regression test PASS post-fix (0 failures), revert-proven
  FAIL pre-fix by /investigate. `./scripts/validate.sh` PASS (0 errors / 0
  warnings). The single `test-deploy.sh` suite failure is pre-existing +
  orthogonal (stale global-deploy version artifact 4.6.11 vs 4.6.7, proven
  via `git stash` by /investigate — same artifact D000021's RCA documented).
- 2026-05-18 [qa-smoke] 1 (regression Case 1): green — `tests/drain-one-todo-helper-unavailable.test.sh` Case 1 OK (fail-loud guard present: `RESULT: STATUS=halted; REASON=worktree-helper-unavailable`)
- 2026-05-18 [qa-smoke] 2 (regression Case 2): green — same test Case 2 OK (deployed layout + unreachable helper → exit 2, halted RESULT, `todo_fix.sh` tripwire never fires; no in-place scaffold); Failures: 0, RESULT: PASS, exit=0
- 2026-05-18 [qa-smoke-manual] 3 (revert proof): pending human verification — destructive (reverts the fix); already revert-proven by /investigate (FAIL pre-fix Failures:4 / PASS post-fix), not re-run in QA to keep the working tree intact
- 2026-05-18 [qa-smoke] 4 (no regression): green — `tests/cj-worktree-init.test.sh` 5/5 OK + `tests/drain-one-todo-worktree-resolve.test.sh` OK (safe graceful-degradation states + in-repo/deployed happy path + D000021 sibling preserved)
- 2026-05-18 [qa-smoke-summary] green: 3/3 non-manual rows green (1 manual row pending). `./scripts/validate.sh` PASS (0 errors / 0 warnings).
- 2026-05-18 [qa-pass] D000024 (defect): green smoke from test-plan rows (4 rows; 3 automated green, 1 manual revert-proof deferred). No qa-owned Phase 2 gates per template; Phase 3 `Test-plan verified` gate awaits /ship-time inference.
