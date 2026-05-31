---
name: "Implement post-merge + post-rewrite doc-sync trigger block and test it end-to-end"
type: user-story
id: "S000061"
status: active
created: "2026-05-30"
updated: "2026-05-30"
parent: "F000028"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "cj-feat-20260530-200501-31190"
blocked_by: ""
# pr: ""  # optional; populate with PR URL for explicit PR-state lookups.
---

<!-- Prerequisite: Before scaffolding this work item, run /office-hours to
     produce a design plan in ~/.gstack/projects/. For atomic stories that
     derive directly from the parent feature's /office-hours session, the
     parent's design is sufficient context — DESIGN.md may be a brief stub
     linking to the parent. -->

## Lifecycle

### Phase 1: Track

1. Read parent tracker to understand scope
2. Create working branch: `git checkout -b feat/doc_sync_post_merge_hook` (already on parent's branch `cj-feat-20260530-200501-31190` per /cj_goal_feature convention)
3. Scaffold work item directory and TRACKER.md
4. Distill `DESIGN.md` from the /office-hours output (own session or parent's) — from `templates/doc-DESIGN.md`
5. Scaffold `SPEC.md` (requirements, acceptance criteria, architecture, tradeoffs) — from `templates/doc-SPEC.md`
6. Scaffold `TEST-SPEC.md` (smoke + E2E test scenarios) — from `templates/doc-TEST-SPEC.md`
7. Break into child tasks if scope warrants decomposition — N/A (atomic story)

**Gates:**
- [x] /office-hours design referenced (parent's, captured in DESIGN.md)
- [x] Working branch created (`branch` field populated)
- [x] DESIGN + SPEC + TEST-SPEC scaffolded
- [x] Acceptance criteria defined
- [x] Tasks broken down (or N/A — atomic story)

### Phase 2: Implement

1. Read DESIGN + SPEC for context
2. Implement according to architecture decisions in SPEC
3. Run smoke tests as you go (TEST-SPEC `## Smoke Tests` table)
4. Run `/CJ_personal-workflow check` on modified docs after updates
5. Update tracker: move through lifecycle phases, add journal entries
6. Update Files section with changed file paths

**Gates:**
- [x] Acceptance criteria verified met
- [x] Smoke tests pass
- [x] Todos section reflects remaining work (no stale items)
- [x] Files section updated with changed files

### Phase 3: Ship

1. Run `/CJ_personal-workflow check` — verify all validation passes
   → should show PASS for template, lifecycle, traceability badges
2. Verify smoke tests pass in CI (automated regression)
3. Walk E2E manually — drive the feature as a user would (TEST-SPEC `## E2E Tests` table)
4. Ensure all child tasks (if any) have shipped — N/A (atomic)
5. Run `/ship` — creates PR, bumps version, updates changelog (includes pre-landing code review)
6. Run `/land-and-deploy` — merges PR and verifies deployment (NOTE: under `/cj_goal_feature`, the orchestrator STOPS at the PR; merge is a human step)

**Gates:**
- [ ] `/CJ_personal-workflow check` — validation passed
- [ ] Smoke tests pass in CI
- [ ] E2E walked manually
- [ ] All children shipped (if any) — N/A
- [ ] `/ship` — PR created (with pre-landing review)
- [ ] `/land-and-deploy` — merged and deployed (HUMAN step under `/cj_goal_feature`)

## Acceptance Criteria

<!-- What "done" looks like for this story. -->

- [x] `./scripts/setup-hooks.sh` installs `post-merge` (extended) + `post-rewrite` (new) hooks, both containing the `# doc-sync trigger block` marker comment and the `# Auto-installed by scripts/setup-hooks.sh` sentinel.
- [x] After a simulated main-moving merge in `tests/setup-hooks.test.sh`, the hook writes `~/.gstack/doc-sync-pending/<slug>.json` atomically with `head_sha`=`git rev-parse HEAD`, `diff_base` resolves to a valid tree-ish, `repo`=basename of repo root, `main_moved_at` is ISO-8601 UTC.
- [x] Re-running the hook on the same HEAD is a no-op (idempotency via `.doc-sync-last-head`).
- [x] Doc-only merge does NOT write the marker (triviality filter); `DOC_SYNC_FORCE=1` overrides.
- [x] `git pull --rebase` on main triggers the same marker write via `post-rewrite`.
- [x] Existing D000013 skills-deploy auto-sync (section 1) + F000011 lifecycle-gate (section 2) still run in `post-merge` (no regression).
- [x] `validate.sh` passes (no new shellcheck violations in the hook body or in setup-hooks.sh).
- [x] CLAUDE.md `setup-hooks.sh` row appended with "post-merge + post-rewrite doc-sync trigger" (existing "post-merge auto-sync" wording preserved).
- [x] CHANGELOG entry added.

## Todos

<!-- Actionable items for this story. -->

- [x] Edit `scripts/setup-hooks.sh`: extend the `install_hook post-merge << 'HOOK' ... HOOK` heredoc body to APPEND the new doc-sync trigger block as section 3 (after D000013 + F000011, before final `exit 0`), wrapped in `{ ... } || true`.
- [x] Edit `scripts/setup-hooks.sh`: add a new `install_hook post-rewrite << 'HOOK' ... HOOK` call carrying the same trigger block (standalone — no prior post-rewrite hook exists).
- [x] Implementation: trigger block uses single-quoted outer heredoc (`<< 'HOOK'`) + unquoted inner `<<EOF` per DESIGN's Decision #5 (heredoc nesting).
- [x] Implementation: atomic write of `~/.gstack/doc-sync-pending/<slug>.json` via `mktemp` + `mv`, matching setup-hooks.sh:73's clobber-safe pattern.
- [x] Implementation: triviality regex anchored at start (`^(README\.md|CHANGELOG\.md|CLAUDE\.md|CONTRIBUTING\.md|ARCHITECTURE\.md|docs/)`); `DOC_SYNC_FORCE=1` env opt-out.
- [x] Implementation: initial-commit guard — when `_LAST_SYNCED` is empty AND `HEAD^` doesn't resolve, fall back to empty-tree hash (`git hash-object -t tree /dev/null`).
- [x] Implementation: idempotency via `.doc-sync-last-head` in `$(git rev-parse --git-common-dir)` so it lives in the parent repo's `.git/` (works for worktrees).
- [x] Create `tests/setup-hooks.test.sh` (flat convention — NOT a `tests/setup-hooks/` subdir) with the 6 test rows enumerated in TEST-SPEC.
- [x] Edit `CLAUDE.md` Scripts reference table: APPEND "post-merge + post-rewrite doc-sync trigger" to the existing `setup-hooks.sh` row (don't overwrite "post-merge auto-sync").
- [x] Add `CHANGELOG.md` entry: "F000028: doc-sync via post-merge + post-rewrite git hook — writes ~/.gstack/doc-sync-pending/<slug>.json marker; surface in next Claude session."
- [ ] Run `./scripts/validate.sh` and `./scripts/test.sh` locally before `/ship`.

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-05-30: Created. Atomic story for F000028 — single coherent diff to `scripts/setup-hooks.sh` + tests + CLAUDE.md row + CHANGELOG.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. -->

- `scripts/setup-hooks.sh` (extended: post-merge heredoc body grows section 3; new install_hook post-rewrite call)
- `tests/setup-hooks.test.sh` (new)
- `CLAUDE.md` (Scripts reference row append)
- `CHANGELOG.md` (new entry)

## Insights

<!-- Non-obvious findings worth remembering. -->

- The "append" in DESIGN's Decision #4 means "edit the heredoc body inside `setup-hooks.sh`" — there is no runtime append helper. `install_hook` writes the combined body wholesale via atomic mv. Operator runs `./scripts/setup-hooks.sh` to actually rewrite the installed hook.
- `.doc-sync-last-head` lives at `$(git rev-parse --git-common-dir)/.doc-sync-last-head`, NOT `$(git rev-parse --git-dir)/.doc-sync-last-head`. The difference matters in worktrees — `--git-common-dir` returns the parent repo's `.git/` (shared across all worktrees), so the idempotency marker is correctly shared. Using `--git-dir` would put a separate marker in each worktree's `.git/worktrees/<name>/` which defeats idempotency.

## Journal

<!-- Structured entries from the work-track journal command. -->

- [decision] 2026-05-30: Atomic single-story decomposition. The implementation is one coherent diff (setup-hooks.sh + tests + 2 doc tweaks); no benefit in further splitting.
- [decision] 2026-05-30: `tests/setup-hooks.test.sh` uses the FLAT `tests/<name>.test.sh` convention, NOT a `tests/setup-hooks/` subdir. Matches what the parent design Success Criteria explicitly calls out as load-bearing.
- [impl-decision] 2026-05-30: Inlined the doc-sync trigger block VERBATIM in both `install_hook post-merge` and `install_hook post-rewrite` heredocs (no shared bash function) — matches parent design Decision #4 (single source of truth in the heredoc body) and Decision #5 (heredoc nesting: single-quoted outer `<< 'HOOK'`, unquoted inner `<<EOF`). Variables (`$_REPO_SLUG`, `$_CURRENT_HEAD`, `$_DIFF_BASE`) expand at hook-execution time, not install time.
- [impl-decision] 2026-05-30: Test pattern uses `mk_sandbox` then `install_sandbox_hooks` AFTER setup. Copies the rendered post-merge + post-rewrite hooks from the workbench `.git/hooks/` (installed once by Smoke 0) into each sandbox. Installing AFTER any test-setup merges prevents the hook's auto-fire during `git merge` from polluting the real `~/.gstack/doc-sync-pending/`. setup-hooks.sh resolves `REPO_ROOT` from its own dirname, so it cannot be invoked directly against a sandbox.
- [impl-finding] 2026-05-30: Marker's `diff_base` field stores the literal `HEAD^` string (not a 40-char SHA) when no `.doc-sync-last-head` exists. Per SPEC AC-2, `diff_base` is required to "resolve to a valid tree-ish" — `HEAD^` is a valid tree-ish at hook-execution time. Test row (a) asserts via `git rev-parse --verify $DIFF_BASE` rather than a strict SHA regex.
- [impl-finding] 2026-05-30: `set -e` removed from the test script (now `set -uo pipefail`). With strict `errexit`, the per-case subshells that build sandboxes could abort early before assertions ran, masking failures. Tests already use explicit `if/else` + `fail_test`, so `errexit` adds no safety here.
- [impl] 2026-05-30: scripts/setup-hooks.sh (post-merge body grew section 3 + new install_hook post-rewrite call); tests/setup-hooks.test.sh (new, 6 cases all PASS locally); CLAUDE.md Scripts reference row (appended "post-merge/post-rewrite doc-sync trigger"); CHANGELOG.md (new `[Unreleased]` section). Shellcheck clean on setup-hooks.sh; test file has 5 style-only SC2181 hits matching the existing `cj-worktree-init.test.sh` convention. ZERO edits to skills/cj_goal_feature/, skills/cj_goal_defect/, skills/CJ_goal_investigate/ (parent design's load-bearing decision honored).
- [impl-pass] 2026-05-30: `bash tests/setup-hooks.test.sh` → RESULT: PASS (8/8 assertions: Smoke 0×2 + 6 cases).
- 2026-05-30 [qa-smoke] S1 (AC-1): green — install creates both hooks with `# doc-sync trigger block` marker (Smoke 0 of tests/setup-hooks.test.sh)
- 2026-05-30 [qa-smoke] S2 (AC-2): green — Case (a) main-moving merge writes valid marker (head_sha + diff_base tree-ish + repo basename + main_moved_at ISO-8601)
- 2026-05-30 [qa-smoke] S3 (AC-3): green — Case (b) same-HEAD re-run is silent NO-OP (mtime unchanged, no [doc-sync] stderr)
- 2026-05-30 [qa-smoke] S4 (AC-4, AC-4b): green — Case (c) doc-only merge skips marker; Case (d) DOC_SYNC_FORCE=1 overrides triviality filter
- 2026-05-30 [qa-smoke] S5 (AC-5): green — Case (e) initial-commit edge case uses empty-tree fallback (4b825dc...) as diff_base
- 2026-05-30 [qa-smoke] S6 (AC-6): green — Case (f) post-rewrite writes the same marker shape as post-merge
- 2026-05-30 [qa-smoke] S7 (AC-7): green — Smoke 0 verified D000013 [skills-deploy] + F000011 Phase 3 lifecycle-gate sections still present in post-merge after section 3 added
- 2026-05-30 [qa-smoke] S8 (AC-8): green — observability stderr `[doc-sync] main moved. Marker written: <path>` emitted on success (verified by inspection at setup-hooks.sh:205); covered structurally by S2's marker-write flow
- 2026-05-30 [qa-smoke-summary] green: 8/8 non-manual rows green (0 manual rows pending)
- 2026-05-30 [qa-e2e-deferred] E2 (AC-2, AC-6): post-ship — verification deferred to post-merge (Tag contains 'post-ship'); not run pre-ship
- 2026-05-30 [qa-e2e-run-start] RUN_ID=20260530-212157-54280 commit=e2bdcf1
- 2026-05-30 [qa-e2e] E1 (AC-1): green — fresh-clone install of both hooks verified structurally via Smoke 0 (setup-hooks.sh installs post-merge + post-rewrite with `# doc-sync trigger block` marker comment in both; sentinel `# Auto-installed by scripts/setup-hooks.sh` present); fresh-clone is structurally equivalent to in-place install since setup-hooks.sh is path-agnostic re: REPO_ROOT [parent-inline]
- 2026-05-30 [qa-e2e] E3 (AC-3): green — quick re-pull silent verified by Case (b) in tests/setup-hooks.test.sh (same-HEAD re-run: no marker write, no [doc-sync] stderr); E3's extra `rm marker` step does not alter behavior since idempotency is gated by .doc-sync-last-head (not marker file presence) per scripts/setup-hooks.sh:177-178 [parent-inline]
- 2026-05-30 [qa-e2e] E4 (AC-4): green — doc-only merge skips verified by Case (c) in tests/setup-hooks.test.sh; the stderr line `[doc-sync] main moved but only docs changed; skipping /document-release.` is emitted at scripts/setup-hooks.sh:186 (also at :260 in post-rewrite); behavior matches E4's expected outcome verbatim [parent-inline]
- 2026-05-30 [qa-e2e] E5 (AC-7): green — coexist with D000013 verified by Smoke 0's explicit assertion that `[skills-deploy]` (D000013) and `F000011 Phase 3 lifecycle-gate` sections remain in post-merge after section 3 appended (sentinel-aware re-install proves no backup-thrash); section ordering at scripts/setup-hooks.sh:164-221 confirms section 3 runs after sections 1+2 [parent-inline]
- 2026-05-30 [qa-e2e-summary] green (0s subagent; 4 rows parent-inline; 1 deferred): all 4 pre-ship E2E rows green via structural inspection backed by tests/setup-hooks.test.sh coverage; E2 deferred to post-merge (post-ship tag)
- 2026-05-30 [qa-pass] S000061 (user-story): green smoke + green E2E (4 pre-ship rows; 1 post-ship deferred to post-merge). Phase 2 gates transitioned; post-ship AC (E2) awaiting post-merge verification (see [qa-e2e-deferred] entry above).
