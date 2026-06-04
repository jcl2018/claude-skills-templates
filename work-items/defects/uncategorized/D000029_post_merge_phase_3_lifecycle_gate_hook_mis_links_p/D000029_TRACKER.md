---
type: defect
id: D000029
name: "post-merge Phase-3 lifecycle-gate hook mis-links PRs via gh pr list title/body search and leaves the tracker edit uncommitted, dirtying main (F000011)"
status: phase-1-investigating
created: 2026-06-04T08:29:06Z
auto_scaffolded: true
promoted_from_draft: .inbox/post_merge_phase_3_lifecycle_gate_hook_mis_links_p
---

# D000029: post-merge Phase-3 lifecycle-gate hook mis-links PRs via gh pr list title/body search and leaves the tracker edit uncommitted, dirtying main (F000011)

## Bug Report
post-merge Phase-3 lifecycle-gate hook mis-links PRs via gh pr list title/body search and leaves the tracker edit uncommitted, dirtying main (F000011)

## Journal
- 2026-06-04T08:29:06Z [auto-scaffolded] /CJ_goal_defect captured "post-merge Phase-3 lifecycle-gate hook mis-links PRs via gh pr list title/body search and leaves the tracker edit uncommitted, dirtying main (F000011)" as draft .inbox/post_merge_phase_3_lifecycle_gate_hook_mis_links_p, then promoted to D000029 after /investigate confirmed the root cause (Approach A: disable the post-merge auto-tick). Domain defaulted to 'uncategorized'.
- 2026-06-04 [qa-smoke] TP1 (Generated post-merge hook has no Phase-3 auto-tick): green — installed setup-hooks.sh into a throwaway temp git repo; executable lines of generated `.git/hooks/post-merge` contain no `check-gates-update` / `"$BRANCH"=main` / `work-items.*_TRACKER`.
- 2026-06-04 [qa-smoke] TP2 (Section 1 D000013 redeploy preserved): green — generated hook executable lines contain `"$REPO_ROOT/scripts/skills-deploy" install --overwrite` (Section 1) + `exit 0` tail.
- 2026-06-04 [qa-smoke] TP3 (Removal comment doesn't false-match): green — `check-gates-update` appears only in the removal comment; absence greps run against comment-stripped executable lines (hook_code()/`grep -vE '^\s*#'`) so the descriptive comment does not false-match.
- 2026-06-04 [qa-smoke] TP4 (Test actually runs in CI): green — `./scripts/test.sh` fired the newly-registered runner block ("Running tests/setup-hooks.test.sh ... OK: installed post-merge hook redeploys but no longer auto-ticks trackers (F000011 fix)").
- 2026-06-04 [qa-smoke-summary] green: 4/4 non-manual test-plan rows green (0 manual rows pending).
- 2026-06-04 [qa-pass] D000029 (defect): green smoke from test-plan rows (4 rows). Verified against the WORKING TREE (changes intentionally uncommitted; /CJ_goal_defect commits at /ship). Corroborating gates: `bash tests/setup-hooks.test.sh` → 8 assertions / 0 failures (incl. Smoke 1); `./scripts/test.sh` → PASS; `./scripts/validate.sh` → 0 errors / 0 warnings. No qa-owned Phase 2 gates per defect template; Phase 3 `Test-plan verified` gate awaits /ship-time inference.
- 2026-06-04 [qa-note] Incidental side-effect during QA: an early temp-repo invocation of the worktree's `scripts/setup-hooks.sh` resolved REPO_ROOT to the worktree (the script always targets its own repo root, not cwd) and therefore refreshed the workbench's LIVE shared `.git/hooks/{post-merge,pre-commit}` to the FIXED versions (the new post-merge has Section 1 only, no Phase-3 block). Benign + actually matches the test-plan's deferred post-land step ("re-run setup-hooks.sh to refresh the LIVE hook"); no tracked files touched, no source mutated. Flagging for transparency.
