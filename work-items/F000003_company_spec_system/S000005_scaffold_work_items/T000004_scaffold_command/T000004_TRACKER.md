---
name: "implement-scaffold-create-subcommand"
type: task
id: "T000004_scaffold_command"
status: active
created: "2026-04-12"
updated: "2026-04-12"
parent: "S000005_scaffold_work_items"
repo: "claude-skills-templates"
branch: "claude/nostalgic-volhard"
blocked_by: "T000002_copy_spec_scaffold"
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

- [ ] Add `create` subcommand section to skills/company-workflow/SKILL.md
- [ ] Implement placeholder substitution ({ITEM_NAME}, {ITEM_ID}, {YYYY-MM-DD}, {BRANCH_NAME}, {author})
- [ ] Implement ID generation (scan work-items/ for highest {PREFIX}NNNNNN, increment)
- [ ] Implement artifact mapping (type → required templates list)
- [ ] Add post-scaffold validation (run validate on new tracker)
- [ ] Run E2E tests E1-E8 from S000005 TEST-SPEC

## Log

- 2026-04-12: Created. Implement scaffolding create subcommand. Child of S000005. Blocked by T000002 (templates must exist).

## PRs

## Files

- skills/company-workflow/SKILL.md

## Insights

## Journal

- 2026-04-12 [decision]: Artifact mapping hardcoded in SKILL.md for now. Will migrate to read from company-artifact-manifests.json when S000004 (enforcement) lands.
