---
name: "jq CRLF output re-taints the CJ_goal_* / check-* orchestrator helpers on Windows Git Bash: cj-goal-common.sh, cj-worktree-init.sh, cj-worktree-cleanup.sh, check-version-queue.sh and check-gates-update.sh consume $(jq -r ...) without stripping CR, so a Windows jq build leaves a trailing CR on captured values (breaking `[ -d \"$src\" ]`) and silently degrades the pre-build sync / pr-check phases to skipped (fail-soft hides it) — the orchestrator-helper sibling of D000038's spec-engine class"
type: defect
id: "D000040"
status: active
created: "2026-07-04"
updated: "2026-07-04"
repo: "E:/projects/claude-skills-templates"
branch: "claude/heuristic-albattani-eace9b"
blocked_by: ""
auto_scaffolded: true
promoted_from_draft: .inbox/jq_crlf_class_in_orchestrator_helpers_on_windows
---

## Lifecycle

### Phase 1: Track

1. Reproduction documented (see Reproduction Steps + the bug report)
2. Working branch created: claude/heuristic-albattani-eace9b
3. Required docs scaffolded (D000040 RCA + test-plan)
4. Root cause confirmed by live reproduction (Iron-Law gate passed)

**Gates:**
- [x] Reproduction steps documented
- [x] Working branch created (branch field populated)
- [x] Required docs scaffolded (RCA + test-plan)
- [x] Root cause identified (or best hypothesis logged)

### Phase 2: Implement

1. Fix written directly to source (CR-stripping `jq()` wrapper in the 5 helpers)
2. Regression test added (tests/cj-goal-jq-crlf.test.sh) + wired into scripts/test.sh + spec/test-spec-custom.md
3. Fix + work-item artifacts committed (before QA)
4. RCA updated with the final root cause

**Gates:**
- [x] Fix committed
- [x] RCA doc updated
- [x] Todos section reflects remaining work (no stale items)

### Phase 3: Ship

1. /CJ_qa-work-item — verify the test-plan rows
2. Deterministic doc-regen — doc-sync
3. /ship — open the fix PR
4. /land-and-deploy — merge + verify

**Gates:**
- [ ] /CJ_personal-workflow check — validation passed
- [ ] Test-plan verified (regression scenarios passing)
- [ ] /ship — PR created
- [ ] /land-and-deploy — merged and deployed

## Reproduction Steps

On Windows Git Bash (MINGW64) with a CRLF-emitting jq build (jq 1.7.1), a raw
`$(jq -r ...)` capture in the orchestrator helpers leaves a trailing CR on every
value. Proof: `jq -r '.source // empty' ~/.claude/.skills-templates.json | cat -A`
prints `E:/projects/claude-skills-templates^M$` (the `^M` is the CR). In
`scripts/cj-goal-common.sh` this taints `src`, so `[ -d "$src" ]` is false and the
Fork-2 pre-build sync / pr-check phases silently degrade to `skipped` (fail-soft
hides the breakage). Linux CI cannot see it (Linux jq emits LF).

## Todos

- [ ] Ship via /ship (Gate #2 human diff review)
- [ ] Land via /land-and-deploy
- [ ] Follow-on tasks (out of scope for this defect): bucket (b) drill-harness CRLF/SIGPIPE robustness; bucket (c) deployed-template line-ending re-sync — the two remaining sources of the 32 Windows test.sh failures (TODOS.md P0 row).

## Log

- 2026-07-04: Confirmed the jq-CRLF taint live on the affected Windows box; added the CR-stripping `jq()` wrapper to the 5 orchestrator helpers + a T7-style regression drill. Domain defaulted to 'uncategorized' (same as sibling D000038); relocate if a more specific subdir emerges.

## PRs

<!-- PR links populated at /ship. -->

## Files

<!-- Affected files are listed in the RCA Affected Components table. -->

## Insights

<!-- Root cause + patterns discovered; see the D000040 RCA. -->

## Journal
- 2026-07-04T00:00:00Z [auto-scaffolded] /CJ_goal_defect captured the bug, confirmed the root cause by live reproduction on the affected Windows box, then promoted to D000040. The root cause is the orchestrator-helper instance of the same jq-CRLF class D000038 fixed in the spec engines. Domain defaulted to 'uncategorized'.
