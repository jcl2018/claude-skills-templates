---
name: "historical-migration"
type: user-story
id: "S000015_historical_migration"
status: active
created: "2026-05-05"
updated: "2026-05-05"
parent: "F000008"
repo: "claude-skills-templates"
branch: "feat/tracker-recut"
blocked_by: "S000014"
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
6. Break into child tasks if scope warrants

**Gates:**
- [x] Acceptance criteria defined
- [x] Working branch created
- [x] Required docs scaffolded
- [x] Tasks broken down (N/A — atomic story per relaxed WORKFLOW.md rule; migration is one cohesive sweep)

### Phase 2: Implement

1. **Wait for S000014 to land** (templates + manifest + check.md must be in place before migration; otherwise check.md still expects old shape)
2. **Migrate 5 historical features** (work-items/features/personal-workflow/F000001, system-health/F000002, work-copilot/F000004, ops/deprecation/F000005, ops/deprecation/F000006):
   - For each: merge `feature-summary.md` + `milestones.md` content into a new `{ID}_ROADMAP.md` (preserve any merged-PR / merge-date entries from milestones.md into ROADMAP's `### Delivery History` sub-section)
   - Edit existing `{ID}_DESIGN.md` to rewrite `Milestones:` cross-link to `Roadmap:` (line 76-equivalent body content)
   - Delete `{ID}_feature-summary.md` and `{ID}_milestones.md`
3. **Migrate 8 historical user-stories** (S000001, S000006, S000007, S000008, S000009, S000010, S000012, S000013):
   - For each: merge `{ID}_PRD.md` + `{ID}_ARCHITECTURE.md` content into a new `{ID}_SPEC.md` (preserve PRD's `### P0/P1/P2` sub-sections inside the new `## Requirements` section)
   - Update `{ID}_TEST-SPEC.md` frontmatter: replace `prd:` + `architecture:` keys with single `spec: SPEC.md` (today's restructure handled the body)
   - Add `{ID}_DESIGN.md` per Open Question 1 default — 5-line stub: "no recorded /office-hours session; this user-story predates the convention"
   - Delete `{ID}_PRD.md` and `{ID}_ARCHITECTURE.md`
4. **Self-migrate F000008** (this work item):
   - Merge F000008_feature-summary.md + F000008_milestones.md into F000008_ROADMAP.md
   - Edit F000008_DESIGN.md cross-link
   - Delete F000008_feature-summary.md and F000008_milestones.md
   - For each child user-story (S000014, S000015, S000016): merge PRD + ARCHITECTURE → SPEC; add DESIGN.md (5-line stub since office-hours was at the parent level); update TEST-SPEC frontmatter; delete PRD + ARCHITECTURE
5. Run `/personal-workflow check` on full work-items/ tree — expect zero DRIFT/MISSING/EXTRA findings
6. Verify Step 18 traceability still passes for migrated user-stories that originally had it (S000001, S000006, S000012, S000013 had P0 stories in PRD)

**Gates:**
- [ ] All 5 historical features migrated
- [ ] All 8 historical user-stories migrated (including DESIGN.md stubs)
- [ ] F000008 self-migrated (feature + 3 children)
- [ ] `/personal-workflow check work-items/` returns zero findings
- [ ] Files section updated

### Phase 3: Ship

1. Run `/personal-workflow check` — verify all validation passes
2. Verify TEST-SPEC alignment
3. Children: none
4. Coordinate with S000014 + S000016 — all three land in the same PR via parent F000008
5. (Phase 3 ship gates complete via parent F000008)

**Gates:**
- [ ] `/personal-workflow check` validation passed (zero findings on full work-items/ tree)
- [ ] TEST-SPEC covers all P0 acceptance criteria
- [ ] `/ship` (handled by F000008) — PR created
- [ ] `/land-and-deploy` (handled by F000008) — merged

## Acceptance Criteria

- [ ] Each of the 5 historical features (F000001, F000002, F000004, F000005, F000006) has a `{ID}_ROADMAP.md` containing both Scope/Decomposition (from feature-summary) and Delivery Timeline (from milestones, with `### Delivery History` sub-section if applicable).
- [ ] Each of the 5 historical features has its `{ID}_feature-summary.md` and `{ID}_milestones.md` files deleted.
- [ ] Each of the 5 historical features' `{ID}_DESIGN.md` has its `Milestones:` cross-link rewritten to `Roadmap:`.
- [ ] Each of the 8 historical user-stories (S000001, S000006, S000007, S000008, S000009, S000010, S000012, S000013) has a `{ID}_SPEC.md` with `## Requirements` containing the merged content from PRD + ARCHITECTURE (preserving P0/P1/P2 sub-sections).
- [ ] Each of the 8 has `{ID}_DESIGN.md` (stub for items with no /office-hours record).
- [ ] Each of the 8 has `{ID}_TEST-SPEC.md` frontmatter updated: `prd: PRD.md` + `architecture: ARCHITECTURE.md` → single `spec: SPEC.md`.
- [ ] Each of the 8 has `{ID}_PRD.md` and `{ID}_ARCHITECTURE.md` deleted.
- [ ] F000008 itself migrated: feature artifacts + 3 children all on new shape.
- [ ] `/personal-workflow check work-items/` reports zero DRIFT, zero MISSING, zero EXTRA, zero UNTESTED findings.
- [ ] Step 18 traceability passes for all migrated user-stories that originally had P0 stories defined.

## Todos

- [ ] Migrate F000001 (feature)
- [ ] Migrate F000002
- [ ] Migrate F000004
- [ ] Migrate F000005
- [ ] Migrate F000006
- [ ] Migrate S000001
- [ ] Migrate S000006
- [ ] Migrate S000007
- [ ] Migrate S000008
- [ ] Migrate S000009
- [ ] Migrate S000010
- [ ] Migrate S000012
- [ ] Migrate S000013
- [ ] Self-migrate F000008 (feature + S000014 + S000015 + S000016)
- [ ] Run `/personal-workflow check work-items/` — verify zero findings

## Log

- 2026-05-05: Created.

## PRs

## Files

- `work-items/features/personal-workflow/F000001_personal_workflow/` (and 4 other historical feature dirs) — feature-summary + milestones → ROADMAP; DESIGN edit
- `work-items/features/.../S{ID}_*/` (8 user-story dirs) — PRD + ARCHITECTURE → SPEC; DESIGN add; TEST-SPEC frontmatter
- `work-items/features/personal-workflow/F000008_tracker_recut/` (self) — same migration treatment

## Insights

## Journal
