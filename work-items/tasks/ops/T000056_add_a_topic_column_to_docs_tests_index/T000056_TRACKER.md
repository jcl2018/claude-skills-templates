---
name: "Add a Topic column to docs/tests/index.md grouping related tests by topic (portability / core-suite / cj-goal-workflows) so a reader knows which tests fully cover a topic"
type: task
id: "T000056"
status: active
created: "2026-07-04"
updated: "2026-07-04"
parent: ""
repo: "E:/projects/claude-skills-templates/.claude/worktrees/ecstatic-greider-fb1178"
branch: "claude/task-index-topic-column"
blocked_by: ""
---

<!-- Prerequisite (optional): If this task came from /office-hours, distill the
     design context into the ## Insights section below. Otherwise (per the
     skip-design-for-small-todos convention in WORKFLOW.md), proceed without
     a separate DESIGN.md — the parent user-story's DESIGN already covers it. -->

## Lifecycle

### Phase 1: Track

1. Read parent tracker to understand scope and acceptance criteria
2. Create working branch: `git checkout -b feat/add_a_topic_column_to_docs_tests_index`
   (use parent's branch if the task ships in the same PR; create a new branch if it warrants its own PR)
3. Scaffold required docs:
   - `test-plan.md` (test scenarios for this task) — from `templates/doc-test-plan.md`
4. Populate Files section with expected changed files
5. Write initial Todos from parent's acceptance criteria

**Gates:**
- [x] Parent scope read (parent tracker reviewed)
- [x] Working branch created (`branch` field populated)
- [x] Required docs scaffolded (test-plan)
- [x] Files section populated

### Phase 2: Implement

1. Work from `/office-hours` design doc + parent's acceptance criteria + your Todos
   → design doc at `~/.gstack/projects/add_a_topic_column_to_docs_tests_index/`
2. Commit changes incrementally with descriptive messages
3. Update Todos section — check off completed items, add discoveries
4. Update Files section with actual changed files

**Gates:**
- [x] Core changes committed (>=1 commit SHA in Log)
- [x] Todos section reflects remaining work (no stale items)
- [x] Files section updated with changed files

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

- [x] Implement: Add a Topic column to docs/tests/index.md grouping related tests by topic (portability / core-suite / cj-goal-workflows) so a reader knows which tests fully cover a topic

## Log

<!-- Chronological entries with dates and commit SHAs. Each entry records
     what happened, not what should happen. -->

- 2026-07-04: Created. Auto-scaffolded by /CJ_goal_task from topic: Add a Topic column to docs/tests/index.md grouping related tests by topic (portability / core-suite / cj-goal-workflows) so a reader knows which tests fully cover a topic

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. Populated during Track phase, updated during Implement. -->

- `docs/tests/index.md` — added a hand-maintained **Topic** column + intro paragraph grouping the declared category tests by topic (portability / core-suite / cj-goal-workflows); rows reordered to sit together by topic; comment updated to note the column is NOT sourced from the `categories:` axis.

## Insights

<!-- Auto-injected from the /CJ_goal_task topic -->

Scope (from /CJ_goal_task topic): Add a Topic column to docs/tests/index.md grouping related tests by topic (portability / core-suite / cj-goal-workflows) so a reader knows which tests fully cover a topic


<!-- Non-obvious findings worth remembering. Things that surprised you,
     patterns discovered, or context that future readers will need. -->

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

<!-- Source: /CJ_goal_task: Add a Topic column to docs/tests/index.md grouping related tests by topic (portability / core-suite / cj-goal-workflows) so a reader knows which tests fully cover a topic -->

- 2026-07-04 [qa-smoke] 1 (test-plan): green — Topic column verified via 4 targeted checks: test-spec.sh --check-structure (a-f PASS, findings=0), doc-spec.sh --check-on-disk (5 checks, findings=0), no work-item IDs (Check 19), test-spec.sh --render-docs leaves index byte-identical
- 2026-07-04 [qa-smoke-summary] green: 1/1 non-manual rows green (0 manual rows pending)
- 2026-07-04 [qa-audit] AUDITS=deferred,spec_updates:test-spec-custom:none,doc-spec-custom:none (Step 8.6a/8.6b: deterministic new-surface rows added inline — none needed, no new tests/*.test.sh and no new declared doc; the agent-judged amendment sweep SKIPPED via DEFER_SYNC + 8.6c/8.6d SKIPPED via DEFER_AUDIT — the agentic doc/test sync + audit run on-demand off the build path)
- 2026-07-04 [qa-pass] T000056 (task): green smoke from test-plan rows (1 row). No qa-owned Phase 2 gates per template; Phase 3 `Test-plan verified` gate awaits /ship-time inference.
