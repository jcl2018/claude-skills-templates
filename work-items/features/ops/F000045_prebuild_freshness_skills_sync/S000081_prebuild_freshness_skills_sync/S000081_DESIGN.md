---
type: design
parent: S000081
title: "Pre-build base-freshness + skills-sync (Fork 1 + Fork 2 + all-3-orchestrator wiring) — Design"
version: 1
status: Draft
date: 2026-06-04
author: chjiang
reviewers: []
---

<!-- Atomic story design. Derives from the parent feature's /office-hours
     session; see parent F000045_DESIGN.md for full context. -->

## Problem

cj_goal builds on a not-recently-pulled machine start on stale local `main`
(the worktree branches off current HEAD with no fetch/ff) and with stale
installed skills (`~/.claude/skills/` lags `origin/main` until a manual pull +
install). Both cause cross-machine merge pain and silent skill drift. See parent
[F000045_DESIGN.md](../F000045_DESIGN.md#problem).

## Shape of the solution

Three coordinated pieces in one PR: (Fork 1) fail-soft fetch + `git merge
--ff-only origin/$BRANCH` inside `cj-worktree-init.sh` before `git worktree
add`; (Fork 2) a new `--phase sync` in `cj-goal-common.sh` delegating to
`post-land-sync.sh`'s guarded pull+install core, with `--dry-run` and `--no-sync`
honored; (Piece 3) wiring `--phase sync` into all three orchestrator preambles
(before the worktree block) plus the `skills-update-check` snippet for
`todo_fix`. Build-start sequence:
`update-check → --phase sync (Fork 2) → worktree phase (Fork 1 inside) → pipeline`.

## Big decisions

<!-- See parent F000045_DESIGN.md "Big decisions" for the full table.
     Story-level decisions: -->

| # | Decision | Why |
|---|----------|-----|
| 1 | Fork 1 ff is local-only and always runs; not gated by `--no-sync` | Cheap, core to the value; `--no-sync` governs only the heavy global-state install half. |
| 2 | Fork 2 reuses `post-land-sync.sh`'s guarded core rather than reimplementing pull+install | Vetted helper already resolves `.source`, guards (on-main / clean tracked tree), installs from `.source`, reports version. |
| 3 | A guard refusal / offline pull in Fork 2 is `PHASE_RESULT=skipped`, not `failed` | Same fail-soft posture as the existing `pr-check` phase — never blocks the build. |

## Risks & open questions

| Risk / Question | Next check |
|-----------------|-----------|
| Implement forgets the `scripts/test.sh` `zzz-test-scaffold` parallel edit (F000032/34/35 blind spot) | Explicit Todo + smoke row S5; QA verifies `test.sh` passes. |
| `.source == repo root` self-dev case could double-pull main | Fork 2 runs first → Fork 1 ff is a no-op; covered by the already-fresh test case. |
| Whether `--no-sync` should also suppress Fork-1 ff | RESOLVED (NO) — see parent DESIGN Big-decision #6. |

## Definition of done

<!-- See SPEC Acceptance Criteria for the Given/When/Then form. -->

- [ ] All Acceptance Criteria in `S000081_SPEC.md` pass.
- [ ] All TEST-SPEC smoke + E2E rows pass.
- [ ] `scripts/validate.sh` + `scripts/test.sh` green.

## Not in scope

- New pull/install machinery — reuse `post-land-sync.sh`.
- Per-orchestrator copy-paste — one shared implementation.
- `work-copilot/` consumers — no preamble surface.
- Suppressing Fork-1 ff under `--no-sync` — resolved non-goal.

## Pointers

- Parent design: [../F000045_DESIGN.md](../F000045_DESIGN.md)
- Parent tracker: [../F000045_TRACKER.md](../F000045_TRACKER.md)
- Spec: [S000081_SPEC.md](S000081_SPEC.md)
- Test spec: [S000081_TEST-SPEC.md](S000081_TEST-SPEC.md)
- Reused helper: `scripts/post-land-sync.sh` (F000041)
