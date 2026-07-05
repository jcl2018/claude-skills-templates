---
name: "Make /CJ_test_run's report show the agentic cold-agent prompt and response — the portability-version-agentic test currently prints only a one-line PASS summary; surface the exact prompt sent to claude --print and the agent's JSON verdict/response in a detailed report."
type: task
id: "T000057"
status: active
created: "2026-07-05"
updated: "2026-07-05"
parent: ""
repo: "E:/projects/claude-skills-templates/.claude/worktrees/cj-task-20260705-111556-252387"
branch: "cj-task-20260705-111556-252387"
blocked_by: ""
---

<!-- Prerequisite (optional): If this task came from /office-hours, distill the
     design context into the ## Insights section below. Otherwise (per the
     skip-design-for-small-todos convention in WORKFLOW.md), proceed without
     a separate DESIGN.md — the parent user-story's DESIGN already covers it. -->

## Lifecycle

### Phase 1: Track

1. Read parent tracker to understand scope and acceptance criteria
2. Create working branch: `git checkout -b feat/make_cj_test_run_s_report_show_the`
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
   → design doc at `~/.gstack/projects/make_cj_test_run_s_report_show_the/`
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

- [ ] Implement: Make /CJ_test_run's report show the agentic cold-agent prompt and response — the portability-version-agentic test currently prints only a one-line PASS summary; surface the exact prompt sent to claude --print and the agent's JSON verdict/response in a detailed report.

## Log

<!-- Chronological entries with dates and commit SHAs. Each entry records
     what happened, not what should happen. -->

- 2026-07-05: Created. Auto-scaffolded by /CJ_goal_task from topic: Make /CJ_test_run's report show the agentic cold-agent prompt and response — the portability-version-agentic test currently prints only a one-line PASS summary; surface the exact prompt sent to claude --print and the agent's JSON verdict/response in a detailed report.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. Populated during Track phase, updated during Implement. -->

## Insights

<!-- Auto-injected from the /CJ_goal_task topic -->

Scope (from /CJ_goal_task topic): Make /CJ_test_run's report show the agentic cold-agent prompt and response — the portability-version-agentic test currently prints only a one-line PASS summary; surface the exact prompt sent to claude --print and the agent's JSON verdict/response in a detailed report.


<!-- Non-obvious findings worth remembering. Things that surprised you,
     patterns discovered, or context that future readers will need. -->

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

<!-- Source: /CJ_goal_task: Make /CJ_test_run's report show the agentic cold-agent prompt and response — the portability-version-agentic test currently prints only a one-line PASS summary; surface the exact prompt sent to claude --print and the agent's JSON verdict/response in a detailed report. -->

- 2026-07-05 [qa-smoke] row1 (manual-verification): green — hermetic detail test `tests/portability-version-agentic-detail.test.sh` passed (8 asserts, NO model spend): prompt written byte-identical to what claude received, AGENTIC-DETAIL block emitted, test-run.sh folds it into the materialized report's `## Agentic detail`.
- 2026-07-05 [qa-smoke] row1 (test-spec engine): green — `test-spec.sh --validate` OK schema_version=1; `--check-coverage` findings=0 (new unit `portability-version-agentic-detail` anchored, reverse sweep clean, rows=90); `--render-docs --check` in sync (findings=0).
- 2026-07-05 [qa-smoke] row1 (skip-path + syntax): green — SKIP path (`env -u CJ_E2E_LOCAL`) exits 0 with 0 AGENTIC-DETAIL blocks (no accidental model spend); `bash -n` clean on all 5 changed shell surfaces (test-run.sh, agentic-sandbox.sh, test.sh, both agentic test files).
- 2026-07-05 [qa-smoke-note] LIVE agentic E2E (`CJ_E2E_LOCAL=1 test-run.sh portability-version-agentic --e2e`) was pre-confirmed GREEN by the /CJ_goal_task orchestrator (report's `## Agentic detail` carries the verbatim prompt + raw claude response + verdict); NOT re-run here to avoid model spend.
- 2026-07-05 [qa-smoke-summary] green: 6/6 non-manual smoke-equivalent rows green (0 manual rows pending — the one prose test-plan row was verified by the hermetic smoke-equivalents above).
- 2026-07-05 [qa-audit] AUDITS=deferred,spec_updates:test-spec-custom:none(new-unit-row-present),doc-spec-custom:none (Step 8.6a/8.6b: deterministic new-surface check confirmed the new `tests/portability-version-agentic-detail.test.sh` units: row is already present + well-formed; no new repo-specific docs to declare — the agent-judged amendment sweep SKIPPED via DEFER_SYNC + 8.6c/8.6d SKIPPED via DEFER_AUDIT; the agentic doc/test sync + audit run on-demand off the build path).
- 2026-07-05 [qa-pass] T000057 (task): green smoke from test-plan rows (1 row, verified via 6 hermetic smoke-equivalents; LIVE agentic E2E pre-confirmed by orchestrator). No qa-owned Phase 2 gates per template; Phase 3 `Test-plan verified` gate awaits /ship-time inference.
