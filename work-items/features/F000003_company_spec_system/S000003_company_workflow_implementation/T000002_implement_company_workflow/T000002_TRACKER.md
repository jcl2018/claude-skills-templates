---
name: "Implement Company Workflow"
type: task
id: "T000002_implement_company_workflow"
status: closed
created: "2026-04-11"
updated: "2026-04-14"
parent: "S000003_company_workflow_implementation"
repo: "claude-skills-templates"
branch: "claude/nostalgic-volhard"
blocked_by: ""
---

## Lifecycle

### Phase 1: Track

1. Read parent tracker to understand scope and acceptance criteria
2. Create working branch: `git checkout -b feat/{slug}`
   (use parent's branch if the task ships in the same PR; create a new branch if it warrants its own PR)
3. Scaffold required docs:
   - `test-plan.md` (test scenarios for this task) -- from `templates/doc-test-plan.md`
4. Populate Files section with expected changed files
5. Write initial Todos from parent's acceptance criteria

**Gates:**
- [x] Parent scope read (parent tracker reviewed)
- [x] Working branch created (`branch` field populated)
- [x] Required docs scaffolded (test-plan)
- [x] Files section populated

### Phase 2: Implement

1. Work from `/office-hours` design doc + parent's acceptance criteria + your Todos
   -> design doc at `~/.gstack/projects/{slug}/`
2. Commit changes incrementally with descriptive messages
3. Update Todos section -- check off completed items, add discoveries
4. Update Files section with actual changed files

**Gates:**
- [x] Core changes committed (>=1 commit SHA in Log)
- [x] Todos section reflects remaining work (no stale items)
- [x] Files section updated with changed files

### Phase 3: Ship

1. Run `/docs check` -- verify no regressions
2. Verify test-plan: all test scenarios passing
3. Run `/ship` -- creates PR, bumps version, updates changelog (includes pre-landing code review)
4. Run `/land-and-deploy` -- merges PR and verifies deployment

**Gates:**
- [x] `/docs check` -- validation passed
- [x] Test-plan verified (all scenarios passing)
- [x] `/ship` -- PR created
- [x] `/land-and-deploy` -- merged and deployed

## Todos

- [x] Copy ~/Downloads/spec/templates/*.md to templates/company-workflow/ (13 files, byte-identical)
- [x] Copy contract.json, reference guides (7 files), philosophy docs (3 files), fixtures (3 files)
- [x] Create skills/company-workflow/SKILL.md with fallback chain and validate subcommand
- [x] Create template-registry.json with workbench + company-workflow sets
- [x] Add company-workflow to skills-catalog.json
- [x] validate.sh PASS, test.sh PASS

## Log

- 2026-04-11: Created. One-time manual copy of company spec into repo structure + skill scaffold. 27 files copied (13 templates + 1 contract + 7 guides + 3 rationale + 3 fixtures). SKILL.md created with 2-level fallback chain. Catalog entry added. validate.sh PASS, test.sh PASS.
- 2026-04-13: Consolidated from 3 tasks (T000002 copy/scaffold, T000003 enforcement, T000004 scaffolding) into single task. Rewritten as exemplary reference using 3-phase lifecycle.
- 2026-04-14: Closed. Template registration scope complete. Enforcement (check) and scaffolding (create) moved to T000005 and T000006 as standalone skill subcommands.

## PRs

## Files

- templates/company-workflow/
- skills/company-workflow/SKILL.md
- skills/company-workflow/contract.json
- skills/company-workflow/reference/
- skills/company-workflow/philosophy/
- skills/company-workflow/fixtures/
- template-registry.json
- skills-catalog.json

## Insights

- Source files at ~/Downloads/spec/ are a one-time import. After commit, the repo is the source of truth.
- The spec has 13 template files, 7 guide files, 3 rationale files, and 3 invalid fixture files.

## Journal

### 2026-04-11 -- finding
Spec templates differ from existing templates in key ways: workflow_type field, url field, verbose lifecycle checkboxes, review type support, scrum doc type.

<!-- CLOSED: 2026-04-14 -- template registration complete, enforcement+scaffolding moved to T000005/T000006 -->
