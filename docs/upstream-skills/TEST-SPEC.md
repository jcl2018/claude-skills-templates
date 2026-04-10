---
type: test-spec
feature: upstream-skills
title: "Upstream Skills — Test Specification"
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
| 1 | core | Every catalog upstream skill has a SKILL.md | AC-1 | skills-catalog.json lists upstream skills | For each skill with source=gstack, check skills/{name}/SKILL.md exists | All files present | P0 | Unit |
| 2 | integration | Catalog version matches deployed VERSION | AC-1 | Deploy has run | Compare skills-catalog.json upstreams.gstack.version with ~/.claude/ state | Versions match | P0 | E2E |
| 3 | integration | Audit check 1.7 detects version mismatch | AC-3 | Catalog version is outdated | Run /project:audit | Check 1.7 reports WARN with version delta | P0 | E2E |

## Test Tiers

### Tier 1: Smoke Tests (automated, no live execution)

| # | Tag | Check | What It Validates | Script/Command |
|---|-----|-------|-------------------|---------------|
| S1 | core | All upstream SKILL.md files exist | Catalog-to-filesystem consistency | `jq -r '.skills[] | select(.source=="gstack") | .name' skills-catalog.json \| while read s; do test -f "skills/$s/SKILL.md"; done` |
| S2 | core | No local edits in skills/ | P2: upstream files are unmodified copies | `git diff --name-only skills/` returns empty |

### Tier 2: E2E Tests (real end-to-end execution)

| # | Tag | Scenario | Steps (as a real user would) | Expected Outcome | Rubric |
|---|-----|----------|----------------------------|-----------------|--------|
| E1 | integration | Full sync cycle | Pull gstack, copy SKILL.md files, update catalog version, deploy | All skills deployed, audit check 1.7 passes | Pass: zero FAIL in room 1 |

## Coverage Gaps

| Gap | Why Not Tested | Risk Accepted |
|-----|---------------|---------------|
| Behavioral verification of each upstream skill | Requires invoking each skill with test fixtures | Broken skill discovered at invocation time |
| Multi-upstream catalog support | Only gstack exists as upstream today | Would need test when second upstream added |
