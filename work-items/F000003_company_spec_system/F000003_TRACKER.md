---
name: "company-spec-work-item-system"
type: feature
id: "F000003_company_spec_system"
status: active
created: "2026-04-11"
updated: "2026-04-13"
repo: "claude-skills-templates"
branch: "claude/nostalgic-volhard"
blocked_by: ""
---

## Lifecycle

### Phase 1: Track

1. Run `/office-hours` to explore the problem space and generate a design doc
   -> produces design doc in `~/.gstack/projects/`
2. Create working branch: `git checkout -b feat/{slug}`
3. Scaffold work item directory and TRACKER.md
4. Define acceptance criteria (what "done" looks like for the whole feature)
5. Decompose into child user-stories
   -> detail (PRD, ARCHITECTURE, TEST-SPEC, milestones) lives in child stories

**Gates:**
- [x] Acceptance criteria scoped
- [x] Working branch created (`branch` field populated)
- [x] Broken down into child stories

### Phase 2: Implement

1. Child user-stories/tasks drive implementation (feature tracker coordinates)
2. Monitor child progress -- update this tracker when children complete phases
3. Update Todos section -- check off completed children, add discoveries
4. Update Files section with top-level changed files

**Gates:**
- [x] All child stories have entered Phase 2+
- [ ] Feature-level Todos reflect remaining coordination work

### Phase 3: Ship

1. Run `/docs check` -- verify full hierarchy passes all badges
2. Run `/docs tree` -- verify structural completeness (all children present)
3. Ensure all child stories have shipped
4. Run `/ship` -- creates feature PR, includes pre-landing code review
5. Run `/land-and-deploy` -- merges and verifies

**Gates:**
- [ ] `/docs check` -- all children pass validation
- [ ] `/docs tree` -- structure complete
- [ ] All children shipped
- [ ] `/ship` -- PR created
- [ ] `/land-and-deploy` -- merged and deployed

## Acceptance Criteria

### Template System
- [x] `templates/company-workflow/` contains all 13 company spec templates
- [x] `template-registry.json` at repo root declares both `workbench` and `company-workflow` template sets
- [x] Existing templates at `templates/*.md` are byte-identical to before
- [x] `./scripts/validate.sh` passes (no regression)
- [x] `./scripts/test.sh` passes (no regression)

### Enforcement
- [ ] `company-workflow check` enforces artifact completeness per type (feature=5, defect=3, task=2, userstory=5, review=2)
- [ ] Company skill owns its own artifact manifest (independent from artifact-manifests.json)
- [ ] Missing artifacts flagged [MISSING], frontmatter drift flagged [DRIFT], section drift flagged [DRIFT]

### Scaffolding
- [ ] `company-workflow create --type TYPE --name NAME` scaffolds all 5 types with correct artifacts
- [ ] Placeholder substitution ({ITEM_NAME}, {ITEM_ID}, {YYYY-MM-DD}, {BRANCH_NAME}, {author})
- [ ] Scaffolded output passes `company-workflow validate`

### Integration
- [ ] `skills/company-workflow/` contains SKILL.md, contract.json, reference guides, philosophy docs, fixtures
- [ ] `skills-deploy install` deploys company skill and templates without breaking existing deployment

## Todos

- [ ] [S000003_company_workflow_implementation](S000003_company_workflow_implementation/S000003_TRACKER.md) -- template registry done, enforcement + scaffolding remaining

## Log

- 2026-04-11: Created. Company-spec work item system: build a separate skill + template system for company workflow, coexisting with existing templates via template-registry.json namespacing. Design doc approved (9/10 quality).
- 2026-04-13: Consolidated 3 user stories (S000003, S000004, S000005) and 3 tasks (T000002, T000003, T000004) into single story + task. Rewritten as exemplary reference using 3-phase lifecycle.

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

### 2026-04-11 -- decision
Chose Approach B (Skill + Template Registry) over Approach A (minimal) and Approach C (submodule). Registry provides clean versioning and explicit template set boundaries.

### 2026-04-11 -- decision
Company templates preserve spec's exact `type: userstory` spelling (no hyphen). Personal-dev keeps `user-story` (hyphen). Two intentionally different systems.

### 2026-04-11 -- decision
Validation stays in the skill (not shared tooling). Defended against Codex challenge citing /docs check precedent.
