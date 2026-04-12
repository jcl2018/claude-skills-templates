---
name: "Implement structural completeness check"
type: task
id: "T000002_implement_structural_check"
status: active
created: "2026-04-11"
updated: "2026-04-11"
parent: "S000003_structural_completeness"
repo: "claude-skills-templates"
branch: "feat/structural-completeness"
blocked_by: ""
---

## Lifecycle

### Phase 1: Track
- [x] Parent scope read (parent tracker reviewed)
- [x] Working branch created (`branch` field populated)
- [x] Files section populated

### Phase 2: Implement
- [x] Core changes committed (>=1 commit SHA in Log)
- [x] Todos section reflects remaining work (no stale items)
- [x] Files section updated with changed files

### Phase 3: Review
- [ ] Doc review completed
- [ ] Doc generation finalized
- [ ] Test verification passed

### Phase 4: Ship
- [ ] `/ship` — PR created
- [ ] `/land-and-deploy` — merged and deployed

## Todos

- [x] Add `hierarchy` field to artifact-manifests.json
- [x] Separate claims.json gate in check.md (Steps 1-5 skip if missing, Steps 6+ run)
- [x] Add Step 15: structural completeness check + orphan/misplaced detection + placement rules
- [x] Add Step 16: completeness counts + tree report with all 4 badges per node
- [x] Add Step 17: graph artifact emission to `.docs/work-item-graph.json`
- [x] Add badge taxonomy mapping (all existing statuses → 4 categories with severity)
- [x] Add lifecycle cross-reference ("broken down" checked + 0 children = LIFECYCLE_INCONSISTENT)
- [x] Create `skills/docs/tree.md` for `/docs tree` subcommand (structural badges only)
- [x] Update `skills/docs/SKILL.md` with `/docs tree` routing
- [x] Update `skills-catalog.json` (version bump, add tree.md to files)
- [ ] Run `/docs check` — verify F000002 flagged INCOMPLETE
- [ ] Run `/docs tree` — verify tree renders with structural badges
- [x] Run `./scripts/validate.sh` — verify no regressions

## Log

- 2026-04-11: Created. Full implementation of structural completeness check from S000003 scope.
- 2026-04-12: Implemented. Core impl in 154a4b3, work items in 98aa45a.

## PRs

## Files

- artifact-manifests.json
- skills/docs/check.md
- skills/docs/tree.md (new)
- skills/docs/SKILL.md
- skills-catalog.json

## Insights

## Journal
