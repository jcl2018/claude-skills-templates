---
name: "Curate docs/reference.md with an editorial pass — make the grep-grounded reference shelf opinionated and genuinely useful to a human building this workbench"
type: task
id: "T000055"
status: active
created: "2026-06-28"
updated: "2026-06-28"
parent: ""
repo: "/Users/chjiang/Documents/projects/claude-skills-templates/.claude/worktrees/nervous-tesla-46a57e"
branch: "cj-task-20260628-184936-curate-reference"
blocked_by: ""
---

<!-- Prerequisite (optional): If this task came from /office-hours, distill the
     design context into the ## Insights section below. Otherwise (per the
     skip-design-for-small-todos convention in WORKFLOW.md), proceed without
     a separate DESIGN.md — the parent user-story's DESIGN already covers it. -->

## Lifecycle

### Phase 1: Track

1. Read parent tracker to understand scope and acceptance criteria
2. Create working branch: `git checkout -b feat/curate_docs_reference_md_with_an`
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
   → design doc at `~/.gstack/projects/curate_docs_reference_md_with_an/`
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

- [ ] Implement: Curate docs/reference.md with an editorial pass — make the grep-grounded reference shelf opinionated and genuinely useful to a human building this workbench

## Log

<!-- Chronological entries with dates and commit SHAs. Each entry records
     what happened, not what should happen. -->

- 2026-06-28: Created. Auto-scaffolded by /CJ_goal_task from topic: Curate docs/reference.md with an editorial pass — make the grep-grounded reference shelf opinionated and genuinely useful to a human building this workbench

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

- `docs/reference.md` — editorial pass (reader-orientation intro + opinionated category subtitles + per-entry "when you'd reach for it" notes; same link set, no work-item IDs)
- `work-items/tasks/ops/T000055_*/` — this work item

## Insights

<!-- Auto-injected from the /CJ_goal_task topic -->

Scope (from /CJ_goal_task topic): Curate docs/reference.md with an editorial pass — make the grep-grounded reference shelf opinionated and genuinely useful to a human building this workbench


<!-- Non-obvious findings worth remembering. Things that surprised you,
     patterns discovered, or context that future readers will need. -->

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

<!-- Source: /CJ_goal_task: Curate docs/reference.md with an editorial pass — make the grep-grounded reference shelf opinionated and genuinely useful to a human building this workbench -->

- 2026-06-28 [qa-smoke] 1 (no work-item IDs): green — `grep -E '[FSTD][0-9]{6}' docs/reference.md` no match (Check 19 clean).
- 2026-06-28 [qa-smoke] 2 (doc registry consistent): green — `bash scripts/validate.sh` 0 errors / 0 warnings (Check 15/17/19 green).
- 2026-06-28 [qa-smoke] 3 (grounded + grouped): green — 4 category sections retained; every entry maps to a real repo reference; notes opinionated but concise.
- 2026-06-28 [qa-smoke] 4 (no invented references): green — URL set byte-identical to prior reference.md (editorial enrichment only; 0 added / 0 removed).
- 2026-06-28 [qa-smoke-summary] green: 4/4 rows green. Docs-only change; validate.sh 0/0.
- 2026-06-28 [qa-audit] AUDITS=deferred (no spec-overlay change; 8.6c/8.6d deferred to the orchestrator post-sync audit).
- 2026-06-28 [qa-pass] T000055 (task): green smoke from test-plan rows (4 rows). No qa-owned Phase 2 gates per task template.
