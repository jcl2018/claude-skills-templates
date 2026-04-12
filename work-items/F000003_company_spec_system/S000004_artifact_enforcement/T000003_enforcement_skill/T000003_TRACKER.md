---
name: "implement-enforcement-check-subcommand"
type: task
id: "T000003_enforcement_skill"
status: active
created: "2026-04-11"
updated: "2026-04-11"
parent: "S000004_artifact_enforcement"
repo: "claude-skills-templates"
branch: "claude/nostalgic-volhard"
blocked_by: "T000002_copy_spec_scaffold"
---

## Lifecycle

### Phase 1: Track
- [x] Parent scope read (parent tracker reviewed)
- [x] Working branch created (`branch` field populated)
- [ ] Files section populated

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

- [ ] Create skills/company-workflow/company-artifact-manifests.json with 5 type entries
- [ ] Add `check` subcommand to skills/company-workflow/SKILL.md
- [ ] Implement: load manifest → resolve templates → walk work item dir → compare → report
- [ ] Test: scaffold complete feature, run check → all [PASS]
- [ ] Test: scaffold incomplete feature (missing PRD), run check → [MISSING]
- [ ] Test: corrupt tracker (remove workflow_type), run check → [DRIFT]
- [ ] Test: run /docs check → output unchanged (no interference)

## Log

- 2026-04-11: Created. Implement artifact enforcement in company skill. Child of S000004. Blocked by T000002 (templates must exist first).

## PRs

## Files

- skills/company-workflow/company-artifact-manifests.json
- skills/company-workflow/SKILL.md

## Insights

- Follow the /docs check pattern (check.md Steps 7-14) as reference implementation.
- Manifest mirrors artifact-manifests.json structure but lives inside the skill directory.
- The `check` subcommand is separate from the `validate` subcommand: validate checks contract.json (structural rules on a single file), check verifies artifact completeness (right files exist for the type).

## Journal

- 2026-04-11 [decision]: Two subcommands in the skill: `validate` (contract.json structural rules) and `check` (artifact completeness per type). Different concerns, different entry points.
