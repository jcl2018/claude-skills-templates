---
type: architecture
parent: ""
feature: F000003_company_spec_system
title: "Company-Spec Work Item System — Architecture"
version: 1
status: Draft
date: 2026-04-11
author: chjiang
prd: F000003_PRD.md
reviewers: []
---

## Overview

This design adds a company-workflow template system alongside the existing existing
templates using subfolder namespacing and a template registry. The approach was chosen
to provide clean versioning between template sets without modifying any existing files.
The skill owns validation via contract.json, following the `/docs check` pattern.

## Architecture

```
templates/                          templates/company-workflow/
  tracker-feature.md  (personal)      tracker-feature.md  (company)
  tracker-task.md                     tracker-task.md
  tracker-defect.md                   tracker-defect.md
  tracker-user-story.md               tracker-user-story.md
  doc-*.md                            tracker-review.md     (NEW type)
                                      doc-*.md
                                      doc-review-notes.md   (NEW)
                                      doc-scrum.md          (NEW)
        │                                     │
        └──── template-registry.json ─────────┘
                    │
        skills/company-workflow/
          SKILL.md        (routing, enforcement)
          contract.json   (structural rules)
          reference/      (guide-*.md)
          philosophy/     (rationale-*.md)
          fixtures/       (invalid-*.md)
```

### Components Affected

| Component | Repo | Change Type | Description |
|-----------|------|------------|-------------|
| templates/company-workflow/ | templates/ | New | Company spec template files (13 files) |
| skills/company-workflow/ | skills/ | New | Skill with validation, guides, philosophy, fixtures |
| template-registry.json | repo root | New | Declares template sets with metadata |
| skills-catalog.json | repo root | Modified | Add company-workflow skill entry |

### Data Flow

1. User invokes company skill or scaffolding command
2. Skill reads template-registry.json to resolve the `company-workflow` set
3. Skill reads templates from `templates/company-workflow/` path declared in registry
4. Skill scaffolds work item with company-required frontmatter fields
5. Validation reads contract.json and checks the scaffolded work item
6. Exit code 0 (valid) or 1 (invalid with stderr violations)

## API Changes

### New APIs

| API | Signature | Description |
|-----|-----------|-------------|
| company-workflow validate | `<work-item-path>` → exit 0/1 | Validates work item against contract.json |

### Modified APIs

| API | Before | After | Reason |
|-----|--------|-------|--------|
| skills-catalog.json | 2 skills | 3 skills | Add company-workflow entry |

## Dependencies

| Dependency | Type | Status | Notes |
|-----------|------|--------|-------|
| skills-deploy | Infra | Available | May need subfolder template support |
| artifact-manifests.json | Code | Available | May need company-workflow type→artifact mapping |
| contract.json (from spec) | Code | Available | One-time copy from ~/Downloads/spec/ |

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| skills-deploy can't handle subfolders | Med | Med | Create T000003 to patch if needed |
| userstory/user-story spelling confusion | Med | Med | Intentional divergence documented; registry is authoritative |
| validate.sh breaks with new skill | Low | High | Run validate.sh as acceptance criterion |

## Design Decisions

| Decision | Chosen | Rejected Alternative | Why |
|----------|--------|---------------------|-----|
| Namespacing | Subfolder (templates/company-workflow/) | Separate top-level dir | Consistency with existing patterns |
| Validation location | Inside skill with callable entry point | Shared script in scripts/ | /docs check pattern works; CI can still call it |
| Template versioning | template-registry.json at repo root | Directory names only | Explicit boundaries and versions |
| userstory spelling | Preserve spec's exact spelling | Normalize to user-story | Company spec is the truth; two systems diverge |
| Spec import method | One-time manual copy | Git submodule | Submodules are painful; repo is source of truth after commit |
