---
name: "Shared cj-worktree-init.sh helper + CJ_goal_run/CJ_goal_todo_fix preamble integration"
type: user-story
id: "S000054"
status: active
created: "2026-05-16"
updated: "2026-05-16"
parent: "F000025"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "main"
blocked_by: ""
---

<!-- Atomic single-story: helper + 2 caller preambles + drain-loop integration +
     test.sh assertion + helper test + TODOS row + CLAUDE.md note all ship in one
     PR. Parent F000025_DESIGN.md is sufficient context — this story's DESIGN.md
     is a brief stub. -->

## Lifecycle

### Phase 1: Track

1. Read parent tracker to understand scope
2. Create working branch: `git checkout -b feat/default_worktree_for_cj_goal` (or use parent's branch if shipping in same PR)
3. Scaffold work item directory and TRACKER.md
4. Distill `DESIGN.md` from the /office-hours output (own session or parent's) — from `templates/doc-DESIGN.md`
5. Scaffold `SPEC.md` (requirements, acceptance criteria, architecture, tradeoffs) — from `templates/doc-SPEC.md`
6. Scaffold `TEST-SPEC.md` (smoke + E2E test scenarios) — from `templates/doc-TEST-SPEC.md`
7. Break into child tasks if scope warrants decomposition (per WORKFLOW.md, tasks are optional for atomic stories)

**Gates:**
- [x] /office-hours design referenced (own or parent's, captured in DESIGN.md)
- [x] Working branch created (`branch` field populated)
- [x] DESIGN + SPEC + TEST-SPEC scaffolded
- [x] Acceptance criteria defined
- [x] Tasks broken down (or N/A — atomic story)

### Phase 2: Implement

1. Read DESIGN + SPEC for context
2. Implement according to architecture decisions in SPEC
3. Run smoke tests as you go (TEST-SPEC `## Smoke Tests` table)
4. Run `/CJ_personal-workflow check` on modified docs after updates
5. Update tracker: move through lifecycle phases, add journal entries
6. Update Files section with changed file paths

**Gates:**
- [ ] Acceptance criteria verified met
- [ ] Smoke tests pass
- [ ] Todos section reflects remaining work (no stale items)
- [ ] Files section updated with changed files

### Phase 3: Ship

1. Run `/CJ_personal-workflow check` — verify all validation passes
   → should show PASS for template, lifecycle, traceability badges
2. Verify smoke tests pass in CI (automated regression)
3. Walk E2E manually — drive the feature as a user would (TEST-SPEC `## E2E Tests` table)
4. Ensure all child tasks (if any) have shipped
5. Run `/ship` — creates PR, bumps version, updates changelog (includes pre-landing code review)
6. Run `/land-and-deploy` — merges PR and verifies deployment

❌ If `/CJ_personal-workflow check` finds issues: fix findings, re-run until clean
❌ If smoke or E2E fails: fix, re-run

**Gates:**
- [ ] `/CJ_personal-workflow check` — validation passed
- [ ] Smoke tests pass in CI
- [ ] E2E walked manually
- [ ] All children shipped (if any)
- [ ] `/ship` — PR created (with pre-landing review)
- [ ] `/land-and-deploy` — merged and deployed

## Acceptance Criteria

- [ ] `scripts/cj-worktree-init.sh` shipped, executable, ~60 lines, emits single-line JSON
- [ ] Helper accepts `--caller {run|investigate|todo} [--no-worktree] [--quiet] [--dry-run] [--force-create]`
- [ ] `/CJ_goal_run/SKILL.md` preamble integrates helper BEFORE Path Resolution, conditional on `[ $# -gt 0 ]`
- [ ] `/CJ_goal_todo_fix/SKILL.md` preamble integrates helper BEFORE Path Resolution, single-TODO mode only
- [ ] `skills/CJ_goal_todo_fix/scripts/drain-one-todo.sh` calls helper with `--force-create --quiet` per iteration via BASH_SOURCE relative path
- [ ] `scripts/test.sh` includes regression assertion: both target SKILL.md files contain the worktree-init preamble block
- [ ] `tests/cj-worktree-init.test.sh` exists, executable, passes 5 cases
- [ ] `TODOS.md` includes a row capturing the deferred `/CJ_goal_investigate` worktree wiring (P3, S; "Add worktree-default preamble to /CJ_goal_investigate — once parent worktree lands; copy-paste from /CJ_goal_run's preamble; one-line test.sh assertion.")
- [ ] `CLAUDE.md` includes a one-line note that `/CJ_goal_run + /CJ_goal_todo_fix` auto-worktree on main
- [ ] `scripts/validate.sh` exits 0

## Todos

- [ ] Write `scripts/cj-worktree-init.sh` (helper, JSON output, dirty-check, PID-suffix, --force-create, retry-once on collision)
- [ ] Write `tests/cj-worktree-init.test.sh` (5 cases)
- [ ] Edit `skills/CJ_goal_run/SKILL.md` (preamble worktree-init block BEFORE Path Resolution; `--caller run`)
- [ ] Edit `skills/CJ_goal_todo_fix/SKILL.md` (preamble worktree-init block BEFORE Path Resolution; `--caller todo`; single-TODO mode only)
- [ ] Edit `skills/CJ_goal_todo_fix/scripts/drain-one-todo.sh` (per-iteration helper call with `--force-create --quiet` via BASH_SOURCE)
- [ ] Edit `scripts/test.sh` (regression assertion for preamble wiring + invoke new helper test)
- [ ] Edit `TODOS.md` (deferred row for /CJ_goal_investigate worktree wiring)
- [ ] Edit `CLAUDE.md` (one-line note: /CJ_goal_run + /CJ_goal_todo_fix auto-worktree on main)

## Log

- 2026-05-16: Created. /CJ_personal-pipeline scaffold per design 20260516-121928.

## PRs

## Files

- `scripts/cj-worktree-init.sh` (new)
- `tests/cj-worktree-init.test.sh` (new)
- `skills/CJ_goal_run/SKILL.md` (modified)
- `skills/CJ_goal_todo_fix/SKILL.md` (modified)
- `skills/CJ_goal_todo_fix/scripts/drain-one-todo.sh` (modified)
- `scripts/test.sh` (modified)
- `TODOS.md` (modified)
- `CLAUDE.md` (modified)

## Insights

- The "Revised Design Specifics (post-Eng-review)" section in the design doc is the binding contract; the earlier "Design specifics" section is superseded.
- Sensitive surfaces touched: `scripts/validate.sh` is NOT directly modified, but `scripts/test.sh` is. Skill scripts under `skills/CJ_goal_todo_fix/scripts/` count as the "skill scripts" sensitive-surface family per pipeline.md surface table.
- Drain mode design choice (a) — one worktree per drained TODO — was selected over (b) one-per-session-reused because /ship Gate #2 enforces one PR per TODO, which requires distinct branches per drained item.

## Journal

- [orchestrator] 2026-05-16T13:59:32Z pre-scaffold check: branch (d) clean-slate; S000054 scaffolded as single child of F000025. RUN_ID=20260516-135932-66386.
- [orchestrator] 2026-05-16T21:16:28Z Phase 2 implement complete via /CJ_personal-pipeline inline impl (no Agent subagent available in this harness; orchestrator wrote files directly). All 8 file edits per SPEC Components Affected.
- [qa-smoke-summary] 2026-05-16T21:16:28Z green — 5/5 smoke tests pass (S1 helper test, S2 test.sh suite, S3 JSON shape, S4 preamble grep, S5 TODOS row).
- [qa-pass] 2026-05-16T21:16:28Z Phase 3 smoke complete; e2e=ambiguous (E2E rows require live /CJ_goal_run / /CJ_goal_todo_fix invocation on main — out of pipeline scope, will be walked manually before /ship per F000025 Acceptance Criteria).
- [qa-e2e-deferred] 2026-05-16T21:16:48Z E2E rows E1-E5 in S000054_TEST-SPEC.md require live /CJ_goal_run + /CJ_goal_todo_fix invocation from main (not reachable from within the pipeline orchestrator); deferred to post-ship manual walkthrough per F000025 Acceptance Criteria + ROADMAP Success Criteria. Smoke tests (S1-S5) cover all structurally-verifiable acceptance criteria.
- [auto-final-gate-suppressed] 2026-05-16T21:17:08Z 0 mechanical, 0 taste, 2 user-challenge-approved; decisions at /Users/chjiang/.gstack/analytics/CJ_personal-pipeline-auto-decisions.jsonl (filter run_id=20260516-135932-66386)
