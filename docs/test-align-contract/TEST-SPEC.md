---
type: test-spec
feature: test-align-contract
title: "Test Align Contract — Test Specification"
version: 1
status: Active
date: 2026-04-10
author: chjiang
prd: PRD.md
architecture: ARCHITECTURE.md
---

## Test Matrix

| # | Tag | Test Case | AC | Precondition | Steps | Expected Result | Priority | Type |
|---|-----|-----------|-----|-------------|-------|-----------------|----------|------|
| 1 | core | Tier 1 produces per-family smoke results | AC-1 | Doc triplets exist under docs/ | Run /test-align-contract | Summary table with S1-S5 per family | P0 | E2E |
| 2 | core | S2 validates frontmatter fields | AC-2 | Triplet with proper frontmatter | Run Tier 1 | PRD has type:prd, ARCH has type:architecture + prd:, SPEC has type:test-spec + prd: + architecture: | P0 | E2E |
| 3 | core | S3 validates required sections | AC-3 | Triplet with all template sections | Run Tier 1 | All required sections detected | P0 | E2E |
| 4 | integration | Tier 2 invokes /align-feature-contract | AC-4 | /align-feature-contract deployed | Run Tier 2 | Per-family alignment report produced | P0 | E2E |

## Test Tiers

### Tier 1: Smoke Tests (automated, no live execution)

| # | Tag | Check | What It Validates | Script/Command |
|---|-----|-------|-------------------|---------------|
| S1 | core | SKILL.md exists | Skill is deployed | `[ -f .claude/skills/test-align-contract/SKILL.md ]` |
| S2 | core | Contract exists | Behavioral contract present | `jq '.contracts[] \| select(.skill == "test-align-contract")' skill-contracts.json` |
| S3 | core | Catalog entry exists | Skill registered | `jq '.skills[] \| select(.name == "test-align-contract")' skills-catalog.json` |
| S4 | core | /align-feature-contract available | Dependency met | `[ -f .claude/skills/align-feature-contract/SKILL.md ]` |

### Tier 2: E2E Tests (real end-to-end execution)

| # | Tag | Scenario | Steps (as a real user would) | Expected Outcome | Rubric |
|---|-----|----------|----------------------------|-----------------|--------|
| E1 | core | Full test run | Type `/test-align-contract` in Claude Code session | Tier 1 + Tier 2 results for all families | All complete families pass Tier 1; well-formed families pass Tier 2 |
| E2 | core | Incomplete triplet handling | Add a docs/{family}/ with only PRD.md | Report shows INCOMPLETE, not crash | Graceful handling of partial families |

## Coverage Gaps

| Gap | Why Not Tested | Risk Accepted |
|-----|---------------|---------------|
| Tier 2 with deliberately malformed triplets | Would require creating test fixtures | Low risk: /align-feature-contract handles malformed input gracefully |
| Template section list freshness | S3 checks hardcoded in SKILL.md, not derived from templates | Medium risk: template changes need manual SKILL.md update |
