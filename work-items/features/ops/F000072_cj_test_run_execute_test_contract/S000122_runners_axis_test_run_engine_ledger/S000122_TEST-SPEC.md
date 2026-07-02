---
type: test-spec
parent: S000122
feature: F000072
title: "runners: axis + test-run.sh engine + run ledger + /CJ_test_run wrapper — Test Specification"
version: 1
status: Draft
date: 2026-07-01
author: chang
spec: SPEC.md
reviewers: []
---

<!-- Scope: ENTIRE user story (all five F000072 Approach A components).
     Smoke = automated regression (fixture-repo tests in tests/test-run.test.sh
     wired into scripts/test.sh — NEVER invoking the real test.sh from inside
     the engine under test). E2E = manual user-scenario verification before
     /ship. Soft cap: 5 rows per tier — rows here bundle related assertions to
     stay within it. -->

## Smoke Tests

<!-- Automated regression. AC column maps each row to a SPEC story number. -->

| # | Tag | AC | Check | What It Validates | Script/Command |
|---|-----|-----|-------|-------------------|----------------|
| S1 | core | AC-1, AC-2 | `runners:` grammar + listings | `--validate` accepts well-formed rows and rejects each named violation (duplicate id, bad tier/platform, empty command, unknown covers family, explicit `ci`/`hook` in covers); an axis-less registry validates unchanged; `--list-runners` and `--list-units --with-family` emit the machine-readable forms | `bash tests/test-run.test.sh` |
| S2 | usability | AC-3, AC-4 | Plan + tier gating on fixtures | `--dry-run` prints per-runner plan rows + uncovered-family lines (`ci-only`, hook check, `skipped(no-covering-runner)`) and executes nothing; default run selects only `tier: free`; `--evals`/`--e2e`/`--all` widen selection; unselected rows are `skipped(tier-not-selected)`; a `platform:`-guarded fixture row is `skipped(platform)` on the wrong platform | `bash tests/test-run.test.sh` |
| S3 | observability | AC-5, AC-6 | Ledger fields + evidence-derived aggregate | A failing fixture runner ⇒ aggregate `fail` + exit 1 + verbatim FAIL lines + ledger outcome `fail`; a green run ⇒ `pass`; zero-executed ⇒ `all-skipped` + exit 0 and never rendered `pass`; rc=0 with FIRST line `^SKIP:` ⇒ `skipped(self-gated)` while a mid-output SKIP does not trigger; `.md` + `.json` written with schema: 1, timestamp, HEAD SHA, repo root, flags, and per-runner id/command/tier/rc/outcome/families/unit-count/duration | `bash tests/test-run.test.sh` |
| S4 | resilience | AC-7 | Registry edge paths | Absent registry ⇒ `REGISTRY=absent` + exit 0; invalid registry ⇒ `[test-spec-no-config]` passthrough + exit 1; valid registry with zero `runners:` rows ⇒ `SKIP: no runners declared` + exit 0 with NO report and NO ledger written | `bash tests/test-run.test.sh` |
| S5 | integration | AC-8, AC-10 | Workbench registration + suite wiring | The workbench overlay's `run-test-sh`/`run-eval`/`run-e2e-local` rows validate; new units rows keep Check 24 green; regenerated test catalog keeps Check 26 green; regenerated workflow docs keep Check 27 green; `tests/test-run.test.sh` runs inside `scripts/test.sh` | `bash scripts/validate.sh && bash scripts/test.sh` |

<!-- Tag vocabulary: core, resilience, observability, usability, security, integration.
     AC-11 (CR-safe jq) is exercised implicitly by S1-S4 running under Git Bash
     CI (windows-latest) where the CRLF-emitting jq lives; see Coverage Gaps. -->

## E2E Tests

<!-- Manual end-to-end verification, run after implementing and before /ship.
     AC column maps each row to a SPEC story number. -->

| # | Tag | AC | Scenario | Steps (as a real user would) | Expected Outcome | Rubric |
|---|-----|-----|----------|------------------------------|------------------|--------|
| E1 | usability | AC-3, AC-8 | Honest plan on the workbench | From the repo root run `bash scripts/test-run.sh --dry-run` | Plan lists `run-test-sh` (free, covers validate+test+test-deploy+windows-smoke, will-run), `run-eval` (paid, `skipped(tier-not-selected)`), `run-e2e-local` (local-only, `skipped(tier-not-selected)`); `ci` shown `ci-only (runs on GitHub)`; `hook` shown as the installed check; exits 0 with nothing executed | Every declared runner appears with the correct tier/decision; no command runs |
| E2 | core | AC-4, AC-5, AC-6 | Default free-tier run end to end | Run `bash scripts/test-run.sh` (no flags); open the newest `tests/test-run/reports/<UTC-ts>.md` and `.json` | `scripts/test.sh` executes exactly ONCE; report + ledger written; aggregate matches the suite's real rc (`pass` + exit 0 on a green tree); paid/local-only rows recorded `skipped(tier-not-selected)`; no model invoked | Aggregate mirrors reality; ledger fields complete; a second run writes a NEW timestamped pair |
| E3 | security | AC-4 | Paid/local-only stay behind flags | Compare `bash scripts/test-run.sh --dry-run` vs `--dry-run --evals` vs `--dry-run --e2e` vs `--dry-run --all` | `run-eval` flips to will-run only under `--evals`/`--all`; `run-e2e-local` only under `--e2e`/`--all`; the flagless plan never selects either | Tier law holds exactly; no surprise spend path exists |
| E4 | resilience | AC-7, AC-9 | Consumer-repo honesty via the wrapper | In a scratch git repo, seed a rules-only registry (`bash scripts/test-spec.sh --seed > spec/test-spec.md` equivalent), then invoke `/CJ_test_run`; repeat with no registry at all | Rules-only: Stage-1 pre-step prints verbatim, then `SKIP: no runners declared`, exit 0, no report/ledger files created; registry-absent: named `REGISTRY=absent` SKIP path; wrapper narrates both honestly | Neither path executes anything, fabricates a ledger, or renders green |
| E5 | usability | AC-9 | /CJ_test_run standalone on the workbench | Invoke `/CJ_test_run` in the workbench and follow the narration | Stage-1 pre-step output (four engine calls) precedes execution; report + ledger paths narrated; skill resolves engines via the documented chain; routing phrase "run the tests" reaches the skill | Wrapper adds narration only — engine behavior identical to E2 |

## Coverage Gaps

<!-- What is explicitly NOT tested and why. -->

| Gap | Why Not Tested | Risk Accepted |
|-----|----------------|---------------|
| Real paid-tier eval execution (`run-eval` actually invoking `scripts/eval.sh` against a model) | Hard cost-tier law: tests must never surprise-spend; fixture paid rows prove the gating logic instead | A real `--evals` run could fail for eval-harness reasons the fixtures don't model; first real run is operator-supervised |
| Real local-only e2e execution (`run-e2e-local` driving `scripts/e2e-local.sh` to completion) | Requires gstack + claude login + ~real build runtime; e2e-local.sh has its own suite (`tests/e2e-local.test.sh`) and self-gates | Self-gate integration is proven only via the first-line `^SKIP:` fixture, not the real harness |
| CRLF-jq behavior on a POSIX-only dev machine (AC-11) | The CRLF-emitting jq exists only on Windows builds; exercised by the `windows-latest` Git Bash CI job running the same fixture suite, not locally on macOS | A CR regression could land locally and only surface at CI, not before commit |
| `/CJ_test_audit` consuming the ledger (`suite-green` freshness handshake) | Explicitly out of scope — the audit stays READ-ONLY this story; follow-up feature | Until the follow-up lands, the ledger is citable by humans but not enforced by the audit |
| Per-unit pass/fail attribution within a runner | Rejected as false precision (runner-granularity decision) | A failing unit inside a green-rc runner wrapper would be invisible; mitigated by runners being the repo's real suites whose rc is authoritative |
