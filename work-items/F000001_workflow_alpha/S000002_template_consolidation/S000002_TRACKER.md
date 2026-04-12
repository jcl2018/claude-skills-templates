---
name: "Work Item Template Consolidation"
type: user-story
id: "S000002_template_consolidation"
status: active
created: "2026-04-11"
updated: "2026-04-11"
parent: "F000001_workflow_alpha"
repo: "claude-skills-templates"
branch: "feat/workflow-alpha"
blocked_by: ""
---

## Lifecycle

### Phase 1: Track

1. Read parent tracker to understand scope
2. Run `/office-hours` with your idea
   → produces design doc in `~/.gstack/projects/`
3. Create working branch: `git checkout -b feat/{slug}`
4. Scaffold work item directory and TRACKER.md
5. Extract from design doc into doc triplet: requirements → `PRD.md`, architecture decisions → `ARCHITECTURE.md`, test scenarios → `TEST-SPEC.md`
   (use templates from `templates/doc-PRD.md`, `doc-ARCHITECTURE.md`, `doc-TEST-SPEC.md`)
6. Create milestones from PRD acceptance criteria
7. Break into child tasks if scope warrants decomposition

**Gates:**
- [x] Acceptance criteria defined
- [x] Working branch created (`branch` field populated)
- [x] Doc triplet produced (PRD + ARCHITECTURE + TEST-SPEC)
- [ ] Milestones created
- [ ] Tasks broken down (if needed)

### Phase 2: Implement

1. Work from doc triplet + acceptance criteria (build-forward mode)
2. Commit changes incrementally with descriptive messages
3. Update Todos section — remove completed items, add new discoveries
4. Update Files section with all changed file paths

**Gates:**
- [x] Implementation committed (>=1 commit SHA in Log)
- [ ] Acceptance criteria verified met
- [ ] Todos section reflects remaining work (no stale items)
- [ ] Files section updated with changed files

### Phase 3: Review

1. Run `/docs check` — verify all validation passes
   → should show PASS for template, lifecycle, traceability, structure badges
2. Run `/docs tree` — verify hierarchy and structural completeness
3. Run tests: `./scripts/test.sh`
4. Review TEST-SPEC alignment: do test cases cover all P0 acceptance criteria?
5. Run `/review` for code review (if PR exists)

❌ If `/docs check` finds issues: fix findings, re-run until clean

**Gates:**
- [ ] `/docs check` — validation passed
- [ ] `/docs tree` — structure verified
- [ ] Test verification passed
- [ ] Doc triplet alignment verified (TEST-SPEC covers P0 stories)

### Phase 4: Ship

1. Run `/ship` — creates PR, bumps version, updates changelog
2. Run `/land-and-deploy` — merges PR and verifies deployment

❌ If CI fails: fix, push, re-run `/ship`

**Gates:**
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
