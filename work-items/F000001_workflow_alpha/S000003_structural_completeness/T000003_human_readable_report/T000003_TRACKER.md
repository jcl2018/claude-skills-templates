---
name: "Human-readable work item health report"
type: task
id: "T000003_human_readable_report"
status: active
created: "2026-04-12"
updated: "2026-04-12"
parent: "S000003_structural_completeness"
repo: "claude-skills-templates"
branch: "feat/structural-completeness"
blocked_by: "T000002"
---

## Lifecycle

### Phase 1: Track
- [x] Parent scope read (parent tracker reviewed)
- [x] Working branch created (`branch` field populated)
- [x] Files section populated

### Phase 2: Implement
- [ ] Core changes committed (>=1 commit SHA in Log)
- [ ] Todos section reflects remaining work (no stale items)
- [ ] Files section updated with changed files

### Phase 3: Review
- [ ] Doc review completed
- [ ] Doc generation finalized
- [ ] Test verification passed

### Phase 4: Ship
- [ ] `/ship` — PR created
- [ ] `/land-and-deploy` — merged and deployed

## Todos

- [ ] Add Step 18.5 to check.md: write `.docs/work-item-report.md` after graph artifact
- [ ] Report format: markdown with tree, badge summary table, findings list, structural summary
- [ ] Similar to system-health's human-readable dashboard output
- [ ] /docs tree also writes a lightweight version (structural badges only)
- [ ] Ensure report is regenerated on each /docs check run (not stale)

## Log

- 2026-04-12: Created. Human-readable report to complement work-item-graph.json.

## PRs

## Files

- skills/docs/check.md
- skills/docs/tree.md

## Insights

## Journal
