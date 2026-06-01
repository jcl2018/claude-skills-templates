---
type: defect
id: D000026
name: "/CJ_goal_feature preamble doc-sync AUQ recommends A on main but A always aborts; flag A as would-abort-upstream and recommend B (snooze). Same shape in /CJ_goal_defect + /CJ_goal_investigate preambles."
status: phase-1-investigating
created: 2026-06-01T02:46:32Z
auto_scaffolded: true
promoted_from_draft: .inbox/cj_goal_feature_preamble_doc_sync_auq_recommends_a
---

# D000026: /CJ_goal_feature preamble doc-sync AUQ recommends A on main but A always aborts; flag A as would-abort-upstream and recommend B (snooze). Same shape in /CJ_goal_defect + /CJ_goal_investigate preambles.

## Bug Report
/CJ_goal_feature preamble doc-sync AUQ recommends A on main but A always aborts; flag A as would-abort-upstream and recommend B (snooze). Same shape in /CJ_goal_defect + /CJ_goal_investigate preambles.

The /CJ_goal_feature preamble (and same shape in /CJ_goal_defect + /CJ_goal_investigate) emits a DOC_SYNC_PENDING AUQ when F000028's post-merge hook drops a marker. The AUQ template per F000029 labels A as "recommended on main", but upstream gstack /document-release Step 1 hard-aborts when invoked from the base branch ("You're on the base branch. Run from a feature branch."). On main, A always aborts; B (snooze) is the only path that actually works.

## Journal
- 2026-06-01T02:46:32Z [auto-scaffolded] /CJ_goal_defect captured the bug as draft .inbox/cj_goal_feature_preamble_doc_sync_auq_recommends_a, then promoted to D000026 after /investigate populated the root cause. Domain defaulted to 'uncategorized'.
- 2026-05-31 [qa-smoke] 1 (regression test for D000026): green — bash tests/cj-goal-doc-sync-auq-recommendation.test.sh exited 0 (17/17 OK, all 3 SKILL.md + CLAUDE.md show corrected wording + pre-fix wording absent)
- 2026-05-31 [qa-smoke] 2 (full test suite still passes): green — bash scripts/test.sh exited 0 (Failures: 0, RESULT: PASS — new regression test wired in correctly)
- 2026-05-31 [qa-smoke] 3 (catalog/filesystem cross-check still passes): green — bash scripts/validate.sh exited 0 (Errors: 0, Warnings: 0, RESULT: PASS)
- 2026-05-31 [qa-smoke-manual] 4 (manual post-merge verification): pending human verification — next session's /CJ_goal_feature invocation should surface a doc-sync AUQ with B recommended on main, A flagged "would abort upstream"; deferred to post-merge
- 2026-05-31 [qa-smoke-summary] green: 3/3 non-manual rows green (1 manual row pending post-merge)
- 2026-05-31 [qa-halt] PHASE2_GATES=red — Phase 2 implementer-owned commit gate (`Fix committed`) is unchecked; 5 modified files (CLAUDE.md, scripts/test.sh, 3 SKILL.md) + 2 untracked (tests/cj-goal-doc-sync-auq-recommendation.test.sh + work-items/defects/.../D000026_*) remain uncommitted from /investigate phase. Per /CJ_qa-work-item Step 2, defect QA refuses on uncommitted state — /ship will handle commits next. Smoke test-plan rows all green (test commands verified runnable independently); orchestrator may treat as smoke-equivalent green for Phase 2 progression once /ship commits the fix.
