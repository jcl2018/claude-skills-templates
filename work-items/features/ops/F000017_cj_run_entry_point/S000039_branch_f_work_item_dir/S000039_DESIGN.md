---
type: design
parent: S000039
title: "Branch(f) work-item-dir — Story Design"
version: 1
status: Draft
date: 2026-05-13
author: chjiang
reviewers: []
---

## Problem

Even after rename + Branch(g) (S000038), the user can't say "resume this specific
work-item dir" — they would have to fall through to Branch(g)'s scan and pray
the candidate matches. Branch(f) gives `/CJ_run` a direct work-item-dir input:
pass a path, get the right sub-pipeline dispatched based on phase state.

This is also what Branch(g) dispatches to internally after picking a candidate.
So Branch(f) is the workhorse and Branch(g) is the smart picker on top of it.

## Shape of the solution

One new code path in `run.md` Step 1, plus a dispatch helper. Reads:
- `IMPL_GATE` from TRACKER (Phase 2 impl gate string check)
- `QA_GATE` from TRACKER (Phase 2 QA gate string check)
- `PR_URL` from TRACKER frontmatter `pr:` field

Picks a MODE from `{impl_qa_ship, qa_ship, ship, open_pr, already_shipped, pr_unknown_state}`.
Dispatches accordingly.

## Big decisions

| # | Decision | Why |
|---|----------|-----|
| 1 | Branch(g) calls into Branch(f) after selection | DRY — phase detection lives in one place |
| 2 | Six MODE values (not three) | Real states need distinct handling: open PR vs merged PR vs unknown state all behave differently |
| 3 | Verbatim gate strings (not regex) | Canonical from `tracker-user-story.md`; exact match is the safest contract |
| 4 | `gh pr view` for PR state with UNKNOWN fallback | Best-effort: works online, doesn't block offline |
| 5 | `pr_unknown_state` AUQ instead of auto-decide | When gh returns a state we don't expect (CLOSED-without-merge, DRAFT_DELETED, etc.), defer to user |
| 6 | `blocked_by: F000016` even though only impl_qa_ship needs it | Cohesion: one story, one ship; partial-ship is documented as the fallback if F000016 slips |

## Risks & open questions

| Risk / Question | Next check |
|-----------------|-----------|
| Gate strings change in template upgrade | Add a smoke test that greps for the canonical strings in the template; alert on drift |
| `gh` not authenticated or rate-limited | Fall back gracefully; mode resolution should not require network |
| Concurrent /CJ_run invocations on same work-item-dir | Idempotency is sub-skill's responsibility; not Branch(f)'s concern |
| `PR_URL` field naming inconsistent across templates | Check both `pr:` and `PR:` (case-insensitive); document in code |

## Definition of done

- [ ] Branch(f) detection works for all six MODE values
- [ ] Test corpus covers each mode (smoke tests)
- [ ] Branch(g) → Branch(f) integration tested (S000038 dependency)
- [ ] `gh` offline path tested (graceful degradation)
- [ ] AC #5 (Branch(g) integration) verified after S000038 lands

## Not in scope

- Defect/task TRACKER support — different gate strings, deferred to v0.3
- Rollback of merged PRs — out of scope
- Parallel multi-item dispatch (`--all` flag) — deferred to v0.3
- Cross-branch work-item-dir handling — current worktree only

## Pointers

- Parent tracker: [S000039_TRACKER.md](S000039_TRACKER.md)
- Parent feature: [../F000017_DESIGN.md](../F000017_DESIGN.md)
- SPEC: [S000039_SPEC.md](S000039_SPEC.md)
- TEST-SPEC: [S000039_TEST-SPEC.md](S000039_TEST-SPEC.md)
- Blocker: [../../F000016_ship_feature_multi_story_auto_iterate/F000016_TRACKER.md](../../F000016_ship_feature_multi_story_auto_iterate/F000016_TRACKER.md) (S000036 specifically)
- Source design: `~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-claude-awesome-pasteur-36565c-design-20260513-154622.md`
