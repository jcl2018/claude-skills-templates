---
type: design
parent: F000033
title: "USAGE.md drift detection (validate.sh Check 14) — Feature Design"
version: 1
status: Draft
date: 2026-06-01
author: chjiang
reviewers: []
---

<!-- A feature's cross-story design doc. Captures the PROBLEM, the SHAPE of
     the solution, the BIG DECISIONS with rationale, the RISKS, the
     DEFINITION OF DONE, and out-of-scope boundaries. Story-scope detail
     (SPEC/TEST-SPEC) lives on the nested user-stories — do
     not duplicate it here. -->

## Problem

F000032 (PR #186) ships per-skill `USAGE.md` as a required file class, audited for structural presence + the five required H2 sections by `scripts/validate.sh` Check 13. What Check 13 does NOT catch: USAGE.md going stale when its sibling SKILL.md changes. A SKILL.md edit that adds new behavior, renames a flag, or removes a feature can leave USAGE.md silently out of date, and Check 13 still passes.

The reasonable conversational follow-up — "will /document-release recognize these and update?" — has an honest answer: no. `/document-release` is upstream gstack; it does not know USAGE.md as a doc class. The workbench has to add the drift signal itself, and it has to do so cheaply, deterministically, and locally.

This feature closes the gap with one new validate.sh check.

## Shape of the solution

One atomic PR. Five files touched:

1. `scripts/validate.sh` — new Check 14 block (~20 lines) after current Check 13. For every routable non-deprecated skill (predicate matches Check 13), compare `git log -1 --format=%ct` on SKILL.md vs USAGE.md. ERROR when SKILL.md > USAGE.md; embed the override one-liner in the error message.
2. `CLAUDE.md` — new `### USAGE.md drift detection` subsection under `## Conventions` documenting the convention + override.
3. `doc/PHILOSOPHY.md` — extend the F000032-added `## Documentation surfaces` section with a drift-rule paragraph + audit-trail callout.
4. `scripts/test.sh` — new smoke test proving Check 14 fires on drift and the documented override clears it.
5. `CHANGELOG.md` + `VERSION` — F000033 entry, PATCH bump.

| Concern | User-story | Artifact |
|---------|-----------|----------|
| validate.sh Check 14 + CLAUDE.md + PHILOSOPHY.md + test.sh extension | S000066 | `S000066_usage_drift_check_impl/S000066_TRACKER.md` |

## Big decisions

| # | Decision | Why |
|---|----------|-----|
| 1 | Lightweight git-log-based check (Approach A) over content-aware diff (B), WARN-severity (C), or post-merge AUQ (D) | A is the smallest surface that survives the same 12-month horizon as F000032. B is ~5x complexity with heuristic tuning. C replays F000030's WARN-decay failure mode. D adds coupling to F000028's hook surface and misses in-branch drift. |
| 2 | Audit predicate `status != "deprecated"` AND non-empty `files` (matches Check 13 exactly) | Different predicate would let Check 13 + Check 14 fall out of sync. Re-use, don't fork. Same 11-skill audit set. |
| 3 | `git log -1 --format=%ct`, NOT filesystem mtimes | Commit timestamps are deterministic across worktrees, fresh clones, and CI runners. Filesystem mtimes diverge. |
| 4 | Strict `>` (not `>=`) on `%ct` comparison | Atomic SKILL.md+USAGE.md commits (F000032's backfill, brand-new skills per CLAUDE.md) share `%ct`; equal timestamps are the convention, not drift. Brand-new skills don't false-fire. |
| 5 | ERROR severity, with documented cheap operator override | F000030 + F000032 already establish ERROR + override as the workbench's load-bearing pattern. WARN replays F000030's 1/13 adoption decay. |
| 6 | Override is `last-updated:` frontmatter bump, NOT `git commit --allow-empty` | Empty commits touch no paths; `git log -1 -- <path>` only returns commits that touched the path, so empty commits don't advance `%ct`. The `last-updated:` field already exists in F000032's template + every backfilled USAGE.md — a one-line `sed` produces a real content change AND a human-readable audit trail (the date). |
| 7 | No coupling to F000028's post-merge doc-sync hook | F000028's hook is a separate surface; tying Check 14 to it would slow the validate-time signal. If post-merge surfacing becomes useful after v1, add as a follow-up. |
| 8 | SKIP (with one-line note) when `git log` returns empty (untracked / staged-only) | Check 13 owns presence; Check 14 owns freshness. "Freshness" of an uncommitted file is meaningless. Visible skip note ≠ silent pass. |

## Risks & open questions

| Risk / Question | Next check |
|-----------------|-----------|
| Stacking dependency on PR #186 — Check 14 references USAGE.md paths that only exist after #186 merges | Mitigation: PR body explicitly notes "stacked on #186; merge after #186." If #186 closes without merging, this PR rebases onto main and naturally fails to apply (fail-loud, not silent-pass). |
| Cosmetic SKILL.md edits (typo, version bump) fire Check 14 | Mitigation accepted: the documented override is cheap (one `sed` + commit, ~5 sec). Forcing the operator to acknowledge cosmetic edits IS the audit trail; users won't bypass the override silently. |
| Atomic-commit ordering through pre-commit hook | Same shape as F000032: stage Check 14 + CLAUDE.md + PHILOSOPHY.md + test.sh together in one /ship commit. Only failure mode is operator running `git commit` mid-implement on partial state. |
| Whether Check 14 should also surface via F000028 post-merge AUQ (Open Question 5) | Deferred to follow-up if validate-time signal proves insufficient. |
| README.md doesn't mention drift rule | Out of scope. PHILOSOPHY + CLAUDE.md are the documented surfaces; README regenerates from catalog. |

## Definition of done

- [ ] `scripts/validate.sh` Check 14 implements the spec above; passes for all 11 routable non-deprecated skills on this PR's HEAD (same `%ct` as F000032's atomic commit).
- [ ] `CLAUDE.md` has the new `### USAGE.md drift detection` subsection with the override one-liner.
- [ ] `doc/PHILOSOPHY.md ## Documentation surfaces` extended with a drift-rule paragraph.
- [ ] `scripts/test.sh` has the new Check 14 smoke test (fires on drift, override clears it, `git reset --hard` cleans up).
- [ ] `./scripts/validate.sh` exits 0 with 0 errors / 0 warnings.
- [ ] `./scripts/test.sh` exits 0 (full suite).
- [ ] CHANGELOG entry in user-forward voice; VERSION bumped PATCH.
- [ ] PR opened against `cj-feat-20260601-152835-3769` (NOT main).

## Not in scope

- README.md per-skill drift-status column — deferred; needs catalog + script changes.
- work-copilot/ analog drift check — workbench-only scope.
- Surfacing drift via F000028 post-merge doc-sync hook — Open Question 5, deferred.
- Upstream `/document-release` modification — not ours to modify.
- Distinguishing "real" SKILL.md changes from cosmetic edits — would require heuristic (see Approach B); the override is the audit trail.
- Per-skill snooze of Check 14 — single global ERROR is sufficient.

## Pointers

- Parent tracker: [F000033_TRACKER.md](F000033_TRACKER.md)
- Roadmap: [F000033_ROADMAP.md](F000033_ROADMAP.md)
- Child story: [S000066_usage_drift_check_impl/S000066_TRACKER.md](S000066_usage_drift_check_impl/S000066_TRACKER.md)
- Source design: `~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-cj-feat-20260601-162235-stack186-design-20260601-162450.md`
- Stacked on: PR #186 (F000032 / S000065 / branch `cj-feat-20260601-152835-3769`) — must merge first.
- F000030 (PR #180, v5.0.11) — established the ERROR + documented-override pattern; this feature reuses it.
- F000032 (PR #186, OPEN) — introduced USAGE.md + Check 13 (presence + structure); this feature pairs symmetrically as Check 14 (freshness).
