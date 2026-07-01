---
type: roadmap
parent: F000071
title: "cj_goal local happy-path E2E harness — Roadmap"
date: 2026-06-30
author: chjiang
status: Draft
---

<!-- A feature's roll-up roadmap — merges what was previously in feature-summary
     + milestones. Captures scope/non-goals (the feature's identity), decomposition
     (which user-stories carry the work), and delivery timeline (when each piece
     ships). The /CJ_personal-workflow templates step produces this. -->

## Scope

This feature delivers a LOCAL happy-path end-to-end harness that proves a cj_goal
autonomous BUILD runs end to end — past the AUQ wall that blocks a headless run —
by auto-answering the cj_goal *build* gates under a hard guard and stopping at the
`/ship` boundary in a sandbox, NEVER touching the ship/merge/deploy gates. The
first shipped story (Part A — S000120) is the dormant, CI-green build-gate
auto-answer seam + its non-activation proof: the verdict helper, the uniform seam
prose in the four pipelines, the marker gitignore + validate marker-absence check,
and the deterministic verdict-matrix test. The real-run harness (Part B) and the
workflow documentation (Part C) are tracked follow-on.

## Non-Goals

- Auto-answer of any gstack ship / merge / `/land` / deploy gate — the seam is build-gates-only by an enforced allowlist; this is the autonomy ceiling and is EXPLICITLY NEVER built.
- A CI-automated E2E run — gstack-in-CI, eval allowedTools, and budget remain a separate deferred epic; Part B is local-only / CI-skipped.
- A real PR against GitHub (`real-pr` depth via a scratch repo) — deferred; the sandbox uses a LOCAL bare origin that accepts push but defeats `gh pr create`.
- The other cj_goal verbs as Part-B harness cases — `feature` needs office-hours handling; deferred follow-on.

## Success Criteria

- [ ] **Part A (S000120):** the verdict matrix is asserted by `tests/cj-e2e-gate.test.sh` (no Claude); the four pipelines branch on the helper; a normal run is observably behavior-unchanged; `.cj-e2e-sandbox` is gitignored and validate-checked-absent; CI-green.
- [ ] The seam can be shown to return `inactive` for any non-`{design-gate, qa-audit}` gate id (never matches a ship/merge/deploy marker).
- [ ] `validate.sh` reports 0 errors and `test.sh` is green with Part A landed.
- [ ] Parts B and C exist as tracked follow-on rows here (not silently dropped).

## Decomposition

<!-- The user-stories that decompose this feature, with current status. -->

| User-Story | Title | Status |
|-----------|-------|--------|
| [S000120](S000120_build_gate_auto_answer_seam/S000120_TRACKER.md) | Build-gate auto-answer seam (Part A — dormant, CI-green) | Open |

<!-- Part B (local-E2E harness + materialized report) and Part C (workflow-docs
     roster entry + test-hierarchy update) are TRACKED FOLLOW-ON: they will be
     scaffolded as additional child stories of this feature when Part A has
     landed. They are intentionally NOT decomposed into child stories yet. -->

## Delivery Timeline

| # | Milestone | Target Date | Status | Owner | Notes | Blocked By |
|---|-----------|-------------|--------|-------|-------|------------|
| 1 | Ship S000120 (Part A — dormant build-gate auto-answer seam) | — | Not Started | chjiang | One low-risk mergeable PR; CI-green; guard off by default | — |
| 2 | Scaffold + ship Part B (local-E2E harness + materialized report) | — | Deferred | chjiang | CI-skipped; needs local gstack + ANTHROPIC_API_KEY + gh | #1 |
| 3 | Scaffold + ship Part C (workflow-docs roster entry + test-hierarchy update) | — | Deferred | chjiang | Extend `docs/workflows/utilities-and-phase-steps.md`; Check 27 green | #2 |

### Delivery History

<!-- Backward-looking record: PR links, merge dates, version bumps after ship.
     Append-only. -->

- 2026-06-30: Scaffolded F000071 with child story S000120 (Part A). Parts B and C captured as tracked follow-on.

## Dependency Graph

<!-- Visual representation of milestone ordering. Format: #N description --> #M
     description (arrow = "blocks"). -->

```
#1 Part A: dormant seam (S000120, CI-green) --> #2 Part B: local-E2E harness + report --> #3 Part C: workflow docs
```

## Open Questions

<!-- Questions still being decided. -->

| Question | Next check |
|----------|-----------|
| Part B report home/format — gitignored `tests/e2e-local/reports/*.md` + `.json` sibling, with a committed `reports/EXAMPLE.md` so the format is reviewable in the PR | Resolved in the Part B follow-on story (not S000120) |
| Part C workflow-docs placement — extend `docs/workflows/utilities-and-phase-steps.md` roster (a new top-level roster section orphans an undeclared `docs/workflows/*.md` → Check 15a ERROR) | Resolved in the Part C follow-on story (not S000120); lean: extend the existing roster |
