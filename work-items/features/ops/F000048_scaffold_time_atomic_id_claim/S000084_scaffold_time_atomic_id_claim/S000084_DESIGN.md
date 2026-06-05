---
type: design
parent: S000084
title: "Scaffold-time atomic ID claim — Story Design"
version: 1
status: Draft
date: 2026-06-04
author: chjiang
reviewers: []
---

<!-- Atomic story design. Derives directly from the parent feature's
     /office-hours session; brief per-section content is fine. See the
     parent F000048_DESIGN.md for the full cross-story design. -->

## Problem

Two concurrent same-machine cj_goal worktrees both reach `/CJ_scaffold-work-item`
Step 5.1 before either has pushed, both compute the same `max(local, open-PRs,
origin)`, and both mint the same next ID. Sources 2 (open PRs) and 3
(origin/main) cannot see a sibling that has not yet pushed, so the collision is
discovered only at merge/`/ship` and recovered by hand. See parent
[F000048_DESIGN.md](../F000048_DESIGN.md#problem).

## Shape of the solution

A new helper `scripts/cj-id-claim.sh` owns a 4th ID source: an atomic claim
directory created with `mkdir "$CLAIM_ROOT/<ID>"` under
`CLAIM_ROOT="$(cd "$(git rev-parse --git-common-dir)" && pwd)/cj-id-claims"` —
the SHARED `.git` common-dir, visible to all sibling worktrees instantly. The
helper reaps dead claims (lazy: on-origin or older than TTL), reuses a live
same-branch claim for idempotency, then runs a bounded atomic claim loop. Step
5.1 of `scaffold.md` calls the helper after computing the 3-source `HIGHEST`,
with a fail-soft fallback to the current `printf` when the helper is absent. See
[S000084_SPEC.md](S000084_SPEC.md) for the full contract + algorithm.

## Big decisions

| # | Decision | Why |
|---|----------|-----|
| 1 | Engine in `scripts/cj-id-claim.sh`, not inlined in scaffold.md | Unit-testable in isolation (race/reap/prefix); engine-in-script convention. |
| 2 | `mkdir` CAS over `git update-ref` CAS | Simplest atomic primitive; mtime gives trivial TTL reaping; portable (Git-Bash/Windows-safe). |
| 3 | Absolute `CLAIM_ROOT` | A relative `--git-common-dir` would give agents with different cwd different roots and silently break the CAS. |
| 4 | Fail-soft Step 5.1 wiring | Helper-absent deploys must still mint an ID (degrade to 3-source), never break scaffold. |

## Risks & open questions

| Risk / Question | Next check |
|-----------------|-----------|
| TTL default 72h — generous but tunable via `--ttl-hours`. | Confirm at QA. |
| Reaping interleaved with a live competing claim could delete a winner. | Mitigated by the REAP INVARIANT (only on-origin or >TTL removed); covered by reap test cases. |
| Octal misread of zero-padded IDs (`000048`). | Parse with `n=$((10#$n))`, mirroring scaffold.md Step 5.1; covered by tests. |

## Definition of done

- [ ] All seven Acceptance Criteria in [S000084_SPEC.md](S000084_SPEC.md#acceptance-criteria) verified, including the looped concurrent-race test.
- [ ] `tests/cj-id-claim.test.sh` registered in `scripts/test.sh` and observably executed; validate.sh + test.sh green.

## Not in scope

- Cross-machine pre-push pre-emption — covered post-push by Sources 2+3; deferred. (See parent [F000048_DESIGN.md](../F000048_DESIGN.md#not-in-scope).)
- Proactive claim release in `/ship`/`post-land-sync.sh` — deferred; on-origin reap clears merged claims.
- Aggressive liveness/PID reaping — unnecessary; ID gaps are harmless.

## Pointers

- Parent feature design: [../F000048_DESIGN.md](../F000048_DESIGN.md)
- Parent tracker: [../F000048_TRACKER.md](../F000048_TRACKER.md)
- Story tracker: [S000084_TRACKER.md](S000084_TRACKER.md)
- Spec: [S000084_SPEC.md](S000084_SPEC.md)
- Test spec: [S000084_TEST-SPEC.md](S000084_TEST-SPEC.md)
- Source design doc: `/Users/chjiang/.gstack/projects/jcl2018-claude-skills-templates/chjiang-cj-feat-20260604-225454-7907-design-20260604-231729.md`
