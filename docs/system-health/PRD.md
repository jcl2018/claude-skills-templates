---
type: prd
feature: system-health
title: "System Health v0.2.0 — Product Requirements"
version: 2
status: Active
date: 2026-04-11
author: chjiang
---

## Problem Statement

Claude Code power users accumulate 40+ skills, custom rules, MCP servers, and hooks in ~/.claude/ with no way to check the health of their installation. Broken symlinks, orphan skills, dead references, and disk bloat accumulate silently. Waza checks config correctness per-project. Gstack /health checks code quality per-repo. Nobody checks the physical health of ~/.claude/ itself or maps the dependency topology between installed skills.

## Mental Model

5-step health check: scan installed skills, build a dependency graph, check filesystem health, optionally invoke waza for config hygiene (unscored appendix), and score with trend tracking. The dependency graph is the core differentiator.

## User Stories

### P0 (Must-Have)

| # | Tag | What it asks | As a... | I want to... | So that... |
|---|-----|-------------|---------|-------------|------------|
| 1 | core | Can I run a health check with one command? | power user | run `/system-health` and see a scored dashboard | I know if my setup is healthy |
| 2 | graph | Does /system-health show my dependency graph? | power user | see which skills depend on which, who the hubs are, what's orphaned | I understand my skill topology |
| 3 | graph | Does it detect broken references? | power user | see dead symlinks and references to uninstalled skills | I can fix broken links |
| 4 | filesystem | Does it check disk health? | power user | see disk usage, stale sessions, temp files, history size | I know when cleanup is needed |
| 5 | waza | Does it integrate waza config checks? | power user | get config hygiene alongside filesystem health in one command | I don't need to run two tools |
| 6 | trend | Does it track health over time? | power user | see if my setup is getting healthier or messier | I can catch regressions |

## Acceptance Criteria

### Story #1: One-command health check [core]

```
GIVEN ~/.claude/ exists with installed skills
WHEN  I run /system-health
THEN  a scored dashboard with 4 buckets is displayed
  AND a composite score 0-10 is computed
```

### Story #2: Dependency graph [graph]

```
GIVEN 2+ skills are installed in ~/.claude/skills/
WHEN  /system-health runs the graph analysis
THEN  hub nodes (in-degree > 5) are identified
  AND orphan skills (zero in-degree) are listed
  AND the top 3 hubs by in-degree are displayed
```

### Story #3: Broken references [graph]

```
GIVEN a skill references another skill that is not installed
WHEN  /system-health runs the graph analysis
THEN  the dead reference is listed with source and target
```

### Story #4: Filesystem health [filesystem]

```
GIVEN ~/.claude/ has accumulated files over time
WHEN  /system-health runs filesystem checks
THEN  disk usage per subdirectory is shown
  AND stale sessions (>24h mtime) are counted
  AND temp files are counted
```

### Story #5: Waza integration [waza]

```
GIVEN waza is installed at ~/.claude/skills/waza/health/
WHEN  /system-health runs (not --quick)
THEN  waza output appears as an unscored appendix
```

### Story #6: Trend tracking [trend]

```
GIVEN a prior health run exists in ~/.gstack/health/
WHEN  /system-health runs and computes a score
THEN  the delta from the previous run is shown
  AND a new snapshot is appended to health-history.jsonl
```

## Success Metrics

| Metric | Target | How Measured |
|--------|--------|-------------|
| Runs without errors | Yes | Manual E2E test |
| Detects known broken symlink | Yes | cross-retro symlink in test environment |
| Graph identifies all installed skills | Yes | Count matches ls ~/.claude/skills/ |
| Waza graceful degradation | Yes | No error when waza is absent |
| Trend delta shown on 2nd run | Yes | Run twice, verify delta displayed |

## Out of Scope

- DOT/Graphviz visualization (v0.3.0)
- Blast-radius analysis ("what breaks if I remove X?") (v0.3.0)
- Auto-fix mode (future)
- Per-repo health (use gstack /health)
- Per-project config audit (use waza /health)

## Breaking Changes from v0.1.0

- `--scope` flag removed (was home-setup-specific)
- `--layer` flag removed (9-layer model replaced by 5-step architecture)
- Waza is now an unscored appendix, not a scored layer
