---
name: "post-land-sync helper + CLAUDE.md docs + test wiring"
type: user-story
id: "S000074"
status: active
created: "2026-06-03"
updated: "2026-06-03"
parent: "F000041"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "cj-feat-20260603-180257-28011"
blocked_by: ""
---

<!-- Prerequisite: Before scaffolding this work item, run /office-hours to
     produce a design plan in ~/.gstack/projects/. Distill that plan into
     DESIGN.md during Phase 1 below. (For atomic stories that derive directly
     from the parent feature's /office-hours session, the parent's design is
     sufficient context — DESIGN.md may be a brief stub linking to the parent.) -->

## Lifecycle

### Phase 1: Track

1. Read parent tracker to understand scope
2. Create working branch: `git checkout -b feat/post_land_sync` (or use parent's branch if shipping in same PR)
3. Scaffold work item directory and TRACKER.md
4. Distill `DESIGN.md` from the /office-hours output (own session or parent's) — from `templates/doc-DESIGN.md`
5. Scaffold `SPEC.md` (requirements, acceptance criteria, architecture, tradeoffs) — from `templates/doc-SPEC.md`
6. Scaffold `TEST-SPEC.md` (smoke + E2E test scenarios) — from `templates/doc-TEST-SPEC.md`
7. Break into child tasks if scope warrants decomposition (per WORKFLOW.md, tasks are optional for atomic stories)

**Gates:**
- [x] /office-hours design referenced (own or parent's, captured in DESIGN.md)
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
4. Ensure all child tasks (if any) have shipped
5. Run `/ship` — creates PR, bumps version, updates changelog (includes pre-landing code review)
6. Run `/land-and-deploy` — merges PR and verifies deployment

❌ If `/CJ_personal-workflow check` finds issues: fix findings, re-run until clean
❌ If smoke or E2E fails: fix, re-run

**Gates:**
- [ ] `/CJ_personal-workflow check` — validation passed
- [ ] Smoke tests pass in CI
- [ ] E2E walked manually
- [ ] All children shipped (if any)
- [ ] `/ship` — PR created (with pre-landing review)
- [ ] `/land-and-deploy` — merged and deployed

## Acceptance Criteria

<!-- What "done" looks like for this story. -->

- [ ] `scripts/post-land-sync.sh --dry-run` resolves `.source`, prints the would-run `git pull --ff-only` + `skills-deploy install` + current collection_version, and mutates nothing.
- [ ] Real run performs `git -C <.source> pull --ff-only` + `<.source>/scripts/skills-deploy install` and prints collection_version before→after.
- [ ] Helper guards a missing / non-main / dirty `.source` — warns + exits non-zero without pulling or installing.
- [ ] `tests/post-land-sync.test.sh` exists, exercises resolution + guards + `--dry-run` (no real `~/.claude` mutation), and is wired into `scripts/test.sh`.
- [ ] `CLAUDE.md` "CI/CD merge convention" documents the post-merge step (a), the bypass reason (b), and the drift note (c).

## Todos

<!-- Actionable items for this story. -->

- [x] Write `scripts/post-land-sync.sh` (`#!/usr/bin/env bash` + `set -euo pipefail`; resolve `.source`; guards; pull; install; before→after version report; `--dry-run`).
- [x] Edit `CLAUDE.md` "CI/CD merge convention" — post-merge step + bypass subsection + drift note.
- [x] Write `tests/post-land-sync.test.sh` (resolution + guards + `--dry-run` via temp fixture; never mutate real `~/.claude`).
- [x] Wire `tests/post-land-sync.test.sh` into `scripts/test.sh`.

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-06-03: Created. Single child of F000041 — carries the helper + docs + test implementation surface.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. -->

- `scripts/post-land-sync.sh` (NEW)
- `CLAUDE.md` (EDIT — CI/CD merge convention)
- `tests/post-land-sync.test.sh` (NEW)
- `scripts/test.sh` (EDIT — wire new test)

## Insights

<!-- Non-obvious findings worth remembering. -->

- Every new `scripts/*.test.sh` must be wired into `scripts/test.sh` to actually run — a test file alone is invisible to the suite. This is a known repeat blind spot for the implement phase; the TEST-SPEC pins the wiring as its own row.
- The helper's value is collapsing two operator actions (post-merge install + drift reconciliation) into one correct command; the guards are what make an unattended re-run safe.

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

- [decision] Summary: This atomic story carries the entire F000041 implementation surface (helper + docs + test + wiring); no further task-level decomposition — the four Components Affected map cleanly to four todos.
- 2026-06-03 [impl-decision] Test isolation via temp fixture + POST_LAND_SYNC_MANIFEST env override (per SPEC Tradeoffs "Test isolation" row): the helper reads its manifest path from `POST_LAND_SYNC_MANIFEST` (default `~/.claude/.skills-templates.json`), so the test points it at a throwaway temp manifest whose `.source` is a temp git repo. Combined with `--dry-run`, the test exercises resolution + all four guards with zero real `~/.claude` mutation.
- 2026-06-03 [impl-decision] Dirty-tree guard uses `git status --porcelain --untracked-files=no` so untracked scratch files in `.source` do NOT block the sync (per SPEC: "Untracked files are OK"); only tracked changes refuse. Guards exit 2 (distinct from exit 1 = bad invocation) with a per-guard named message.
- 2026-06-03 [impl-finding] Sensitive surface: SPEC Components Affected names `scripts/test.sh` (a validator per implement.md Step 6.4). Under default propose-mode this would trigger a Step 7 AUQ and demote `--auto`. This run is dispatched by /CJ_goal_feature's silent build where the enumerated sensitive-surface edit (scripts/test.sh) is PRE-AUTHORIZED by the operator's design-approval gate — proceeded without AUQ per the runner contract; CLAUDE.md is also a core doc, edited within the pre-authorized surface. No edits made outside the enumerated surface.
- 2026-06-03 [impl-finding] skills-deploy install must run FROM `.source` (the main checkout), not from a worktree — a worktree-invoked install skips foreign-owned skills (known workbench lesson). The helper wraps the install in `( cd "$SRC" && "$SRC/scripts/skills-deploy" install )`.
- 2026-06-03 [impl] Wrote 2 files (scripts/post-land-sync.sh, tests/post-land-sync.test.sh); modified 2 (CLAUDE.md "CI/CD merge convention", scripts/test.sh wiring). Both new .sh files chmod +x. Test passes 14/14 assertions; real ~/.claude collection_version unchanged (6.0.8).
- 2026-06-03 [impl-auto] --auto requested; demoted to propose-equivalent by the sensitive-surface override (scripts/test.sh + CLAUDE.md), but the silent-build runner contract pre-authorizes these enumerated edits, so writes proceeded without an interactive gate.
- 2026-06-03 [impl-pass] S000074: implementation complete. Phase 2 implementer-owned gates transitioned.
- 2026-06-03 [qa-smoke] S1 (AC-1): green — `tests/post-land-sync.test.sh` dry-run case (temp fixture) exits 0; resolves `.source`, prints would-run pull/install + collection_version, mutates nothing.
- 2026-06-03 [qa-smoke] S2 (AC-3): green — guard cases (missing/non-main/dirty/non-git `.source`) each exit non-zero (2) with a named GUARD-FAILED message; no pull/install; untracked-only files do NOT trip the dirty guard.
- 2026-06-03 [qa-smoke] S3 (AC-2): green — `--dry-run` echoes the real-run command shape: `git -C <.source> pull --ff-only` + `<.source>/scripts/skills-deploy install` with a before-version read; asserted via dry-run output, no real mutation.
- 2026-06-03 [qa-smoke] S4 (AC-4): green — `grep -q 'post-land-sync.sh' CLAUDE.md && grep -qi 'bypass' CLAUDE.md` both match; CLAUDE.md "CI/CD merge convention" documents the post-merge step (a), the bypass-reason (b), and the drift note (c).
- 2026-06-03 [qa-smoke] S5 (AC-5): green — `grep -q 'post-land-sync.test.sh' scripts/test.sh` matches; test is wired into the suite (lines 1248-1253).
- 2026-06-03 [qa-smoke-summary] green: 5/5 non-manual rows green (0 manual rows pending). Standalone `bash tests/post-land-sync.test.sh` = RESULT: PASS (14/14 assertions, real-manifest backstop confirms 6.0.8 unchanged).
- 2026-06-03 [qa-e2e-run-start] RUN_ID=20260603-183605-80249 commit=677dfeb
- 2026-06-03 [qa-e2e] E1 (AC-1): green — ran `./scripts/post-land-sync.sh --dry-run` against the real manifest; output printed resolved `.source` (/Users/chjiang/Documents/projects/claude-skills-templates), both would-run commands (pull --ff-only + skills-deploy install from .source), and collection_version 6.0.8; `.source` HEAD unchanged (677dfeb→677dfeb), nothing mutated. [parent-inline]
- 2026-06-03 [qa-e2e] E2 (AC-2): green (dry-run-verified) — the real 6.0.8→6.0.10 dogfood reconciliation was NOT run for real per the QA contract (a real run mutates ~/.claude); verified via `--dry-run` that the helper WOULD do the right thing: guards pass on clean main, prints before-version 6.0.8, and would execute `git -C <.source> pull --ff-only` then `skills-deploy install` from `.source` — exactly the path that brings the manifest to `.source`'s VERSION and prints before→after. Real run is a deliberate post-ship operator step. [parent-inline]
- 2026-06-03 [qa-e2e] E3 (AC-5): green — ran `./scripts/test.sh`; suite RESULT: PASS (0 failures); `tests/post-land-sync.test.sh` ran (line 916) and passed (line 917) inside the suite. [parent-inline]
- 2026-06-03 [qa-e2e-summary] green (0s subagent; 3 rows parent-inline; 0 deferred): all 3 E2E criteria green (E2 dry-run-verified — real 6.0.8→6.0.10 dogfood deferred to post-ship operator step per QA contract). No subagent dispatched; all rows ran parent-inline by the QA runner.
- 2026-06-03 [qa-pass] S000074 (user-story): green smoke + green E2E. Phase 2 gates transitioned. (E2 verified via --dry-run only — the real ~/.claude reconciliation is a post-ship operator step; real collection_version left at 6.0.8.)
