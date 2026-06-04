---
type: roadmap
parent: F000047
title: "Cross-repo portability audit for delivered skills — Roadmap"
date: 2026-06-04
author: chjiang
status: Draft
---

<!-- A feature's roll-up roadmap — scope/non-goals (identity), decomposition
     (which user-stories carry the work), and delivery timeline (when each
     piece ships). -->

## Scope

Add a `/CJ_portability-audit` skill that verifies each delivered skill's
self-declared `portability` field against its ACTUAL repo-local dependencies —
turning an honor-system label into a verified invariant. A static dependency-lint
engine (Layer 1) is shared between the skill (rich per-skill report) and a
`validate.sh` advisory check (always-on, exit 0 in v1). An opt-in dynamic pass
(Layer 2) drives a real skill against a stripped scratch repo to prove graceful
degradation. v1 ships Layer 1 + an optional `portability_requires` adjudication
catalog field + a single local Layer-2 case; broad Layer-2 coverage + nightly CI +
the advisory→hard-gate hardening are deferred to a follow-up story.

## Non-Goals

- Layer 2 broad dynamic coverage across all runnable leaf skills + orchestrator partial runs — DEFERRED to Story 2 (re-imports the parked-eval-harness cost/flake, D000023).
- Nightly-CI wiring of the portability eval job — DEFERRED to Story 2.
- Advisory→hard-gate hardening (`PORTABILITY_STRICT=1`) — DEFERRED to Story 2, after declarations are reconciled.
- Auto-fixing mismatches — the audit reports; the operator relabels `portability` or adjudicates via `portability_requires`.
- Merging with `/CJ_repo-init` — that is consumer-side; this is producer-side. Different lifecycle, kept separate (Approach C rejected).

## Success Criteria

- [ ] `/CJ_portability-audit` prints a per-skill portability verdict table over the runtime-derived Check-14/15b selector set; each finding names skill + executed repo-local dep + why (declared vs actual).
- [ ] The shared static-lint engine runs as a `validate.sh` advisory check (exit 0 in v1, findings visible).
- [ ] ≥1 REAL finding surfaces before adjudication (non-no-op proof), then v1 lands green via pre-seeded `portability_requires`.
- [ ] Optional `portability_requires` catalog field ships + engine honors it.
- [ ] Engine has `scripts/test.sh` integration coverage (`zzz-test-scaffold` pattern).
- [ ] New skill fully documented (SKILL.md + USAGE.md + catalog + ARCHITECTURE roster + PHILOSOPHY decision tree) + correct-behavior spec in `doc/WORKFLOWS.md`.
- [ ] First run flags the three `CJ_goal_*` orchestrators + `CJ_qa-work-item` + `CJ_implement-from-spec` as `standalone`-but-coupled (D4 headline).
- [ ] `scripts/eval.sh --portability` mode + fixture-prep helper run ONE leaf-skill case (`CJ_suggest`) locally green against a stripped + `.source`-neutralized scratch repo.

## Decomposition

<!-- The user-stories that decompose this feature. Status values: Open, In Progress, Closed. -->

| User-Story | Title | Status |
|-----------|-------|--------|
| [S000083](S000083_layer1_static_dependency_lint/S000083_TRACKER.md) | Layer 1 static dependency lint (engine + skill + validate.sh check + `portability_requires` field + docs + one local Layer-2 case) | Open |
| (Story 2 — not yet scaffolded) | Layer 2 broad dynamic eval coverage + nightly CI + advisory→hard-gate hardening | Deferred |

## Delivery Timeline

<!-- Forward-looking milestones. Status: Done, In Progress, Not Started, At Risk, Deferred. -->

| # | Milestone | Target Date | Status | Owner | Notes | Blocked By |
|---|-----------|-------------|--------|-------|-------|------------|
| 1 | Ship S000083 (Layer 1 static lint — v1 must-ship) | — | Not Started | chjiang | Engine + skill + validate.sh advisory check + test.sh fixture + `portability_requires` field + docs + one local `CJ_suggest` Layer-2 case | — |
| 2 | End-to-end pipeline run (audit prints verdict table; validate.sh green; one Layer-2 case green) | — | Not Started | chjiang | The v1 acceptance run | #1 |
| 3 | Ship Story 2 (Layer 2 broad coverage + nightly CI + hard-gate hardening) | — | Deferred | chjiang | Scaffold as a sibling user-story after Story 1 lands; out of v1 scope | #1 |

### Delivery History

<!-- Backward-looking record: PR links, merge dates, version bumps after ship. Append-only. -->

- 2026-06-04: F000047 scaffolded from the /office-hours design (APPROVED, two adversarial spec-review rounds + operator premise gate).

## Dependency Graph

<!-- #N description --> #M description (arrow = "blocks"). -->

```
#1 Ship S000083 (Layer 1 static lint) --> #2 End-to-end v1 acceptance run
#1 Ship S000083 (Layer 1 static lint) --> #3 Ship Story 2 (Layer 2 broad + nightly + hard-gate) [DEFERRED]
```

## Open Questions

<!-- Questions still being decided. -->

| Question | Next check |
|----------|-----------|
| When to flip the validate.sh check to hard-fail (`PORTABILITY_STRICT=1`)? Mechanism decided (`portability_requires` ships in v1); only timing is open. | Story 2 — once declarations are fully adjudicated. |
| Dynamic-eval CI home: extend `eval-nightly.yml` (one cron) vs a new workflow? | Story 2 — lean is extend the existing one. |
