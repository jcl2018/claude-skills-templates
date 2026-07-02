---
type: roadmap
parent: F000072
title: "/CJ_test_run — execute the test contract and report real pass/fail — Roadmap"
date: 2026-07-01
author: chang
status: Draft
---

<!-- A feature's roll-up roadmap. Captures scope/non-goals (the feature's
     identity), decomposition (which user-stories carry the work), and delivery
     timeline (when each piece ships). -->

## Scope

Give the workbench (and any adopting repo) one verb that actually RUNS the
declared test suite and reports honest pass/fail: an optional `runners:` axis in
the `spec/test-spec-custom.md` overlay declares HOW to run the repo's tests
(command + cost tier + covered families), a deterministic `scripts/test-run.sh`
engine plans (`--dry-run`) and executes them tier-by-tier (free by default;
paid/local-only behind explicit flags), and every run writes a human `.md`
report plus a machine-readable `.json` run ledger whose aggregate verdict is
derived from captured evidence — the "does it pass?" companion to
`/CJ_test_audit`'s "is it wired?". A thin `/CJ_test_run` skill wrapper fronts
the engine with the deterministic Stage-1 audit subset as a pre-step.

## Non-Goals

- `/CJ_test_audit` Stage-1 ledger freshness check — the audit stays READ-ONLY in this feature; the handshake is an explicit follow-up.
- `--changed` diff-driven impacted-runner selection — deferred with rejected Approach B (three sensitive surfaces in one diff).
- Hardcoded family→command mapping table — rejected Approach C; contradicts the operator's decision that the CONTRACT defines what runs.
- Editing the GENERAL `spec/test-spec.md` seed — the `runners:` axis is OVERLAY-only; the seed stays byte-identical to `test-spec.sh --seed`.
- New CI/CD surface — nightly-eval and windows CI jobs unchanged.
- The jq-CRLF defect fix — a prerequisite landed via a separate /CJ_goal_defect run, not part of this feature's diff.

## Success Criteria

- [ ] On this workbench: `bash scripts/test-run.sh --dry-run` prints an honest plan; a default run executes `test.sh` once and writes a green report + ledger whose aggregate matches the real rc.
- [ ] On a bare consumer repo (rules-only registry, no runners): honest `SKIP: no runners declared`, exit 0, no execution.
- [ ] On a fixture with a failing runner: aggregate FAIL, exit 1, verbatim FAIL lines in the report, ledger outcome `fail`.
- [ ] `--evals`/`--e2e` execute only when passed; a default run never touches a model.
- [ ] Full `validate.sh` + `scripts/test.sh` green including the new units rows, catalog entry, roster entry, regenerated docs; `/CJ_test_run` invocable standalone.

## Decomposition

<!-- Status values: Open, In Progress, Closed. -->

| User-Story | Title | Status |
|-----------|-------|--------|
| [S000122](S000122_runners_axis_test_run_engine_ledger/S000122_TRACKER.md) | runners: axis + test-run.sh engine + run ledger + /CJ_test_run wrapper | Open |

## Delivery Timeline

<!-- Blocked By = milestone number(s) that must complete first, or "—" if none. -->

| # | Milestone | Target Date | Status | Owner | Notes | Blocked By |
|---|-----------|-------------|--------|-------|-------|------------|
| 1 | Prerequisite: jq-CRLF defect fix landed (separate /CJ_goal_defect run) | — | Not Started | chang | Red validate.sh on Windows blocks every commit until this lands | — |
| 2 | `runners:` grammar + `--validate` rules + `--list-runners` + `--list-units --with-family` in `test-spec.sh`, with parser fixtures | — | Not Started | chang | Design build-order step 2 | #1 |
| 3 | `test-run.sh --dry-run` (the plan) honest on this repo AND a bare fixture repo | — | Not Started | chang | Design build-order step 3 | #2 |
| 4 | Execution + report + ledger (tiers, closed enums, absent/invalid/no-runners paths) | — | Not Started | chang | Design build-order step 4 | #3 |
| 5 | Workbench overlay rows + `/CJ_test_run` wrapper + paperwork (catalog, routing, roster, philosophy, units rows, regenerated docs) | — | Not Started | chang | Design build-order step 5 — Ship S000122 | #4 |
| 6 | End-to-end pipeline run (QA + doc-sync + audits + PR) | — | Not Started | chang | Feature-level E2E through /CJ_goal_feature tail | #5 |

### Delivery History

<!-- Append-only. PR links, merge dates, version bumps after ship. -->

- 2026-07-01: Scaffolded from the approved /office-hours design (chang-claude-dazzling-shirley-87c62e-design-20260701-161358.md).

## Dependency Graph

```
#1 jq-CRLF defect fix (separate defect run)
   --> #2 runners: grammar + --list-runners + --list-units --with-family
          --> #3 test-run.sh --dry-run plan
                 --> #4 execution + report + ledger
                        --> #5 workbench rows + /CJ_test_run wrapper + paperwork
                               --> #6 end-to-end pipeline run
```

## Open Questions

<!-- Questions still being decided. -->

| Question | Next check |
|----------|-----------|
| None blocking — formerly-open items (test-deploy/windows-smoke coverage by `run-test-sh`, ledger `schema: 1`, minimal v1 hook-family check) are resolved in the design doc | — |
