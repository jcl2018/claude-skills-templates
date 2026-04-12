---
type: architecture
parent: S000005_scaffold_work_items
feature: F000003_company_spec_system
title: "Scaffold Company Work Items — Architecture"
version: 1
status: Draft
date: 2026-04-12
author: chjiang
prd: S000005_PRD.md
reviewers: []
---

## Overview

Adds a `create` subcommand to the company-workflow skill. Reads company templates
via the fallback chain, determines required artifacts per type, generates the next
ID, creates the directory, and fills placeholders.

## Architecture

```
company-workflow create --type TYPE --name NAME [--parent PARENT]
  │
  ├── Path Resolution (existing, from SKILL.md)
  │     └── _SKILL_DIR, _TMPL_DIR resolved
  │
  ├── ID Generation
  │     └── scan work-items/ for highest {PREFIX}NNNNNN
  │     └── increment → new ID
  │
  ├── Artifact Mapping
  │     ├── feature  → [tracker-feature, doc-PRD, doc-ARCHITECTURE, doc-TEST-SPEC, doc-milestones]
  │     ├── defect   → [tracker-defect, doc-RCA, doc-test-plan]
  │     ├── task     → [tracker-task, doc-test-plan]
  │     ├── userstory → [tracker-user-story, doc-PRD, doc-ARCHITECTURE, doc-TEST-SPEC, doc-milestones]
  │     └── review   → [tracker-review, doc-review-notes]
  │
  ├── Directory Creation
  │     └── work-items/{ID}_{slug}/
  │
  ├── Template Copy + Placeholder Substitution
  │     └── for each artifact: read template, replace {ITEM_NAME}, {ITEM_ID}, etc.
  │
  └── Post-scaffold Validation
        └── run validate on the new tracker
```

### Components Affected

| Component | Repo | Change Type | Description |
|-----------|------|------------|-------------|
| skills/company-workflow/SKILL.md | skills/ | Modified | Add `create` subcommand |

### Data Flow

1. User runs `company-workflow create --type feature --name "google-search-clone"`
2. Skill resolves template dir via fallback chain
3. Scans work-items/ for highest F-prefixed ID, increments
4. Creates `work-items/F{next}_google_search_clone/`
5. For each required artifact: reads template from _TMPL_DIR, replaces placeholders, writes to directory
6. Runs `company-workflow validate` on the new tracker
7. Reports success or validation errors

## API Changes

### New APIs

| API | Signature | Description |
|-----|-----------|-------------|
| company-workflow create | `--type TYPE --name NAME [--parent ID]` | Scaffolds a complete work item |

### Modified APIs

None.

## Dependencies

| Dependency | Type | Status | Notes |
|-----------|------|--------|-------|
| S000003 (templates + registry + validate) | Feature | Complete | Templates and validate subcommand must exist |

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| ID collision if concurrent scaffolding | Low | Med | Single-user repo, sequential operation |
| Placeholder not substituted | Med | Low | Post-scaffold validation catches missing fields |

## Design Decisions

| Decision | Chosen | Rejected Alternative | Why |
|----------|--------|---------------------|-----|
| Artifact mapping | Hardcoded in SKILL.md | Read from company-artifact-manifests.json | Manifest doesn't exist yet (S000004 scope). Hardcode now, migrate when manifest lands. |
| Post-scaffold validation | Automatic | Optional | Catches errors at creation time, not review time |
