---
type: test-plan
parent: D000043
title: "skills-deploy doctor misses CRLF line-ending drift — Test Plan"
date: 2026-07-05
author: chang
status: Final
---

<!-- Scope: ONE fix (defect). Cases are regression cases for the specific bug. -->

## Scope

The fix adds an independent CR probe to `skills-deploy` `do_doctor`'s template
health loop (flags a deployed template with CRLF regardless of the checksum), plus
a regression case (`test-deploy.sh` Test 8c). It closes bucket (c) of the Windows
`test.sh` P0; the operational drift on this machine was cleared by renormalizing +
re-installing templates as LF.

## Regression Test Cases

| # | Test Case | Steps | Expected Result | Status |
|---|-----------|-------|-----------------|--------|
| 1 | Doctor flags a CRLF-drifted deployed template (Test 8c) | `bash scripts/test-deploy.sh` (Test 8c: install → `sed 's/$/\r/'` one deployed template → `skills-deploy doctor`) | Test 8c OK: doctor emits a `CRLF line endings` WARN for the drifted template | Pass |
| 2 | No false positive on a clean LF install | Fixture install (LF) → `skills-deploy doctor` | No `CRLF line endings` WARN | Pass |
| 3 | Bucket (c) cleared on this machine (D000012) | `skills-deploy install --overwrite` from an LF checkout, then byte-`cmp` source vs `~/.claude/templates/*` | 0 drift; doctor reports 0 CRLF warnings | Pass |
| 4 | Bucket (b) already resolved (no drill-harness failures) | `bash scripts/test.sh` reproduction | All Check 17/19/24-29 / S000094 / S000096 / F000060 drill-harness guards pass; the only fails were the pre-clear template cmp (bucket c) | Pass |

## Verification Steps

- [x] `shellcheck scripts/skills-deploy scripts/test-deploy.sh` → rc=0 (clean)
- [x] Test 8c in isolation: doctor WARNs on a CRLF-drifted template; silent on a clean LF install
- [x] Live: renormalized + re-installed → deployed templates all LF, doctor 0 CRLF warnings, D000012 drift 0
- [x] Full `bash scripts/test.sh` reproduction confirmed bucket (b) resolved (0 drill-harness failures)
- [ ] Full `bash scripts/validate.sh` → RESULT: PASS (Linux CI is the authoritative gate)

## Environments Tested

| Environment | Build | Result |
|------------|-------|--------|
| Windows 10 Git Bash (MINGW64), core.autocrlf=true | claude/heuristic-albattani-eace9b @ v6.0.119 + fix | Pass |

## Out of Scope

The Windows P0's other buckets are already done and are NOT re-touched here:
bucket (a) — the jq-CRLF orchestrator-helper sweep — shipped as D000040 / PR #328
(v6.0.118); bucket (b) — drill-harness SIGPIPE/CRLF robustness — was resolved by
F000081's targeted-engine rework + D000040's `_VALIDATE_OUT` here-string fix.
