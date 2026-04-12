---
name: "Structural Completeness + Tree Report"
type: user-story
id: "S000003_structural_completeness"
status: active
created: "2026-04-11"
updated: "2026-04-11"
parent: "F000001_workflow_alpha"
repo: "claude-skills-templates"
branch: "feat/structural-completeness"
blocked_by: ""
---

## Lifecycle

### Phase 1: Track
- [x] Acceptance criteria defined
- [x] Working branch created (`branch` field populated)
- [x] Doc triplet produced (PRD + ARCHITECTURE + TEST-SPEC)
- [x] Milestones created
- [ ] Tasks broken down (if needed)

### Phase 2: Implement
- [x] Build-forward mode (from doc triplet + acceptance criteria)
- [x] Implementation committed (>=1 commit SHA in Log)
- [ ] Acceptance criteria verified met

### Phase 3: Review
- [ ] Doc review completed
- [ ] Doc generation finalized
- [ ] Doc triplet alignment check (TEST-SPEC)

### Phase 4: Ship
- [ ] `/ship` — PR created
- [ ] `/land-and-deploy` — merged and deployed

## Acceptance Criteria

- [ ] `/docs check` flags F000002_system_health_v1 as INCOMPLETE (0 user-story children)
- [ ] `/docs check` flags S000002_template_consolidation as INCOMPLETE (0 task children)
- [ ] Tree report renders hierarchy with per-node badges (template, lifecycle, traceability, structure)
- [ ] `work-item-graph.json` emitted to `.docs/` with correct schema (nodes, edges, structural_rules, completeness)
- [ ] Hierarchy rules read from `artifact-manifests.json` `hierarchy` field (required, no fallback)
- [ ] Orphan/misplaced detection: task under feature flagged as MISPLACED
- [ ] Placement rules enforced: feature/defect root-level, story inside feature, task inside story
- [ ] Badge taxonomy maps all existing check statuses to 4 badge categories with severity ordering
- [ ] Claims.json gate separated: Steps 1-5 skip if missing, Steps 6+ run regardless
- [ ] Lifecycle cross-reference: "broken down" checked + 0 children = LIFECYCLE_INCONSISTENT
- [ ] `/docs tree` subcommand renders tree with structural badges only (other badges show "—")
- [ ] Repos without `work-items/` gracefully skip structural checks and tree report
- [ ] Existing checks (1-3) continue to work unchanged

## Todos

- [ ] Add `hierarchy` field to artifact-manifests.json
- [ ] Separate claims.json gate in check.md (Steps 1-5 vs 6+)
- [ ] Add Steps 15-17 to check.md (structural check + orphan detection, tree report, graph artifact)
- [ ] Add badge taxonomy mapping to check.md
- [ ] Add lifecycle cross-reference for "broken down" checkbox
- [ ] Create tree.md for `/docs tree` subcommand
- [ ] Update SKILL.md with `/docs tree` routing
- [ ] Update skills-catalog.json (version bump, add tree.md)
- [ ] Run `/docs check` to verify F000002 flagged
- [ ] Run `./scripts/validate.sh` to confirm no regressions

## Log

- 2026-04-11: Created. Structural completeness enforcement for work item hierarchy.
- 2026-04-11: Design doc produced via /office-hours (9/10 after adversarial review).
- 2026-04-11: CEO review completed (SCOPE EXPANSION, 5 expansions accepted, 1 deferred).

## PRs

## Files

- skills/docs/check.md
- skills/docs/tree.md (new)
- skills/docs/SKILL.md
- artifact-manifests.json
- skills-catalog.json

## Insights

- Claims.json gate blocks ALL downstream checks including work items (Codex found this).
- Badge taxonomy must map all existing statuses to 4 categories with explicit severity ordering.
- F000002's TRACKER has "broken down" checked but 0 children — lifecycle/structural contradiction.

## Journal

### 2026-04-11 -- decision
Absolute rule: feature must have >= 1 user-story, user-story must have >= 1 task. No escape hatch. If something doesn't decompose, it's the wrong type.

### 2026-04-11 -- decision
Hierarchy rules stored in artifact-manifests.json, not hard-coded. Required field, no fallback. Forces repos to be explicit.

### 2026-04-11 -- decision
/docs tree shows structural badges only. Template/lifecycle/traceability badges show "—". Speed over completeness for the quick view.
