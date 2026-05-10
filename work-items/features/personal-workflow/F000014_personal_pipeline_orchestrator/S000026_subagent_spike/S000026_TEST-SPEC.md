---
type: test-spec
parent: S000026
feature: F000014
title: "Subagent capabilities spike — Test Specification"
version: 1
status: Draft
date: 2026-05-09
author: chjiang
spec: SPEC.md
reviewers: []
---

<!-- Spike-shaped story. Most "tests" here are the probes themselves running
     successfully. Smoke = probe scripts execute without error. E2E = the
     findings.md document captures verdicts the parent design can act on. -->

## Smoke Tests

| # | Tag | AC | Check | What It Validates | Script/Command |
|---|-----|-----|-------|-------------------|----------------|
| S1 | core | AC-1 | `probe-auq.sh` exits 0 and prints a verdict line | Probe ran cleanly and produced a categorical result (yes/no with sub-classification) | `tests/spike/subagent-capabilities/probe-auq.sh` |
| S2 | core | AC-2 | `probe-result.sh` is syntactically valid bash | Script does not bomb on startup; full 5-trial run is operator-driven (15-min budget; requires `claude` CLI) and verified at E2E rather than smoke | `bash -n tests/spike/subagent-capabilities/probe-result.sh` |
| S3 | usability | AC-3 | `findings.md` contains required sections | Findings report has VERDICT lines + Recommended downstream action heading | `grep -q "VERDICT:" tests/spike/subagent-capabilities/findings.md && grep -q "Recommended downstream action" tests/spike/subagent-capabilities/findings.md` |

## E2E Tests

| # | Tag | AC | Scenario | Steps (as a real user would) | Expected Outcome | Rubric |
|---|-----|-----|----------|------------------------------|------------------|--------|
| E1 | core | AC-1, AC-4 | AUQ-bubble verdict actionable | Run `probe-auq.sh`, read its output, classify result. If BUBBLES=no, sub-classification (hang/error/cancel) is present. | Verdict + (if no) sub-classification visible in stdout | If no AUQ bubbled but probe just printed "no" without sub-classification, fail — operator can't pick redesign |
| E2 | core | AC-2 | RESULT-line tally interpretable | Run `probe-result.sh`, read its output. Tally is N/5 with N ∈ {0,1,2,3,4,5}. | Tally line visible; raw outputs (if 5/5 fail) inspected to understand failure mode | If tally is N/5 but raw outputs aren't captured for misses, fail — operator can't pick parser-leniency strategy |
| E3 | usability | AC-3 | Findings report enables F000014 implementer to pick design path without re-running probes | Read `findings.md`. Identify verdict for both legs + recommended downstream action. Confirm the action maps to one of {as-is, pre-collect-AUQs, add-leniency, both}. | One clear recommended action stated; F000014 implementer can pick it up cold | If recommended action is hedged or absent, fail — defeats spike's purpose |

## Coverage Gaps

| Gap | Why Not Tested | Risk Accepted |
|-----|----------------|---------------|
| Probe regression after Claude Code upgrade | Throwaway probes; not maintained | If Claude Code subagent semantics change, F000014 design may need re-spiking. Mitigation: findings.md records version/overlay context. |
| Combined AUQ + RESULT-line probe | Two separate failure modes; isolating diagnosis | Marginal — running them in sequence already gives joint signal |
| Latency / cost of subagent dispatch | Out of spike scope (orchestrator design doesn't gate on this) | Acceptable — separate question from "does the contract work?" |
