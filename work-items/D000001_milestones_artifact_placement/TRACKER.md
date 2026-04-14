---
name: "Milestones artifact mapped to wrong work item type"
type: defect
id: "D000001"
status: active
created: "2026-04-13"
updated: "2026-04-13"
repo: "jcl2018/claude-skills-templates"
branch: "fix/milestones-artifact-placement"
blocked_by: ""
---

## Lifecycle

### Phase 1: Track

1. Document reproduction steps in the Log section
2. Create working branch: `git checkout -b fix/milestones-artifact-placement`
3. Scaffold required docs:
   - `RCA.md` (root cause analysis) — from `templates/doc-RCA.md`
   - `test-plan.md` (regression test plan) — from `templates/doc-test-plan.md`
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
   → design doc at `~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-main-design-20260413-190700.md`
2. Implement fix based on root cause analysis
3. Write regression test covering the defect scenario
4. Commit fix and test together
5. Update RCA doc with final root cause

**Gates:**
- [ ] Fix committed with regression test
- [ ] RCA doc updated
- [ ] Todos section reflects remaining work (no stale items)

### Phase 3: Ship

1. Run `/docs check` — verify no regressions
2. Verify test-plan: regression test scenarios passing
3. Run `/ship` — creates fix PR (includes pre-landing code review)
4. Run `/land-and-deploy` — merges and verifies fix in production

❌ If regression test fails: investigate further
❌ If CI fails: fix, push, re-run `/ship`

**Gates:**
- [ ] `/docs check` — validation passed
- [ ] Test-plan verified (regression scenarios passing)
- [ ] `/ship` — PR created
- [ ] `/land-and-deploy` — merged and deployed

## Reproduction Steps

1. Open `artifact-manifests.json`
2. Observe `types.user-story.required` array contains `{"artifact": "milestones", "template": "doc-milestones.md", "filename": "milestones.md"}`
3. Observe `types.feature.required` array does NOT contain a milestones entry
4. Open `rules/work-items.md`
5. Observe line 10: user-story lists `doc-milestones.md`
6. Observe line 7: feature does NOT list `doc-milestones.md`
7. **Expected:** Milestones should be a required artifact of the feature type, not user-story

## Todos

- [x] Scaffold D000001 defect work item
- [x] Implement fix in artifact-manifests.json
- [x] Implement fix in rules/work-items.md
- [x] Update template frontmatter (parent placeholder)
- [x] Move F000001 milestones from S000001 to feature level
- [x] Delete S000001_milestones.md
- [x] Sync global rules (~/.claude/rules/work-items.md)
- [x] Fill in RCA doc
- [x] Update test-plan with all changes
- [ ] Run validate.sh
- [ ] /ship

## Log

- 2026-04-13: Created. Milestones artifact (`doc-milestones.md`) is mapped as required for user-story type but should be required for feature type. Milestones track feature-level delivery timelines, not individual story progress.
- 2026-04-13: Root cause identified — original artifact mapping in v2.0.0 manifest placed milestones under user-story alongside PRD/ARCHITECTURE/TEST-SPEC without distinguishing feature-level vs story-level concerns.

## PRs

## Files

- `artifact-manifests.json`
- `rules/work-items.md`

## Insights

- Root cause: during the initial artifact manifest design (v2.0.0), milestones was grouped with the user-story doc triplet (PRD/ARCHITECTURE/TEST-SPEC) without considering that milestones tracks feature-level delivery, not story-level work.
- The 3-phase lifecycle simplification (session 20) correctly removed PRD/ARCHITECTURE/TEST-SPEC from feature level but did not re-examine whether milestones belonged at feature level instead of user-story level.

## Journal
