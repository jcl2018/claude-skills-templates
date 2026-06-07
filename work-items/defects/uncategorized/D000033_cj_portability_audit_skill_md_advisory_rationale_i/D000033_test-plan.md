---
type: test-plan
parent: D000033
title: "CJ_portability-audit SKILL.md stale advisory rationale — Test Plan"
date: 2026-06-06
author: CJ_goal_defect
status: Draft
---

<!-- Doc-accuracy defect: regression cases are static-lint assertions, not a
     runtime repro. -->

## Scope

Prose-only fix to `skills/CJ_portability-audit/SKILL.md` (Overview advisory
rationale) and `skills/CJ_portability-audit/USAGE.md` (Surface-2/3 + `last-updated`).
No code or behavior change.

## Regression Test Cases

| # | Test Case | Steps | Expected Result | Status |
|---|-----------|-------|-----------------|--------|
| 1 | Stale phrase removed | `grep -n "HAS real declared-vs-actual" skills/CJ_portability-audit/SKILL.md` | no match | Pass |
| 2 | Catalog-clean claim is accurate | `bash scripts/cj-portability-audit.sh` | `FINDINGS=0`, `SKILLS_AUDITED=12` | Pass |
| 3 | USAGE-drift gate clean (Check 14) | `bash scripts/validate.sh` | Check 14 PASS for CJ_portability-audit; 0 errors | Pass |
| 4 | Portability advisory posture intact (Check 18) | `bash scripts/validate.sh` | Check 18 PASS (advisory; exit 0) | Pass |

## Verification Steps

- [x] `scripts/validate.sh` → Errors: 0, Warnings: 0 (Check 14 + Check 18 pass)
- [x] `scripts/cj-portability-audit.sh` → `FINDINGS=0`
- [x] Stale phrase confirmed gone from SKILL.md
- [x] USAGE.md `last-updated` bumped (second-resolution) to clear Check 14 drift

## Environments Tested

| Environment | Build | Result |
|------------|-------|--------|
| macOS / POSIX shell | cj-def branch @ v6.0.50 base | Pass |
