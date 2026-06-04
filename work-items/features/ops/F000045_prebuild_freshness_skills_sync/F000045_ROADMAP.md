---
type: roadmap
parent: F000045
title: "Pre-build base-freshness + skills-sync for the cj_goal entry points — Roadmap"
date: 2026-06-04
author: chjiang
status: Draft
---

<!-- A feature's roll-up roadmap. Captures scope/non-goals, decomposition,
     and delivery timeline. -->

## Scope

Add a built-in pre-build guard at the three `cj_goal` entry points so every
build across machines starts from a known-fresh base (`main` fast-forwarded to
`origin/main` at worktree-creation time) and current installed skills
(`skills-deploy install` from `.source` at build start). One shared
implementation — an in-helper ff plus a new `--phase sync` — covers
`/CJ_goal_feature`, `/CJ_goal_defect`, and `/CJ_goal_todo_fix`. Both halves are
fail-soft (offline never blocks a build) and the heavy install half is
opt-out-able via `--no-sync`.

## Non-Goals

- Per-orchestrator copy-paste implementations — one shared implementation only.
- New pull/install machinery — reuse `post-land-sync.sh`'s guarded core.
- Hot-swapping the already-in-context running orchestrator — out of reach by design.
- `work-copilot/` Copilot consumers — no preamble surface.
- Making `--no-sync` suppress the Fork-1 ff — resolved as a non-goal.

## Success Criteria

<!-- Bulleted, measurable outcomes observable from the outside. -->

- [ ] On a behind-`origin/main` machine, the build worktree base is `origin/main`'s tip (`git merge-base --is-ancestor origin/main <worktree-base>` true).
- [ ] Diverged local `main` → warning in the worktree `note`; build proceeds (no halt).
- [ ] Offline fetch → build proceeds on local main, exit 0, no operator-facing error.
- [ ] `--phase sync` installs from `.source`, reports `collection_version` before→after; guard refusal → `PHASE_RESULT=skipped` (not `failed`).
- [ ] `--no-sync` skips the install phase while Fork-1 ff still runs.
- [ ] All three orchestrators exhibit the above; `todo_fix` gains the update-check snippet.
- [ ] `scripts/validate.sh` + `scripts/test.sh` pass (new `cj-worktree-init.test.sh` cases + `zzz-test-scaffold` fixture update included).

## Decomposition

<!-- The user-stories that decompose this feature. -->

| User-Story | Title | Status |
|-----------|-------|--------|
| [S000081](S000081_prebuild_freshness_skills_sync/S000081_TRACKER.md) | Pre-build base-freshness + skills-sync (Fork 1 + Fork 2 + all-3-orchestrator wiring) | Open |

## Delivery Timeline

<!-- Forward-looking milestones. -->

| # | Milestone | Target Date | Status | Owner | Notes | Blocked By |
|---|-----------|-------------|--------|-------|-------|------------|
| 1 | Ship S000081 (Fork 1 ff + Fork 2 sync phase + all-3-orchestrator wiring + tests) | — | Not Started | chjiang | Single atomic story carries all three pieces | — |
| 2 | End-to-end pipeline run (build from a behind-origin machine lands on fresh base + synced skills) | — | Not Started | chjiang | Verifies the feature value end-to-end | #1 |

### Delivery History

<!-- Backward-looking record: PR links, merge dates, version bumps after ship. -->

- 2026-06-04: Created — scaffolded from /office-hours design doc.

## Dependency Graph

<!-- Visual representation of milestone ordering. -->

```
#1 Ship S000081 (ff + sync phase + wiring + tests) --> #2 End-to-end pipeline run
```

## Open Questions

<!-- Questions still being decided. -->

| Question | Next check |
|----------|-----------|
| Should `--no-sync` also suppress Fork-1's ff? | RESOLVED (NO) — documented in DESIGN Big-decision #6; no further check needed. |
