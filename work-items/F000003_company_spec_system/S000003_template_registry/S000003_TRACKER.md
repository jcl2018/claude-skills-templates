---
name: "template-registry-namespace-coexistence"
type: user-story
id: "S000003_template_registry"
status: active
created: "2026-04-11"
updated: "2026-04-11"
parent: "F000003_company_spec_system"
repo: "claude-skills-templates"
branch: "claude/nostalgic-volhard"
blocked_by: ""
---

## Lifecycle

### Phase 1: Track
- [x] Acceptance criteria defined
- [x] Working branch created (`branch` field populated)
- [x] Doc triplet produced (PRD + ARCHITECTURE + TEST-SPEC)
- [x] Milestones created
- [x] Tasks broken down (if needed)

### Phase 2: Implement
- [x] Build-forward mode (from doc triplet + acceptance criteria)
- [x] Implementation committed (>=1 commit SHA in Log)
- [x] Acceptance criteria verified met

### Phase 3: Review
- [x] Doc review completed
- [x] Doc generation finalized
- [x] Doc triplet alignment check (TEST-SPEC) — Tier 1 smoke S1-S8 all PASS. E2E tests moved to S000005 (scaffolding scope).

### Phase 4: Ship
- [ ] `/ship` — PR created
- [ ] `/land-and-deploy` — merged and deployed

## Acceptance Criteria

- [x] `template-registry.json` exists at repo root with valid JSON schema
- [x] Registry declares `workbench` set pointing to `templates/` with types: feature, defect, task, user-story
- [x] Registry declares `company-workflow` set pointing to `templates/company-workflow/` with types: feature, defect, task, userstory, review
- [x] `company-workflow` set references contract path and guides path
- [x] `templates/company-workflow/` subfolder exists with all 13 company spec templates
- [x] Existing `templates/*.md` files are unchanged (byte-identical diff check)
- [x] `./scripts/validate.sh` passes after changes

## Todos

- [x] Design template-registry.json schema (version, sets, tracker_types, doc_types, contract, guides)
- [x] Create template-registry.json with both template set declarations
- [x] Set up templates/company-workflow/ subfolder (13 files)
- [x] Copy company spec templates into templates/company-workflow/ (byte-identical verified)
- [x] Verify workbench templates unchanged via git diff (empty diff confirmed)
- [x] Create skills/company-workflow/SKILL.md with 2-level fallback chain
- [x] Add catalog entry (templates: [] per eng review finding)
- [x] validate.sh PASS, test.sh PASS

## Log

- 2026-04-11: Created. Define template-registry.json and templates/company-workflow/ namespace. Child of F000003.
- 2026-04-11: Implemented. 27 source files copied (all byte-identical). template-registry.json created with workbench + company-workflow sets (tracker_types + doc_types). SKILL.md with 2-level fallback, validate subcommand, routing table. Catalog entry added. Eng review passed (2 issues resolved, 1 critical gap deferred to T000003). validate.sh PASS, test.sh PASS.

## PRs

## Files

- template-registry.json
- templates/company-workflow/

## Insights

- Template registry pattern draws from artifact-manifests.json design. Both are metadata files declaring type-to-artifact mappings.
- Subfolder namespacing follows the same convention as skills/ (skills/{name}/ → templates/{set}/).

## Journal

- 2026-04-11 [decision]: Templates use subfolder namespacing under templates/ rather than a separate top-level directory. Consistency with existing directory patterns.
