---
name: "company-spec-work-item-system"
type: feature
id: "F000003_company_spec_system"
status: active
created: "2026-04-11"
updated: "2026-04-11"
repo: "claude-skills-templates"
branch: "claude/nostalgic-volhard"
blocked_by: ""
---

## Lifecycle

### Phase 1: Track
- [x] Acceptance criteria scoped
- [x] Working branch created (`branch` field populated)
- [ ] Doc triplet produced (PRD + ARCHITECTURE + TEST-SPEC)
- [x] Broken down into child tasks/stories

### Phase 2: Implement
- [ ] Doc triplet read (build-forward mode)
- [ ] Core implementation committed (>=1 commit SHA in Log)
- [ ] Child tasks completed or deferred
- [ ] Files section updated

### Phase 3: Review
- [ ] Doc review completed
- [ ] Doc generation finalized

### Phase 4: Ship
- [ ] `/ship` — PR created
- [ ] `/land-and-deploy` — merged and deployed

## Acceptance Criteria

- [ ] `templates/company-workflow/` contains all company spec templates (structurally conformant per contract.json)
- [ ] `skills/company-workflow/` contains SKILL.md, contract.json, reference guides, philosophy docs, fixtures
- [ ] `template-registry.json` at repo root declares both `templates` and `company-workflow` template sets
- [ ] Validation entry point callable: `company-workflow validate <path>` returns exit 0/1
- [ ] Existing templates at `templates/*.md` are byte-identical to before
- [ ] `./scripts/validate.sh` passes (no regression)
- [ ] `./scripts/test.sh` passes (no regression)
- [ ] Reference guides and philosophy docs present in skill directory
- [ ] `company-workflow check` enforces artifact completeness per type (feature=5, defect=3, task=2, userstory=5, review=2)
- [ ] Company skill owns its own artifact manifest (independent from artifact-manifests.json)
- [ ] `skills-deploy install` deploys company skill and templates without breaking existing deployment

## Todos

- [ ] Copy spec templates from ~/Downloads/spec/templates/ to templates/company-workflow/
- [ ] Create skills/company-workflow/ with SKILL.md, contract.json, reference/, philosophy/, fixtures/
- [ ] Create template-registry.json at repo root
- [ ] Add company-workflow to skills-catalog.json
- [ ] Implement validation entry point in SKILL.md (`validate` — contract.json structural rules)
- [ ] Implement enforcement entry point in SKILL.md (`check` — artifact completeness per type)
- [ ] Create company-artifact-manifests.json inside skills/company-workflow/
- [ ] Test skills-deploy handles subfolder templates (create follow-on task if not)
- [ ] Run validate.sh and test.sh to confirm no regressions

## Log

- 2026-04-11: Created. Company-spec work item system: build a separate skill + template system for company workflow, coexisting with existing templates via template-registry.json namespacing. Design doc approved (9/10 quality, 2 review rounds).

## PRs

## Files

- templates/company-workflow/
- skills/company-workflow/
- template-registry.json
- skills-catalog.json

## Insights

- Two template sets coexist: workbench (root templates/) and company-workflow (templates/company-workflow/). Intentionally different spellings for user-story type (hyphen in workbench, no hyphen in company spec).
- Validation lives in the skill with a callable entry point, following the /docs check pattern.
- Codex challenged validation-in-skill premise; user defended with concrete pattern reference.

## Journal

- 2026-04-11 [decision]: Chose Approach B (Skill + Template Registry) over Approach A (minimal) and Approach C (submodule). Registry provides clean versioning and explicit template set boundaries.
- 2026-04-11 [decision]: Company templates preserve spec's exact `type: userstory` spelling (no hyphen). Personal-dev keeps `user-story` (hyphen). Two intentionally different systems.
- 2026-04-11 [decision]: Validation stays in the skill (not shared tooling). Defended against Codex challenge citing /docs check precedent.
