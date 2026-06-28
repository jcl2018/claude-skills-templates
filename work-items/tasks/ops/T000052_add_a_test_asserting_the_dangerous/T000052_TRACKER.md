---
name: "Add a test asserting the dangerous multi-line 'awk -v' PR-body splice idiom never reappears in the four CJ_goal_* pipeline.md files"
type: task
id: "T000052"
status: active
created: "2026-06-28"
updated: "2026-06-28"
parent: ""
repo: "/Users/chjiang/Documents/projects/claude-skills-templates/.claude/worktrees/nervous-tesla-46a57e"
branch: "cj-task-20260628-131238-prbody-splice-guard"
blocked_by: ""
---

<!-- Prerequisite (optional): If this task came from /office-hours, distill the
     design context into the ## Insights section below. Otherwise (per the
     skip-design-for-small-todos convention in WORKFLOW.md), proceed without
     a separate DESIGN.md — the parent user-story's DESIGN already covers it. -->

## Lifecycle

### Phase 1: Track

1. Read parent tracker to understand scope and acceptance criteria
2. Create working branch: `git checkout -b feat/add_a_test_asserting_the_dangerous`
   (use parent's branch if the task ships in the same PR; create a new branch if it warrants its own PR)
3. Scaffold required docs:
   - `test-plan.md` (test scenarios for this task) — from `templates/doc-test-plan.md`
4. Populate Files section with expected changed files
5. Write initial Todos from parent's acceptance criteria

**Gates:**
- [ ] Parent scope read (parent tracker reviewed)
- [ ] Working branch created (`branch` field populated)
- [ ] Required docs scaffolded (test-plan)
- [ ] Files section populated

### Phase 2: Implement

1. Work from `/office-hours` design doc + parent's acceptance criteria + your Todos
   → design doc at `~/.gstack/projects/add_a_test_asserting_the_dangerous/`
2. Commit changes incrementally with descriptive messages
3. Update Todos section — check off completed items, add discoveries
4. Update Files section with actual changed files

**Gates:**
- [ ] Core changes committed (>=1 commit SHA in Log)
- [ ] Todos section reflects remaining work (no stale items)
- [ ] Files section updated with changed files

### Phase 3: Ship

1. Run `/CJ_personal-workflow check` — verify no regressions
2. Verify test-plan: all test scenarios passing
3. Run `/ship` — creates PR, bumps version, updates changelog (includes pre-landing code review)
4. Run `/land-and-deploy` — merges PR and verifies deployment

❌ If tests fail: fix, re-run
❌ If CI fails: fix, push, re-run `/ship`

**Gates:**
- [ ] `/CJ_personal-workflow check` — validation passed
- [ ] Test-plan verified (all scenarios passing)
- [ ] `/ship` — PR created
- [ ] `/land-and-deploy` — merged and deployed

## Todos

<!-- Actionable items for this task. Not lifecycle duplicates — these are
     the actual things to build, fix, or investigate. -->

- [ ] Implement: Add a test asserting the dangerous multi-line 'awk -v' PR-body splice idiom never reappears in the four CJ_goal_* pipeline.md files

## Log

<!-- Chronological entries with dates and commit SHAs. Each entry records
     what happened, not what should happen. -->

- 2026-06-28: Created. Auto-scaffolded by /CJ_goal_task from topic: Add a test asserting the dangerous multi-line 'awk -v' PR-body splice idiom never reappears in the four CJ_goal_* pipeline.md files

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

- `tests/cj-goal-pr-body-splice-guard.test.sh` (new) — the guard test
- `scripts/test.sh` — hand-wired runner block (discovery is not glob-based)
- `spec/test-spec-custom.md` — `units:` row `test-cj-goal-pr-body-splice-guard` (Check 24 coverage)
- `work-items/tasks/ops/T000052_*/` — this work item

## Insights

<!-- Auto-injected from the /CJ_goal_task topic -->

Scope (from /CJ_goal_task topic): Add a test asserting the dangerous multi-line 'awk -v' PR-body splice idiom never reappears in the four CJ_goal_* pipeline.md files


<!-- Non-obvious findings worth remembering. Things that surprised you,
     patterns discovered, or context that future readers will need. -->

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

<!-- Source: /CJ_goal_task: Add a test asserting the dangerous multi-line 'awk -v' PR-body splice idiom never reappears in the four CJ_goal_* pipeline.md files -->

- 2026-06-28 [qa-smoke] 1 (clean-baseline guard): green — `bash tests/cj-goal-pr-body-splice-guard.test.sh` exits 0; all 4 pipeline.md report "no dangerous 'awk -v' payload" + the safe `--body-file` splice present.
- 2026-06-28 [qa-smoke] 2 (negative / injected idiom): green — real guard run against a temp copy with `awk -v v="$_INSERT"` injected into CJ_goal_feature/pipeline.md exits 1 and names the offender (`skills/CJ_goal_feature/pipeline.md:1197`); real repo files untouched.
- 2026-06-28 [qa-smoke] 3 (wired into suite): green — `scripts/test.sh` has a runner block (lines 1660-1665) that invokes the guard; it fired live in the full suite run (log lines 1300-1301).
- 2026-06-28 [qa-smoke] 4 (contract registration): green — `test-spec.sh --validate` (OK schema_version=1) + `--check-coverage` (rows=70 reverse_tokens=50 findings=0); unit `test-cj-goal-pr-body-splice-guard` registered (spec/test-spec-custom.md:661) + anchored, no reverse-sweep orphan.
- 2026-06-28 [qa-smoke-summary] green: 4/4 non-manual rows green (0 manual rows pending). Broader surface also green: validate.sh (0 errors / 0 warnings / PASS) + full test.sh suite (Failures: 0 / RESULT: PASS; new guard runner fired).
- 2026-06-28 [qa-audit] AUDITS=deferred,spec_updates:test-spec-custom:current(test-cj-goal-pr-body-splice-guard already registered+anchored),doc-spec-custom:none (Step 8.6a/8.6b ran inline; 8.6c/8.6d DEFERRED via DEFER_AUDIT — orchestrator runs the post-sync audit)
- 2026-06-28 [qa-pass] T000052 (task): green smoke from test-plan rows (4 rows). No qa-owned Phase 2 gates per template; Phase 3 `Test-plan verified` gate awaits /ship-time inference.
