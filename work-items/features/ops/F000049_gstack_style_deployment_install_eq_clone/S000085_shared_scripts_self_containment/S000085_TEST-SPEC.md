---
type: test-spec
parent: S000085
feature: F000049
title: "Shared scripts travel with the install (runtime de-coupling foundation) — Test Specification"
version: 1
status: Draft
date: 2026-06-05
author: chjiang
spec: SPEC.md
reviewers: []
---

## Smoke Tests

| # | Tag | AC | Check | What It Validates | Script/Command |
|---|-----|-----|-------|-------------------|----------------|
| S1 | core | AC-1 | The shared `scripts/*.sh` set (+ `skills-update-check`) present at `_cj-shared/scripts/` after a hermetic `skills-deploy install` | install deposits every shared script | `scripts/test.sh` (S000085 block: deposit + manifest assertions) |
| S2 | core | AC-2 | Each of the 4 orchestrator-family skill preambles tries repo-local → deployed (`_cj-shared`) → `.source` in order | the 3-tier resolution chain is wired | `scripts/test.sh` (S000085 block: no-source-clone resolution assertion) |
| S3 | core | AC-4 | `skills-catalog.json` portability for the 4 orchestrator-family skills reads `local-only`; the audit agrees (`FINDINGS=0`) | the catalog re-tier landed | `scripts/test.sh` (S000085 block: tier + audit assertions) |
| S4 | integration | AC-5 | `validate.sh` + `scripts/test.sh` both exit 0 under the new layout | the change is non-breaking | `./scripts/validate.sh && ./scripts/test.sh` |
| S5 | resilience | AC-3 | A skill resolves a shared script with `.source` absent (consumer-repo simulation, D000030/D000032 pattern) | no-source-clone resolution works | `scripts/test.sh` (S000085 block: 3-tier resolves from `_cj-shared` with no source clone) |

## E2E Tests

| # | Tag | AC | Scenario | Steps (as a real user would) | Expected Outcome | Rubric |
|---|-----|-----|----------|------------------------------|------------------|--------|
| E1 | resilience | AC-3 | Run a shared-script-dependent skill path on a simulated fresh machine | (1) Install the CJ_ family; (2) relocate/remove `.source` so it is unreachable; (3) from a repo with NO `scripts/` of its own, invoke a skill path that needs a shared script | The skill resolves the script from the deployed shared home and completes; no `.source`-missing error is surfaced | PASS if the path completes using the deployed script (tier 2), not `.source` (tier 3); FAIL on any `.source`-missing halt |

## Coverage Gaps

| Gap | Why Not Tested | Risk Accepted |
|-----|----------------|---------------|
| The install==clone flip (S2) and the `.source` removal (S4) | Out of scope for S1 — the `.source` fallback is deliberately retained here | S1 alone does not deliver the gstack end-state; tiers read `local-only`, not `standalone` |
| Windows/Git-Bash copy-mode of the deployed shared scripts | Deferred to the S5 parity story | A Git-Bash consumer may see different deploy behavior until S5; S1 keeps POSIX + LF + `date_to_epoch` idioms to limit drift |
| Claude Code skill discovery from a bundle (O1) | Not touched by S1 — no layout change | None for S1; this blocks S2, where it is resolved |
