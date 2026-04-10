---
type: architecture
feature: test-align-contract
title: "Test Align Contract — Architecture"
version: 1
status: Active
date: 2026-04-10
author: chjiang
prd: PRD.md
---

## Overview

The test harness discovers all doc triplet families under docs/ and runs two test tiers against them. Tier 1 is a deterministic bash-driven scan (frontmatter, sections, cross-references, placeholders). Tier 2 invokes /align-feature-contract as an E2E test. Both tiers produce a unified summary table.

## Architecture

```
/test-align-contract (entry point — .claude/skills/test-align-contract/SKILL.md)
  |
  +---> Discovery: scan docs/*/ for complete triplets (PRD + ARCH + TEST-SPEC)
  |
  +---> Tier 1: Smoke Tests (deterministic, no AI)
  |       +-- S1: Frontmatter exists (YAML between --- delimiters)
  |       +-- S2: Required fields (type, prd, architecture per doc type)
  |       +-- S3: Required sections (Problem Statement, User Stories, etc.)
  |       +-- S4: Cross-references resolve (prd: and architecture: point to files)
  |       +-- S5: No placeholder text ({placeholder} patterns)
  |
  +---> Tier 2: E2E Tests (requires AI execution)
  |       +-- Invoke /align-feature-contract per family
  |       +-- Verify: template alignment report produced
  |       +-- Verify: traceability summary produced
  |       +-- Verify: no FAIL-severity on well-formed triplets
  |
  +---> Unified report (Tier 1 table + Tier 2 results)
```

### Components Affected

| Component | Path | Change Type | Description |
|-----------|------|------------|-------------|
| Test harness skill | .claude/skills/test-align-contract/SKILL.md | Core | Entry point, orchestrates both tiers |
| Doc triplet families | docs/{family}/ | Test target | Scanned and tested by the harness |
| /align-feature-contract | .claude/skills/align-feature-contract/SKILL.md | Dependency | Invoked by Tier 2 for E2E testing |

### Data Flow

1. Discovery scans docs/*/ and classifies each directory as TRIPLET or INCOMPLETE
2. Tier 1 runs 5 checks per complete triplet, producing a PASS/FAIL table
3. Tier 2 invokes /align-feature-contract per family and captures output
4. Results from both tiers are combined into a unified report

## Dependencies

| Dependency | Type | Status | Notes |
|-----------|------|--------|-------|
| /align-feature-contract | Skill (P3) | Available | Tier 2 delegation target |
| Doc triplet families | Content | Available | Test targets under docs/ |
| Templates | Reference | Available | Define expected sections for S3 checks |

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| New triplet family added but not discovered | Low | Low | Discovery uses glob, catches all docs/{family}/ dirs |
| Template section list changes | Low | Medium | S3 checks are hardcoded; update when templates change |
| /align-feature-contract output format changes | Low | Medium | Tier 2 checks for presence of key sections, not exact format |

## Design Decisions

| Decision | Chosen | Rejected Alternative | Why |
|----------|--------|---------------------|-----|
| Two-tier approach | Smoke + E2E | E2E only | Tier 1 is fast and deterministic, catches 80% of issues without AI |
| Glob-based discovery | Scan docs/*/ | Hardcoded family list | Auto-discovers new families, no maintenance |
| Unified report | Combined Tier 1 + Tier 2 table | Separate outputs | Single view of all test results |
