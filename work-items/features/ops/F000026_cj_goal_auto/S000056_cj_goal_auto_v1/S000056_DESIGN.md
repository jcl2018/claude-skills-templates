---
type: design
parent: S000056
title: "v1.0 full-handoff one-liner-to-deployed skill — User-Story Design"
version: 1
status: Draft
date: 2026-05-19
author: chjiang
reviewers: []
---

<!-- Atomic story design. Brief stub by design; the parent feature
     DESIGN at ../F000026_DESIGN.md carries the full cross-story
     rationale. -->

## Problem

The autonomous-path mechanics (worktree + classifier + workbench-owned generator + post-condition gate + invoke `/CJ_goal_run --handoff --no-drain` + deterministic merge gate + deploy) all live in a single user-story because v1 is single-PR by design. There is no cross-story coordination to spread across multiple stories. This story is the entire v1.0 surface.

See `../F000026_DESIGN.md` for the full problem framing, F000021 autonomy ceiling exception rationale, and corrected-P4 / D9-A reasoning.

## Shape of the solution

A new experimental skill `skills/CJ_goal_auto/{SKILL.md, auto.md}` + a deterministic helper `scripts/cj-handoff-gate.sh` + targeted edits to `skills/CJ_goal_run/run.md` (the `--handoff` / `--no-drain` / co-located sentinel + the post-`/ship`/pre-`/land-and-deploy` gate call) + `skills/CJ_goal_auto/**` catalog entry + routing rule + `scripts/test.sh` tests + VERSION + CHANGELOG.

Five stages, plus a denylist as load-bearing safety control:

1. Stage 0 — worktree (F000025 pattern) + version-queue preflight + `--handoff` capability self-check (sentinel grep, fail-closed).
2. Stage 0.5 — orchestrator-owned scope classifier (`small-unambiguous` only proceeds).
3. Stage 1 — workbench-owned design-doc generator from fixed template.
4. Stage 1.5 — fail-closed post-condition doc gate.
5. Stage 2 — `/CJ_goal_run <doc> --handoff --no-drain` → Phase 3 `/ship` (PR-prep) → `scripts/cj-handoff-gate.sh` (orchestrator-owned merge gate) → Phase 4 `/land-and-deploy` (merge).
6. Stage 3 — Deploy; PR body carries audit line + pinned BASE SHA.

## Big decisions

| # | Decision | Why |
|---|----------|-----|
| 1 | Single user-story (atomic story) | Design constrains v1 to single-PR changes only; no cross-story coordination needed. |
| 2 | Deterministic helper extracted to `scripts/cj-handoff-gate.sh` | Unit-testable in `scripts/test.sh` without LLM judgment in the merge gate (Eng F5). The eval.sh harness is scoped to structured-report skills and can't drive Write/Edit/Skill/Agent — wrong tool for this. |
| 3 | Sentinel co-located with the gate call in `run.md` (asserted within N lines by test 9) | Proof-of-support and behavior drift together (Eng F3). |

## Risks & open questions

| Risk / Question | Next check |
|-----------------|-----------|
| `/investigate`-style FIX_PLAN preamble for pre-fix blast-radius detection | Out of v1 scope; revisit if Stage 0.5 classifier proves insufficient. See parent DESIGN. |
| `gh` rate limits when `--audit`/`--list-handoffs` pages through historic PRs | Cap `--list-handoffs` to last 10 entries by default; jsonl is local-first so no `gh` round-trip required for the receipt itself. |

## Definition of done

- [ ] All Acceptance Criteria in `S000056_TRACKER.md` pass.
- [ ] All 11 tests in `scripts/test.sh` (added by this story) pass locally and in CI.
- [ ] `validate.sh` green; catalog + routing + VERSION + CHANGELOG present.
- [ ] One real-small-item dogfood run completes end-to-end with the audit receipt written and the PR body line present.

## Not in scope

- Multi-story / multi-PR auto-iterate, GATE #1 auto-approve, headless office-hours, Approach C, atomic VERSION slot, Copilot bundle portability — all deferred per parent DESIGN.
- An automated ground-truth oracle for classifier false-negatives — bounded by every-5th retro AUQ + size cap + denylist (parent DESIGN Risk row).

## Pointers

- Parent tracker: [../F000026_TRACKER.md](../F000026_TRACKER.md)
- Parent design: [../F000026_DESIGN.md](../F000026_DESIGN.md)
- Parent roadmap: [../F000026_ROADMAP.md](../F000026_ROADMAP.md)
- /office-hours design: `~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-claude-flamboyant-johnson-c3d0e5-design-20260517-125333.md`
- Sibling skills: `/CJ_goal_run`, `/CJ_goal_todo_fix`, `/CJ_goal_investigate`
- F000025 worktree helper: `scripts/cj-worktree-init.sh`
