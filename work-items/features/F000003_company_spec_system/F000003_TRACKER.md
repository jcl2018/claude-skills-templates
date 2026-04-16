---
name: "company-spec-work-item-system"
type: feature
id: "F000003_company_spec_system"
status: active
created: "2026-04-11"
updated: "2026-04-14"
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
   -> detail (PRD, ARCHITECTURE, TEST-SPEC) lives in child stories

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

### Template Registration (shipped)
- [x] `templates/company-workflow/` contains all 13 company spec templates
- [x] `template-registry.json` declares both template sets
- [x] Existing templates unchanged
- [x] validate.sh + test.sh pass

### Standalone Skill
- [x] Skill has zero gstack dependencies
- [ ] `company-workflow validate <dir>` enforces artifact completeness per type
- [ ] company-artifact-manifests.json created with 5 type entries
- [ ] Skill works when installed in any repo via skills-deploy

### Integration
- [ ] `skills-deploy install` deploys skill + templates
- [ ] Reference guides and philosophy docs accessible

## Todos

- [ ] [S000003_company_workflow_implementation](S000003_company_workflow_implementation/S000003_TRACKER.md) -- check + create remaining

## Log

- 2026-04-11: Created. Company-spec work item system: standalone skill packaging company template spec. Design doc approved (9/10).
- 2026-04-13: Consolidated 3 stories into 1, rewritten for 3-phase lifecycle.
- 2026-04-14: PRD realigned for standalone framing. Stripped gstack deps from SKILL.md. T000002 closed (registration done). T000005 (check) and T000006 (create) created.

## PRs

## Files

- templates/company-workflow/
- skills/company-workflow/
- template-registry.json
- skills-catalog.json

## Insights

- The skill is standalone: zero gstack dependencies. Portable to any repo.
- Two template systems coexist: workbench (3-phase, user-story) and company (4-phase, userstory). Intentional divergence.
- One unified validate command with file mode (contract.json) and directory mode (artifact completeness).

## Journal

### 2026-04-11 -- decision
Chose Skill + Template Registry approach. Registry provides clean versioning and explicit template set boundaries.

### 2026-04-11 -- decision
Company templates preserve spec's exact `type: userstory` spelling. Two intentionally different systems.

### 2026-04-14 -- decision
Skill is standalone. Zero gstack dependencies. No analytics, no /review, no /ship, no /docs check references.

### 2026-04-15 -- decision
Simplified from 3 subcommands (validate/check/create) to 1 unified validate command. File mode = contract.json structural rules. Directory mode = artifact completeness via company-artifact-manifests.json. T000005 (check) and T000006 (create) killed.
