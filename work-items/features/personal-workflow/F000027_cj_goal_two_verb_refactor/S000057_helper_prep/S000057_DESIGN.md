---
type: design
parent: S000057
title: "Helper prep — cj-worktree-init.sh --caller extension + cj-goal-common.sh + early feature smoke harness — Design"
version: 1
status: Draft
date: 2026-05-21
author: chjiang
reviewers: []
---

<!-- Atomic story under F000027. Design context comes from the parent feature's
     /office-hours session; see F000027_DESIGN.md for the cross-story picture. -->

## Problem

The two new verb skills need shared plumbing that doesn't exist yet, and one existing guard actively blocks them. `cj-worktree-init.sh` rejects unknown `--caller` values at lines 55-57 (`--caller feature|defect` → `state:failed`/`exit 1`). The common, deterministic work (worktree init, telemetry/audit-receipt write, PR-existence checks) would otherwise be duplicated as LLM-followed prose in both skills, where it drifts and can't be tested. And because the build is defect-first, the feature path would go wholly unvalidated until PR #2.

## Shape of the solution

Three foundation pieces: (1) extend the `cj-worktree-init.sh` `--caller` validator `case` + prefix map to accept `feature`→`cj-feat` and `defect`→`cj-def`; (2) add `scripts/cj-goal-common.sh`, a deterministic bash helper exposing worktree-init, telemetry write, and PR-existence checks behind explicit `--phase`/`--mode` flags; (3) add an early `feature` smoke harness that exercises the feature path shape before the `/cj_goal_feature` skill exists. See the parent [F000027_DESIGN.md](../F000027_DESIGN.md) for how this slots under the two-verb refactor.

## Big decisions

| # | Decision | Why |
|---|----------|-----|
| 1 | Common logic is deterministic bash with mode flags, not an LLM-followed doc. | Testable and drift-free; skill-tool invocations stay inline in each verb skill (Approach A). |
| 2 | Add the smoke harness now, right after the `--caller` change. | Defect-first sequencing never exercises the feature tail; this validates the riskier path before PR #2 (Approach C). |

## Risks & open questions

| Risk / Question | Next check |
|-----------------|-----------|
| Extending the `--caller` validator could regress existing callers (`cj-run`/`cj-todo`/`cj-inv`). | TEST-SPEC smoke rows assert all existing callers still resolve; `test.sh` stays green. |

## Definition of done

- [ ] `--caller feature` → `cj-feat`, `--caller defect` → `cj-def`, both exit 0.
- [ ] `cj-goal-common.sh` covers worktree/telemetry/PR-check phases under `--phase`/`--mode`.
- [ ] Early feature smoke harness runs and passes independently of S000059.

## Not in scope

- The `cj-handoff-gate.sh` `.gstack/phase2-markers.txt` writer — no longer required for `feature` (PR-stop drops the dependency). See parent DESIGN.

## Pointers

- Parent feature design: [../F000027_DESIGN.md](../F000027_DESIGN.md)
- Story tracker: [S000057_TRACKER.md](S000057_TRACKER.md)
- Story spec: [S000057_SPEC.md](S000057_SPEC.md)
