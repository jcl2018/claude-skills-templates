---
type: roadmap
parent: F000013
title: "Behavioral eval harness V1 — Roadmap"
date: 2026-05-09
author: chjiang
status: Draft
---

<!-- A feature's roll-up roadmap — merges what was previously in feature-summary
     + milestones. Captures scope/non-goals (the feature's identity), decomposition
     (which user-stories carry the work), and delivery timeline (when each piece
     ships). The /personal-workflow templates step produces this. -->

## Scope

V1 of a behavioral eval harness for the skill workbench. Bash runner (`scripts/eval.sh`) discovers eval cases under `tests/eval/<skill>/<case>/`, seeds each case's fixture into a scratch tmpdir + fake `$HOME`, spawns headless `claude --bare -p --output-format json --json-schema`, validates the model's structured JSON output. Cadence is nightly on `main` plus manual local invocation. V1 covers `personal-workflow` and `system-health` only — skills whose primary user-facing output is a structured report.

## Non-Goals

- **Filesystem-mutating skill coverage** (`scaffold-work-item`, `implement-from-spec`, `qa-work-item`) — needs structural-assertion helpers; deferred to V2
- **`deprecated/company-workflow` coverage** — skill is deprecated, permanently excluded
- **Per-PR cadence** — V1 ships nightly-only to bound CI cost
- **LLM-judge** — V1 uses schema-only assertion; LLM-judge for prose-quality cases is V2
- **Schema consolidation** — V1 accepts per-case hand-written drift; consolidation into `tests/eval/schemas/` with `$ref`s is V2
- **Parser-logic unit tests for `check.md`** — closing the "spec is correct" half of the S000022 gap requires parser extraction; V1 only covers the "Claude executes the spec" half

## Success Criteria

- [ ] `bash scripts/eval.sh` runs end-to-end on a clean checkout against `personal-workflow` + `system-health`, reporting PASS/FAIL per case
- [ ] S000022 Step 18 traceability regression case fails when the parser fix is reverted on a test branch
- [ ] `.github/workflows/eval-nightly.yml` runs nightly on `main` and surfaces failures via existing notification surface
- [ ] V1 case count is 6–10 cases across the 2 in-scope skills
- [ ] Observed cost per nightly run is under $1.50 USD
- [ ] Observed wall-clock per nightly run is under 12 minutes
- [ ] TODOS.md "Behavioral eval harness (P1, M)" is marked DONE-V1

## Decomposition

<!-- The user-stories that decompose this feature, with current status. The
     validator does not enforce this list, but it's the canonical map for human
     readers. Status values: Open, In Progress, Closed. -->

| User-Story | Title | Status |
|-----------|-------|--------|
| [S000023](S000023_spike_and_skeleton/S000023_TRACKER.md) | Spike 0 + runner skeleton + first passing case | Open |
| [S000024](S000024_v1_case_coverage/S000024_TRACKER.md) | V1 eval case coverage (personal-workflow + system-health) | Open |
| [S000025](S000025_nightly_ci/S000025_TRACKER.md) | Nightly CI workflow + first run validation + TODOS update | Open |

## Delivery Timeline

<!-- Forward-looking milestones for this feature. Owner = primary person responsible.
     Status: Done, In Progress, Not Started, At Risk, Deferred.
     Blocked By = milestone number(s) that must complete first, or "—" if none.
     Forward roadmap entries go here; historical entries (PR links, merge dates
     after ship) move to the ### Delivery History sub-section below. -->

| # | Milestone | Target Date | Status | Owner | Notes | Blocked By |
|---|-----------|-------------|--------|-------|-------|------------|
| 1 | Ship S000023 (spike + skeleton + first case) | — | Not Started | chjiang | Resolves S0.1/S0.2/S0.3 spike questions; lands `scripts/eval.sh` + `tests/eval/lib/*` + first passing case | — |
| 2 | Ship S000024 (V1 case coverage) | — | Not Started | chjiang | personal-workflow regression (S000022) + reasoning + baseline; system-health cases | #1 |
| 3 | Ship S000025 (nightly CI + TODOS update) | — | Not Started | chjiang | `.github/workflows/eval-nightly.yml` + first run validation; observed cost/time inform V1.1 if > 50% over budget | #2 |
| 4 | End-to-end pipeline run | — | Not Started | chjiang | First successful nightly CI run on `main`; success criteria verified empirically | #3 |

### Delivery History

<!-- Backward-looking record: PR links, merge dates, version bumps after ship.
     Append-only. Don't edit historical entries — they're the durable record
     of what shipped when. Use this section to absorb any pre-existing
     milestones content during a feature-summary+milestones → ROADMAP migration. -->

- 2026-05-09: F000013 scaffolded from `chjiang-main-design-20260509-110013.md`

## Dependency Graph

<!-- Visual representation of milestone ordering. Format: #N description --> #M
     description (arrow = "blocks"). Keep in sync with the Blocked By column. -->

```
#1 Ship S000023 (spike + skeleton + first case)
        │
        ▼
#2 Ship S000024 (V1 case coverage)
        │
        ▼
#3 Ship S000025 (nightly CI + TODOS update)
        │
        ▼
#4 End-to-end pipeline run (first nightly CI succeeds)
```

## Open Questions

<!-- Questions still being decided. -->

| Question | Next check |
|----------|-----------|
| Does Spike 0 resolve to direct `--plugin-dir` use (cleaner) or fake-`$HOME` fallback (current sketch shape)? | S000023 first task; runner shape simplifies if direct works |
| If observed nightly cost or wall-clock exceeds budget by > 50%, do we cut cases or tighten prompts? | After first real CI run in S000025 — decision deferred to empirical data |
| Should V1.1 add per-PR cadence with `paths: skills/**` filter, or wait for V2? | After 2 weeks of nightly running — let signal/cost ratio decide |
