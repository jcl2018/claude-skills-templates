---
type: roadmap
parent: F000002
title: "system-health — Roadmap"
date: 2026-04-24
author: chjiang
status: Draft
---

<!-- Migrated from F000002_feature-summary.md + F000002_milestones.md during
     F000008 v1.5.0 sweep. Section content preserved verbatim from the
     two source files for historical fidelity. The new doc-ROADMAP.md
     template suggests Scope / Non-Goals / Success Criteria / Decomposition
     / Delivery Timeline (with Delivery History sub-section) / Dependency
     Graph / Open Questions; refine over time as needed. -->

<!-- ===== From F000002_feature-summary.md ===== -->

<!-- Retroactive backfill: F000002 shipped before feature-summary.md was a
     required feature artifact for personal-workflow (added in this PR's
     manifest update). The original roll-up identity for this feature lives
     in F000002_TRACKER.md (Acceptance Criteria, Insights, Journal). This
     file exists for manifest compliance. -->

## Scope

`system-health` is the read-only `~/.claude/` dashboard skill. It scans
installed skills with frontmatter extraction, builds a dependency graph
(adjacency list, in-degree, orphans, dead refs), checks filesystem health
(disk usage, stale sessions, temp files, history size), surfaces usage
trends from `~/.gstack/analytics/skill-usage.jsonl`, and emits a 4-bucket
scored composite (Structure / References / Integrity / Hygiene) with trend
snapshots. Bash/jq for graph computation; Claude only interprets the
structured output.

## Success Criteria

- [x] Scans all installed skills in `~/.claude/skills/` with frontmatter extraction
- [x] Builds dependency graph (adjacency list, in-degree, orphans, dead refs)
- [x] Checks filesystem health (disk usage, stale sessions, temp files, history size)
- [x] Optional waza integration as unscored appendix (CWD-dependent, would corrupt scoring)
- [x] Usage trends overlay from `~/.gstack/analytics/skill-usage.jsonl` (unscored)
- [x] 4-bucket scored composite: Structure / References / Integrity / Hygiene
- [x] Trend tracking via `~/.gstack/health/` snapshots
- [x] Read-only (no Edit/Write in `allowed-tools`)
- [x] Graceful degradation when `waza` or `jq` is unavailable

## Decomposition

<!-- F000002 was developed via raw version bumps (v0.1.0 → v1.0.0) before the
     user-story decomposition convention was introduced. No nested user-story
     directories exist. Future system-health work goes here as new user-stories. -->

- (none — historical: feature delivered via direct version bumps prior to user-story decomposition)

## Non-Goals

- Including `waza` output in the scored composite — its CWD-dependent output would corrupt trend tracking. Kept as unscored appendix.
- Mutating any file under `~/.claude/` — `system-health` is strictly read-only. Cleanup actions are advisory output, not direct edits.
- Replacing the bash/jq graph engine with Claude reasoning — determinism on 40+ nodes was the explicit design choice.

<!-- ===== From F000002_milestones.md ===== -->

## Delivery Timeline

<!-- Backfill: F000002 was developed via raw version bumps before milestones.md
     was a required feature artifact. The milestones below reconstruct the
     historical delivery from the F000002_TRACKER.md Log. -->

| # | Milestone | Target Date | Status | Owner | Notes | Blocked By |
|---|-----------|-------------|--------|-------|-------|------------|
| 1 | v0.1.0 — Initial import from home-setup | 2026-04-10 | Done | chjiang | Imported custom skills/templates (commit fbfc9ba) | — |
| 2 | Migrate to lifecycle format | 2026-04-10 | Done | chjiang | Adopted shared lifecycle convention (commit 0e7643e) | #1 |
| 3 | v0.2.0 — Graph-first rewrite | 2026-04-11 | Done | chjiang | 5-step pipeline; dependency graph + 4-bucket scoring; PR #4, commit 107031e | #2 |
| 4 | v0.3.0 — Usage trends overlay | 2026-04-11 | Done | chjiang | Reads `~/.gstack/analytics/skill-usage.jsonl`; PR #8, commit 0659c00 | #3 |
| 5 | Usage telemetry preamble | 2026-04-11 | Done | chjiang | Standardized usage logging across skills; PR #10, commit 59f86eb | #4 |
| 6 | waza path + install fix | 2026-04-11 | Done | chjiang | Corrected waza CLI invocation; commit 18496fd | #3 |
| 7 | v1.0.0 — Work item formalization | 2026-04-11 | Done | chjiang | Cut v1.0.0; F000002 tracker scaffolded around the shipped skill | #5, #6 |
| 8 | One-feature-per-skill consolidation | 2026-04-24 | Done | chjiang | Renamed `system_health_v1` → `system_health`; status flipped to `shipped` | #7 |

## Dependency Graph

```
#1 v0.1.0 import --> #2 lifecycle --> #3 v0.2.0 graph --+--> #4 v0.3.0 trends --> #5 telemetry --+
                                                        |                                        |
                                                        +--> #6 waza fix ------------------------+
                                                                                                 |
                                                                              #7 v1.0.0 cut <---+
                                                                                                 |
                                                                              #8 consolidation <-+
```

## Open Questions

<!-- Questions still being decided. Migrated content has no recorded open
     questions; left empty intentionally. -->

| Question | Next check |
|----------|-----------|
| _none recorded at migration time_ | _N/A_ |
