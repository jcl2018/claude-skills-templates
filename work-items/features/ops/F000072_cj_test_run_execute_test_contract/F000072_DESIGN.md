---
type: design
parent: F000072
title: "/CJ_test_run — execute the test contract and report real pass/fail — Feature Design"
version: 1
status: Approved
date: 2026-07-01
author: chang
reviewers: []
---

<!-- A feature's cross-story design doc. Distilled from the APPROVED
     /office-hours design at
     ~/.gstack/projects/jcl2018-claude-skills-templates/chang-claude-dazzling-shirley-87c62e-design-20260701-161358.md
     (Mode: Builder, Status: APPROVED). Story-scope detail (SPEC/TEST-SPEC)
     lives on the nested user-story. -->

## Problem

`/CJ_test_audit` is a READ-ONLY static audit: it proves declared tests are WIRED
(anchor-grep, coverage linkage, catalog freshness) but never EXECUTES them — a
suite can be cited-green while actually red. Live proof on the operator's
Windows machine: `validate.sh` is red (a jq-CRLF defect) while every
audit-of-record is green.

The operator wants one verb that actually RUNS the repo's tests and reports
honest pass/fail — the "does it pass?" companion to the audit's "is it wired?" —
with the static audit report as a pre-step, working in ANY repo the way the
audit does, and with the test contract itself defining what runs there.

## Shape of the solution

Approach A ("runners-axis core"), one PR, five components carried by a single
atomic user-story:

1. **`runners:` overlay axis** in `spec/test-spec-custom.md` (sibling of
   `units:`/`gates:`/`behaviors:`; OPTIONAL and registry-gated — absence
   changes no existing behavior). Rows: `id` (unique), `command` (non-empty),
   `tier` (closed enum `{free, paid, local-only}`), `covers` (non-empty family
   list or `all` = the RUNNABLE families
   `{validate, test, test-deploy, eval, windows-smoke}` — a set defined
   explicitly by the axis grammar, NOT the contract's existing "test-bearing"
   term; explicit `ci`/`hook` in `covers` REJECTED by `--validate`), optional
   `platform` (`{any, windows, posix}`, default `any`), optional `note`. Plus
   `--list-runners` and `--list-units --with-family` in `test-spec.sh`.
2. **`scripts/test-run.sh` engine**: plan (`--dry-run`), tiered execution
   (free by default; `--evals`/`--e2e`/`--all`), report + `.json` run ledger
   under `tests/test-run/reports/`, closed skip-reason and aggregate enums,
   absent/invalid/no-runners registry paths.
3. **Workbench overlay `runners:` rows**: `run-test-sh` (free),
   `run-eval` (paid), `run-e2e-local` (local-only); `ci`/`hook` stay
   runner-less by design.
4. **`/CJ_test_run` skill wrapper** + shipping paperwork (catalog, routing,
   roster, philosophy, regenerated docs).
5. **Fixture-repo tests** (`tests/test-run.test.sh`) wired into
   `scripts/test.sh` and registered as units rows.

| Concern | User-story | Artifact |
|---------|-----------|----------|
| All five components (runners: axis grammar, test-run.sh engine, workbench rows, /CJ_test_run wrapper + paperwork, fixture tests) | S000122 | [S000122_runners_axis_test_run_engine_ledger/S000122_TRACKER.md](S000122_runners_axis_test_run_engine_ledger/S000122_TRACKER.md) |

## Big decisions

| # | Decision | Why |
|---|----------|-----|
| 1 | Execution lives in a NEW verb `/CJ_test_run`; `/CJ_test_audit` stays READ-ONLY | The audit's contract and posture are untouched (Premise 1); the audit-side ledger freshness check is an explicit follow-up, not this story |
| 2 | The CONTRACT defines what runs: the `runners:` overlay axis (Premise 4, revised twice, operator-driven) | Rejected the expedient hardcoded family→command mapping table (Approach C / cross-model recommendation) — the operator chose the schema field so the contract is the source of truth, not the tool; the general `spec/test-spec.md` seed stays byte-identical to `test-spec.sh --seed` (OVERLAY-only addition, the F000066 `behaviors:` precedent) |
| 3 | Cost tiers are hard UX law: default = `tier: free` only; `paid` (evals) and `local-only` (e2e) run only behind explicit flags (`--evals`, `--e2e`, `--all`) | Never surprise model spend |
| 4 | No false pass: outcomes DERIVED from captured evidence (rc + output); anything unrun is `skipped(<named reason>)` from a closed enum; aggregate `{pass, fail, all-skipped}` with `all-skipped` NEVER rendered `pass` | The `e2e-local.sh` report posture, generalized; a skipped tier is never counted green |
| 5 | Runner-granularity verdicts, not per-unit attribution | Per-unit pass/fail attribution from a 3,245-line monolith's stdout is false precision (adopted from the cross-model cold-read) |
| 6 | `.md` report + machine-readable `.json` run ledger per run | The ledger is the first citable evidence artifact for the contract's `suite-green` rule — the staged handshake toward a deterministic audit-side check |
| 7 | Approach A over B (add audit handshake + `--changed`) | B is XL/High-risk — three sensitive surfaces in one diff; one oversized hop to the same destination |
| 8 | ONE workbench free runner row `run-test-sh` covering validate + test + test-deploy + windows-smoke | Verified: test.sh runs validate.sh, drives test-deploy.sh, and runs windows-smoke.sh on ANY host — a separate windows-smoke row would double-execute on Windows and mis-report `skipped(platform)` on POSIX |
| 9 | CR-safe jq everywhere new: all NEW jq consumption strips CR; JSON string encoding via jq `-R`/`-Rs`, never hand-escaped sh | The lesson of the live jq-CRLF Windows defect (POSIX + Git Bash constraint) |
| 10 | Fixture-repo tests only — NEVER invoke the real `scripts/test.sh` | Recursion/runtime trap (adopted from the cross-model cold-read) |

## Risks & open questions

| Risk / Question | Next check |
|-----------------|-----------|
| BLOCKER prerequisite: the jq-CRLF defect (workbench scripts consume `$(jq -r ...)` without stripping CR) false-halts `workflow-spec.sh --list-orchestrators` → cascades into `test-spec.sh` + `validate.sh` Checks 24/26/27/28, blocking every commit on the operator's Windows machine | Land the fix FIRST via a separate /CJ_goal_defect run (design doc Next Steps step 1) before this feature's build |
| Sensitive surfaces touched: `scripts/test-spec.sh` (parser grammar), `skills-catalog.json`, `spec/test-spec-custom.md`, `rules/skill-routing.md`, `spec/workflow-spec.md` | The sensitive-surface QA discipline applies at implement + QA phases |
| Self-gate detection precision: rc=0 AND the FIRST output line matching `^SKIP:` ⇒ `skipped(self-gated)`; a mid-output "SKIP" must never trigger it (test.sh prints incidental SKIPs) | Fixture test asserts the first-line-only rule |
| Formerly-open items are RESOLVED in the design doc: test-deploy.sh IS driven by test.sh (covered by `run-test-sh`, no own row); windows-smoke.sh likewise; ledger `schema: 1` decided; hook-family check depth decided minimal for v1 (installed pre-commit hook present + grep for the validator reference — full sentinel parsing deferred) | None — recorded here so they don't reopen |

## Definition of done

- [ ] On this workbench: `bash scripts/test-run.sh --dry-run` prints an honest plan; a default run executes `test.sh` once and writes a green report + ledger whose aggregate matches the real rc.
- [ ] On a bare consumer repo (rules-only registry, no runners): honest `SKIP: no runners declared`, exit 0, no execution.
- [ ] On a fixture with a failing runner: aggregate FAIL, exit 1, verbatim FAIL lines in the report, ledger outcome `fail`.
- [ ] `--evals`/`--e2e` execute only when passed; a default run never touches a model.
- [ ] Full `validate.sh` + `scripts/test.sh` green including the new units rows, catalog entry, roster entry, regenerated docs; `/CJ_test_run` invocable standalone.

## Not in scope

- The `/CJ_test_audit` Stage-1 ledger freshness check (the audit-side handshake) — explicit follow-up; the audit stays READ-ONLY in this story (Constraint + Premise 1).
- `--changed` diff-driven impacted-runner selection — deferred with Approach B.
- A hardcoded family→command mapping table (Approach C) — rejected: contradicts the D4 decision; the epic would redo it.
- Editing the GENERAL `spec/test-spec.md` seed — it stays byte-identical to `test-spec.sh --seed`; the axis is OVERLAY-only.
- New CI/CD surface — the nightly-eval and windows CI jobs are unchanged; distribution rides `skills-deploy install` (scripts travel to `_cj-shared/scripts/` by the existing `scripts/*.sh` glob).
- The jq-CRLF defect fix itself — a separate /CJ_goal_defect run (build-order prerequisite, not part of this diff).

## Pointers

- Parent tracker: [F000072_TRACKER.md](F000072_TRACKER.md)
- Roadmap: [F000072_ROADMAP.md](F000072_ROADMAP.md)
- Source /office-hours design: `~/.gstack/projects/jcl2018-claude-skills-templates/chang-claude-dazzling-shirley-87c62e-design-20260701-161358.md` (APPROVED)
- Child story: [S000122_runners_axis_test_run_engine_ledger/S000122_TRACKER.md](S000122_runners_axis_test_run_engine_ledger/S000122_TRACKER.md)
- Precedents: F000066 (the `behaviors:` overlay-axis pattern this follows), F000071 (`e2e-local.sh` — the honest-report posture + gitignored `reports/` + committed `EXAMPLE.md` mirror)
