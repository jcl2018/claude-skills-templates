---
type: architecture
parent: ""
feature: F000002_system_health_v1
title: "system-health V1 — Architecture"
version: 1
status: Approved
date: 2026-04-11
author: chjiang
prd: F000002_PRD.md
reviewers: []
---

## Overview

system-health is a read-only Claude Code skill that scans ~/.claude/, builds a
dependency graph of installed skills, checks filesystem health, optionally invokes
waza for config hygiene, overlays usage analytics, and produces a scored dashboard
with trend tracking. The architecture is a 5-step pipeline where bash/jq performs
all computation and Claude interprets the structured output.

This approach was chosen because graph algorithms and statistical aggregation must
be deterministic and testable. Claude's role is interpretation and presentation,
not computation.

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    /system-health                        │
├──────────┬──────────┬──────────┬──────────┬─────────────┤
│  Step 1  │  Step 2  │  Step 3  │  Step 4  │   Step 5    │
│   Scan   │  Graph   │ Filesys  │Waza/Usage│ Score+Trend │
│          │          │          │(unscored)│             │
│ bash     │ bash/jq  │ bash     │ bash/jq  │ bash/jq     │
│          │          │          │          │             │
│ SKILL:   │ EDGE:    │ DISK:    │ WAZA:    │ SCORE:      │
│ FM:      │ INDEG:   │ HISTORY: │ USAGE_*: │ SNAPSHOT:   │
│ REF:     │ ORPHAN:  │ SESSIONS:│          │ PREV:       │
│ SYMLINK: │ BROKEN:  │ TEMP:    │          │             │
│          │ DEAD:    │ EMPTY:   │          │             │
└──────────┴──────────┴──────────┴──────────┴─────────────┘
     │           │          │          │           │
     └───────────┴──────────┴──────────┴───────────┘
                         │
                   Claude interprets
                   structured output
                         │
                    ┌─────────┐
                    │Dashboard│
                    │ Report  │
                    └─────────┘
```

### Components Affected

| Component | Repo | Change Type | Description |
|-----------|------|------------|-------------|
| skills/system-health/SKILL.md | claude-skills-templates | Modified | Main skill implementation (695 lines) |
| skills/system-health/DESIGN.md | claude-skills-templates | Modified | Skill design decisions |
| skills/system-health/CHANGELOG.md | claude-skills-templates | Modified | Version history |
| skills-catalog.json | claude-skills-templates | Modified | Catalog entry with version |
| ~/.gstack/health/ | ~/.gstack | Created at runtime | Trend history snapshots |
| ~/.gstack/analytics/skill-usage.jsonl | ~/.gstack | Read at runtime | Usage data source |

### Data Flow

1. **Step 1 (Scan):** Bash walks ~/.claude/skills/*, extracts YAML frontmatter via sed, greps *.md/*.json for cross-references, checks symlink health. Emits structured SKILL:/FM:/REF:/SYMLINK: lines.

2. **Step 2 (Graph):** Bash builds adjacency list from cross-references, computes in-degree per skill, identifies orphans (zero in-degree), detects broken symlinks and dead references. Emits EDGE:/INDEG:/ORPHAN:/BROKEN:/DEAD: lines.

3. **Step 3 (Filesystem):** Bash checks disk usage (du -sh per subdirectory), history.jsonl size, stale sessions (mtime > 24h), temp files, empty directories, settings.json structure via jq keys. Emits structured lines.

4. **Step 4 (Waza, optional unscored):** If waza installed, runs collect-data.sh. Output appears as unscored appendix. If missing, prints install message.

5. **Step 4.5 (Usage Trends, unscored):** jq reducer normalizes 3 JSONL schemas, filters non-run events, sanitizes durations > 86400s, aggregates per-skill/per-repo/per-hour stats, detects anomalies. Emits USAGE_* lines.

6. **Step 5 (Score+Trend):** Claude reads all structured output, scores 4 buckets (0-10 each), computes weighted composite, appends snapshot to ~/.gstack/health/claude-home-health-history.jsonl, shows delta from previous run.

## API Changes

### New APIs

No APIs. This is a prompt-driven skill invoked via `/system-health`.

### Modified APIs

N/A.

## Dependencies

| Dependency | Type | Status | Notes |
|-----------|------|--------|-------|
| jq | CLI tool | Available | Required for settings extraction, usage trends. Graceful fallback if missing. |
| waza | Skill (runtime) | Optional | collect-data.sh for config hygiene. Skipped with message if absent. |
| ~/.gstack/analytics/skill-usage.jsonl | Data file | Optional | Created by gstack skill preambles. Empty = no usage trends. |

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Corrupt skill-usage.jsonl | Med | Low | jq parse errors caught, skip with message |
| Duration field contains Unix timestamps | High (known bug) | Low | Any duration_s > 86400 treated as null |
| Large ~/.claude/ (100+ skills) slows scan | Low | Med | Grep limited to *.md and *.json, not all files |
| Waza absent in most installs | High | None | Graceful degradation, install message shown |
| history.jsonl very large (>100MB) | Low | Low | Only reports size, does not parse content |

## Design Decisions

| Decision | Chosen | Rejected Alternative | Why |
|----------|--------|---------------------|-----|
| Graph computation | bash/jq (deterministic) | Claude reasoning | Reliable for 40+ nodes, testable, reproducible |
| Waza scoring | Unscored appendix | 15% weighted bucket | CWD-dependent output makes trend scores fluctuate |
| Usage trends scoring | Unscored appendix | Scored bucket | Data lives in ~/.gstack/, not ~/.claude/. Different domain. |
| Grep scope | *.md and *.json only | All files | Reduces false positives from binaries, JSONL, images |
| Settings extraction | jq keys only | Raw cat | Security: never expose credentials or API keys |
| Edit/Write tools | Not in allowed-tools | Included | Read-only skill by design. Report, don't fix. |
| Scoring weights | Structure 25%, References 35%, Integrity 25%, Hygiene 15% | Equal weights | References most impactful: broken deps cascade. Hygiene least: cosmetic. |
