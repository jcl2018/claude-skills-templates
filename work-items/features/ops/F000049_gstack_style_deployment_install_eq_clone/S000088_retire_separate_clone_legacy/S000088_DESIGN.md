---
type: design
parent: S000088
title: "Retire the separate-clone legacy (drop runtime .source, declare install==clone-in-place) — Story Design"
version: 1
status: Draft
date: 2026-06-05
author: chjiang
reviewers: []
---

<!-- Atomic story: brief stub. The full S4 design (the de-risking finding + the
     D1/D2/D3 calls + the safe staging) lives in the /office-hours doc + the
     parent design — see Pointers. -->

## Problem

F000049's S4 = "drop `.source` + retire the worktree/`post-land-sync` machinery +
flip `--bundle` to default." This is the subtractive close-out that retires the
machinery every `cj_goal` run (incl. the four that landed S1–S3) uses. The
de-risking finding makes it safe: the live manifest's `source` already EQUALS the
dev checkout (`install_mode: null`), so install==clone is reachable **in place** —
no relocation.

## Shape of the solution

Three moves, in an i1→i2 order with a green checkpoint between:

1. **Declare** install==clone-in-place: the default `skills-deploy install` stamps
   `install_mode: in-place` + `bundle_path` = the checkout (it already records
   `source` = the checkout — this just makes the install==clone nature explicit).
2. **Drop** the runtime `.source` reach-backs: the 4 orchestrators resolve
   `cj-goal-common.sh` 2-tier (repo-local → `_cj-shared`, no `.source` elif); all
   10 `.source`-reaching skills resolve the passive update-check from `_cj-shared`.
3. **Reframe** (not delete) the sync helpers to the in-place checkout.

| Concern | User-story | Artifact |
|---------|-----------|----------|
| Retire the separate-clone legacy (declare in-place + drop `.source` + reframe sync) | S000088 | S000088_SPEC.md / S000088_TEST-SPEC.md |

## Big decisions

| # | Decision | Why |
|---|----------|-----|
| 1 | D1-B: declare the EXISTING checkout install==clone (in place); do not relocate | `source` already == the checkout; relocation is needless for a single-dev workbench |
| 2 | "Flip `--bundle` to default" = the default IS install==clone-in-place; `--bundle` stays the consumer bootstrap | Forcing relocation contradicts D1-B; the default already symlinks from its checkout |
| 3 | "Retire `post-land-sync`/`--phase sync`" = REFRAME, not delete | `gh pr merge` is REMOTE; the in-place checkout still needs a post-merge `git pull` |
| 4 | D2: keep the `cj-feat-*` worktree flow | Worktrees are the parallel-build isolation primitive; "develop in place" replaces the `.source` reach, not worktrees |

## Risks & open questions

| Risk / Question | Next check |
|-----------------|-----------|
| Operator expected the literal full deletion from "build full S4" | The SPEC Tradeoffs + PR state the reframe explicitly; PR review is the check |
| `_cj-shared` absent on a pre-S1 install | Fail-soft: orchestrators WARN + proceed; the nudge no-ops (P1 #6) |
| Reinstall-free pull for NEW files (dir-symlinks) | S5 — entangled with Windows copy-mode |

## Definition of done

- [ ] Default install stamps `install_mode: in-place` + `bundle_path`
- [ ] 4 orchestrators: no `.source` cj-goal-common tier; 10 skills: update-check resolves from `_cj-shared`
- [ ] `/CJ_portability-audit` family local-only, no `.source`-reachback finding; `bundle-status` recognizes `in-place`
- [ ] Sync helpers reframed (not deleted); worktrees kept; docs updated
- [ ] Hermetic S000088 test; `validate.sh` + `scripts/test.sh` green; shellcheck clean

## Not in scope

- Deleting `post-land-sync` / `--phase sync` (unsafe under remote-merge in-place) — reframed instead
- Dir-level skill symlinks for reinstall-free pull of NEW files — S5
- Windows/Git-Bash copy-mode parity — S5

## Pointers

- /office-hours S4 design (full + the de-risking finding + D1/D2/D3): `.gstack/gstack-s4-retire-legacy-design-20260605.md`
- Parent feature design: [../F000049_DESIGN.md](../F000049_DESIGN.md)
- S3 (landed): [../S000087_develop_in_place/S000087_TRACKER.md](../S000087_develop_in_place/S000087_TRACKER.md) — the develop-in-place enablement this completes
