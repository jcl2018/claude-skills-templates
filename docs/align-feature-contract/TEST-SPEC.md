---
type: test-spec
feature: align-feature-contract
title: "Align Feature Contract — Test Specification"
version: 1
status: Active
date: 2026-04-09
author: chjiang
prd: PRD.md
architecture: ARCHITECTURE.md
---

## Test Matrix

| # | Tag | Test Case | AC | Precondition | Steps | Expected Result | Priority | Type |
|---|-----|-----------|-----|-------------|-------|-----------------|----------|------|
| 1 | core | L1 detects missing section | AC-1 | PRD.md missing "User Stories" section | Run /align-feature-contract on family | L1 FAIL listing "User Stories" as missing | P0 | E2E |
| 2 | core | L2 detects broken cross-ref | AC-2 | ARCHITECTURE.md has prd: pointing to nonexistent file | Run /align-feature-contract | L2 FAIL listing broken prd reference | P0 | E2E |
| 3 | usability | Fix mode adds missing section | AC-4 | PRD.md missing "Out of Scope" section | Run with fix mode | "Out of Scope" section added from template | P0 | E2E |

## Test Tiers

### Tier 1: Smoke Tests (automated, no live execution)

| # | Tag | Check | What It Validates | Script/Command |
|---|-----|-------|-------------------|---------------|
| S1 | core | Skill file exists | Enforcement skill is present | `test -f .claude/skills/align-feature-contract/SKILL.md` |
| S2 | core | Test harness exists | Test infrastructure is present | `test -f .claude/skills/test-align-contract/SKILL.md` |
| S3 | core | All three templates exist | L1 has sources to compare against | `test -f templates/PRD-TEMPLATE.md && test -f templates/ARCHITECTURE-TEMPLATE.md && test -f templates/TEST-SPEC-TEMPLATE.md` |

### Tier 2: E2E Tests (real end-to-end execution)

| # | Tag | Scenario | Steps (as a real user would) | Expected Outcome | Rubric |
|---|-----|----------|----------------------------|-----------------|--------|
| E1 | core | Run on a compliant triplet | Invoke /align-feature-contract on a complete family | All three levels pass | Pass: L1 PASS, L2 PASS, L3 PASS |
| E2 | core | Run on a broken triplet | Create fixture with missing sections and broken refs | L1 and L2 report specific failures | Pass: failures name exact missing sections/refs |

## Coverage Gaps

| Gap | Why Not Tested | Risk Accepted |
|-----|---------------|---------------|
| Fix mode on partially written sections | Ambiguous what "fix" means for incomplete content | Fix mode only adds missing sections, does not rewrite existing ones |
| Template changes breaking existing triplets | Would require regression suite across all families | Mitigated by running /align-feature-contract after template edits |
