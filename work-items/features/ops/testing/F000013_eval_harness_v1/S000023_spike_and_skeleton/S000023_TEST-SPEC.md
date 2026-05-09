---
type: test-spec
parent: S000023
feature: F000013
title: "Spike 0 + runner skeleton + first passing case — Test Specification"
version: 1
status: Draft
date: 2026-05-09
author: chjiang
spec: SPEC.md
reviewers: []
---

<!-- Scope: ENTIRE user story. Smoke + E2E together must cover every SPEC P0
     acceptance criterion. -->

## Smoke Tests

<!-- Automated regression. Fast, deterministic, runnable from a script or CI.
     Once written, you should not need to edit these. Soft cap: 5 rows.
     AC column maps each row to a SPEC acceptance criterion. -->

| # | Tag | AC | Check | What It Validates | Script/Command |
|---|-----|-----|-------|-------------------|----------------|
| S1 | core | AC-2 | `eval.sh` accepts no args, one positional arg (skill), and two positional args (skill + case) | Runner filter wiring works at all three argument cardinalities | `bash scripts/eval.sh && bash scripts/eval.sh personal-workflow && bash scripts/eval.sh personal-workflow check-flags-missing-lifecycle` |
| S2 | core | AC-3, AC-5 | First passing case returns PASS end-to-end | Pipeline executes; fixture seeding + claude invocation + schema validation all wire up | `bash scripts/eval.sh personal-workflow check-flags-missing-lifecycle` |
| S3 | core | AC-4 | Two cases run under `xargs -P 4` produce stable PASS results across 5 consecutive runs | Concurrency is safe; fake-`$HOME` per case isolates state correctly | `for i in 1 2 3 4 5; do bash scripts/eval.sh personal-workflow || exit 1; done` |
| S4 | resilience | AC-6 | A deliberately bad schema (overly strict) causes the runner to FAIL, not silently PASS | ajv-cli fallback validation actually catches schema violations | manual: temporarily tighten expected.schema.json so the model's correct output violates it; verify FAIL |
| S5 | usability | AC-9 (P1) | shellcheck passes on all three new bash files | Bash code is free of common bugs | `shellcheck scripts/eval.sh tests/eval/lib/run-case.sh tests/eval/lib/seed-fixture.sh` |

<!-- Tag vocabulary: core, resilience, observability, usability, security, integration -->

## E2E Tests

<!-- Manual end-to-end verification, run after implementing and before /ship.
     Soft cap: 5 rows. Each row should be one user-visible scenario,
     not one branch in the code. AC column maps each row to a SPEC
     acceptance criterion. -->

| # | Tag | AC | Scenario | Steps (as a real user would) | Expected Outcome | Rubric |
|---|-----|-----|----------|------------------------------|------------------|--------|
| E1 | core | AC-1 | Maintainer runs Spike 0, records findings | 1. Run `claude --bare -p "/personal-workflow check ./" --plugin-dir ./skills --print --output-format json --no-session-persistence` against a known-valid fixture. 2. Observe whether skill is invoked. 3. Repeat with `--json-schema "$(cat schema.json)"` testing both inline and `@file`. 4. Repeat with deliberately-bad case to observe schema enforcement. | `tests/eval/README.md` has a "Spike 0 findings" section; runner code in `lib/run-case.sh` matches the chosen paths. | Pass: README documents all 3 spike outcomes AND lib/run-case.sh's `--plugin-dir` / `--json-schema` / fallback usage matches them. Fail: any finding undocumented or runner contradicts findings. |
| E2 | core | AC-3, AC-5, AC-7 | New contributor reads README and writes a second test case | 1. Read `tests/eval/README.md`. 2. Author a new case directory (any plausible new test, e.g., `check-passing-feature`). 3. Run `bash scripts/eval.sh personal-workflow check-passing-feature`. | New case runs correctly without contributor needing to read source code or ask the maintainer. | Pass: contributor authors a working case from README alone. Fail: contributor needs to read run-case.sh source. |
| E3 | observability | AC-8 (P1) | Maintainer runs full eval suite locally and reads summary | 1. Run `bash scripts/eval.sh`. 2. Read final summary line. | Summary line shows `PASS: N FAIL: M`; failed cases listed by name on stderr. | Pass: maintainer can identify pass count + which cases failed without grepping. Fail: requires manual log inspection. |

## Coverage Gaps

<!-- What is explicitly NOT tested and why. Honesty beats false confidence. -->

| Gap | Why Not Tested | Risk Accepted |
|-----|----------------|---------------|
| Cost ceiling (`--max-budget-usd 0.15` enforcement) | Not testable in S000023 — needs actual API calls and real model behavior at the ceiling | If a case routinely exceeds $0.15, S000025's first CI run will surface it; V1 success criteria validates empirically |
| `--json-schema` warn-only handling without ajv-cli installed | If S0.3 resolves to warn-only AND ajv-cli isn't available (npm offline, etc.), the harness can't reliably FAIL on schema mismatch | npx pre-warm in eval.sh tries `--prefer-offline` first; offline-CI fallback is V2 concern |
| Skill resolution behavior under `--plugin-dir` for skills with cross-skill dependencies (e.g., scaffold-work-item depends on personal-workflow) | V1 only tests personal-workflow + system-health which don't have cross-skill runtime deps | Cross-skill cases are V2 (scaffold/implement/qa cases) — solve when needed |
