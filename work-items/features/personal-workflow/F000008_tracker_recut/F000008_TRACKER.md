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

<!-- This work item was scaffolded under the v2 manifest (TRACKER + feature-summary +
     DESIGN + milestones) and self-migrated to the v3 shape (TRACKER + DESIGN +
     ROADMAP) as part of S000015's sweep. Lifecycle text below reflects the v3 shape
     it now lives under. Original scaffolding history is captured in the Log
     section. -->

1. Run `/office-hours` to explore the problem space and generate a design doc
   → produces design doc in `~/.gstack/projects/`
2. Create working branch: `git checkout -b feat/tracker-recut`
3. Scaffold work item directory and TRACKER.md
4. Distill `DESIGN.md` from the /office-hours output — from `templates/doc-DESIGN.md`
5. Scaffold `ROADMAP.md` (scope, non-goals, decomposition, delivery timeline) — from `templates/doc-ROADMAP.md`
6. Define acceptance criteria (what "done" looks like for the whole feature)
7. Decompose into child user-stories
   → detail (DESIGN, SPEC, TEST-SPEC) lives in child stories

**Gates:**
- [x] /office-hours design produced (in `~/.gstack/projects/`)
- [x] Working branch created (`branch` field populated)
- [x] DESIGN + ROADMAP scaffolded
- [x] Acceptance criteria scoped
- [x] Broken down into child stories

### Phase 2: Implement

1. Child user-stories drive implementation (feature tracker coordinates)
2. Monitor child progress — update this tracker when children complete phases
3. Update Todos section — check off completed children, add discoveries
4. Update Files section with top-level changed files

**Gates:**
- [x] All child stories have entered Phase 2+
- [x] Feature-level Todos reflect remaining coordination work

### Phase 3: Ship

1. Run `/personal-workflow check` — verify all children pass validation
2. Verify smoke tests pass in CI (automated regression)
3. Walk E2E manually — run user-scenario verification before ship
4. Run `/ship` — creates feature PR (includes pre-landing code review)
5. Run `/land-and-deploy` — merges and verifies deployment

**Gates:**
- [ ] `/personal-workflow check` — all children pass validation
- [ ] Smoke tests pass in CI
- [ ] E2E walked manually
- [ ] `/ship` — PR created (with pre-landing review)
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
