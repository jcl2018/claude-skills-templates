---
type: roadmap
parent: F000018
title: "/CJ_run end-to-end — suppress /land-and-deploy readiness gate — Roadmap"
date: 2026-05-13
author: chjiang
status: Draft
---

<!-- A feature's roll-up roadmap — merges what was previously in feature-summary
     + milestones. Captures scope/non-goals (the feature's identity), decomposition
     (which user-stories carry the work), and delivery timeline (when each piece
     ships). The /CJ_personal-workflow templates step produces this. -->

## Scope

Add a `--suppress-readiness-gate` flag plumbing pattern between `/CJ_run` and
`/land-and-deploy` so a green end-to-end pipeline run produces zero readiness
AUQs (only autoplan + /ship diff review surface). The workbench-side change is
contained in `skills/CJ_run/`; the gstack flag itself ships separately.

## Non-Goals

- Modifying gstack's `/land-and-deploy` skill — out of scope here; the gstack PR is owned by the user by hand.
- Suppressing Step 5 deploy-strategy AUQ (no platform config) — different semantic change with its own blast radius; follow-up TODO to populate `## Deploy Configuration` in CLAUDE.md instead.
- Suppressing Step 1.5 first-run dry-run AUQ — one-time setup gate already CONFIRMED for this workbench.
- A `--non-interactive` flag for fully unattended runs — separate story if needed later.

## Success Criteria

- [ ] Running `/CJ_run <approved-design-doc>` end-to-end on an all-green pipeline produces zero readiness-gate AUQs. Two AUQs total: autoplan final approval + /ship diff review.
- [ ] Running `/CJ_run <work-item-dir>` in Branch(f) `open_pr` mode auto-continues into `/land-and-deploy --suppress-readiness-gate #<PR_NUM>` with the same PR-num parsing as Step 5.
- [ ] Free-test regression at /land-and-deploy time halts cleanly with `END_STATE=halted_at_deploy`.
- [ ] Merge conflict still STOPs via /land-and-deploy's current diagnostic.
- [ ] Direct invocation of `/land-and-deploy` (without /CJ_run, no flag) preserves today's behavior bit-for-bit.
- [ ] Cross-version compatibility: new workbench + old gstack → flag ignored, no regression.

## Decomposition

<!-- The user-stories that decompose this feature, with current status. The
     validator does not enforce this list, but it's the canonical map for human
     readers. Status values: Open, In Progress, Closed. -->

| User-Story | Title | Status |
|-----------|-------|--------|
| [S000040](S000040_workbench_side/S000040_TRACKER.md) | Workbench-side change: pass flag, fix Branch(f) open_pr, bump version | In Progress |

## Delivery Timeline

| # | Milestone | Target Date | Status | Owner | Notes | Blocked By |
|---|-----------|-------------|--------|-------|-------|------------|
| 1 | Ship S000040 (workbench-side change) | 2026-05-13 | In Progress | chjiang | Single user-story; safe no-op until gstack PR lands | — |
| 2 | End-to-end pipeline run on a future design doc | — | Not Started | chjiang | Dogfood after gstack PR lands; verifies zero readiness AUQ | #1 |

### Delivery History

- 2026-05-13: F000018 scaffolded; S000040 in progress.

## Dependency Graph

```
#1 Ship S000040 (workbench-side) -----> #2 E2E dogfood after gstack lands
```

## Open Questions

| Question | Next check |
|----------|-----------|
| Order of operations: which PR lands first (gstack or workbench)? | Forward-compat handles both orders; user picks per their gstack release cadence. |
| Should follow-up TODO ("populate `## Deploy Configuration` in CLAUDE.md") be scaffolded as a separate task? | Defer — small ancillary, address inline next time /CJ_run is invoked. |
