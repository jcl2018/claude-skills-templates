---
type: design
parent: S000061
title: "Implement post-merge + post-rewrite doc-sync trigger block and test it end-to-end — Story Design"
version: 1
status: Draft
date: 2026-05-30
author: chjiang
reviewers: []
---

<!-- Atomic-story DESIGN.md — brief; the heavy design context lives at the
     parent feature's F000028_DESIGN.md. This stub captures the per-story
     shape just enough that /CJ_personal-workflow check passes (all 7
     standard sections required). -->

## Problem

The parent feature F000028 needs a single, coherent implementation slice: extend `scripts/setup-hooks.sh` with the doc-sync trigger block (in both `post-merge` and `post-rewrite` hooks), add a flat `tests/setup-hooks.test.sh` covering 6 scenarios, append a CLAUDE.md note, and add a CHANGELOG entry. See parent [F000028_DESIGN.md](../F000028_DESIGN.md) for the full problem framing and the reframe from "step at end of three skills" to "hook on main-moved."

## Shape of the solution

One PR with four touched files:

| Concern | File | Change Type |
|---------|------|-------------|
| Hook install (the runtime artifact) | `scripts/setup-hooks.sh` | Modified — extend `install_hook post-merge` heredoc body; add new `install_hook post-rewrite` call |
| Test coverage of the 6 scenarios | `tests/setup-hooks.test.sh` | New (flat convention, NOT a subdir) |
| Doc note to operators | `CLAUDE.md` Scripts reference table | Modified — APPEND to `setup-hooks.sh` row |
| Release note | `CHANGELOG.md` | Modified — new entry |

The trigger block body is a single shell snippet shared between both hooks (verbatim). See parent F000028_DESIGN.md for the load-bearing decisions (heredoc nesting, triviality regex anchoring, idempotency via `.doc-sync-last-head` in `--git-common-dir`).

## Big decisions

| # | Decision | Why |
|---|----------|-----|
| 1 | Single PR for all four file changes; no per-file split. | The four changes are mutually load-bearing — shipping the hook without tests is unverifiable; shipping tests without the hook fails; the CLAUDE.md note and CHANGELOG are required ship hygiene. Splitting adds review overhead with zero independent value. |
| 2 | Tests file at `tests/setup-hooks.test.sh` (flat), not `tests/setup-hooks/`. | Parent design Success Criteria explicitly call out the flat `tests/<name>.test.sh` convention. Matching the existing convention also means `./scripts/test.sh` picks it up without configuration. |
| 3 | `.doc-sync-last-head` lives at `$(git rev-parse --git-common-dir)/.doc-sync-last-head`. | `--git-common-dir` returns the parent repo's shared `.git/` even from inside a worktree. `--git-dir` would put a separate marker in each worktree, defeating cross-worktree idempotency. This repo's day-to-day work happens in worktrees (per CLAUDE.md), so this distinction is load-bearing. |

## Risks & open questions

| Risk / Question | Next check |
|-----------------|-----------|
| Test fixture setup (`tests/setup-hooks.test.sh`) needs to create a temp repo, run `./scripts/setup-hooks.sh` against it, simulate `git merge --no-ff` of a feature branch, then assert marker contents. Could be brittle if not isolated. | Use `mktemp -d` for a fresh temp dir per test row; `cd` in a subshell; clean up via `trap`. Cover the test fixture itself with a dry-run before merging. |
| Edge case (e): initial-commit fallback (empty `_LAST_SYNCED` + no `HEAD^`) is tricky to test because a "merge into the initial commit" is unusual. | Construct the fixture with a single-commit repo (no prior commits), then merge a feature branch with one commit to trigger the edge. Assert `_DIFF_BASE` resolves to the empty tree hash and the hook still writes a marker. |
| Heredoc nesting bug (DESIGN Decision #5) is silent — if quoting is flipped, the marker contains literal `$_CURRENT_HEAD` instead of the actual SHA. | Test row (a) explicitly asserts `head_sha == git rev-parse HEAD` AFTER the hook fires. Wrong quoting fails this assertion immediately. |

## Definition of done

- [ ] All Acceptance Criteria in S000061_TRACKER.md verified.
- [ ] All Acceptance Criteria in parent F000028_TRACKER.md verified.
- [ ] `/CJ_personal-workflow check work-items/features/ops/F000028_doc_sync_post_merge_hook/` returns PASS.
- [ ] `./scripts/validate.sh` returns clean.
- [ ] `./scripts/test.sh` returns clean (including the new `tests/setup-hooks.test.sh` rows).
- [ ] `/ship` opens a PR; the PR is the architecture review gate per `/cj_goal_feature`.

## Not in scope

<!-- Mirror of parent F000028_DESIGN.md "Not in scope" — story-level reiteration. -->

- Editing any of the three cj_goal skill files — design's core decision (parent F000028 Decision #1).
- Marker-pickup AUQ in cj_goal skills — separate follow-up.
- Spawning `claude --print /document-release` from the hook — rejected (parent F000028 Decision #2).
- Per-machine opt-out flag — deferred to v2.

## Pointers

<!-- Cross-links to related artifacts. -->

- Parent feature: [F000028_TRACKER.md](../F000028_TRACKER.md)
- Parent feature DESIGN: [F000028_DESIGN.md](../F000028_DESIGN.md) (the load-bearing design context lives here)
- Parent feature ROADMAP: [F000028_ROADMAP.md](../F000028_ROADMAP.md)
- Story SPEC: [S000061_SPEC.md](S000061_SPEC.md)
- Story TEST-SPEC: [S000061_TEST-SPEC.md](S000061_TEST-SPEC.md)
- Source /office-hours design doc: `~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-cj-feat-20260530-200501-31190-design-20260530-205001.md`
