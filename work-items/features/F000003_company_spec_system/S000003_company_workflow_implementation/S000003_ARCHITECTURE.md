---
type: architecture
parent: S000003_company_workflow_implementation
feature: F000003_company_spec_system
title: "Company Workflow Implementation — Architecture"
version: 1
status: Draft
date: 2026-04-11
author: chjiang
prd: S000003_PRD.md
reviewers: []
---

## Overview

Three interconnected capabilities in the company-workflow skill, built on subfolder
namespacing and a template registry:

1. **Template Registry**: `template-registry.json` declares named template sets.
   `templates/company-workflow/` holds 13 company spec templates. No existing files modified.
2. **Artifact Enforcement**: `company-workflow check` validates work items against a
   company-specific manifest. Independent from `/docs check`.
3. **Scaffolding**: `company-workflow create` scaffolds new work items with the correct
   artifacts per type, fills placeholders, and validates the result.

## Architecture

```
template-registry.json (repo root)
    |
    +-- "workbench"         --> templates/                  (this repo's dev workflow)
    +-- "company-workflow"  --> templates/company-workflow/  (company spec)
            |
            v
skills/company-workflow/
    |
    +-- SKILL.md            (routing: validate, check, create)
    +-- contract.json       (structural rules for validate)
    +-- company-artifact-manifests.json  (type->artifact mapping for check)
    +-- reference/          (guide-*.md for AI doc generation)
    +-- philosophy/         (rationale-*.md for lifecycle reasoning)
    +-- fixtures/           (invalid-*.md for validation testing)
            |
            v
Three subcommands:
    |
    +-- validate <path>     (contract.json rules -> exit 0/1)
    +-- check <path>        (artifact completeness -> [PASS]/[MISSING]/[DRIFT])
    +-- create --type --name (scaffold -> validate)
```

### Components Affected

| Component | Change Type | Description |
|-----------|------------|-------------|
| templates/company-workflow/ | New | 13 company spec template files |
| skills/company-workflow/SKILL.md | New | Skill with validate, check, create subcommands |
| skills/company-workflow/contract.json | New | Structural validation rules |
| skills/company-workflow/company-artifact-manifests.json | New | Type->artifact mapping for enforcement |
| skills/company-workflow/reference/ | New | 7 guide files for AI doc generation |
| skills/company-workflow/philosophy/ | New | 3 rationale files for lifecycle |
| skills/company-workflow/fixtures/ | New | 3 invalid fixture files for testing |
| template-registry.json | New | Declares template sets with metadata |
| skills-catalog.json | Modified | Add company-workflow skill entry |

### Data Flow

**Validate flow:**
1. User runs `company-workflow validate <tracker-path>`
2. Skill reads contract.json for expected frontmatter fields and section order
3. Parses the tracker's YAML frontmatter and ## headings
4. Compares actual vs expected
5. Exit 0 (valid) or exit 1 (stderr lists violations)

**Check flow:**
1. User runs `company-workflow check <work-item-path>`
2. Skill reads company-artifact-manifests.json for type->artifact mapping
3. Reads TRACKER.md frontmatter to determine type
4. For each required artifact: resolves template, parses expected fields/sections
5. Checks if artifact exists and matches template structure
6. Reports [PASS], [MISSING], or [DRIFT] per artifact

**Create flow:**
1. User runs `company-workflow create --type TYPE --name NAME [--parent ID]`
2. Skill resolves template dir via fallback chain
3. Scans work-items/ for highest ID with matching type prefix, increments
4. Creates `work-items/{ID}_{slug}/`
5. For each required artifact: reads template, replaces placeholders, writes file
6. Runs validate on the new tracker
7. Reports success or validation errors

## API Changes

### New APIs

| API | Signature | Description |
|-----|-----------|-------------|
| template-registry.json | JSON file | Declares template sets with version, path, contract, types |
| company-workflow validate | `<path>` -> exit 0/1 | Validates tracker against contract.json |
| company-workflow check | `<path>` -> structured report | Validates artifact completeness per type |
| company-workflow create | `--type TYPE --name NAME [--parent ID]` | Scaffolds complete work item |

### Modified APIs

| API | Before | After | Reason |
|-----|--------|-------|--------|
| skills-catalog.json | 2 skills | 3 skills | Add company-workflow entry |

## Dependencies

| Dependency | Type | Status | Notes |
|-----------|------|--------|-------|
| Company spec templates | Code | Available | From ~/Downloads/spec/templates/ |
| skills-deploy | Infra | Available | May need subfolder template support |
| contract.json (from spec) | Code | Available | One-time copy |

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| skills-deploy can't handle subfolders | Med | Med | Create follow-up task to patch if needed |
| userstory/user-story spelling confusion | Med | Med | Intentional divergence documented; registry is authoritative |
| validate.sh breaks with new skill | Low | High | Run validate.sh as acceptance criterion |
| Template changes break enforcement | Med | Med | Enforcement reads templates dynamically, not hardcoded |

## Design Decisions

| Decision | Chosen | Rejected Alternative | Why |
|----------|--------|---------------------|-----|
| Namespacing | Subfolder (templates/company-workflow/) | Separate top-level dir | Consistency with existing patterns |
| Validation location | Inside skill with callable entry point | Shared script in scripts/ | /docs check pattern; CI can still call it |
| Template versioning | template-registry.json at repo root | Directory names only | Explicit boundaries and versions |
| userstory spelling | Preserve spec's exact spelling | Normalize to user-story | Company spec is the truth; two systems diverge |
| Spec import method | One-time manual copy | Git submodule | Submodules are painful; repo is source of truth after commit |
| Enforcement ownership | Company skill owns its own manifest | Extend /docs check | Two independent systems, each owns its domain |
| Artifact mapping (scaffolding) | Hardcoded initially | Read from manifest | Manifest doesn't exist yet (enforcement scope); migrate later |
| Post-scaffold validation | Automatic | Optional | Catches errors at creation time |
