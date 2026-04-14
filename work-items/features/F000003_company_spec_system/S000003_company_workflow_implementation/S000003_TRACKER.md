---
name: "Company Workflow Implementation"
type: user-story
id: "S000003_company_workflow_implementation"
status: active
created: "2026-04-11"
updated: "2026-04-13"
parent: "F000003_company_spec_system"
repo: "claude-skills-templates"
branch: "claude/nostalgic-volhard"
blocked_by: ""
---

## Lifecycle

### Phase 1: Track

1. Read parent tracker to understand scope
2. Run `/office-hours` with your idea
   -> produces design doc in `~/.gstack/projects/`
3. Create working branch: `git checkout -b feat/{slug}`
4. Scaffold work item directory and TRACKER.md
5. Scaffold required docs from design doc:
   - `PRD.md` (requirements) -- from `templates/doc-PRD.md`
   - `ARCHITECTURE.md` (architecture decisions) -- from `templates/doc-ARCHITECTURE.md`
   - `TEST-SPEC.md` (test scenarios) -- from `templates/doc-TEST-SPEC.md`
   - `milestones.md` (delivery milestones) -- from `templates/doc-milestones.md`
6. Create milestones from PRD acceptance criteria
7. Break into child tasks if scope warrants decomposition

**Gates:**
- [x] Acceptance criteria defined
- [x] Working branch created (`branch` field populated)
- [x] Required docs scaffolded (PRD + ARCHITECTURE + TEST-SPEC + milestones)
- [x] Milestones created
- [x] Tasks broken down (if needed)

### Phase 2: Implement

1. Child tasks drive implementation (user-story tracker coordinates)
2. Monitor child progress -- update this tracker when children complete phases
3. Update Todos section -- check off completed children, add discoveries
4. Update Files section with changed file paths

**Gates:**
- [x] All child tasks have entered Phase 2+
- [ ] Acceptance criteria verified met
- [ ] Todos section reflects remaining work (no stale items)
- [ ] Files section updated with changed files

### Phase 3: Ship

1. Run `/docs check` -- verify all validation passes
   -> should show PASS for template, lifecycle, traceability, structure badges
2. Run `/docs tree` -- verify hierarchy and structural completeness
3. Verify TEST-SPEC alignment: do test cases cover all P0 acceptance criteria?
4. Ensure all child tasks have shipped
5. Run `/ship` -- creates PR, bumps version, updates changelog (includes pre-landing code review)
6. Run `/land-and-deploy` -- merges PR and verifies deployment

**Gates:**
- [ ] `/docs check` -- validation passed
- [ ] `/docs tree` -- structure verified
- [ ] TEST-SPEC covers all P0 acceptance criteria
- [ ] All children shipped
- [ ] `/ship` -- PR created
- [ ] `/land-and-deploy` -- merged and deployed

## Acceptance Criteria

### Template Registry
- [x] `template-registry.json` exists at repo root with valid JSON schema
- [x] Registry declares `workbench` set pointing to `templates/` with types: feature, defect, task, user-story
- [x] Registry declares `company-workflow` set pointing to `templates/company-workflow/` with types: feature, defect, task, userstory, review
- [x] `company-workflow` set references contract path and guides path
- [x] `templates/company-workflow/` subfolder exists with all 13 company spec templates (byte-identical to source)
- [x] Existing `templates/*.md` files are unchanged
- [x] `./scripts/validate.sh` passes after changes

### Artifact Enforcement
- [ ] Company skill has its own artifact manifest (company-artifact-manifests.json)
- [ ] `company-workflow check <path>` validates artifact completeness for a work item
- [ ] Feature: requires tracker + PRD + ARCHITECTURE + TEST-SPEC + milestones (5 artifacts)
- [ ] Defect: requires tracker + RCA + test-plan (3 artifacts)
- [ ] Task: requires tracker + test-plan (2 artifacts)
- [ ] User story: requires tracker + PRD + ARCHITECTURE + TEST-SPEC + milestones (5 artifacts)
- [ ] Review: requires tracker + review-notes (2 artifacts)
- [ ] Missing artifacts flagged as [MISSING], frontmatter drift as [DRIFT], section drift as [DRIFT]
- [ ] Enforcement is fully independent from /docs check and artifact-manifests.json

### Scaffolding
- [ ] `company-workflow create --type feature --name <name>` scaffolds 5 artifacts
- [ ] `company-workflow create --type defect --name <name>` scaffolds 3 artifacts
- [ ] `company-workflow create --type task --name <name> --parent <id>` scaffolds 2 artifacts
- [ ] `company-workflow create --type userstory --name <name>` scaffolds 5 artifacts
- [ ] `company-workflow create --type review --name <name>` scaffolds 2 artifacts
- [ ] Scaffolded trackers have all company-required frontmatter fields
- [ ] Placeholder substitution works ({ITEM_NAME}, {ITEM_ID}, {YYYY-MM-DD}, {BRANCH_NAME}, {author})
- [ ] Scaffolded output passes `company-workflow validate`
- [ ] ID generation follows convention ({TYPE_PREFIX}{NNNNNN})

## Todos

- [ ] [T000002_implement_company_workflow](T000002_implement_company_workflow/T000002_TRACKER.md) -- template registry done, enforcement + scaffolding remaining
- [ ] Implement enforcement (company-artifact-manifests.json + check subcommand)
- [ ] Implement scaffolding (create subcommand + ID generation + placeholder substitution)
- [ ] Run /docs check to verify hierarchy
- [ ] Run ./scripts/test.sh for full validation

## Log

- 2026-04-11: Created. Template registry, namespace coexistence, and company skill scaffold. Child of F000003.
- 2026-04-11: Implemented template registry. 27 source files copied (all byte-identical). template-registry.json created. SKILL.md with 2-level fallback, validate subcommand. Catalog entry added. validate.sh PASS, test.sh PASS.
- 2026-04-13: Consolidated from 3 stories (S000003 template registry, S000004 artifact enforcement, S000005 scaffold work items) and 3 tasks (T000002, T000003, T000004) into single story + task. Rewritten as exemplary reference using 3-phase lifecycle.

## PRs

## Files

- template-registry.json
- templates/company-workflow/
- skills/company-workflow/SKILL.md
- skills/company-workflow/contract.json
- skills/company-workflow/reference/
- skills/company-workflow/philosophy/
- skills/company-workflow/fixtures/
- skills-catalog.json

## Insights

- Template registry pattern draws from artifact-manifests.json design. Both are metadata files declaring type-to-artifact mappings.
- Enforcement is separate from /docs check by design. Each system owns its domain. /docs check reads artifact-manifests.json for workbench types; company skill reads its own manifest for company types.
- E2E tests for scaffolding were originally in the template registry scope but moved out because they test scaffolding behavior, not registry setup. Tests follow the capability.

## Journal

*Originally split into 3 stories (S000003 template registry, S000004 artifact enforcement, S000005 scaffold work items), consolidated 2026-04-13.*

### 2026-04-11 -- decision
Templates use subfolder namespacing under templates/ rather than a separate top-level directory. Consistency with existing directory patterns.

### 2026-04-11 -- decision
Separate enforcement per skill, not extending artifact-manifests.json. Company skill owns its own manifest and enforcement. Two independent systems.

### 2026-04-11 -- decision
Two subcommands in the skill: `validate` (contract.json structural rules on a single file) and `check` (artifact completeness per type). Different concerns, different entry points.

### 2026-04-12 -- decision
Split scaffolding from template registry scope. Template registry = templates + registry + skill structure + validate. Scaffolding = create subcommand + E2E scaffolding tests. Tests follow the capability.

### 2026-04-12 -- decision
Artifact mapping hardcoded in SKILL.md for scaffolding initially. Will migrate to read from company-artifact-manifests.json when enforcement lands.
