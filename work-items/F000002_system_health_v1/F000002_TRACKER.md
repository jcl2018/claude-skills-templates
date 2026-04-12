---
name: "system-health-v1"
type: feature
id: "F000002_system_health_v1"
status: active
created: "2026-04-10"
updated: "2026-04-11"
repo: "claude-skills-templates"
branch: "main"
blocked_by: ""
---

## Lifecycle

### Phase 1: Track
- [x] Acceptance criteria scoped
- [x] Working branch created (`branch` field populated)
- [x] Doc triplet produced (PRD + ARCHITECTURE + TEST-SPEC)
- [x] Broken down into child tasks/stories

### Phase 2: Implement
- [x] Doc triplet read (build-forward mode)
- [x] Core implementation committed (>=1 commit SHA in Log)
- [x] Child tasks completed or deferred
- [x] Files section updated

### Phase 3: Review
- [x] Doc review completed
- [x] Doc generation finalized

### Phase 4: Ship
- [x] `/ship` — PR created
- [x] `/land-and-deploy` — merged and deployed

## Acceptance Criteria

- [x] Scans all installed skills in ~/.claude/skills/ with frontmatter extraction
- [x] Builds dependency graph (adjacency list, in-degree, orphans, dead refs)
- [x] Checks filesystem health (disk usage, stale sessions, temp files, history size)
- [x] Optional waza integration as unscored appendix
- [x] Usage trends from ~/.gstack/analytics/skill-usage.jsonl (unscored)
- [x] 4-bucket scored composite (Structure/References/Integrity/Hygiene)
- [x] Trend tracking via ~/.gstack/health/ snapshots
- [x] Read-only (no Edit/Write in allowed-tools)
- [x] Graceful degradation when waza or jq unavailable

## Todos

- [x] v0.1.0: Initial import from home-setup
- [x] v0.2.0: Graph-first rewrite targeting ~/.claude/
- [x] v0.3.0: Usage trends overlay
- [x] v1.0.0: Work item formalization and version cut

## Log

- 2026-04-10: Created. ~/.claude/ health dashboard with dependency graph.
- 2026-04-10: fbfc9ba — Initial import of custom skills and templates (v0.1.0)
- 2026-04-10: 0e7643e — Migrated to lifecycle format
- 2026-04-11: 107031e — Complete rewrite: 5-step pipeline, dependency graph, 4-bucket scoring (v0.2.0)
- 2026-04-11: 0659c00 — Added usage trends overlay from skill-usage.jsonl (v0.3.0)
- 2026-04-11: 59f86eb — Added usage telemetry preamble
- 2026-04-11: 18496fd — Fixed waza path and install instructions
- 2026-04-11: V1 cut — version bump to 1.0.0, work item formalization

## PRs

- #4 — feat: rewrite system-health v0.2.0 (merged)
- #8 — feat: add usage trends to system-health v0.3.0 (merged)
- #10 — feat: add usage telemetry preamble (merged)

## Files

- skills/system-health/SKILL.md
- skills/system-health/DESIGN.md
- skills/system-health/CHANGELOG.md
- skills-catalog.json

## Insights

- Graph computation must be deterministic bash/jq, not Claude reasoning. Claude interprets structured output but never computes adjacency lists, in-degree, or anomalies.
- Waza is CWD-dependent (reflects current project config), so including it in the scored composite would make scores fluctuate by directory. Kept as unscored appendix.
- Usage data has 3 JSONL schemas (simple, intermediate, v1) plus non-run events. The reducer normalizes all three before aggregation.
- Duration sanitization: any duration_s > 86400 is treated as null (known upstream bug where Unix timestamps leak into duration fields).

## Journal

- 2026-04-10 [decision]: Chose bash/jq for graph computation over Claude reasoning. Deterministic, testable, handles 40+ nodes reliably.
- 2026-04-10 [decision]: Waza integration as unscored appendix. CWD-dependent output would corrupt trend tracking.
- 2026-04-11 [decision]: Usage trends as unscored section. Data lives in ~/.gstack/, not ~/.claude/. Same pattern as waza.
- 2026-04-11 [finding]: CHANGELOG missing [0.3.0] entry despite SKILL.md being at 0.3.0. Backfilled during V1 cut.
