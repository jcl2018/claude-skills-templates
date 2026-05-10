---
type: test-spec
parent: S000029
feature: F000015
title: "Phase 0 spike — parser surface + Step 8.5 scan surface enumeration — Test Specification"
version: 1
status: Draft
date: 2026-05-09
author: chjiang
spec: SPEC.md
reviewers: []
---

<!-- Tests for an investigation spike. Smoke = automated structural checks on
     the journal note + TODOS.md. E2E = manual verification that the verdicts
     are usable input for S000030. -->

## Smoke Tests

<!-- Automated regression. Fast, deterministic, runnable from a script or CI. -->

| # | Tag | AC | Check | What It Validates | Script/Command |
|---|-----|-----|-------|-------------------|----------------|
| S1 | observability | AC-3 | Journal entry exists | `S000029_TRACKER.md` Journal section contains a Phase 0 note dated 2026-05-09 or later | `grep -c '^- \[finding\] .*Phase 0' work-items/features/personal-workflow/F000015_brief_mode_for_personal_pipeline/S000029_phase0_spike/S000029_TRACKER.md` |
| S2 | core | AC-1 | Parser-surface verdict present | Journal note contains "parser surface" + an explicit yes/no | `grep -E 'parser surface: (yes|no)' work-items/features/personal-workflow/F000015_brief_mode_for_personal_pipeline/S000029_phase0_spike/S000029_TRACKER.md` |
| S3 | core | AC-2 | Step 8.5 scan-surface verdict present | Journal note contains "placeholders inert" + an explicit yes/no | `grep -E 'placeholders inert: (yes|no)' work-items/features/personal-workflow/F000015_brief_mode_for_personal_pipeline/S000029_phase0_spike/S000029_TRACKER.md` |
| S4 | observability | AC-3 | Action keyword present | Journal note ends with one of `action: extend`, `action: harden`, `action: escalate` | `grep -E 'action: (extend\|harden\|escalate)' work-items/features/personal-workflow/F000015_brief_mode_for_personal_pipeline/S000029_phase0_spike/S000029_TRACKER.md` |
| S5 | usability | AC-5 | Escalation has TODOS.md entry | If action=escalate, TODOS.md has a line referencing F000015 / Approach B | `if grep -q 'action: escalate' .../S000029_TRACKER.md; then grep -q 'F000015.*Approach B' TODOS.md; fi` |

<!-- Tag vocabulary: core, resilience, observability, usability, security, integration -->

## E2E Tests

<!-- Manual end-to-end verification, run after implementing and before /ship. -->

| # | Tag | AC | Scenario | Steps (as a real user would) | Expected Outcome | Rubric |
|---|-----|-----|----------|------------------------------|------------------|--------|
| E1 | core | AC-1 | Parser-surface enumeration is usable for S000030 | Implementer of S000030 reads the Phase 0 journal note; lists every parser field needing the stub | Implementer can decide stub-template content without re-reading scaffold.md from scratch | PASS if implementer says "yes, I have what I need to edit pipeline.md"; FAIL otherwise |
| E2 | core | AC-2 | Step 8.5 scan-surface enumeration is usable for S000030 | Implementer of S000030 reads the Phase 0 journal note; lists every scan pattern that the stub must avoid matching | Implementer can decide placeholder strings without re-reading pipeline.md from scratch | PASS if implementer says "yes, I have what I need to ensure inertness"; FAIL otherwise |
| E3 | resilience | AC-4 | Extension scope is single-file (only if action=extend) | Implementer applies the recommended extension; verifies the diff touches one file | Diff scope matches the spike's recommendation | PASS if diff is single-file (or two files with documented reason); FAIL if scope drifts |

<!-- E2E test skill: none (this is an investigation spike; implementer-driven verification only) -->

## Coverage Gaps

| Gap | Why Not Tested | Risk Accepted |
|-----|----------------|---------------|
| Whether the stub template extension itself satisfies the parser at runtime | S000031 fixture covers this end-to-end; S000029 is a static enumeration only | If extension is mis-scoped, fixture failure surfaces it during S000031 ship phase, not before |
| Whether placeholders are still inert after future Step 8.5 changes | Out of scope; new Step 8.5 patterns added later may regress brief-mode quietly | Accepted; mitigated by S000031 fixture re-running on each pipeline.md change |
