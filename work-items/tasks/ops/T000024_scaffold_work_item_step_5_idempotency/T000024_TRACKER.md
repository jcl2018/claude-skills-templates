---
name: "`/scaffold-work-item` Step 5 idempotency hole (P3, S)"
type: task
id: "T000024"
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
2. Create working branch: `git checkout -b feat/scaffold_work_item_step_5_idempotency`
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
   → design doc at `~/.gstack/projects/scaffold_work_item_step_5_idempotency/`
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

- [x] Implement: `/scaffold-work-item` Step 5 idempotency hole (P3, S)

## Log

<!-- Chronological entries with dates and commit SHAs. Each entry records
     what happened, not what should happen. -->

- 2026-05-14: Created. Auto-scaffolded by /CJ_goal from TODOS.md ### `/scaffold-work-item` Step 5 idempotency hole (P3, S)

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. Populated during Track phase, updated during Implement. -->

- `skills/CJ_scaffold-work-item/scaffold.md` — added Step 5.0 idempotency pre-check (Probe A: SCAFFOLDED footer; Probe B: tracker frontmatter grep) before fresh-ID generation (now renumbered as Step 5.1).

## Insights

<!-- Auto-injected from TODOS.md body by /CJ_goal -->

Step 5 of `skills/scaffold-work-item/scaffold.md` always generates a fresh ID by incrementing the max existing tracker prefix. Re-running on `chjiang-main-design-20260508-102829.md` (F000010's source design doc) would write a duplicate F000011 alongside the existing F000010 — Step 9's idempotency check uses TARGET_PATH derived from the freshly-generated NEW_ID, so the existing dir is never inspected. Closes the deferred S000017 AC-5 (idempotency). **Fix:** before Step 5, either read the source design doc's `**Status: SCAFFOLDED → ...**` footer (Step 12 already writes it) OR grep `work-items/*/TRACKER.md` frontmatter for a tracker referencing this design-doc path; if matched, set NEW_ID to the existing ID and let Step 9 boundary-check + NO-OP run as designed. **When:** before the next re-run of `/scaffold-work-item` on an existing work item — until then, the bootstrap workflow (backup → delete → re-scaffold → diff) is the working alternative. **Reference:** found 2026-05-08 during S000018/S000019 verification.


<!-- Non-obvious findings worth remembering. Things that surprised you,
     patterns discovered, or context that future readers will need. -->

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

<!-- Source: TODOS.md ### `/scaffold-work-item` Step 5 idempotency hole (P3, S) -->

- 2026-05-14 [orchestrator] --work-item-dir mode: using pre-staged dir at /Users/chjiang/Documents/projects/claude-skills-templates/work-items/tasks/ops/T000024_scaffold_work_item_step_5_idempotency; scaffold skipped.
- 2026-05-14 [implement] Added Step 5.0 idempotency pre-check to skills/CJ_scaffold-work-item/scaffold.md: reads design-doc SCAFFOLDED footer (Probe A) and grep TRACKER.md frontmatter for design-doc references (Probe B); on match, sets NEW_ID=EXISTING_ID and reuses TARGET_PATH so Step 9 boundary check NO-OPs as designed. Closes deferred S000017 AC-5.
- 2026-05-14 [qa-smoke-summary] green — 7 smoke checks PASS: Step 5.0 section present, Probe A + Probe B both present, Step 5.1 renumbered, NEW_ID=EXISTING_ID assignment present, original Step 5 heading preserved, validate.sh PASS post-edit, git status shows only intended file changed.
- 2026-05-14 [qa-pass] T000024 smoke-only verification complete (type=task; no E2E surface). Test-plan row 1 (manual verification) PASS: behavior matches TODO body — Step 5.0 reads SCAFFOLDED footer OR grep tracker frontmatter; on match sets NEW_ID=EXISTING_ID and lets Step 9 NO-OP run as designed.
- 2026-05-14 [auto-pipeline-clean] suppression mode — 1 mechanical decision(s); no taste / user-challenge-approved decisions; END_STATE=green.
