---
type: test-plan
parent: D000038
title: "jq CRLF output breaks the spec engines on Windows Git Bash — Test Plan"
date: 2026-07-01
author: chang
status: Final
---

<!-- Scope: ONE fix (defect). Cases are regression cases for the specific bug. -->

## Scope

The fix adds a local CRLF-stripping `jq()` wrapper to `scripts/workflow-spec.sh`
(the only standalone spec engine with jq call sites), a T7 CRLF-jq regression
drill to `tests/workflow-spec-render.test.sh`, and updates the drill-enumerating
ok message in `scripts/test.sh`.

## Regression Test Cases

| # | Test Case | Steps | Expected Result | Status |
|---|-----------|-------|-----------------|--------|
| 1 | Engine under a CRLF-emitting jq (T7 drill — the original bug scenario) | `bash tests/workflow-spec-render.test.sh` (T7 PATH-prepends a jq shim appending `\r` to every output line, then runs `--list-orchestrators` + `--validate`) | Suite RESULT: PASS incl. both T7 OK lines: `--list-orchestrators` exits 0 with CR-free output, no `[workflow-spec-no-config]` false-halt; `--validate` exits 0 | Pass |
| 2 | Live engine on this Windows machine (real CRLF jq first in PATH) | `bash scripts/workflow-spec.sh --list-orchestrators` | Prints the 4 CJ_goal_* orchestrator names, rc=0 | Pass |
| 3 | Cascade repaired: downstream engines + validate checks | `bash scripts/test-spec.sh --validate && bash scripts/validate.sh` | test-spec `OK schema_version=1`; validate.sh Checks 24/26/27/28 PASS; `Errors: 0 ... RESULT: PASS`, rc=0 | Pass |

## Verification Steps

- [x] Full `bash scripts/validate.sh` on the affected Windows machine → RESULT: PASS, 0 errors
- [x] Regression suite `bash tests/workflow-spec-render.test.sh` → T1–T7 all OK, RESULT: PASS
- [x] Red-proof: pre-fix engine under the T7 CRLF shim false-halts rc=1 (drill genuinely catches the bug class)
- [x] Insurance suites: `tests/workflow-coverage.test.sh` PASS; `tests/test-spec-render.test.sh` PASS

## Environments Tested

| Environment | Build | Result |
|------------|-------|--------|
| Windows 10 Git Bash (MINGW64), jq-1.7.1 PE32+ (CRLF-emitting) | cj-def-20260701-173850-2847 @ v6.0.101 + fix | Pass |
