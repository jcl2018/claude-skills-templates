---
type: architecture
parent: S000003_template_registry
feature: F000003_company_spec_system
title: "Template Registry and Namespace Coexistence — Architecture"
version: 1
status: Draft
date: 2026-04-11
author: chjiang
prd: S000003_PRD.md
reviewers: []
---

## Overview

Introduces `template-registry.json` at repo root and a `templates/company-workflow/` subfolder.
The registry is a passive metadata file that declares template sets. The subfolder
prevents naming conflicts. No existing files are modified.

## Architecture

```
template-registry.json (repo root)
  │
  ├── "workbench"
  │     path: "templates/"
  │     types: [feature, defect, task, user-story]
  │     contract: null
  │
  └── "company-workflow"
        path: "templates/company-workflow/"
        types: [feature, defect, task, userstory, review]
        contract: "skills/company-workflow/contract.json"
        guides: "skills/company-workflow/reference/"
```

### Components Affected

| Component | Repo | Change Type | Description |
|-----------|------|------------|-------------|
| template-registry.json | repo root | New | Metadata declaring template sets |
| templates/company-workflow/ | templates/ | New | 13 company spec template files |

### Data Flow

1. Skill or tooling reads template-registry.json
2. Looks up the set name
3. Resolves path from the registry entry
4. Reads templates from that path

## API Changes

### New APIs

| API | Signature | Description |
|-----|-----------|-------------|
| template-registry.json | JSON file | Declares template sets with version, path, contract, types |

### Modified APIs

None.

## Dependencies

| Dependency | Type | Status | Notes |
|-----------|------|--------|-------|
| Company spec templates | Code | Available | From ~/Downloads/spec/templates/ |

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Registry schema changes | Low | Low | version field allows evolution |
| Third template set needed | Low | Low | Registry supports arbitrary names |

## Design Decisions

| Decision | Chosen | Rejected Alternative | Why |
|----------|--------|---------------------|-----|
| Registry location | Repo root | Inside skill dir | Registry describes the whole repo |
| Namespace method | Subfolder | Prefix naming | Subfolders match existing patterns |
| Format | JSON | YAML | Consistency with existing configs |
