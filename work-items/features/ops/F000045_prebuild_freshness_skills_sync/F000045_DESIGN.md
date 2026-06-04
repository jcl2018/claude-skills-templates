---
type: design
parent: F000045
title: "Pre-build base-freshness + skills-sync for the cj_goal entry points — Feature Design"
version: 1
status: Draft
date: 2026-06-04
author: chjiang
reviewers: []
---

<!-- A feature's cross-story design doc. Captures the PROBLEM, the SHAPE of
     the solution, the BIG DECISIONS with rationale, the RISKS, the
     DEFINITION OF DONE, and out-of-scope boundaries. Story-scope detail
     (SPEC/TEST-SPEC) lives on the nested user-stories — do
     not duplicate it here. -->

## Problem

The three `cj_goal` orchestrators (`/CJ_goal_feature`, `/CJ_goal_defect`,
`/CJ_goal_todo_fix`) are the main entry points for all build work in this
workbench. When the workbench is developed across multiple machines, a machine
that hasn't pulled recently starts a build on **stale `main`** and with **stale
installed skills**:

1. **Stale base.** `scripts/cj-worktree-init.sh` creates the build branch with
   `git worktree add "$WT_PATH" -b "$NAME"` — off current local HEAD with no
   fetch/ff first. The build proceeds on old code, then collides at ship/land.
2. **Stale skills.** The locally installed skills under `~/.claude/skills/` lag
   `origin/main` until a manual `git pull` + `skills-deploy install`. The
   existing F000009 `skills-update-check` (preamble) only reacts to a
   `collection_version` bump and is 24h-gated — it misses plain commit drift and
   doesn't guarantee a sync at build start.

This was reproduced live: the dev machine was 1 commit behind `origin/main` at
the start of the run. The value: every build across machines starts from a
known-fresh base + current skills, with zero operator ceremony, and one shared
implementation covers all three entry points.

## Shape of the solution

Approach A — three coordinated pieces, one shared implementation, carried by a
single atomic child user-story (S000081): (1) Fork-1 fast-forward of local
`main` inside `cj-worktree-init.sh` before `git worktree add`; (2) Fork-2 new
`--phase sync` in `cj-goal-common.sh` delegating to `post-land-sync.sh`'s
guarded pull+install core; (3) wiring the `--phase sync` call (plus, for
`todo_fix`, the `skills-update-check` snippet) into all three orchestrator
preambles. Sequence at build start:
`update-check → --phase sync (Fork 2) → worktree phase (Fork 1 inside) → pipeline`.

| Concern | User-story | Artifact |
|---------|-----------|----------|
| Fork 1 ff local main + Fork 2 `--phase sync` + all-3-orchestrator wiring (one cohesive change) | S000081 | [S000081_prebuild_freshness_skills_sync/S000081_TRACKER.md](S000081_prebuild_freshness_skills_sync/S000081_TRACKER.md) |

## Big decisions

<!-- Choices that shape the feature, with rationale. -->

| # | Decision | Why |
|---|----------|-----|
| 1 | Fix at the shared cj_goal entry-point path, not three separate edits | One shared implementation (`--phase sync` + the in-helper ff) covers all three entry points; no per-orchestrator copy-paste. |
| 2 | Base-freshness = fast-forward local `main` (Fork 1); warn + proceed on divergence, never halt | Preserves the "branch off main" semantics and keeps local main current. Rejected Approach C (branch off origin/main directly) — silently skips rare unpushed local main commits. |
| 3 | Skills-sync runs unconditionally at every build start from `.source` (Fork 2 strong guarantee), with `--no-sync` opt-out | Operator chose the strong guarantee over the lighter advisory path (Approach B). `--no-sync` covers the latency / global-churn concern. |
| 4 | `skills-deploy install` runs from `.source`, never the worktree | A worktree-invoked install skips foreign-owned skills (the known collection-version-stuck bug). Reuses exactly what `post-land-sync.sh` already does. |
| 5 | Reuse `post-land-sync.sh`'s guarded core; the new work is the trigger point + base-freshness, not new pull/install machinery | `skills-update-check` (F000009) and `post-land-sync.sh` already encapsulate guarded `git pull --ff-only` + install + version reporting. |
| 6 | `--no-sync` governs only the heavy install half; Fork-1 ff still runs under it | Fork-1 ff is cheap/local and core to the value; documented chosen behavior for the one Open Question. |

## Risks & open questions

<!-- What could go wrong, and what's still undecided. -->

| Risk / Question | Next check |
|-----------------|-----------|
| `skills-deploy install` adds latency + global churn to every build start | Mitigated by `--no-sync`; verified by the `--no-sync` smoke test (no install invoked). |
| Self-modification reality: a start-of-run sync updates the worktree base + the next invocation's installed skills; it cannot hot-swap the already-running orchestrator | Accepted and expected; documented in DESIGN/SPEC. No action. |
| Whether `--no-sync` should also suppress Fork-1's ff | RESOLVED: NO — Fork-1 ff is cheap/local and core to the value; `--no-sync` governs only the heavy global-state install. |
| `zzz-test-scaffold` integration fixture in `scripts/test.sh` is a recurring implement blind spot (F000032/34/35) | Pre-flighted in the SPEC + TEST-SPEC; the implement step must parallel-edit the fixture for the new phase. |

## Definition of done

<!-- Objective, measurable criteria for "shipped." -->

- [ ] Build worktree branches off `origin/main`'s tip when local `main` is behind (verified via `git merge-base --is-ancestor`).
- [ ] Diverged local `main` → warning in worktree `note`, no halt.
- [ ] Offline fetch → proceed on local main, exit 0, no operator-facing error.
- [ ] `--phase sync` installs from `.source`, reports version before→after; guard refusal → `PHASE_RESULT=skipped`.
- [ ] `--no-sync` skips install while Fork-1 ff still runs.
- [ ] All three orchestrators exhibit 1–5; `todo_fix` gains the update-check snippet.
- [ ] `scripts/validate.sh` + `scripts/test.sh` pass (new test cases + `zzz-test-scaffold` fixture update included).

## Not in scope

<!-- Explicit non-goals. -->

- Per-orchestrator copy-paste implementations — explicitly one shared implementation.
- New pull/install machinery — reuse `post-land-sync.sh`'s guarded core.
- Hot-swapping the already-in-context running orchestrator — out of reach by design (self-modification reality).
- `work-copilot/` Copilot consumers — no preamble surface (same boundary as F000009).
- Making `--no-sync` suppress the Fork-1 ff — resolved as a non-goal.

## Pointers

<!-- Cross-links to related artifacts. -->

- Parent tracker: [F000045_TRACKER.md](F000045_TRACKER.md)
- Roadmap: [F000045_ROADMAP.md](F000045_ROADMAP.md)
- Source design: `~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-cj-feat-20260604-000025-81623-design-20260604-000519.md`
- Reused helper: `scripts/post-land-sync.sh` (F000041)
- Related: F000009 (skills-update-check), F000025/F000027 (auto-worktree on main)
