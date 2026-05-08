---
name: "tracker-recut"
type: feature
id: "F000008_tracker_recut"
status: active
created: "2026-05-05"
updated: "2026-05-05"
repo: "claude-skills-templates"
branch: "feat/tracker-recut"
blocked_by: ""
---

## Lifecycle

### Phase 1: Track

1. Run `/office-hours` to explore the problem space and generate a design doc
   → produces design doc in `~/.gstack/projects/`
2. Create working branch: `git checkout -b feat/tracker-recut`
3. Scaffold work item directory and TRACKER.md
4. Scaffold `feature-summary.md` (roll-up identity: scope, success criteria, constituent stories, non-goals) — from `templates/doc-feature-summary.md`
5. Scaffold `DESIGN.md` (problem shape, big decisions, risks) — from `templates/doc-DESIGN.md`
6. Scaffold `milestones.md` (delivery timeline) — from `templates/doc-milestones.md`
7. Define acceptance criteria (what "done" looks like for the whole feature)
8. Decompose into child user-stories
   → detail (PRD, ARCHITECTURE, TEST-SPEC) lives in child stories

**Gates:**
- [x] Acceptance criteria scoped
- [x] Working branch created (`branch` field populated)
- [x] feature-summary + DESIGN + milestones scaffolded
- [x] Broken down into child stories

### Phase 2: Implement

1. Child user-stories/tasks drive implementation (feature tracker coordinates)
2. Monitor child progress — update this tracker when children complete phases
3. Update Todos section — check off completed children, add discoveries
4. Update Files section with top-level changed files

**Gates:**
- [ ] All child stories have entered Phase 2+
- [ ] Feature-level Todos reflect remaining coordination work

### Phase 3: Ship

1. Run `/personal-workflow check` — verify all children pass validation
2. Ensure all child stories have shipped
3. Run `/ship` — creates feature PR, includes pre-landing code review
4. Run `/land-and-deploy` — merges and verifies

**Gates:**
- [ ] `/personal-workflow check` — all children pass validation
- [ ] All children shipped
- [ ] `/ship` — PR created
- [ ] `/land-and-deploy` — merged and deployed

## Acceptance Criteria

- [ ] Tracker templates produce 4 trackers with workflow-mirrored Phase ordering and 4-gate Phase 3 (smoke pass, E2E walked, /ship, /land-and-deploy).
- [ ] New artifact set lands cleanly: doc-SPEC.md and doc-ROADMAP.md created; doc-PRD.md, doc-ARCHITECTURE.md, doc-feature-summary.md, doc-milestones.md deleted.
- [ ] All 5 historical features migrated to TRACKER + DESIGN + ROADMAP shape; all 8 historical user-stories migrated to TRACKER + DESIGN + SPEC + TEST-SPEC shape.
- [ ] `/personal-workflow check` passes on the full `work-items/` tree post-migration with zero DRIFT, zero MISSING, zero EXTRA findings.
- [ ] `./scripts/test.sh` and `./scripts/validate.sh` pass.
- [ ] All ancillary surfaces updated: WORKFLOW.md (7 lines), CONTRIBUTING.md, PHILOSOPHY.md, template-registry.json, scripts/test.sh:585, scripts/test-deploy.sh canary swap.

## Todos

- [ ] S000014: introduce new templates + manifest + check.md changes
- [ ] S000015: migrate 13 historical work items + F000008 itself to new shape
- [ ] S000016: examples + fixtures + repo-level surfaces (PHILOSOPHY, CONTRIBUTING, scripts, registry, catalog)
- [ ] VERSION bump to v1.5.0; CHANGELOG entry

## Log

- 2026-05-05: Created. /office-hours design approved at `~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-main-design-20260505-140754.md`. Predecessor v1.4.0 (TEST-SPEC restructure, commit abe411c) verified shipped before scaffolding.

## PRs

## Files

- `templates/personal-workflow/` (multiple — 2 created, 4 deleted, 2 edited, 4 trackers updated)
- `skills/personal-workflow/personal-artifact-manifests.json` (v3.0.0)
- `skills/personal-workflow/check.md` (Step 18 + 4 incidentals)
- `skills/personal-workflow/WORKFLOW.md` (7 lines)
- `skills/personal-workflow/SKILL.md` (version bump)
- `CONTRIBUTING.md`, `PHILOSOPHY.md`, `template-registry.json`, `skills-catalog.json`
- `scripts/test.sh` (line 585 split per-workflow), `scripts/test-deploy.sh` (canary doc-PRD → doc-RCA)
- All historical work-item directories under `work-items/features/` (5 features + 8 user-stories)
- F000008 itself (self-migrated during S000015's sweep)

## Insights

## Journal
