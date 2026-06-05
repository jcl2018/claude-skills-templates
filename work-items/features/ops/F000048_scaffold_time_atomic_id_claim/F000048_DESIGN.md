---
type: design
parent: F000048
title: "Scaffold-time atomic F-ID claim (close the pre-push collision race) — Feature Design"
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
     not duplicate it here. For a filled-in example, see
     `work-items/features/F000004_work_copilot/F000004_DESIGN.md`. -->

## Problem

When multiple cj_goal agents run concurrently on one repo (the common case:
several Conductor/Claude sessions, each in its own git worktree of the same
clone), they collide on the next work-item ID. Two agents both reach
`/CJ_scaffold-work-item` Step 5.1, both compute `max(local, open-PRs, origin) =
F000047`, and both mint `F000048`. The collision is only discovered at
merge/`/ship` time and is recovered manually ("renumber after merge"). A retro
counted ~4 cj_goal runs hit by this. The existing 3-source check already catches
a sibling that has pushed+opened a PR (Source 2) and a sibling that has merged
(Source 3); the one window it structurally cannot see is two worktrees both at
scaffold time with neither pushed yet — the scaffold-before-push race.

## Shape of the solution

Add a **4th ID source: an atomic claim in the shared `.git` common-dir**, made
at scaffold time before any PR. A new helper `scripts/cj-id-claim.sh` owns the
atomic claim loop + lazy reaping; `skills/CJ_scaffold-work-item/scaffold.md`
Step 5.1 calls it (with a fail-soft fallback to the current 3-source behavior
when the helper is absent). The atomic create is the lock:
`mkdir "$(git rev-parse --git-common-dir)/cj-id-claims/<ID>"` fails if a sibling
already holds it. The whole feature is a single atomic user-story.

| Concern | User-story | Artifact |
|---------|-----------|----------|
| Claim engine + Step 5.1 wiring + tests | S000084 | [S000084_scaffold_time_atomic_id_claim/S000084_TRACKER.md](S000084_scaffold_time_atomic_id_claim/S000084_TRACKER.md) |

## Big decisions

<!-- Choices that shape the feature, with rationale. Future readers need
     to know why this path over the rejected alternatives. -->

| # | Decision | Why |
|---|----------|-----|
| 1 | Approach A — helper script + `mkdir` CAS | Simplest atomic compare-and-swap; trivial inspection/reaping via dir mtime; unit-testable in isolation (race, reap, prefix isolation). Reuses the engine-in-script convention (`cj-worktree-init.sh`, `check-version-queue.sh`, `cj-goal-common.sh`) and portable `mkdir` (Git-Bash/Windows-safe). |
| 2 | Rejected B (`git update-ref` CAS) | git-native + forward-compatible with cross-machine, but needs an object to point at, ref cleanup, and TTL/reaping needs ref-date plumbing (no clean mtime) — more arcane for zero v1 benefit. |
| 3 | Rejected C (inline in scaffold.md) | Smallest diff, but the tricky atomic+reaping logic would live in a skill `.md`, exercisable only through the whole scaffold skill — NOT unit-testable; violates engine-in-script. |
| 4 | v1 scope = same-machine / same-clone (shared `.git`) only | Matches the fix to the actual failure (worktrees sharing one `.git`). Cross-machine pre-push is not regressed (covered post-push by Sources 2+3), just not pre-empted. |
| 5 | Lazy, conservative reaping (TTL or on-origin) | ID gaps are harmless — a stale claim costs at most a skipped number, never a wrong/duplicate ID. No aggressive liveness detection needed. |

## Risks & open questions

<!-- What could go wrong, and what's still undecided. Each row should
     have a "Next check" naming who/when resolves it — otherwise it
     will rot. -->

| Risk / Question | Next check |
|-----------------|-----------|
| TTL value — 72h proposed (generous; a build rarely runs longer). Tunable via `--ttl-hours`. | Confirm at QA. |
| `/ship` / post-land proactive reap — on merge the next run's on-origin reap clears the claim, so explicit release isn't required; a proactive reap is a nice-to-have. | Deferred; revisit if stale claims accumulate. |
| `git rev-parse --git-common-dir` may return a relative path → two agents with different cwd get different claim roots and the CAS silently breaks. | Mitigated in design: normalize to ABSOLUTE (`cd "$(...)" && pwd`); covered by test case (7) worktree-resolution. |

## Definition of done

<!-- Objective, measurable criteria for "shipped." Not aspirations. A
     reviewer should be able to verify each item without asking the
     author. -->

- [ ] Two concurrent `cj-id-claim.sh` invocations with the same floor return distinct IDs every round of a 20+ round loop.
- [ ] A claim whose ID is on origin/main, or older than the TTL, is reaped and not counted.
- [ ] Scaffold re-run on the same branch (pre-completion) keeps its ID (idempotent).
- [ ] Helper-absent fallback still mints an ID (scaffold never breaks).
- [ ] `tests/cj-id-claim.test.sh` is explicitly registered in `scripts/test.sh` and observably executed; validate.sh + test.sh green.

## Not in scope

<!-- Explicit non-goals. Prevents scope creep and gives reviewers an
     unambiguous boundary. -->

- Cross-machine pre-push pre-emption (two different clones, neither pushed) — stays covered post-push by Sources 2+3, not pre-empted. Deferred to a future v2.
- Aggressive liveness detection / PID-liveness reaping — unnecessary because ID gaps are harmless; lazy TTL + on-origin reaping suffices.
- Proactive claim release in `/ship` or `post-land-sync.sh` — nice-to-have; the next run's on-origin reap clears merged claims.
- A broad version+ID rework — the VERSION half already has `check-version-queue.sh`; this feature is scoped to the F-ID race only.

## Pointers

<!-- Cross-links to related artifacts: parent tracker, roadmap,
     upstream sources, related features/defects. Use relative paths
     from the feature directory. -->

- Parent tracker: [F000048_TRACKER.md](F000048_TRACKER.md)
- Roadmap: [F000048_ROADMAP.md](F000048_ROADMAP.md)
- Source design doc: `/Users/chjiang/.gstack/projects/jcl2018-claude-skills-templates/chjiang-cj-feat-20260604-225454-7907-design-20260604-231729.md`
- Related: `scripts/check-version-queue.sh` (the VERSION-slot analogue), `skills/CJ_scaffold-work-item/scaffold.md` Step 5.1 (the existing 3-source check)
