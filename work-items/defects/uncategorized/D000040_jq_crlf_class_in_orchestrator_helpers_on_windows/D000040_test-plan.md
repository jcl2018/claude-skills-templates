---
type: test-plan
parent: D000040
title: "jq CRLF output re-taints the orchestrator helpers on Windows Git Bash — Test Plan"
date: 2026-07-04
author: chang
status: Final
---

<!-- Scope: ONE fix (defect). Cases are regression cases for the specific bug. -->

## Scope

The fix adds the pipefail-independent CR-stripping `jq()` wrapper
(`jq() { command jq "$@" | tr -d '\r'; return "${PIPESTATUS[0]}"; }`) to the five
`CJ_goal_*` / `check-*` orchestrator helpers (cj-goal-common.sh, cj-worktree-init.sh,
cj-worktree-cleanup.sh, check-version-queue.sh, check-gates-update.sh), plus a new
regression drill `tests/cj-goal-jq-crlf.test.sh` wired into `scripts/test.sh` +
`spec/test-spec-custom.md`, and the regenerated test catalog.

## Regression Test Cases

| # | Test Case | Steps | Expected Result | Status |
|---|-----------|-------|-----------------|--------|
| 1 | The regression drill (structural + CRLF-shim mechanism + worktree e2e) | `bash tests/cj-goal-jq-crlf.test.sh` | RESULT: PASS — T1 (x5) each helper defines the CR-stripping `jq()` wrapper; T2 wrapper strips CR + preserves non-zero jq exit status with pipefail OFF under a CRLF-emitting jq shim; T3 `cj-goal-common.sh --phase worktree --dry-run` under the shim emits non-empty CR-free output | Pass |
| 2 | Proven-taint scenario on this Windows box (real CRLF jq) | `src=$(jq -r '.source // empty' ~/.claude/.skills-templates.json)` inside cj-goal-common's wrapper, then `[ -d "$src" ]` | `src` has no trailing CR; `[ -d "$src" ]` is true (the sync/pr-check phases no longer silently skip) | Pass |
| 3 | No regression in the existing helper suites | `bash tests/cj-goal-common-sync.test.sh; bash tests/cj-goal-common-recap.test.sh; bash tests/cj-worktree-init.test.sh; bash tests/cj-worktree-cleanup.test.sh` | All four suites PASS (the added wrapper is behavior-preserving) | Pass |
| 4 | Contract + catalog stay green | `bash scripts/test-spec.sh --check-coverage && bash scripts/test-spec.sh --render-docs --check` | `OK coverage ... findings=0` (Check 24, new units row satisfied) and `OK ... in sync ... findings=0` (Check 26) | Pass |

## Verification Steps

- [x] `bash tests/cj-goal-jq-crlf.test.sh` → RESULT: PASS (5 structural + 2 mechanism + 1 e2e)
- [x] shellcheck on all 5 modified helpers + the new test → rc=0 (clean)
- [x] Live proof: wrapper strips CR (`cat -A` shows no `^M`) and preserves jq exit status (`jq -e` rc=1/0) with pipefail OFF
- [x] Existing helper suites (cj-goal-common-sync/-recap, cj-worktree-init/-cleanup) all PASS
- [x] Check 24 coverage `findings=0`; Check 26/27 render `--check` `findings=0`
- [ ] Full `bash scripts/validate.sh` → RESULT: PASS (running; Linux CI is the authoritative gate)

## Environments Tested

| Environment | Build | Result |
|------------|-------|--------|
| Windows 10 Git Bash (MINGW64), jq-1.7.1 (CRLF-emitting) | claude/heuristic-albattani-eace9b @ v6.0.113 + fix | Pass |

## Out of Scope (follow-on tasks — TODOS.md P0 row)

The visible 32 Windows `test.sh` failures come mostly from two OTHER buckets, each
a separate follow-on task, NOT fixed here:

- **(b)** drill-harness scratch-fixture checks failing on Windows (CRLF / SIGPIPE
  `Aborted` on `grep -q` pipes).
- **(c)** 11 `deployed template differs from workbench` failures — `~/.claude/templates/*`
  line-ending drift, cleared by re-running `skills-deploy install` from a clean LF checkout.

This defect fixes bucket (a): the hidden orchestrator-helper degradation + a
regression guard so the class cannot creep back into these five helpers.
