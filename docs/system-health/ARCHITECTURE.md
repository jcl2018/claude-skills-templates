---
type: architecture
feature: system-health
title: "System Health v0.2.0 — Architecture"
version: 2
status: Active
date: 2026-04-11
author: chjiang
prd: PRD.md
---

## Overview

The /system-health skill checks ~/.claude/ filesystem health via a 5-step pipeline:
scan, graph analysis, filesystem health, optional waza integration, and scored trend
tracking. Graph computation is deterministic (bash/jq), not Claude reasoning.

## Architecture

```
/system-health (entry point — skills/system-health/SKILL.md)
  |
  +---> Step 1: SCAN (single consolidated bash command)
  |       |-- shopt -s nullglob (empty glob guard)
  |       |-- Walk ~/.claude/skills/*/ (top-level only)
  |       |-- Extract SKILL.md frontmatter (name, version, description)
  |       |-- Grep *.md and *.json for cross-references
  |       |-- Parse settings.json structurally (jq keys only)
  |       +-- Check rules/, templates/ existence
  |
  +---> Step 2: GRAPH ANALYSIS (bash/jq, deterministic)
  |       |-- Build adjacency list from REF: lines
  |       |-- Filter: only edges where target dir exists
  |       |-- Compute in-degree per skill
  |       |-- Detect orphans (zero in-degree)
  |       |-- Detect dead references (target not installed)
  |       |-- Detect broken symlinks (find -L)
  |       +-- Claude INTERPRETS results, doesn't compute them
  |
  +---> Step 3: FILESYSTEM HEALTH (bash)
  |       |-- du -sh per ~/.claude/ subdirectory
  |       |-- history.jsonl size and line count
  |       |-- Stale sessions (find -mtime +1)
  |       |-- Temp files (.tmp, .bak, .pending-*)
  |       +-- Empty directories, missing config files
  |
  +---> Step 4: WAZA INTEGRATION (optional, unscored)
  |       |-- Check if collect-data.sh exists
  |       |-- Run and capture output
  |       +-- Include as unscored appendix (CWD-dependent)
  |
  +---> Step 5: SCORE + TREND
          |-- 4-bucket scoring (Structure 25%, References 35%, Integrity 25%, Hygiene 15%)
          |-- Save snapshot to ~/.gstack/health/claude-home-health-history.jsonl
          |-- Show delta from previous run
          +-- Handle corrupt history with jq fallback
```

### Components Affected

| Component | Path | Change Type | Description |
|-----------|------|------------|-------------|
| Health skill | skills/system-health/SKILL.md | Core | Rewritten 5-step pipeline |
| Skill design | skills/system-health/DESIGN.md | Updated | Design decisions documented |
| Changelog | skills/system-health/CHANGELOG.md | Updated | v0.2.0 entry |
| Catalog | skills-catalog.json | Updated | waza dependency declared |
| PRD | docs/system-health/PRD.md | Rewritten | New user stories for ~/.claude/ scope |
| Architecture | docs/system-health/ARCHITECTURE.md | Rewritten | 5-step architecture |
| Test spec | docs/system-health/TEST-SPEC.md | Rewritten | New test matrix |

### Data Flow

1. Step 1 bash command produces structured text output (SKILL:, FM:, REF:, SYMLINK:, etc.)
2. Step 2 bash command processes the same ~/.claude/skills/ to build graph (EDGE:, INDEG:, ORPHAN:, BROKEN:, DEAD:)
3. Step 3 bash command checks filesystem health (DISK USAGE:, HISTORY:, SESSIONS:, etc.)
4. Step 4 optionally invokes waza's collect-data.sh (verbatim output)
5. Step 5 scores 4 buckets and appends JSONL snapshot
6. Claude reads all outputs and presents the dashboard + recommendations

## Dependencies

| Dependency | Type | Status | Notes |
|-----------|------|--------|-------|
| waza | Skill (runtime) | Optional | collect-data.sh for config hygiene. Graceful degradation. |
| jq | CLI tool | Recommended | Settings extraction, history parsing. Fallback if missing. |

## Design Decisions

| Decision | Chosen | Rejected | Why |
|----------|--------|----------|-----|
| Graph in bash/jq | Deterministic computation | Claude reasoning | Reliable for 40+ nodes, testable, reproducible |
| Waza unscored | Appendix only | 15% weighted bucket | CWD-dependent output makes trend unreliable |
| Grep *.md/*.json | File-type filter | Grep all files | Reduces false positives from binaries, JSONL, screenshots |
| Settings via jq keys | Structural extraction | Raw dump | Security: don't expose credentials |
| No Edit allowed | Read-only skill | Edit in allowed-tools | Matches read-only reporting design |
| Fixed history path | ~/.gstack/health/ | repo-slug-based | Global check, not repo-specific |
