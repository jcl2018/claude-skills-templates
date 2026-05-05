---
type: feature-summary
parent: F000002_system_health
title: "system-health — Feature Summary"
date: 2026-04-24
author: chjiang
status: Backfill
---

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

## Constituent User-Stories

<!-- F000002 was developed via raw version bumps (v0.1.0 → v1.0.0) before the
     user-story decomposition convention was introduced. No nested user-story
     directories exist. Future system-health work goes here as new user-stories. -->

- (none — historical: feature delivered via direct version bumps prior to user-story decomposition)

## Out-of-Scope

- Including `waza` output in the scored composite — its CWD-dependent output would corrupt trend tracking. Kept as unscored appendix.
- Mutating any file under `~/.claude/` — `system-health` is strictly read-only. Cleanup actions are advisory output, not direct edits.
- Replacing the bash/jq graph engine with Claude reasoning — determinism on 40+ nodes was the explicit design choice.
