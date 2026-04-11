---
type: prd
feature: test-align-contract
title: "Test Align Contract — Product Requirements"
version: 1
status: Active
date: 2026-04-10
author: chjiang
---

## Problem Statement

/align-feature-contract enforces doc triplet contracts (template alignment, cross-doc traceability, reference verification), but it has no automated test coverage. Without a test harness, regressions in the enforcement engine go undetected until a real audit fails. The repo owner needs a two-tier test suite that catches structural issues fast (Tier 1 smoke) and validates full behavioral correctness periodically (Tier 2 E2E).

## Mental Model

Two tiers: Tier 1 runs deterministic structural checks (file existence, frontmatter fields, required sections, cross-reference resolution, placeholder detection) on every doc triplet family. Tier 2 invokes /align-feature-contract on each family and verifies it produces expected output. Tier 1 is fast and scriptable. Tier 2 requires AI execution and catches behavioral regressions.

## User Stories

### P0 (Must-Have)

| # | Tag | What it asks | As a... | I want to... | So that... |
|---|-----|-------------|---------|-------------|------------|
| 1 | core | Can I run structural smoke tests on all triplets? | repo owner | run /test-align-contract and get Tier 1 results per family | structural regressions are caught without invoking AI |
| 2 | core | Does Tier 1 check frontmatter fields? | repo owner | have smoke tests verify type, prd, and architecture fields exist | broken cross-references are caught early |
| 3 | core | Does Tier 1 check required sections? | repo owner | have smoke tests verify Problem Statement, User Stories, etc. exist | template compliance is enforced structurally |
| 4 | integration | Can I run E2E tests that invoke /align-feature-contract? | repo owner | run Tier 2 and see per-family results from the real engine | behavioral regressions in the enforcement engine are caught |

### P1 (Important)

None for v1.

### P2 (Nice-to-Have)

None for v1.

## Acceptance Criteria

### Story #1: Smoke tests [core]

```
GIVEN doc triplet families exist under docs/
WHEN  /test-align-contract runs Tier 1
THEN  each family reports PASS or FAIL for 5 structural checks (S1-S5)
  AND a summary table shows all families
```

### Story #2: Frontmatter checks [core]

```
GIVEN a triplet family has PRD.md, ARCHITECTURE.md, TEST-SPEC.md
WHEN  Tier 1 check S2 runs
THEN  PRD must have type: prd
  AND ARCHITECTURE must have type: architecture and prd: field
  AND TEST-SPEC must have type: test-spec and prd: and architecture: fields
```

### Story #3: Section checks [core]

```
GIVEN a triplet family has all three docs
WHEN  Tier 1 check S3 runs
THEN  PRD must have "Problem Statement", "User Stories", "Acceptance Criteria" sections
  AND ARCHITECTURE must have "Overview", "Architecture" sections
  AND TEST-SPEC must have "Test Matrix", "Test Tiers" sections
```

### Story #4: E2E execution [integration]

```
GIVEN a complete triplet family exists
WHEN  Tier 2 runs /align-feature-contract on that family
THEN  it produces template alignment report, traceability summary, and fixability summary
  AND well-formed triplets produce no FAIL-severity findings
```

## Success Metrics

| Metric | Target | How Measured |
|--------|--------|-------------|
| Tier 1 coverage | All doc triplet families scanned | /test-align-contract discovers every docs/{family}/ with 3 files |
| Structural pass rate | 100% of families pass S1-S5 | Tier 1 summary table shows all PASS |
| E2E pass rate | 100% of well-formed families pass Tier 2 | No FAIL-severity findings on clean triplets |

## Out of Scope

- Testing /align-feature-contract's fix mode (only tests detection)
- Performance benchmarking of the enforcement engine
- Cross-repo triplet testing

## Assumptions

- /align-feature-contract is deployed and functional for Tier 2
- Doc triplet families follow the docs/{family}/ convention with PRD.md, ARCHITECTURE.md, TEST-SPEC.md
- Templates define the canonical section list for structural checks
