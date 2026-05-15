---
name: "Pre-ship vs post-ship AC categorization for `/CJ_qa-work-item` (P3, S)"
type: task
id: "T000027"
status: active
created: "2026-05-14"
updated: "2026-05-14"
parent: ""
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "main"
blocked_by: ""
---

<!-- Prerequisite (optional): If this task came from /office-hours, distill the
     design context into the ## Insights section below. Otherwise (per the
     skip-design-for-small-todos convention in WORKFLOW.md), proceed without
     a separate DESIGN.md — the parent user-story's DESIGN already covers it. -->

## Lifecycle

### Phase 1: Track

1. Read parent tracker to understand scope and acceptance criteria
2. Create working branch: `git checkout -b feat/pre_ship_vs_post_ship_ac_categorization`
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
   → design doc at `~/.gstack/projects/pre_ship_vs_post_ship_ac_categorization/`
2. Commit changes incrementally with descriptive messages
3. Update Todos section — check off completed items, add discoveries
4. Update Files section with actual changed files

**Gates:**
- [ ] Core changes committed (>=1 commit SHA in Log)
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

- [x] Implement: Pre-ship vs post-ship AC categorization for `/CJ_qa-work-item` (P3, S) — v1 narrow scope: (a) Tag-column `post-ship` token (no schema migration) + (b) qa.md Step 4.user-story filter writing `[qa-e2e-deferred]` entries. Deferred (c) tracker-template gate + (d) check.md post-merge inference per TODO body's recommended v1 narrowing.

## Log

<!-- Chronological entries with dates and commit SHAs. Each entry records
     what happened, not what should happen. -->

- 2026-05-14: Created. Auto-scaffolded by /CJ_goal from TODOS.md ### Pre-ship vs post-ship AC categorization for `/CJ_qa-work-item` (P3, S)

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. Populated during Track phase, updated during Implement. -->

- `skills/CJ_qa-work-item/qa.md` — Step 4.user-story → Post-ship E2E filter section (filter logic + edge cases); Step 8 summary `{N_DEFERRED}` documented to include post-ship; Step 9 `[qa-pass]` "all post-ship" variant; Step 11 summary `Deferred:` line; new "Post-Ship E2E Filter Contract (T000027)" trailer section.
- `templates/CJ_personal-workflow/doc-TEST-SPEC.md` — E2E Tests section comment block documents `post-ship` Tag token semantics; Tag vocabulary comment updated to list `post-ship` as a modifier.

## Insights

<!-- Auto-injected from TODOS.md body by /CJ_goal -->

When a work-item's acceptance criteria include rows that are structurally only verifiable post-ship (e.g., S000025 ACs 2/3/4/7 require `gh workflow run eval-nightly.yml` against merged main — the workflow file doesn't exist on remote refs reachable by `gh workflow run` until the PR ships), the current QA flow forces an awkward path: the QA subagent dispatches per qa.md Step 7, returns `ambiguous` for the structurally-impossible rows, the user adjudicates "treat as green" per qa.md Step 8, and Phase 2 QA-owned gates flip to `[x]` even though those ACs aren't actually verified. Repeated for every work-item that ships new CI surfaces. **Fix sketch:** (a) add an optional `phase: post-ship` field to TEST-SPEC E2E rows (or a separate `## Post-Ship E2E` section); (b) teach `qa.md` Step 4 to filter post-ship rows out of the subagent dispatch with a `[qa-e2e-deferred]` journal entry naming the rows + their ACs; (c) add a dedicated Phase 3 gate `Post-ship ACs verified` to the user-story tracker template (and equivalents for defect/task templates); (d) teach `/CJ_personal-workflow check --update`'s post-merge inference to mark the new gate from journal entries written after `gh workflow run` succeeds. Cleaner separation than the current pretend-green-then-track-in-Todos pattern, and removes the per-work-item adjudication overhead. **When:** before the next work-item with structurally post-ship ACs hits `/CJ_qa-work-item`. **Reference:** found 2026-05-11 during S000025 QA — D5 adjudication burned a full AUQ on a structurally predetermined answer; full discussion in S000025_TRACKER.md `[qa-adjudication]` journal entry.


<!-- Non-obvious findings worth remembering. Things that surprised you,
     patterns discovered, or context that future readers will need. -->

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

<!-- Source: TODOS.md ### Pre-ship vs post-ship AC categorization for `/CJ_qa-work-item` (P3, S) -->

- 2026-05-15T07:01:06Z [orchestrator] --work-item-dir mode: using pre-staged dir at /Users/chjiang/Documents/projects/claude-skills-templates/work-items/tasks/ops/T000027_pre_ship_vs_post_ship_ac_categorization; scaffold skipped.
- 2026-05-15T07:07:00Z [impl] T000027 (task): v1 narrow scope (a)+(b) implemented. Tag-column `post-ship` token added to TEST-SPEC template; qa.md Step 4.user-story filters post-ship rows with `[qa-e2e-deferred]` journal entries before Step 4.5 classifier. 2 files changed.
- 2026-05-15T07:07:00Z [gate-green] post-implement validate.sh: PASS (0 errors, 0 warnings).
- 2026-05-15 [qa-smoke-manual] 1 (manual verification): pending human verification — Manual verification of post-ship Tag filter behavior; the implementation is doc-and-template change, no runtime to execute pre-ship.
- 2026-05-15 [qa-smoke-summary] green: 0/0 non-manual rows green (1 manual rows pending)
- 2026-05-15 [qa-pass] T000027 (task): green smoke from test-plan rows (1 rows, all manual_pending). No qa-owned Phase 2 gates per template; Phase 3 `Test-plan verified` gate awaits /ship-time inference.
- 2026-05-15T07:07:28Z [auto-final-gate-suppressed] 1 mechanical, 2 taste, 1 user-challenge-approved; decisions at /Users/chjiang/.gstack/analytics/CJ_personal-pipeline-auto-decisions.jsonl
