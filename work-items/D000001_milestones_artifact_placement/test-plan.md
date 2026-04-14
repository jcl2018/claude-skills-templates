---
type: test-plan
parent: D000001
title: "Milestones artifact mapped to wrong work item type — Regression Test Plan"
date: 2026-04-13
author: chjiang
status: Draft
---

## Scope

Files modified:
- `artifact-manifests.json` — milestones entry moved from user-story.required to feature.required
- `rules/work-items.md` — milestones listing moved from user-story line to feature line
- `~/.claude/rules/work-items.md` — global rules synced to match
- `templates/doc-milestones.md` — frontmatter parent placeholder updated from `{USER_STORY_ID}` to `{FEATURE_ID}`
- `work-items/F000001_workflow_alpha/milestones.md` — moved up from S000001 story level
- `work-items/F000001_workflow_alpha/S000001_workflow_implementation/S000001_milestones.md` — deleted

## Regression Test Cases

| # | Test Case | Steps | Expected Result | Status |
|---|-----------|-------|-----------------|--------|
| 1 | Milestones absent from user-story | Read artifact-manifests.json, check types.user-story.required | No milestones entry in array (4 entries: tracker, prd, architecture, test-spec) | Pending |
| 2 | Milestones present in feature | Read artifact-manifests.json, check types.feature.required | milestones entry present (2 entries: tracker, milestones) | Pending |
| 3 | Rules match manifest (feature) | Read rules/work-items.md, check feature line | Lists `tracker-feature.md + doc-milestones.md` | Pending |
| 4 | Rules match manifest (user-story) | Read rules/work-items.md, check user-story line | Lists `tracker-user-story.md + doc-PRD.md + doc-ARCHITECTURE.md + doc-TEST-SPEC.md` (no milestones) | Pending |
| 5 | validate.sh passes | Run `./scripts/validate.sh` | Exit 0, no errors | Pending |
| 6 | JSON valid | Parse artifact-manifests.json with jq | Valid JSON, no syntax errors | Pending |
| 7 | Template frontmatter updated | Read templates/doc-milestones.md | `parent` placeholder is `{FEATURE_ID}`, no `feature` field | Pending |
| 8 | F000001 milestones at feature level | Check work-items/F000001_workflow_alpha/milestones.md exists | File exists with `parent: F000001_workflow_alpha`, all 13 milestones preserved | Pending |
| 9 | S000001 milestones removed | Check work-items/F000001_workflow_alpha/S000001_workflow_implementation/ | No milestones file present | Pending |
| 10 | Global rules synced | Read ~/.claude/rules/work-items.md | Feature line includes doc-milestones.md, user-story line does not | Pending |

## Verification Steps

- [ ] Local `./scripts/validate.sh` passes
- [ ] `jq . artifact-manifests.json` parses without error
- [ ] Manual inspection confirms milestones under feature.required
- [ ] Manual inspection confirms milestones removed from user-story.required
- [ ] rules/work-items.md feature line includes doc-milestones.md
- [ ] rules/work-items.md user-story line excludes doc-milestones.md
- [ ] ~/.claude/rules/work-items.md matches repo rules/work-items.md
- [ ] Template parent placeholder is {FEATURE_ID}, not {USER_STORY_ID}
- [ ] F000001 has milestones.md at feature level with correct frontmatter
- [ ] S000001_milestones.md no longer exists

## Environments Tested

| Environment | Build | Result |
|------------|-------|--------|
| macOS Darwin 25.3.0 | fix/milestones-artifact-placement | Pending |
