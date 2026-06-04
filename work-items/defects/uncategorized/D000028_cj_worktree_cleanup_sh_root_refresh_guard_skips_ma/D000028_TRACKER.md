---
type: defect
id: D000028
name: "cj-worktree-cleanup.sh root-refresh guard skips main checkout and pull when the root has untracked files; should only skip on a dirty tracked tree"
status: phase-1-investigating
created: 2026-06-04T07:51:59Z
auto_scaffolded: true
promoted_from_draft: .inbox/cj_worktree_cleanup_sh_root_refresh_guard_skips_ma
---

# D000028: cj-worktree-cleanup.sh root-refresh guard skips main checkout and pull when the root has untracked files; should only skip on a dirty tracked tree

## Bug Report
cj-worktree-cleanup.sh root-refresh guard skips main checkout and pull when the root has untracked files; should only skip on a dirty tracked tree

## Journal
- 2026-06-04T07:51:59Z [auto-scaffolded] /CJ_goal_defect captured "cj-worktree-cleanup.sh root-refresh guard skips main checkout and pull when the root has untracked files; should only skip on a dirty tracked tree" as draft .inbox/cj_worktree_cleanup_sh_root_refresh_guard_skips_ma, then promoted to D000028 after /investigate populated the root cause. Domain defaulted to 'uncategorized'.
- 2026-06-04 [qa-smoke] 1 (untracked-only root refreshes): green — `bash tests/cj-worktree-cleanup.test.sh` Case 12b: untracked-only root → ROOT_REFRESH=ok (the D-fix; refresh now proceeds).
- 2026-06-04 [qa-smoke] 2 (dirty tracked root still skips): green — same suite Case 12: dirty TRACKED root → ROOT_REFRESH=skipped + "dirty tracked tree" note.
- 2026-06-04 [qa-smoke] 3 (per-worktree dirty rail unchanged): green — same suite Case 9: cj-* worktree with untracked scratch + MERGED PR → SKIPPED (reason=dirty); per-worktree rail at line 185 keeps bare --porcelain (untracked still counts).
- 2026-06-04 [qa-smoke] 4 (negative control): green — RCA investigation trail row (00:50) confirms restoring the buggy bare --porcelain guard makes Case 12b FAIL, so the test discriminates the bug.
- 2026-06-04 [qa-smoke-summary] green: 4/4 non-manual rows green (0 manual rows pending). Full suite `./scripts/test.sh` PASS (cj-worktree-cleanup.test.sh fires in-suite, 0 failures); `./scripts/validate.sh` PASS (0 errors / 0 warnings). Fix confirmed at scripts/cj-worktree-cleanup.sh:309 (--untracked-files=no); per-worktree rail at line 185 unchanged.
- 2026-06-04 [qa-pass] D000028 (defect): green smoke from test-plan rows (4 rows). No qa-owned Phase 2 gates per template (TRACKER has no Lifecycle/Gates block); Phase 3 `Test-plan verified` gate awaits /ship-time inference. Fix is intentionally uncommitted at this QA stage (/CJ_goal_defect commits at /ship); code present + verified in the working tree.
