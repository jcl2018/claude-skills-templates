---
type: test-spec
parent: S000019
feature: F000010
title: "qa-work-item skill — Test Specification"
version: 1
status: Draft
date: 2026-05-08
author: chjiang
spec: SPEC.md
reviewers: []
---

<!-- v1 test plan: manual fixture-based testing per Step 0A choice. The QA
     engineer subagent pattern is novel; the fixture is a small TEST-SPEC +
     known-buggy implementation, expected findings include the planted bug. -->

## Smoke Tests

| # | Tag | AC | Check | What It Validates | Script/Command |
|---|-----|-----|-------|-------------------|----------------|
| S1 | core | AC-1 | Skill exists in catalog and has valid frontmatter | Catalog wiring correct | `./scripts/validate.sh` |
| S2 | core | AC-1 | Smoke test row execution: each row's Script/Command runs and exit code captured | Smoke phase works | manual: scaffold a fixture user-story with `echo green` and `false` smoke commands; verify both run and one exits non-zero |
| S3 | resilience | AC-6 | Smoke red short-circuits before E2E | Failure short-circuit works | manual: run skill on fixture where S2 fails; verify subagent NOT invoked |
| S4 | resilience | AC-7 | Idempotency: re-run on already-green user-story is NO-OP | Idempotent contract holds | manual: run skill twice; second run prints "already QA'd green" |
| S5 | resilience | AC-8 | Boundary refuses on Phase 2 not met | Drift detection at entry | manual: uncheck a Phase 2 gate, run skill, observe refusal |

## E2E Tests

| # | Tag | AC | Scenario | Steps (as a real user would) | Expected Outcome | Rubric |
|---|-----|-----|----------|------------------------------|------------------|--------|
| E1 | core | AC-2, AC-4 | QA engineer subagent finds a planted bug | 1. Author fixture: small implementation with planted off-by-one. 2. Author TEST-SPEC asserting correct behavior. 3. Run `/qa-work-item <fixture-dir>`. 4. Verify subagent reports the bug as red. | Subagent finds the planted bug; tracker has red finding entry; AUQ fires | PASS if subagent identifies the bug correctly with a useful 1-line description; FAIL on missed bug or false positive |
| E2 | core | AC-3 | Subagent return is short (Premise 1) | 1. Run any successful E2E run. 2. Inspect the subagent's response in the parent skill's context. | Subagent's response is ≤ 200 tokens (1-2 sentences + file pointers) | PASS if response is short; FAIL if subagent returns wall-of-text findings |
| E3 | core | AC-5 | Phase 2 gate transitions on green | 1. Author fixture with passing implementation. 2. Run skill. 3. Inspect tracker. | `[ ] Acceptance criteria met` and `[ ] Smoke tests pass` checked off | PASS if gates transition; FAIL on stale or incorrect gate state |
| E4 | resilience | AC-9 | Subagent timeout | 1. Author fixture where subagent prompt induces a long-running task (e.g., "verify all 100 fictional criteria one by one"). 2. Run skill with confirmed 5-min cap. 3. Verify timeout. | Skill writes timeout entry; AUQ asks re-run/skip/abort | PASS if timeout fires at 5min; FAIL on hang or different cap |
| E5 | usability | AC-10 | Silent green path | 1. Run skill on green fixture. 2. Verify NO AskUserQuestion fires; skill exits silently. | No AUQ; only completion message | PASS if no AUQ; FAIL if AUQ fires on green |
| E6 | performance | AC-11 | Prompt cache hit on second run | 1. Run skill on fixture. 2. Re-run on same fixture (different work-item). 3. Inspect token counts in Claude Code analytics. | Second run shows cache hit on stable preamble portion | PASS if cache hit observable; FAIL on no caching effect |

## Coverage Gaps

| Gap | Why Not Tested | Risk Accepted |
|-----|----------------|---------------|
| Subagent non-determinism — same TEST-SPEC produces different findings | Inherent LLM behavior; goal is "subagent finds the planted bug consistently" not "exactly N findings every time" | Medium: fixture targets should be unambiguous |
| Subagent prompt injection from TEST-SPEC | Personal-use workbench; low-priority threat model | Low: re-evaluate if scaling to multi-user consumers |
| Subagent reading sensitive files outside work-item dir | Expected; subagent needs to read implementation. Documented behavior, not a vulnerability | Low: trust boundary is the user's local repo |
| Adversarial QA subagent (P2 AC-15) | Deferred to v2 | Low: feature gap, not a quality risk |
| TEST-SPEC with empty Smoke / E2E tables | SPEC says "skip smoke, log INFO; proceed to E2E"; manual verification | Low: edge case |
| Subagent calling other Agent tool calls (recursion) | Anti-pattern; subagent should not spawn its own subagents | Medium: SKILL.md should explicitly forbid in prompt |
| Concurrency: two simultaneous QA runs on same user-story | Personal use, single user, single machine | Low: shouldn't occur |
