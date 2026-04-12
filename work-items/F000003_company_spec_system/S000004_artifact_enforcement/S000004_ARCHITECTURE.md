---
type: architecture
parent: S000004_artifact_enforcement
feature: F000003_company_spec_system
title: "Artifact Enforcement — Architecture"
version: 1
status: Draft
date: 2026-04-11
author: chjiang
prd: S000004_PRD.md
reviewers: []
---

## Overview

The company skill gets a `check` subcommand that validates work items against a
company-specific artifact manifest. It follows the same pattern as `/docs check`
(Steps 7-14) but reads its own manifest and its own templates. The two enforcement
systems are fully independent.

## Architecture

```
company-workflow check <path>
  │
  ├── Load: skills/company-workflow/company-artifact-manifests.json
  │     └── type → [required artifacts with template + filename]
  │
  ├── Resolve: templates/company-workflow/{template}
  │     └── parse frontmatter fields + ## section headers
  │
  ├── Walk: work-items/{path}/
  │     └── find TRACKER.md, read type from frontmatter
  │     └── list all .md files, match against expected filenames
  │
  └── Report:
        ├── [PASS]    artifact present, all fields, all sections
        ├── [MISSING] required artifact not found
        └── [DRIFT]   field missing or section missing/reordered
```

### Components Affected

| Component | Repo | Change Type | Description |
|-----------|------|------------|-------------|
| skills/company-workflow/company-artifact-manifests.json | skills/ | New | Type→artifact mapping for company work items |
| skills/company-workflow/SKILL.md | skills/ | Modified | Add `check` subcommand |

### Data Flow

1. User runs `company-workflow check work-items/F000003_company_spec_system/`
2. Skill reads company-artifact-manifests.json
3. Reads TRACKER.md frontmatter to determine type (e.g., `feature`)
4. Looks up required artifacts for that type (e.g., 5 for feature)
5. For each required artifact, resolves template from templates/company-workflow/
6. Parses template for expected frontmatter keys and section headers
7. Checks if the artifact file exists in the work item directory
8. If exists: compares actual frontmatter and sections against expected
9. Outputs structured report

## API Changes

### New APIs

| API | Signature | Description |
|-----|-----------|-------------|
| company-workflow check | `<work-item-path>` → structured report | Validates artifact completeness and structural compliance |

### Modified APIs

None.

## Dependencies

| Dependency | Type | Status | Notes |
|-----------|------|--------|-------|
| S000003 (template registry) | Feature | Pending | Templates must be in place before enforcement can read them |
| contract.json | Code | Available | Structural rules for tracker validation |

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Manifest format drift from artifact-manifests.json | Low | Low | Same structure, reviewed at creation |
| Template changes break enforcement | Med | Med | Enforcement reads templates dynamically, not hardcoded |

## Design Decisions

| Decision | Chosen | Rejected Alternative | Why |
|----------|--------|---------------------|-----|
| Enforcement ownership | Company skill owns its own | Extend /docs check | Two independent systems, each owns its domain |
| Manifest location | Inside skill directory | Repo root | Skill is self-contained; manifest ships with the skill |
| Report format | Same as /docs check ([PASS]/[MISSING]/[DRIFT]) | Custom format | Familiar output, consistent UX across enforcement systems |
