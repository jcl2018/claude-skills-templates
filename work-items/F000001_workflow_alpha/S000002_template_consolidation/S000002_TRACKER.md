---
name: "Work Item Template Consolidation"
type: userstory
id: "S000002_template_consolidation"
status: active
created: "2026-04-11"
updated: "2026-04-11"
repo: "claude-skills-templates"
branch: "feat/workflow-alpha"
blocked_by: ""
---

## Lifecycle

### Phase 1: Track
- [x] Acceptance criteria defined
- [x] Working branch created
- [x] Doc triplet produced (PRD + ARCHITECTURE + TEST-SPEC)
- [ ] Milestones created
- [ ] Tasks broken down (if needed)

### Phase 2: Implement
- [x] Build-forward mode (from doc triplet + acceptance criteria)
- [x] Implementation committed
- [ ] Acceptance criteria verified met

### Phase 3: Review
- [ ] Doc review completed
- [ ] Doc generation finalized
- [ ] Doc triplet alignment check (TEST-SPEC)

### Phase 4: Ship
- [ ] `/ship` — PR created
- [ ] `/land-and-deploy` — merged and deployed

## Acceptance Criteria

- [x] Tracker templates reflect solo-dev workflow (no "reviewer noted", no "Linux branch build")
- [x] Lifecycle gates are meaningful for a single developer working with Claude Code
- [x] Redundant fields removed (JIRA/TFS URL, workflow_type)
- [x] Review phase gates: doc review + generation (feature), + test verification (task/defect), + triplet alignment (user-story)
- [x] Ship phase gates: `/ship` + `/land-and-deploy`
- [x] Task tracker is lightweight
- [x] All 4 tracker templates updated consistently (review type removed)
- [ ] Phase detection logic in SKILL.md still works after gate text changes
- [x] Structured IDs: F/S/D/T prefix with 6-digit number + keywords, used in folder names and doc filenames
- [x] Scrum removed (subcommand, template, notes generation)
- [x] Review work item type removed (tracker-review.md, doc-review-notes.md, review-* branch pattern)

## Todos

- [x] Update tracker-feature.md
- [x] Update tracker-defect.md
- [x] Update tracker-user-story.md
- [x] Update tracker-task.md
- [x] Remove tracker-review.md, doc-review-notes.md, doc-scrum.md, TRACKER-TEMPLATE.md
- [x] Update SKILL.md (remove review-* pattern, scrum routing)
- [x] Update track.md (remove scrum, add structured ID generation)
- [x] Update artifact-manifests.json (remove review type)
- [ ] Verify phase detection still works
- [ ] Align existing work items to new template format

## Log

- 2026-04-11: Created. Template consolidation for solo-dev workflow.
- 2026-04-11: Implemented. Updated 4 tracker templates, removed 4 files, updated SKILL.md + track.md + artifact-manifests.json.
- 2026-04-11: Aligned all workflow-alpha work items to new template format with structured IDs.

## PRs

## Files

- templates/tracker-feature.md
- templates/tracker-defect.md
- templates/tracker-task.md
- templates/tracker-user-story.md
- skills/workflow/SKILL.md
- skills/workflow/track.md

## Insights

- Phase detection counts checkboxes, not text — changing gate wording is safe.

## Journal

### 2026-04-11 -- decision
Kept 4 phases for tasks (not 2) but with lighter gates. Consistent model; fewer gates achieves "lighter" without a structural change.
