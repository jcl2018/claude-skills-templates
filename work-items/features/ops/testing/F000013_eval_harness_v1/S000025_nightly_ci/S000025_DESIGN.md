---
type: design
parent: S000025
title: "Nightly CI workflow + first run validation + TODOS update — Design"
version: 1
status: Draft
date: 2026-05-09
author: chjiang
reviewers: []
---

<!-- Atomic-story DESIGN.md: keep all 7 sections, brief content per section is fine.
     For full feature-level context, see the parent F000013_DESIGN.md. -->

## Problem

S000023 ships the runner. S000024 ships the cases. Without nightly CI, the harness only runs when chjiang remembers to invoke it locally — which is approximately never under sustained development. Nightly CI on `main` is what makes the eval harness a regression signal vs. a vanity tool. The first real CI run also empirically validates the V1 success criteria (cost ≤ $1.50, wall-clock ≤ 12 min) — paper estimates only get you so far.

## Shape of the solution

A single `.github/workflows/eval-nightly.yml` workflow, cron-triggered at 09:00 UTC daily on main, also triggerable via `workflow_dispatch` for manual runs. Steps: checkout, install `claude` CLI, run `bash scripts/eval.sh`, surface PASS/FAIL count to the workflow summary. Requires `ANTHROPIC_API_KEY` repo secret (chjiang manages). Workflow has a 15-min timeout to bound runaway cost. After first manual `workflow_dispatch` run, observe cost + wall-clock and decide whether to ship V1 as-designed or open follow-ups for case cuts / tighter prompts.

## Big decisions

| # | Decision | Why |
|---|----------|-----|
| 1 | Cron at 09:00 UTC, not on push to main | Push-trigger means every commit runs evals = repeated cost on doc-only / unrelated changes. Daily cadence is enough signal at V1 case count. |
| 2 | `workflow_dispatch` enabled in V1 | Enables manual runs for debugging and verification without waiting for the next cron. Zero ongoing cost. |
| 3 | 15-minute timeout | Bounds runaway cost. Design success criterion is 12 min; 25% headroom. If actual run consistently brushes the timeout, V1 needs surgery before ship. |
| 4 | First-run observation drives V1 ship/revise decision | Paper estimates are estimates. Real numbers tell us if V1 is shippable or if scope needs cutting. |

## Risks & open questions

| Risk / Question | Next check |
|-----------------|-----------|
| `claude` CLI install method in GitHub Actions runner — `npm i -g`? Curl install script? Pre-installed in actions/setup-node? | First workflow draft — try simplest install path first, document what works in workflow comments |
| `ANTHROPIC_API_KEY` repo secret may not be set yet on this repo | Check `gh secret list` before first run; set if missing |
| First run cost may exceed $1.50 budget | Observe first run output; if > $2.25 (50% over), open follow-up before V1 ship |
| First run wall-clock may exceed 12 min | Observe; if > 18 min (50% over), open follow-up |
| Failure-notification path may be passive (just shows up in nightly run history) | V1 accepts this — nightly cadence + active monitoring is enough for a workbench. V2 can wire to email/Discord if appetite. |

## Definition of done

- [ ] `.github/workflows/eval-nightly.yml` exists, runs nightly + workflow_dispatch
- [ ] First manual run via `gh workflow run eval-nightly.yml` completes
- [ ] Cost + wall-clock from first run recorded in tracker journal
- [ ] V1 success criteria verified (cost ≤ $1.50, wall-clock ≤ 12 min) OR revised based on empirical data
- [ ] `TODOS.md` updated: eval harness DONE-V1 with link to F000013 + V2 trajectory
- [ ] Failure-notification path verified (deliberate failure on a temporary branch surfaces in workflow output)

## Not in scope

- **Spike 0 + skeleton + first case** — S000023
- **V1 case authoring** — S000024
- **Per-PR cadence** — V2 (with `paths: skills/**` filter)
- **LLM-judge for prose cases** — V2
- **Discord/email notification on failure** — V2 (nightly cadence is enough for V1)

## Pointers

- Parent feature: [../F000013_TRACKER.md](../F000013_TRACKER.md)
- Parent feature design: [../F000013_DESIGN.md](../F000013_DESIGN.md)
- Sibling stories: [../S000023_spike_and_skeleton/S000023_TRACKER.md](../S000023_spike_and_skeleton/S000023_TRACKER.md), [../S000024_v1_case_coverage/S000024_TRACKER.md](../S000024_v1_case_coverage/S000024_TRACKER.md)
- Source design doc: `~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-main-design-20260509-110013.md`
