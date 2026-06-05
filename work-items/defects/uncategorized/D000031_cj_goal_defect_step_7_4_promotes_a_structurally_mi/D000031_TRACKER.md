---
name: "CJ_goal_defect Step 7.4 promotes a structurally-minimal defect tracker that fails the /CJ_personal-workflow check boundary gate run by /CJ_qa-work-item (Step 8), so every run halts at QA unless the operator manually fleshes the tracker. The promoted D000NNN_TRACKER.md has only frontmatter + ## Bug Report + ## Journal, but tracker-defect.md requires frontmatter fields updated/repo/branch/blocked_by plus the ## Lifecycle (3 phases, 11 checkboxes) / Reproduction Steps / Todos / Log / PRs / Files / Insights sections. Compounding it, there is no commit step before Step 8, so the Phase-2 'Fix committed' implementer gate is unchecked and QA refuses 'Phase 2 incomplete'. Fix Step 7.4 to emit a fully tracker-defect.md-compliant tracker (Phase 1 + Phase 2 gates checked) and add a commit-before-QA step so the investigate-written fix is committed and the 'Fix committed' gate is honest."
type: defect
id: "D000031"
status: active
created: "2026-06-05"
updated: "2026-06-05"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "cj-def-20260604-235629-51218"
blocked_by: ""
auto_scaffolded: true
promoted_from_draft: .inbox/cj_goal_defect_step_7_4_promotes_a_structurally_mi
---

## Lifecycle

### Phase 1: Track

1. Reproduction documented (see Reproduction Steps + the bug report)
2. Working branch created: cj-def-20260604-235629-51218
3. Required docs scaffolded (D000031 RCA + test-plan — written at Step 7.5)
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

CJ_goal_defect Step 7.4 promotes a structurally-minimal defect tracker that fails the /CJ_personal-workflow check boundary gate run by /CJ_qa-work-item (Step 8), so every run halts at QA unless the operator manually fleshes the tracker. The promoted D000NNN_TRACKER.md has only frontmatter + ## Bug Report + ## Journal, but tracker-defect.md requires frontmatter fields updated/repo/branch/blocked_by plus the ## Lifecycle (3 phases, 11 checkboxes) / Reproduction Steps / Todos / Log / PRs / Files / Insights sections. Compounding it, there is no commit step before Step 8, so the Phase-2 'Fix committed' implementer gate is unchecked and QA refuses 'Phase 2 incomplete'. Fix Step 7.4 to emit a fully tracker-defect.md-compliant tracker (Phase 1 + Phase 2 gates checked) and add a commit-before-QA step so the investigate-written fix is committed and the 'Fix committed' gate is honest.

## Todos

- [ ] Ship via /ship (Gate #2 human diff review)
- [ ] Land via /land-and-deploy

## Log

- 2026-06-05: Promoted from draft .inbox/cj_goal_defect_step_7_4_promotes_a_structurally_mi after /investigate populated the root cause. Domain defaulted to 'uncategorized'; relocate to a more specific subdir if needed.

## PRs

<!-- PR links populated at /ship. -->

## Files

<!-- Affected files are listed in the RCA Affected Components table. -->

## Insights

<!-- Root cause + patterns discovered; see the D000031 RCA. -->

## Journal
- 2026-06-05T07:07:33Z [auto-scaffolded] /CJ_goal_defect captured the bug as draft .inbox/cj_goal_defect_step_7_4_promotes_a_structurally_mi, then promoted to D000031 after /investigate populated the root cause. Domain defaulted to 'uncategorized'.
- 2026-06-05 [qa-smoke] 1 (regression): green — Step 7.4 TRK heredoc extracted; 9 frontmatter fields + 3 phases + 11 lifecycle checkboxes + all 8 sections (scripts/test.sh D000031 assertion OK)
- 2026-06-05 [qa-smoke] 2 (regression): green — Step 7.6 commit-before-QA step present in pipeline.md
- 2026-06-05 [qa-smoke] 3 (regression): green — DOGFOOD: this run's own promoted tracker passes the QA boundary check (no 'Phase 2 incomplete' refusal), no manual fleshing
- 2026-06-05 [qa-smoke-summary] green: 3/3 non-manual rows green (0 manual rows pending)
- 2026-06-05 [qa-pass] D000031 (defect): green smoke from test-plan rows (3 rows). No qa-owned Phase 2 gates per template; Phase 3 `Test-plan verified` gate awaits /ship-time inference.
