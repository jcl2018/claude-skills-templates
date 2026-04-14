---
type: test-plan
parent: D000002
title: "Work item format consistency — Regression Test Plan"
date: 2026-04-13
author: chjiang
status: Draft
---

## Scope

Files modified:
- `artifact-manifests.json` — placement values changed from "root" to "features"/"defects"
- `rules/work-items.md` — directory structure updated, ID-prefix convention documented
- `~/.claude/rules/work-items.md` — global rules synced
- `templates/tracker-defect.md` — Phase 2 gate text simplified
- `skills/docs/check.md` — placement validation updated for type subfolders
- `work-items/` — structural migration to type subfolders + artifact renames

## Regression Test Cases

| # | Test Case | Steps | Expected Result | Status |
|---|-----------|-------|-----------------|--------|
| 1 | Type subfolders exist | `ls work-items/` | `features/` and `defects/` directories present | Pending |
| 2 | Features in features/ | `ls work-items/features/` | F000001_workflow_alpha/ and F000002_system_health_v1/ | Pending |
| 3 | Defects in defects/ | `ls work-items/defects/` | D000001_milestones_artifact_placement/ and D000002_workitem_format_consistency/ | Pending |
| 4 | D000001 artifacts ID-prefixed | `ls work-items/defects/D000001_*/` | D000001_TRACKER.md, D000001_RCA.md, D000001_test-plan.md | Pending |
| 5 | F000001 milestones ID-prefixed | Check F000001 directory | F000001_milestones.md (not milestones.md) | Pending |
| 6 | D000001 tracker closed | Read D000001_TRACKER.md frontmatter | status: closed | Pending |
| 7 | D000001 test-plan complete | Read D000001_test-plan.md frontmatter | status: Complete, all cases Pass | Pending |
| 8 | Defect template gate text | Read templates/tracker-defect.md Phase 2 | "Fix committed" (no "with regression test") | Pending |
| 9 | Manifest placement updated | Read artifact-manifests.json placement | feature: "features", defect: "defects" | Pending |
| 10 | Rules directory structure | Read rules/work-items.md | Shows type subfolders (features/, defects/) | Pending |
| 11 | Global rules synced | Diff rules/work-items.md vs ~/.claude/rules/ | Files match | Pending |
| 12 | validate.sh passes | Run `./scripts/validate.sh` | Exit 0 | Pending |
| 13 | No flat work items remain | `ls work-items/` (excluding features/ defects/) | No stray item directories at root level | Pending |
| 14 | D000002 scaffolded correctly | `ls work-items/defects/D000002_*/` | D000002_TRACKER.md, D000002_RCA.md, D000002_test-plan.md | Pending |

## Verification Steps

- [ ] `ls work-items/` shows only `features/` and `defects/`
- [ ] All artifact filenames prefixed with item ID
- [ ] D000001 tracker closed, test-plan complete
- [ ] Defect template gate text says "Fix committed"
- [ ] Manifest placement values are "features" and "defects"
- [ ] Rules show type subfolders
- [ ] Global rules match repo rules
- [ ] validate.sh passes
- [ ] D000002 scaffolded in correct format

## Environments Tested

| Environment | Build | Result |
|------------|-------|--------|
| macOS Darwin 25.3.0 | fix/workitem-format-consistency | Pending |
