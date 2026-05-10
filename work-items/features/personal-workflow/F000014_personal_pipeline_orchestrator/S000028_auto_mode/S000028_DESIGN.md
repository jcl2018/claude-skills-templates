---
type: design
parent: S000028
title: "Auto-mode for /personal-pipeline — Design"
version: 1
status: Draft
date: 2026-05-10
author: chjiang
reviewers: []
---

<!-- Brief stub — see source design at
     ~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-claude-elegant-ptolemy-c264a2-design-20260509-184827.md
     and parent F000014's design context. This story owns the implementation
     of the --auto flag layer on top of F000014's orchestrator. -->

## Problem

`/personal-pipeline` (F000014, v1.13.0) compresses scaffold/implement/QA into
one keystroke but still requires answering 5+ AskUserQuestion gates per run on
worst-case paths (Step 4 confirm-shape, Step 5.2 sensitive-surface and
taste-fork pre-collection, Steps 6/8 gate-red, Step 9 sunset). The
orchestration labor is gone; the human-decision labor remains.

`/autoplan` (gstack) solved the same shape problem for plan reviews: read
skills at full depth but auto-decide intermediate AUQs using 6 principles,
classify each decision (Mechanical / Taste / User Challenge), and surface
only close calls at one final approval gate. This story ports that contract
to /personal-pipeline as a `--auto` flag.

## Shape of the solution

```
skills/personal-pipeline/
├── SKILL.md          # +Usage flag, +Auto Mode subsection (~30 lines added)
└── pipeline.md       # +Auto Mode Overlay section, +Step 8.5, +per-step auto-mode notes (~120 lines added)
```

Plus: `skills-catalog.json` description bump (+1 line) and README.md
regeneration via `./scripts/generate-readme.sh`. No new files; no new skill.

| Concern | Owner | Artifact |
|---------|-------|----------|
| Auto-mode logic + 6 principles + decision classification | S000028 | `pipeline.md` (Auto Mode Overlay) |
| Step 8.5 final approval gate | S000028 | `pipeline.md` (Step 8.5) |
| `$DECISION_LOG` schema + tagging | S000028 | `pipeline.md` (Auto Mode Overlay format block) |
| Flag parsing + Usage docs | S000028 | `SKILL.md` (Usage) |
| Catalog discoverability | S000028 | `skills-catalog.json` description |

## Big decisions

| # | Decision | Why |
|---|----------|-----|
| 1 | `--auto` flag on existing /personal-pipeline (Approach A) — not a separate skill | Premise 1: minimal blast radius; manual path stays byte-identical to v1.13.0; subagent-wraps-skill pattern is broken (S000026: subagents have no AUQ tool) so a wrapping skill (Approach B) is unworkable |
| 2 | Replace /autoplan's P6 (Bias toward action) with "Bias toward halt-on-doubt" | Code-mutating pipeline has higher blast radius than plan review; on Mechanical/Taste close calls with cross-callable impact, halt-and-surface beats silent auto-approve |
| 3 | Split User Challenge into Approve-with-surfacing vs Halt-at-Gate | Step 5.2 (sensitive surface) has a forward-thread decision (subagent needs an answer to proceed); Steps 5.3/6/8 (gate-red) have no forward — conflating both as one class made Step 8.5 unreachable on abort paths |
| 4 | Drop "Reject specific decisions" at Step 8.5 in v1 — Abort + manual revert only | Programmatic rollback across mid-pipeline subagent edits is fragile; user runs `git restore` after Abort with the per-decision `files_affected` list as guidance |
| 5 | `$DECISION_LOG` = single shared file `~/.gstack/analytics/personal-pipeline-auto-decisions.jsonl`, run_id-tagged | Matches existing telemetry single-file pattern; append-only; no per-run rotation in v1 |
| 6 | No chain into /ship in v1 | /ship has its own adversarial review surface; auto mode stops at "green pipeline + final gate approved"; chaining is a future call (B from D2 in source design) |
| 7 | Sunset checkpoint stays always-AUQ in both modes | Per-invocation visible by design; counts pooled across modes per F000014's existing trip-wire contract |

## Risks & open questions

| Risk / Question | Next check |
|-----------------|-----------|
| `$DECISION_LOG` value persistence depends on the model not forgetting the constant path across multi-Bash-call orchestration | Implementer: derive `$DECISION_LOG` deterministically from a constant string at Step 1 + reference it explicitly in every Auto Mode Overlay block |
| Step 5.2 sensitive-surface "auto-pick approve forward" then reject-at-8.5 leaves files mutated; user must revert manually | Smoke test E2 verifies Abort prints the `files_affected` list grouped by gate; user verifies revert manually post-test |
| Multi-User-Challenge wall-of-text at Step 8.5 if $K > 5 | If real usage hits this, file follow-up to collapse mechanical+taste into a table and expand User Challenges one-at-a-time |
| validate.sh-without-TODOS-entry carve-out (deferred to Open Q4) — v1 ships simple rule (always approve, always surface) | Revisit if real runs show sensitive-surface false-approves on validator changes |

## Definition of done

- [ ] All 11 ACs in `S000028_TRACKER.md` verified met
- [ ] Smoke tests S1-S5 pass (TEST-SPEC `## Smoke Tests`)
- [ ] E2E tests E1-E2 walked manually (TEST-SPEC `## E2E Tests`)
- [ ] `/personal-workflow check` passes on this dir + parent F000014 dir
- [ ] Manual code path of `pipeline.md` provably unchanged at the Bash-block level (spot-check diff vs v1.13.0 baseline)
- [ ] Bootstrap dogfood: run `/personal-pipeline --auto` on a real TODOS.md item end-to-end with one Step 8.5 gate (or short-circuit)

## Not in scope

- **`/personal-pipeline-auto` as a separate skill** — chose Approach A (flag) over Approach B (separate skill); separate skill violates premise 1
- **Per-user gstack-config opt-in** — chose Approach A over Approach C; deferrable layer-on-top if friction proves real
- **Auto mode + dry run** — preview decisions without applying; future flag combination
- **Programmatic rollback for partial Approve at Step 8.5** — v1 = Abort + manual revert only
- **Chain into /ship** — `/ship` is a separate user invocation; auto mode stops at "green pipeline + final gate approved"
- **Decision-log retention** — single shared file in v1, no rotation; revisit at 1MB
- **`validate.sh`-without-TODOS-entry carve-out** — deferred to Open Q4 of source design

## Pointers

- Parent tracker: [S000028_TRACKER.md](S000028_TRACKER.md)
- SPEC: [S000028_SPEC.md](S000028_SPEC.md)
- TEST-SPEC: [S000028_TEST-SPEC.md](S000028_TEST-SPEC.md)
- Parent feature tracker: [F000014_TRACKER.md](../F000014_TRACKER.md)
- Sibling: [S000027_DESIGN.md](../S000027_pipeline_skill/S000027_DESIGN.md) (the orchestrator implementation this extends)
- Sibling: [S000026_DESIGN.md](../S000026_subagent_spike/S000026_DESIGN.md) (subagent capability spike that constrained this design)
- Source /office-hours design: `~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-claude-elegant-ptolemy-c264a2-design-20260509-184827.md`
- /autoplan reference: `~/.claude/skills/gstack/autoplan/SKILL.md`
