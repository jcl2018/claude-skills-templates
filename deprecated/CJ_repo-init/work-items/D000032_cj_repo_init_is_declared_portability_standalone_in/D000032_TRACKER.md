---
name: "CJ_repo-init is declared portability: standalone in skills-catalog.json but its SKILL.md executes scripts/cj-repo-init.sh — a workbench ROOT helper absent from a fresh consumer repo. /CJ_repo-init's whole purpose is bootstrapping a repo that has never seen the workbench, so it is not actually standalone: /CJ_portability-audit --no-adjudication flags FINDINGS=1, and it only passes the default audit via a portability_requires adjudication (documented debt, v6.0.36/T000042). Fix: bundle the engine into skills/CJ_repo-init/scripts/cj-repo-init.sh, rewire SKILL.md to resolve the bundled engine, drop the adjudication; this exposed an audit is_exec precision bug (seed-data string literals in a bundled .sh false-flagged) which is fixed too."
type: defect
id: "D000032"
status: active
created: "2026-06-05"
updated: "2026-06-05"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "cj-def-20260605-003802-77237"
blocked_by: ""
auto_scaffolded: true
promoted_from_draft: .inbox/cj_repo_init_is_declared_portability_standalone_in
---

## Lifecycle

### Phase 1: Track

1. Reproduction documented (see Reproduction Steps + the bug report)
2. Working branch created: cj-def-20260605-003802-77237
3. Required docs scaffolded (D000032 RCA + test-plan)
4. /investigate populated the root cause (Iron-Law gate passed)

**Gates:**
- [x] Reproduction steps documented
- [x] Working branch created (branch field populated)
- [x] Required docs scaffolded (RCA + test-plan)
- [x] Root cause identified (or best hypothesis logged)

### Phase 2: Implement

1. /investigate Phase 4 wrote the fix directly to source
2. Regression test added covering the defect scenario
3. Fix + work-item artifacts committed (Step 7.6, before QA)
4. RCA updated with the final root cause

**Gates:**
- [x] Fix committed
- [x] RCA doc updated
- [x] Todos section reflects remaining work (no stale items)

### Phase 3: Ship

1. /CJ_qa-work-item — verify the test-plan rows (Step 8)
2. /CJ_document-release — doc-sync (Step 5.5)
3. /ship — open the fix PR (Step 9)
4. /land-and-deploy — merge + verify (Step 10)

**Gates:**
- [ ] /CJ_personal-workflow check — validation passed
- [ ] Test-plan verified (regression scenarios passing)
- [ ] /ship — PR created
- [ ] /land-and-deploy — merged and deployed

## Reproduction Steps

CJ_repo-init is declared portability: standalone in skills-catalog.json but its SKILL.md executes scripts/cj-repo-init.sh — a workbench ROOT helper absent from a fresh consumer repo. /CJ_repo-init's whole purpose is bootstrapping a repo that has never seen the workbench, so it is not actually standalone: /CJ_portability-audit --no-adjudication flags FINDINGS=1, and it only passes the default audit via a portability_requires adjudication (documented debt, v6.0.36/T000042). Fix: bundle the engine into skills/CJ_repo-init/scripts/cj-repo-init.sh, rewire SKILL.md to resolve the bundled engine, drop the adjudication; this exposed an audit is_exec precision bug (seed-data string literals in a bundled .sh false-flagged) which is fixed too.

## Todos

- [ ] Ship via /ship (Gate #2 human diff review)
- [ ] Land via /land-and-deploy

## Log

- 2026-06-05: Promoted from draft .inbox/cj_repo_init_is_declared_portability_standalone_in after /investigate populated the root cause. Surfaced by the operator's "are all skills actually standalone" portability audit.

## PRs

<!-- PR links populated at /ship. -->

## Files

<!-- Affected files are listed in the RCA Affected Components table. -->

## Insights

<!-- Root cause + patterns discovered; see the D000032 RCA. -->

## Journal
- 2026-06-05T18:08:20Z [auto-scaffolded] /CJ_goal_defect promoted to D000032. Combined scope (skill fix + audit is_exec precision) operator-approved.
- 2026-06-05 [qa-smoke] 1 (regression): green — CJ_repo-init portable in --no-adjudication, FINDINGS=0 (genuinely standalone, no adjudication)
- 2026-06-05 [qa-smoke] 2 (regression): green — no other skill regressed (no findings: lines)
- 2026-06-05 [qa-smoke] 3 (regression): green — scripts/test.sh S000083i (seed literal not flagged) + a-h intact + cj-repo-init.test.sh; Failures: 0
- 2026-06-05 [qa-smoke-summary] green: 3/3 non-manual rows green (0 manual rows pending)
- 2026-06-05 [qa-pass] D000032 (defect): green smoke from test-plan rows (3 rows). No qa-owned Phase 2 gates per template; Phase 3 `Test-plan verified` gate awaits /ship-time inference.
