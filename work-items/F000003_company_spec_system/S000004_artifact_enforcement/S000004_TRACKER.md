---
name: "artifact-enforcement"
type: user-story
id: "S000004_artifact_enforcement"
status: active
created: "2026-04-11"
updated: "2026-04-11"
parent: "F000003_company_spec_system"
repo: "claude-skills-templates"
branch: "claude/nostalgic-volhard"
blocked_by: "S000003_template_registry"
---

## Lifecycle

### Phase 1: Track
- [x] Acceptance criteria defined
- [x] Working branch created (`branch` field populated)
- [ ] Doc triplet produced (PRD + ARCHITECTURE + TEST-SPEC)
- [ ] Milestones created
- [x] Tasks broken down (if needed)

### Phase 2: Implement
- [ ] Build-forward mode (from doc triplet + acceptance criteria)
- [ ] Implementation committed (>=1 commit SHA in Log)
- [ ] Acceptance criteria verified met

### Phase 3: Review
- [ ] Doc review completed
- [ ] Doc generation finalized
- [ ] Doc triplet alignment check (TEST-SPEC)

### Phase 4: Ship
- [ ] `/ship` — PR created
- [ ] `/land-and-deploy` — merged and deployed

## Acceptance Criteria

- [ ] Company skill has its own artifact manifest defining required artifacts per type
- [ ] `company-workflow check <path>` validates artifact completeness for a work item
- [ ] Feature: requires tracker + PRD + ARCHITECTURE + TEST-SPEC + milestones (5 artifacts)
- [ ] Defect: requires tracker + RCA + test-plan (3 artifacts)
- [ ] Task: requires tracker + test-plan (2 artifacts)
- [ ] User story: requires tracker + PRD + ARCHITECTURE + TEST-SPEC + milestones (5 artifacts)
- [ ] Review: requires tracker + review-notes (2 artifacts)
- [ ] Missing artifacts flagged as [MISSING], frontmatter drift as [DRIFT], section drift as [DRIFT]
- [ ] Enforcement is fully independent from /docs check and artifact-manifests.json
- [ ] Enforcement reads templates from templates/company-workflow/ for field/section expectations

## Todos

- [ ] Create company-artifact-manifests.json inside skills/company-workflow/
- [ ] Implement `company-workflow check` subcommand in SKILL.md
- [ ] Test enforcement against each of the 5 work item types
- [ ] Test enforcement catches missing artifacts, missing fields, missing sections
- [ ] Verify /docs check still works independently (no interference)

## Log

- 2026-04-11: Created. Artifact completeness enforcement for company work items. Child of F000003. Blocked by S000003 (needs templates in place first).

## PRs

## Files

- skills/company-workflow/company-artifact-manifests.json
- skills/company-workflow/SKILL.md

## Insights

- Enforcement is separate from /docs check by design. Each system owns its domain. /docs check reads artifact-manifests.json for workbench types; company skill reads its own manifest for company types.
- The /docs check pattern (Steps 7-14 in check.md) is the reference implementation: build expected model from manifest + templates, build actual model from work-items/, compare.

## Journal

- 2026-04-11 [decision]: Separate enforcement per skill (option B), not extending artifact-manifests.json. Company skill owns its own manifest and enforcement. Two independent systems.
