---
name: "Add a validate.sh check (plus a parallel scripts/test.sh integration assertion) that fails when README.md is out of sync with scripts/generate-readme.sh output, so a stale catalog-derived README cannot pass validation"
type: task
id: "T000050"
status: active
created: "2026-06-13"
updated: "2026-06-13"
parent: ""
repo: "/Users/chjiang/Documents/projects/claude-skills-templates/.claude/worktrees/heuristic-wilson-280dbe"
branch: "cj-task-readme-sync-check"
blocked_by: ""
---

<!-- Prerequisite (optional): If this task came from /office-hours, distill the
     design context into the ## Insights section below. Otherwise (per the
     skip-design-for-small-todos convention in WORKFLOW.md), proceed without
     a separate DESIGN.md — the parent user-story's DESIGN already covers it. -->

## Lifecycle

### Phase 1: Track

1. Read parent tracker to understand scope and acceptance criteria
2. Create working branch: `git checkout -b feat/add_a_validate_sh_check_plus_a_parallel`
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
   → design doc at `~/.gstack/projects/add_a_validate_sh_check_plus_a_parallel/`
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

- [ ] Implement: Add a validate.sh check (plus a parallel scripts/test.sh integration assertion) that fails when README.md is out of sync with scripts/generate-readme.sh output, so a stale catalog-derived README cannot pass validation

## Log

<!-- Chronological entries with dates and commit SHAs. Each entry records
     what happened, not what should happen. -->

- 2026-06-13: Created. Auto-scaffolded by /CJ_goal_task from topic: Add a validate.sh check (plus a parallel scripts/test.sh integration assertion) that fails when README.md is out of sync with scripts/generate-readme.sh output, so a stale catalog-derived README cannot pass validation

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. Populated during Track phase, updated during Implement. -->

## Insights

<!-- Auto-injected from the /CJ_goal_task topic -->

Scope (from /CJ_goal_task topic): Add a validate.sh check (plus a parallel scripts/test.sh integration assertion) that fails when README.md is out of sync with scripts/generate-readme.sh output, so a stale catalog-derived README cannot pass validation


<!-- Non-obvious findings worth remembering. Things that surprised you,
     patterns discovered, or context that future readers will need. -->

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

<!-- Source: /CJ_goal_task: Add a validate.sh check (plus a parallel scripts/test.sh integration assertion) that fails when README.md is out of sync with scripts/generate-readme.sh output, so a stale catalog-derived README cannot pass validation -->

- 2026-06-13 [qa-smoke] 1 (Check 25 PASSes in-sync): green — validate.sh exit 0; Check 25 emits "PASS: README.md matches generate-readme.sh output"; RESULT: PASS (0 errors / 0 warnings)
- 2026-06-13 [qa-smoke] 2 (Check 25 FIRES on drift): green — drifted README → validate.sh exit 1; literal "ERROR: README.md is stale vs generate-readme.sh — run: bash scripts/generate-readme.sh > README.md"; RESULT: FAIL
- 2026-06-13 [qa-smoke] 3 (green after restore): green — `git checkout README.md` → validate.sh exit 0; Check 25 PASS; RESULT: PASS again
- 2026-06-13 [qa-smoke] 4 (read-only): green — git diff on README before restore showed exactly 1 added / 0 removed (only the deliberate planted line); the check itself mutated nothing
- 2026-06-13 [qa-smoke] 5 (Check 24 reverse-coverage clean): green — Check 24 FINDINGS=0, coverage rows=69 reverse_tokens=49 findings=0; no `validate-check-25` reverse finding; units row registered at spec/test-spec-custom.md:443
- 2026-06-13 [qa-smoke] 6 (test.sh Step 3d assertion): green — the 3 Check-25 assertions (in-sync PASS / drift ERROR+non-zero / regenerate exits 0) all OK, ERRORS=0; block lives in the executed zzz-test-scaffold integration cycle; README left clean
- 2026-06-13 [qa-smoke-summary] green: 6/6 non-manual rows green (0 manual rows pending)
- 2026-06-13 [qa-audit] AUDITS=deferred,spec_updates:test-spec-custom:none,doc-spec-custom:none (Step 8.6a/8.6b ran inline — both overlays already current: validate-check-25 row present + anchor-matches-live, no new root/spec doc; 8.6c/8.6d DEFERRED via DEFER_AUDIT — orchestrator runs the post-sync audit)
- 2026-06-13 [qa-pass] T000050 (task): green smoke from test-plan rows (6 rows). No qa-owned Phase 2 gates per template; Phase 3 `Test-plan verified` gate awaits /ship-time inference.
