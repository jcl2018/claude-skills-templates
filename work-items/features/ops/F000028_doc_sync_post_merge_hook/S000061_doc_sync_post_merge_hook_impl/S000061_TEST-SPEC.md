---
type: test-spec
parent: S000061
feature: F000028
title: "Implement post-merge + post-rewrite doc-sync trigger block — Test Specification"
version: 1
status: Draft
date: 2026-05-30
author: chjiang
spec: SPEC.md
reviewers: []
---

<!-- Scope: ENTIRE user story. Smoke + E2E together must cover every SPEC P0
     acceptance criterion. Two tiers: Smoke (automated, CI) and E2E (manual,
     before /ship). Soft cap: 5 rows per tier — exceeded here to cover all 6
     load-bearing test rows enumerated in the parent design Success Criteria. -->

## Smoke Tests

<!-- Automated regression. Fast, deterministic, runnable from a script or CI.
     AC column maps each row to a SPEC acceptance criterion (Story #N). -->

| # | Tag | AC | Check | What It Validates | Script/Command |
|---|-----|-----|-------|-------------------|----------------|
| S1 | core | AC-1 | `./scripts/setup-hooks.sh` installs `post-merge` + `post-rewrite` hooks with the `# doc-sync trigger block` marker comment in both | hook install is wholesale (sentinel-aware re-install does not strip section 3) | `./tests/setup-hooks.test.sh --case install_creates_both_hooks` |
| S2 | core | AC-2 | Main-moving merge in a temp-repo fixture writes `~/.gstack/doc-sync-pending/<slug>.json` with `head_sha`=`git rev-parse HEAD`, `diff_base` resolves to a valid tree-ish, `repo` matches basename, `main_moved_at` is ISO-8601 UTC | trigger block fires on the expected event; heredoc nesting correct (variables expand at hook-execution time, not install time) | `./tests/setup-hooks.test.sh --case main_moving_merge_writes_marker` |
| S3 | resilience | AC-3 | Re-running the hook on the same HEAD is a NO-OP (no new marker, no stderr) | idempotency guard via `.doc-sync-last-head` works | `./tests/setup-hooks.test.sh --case same_head_is_noop` |
| S4 | resilience | AC-4, AC-4b | Doc-only merge skips marker; `DOC_SYNC_FORCE=1` overrides | triviality regex correct (anchored), force-flag honored | `./tests/setup-hooks.test.sh --case doc_only_skips_and_force_overrides` |
| S5 | resilience | AC-5 | Initial-commit edge case (empty `_LAST_SYNCED`, no `HEAD^`) falls back to empty-tree diff base; marker still written and valid | edge-case fallback works | `./tests/setup-hooks.test.sh --case initial_commit_fallback` |
| S6 | integration | AC-6 | `git pull --rebase` on main triggers same marker via `post-rewrite` | post-rewrite installed with same trigger block; shared body works in both hooks | `./tests/setup-hooks.test.sh --case post_rewrite_covers_rebase_flow` |
| S7 | core | AC-7 | After installing the combined post-merge hook, sections 1 (D000013) and 2 (F000011) still run; section 3 runs after them | no regression in existing sections; sentinel-aware re-install does not backup-thrash | `./tests/setup-hooks.test.sh --case existing_sections_coexist` |
| S8 | observability | AC-8 | Hook emits `[doc-sync] main moved. Marker written: <path>` to stderr on success | operator can see at a glance the hook ran | (covered by S2's assertion on stderr) |

<!-- Tag vocabulary: core, resilience, observability, usability, security, integration. -->

## E2E Tests

<!-- Manual end-to-end verification, run after implementing and before /ship.
     AC column maps each row to a SPEC acceptance criterion. -->

| # | Tag | AC | Scenario | Steps (as a real user would) | Expected Outcome | Rubric |
|---|-----|-----|----------|------------------------------|------------------|--------|
| E1 | core | AC-1 | Fresh-clone install of both hooks | (1) `git clone https://github.com/jcl2018/claude-skills-templates.git /tmp/cst-e2e-1`; (2) `cd /tmp/cst-e2e-1`; (3) `./scripts/setup-hooks.sh`; (4) `grep -c '# doc-sync trigger block' .git/hooks/post-merge` (must print 1); (5) `grep -c '# doc-sync trigger block' .git/hooks/post-rewrite` (must print 1) | Both hooks exist, both contain the marker comment | (4) and (5) both print exactly 1; no error from setup-hooks.sh |
| E2 | core post-ship | AC-2, AC-6 | Real-world dogfood: hook fires on THIS PR's own merge | After this PR merges on GitHub: (1) `git checkout main && git pull origin main` in any local checkout with hooks installed; (2) `ls ~/.gstack/doc-sync-pending/claude-skills-templates.json` | Marker exists; contents parseable as valid JSON with non-empty `head_sha` matching `git rev-parse origin/main` | Marker file present; `jq` parses without error |
| E3 | resilience | AC-3 | Quick re-pull is silent | (1) Trigger marker once (E2's flow); (2) immediately `rm ~/.gstack/doc-sync-pending/claude-skills-templates.json`; (3) `git pull origin main` (HEAD doesn't move; same SHA) | No new marker written; no `[doc-sync]` stderr line | `ls ~/.gstack/doc-sync-pending/` shows no claude-skills-templates.json |
| E4 | resilience | AC-4 | Doc-only merge skips | (1) Create a feature branch with only a CHANGELOG.md typo fix; (2) merge it (`git merge --no-ff feat`); (3) check marker dir | No marker written; stderr line `[doc-sync] main moved but only docs changed; skipping /document-release.` printed | No marker; correct stderr text |
| E5 | integration | AC-7 | Coexist verification with D000013 | (1) Merge a PR that touches `skills/CJ_personal-workflow/SKILL.md`; (2) `git pull origin main`; (3) verify both D000013 skills-deploy ran (look for skills-deploy stderr lines) AND doc-sync marker was written | Both sections execute; no error from either; final exit 0 | D000013 stderr present + marker file present |

<!-- E2 is post-ship by structure: the hook fires on THIS PR's own merge, so
     it cannot be verified until after merge. /CJ_qa-work-item Step 4 will
     filter this row out of the E2E subagent dispatch and record a
     [qa-e2e-deferred] journal entry. Verification happens manually after
     merge. -->

## Coverage Gaps

<!-- What is explicitly NOT tested and why. Honesty beats false confidence. -->

| Gap | Why Not Tested | Risk Accepted |
|-----|----------------|---------------|
| `git reset --hard origin/main` does not fire either hook | No git hook can cover this — it's a direct ref manipulation, not a merge or rewrite | Operator who uses `git reset --hard` on main loses doc-sync prompts for those moves; documented as known gap in parent F000028_DESIGN.md |
| Per-machine opt-out flag (`~/.gstack/doc-sync-disabled` sentinel) | Deferred to v2 per parent design Open Question 1 | Users who want to suppress all doc-sync prompts can manually remove `.git/hooks/post-merge` doc-sync section; coarser than a config flag but workable |
| Cross-platform Linux validation | Workbench is macOS-only per CLAUDE.md | Linux developers can't dogfood; if Linux support is needed later, re-test on a Linux fixture |
| Behavior under unusual git operations (`git filter-branch`, `git replace`, etc.) | Out of scope; standard developer flow uses pull / pull --rebase / merge | Edge cases produce no marker; operator runs `/document-release` manually |
| Marker dir garbage collection (unbounded growth if operator never runs `/document-release`) | v1 doesn't GC; future marker-pickup AUQ will delete on consume | Disk-space risk is negligible (markers are ~200 bytes); operator can `rm -rf ~/.gstack/doc-sync-pending/` manually |
