---
name: "cj-id-claim.sh reap regex misses {ID}_TRACKER.md feature trackers, so merged feature IDs never reap and parallel cj_goal builds collide on the same F/S work-item ID + VERSION"
type: defect
id: "D000039"
status: active
created: "2026-07-04"
updated: "2026-07-04"
repo: "E:/projects/claude-skills-templates"
branch: "claude/compassionate-shirley-75499a"
blocked_by: ""
auto_scaffolded: true
promoted_from_draft: .inbox/cj_id_claim_sh_reap_regex_misses_id_tracker_md_fea
---

## Lifecycle

### Phase 1: Track

1. Reproduction documented (see Reproduction Steps + the bug report)
2. Working branch created: claude/compassionate-shirley-75499a
3. Required docs scaffolded (D000039 RCA + test-plan — written at Step 7.5)
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

cj-id-claim.sh reap regex misses {ID}_TRACKER.md feature trackers, so merged feature IDs never reap and parallel cj_goal builds collide on the same F/S work-item ID + VERSION

## Todos

- [ ] Ship via /ship (Gate #2 human diff review)
- [ ] Land via /land-and-deploy

## Log

- 2026-07-04: Promoted from draft .inbox/cj_id_claim_sh_reap_regex_misses_id_tracker_md_fea after /investigate populated the root cause. Domain defaulted to 'uncategorized'; relocate to a more specific subdir if needed.

## PRs

<!-- PR links populated at /ship. -->

## Files

<!-- Affected files are listed in the RCA Affected Components table. -->

## Insights

<!-- Root cause + patterns discovered; see the D000039 RCA. -->

## Journal
- 2026-07-04T00:24:01Z [auto-scaffolded] /CJ_goal_defect captured the bug as draft .inbox/cj_id_claim_sh_reap_regex_misses_id_tracker_md_fea, then promoted to D000039 after /investigate populated the root cause. Domain defaulted to 'uncategorized'.
- 2026-07-04 [qa-smoke] 8a (reap-on-origin slug-less): green — `tests/cj-id-claim.test.sh` Case 8a OK: slug-less on-origin feature claim reaped + re-minted (id_on_origin regex accepts `{ID}_TRACKER.md`); CLAIMED_ID=F000048.
- 2026-07-04 [qa-smoke] 8b (materialized slug-less reuse): green — `tests/cj-id-claim.test.sh` Case 8b OK: materialized `F000090_TRACKER.md` detected by id_has_workitem_dir find-glob → same-branch reuse advanced to F000091.
- 2026-07-04 [qa-smoke] 3/6.0 (slug-bearing shape unchanged): green — `tests/cj-id-claim.test.sh` Cases 3 + 6.0 OK: slug-bearing `_demo_` reap + same-branch reuse behave as before (no regression); adversarial over-match guard holds (F000053 != F000530).
- 2026-07-04 [qa-smoke-summary] green: 3/3 non-manual rows green (0 manual rows pending). Full `tests/cj-id-claim.test.sh` = RESULT: PASS, Failures: 0 (all 13 cases incl. Case 2 concurrency race green this run).
- 2026-07-04 [qa-audit] AUDITS=deferred,spec_updates:test-spec-custom changed(test-cj-id-claim),doc-spec-custom:none (Step 8.6a/8.6b ran inline; 8.6c/8.6d SKIPPED via DEFER_AUDIT — the agent-judged audit runs nightly in CI)
- 2026-07-04 [qa-pass] D000039 (defect): green smoke from test-plan rows (3 rows). No qa-owned Phase 2 gates per template; Phase 3 `Test-plan verified` gate awaits /ship-time inference.
