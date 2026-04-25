---
name: "Company Workflow Implementation"
type: user-story
id: "S000003_company_workflow_implementation"
status: closed
created: "2026-04-11"
updated: "2026-04-15"
parent: "F000003_company_workflow"
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
6. Break into child tasks if scope warrants decomposition

**Gates:**
- [x] Acceptance criteria defined
- [x] Working branch created (`branch` field populated)
- [x] Required docs scaffolded (PRD + ARCHITECTURE + TEST-SPEC)
- [x] Tasks broken down (if needed)

### Phase 2: Implement

1. Child tasks drive implementation (user-story tracker coordinates)
2. Monitor child progress -- update this tracker when children complete phases
3. Update Todos section -- check off completed children, add discoveries
4. Update Files section with changed file paths

**Gates:**
- [x] All child tasks have entered Phase 2+
- [x] Acceptance criteria verified met
- [x] Todos section reflects remaining work (no stale items)
- [x] Files section updated with changed files

### Phase 3: Ship

1. Run `/docs check` -- verify all validation passes
   -> should show PASS for template, lifecycle, traceability, structure badges
2. Run `/docs tree` -- verify hierarchy and structural completeness
3. Verify TEST-SPEC alignment: do test cases cover all P0 acceptance criteria?
4. Ensure all child tasks have shipped
5. Run `/ship` -- creates PR, bumps version, updates changelog (includes pre-landing code review)
6. Run `/land-and-deploy` -- merges PR and verifies deployment

**Gates:**
- [x] `/docs check` -- validation passed
- [x] `/docs tree` -- structure verified
- [x] TEST-SPEC covers all P0 acceptance criteria
- [x] All children shipped
- [x] `/ship` -- PR created
- [x] `/land-and-deploy` -- merged and deployed

## Acceptance Criteria

### Template Registration (shipped)
- [x] `template-registry.json` exists at repo root with valid JSON
- [x] Registry declares `workbench` and `company-workflow` sets
- [x] `templates/company-workflow/` has all 13 company spec templates
- [x] Existing `templates/*.md` unchanged
- [x] `./scripts/validate.sh` passes
- [x] SKILL.md with validate subcommand working
- [x] Skill is standalone (zero gstack dependencies)

### Directory Validation
- [x] company-artifact-manifests.json created with 5 type entries
- [x] `company-workflow validate <dir>` validates artifact completeness
- [x] All 5 types enforced (feature=5, defect=3, task=2, userstory=5, review=2)
- [x] Missing artifacts flagged [MISSING], drift flagged [DRIFT]
- [x] Unresolved placeholders detected in frontmatter values
- [x] Independent from /docs check

## Todos

- [x] [T000002_implement_company_workflow](T000002_implement_company_workflow/T000002_TRACKER.md) -- CLOSED, template registration shipped
- [x] Directory validation (unified validate command with file + directory modes) -- shipped

## Log

- 2026-04-11: Created. Template registry, namespace coexistence, company skill scaffold.
- 2026-04-11: Implemented template registry. 27 files copied. validate.sh PASS, test.sh PASS.
- 2026-04-13: Consolidated from 3 stories into 1. Rewritten for 3-phase lifecycle.
- 2026-04-14: PRD realigned for standalone framing. T000002 closed (registration done). T000005 (check) and T000006 (create) created. Stripped gstack from SKILL.md.
- 2026-04-15: Closed. PRD updated with doc-driven dev workflow (3 steps), delivery section, removed ~/Downloads/spec references. ARCHITECTURE and TEST-SPEC updated with delivery. All acceptance criteria met.

## PRs

## Files

- skills/company-workflow/SKILL.md
- skills/company-workflow/contract.json
- skills/company-workflow/company-artifact-manifests.json
- skills/company-workflow/reference/
- skills/company-workflow/philosophy/
- skills/company-workflow/fixtures/
- templates/company-workflow/
- template-registry.json
- skills-catalog.json

## Insights

- The skill is standalone: zero gstack deps. Works in any repo via skills-deploy.
- Company 4-phase lifecycle preserved even though workbench uses 3-phase. Intentional divergence.
- One unified validate command: file mode (contract.json) and directory mode (artifact completeness).

## Journal

*Originally 3 stories (template registry, enforcement, scaffolding), consolidated 2026-04-13. PRD realigned for standalone framing 2026-04-14.*

### 2026-04-11 -- decision
Templates use subfolder namespacing under templates/ rather than a top-level dir.

### 2026-04-11 -- decision
Separate enforcement per skill, not extending artifact-manifests.json. Two independent systems.

### 2026-04-11 -- decision
Two subcommands: `validate` (contract rules) and `check` (artifact completeness). Different concerns.

### 2026-04-14 -- decision
Skill is standalone. Zero gstack dependencies. No analytics, no /review, no /docs check. Portable to any repo.

### 2026-04-15 -- decision
Simplified from 3 subcommands to 1 unified validate. T000005 (check) and T000006 (create) killed. Directory mode added to validate. company-artifact-manifests.json created. Templates fixed (tracker-review.md phase headings, tracker-feature.md N/A removal, Handoff removed from contract.json).
