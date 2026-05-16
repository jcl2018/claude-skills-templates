---
type: test-spec
parent: S000054
feature: F000025
title: "Shared cj-worktree-init.sh helper + CJ_goal_run/CJ_goal_todo_fix preamble integration — Test Specification"
version: 1
status: Approved
date: 2026-05-16
author: chjiang
spec: SPEC.md
reviewers: []
---

## Smoke Tests

| # | Tag | AC | Check | What It Validates | Script/Command |
|---|-----|-----|-------|-------------------|----------------|
| S1 | core | AC-1, AC-12 | Helper test cases all pass | Helper emits valid JSON across all 5 scenarios | `bash tests/cj-worktree-init.test.sh` |
| S2 | core | AC-11 | scripts/test.sh regression assertion fires when preamble missing | Both target SKILL.md files contain the worktree-init preamble block | `bash scripts/test.sh` (full suite green) |
| S3 | core | AC-1 | Helper --dry-run mode emits valid JSON without filesystem mutation | Contract integrity for the helper in isolation | `bash scripts/cj-worktree-init.sh --caller run --dry-run \| jq -r '.state'` returns `created` |
| S4 | core | AC-3 (preamble wiring) | grep that preamble block is in /CJ_goal_run SKILL.md | Preamble wiring present and intact | `grep -q 'cj-worktree-init.sh --caller run' skills/CJ_goal_run/SKILL.md` |
| S5 | core | AC-13 | TODOS row exists for /CJ_goal_investigate deferred work | Tracked followup is in place | `grep -qi 'CJ_goal_investigate.*worktree' TODOS.md` |

## E2E Tests

| # | Tag | AC | Scenario | Steps (as a real user would) | Expected Outcome | Rubric |
|---|-----|-----|----------|------------------------------|------------------|--------|
| E1 | core | AC-2 | /CJ_goal_run on main creates a worktree | 1. `cd ~/Documents/projects/claude-skills-templates`<br>2. `git checkout main`<br>3. Confirm clean: `git status`<br>4. Invoke `/CJ_goal_run <some-design-doc>`<br>5. Observe stdout for `[worktree] created cj-run-...`<br>6. Confirm cwd is now under `.claude/worktrees/cj-run-...` (or output shows pipeline ran there)<br>7. After completion, `cd ~/Documents/projects/claude-skills-templates && git status` | A new worktree `.claude/worktrees/cj-run-<ts>-<pid>/` exists on branch `cj-run-<ts>-<pid>`; the main checkout's `git status` post-run shows no new untracked files | Pass: worktree created + main clean. Fail: missing worktree OR main has new untracked files |
| E2 | resilience | AC-5 | Conductor already-in-worktree no-ops | 1. `cd .claude/worktrees/<some-existing-worktree>/`<br>2. Invoke `/CJ_goal_run <doc>`<br>3. Observe stdout | `[worktree] already in <name>` echo; orchestrator runs in-place; no nested worktree created | Pass: detected + in-place run. Fail: nested worktree or error |
| E3 | usability | AC-6 | --no-worktree opt-out | 1. `cd ~/.../claude-skills-templates`<br>2. `git checkout main`<br>3. Invoke `/CJ_goal_run --no-worktree <doc>`<br>4. Observe stdout | `[worktree] opted_out` (or similar) echo; no worktree created; orchestrator runs on main | Pass: no worktree creation. Fail: worktree created despite flag |
| E4 | usability post-ship | AC-7 | --quiet gates echo (cron-safe) | 1. Invoke `/CJ_goal_todo_fix --quiet --max-drain 3` from main<br>2. Capture stdout | No `[worktree]` lines on stdout; per-iteration worktrees still created (visible in `.claude/worktrees/`) | Pass: empty stdout for worktree-init. Fail: echo leaks |
| E5 | resilience | AC-8 | Dirty-checkout halt | 1. From main, make an uncommitted edit (e.g. `echo ' ' >> README.md`)<br>2. Invoke `/CJ_goal_run <doc>` (NOT --quiet)<br>3. Observe stderr/stdout | `[worktree] ERROR: dirty checkout: stash/commit or pass --no-worktree`; exit 1; no worktree created | Pass: clear halt message. Fail: silent abandonment or unexpected behavior |

## Coverage Gaps

| Gap | Why Not Tested | Risk Accepted |
|-----|----------------|---------------|
| `git worktree add` failure path beyond retry-once | Hard to deterministically reproduce in CI; the retry-once mitigation is well-understood | Worst case: helper emits `state=failed`, preamble exits 1; user investigates manually |
| Helper unreachable WARN path | Requires manipulating `~/.claude/.skills-templates.json` outside the workbench | Mitigated by the visible-WARN design; not a silent failure mode |
| `/CJ_goal_investigate` preamble | Out of scope (parent worktree unmerged) | Deferred via TODOS.md row; followup will copy-paste preamble + add test.sh assertion |
