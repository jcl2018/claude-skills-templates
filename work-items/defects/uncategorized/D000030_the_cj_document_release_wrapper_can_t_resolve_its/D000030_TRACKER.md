---
name: "/CJ_document-release can't resolve its config helper outside the workbench repo"
type: defect
id: "D000030"
status: active
created: "2026-06-04"
updated: "2026-06-04"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "cj-def-20260604-225342-6085"
blocked_by: ""
auto_scaffolded: true
promoted_from_draft: .inbox/the_cj_document_release_wrapper_can_t_resolve_its
---

## Lifecycle

### Phase 1: Track

1. Document reproduction steps in the Log section
2. Create working branch: `cj-def-20260604-225342-6085`
3. Scaffold required docs:
   - `RCA.md` (root cause analysis)
   - `test-plan.md` (regression test plan)
4. Run `/investigate` to diagnose root cause
5. Log initial symptoms and hypotheses

**Gates:**
- [x] Reproduction steps documented
- [x] Working branch created (`branch` field populated)
- [x] Required docs scaffolded (RCA + test-plan)
- [x] Root cause identified (or best hypothesis logged)

### Phase 2: Implement

1. Implement fix based on root cause analysis
2. Write regression test covering the defect scenario
3. Commit fix and test together
4. Update RCA doc with final root cause

**Gates:**
- [x] Fix committed
- [x] RCA doc updated
- [x] Todos section reflects remaining work (no stale items)

### Phase 3: Ship

1. Run `/CJ_personal-workflow check` — verify no regressions
2. Verify test-plan: regression test scenarios passing
3. Run `/ship` — creates fix PR (includes pre-landing code review)
4. Run `/land-and-deploy` — merges and verifies fix

**Gates:**
- [ ] `/CJ_personal-workflow check` — validation passed
- [ ] Test-plan verified (regression scenarios passing)
- [ ] `/ship` — PR created
- [ ] `/land-and-deploy` — merged and deployed

## Reproduction Steps

1. Adopt `/CJ_document-release` in a consumer repo: scaffold a valid
   `cj-document-release.json` at its root (the helper
   `scripts/cj-document-release-config.sh` lives only in the workbench).
2. From that repo, invoke `/CJ_document-release` (or any `cj_goal_*` run that
   reaches Step 5.5 doc-sync).
3. **Observe:** Step 0.5 runs `bash scripts/cj-document-release-config.sh
   --validate`; the bare relative path is absent in cwd, bash exits 127, and the
   wrapper HALTs with a spurious `[doc-sync-no-config]` despite a valid config.

**Environment:** macOS (workbench-only), `/CJ_document-release` v0.1.0; helper
installed only under the workbench clone resolved by `.source` in
`~/.claude/.skills-templates.json`.

## Todos

- [ ] Ship via `/ship` (Gate #2 human diff review)
- [ ] Land via `/land-and-deploy`

## Log

- 2026-06-04: Created (promoted from draft `.inbox/the_cj_document_release_wrapper_can_t_resolve_its`). Symptom: `/CJ_document-release` HALTs `[doc-sync-no-config]` in every repo except the workbench because SKILL.md invokes the config helper via a bare relative `scripts/` path. Hypothesis (confirmed): missing `.source` reach-back for the helper script.
- 2026-06-04: Fix implemented — resolve the helper repo-local-first then via manifest `.source` (4 call sites + 3 prose refs), unreachable→`[doc-sync-no-config]` HALT; regression test + USAGE.md note added. Verified: test PASS rc=0, `validate.sh` PASS.

## PRs

<!-- PR links with status (open/merged/closed) — populated at /ship. -->

## Files

- `skills/CJ_document-release/SKILL.md` — helper resolution (repo-local-first → `.source`), 4 call sites + 3 prose refs
- `skills/CJ_document-release/USAGE.md` — behavior note + `last-updated` bump
- `tests/cj-document-release.test.sh` — 3 regression assertions (no bare-path; resolved-form+`.source`; functional cwd-toplevel portability)

## Insights

The helper reads its config from the cwd's git toplevel
(`git rev-parse --show-toplevel`), NOT from its own `$0` location — so resolving
the **helper script** from `.source` is safe: a `.source`-resolved helper still
parses the consumer repo's own `cj-document-release.json`. This is the
load-bearing property the fix depends on, locked by the functional regression
test (assertion #27). The pattern mirrors `post-land-sync.sh` /
`skills-update-check`, which resolve workbench scripts via `.source`.

## Journal

- 2026-06-05T05:57:28Z [auto-scaffolded] /CJ_goal_defect captured the bug as draft `.inbox/the_cj_document_release_wrapper_can_t_resolve_its`, then promoted to D000030 after /investigate populated the root cause. Domain defaulted to `uncategorized`.
- 2026-06-05T06:00:00Z [investigate-note] Leaf subagent wrote the fix (3 files) then hit a transient API Overloaded error during sentinel emission; orchestrator independently verified (regression test rc=0; validate.sh PASS; 0 bare-path / 7 resolved-form) and reconstructed the DEBUG_REPORT. Raw: ~/.gstack/analytics/CJ_goal_defect-runs/20260604-225728-12100/investigate-raw.txt
- 2026-06-04 [qa-smoke] 1 (regression): green — no bare-path helper invocation remains in SKILL.md (grep count 0)
- 2026-06-04 [qa-smoke] 2 (regression): green — resolved `bash "$_CFG_HELPER"` ×7 + `.source` reach-back present
- 2026-06-04 [qa-smoke] 3 (regression): green — real helper parses cwd-toplevel config from a temp repo with no scripts/ (suite rc=0)
- 2026-06-04 [qa-smoke-summary] green: 3/3 non-manual rows green (0 manual rows pending)
- 2026-06-04 [qa-pass] D000030 (defect): green smoke from test-plan rows (3 rows). No qa-owned Phase 2 gates per template; Phase 3 `Test-plan verified` gate awaits /ship-time inference.
