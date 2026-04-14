---
name: "Work item format consistency"
type: defect
id: "D000002"
status: active
created: "2026-04-13"
updated: "2026-04-13"
repo: "jcl2018/claude-skills-templates"
branch: "fix/workitem-format-consistency"
blocked_by: ""
---

## Lifecycle

### Phase 1: Track

1. Document reproduction steps in the Log section
2. Create working branch: `git checkout -b fix/workitem-format-consistency`
3. Scaffold required docs:
   - `D000002_RCA.md` (root cause analysis) — from `templates/doc-RCA.md`
   - `D000002_test-plan.md` (regression test plan) — from `templates/doc-test-plan.md`
4. Run `/investigate` to diagnose root cause
   → produces investigation findings in Log + Insights
5. Log initial symptoms and hypotheses

**Gates:**
- [x] Reproduction steps documented
- [x] Working branch created (`branch` field populated)
- [x] Required docs scaffolded (RCA + test-plan)
- [x] Root cause identified (or best hypothesis logged)

### Phase 2: Implement

1. Work from `/office-hours` design doc (if applicable) + root cause analysis
   → design doc at `~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-main-design-20260413-223009.md`
2. Implement fix based on root cause analysis
3. Write regression test covering the defect scenario
4. Commit fix and test together
5. Update RCA doc with final root cause

**Gates:**
- [x] Fix committed
- [x] RCA doc updated
- [x] Todos section reflects remaining work (no stale items)

### Phase 3: Ship

1. Run `/docs check` — verify no regressions
2. Verify test-plan: regression test scenarios passing
3. Run `/ship` — creates fix PR (includes pre-landing code review)
4. Run `/land-and-deploy` — merges and verifies fix in production

❌ If regression test fails: investigate further
❌ If CI fails: fix, push, re-run `/ship`

**Gates:**
- [x] `/docs check` — validation passed (validate.sh: 0 errors, 0 warnings)
- [x] Test-plan verified (regression scenarios passing, 14/14 pass)
- [x] `/ship` — PR created (#29)
- [ ] `/land-and-deploy` — merged and deployed

## Reproduction Steps

1. List files under `work-items/` — observe D000001 is flat alongside F000001/F000002 with no type grouping
2. List D000001 artifacts — observe `TRACKER.md`, `RCA.md`, `test-plan.md` have no ID prefix, while F000001 uses `F000001_TRACKER.md`
3. Read `templates/tracker-defect.md` Phase 2 gate — observe "Fix committed with regression test" (too prescriptive)
4. Read D000001 TRACKER.md — observe `status: active` despite fix merged in #28
5. Read D000001 test-plan.md — observe `status: Draft` with all test cases "Pending" despite fix verified

## Todos

- [x] Close D000001 (tracker + test-plan)
- [x] Update defect template gate text
- [x] Update rules/work-items.md directory structure
- [x] Update artifact-manifests.json placement values
- [x] Sync global rules
- [x] Migrate existing work items to type subfolders
- [x] Rename D000001 artifacts with ID prefix
- [x] Rename F000001 milestones.md with ID prefix
- [x] Scaffold D000002
- [x] Update /docs check placement logic
- [x] Run validate.sh
- [x] /ship (#29)

## Log

- 2026-04-13: Created. Five format inconsistencies identified: no type subfolders, inconsistent ID prefix on artifacts, prescriptive Phase 2 gate text, D000001 tracker not closed, D000001 test-plan not closed.
- 2026-04-13: Root cause identified — original scaffolding of D000001 was the first defect workflow, format conventions were not yet established for defect type. Features had evolved ID-prefix convention organically but defects did not inherit it.
- 2026-04-13: Fix implemented and shipped via /ship. PR #29 created.

## PRs

- #29 (open) — fix: work item format consistency (D000002)

## Files

- `artifact-manifests.json`
- `rules/work-items.md`
- `templates/tracker-defect.md`
- `skills/docs/check.md`
- `work-items/` (structural migration)

## Insights

- The defect format bugs are a natural consequence of D000001 being the first defect ever scaffolded. The conventions that evolved for features (ID prefix, directory nesting) were never explicitly codified for defects.
- The "Fix committed with regression test" gate text came from the template, which assumed all defect fixes include automated regression tests. In practice, many fixes are config/manifest changes that are verified manually.

## Journal
