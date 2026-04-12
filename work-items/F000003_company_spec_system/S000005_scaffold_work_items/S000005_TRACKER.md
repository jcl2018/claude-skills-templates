---
name: "scaffold-company-work-items"
type: user-story
id: "S000005_scaffold_work_items"
status: active
created: "2026-04-12"
updated: "2026-04-12"
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

- [ ] `company-workflow create --type feature --name <name>` scaffolds tracker + PRD + ARCHITECTURE + TEST-SPEC + milestones (5 artifacts)
- [ ] `company-workflow create --type defect --name <name>` scaffolds tracker + RCA + test-plan (3 artifacts)
- [ ] `company-workflow create --type task --name <name> --parent <id>` scaffolds tracker + test-plan (2 artifacts)
- [ ] `company-workflow create --type userstory --name <name>` scaffolds tracker + PRD + ARCHITECTURE + TEST-SPEC + milestones (5 artifacts)
- [ ] `company-workflow create --type review --name <name>` scaffolds tracker + review-notes (2 artifacts)
- [ ] Scaffolded trackers have all company-required frontmatter fields (workflow_type, url, etc.)
- [ ] Scaffolded trackers have lifecycle with type-specific sub-gate checkboxes
- [ ] Scaffolded doc artifacts have correct frontmatter linking (parent, feature, prd, architecture refs)
- [ ] ID generation follows existing convention ({TYPE_PREFIX}{NNNNNN})
- [ ] Scaffolding reads templates from templates/company-workflow/ via the fallback chain

## Todos

- [ ] Add `create` subcommand to skills/company-workflow/SKILL.md
- [ ] Implement template reading + placeholder substitution
- [ ] Implement ID generation (scan work-items/ for highest existing ID per type)
- [ ] Implement artifact mapping (type → required doc templates)
- [ ] Test scaffolding for all 5 types with realistic inputs
- [ ] Test scaffolded output passes `company-workflow validate`

## Log

- 2026-04-12: Created. Scaffolding capability for company work items. Moved E2E tests (E1-E8) from S000003 TEST-SPEC here, since they test scaffolding behavior that S000003 doesn't implement.

## PRs

## Files

- skills/company-workflow/SKILL.md

## Insights

- E2E tests E1-E8 were originally in S000003's TEST-SPEC but tested scaffolding behavior, not template/registry setup. Moved here to align tests with the capability they verify.
- S000003 delivers the templates and registry. This story delivers the ability to use them to create work items.

## Journal

- 2026-04-12 [decision]: Split scaffolding from S000003. S000003 = templates + registry + skill structure + validate. S000005 = create subcommand + E2E scaffolding tests. Tests follow the capability.
