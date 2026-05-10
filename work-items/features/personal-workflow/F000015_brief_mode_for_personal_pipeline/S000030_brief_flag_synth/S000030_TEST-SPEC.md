---
type: test-spec
parent: S000030
feature: F000015
title: "--brief flag plumbing + stub synthesis — Test Specification"
version: 1
status: Draft
date: 2026-05-09
author: chjiang
spec: SPEC.md
reviewers: []
---

<!-- Smoke = automated structural checks on SKILL.md / pipeline.md. E2E = manual
     `/personal-pipeline --brief ...` invocation against a known-trivial defect. -->

## Smoke Tests

<!-- Automated regression. Fast, deterministic, runnable from a script or CI. -->

| # | Tag | AC | Check | What It Validates | Script/Command |
|---|-----|-----|-------|-------------------|----------------|
| S1 | core | AC-1 | Usage section documents --brief | SKILL.md Usage section contains `--brief` and `--type {task\|defect}` | `grep -E '\-\-brief.*\-\-type \{task\\\|defect\}' skills/personal-pipeline/SKILL.md` |
| S2 | core | AC-8 | Six error rows present | Error Handling table has rows matching all six prescribed conditions | `grep -c -E '\\\| \-\-brief .* \\\|' skills/personal-pipeline/SKILL.md` returns ≥6 |
| S3 | core | AC-1 | pipeline.md has Step 0a | pipeline.md contains `Step 0a: Brief Mode` heading or label | `grep -E 'Step 0a.*Brief Mode' skills/personal-pipeline/pipeline.md` |
| S4 | core | AC-6 | telemetry mode field referenced | pipeline.md telemetry write block references `mode` field with all 4 values | `grep -E '"mode": *"(manual\|auto\|brief\|brief\+auto)"' skills/personal-pipeline/pipeline.md` |
| S5 | observability | AC-7 | sunset parser defaults mode | pipeline.md sunset-checkpoint section references mode default | `grep -E 'mode.*default.*manual' skills/personal-pipeline/pipeline.md` |

<!-- Tag vocabulary: core, resilience, observability, usability, security, integration -->

## E2E Tests

<!-- Manual end-to-end verification, run after implementing and before /ship. -->

| # | Tag | AC | Scenario | Steps (as a real user would) | Expected Outcome | Rubric |
|---|-----|-----|----------|------------------------------|------------------|--------|
| E1 | core | AC-3 | Happy-path stub synthesis | Run `/personal-pipeline --brief "Fix SIGPIPE race in scripts/test.sh D5 blocks" --type defect`. Inspect `~/.gstack/projects/jcl2018-claude-skills-templates/`. | A new file `chjiang-claude-lucid-sanderson-bcccff-design-{ts}-brief.md` exists with the stub template populated; brief text appears verbatim inside a ` ```text ... ``` ` block | PASS if stub matches template, brief text fenced; FAIL on any structural mismatch |
| E2 | core | AC-2 | Missing --type | Run `/personal-pipeline --brief "Add dark mode toggle"`. | Error message: `Error: --brief requires --type {task\|defect}.` Exit clean. No file written. | PASS if exact message + zero filesystem mutation |
| E3 | core | AC-2 | --brief --type feature | Run `/personal-pipeline --brief "Build the entire OAuth subsystem" --type feature`. | Error message: `Error: --brief is not available for --type feature. Multi-story features deserve full /office-hours.` Exit clean. No file written. | PASS if exact message + zero filesystem mutation |
| E4 | core | AC-5 | Byte-identical when --brief absent | Run a known existing manual-mode invocation (any prior fixture or work-item design path). Diff output and filesystem state against pre-change run. | Zero behavioral change. | PASS if `diff -ruN before/ after/` shows only the expected work-item dir, identical content |
| E5 | resilience | AC-4 | Filename collision suffix | Run `/personal-pipeline --brief "trivial defect" --type defect` twice within the same second (or pre-touch the un-suffixed file). | First run writes un-suffixed filename; second run writes with `-2` suffix. No `-1` written. | PASS if collision suffix is `-2` exactly; FAIL on `-1` or overwrite |

<!-- E2E test skill: none in v1 (manual smoke; brief-mode fixture lives in S000031) -->

## Coverage Gaps

| Gap | Why Not Tested | Risk Accepted |
|-----|----------------|---------------|
| Telemetry parser handling unknown `mode` values (e.g. typo `breif`) | Out of scope for v1; the writer is the only source of `mode` values today | If parser semantics expand later (consumer reads multiple modes), invalid values may silently fall through; revisit |
| Special-character coverage in brief text | S000031 owns; this story produces a manually-smokeable change but does not exhaustively exercise special chars | If special-char insulation regresses, S000031 fixture catches it |
| Concurrent invocation race on filename collision | Out of scope; filesystem-level race is accepted risk in v1 (per parent F000015 design) | Documented; mitigated by collision-suffix rule which retries until unique |
