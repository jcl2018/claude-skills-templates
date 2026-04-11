---
type: test-spec
feature: work-pipeline
title: "Work Pipeline — Test Specification"
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
| 1 | core | Scaffold creates triplet files | AC-1 | templates/ has all three templates | Run /work-track to create a new item | docs/{family}/ contains PRD.md, ARCHITECTURE.md, TEST-SPEC.md with populated frontmatter | P0 | E2E |
| 2 | core | Router detects current phase | AC-2 | On a branch with an active work manifest | Run /work | Output shows current phase and suggests correct phase skill | P0 | E2E |
| 3 | integration | Ship validates acceptance criteria | AC-4 | TEST-SPEC has AC blocks; some not met | Run /work-ship | Ship is blocked with list of unmet criteria | P0 | E2E |

## Test Tiers

### Tier 1: Smoke Tests (automated, no live execution)

| # | Tag | Check | What It Validates | Script/Command |
|---|-----|-------|-------------------|---------------|
| S1 | core | All 5 work skills have SKILL.md | Pipeline skills exist | `for s in work work-track work-implement work-review work-ship; do test -f ".claude/skills/$s/SKILL.md"; done` |
| S2 | core | Templates exist for scaffolding | Scaffolding inputs are present | `test -f templates/PRD-TEMPLATE.md && test -f templates/ARCHITECTURE-TEMPLATE.md && test -f templates/TEST-SPEC-TEMPLATE.md` |
| S3 | core | All work skills are in catalog | Catalog completeness | `for s in work work-track work-implement work-review work-ship; do jq -e ".skills[] | select(.name==\"$s\")" skills-catalog.json > /dev/null; done` |

### Tier 2: E2E Tests (real end-to-end execution)

| # | Tag | Scenario | Steps (as a real user would) | Expected Outcome | Rubric |
|---|-----|----------|----------------------------|-----------------|--------|
| E1 | core | Full lifecycle | /work-track create, /work-implement, /work-review, /work-ship | Work item progresses through all 4 phases with journal entries at each | Pass: journal has 4+ entries, PR created |

## Coverage Gaps

| Gap | Why Not Tested | Risk Accepted |
|-----|---------------|---------------|
| Journal entry format consistency | Journal is freeform text, hard to validate structurally | Malformed entries reduce traceability but don't break pipeline |
| Handoff blocks between phases | Requires multi-session testing | Broken handoff discovered when next phase skill runs |
