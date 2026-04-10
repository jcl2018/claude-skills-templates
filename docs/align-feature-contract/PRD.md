---
type: prd
feature: align-feature-contract
title: "Align Feature Contract — Product Requirements"
version: 1
status: Active
date: 2026-04-09
author: chjiang
---

## Problem Statement

Doc triplets (PRD + ARCHITECTURE + TEST-SPEC) are only useful if they follow the template structure, reference each other correctly, and contain real content instead of placeholder text. Without enforcement, triplets drift from templates, cross-references break, and placeholder sections persist unnoticed. The repo owner needs automated contract enforcement that catches structural, traceability, and content issues.

## Mental Model

Three enforcement levels: L1 (template alignment) checks that each doc has required sections matching its template. L2 (cross-doc traceability) verifies that ARCHITECTURE references its PRD and TEST-SPEC references both. L3 (reference verification) confirms that referenced files exist on disk. Fix mode can auto-repair common issues. `/test-align-contract` provides a test harness.

## User Stories

### P0 (Must-Have)

| # | Tag | What it asks | As a... | I want to... | So that... |
|---|-----|-------------|---------|-------------|------------|
| 1 | core | Does L1 catch missing required sections? | doc author | run /align-feature-contract and have it flag any PRD missing Problem Statement or User Stories | every triplet has the sections the template requires |
| 2 | core | Does L2 verify cross-doc references? | doc author | have the tool check that ARCHITECTURE.md frontmatter points to its PRD | broken cross-references are caught before they cause confusion |
| 3 | core | Does L3 confirm referenced files exist? | doc author | have the tool verify that prd: and architecture: frontmatter paths resolve to real files | dangling references are flagged |
| 4 | usability | Can fix mode auto-repair issues? | doc author | run with fix mode and have common issues (missing sections, broken refs) repaired | I don't have to manually fix every structural issue |

### P1 (Important)

None for v1.

### P2 (Nice-to-Have)

None for v1.

## Acceptance Criteria

### Story #1: Template alignment [core]

```
GIVEN a PRD.md exists in docs/{family}/
WHEN  /align-feature-contract runs L1 checks
THEN  it reports PASS if all required template sections exist
  AND it reports FAIL with specific missing section names if any are absent
```

### Story #2: Cross-doc traceability [core]

```
GIVEN ARCHITECTURE.md has frontmatter field prd: PRD.md
WHEN  /align-feature-contract runs L2 checks
THEN  it verifies the prd: path resolves to an existing file
  AND it reports PASS if all cross-doc references are valid
  AND it reports FAIL with specific broken references if any are invalid
```

### Story #3: Reference verification [core]

```
GIVEN a doc triplet references files via frontmatter (prd:, architecture:)
WHEN  /align-feature-contract runs L3 checks
THEN  it confirms each referenced file exists on disk
  AND it reports FAIL with the specific missing file path if any are absent
```

### Story #4: Fix mode [usability]

```
GIVEN a doc triplet has L1 or L2 violations
WHEN  /align-feature-contract runs in fix mode
THEN  missing sections are added from templates and frontmatter refs are corrected
```

## Success Metrics

| Metric | Target | How Measured |
|--------|--------|-------------|
| Template compliance | All families pass L1 checks | /align-feature-contract reports zero L1 failures |
| Traceability coverage | All ARCH and TEST-SPEC docs reference their PRD | L2 checks pass across all families |
| Reference integrity | Zero dangling file references | L3 checks pass across all families |

## Out of Scope

- Content quality assessment (handled by /system-health layer 8)
- Enforcing specific content within sections (only checks section existence)

## Assumptions

- Templates in templates/ define the canonical section list for each doc type
- Doc triplets live at docs/{family}/ with consistent naming (PRD.md, ARCHITECTURE.md, TEST-SPEC.md)
- Frontmatter uses YAML format with standard fields (type, feature, prd, architecture)
