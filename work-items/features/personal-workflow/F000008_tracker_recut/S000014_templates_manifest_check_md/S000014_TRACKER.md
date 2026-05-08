---
name: "templates-manifest-check-md"
type: user-story
id: "S000014_templates_manifest_check_md"
status: active
created: "2026-05-05"
updated: "2026-05-05"
parent: "F000008"
repo: "claude-skills-templates"
branch: "feat/tracker-recut"
blocked_by: ""
---

## Lifecycle

### Phase 1: Track

1. Read parent tracker to understand scope
2. Run `/office-hours` with your idea (parent's design covers this story; no per-story office-hours needed)
3. Create working branch: already on `feat/tracker-recut` from F000008
4. Scaffold work item directory and TRACKER.md
5. Scaffold required docs from design doc:
   - `PRD.md` (requirements) — from `templates/doc-PRD.md`
   - `ARCHITECTURE.md` (architecture decisions) — from `templates/doc-ARCHITECTURE.md`
   - `TEST-SPEC.md` (test scenarios) — from `templates/doc-TEST-SPEC.md`
6. Break into child tasks if scope warrants decomposition

**Gates:**
- [x] Acceptance criteria defined
- [x] Working branch created (`branch` field populated)
- [x] Required docs scaffolded (PRD + ARCHITECTURE + TEST-SPEC)
- [x] Tasks broken down (N/A — atomic story per relaxed WORKFLOW.md rule)

### Phase 2: Implement

1. Create new templates: `doc-SPEC.md`, `doc-ROADMAP.md`
2. Delete old templates: `doc-PRD.md`, `doc-ARCHITECTURE.md`, `doc-feature-summary.md`, `doc-milestones.md`
3. Edit kept templates: `doc-DESIGN.md` (3 edits: line 15 prose, line 71 comment, line 76 link), `doc-TEST-SPEC.md` (frontmatter cross-refs)
4. Rewrite tracker templates: `tracker-feature.md` (full rewrite), `tracker-user-story.md` (full rewrite), `tracker-task.md` (Prerequisite line addition), `tracker-defect.md` (no change)
5. Update `personal-artifact-manifests.json` to v3.0.0 with new artifact set
6. Update `check.md`: Step 18 (5 line edits at 303, 305, 309, 329 + delete 330) + 4 incidentals (84, 218, 220, 365)
7. Update `WORKFLOW.md` (7 lines: 21, 22, 38, 41, 49, 64-65, 190) PLUS the relaxed-task-rule edit at line 120 (already applied during F000008 scaffolding — see Insights)
8. Update `SKILL.md` version to 3.0.0
9. Smoke check: scaffold a synthetic new-shape work item under `/tmp` and run `/personal-workflow check` on it; verify PASS

**Gates:**
- [ ] All template create/delete/edit operations complete
- [ ] `/personal-workflow check` confirms new templates parse cleanly (synthetic /tmp test)
- [ ] Acceptance criteria verified met
- [ ] Files section updated

### Phase 3: Ship

1. Run `/personal-workflow check` — should show new-shape support; historical items will DRIFT until S000015 lands (expected)
2. Verify TEST-SPEC alignment: smoke + E2E cover all P0 acceptance criteria
3. Children: none
4. Coordinate with S000015 + S000016 — all three land in the same PR via parent F000008
5. (Phase 3 ship gates complete via parent F000008's `/ship` + `/land-and-deploy`)

**Gates:**
- [ ] `/personal-workflow check` validation passed for new templates (synthetic test)
- [ ] TEST-SPEC covers all P0 acceptance criteria
- [ ] `/ship` (handled by F000008) — PR created
- [ ] `/land-and-deploy` (handled by F000008) — merged

## Acceptance Criteria

- [ ] doc-SPEC.md created with `## Requirements` containing `### P0 (Must-Have)`, `### P1 (Important)`, `### P2 (Nice-to-Have)` sub-sections (preserves Step 18 parser).
- [ ] doc-ROADMAP.md created with `## Scope`, `## Non-Goals`, `## Success Criteria`, `## Decomposition`, `## Delivery Timeline` (with `### Delivery History` sub-section), `## Open Questions`.
- [ ] doc-PRD.md, doc-ARCHITECTURE.md, doc-feature-summary.md, doc-milestones.md deleted from `templates/personal-workflow/`.
- [ ] doc-DESIGN.md edited: line 15 prose, line 71 comment, line 76 Milestones link → Roadmap link.
- [ ] doc-TEST-SPEC.md frontmatter: `prd: PRD.md` + `architecture: ARCHITECTURE.md` → single `spec: SPEC.md`.
- [ ] tracker-feature.md, tracker-user-story.md rewritten with `/office-hours` Prerequisite + workflow-mirrored Phase ordering + 4-gate Phase 3.
- [ ] tracker-task.md Prerequisite line added (optional); tracker-defect.md unchanged.
- [ ] personal-artifact-manifests.json bumped to v3.0.0; types.feature and types.user-story rewritten.
- [ ] check.md Step 18: 4 PRD.md → SPEC.md substitutions (lines 303, 305, 309, 329) + line 330 legacy clause deleted.
- [ ] check.md incidentals: lines 84, 218, 220, 365 updated.
- [ ] WORKFLOW.md lines 21, 22, 38, 41, 49, 64-65, 190 updated.
- [ ] SKILL.md version bumped to 3.0.0.
- [ ] No active surface in skills/personal-workflow/ or templates/personal-workflow/ greps for "PRD" or "ARCHITECTURE" or "feature-summary" or "doc-milestones" except in error messages.

## Todos

- [ ] Draft doc-SPEC.md template (preserve P0/P1/P2 sub-sections)
- [ ] Draft doc-ROADMAP.md template (with Delivery History sub-section)
- [ ] Edit + delete operations on existing templates
- [ ] Manifest v3.0.0
- [ ] check.md Step 18 + 4 incidentals
- [ ] WORKFLOW.md 7-line update
- [ ] SKILL.md version bump
- [ ] Smoke check: synthetic new-shape work item under /tmp; `/personal-workflow check` returns PASS

## Log

- 2026-05-05: Created.

## PRs

## Files

- `templates/personal-workflow/doc-SPEC.md` (new)
- `templates/personal-workflow/doc-ROADMAP.md` (new)
- `templates/personal-workflow/doc-PRD.md` (delete)
- `templates/personal-workflow/doc-ARCHITECTURE.md` (delete)
- `templates/personal-workflow/doc-feature-summary.md` (delete)
- `templates/personal-workflow/doc-milestones.md` (delete)
- `templates/personal-workflow/doc-DESIGN.md` (edit lines 15, 71, 76)
- `templates/personal-workflow/doc-TEST-SPEC.md` (edit frontmatter lines 10-11)
- `templates/personal-workflow/tracker-feature.md` (rewrite)
- `templates/personal-workflow/tracker-user-story.md` (rewrite)
- `templates/personal-workflow/tracker-task.md` (edit: add Prerequisite line)
- `skills/personal-workflow/personal-artifact-manifests.json` (v3.0.0)
- `skills/personal-workflow/check.md` (Step 18 + 4 incidentals)
- `skills/personal-workflow/WORKFLOW.md` (7 lines)
- `skills/personal-workflow/SKILL.md` (version bump)

## Insights

- WORKFLOW.md task-required rule (line 120) was relaxed during F000008 scaffolding — `user-story → at least 1 task child` became `tasks are OPTIONAL; scaffold only when scope warrants further decomposition`. This let F000008's three children ship without task scaffolding (each is one cohesive change). The edit lives on this branch in `skills/personal-workflow/WORKFLOW.md` and is part of S000014's overall WORKFLOW.md update scope.

## Journal
