---
type: roadmap
parent: F000029
title: "Marker-pickup AUQ in cj_goal preambles (closes F000028 doc-sync loop) — Roadmap"
date: 2026-05-30
author: chjiang
status: Approved
---

<!-- A feature's roll-up roadmap — merges what was previously in feature-summary
     + milestones. Captures scope/non-goals (the feature's identity), decomposition
     (which user-stories carry the work), and delivery timeline (when each piece
     ships). The /CJ_personal-workflow templates step produces this. -->

## Scope

Add a marker-pickup AUQ to each of the 3 cj_goal orchestrator preambles (`/cj_goal_feature`, `/cj_goal_defect`, `/CJ_goal_investigate`). When F000028's hook has dropped a doc-sync marker at `~/.gstack/doc-sync-pending/<slug>.json`, the preamble surfaces an AUQ asking the operator to invoke `/document-release` inline, snooze, or skip. Closes the F000028 loop — the hook already drops markers; this feature makes the silent state visible at the right moment (right before the operator kicks off their next workbench task). Mirrors the existing F000009 `skills-update-check` pattern: tiny script in `scripts/`, per-preamble call, cache state for snooze/skip.

## Non-Goals

<!-- Explicit non-goals. Things this feature deliberately does NOT do, and why.
     Prevents scope creep during Implement and gives reviewers an unambiguous
     boundary. -->

- `/CJ_goal_todo_fix` preamble call — same drift-cleanup logic applies but out of scope for this PR; revisit in a follow-up.
- `/CJ_suggest` / `/CJ_system-health` preamble — informational utilities, not work-starters; doesn't fit the trigger surface.
- Per-marker snooze (head_sha-keyed) — design uses global snooze; revisit if operator wants finer control.
- Cross-repo basename collision — inherited limitation from F000028's hook, not a regression introduced here.
- Changes to F000028's hook or marker shape — F000029 is strictly a downstream consumer.

## Success Criteria

<!-- Bulleted, measurable outcomes. Each criterion should be observable from
     the outside (a user, an SLO, a stakeholder report) — not internal code
     state. If you can't measure it, it's not a success criterion; it's
     an aspiration. -->

- [ ] On a clean cache + present marker, `bash scripts/skills-doc-sync-check` prints `DOC_SYNC_PENDING <marker-path>` to stdout, exits 0.
- [ ] `--snooze 24` suppresses subsequent invocations for 24h; after expiry, AUQ fires again.
- [ ] `--skip <head_sha>` suppresses subsequent invocations for that marker `head_sha`; new marker (different `head_sha`) re-fires.
- [ ] `--resolved` deletes marker + clears snooze/skip cache; idempotent silent-success when marker is already absent.
- [ ] Stale `head_sha` (unreachable from HEAD): silent delete + no AUQ.
- [ ] `./scripts/validate.sh` passes (0 errors, 0 warnings); `./scripts/test.sh` passes (new test file invoked).
- [ ] Live dogfood: real `/cj_goal_feature` invocation against a repo with a planted marker surfaces the AUQ with all 3 marker fields populated; no-marker case stays silent (no regression).
- [ ] CLAUDE.md gains the sibling "Doc-sync check mechanism (F000028 follow-up)" subsection with the novel-pattern callout.

## Decomposition

<!-- The user-stories that decompose this feature, with current status. The
     validator does not enforce this list, but it's the canonical map for human
     readers. Status values: Open, In Progress, Closed. -->

| User-Story | Title | Status |
|-----------|-------|--------|
| [S000062](S000062_marker_pickup_auq_impl/S000062_TRACKER.md) | Marker-pickup AUQ implementation (script + 3 preamble edits + tests + CLAUDE.md doc) | Open |

## Delivery Timeline

<!-- Forward-looking milestones for this feature. Owner = primary person responsible.
     Status: Done, In Progress, Not Started, At Risk, Deferred.
     Blocked By = milestone number(s) that must complete first, or "—" if none.
     Forward roadmap entries go here; historical entries (PR links, merge dates
     after ship) move to the ### Delivery History sub-section below. -->

| # | Milestone | Target Date | Status | Owner | Notes | Blocked By |
|---|-----------|-------------|--------|-------|-------|------------|
| 1 | Ship S000062 (script + preamble edits + tests + CLAUDE.md doc) | 2026-05-31 | Not Started | chjiang | Single user-story carries the full implementation | — |
| 2 | End-to-end pipeline run (planted-marker dogfood via `/cj_goal_feature`) | 2026-05-31 | Not Started | chjiang | First real-world AUQ surfacing after merge | #1 |

### Delivery History

<!-- Backward-looking record: PR links, merge dates, version bumps after ship.
     Append-only. Don't edit historical entries — they're the durable record
     of what shipped when. Use this section to absorb any pre-existing
     milestones content during a feature-summary+milestones → ROADMAP migration. -->

- 2026-05-30: F000029 scaffolded from `chjiang-cj-feat-20260530-222955-29095-design-20260530-223418.md` (APPROVED).

## Dependency Graph

<!-- Visual representation of milestone ordering. Format: #N description --> #M
     description (arrow = "blocks"). Keep in sync with the Blocked By column. -->

```
#1 Ship S000062  -->  #2 End-to-end pipeline run (planted-marker dogfood)
```

## Open Questions

<!-- Questions still being decided. -->

| Question | Next check |
|----------|-----------|
| Should `/CJ_goal_todo_fix` also get the preamble call? | Defer until F000029 ships and dogfoods cleanly; revisit as a follow-up. |
| Should `/CJ_suggest` / `/CJ_system-health` also surface the marker? | Probably not (informational utilities); defer. |
| Should snooze be per-marker or global? | Current design: global. Revisit if operator wants finer control. |
