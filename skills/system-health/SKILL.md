---
name: system-health
description: "~/.claude/ health dashboard with dependency graph. Scans installed skills, builds a dependency graph, checks filesystem health, and optionally invokes waza for config hygiene. Produces a scored report with trend tracking."
version: 0.2.0
allowed-tools:
  - Bash
  - Read
  - Glob
  - Grep
  - AskUserQuestion
---

# /system-health — ~/.claude/ Health Dashboard

Checks the physical health of your `~/.claude/` folder. Scans all installed skills,
builds a dependency graph, detects orphans and broken references, checks filesystem
hygiene, and optionally invokes waza for config correctness.

**Not** a per-repo code quality check (that's gstack `/health`).
**Not** a per-project config audit (that's waza `/health`).
This is the filesystem and topology layer that sits between them.

## Usage

- `/system-health` — full health check with dependency graph
- `/system-health --quick` — skip waza integration, filesystem checks only

## Step 0: Parse arguments

Check if the user passed `--quick`. If so, skip Step 4 (waza integration).

## Step 1: Scan ~/.claude/

Run a single consolidated bash command to collect all skill metadata and cross-references.
This avoids 80-100+ sequential tool calls.

```bash
#!/usr/bin/env bash
# Scan ~/.claude/ for skill metadata and cross-references
set -euo pipefail
shopt -s nullglob  # handle empty globs gracefully

echo "=== SKILL INVENTORY ==="
for d in ~/.claude/skills/*/; do
  name=$(basename "$d")
  echo "SKILL:$name"

  # Frontmatter extraction
  if [ -f "$d/SKILL.md" ]; then
    sed -n '/^---$/,/^---$/p' "$d/SKILL.md" | grep -E '^(name|version|description):' | sed 's/^/  FM:/'
  else
    echo "  NO_SKILLMD"
  fi

  # Symlink check
  if [ -L "$d" ]; then
    target=$(readlink "$d")
    echo "  SYMLINK:$target"
    if [ -e "$d" ]; then
      echo "  SYMLINK_OK"
    else
      echo "  SYMLINK_BROKEN"
    fi
  fi

  # Cross-references: grep *.md and *.json only for skill references
  grep -rh --include='*.md' --include='*.json' 'skills/[a-z0-9][-a-z0-9_]*' "$d" 2>/dev/null \
    | grep -oE 'skills/[a-z0-9][-a-z0-9_]*' | sort -u | sed 's/^/  REF:/' || true
done

echo ""
echo "=== SETTINGS ==="
# Extract structural info only (no raw credentials)
if [ -f ~/.claude/settings.json ]; then
  echo "SETTINGS:settings.json"
  if command -v jq >/dev/null 2>&1; then
    echo "  HOOKS:$(jq -r '.hooks // {} | keys | join(",")' ~/.claude/settings.json 2>/dev/null || echo "none")"
    echo "  MCP:$(jq -r '.mcpServers // {} | keys | join(",")' ~/.claude/settings.json 2>/dev/null || echo "none")"
    echo "  PERMISSIONS:$(jq -r '.permissions // {} | keys | join(",")' ~/.claude/settings.json 2>/dev/null || echo "none")"
  else
    echo "  JQ_UNAVAILABLE"
  fi
else
  echo "SETTINGS:MISSING"
fi
if [ -f ~/.claude/settings.local.json ]; then
  echo "SETTINGS:settings.local.json"
  if command -v jq >/dev/null 2>&1; then
    echo "  HOOKS:$(jq -r '.hooks // {} | keys | join(",")' ~/.claude/settings.local.json 2>/dev/null || echo "none")"
    echo "  MCP:$(jq -r '.mcpServers // {} | keys | join(",")' ~/.claude/settings.local.json 2>/dev/null || echo "none")"
  else
    echo "  JQ_UNAVAILABLE"
  fi
fi

echo ""
echo "=== RULES ==="
if [ -d ~/.claude/rules ]; then
  find ~/.claude/rules -name '*.md' -exec echo "RULE:{}" \;
else
  echo "NO_RULES_DIR"
fi

echo ""
echo "=== TEMPLATES ==="
if [ -d ~/.claude/templates ]; then
  find ~/.claude/templates -type f -exec echo "TEMPLATE:{}" \;
else
  echo "NO_TEMPLATES_DIR"
fi
```

Capture the full output. This is the raw data for Steps 2 and 3.

## Step 2: Graph Analysis

Run a second bash command that takes the SKILL/REF lines from Step 1 and builds
the dependency graph deterministically in awk/jq. Claude interprets results,
does NOT compute them.

```bash
#!/usr/bin/env bash
# Build dependency graph from scan output
# Expects Step 1 output piped or stored in a variable
set -euo pipefail
shopt -s nullglob

# Collect edges: for each skill, list what it references
echo "=== ADJACENCY LIST ==="
current=""
for d in ~/.claude/skills/*/; do
  name=$(basename "$d")
  refs=$(grep -rh --include='*.md' --include='*.json' 'skills/[a-z0-9][-a-z0-9_]*' "$d" 2>/dev/null \
    | grep -oE 'skills/[a-z0-9][-a-z0-9_]*' | sed 's|skills/||' | sort -u \
    | while read ref; do
        # Filter: only count if the referenced skill dir actually exists
        [ -d "$HOME/.claude/skills/$ref" ] && [ "$ref" != "$name" ] && echo "$ref"
      done | tr '\n' ',' | sed 's/,$//')
  if [ -n "$refs" ]; then
    echo "EDGE:$name -> $refs"
  else
    echo "EDGE:$name -> (none)"
  fi
done

echo ""
echo "=== IN-DEGREE ==="
# Compute in-degree for each skill
declare -A indeg 2>/dev/null || true
for d in ~/.claude/skills/*/; do
  target=$(basename "$d")
  count=$(grep -rl --include='*.md' --include='*.json' "skills/$target" ~/.claude/skills/*/  2>/dev/null \
    | grep -v "/$target/" | wc -l | tr -d ' ')
  echo "INDEG:$target=$count"
done

echo ""
echo "=== ORPHANS ==="
# Skills with zero in-degree (never referenced by another skill)
for d in ~/.claude/skills/*/; do
  name=$(basename "$d")
  count=$(grep -rl --include='*.md' --include='*.json' "skills/$name" ~/.claude/skills/*/ 2>/dev/null \
    | grep -v "/$name/" | wc -l | tr -d ' ')
  [ "$count" -eq 0 ] && echo "ORPHAN:$name"
done

echo ""
echo "=== BROKEN SYMLINKS ==="
find ~/.claude/skills/ -maxdepth 1 -type l ! -exec test -e {} \; -print 2>/dev/null \
  | while read lnk; do
      echo "BROKEN:$(basename "$lnk") -> $(readlink "$lnk")"
    done

echo ""
echo "=== DEAD REFERENCES ==="
# References to skills that don't exist
for d in ~/.claude/skills/*/; do
  name=$(basename "$d")
  grep -rh --include='*.md' --include='*.json' 'skills/[a-z0-9][-a-z0-9_]*' "$d" 2>/dev/null \
    | grep -oE 'skills/[a-z0-9][-a-z0-9_]*' | sed 's|skills/||' | sort -u \
    | while read ref; do
        [ ! -d "$HOME/.claude/skills/$ref" ] && echo "DEAD:$name references skills/$ref (not installed)"
      done || true
done
```

Analyze the output:
1. **Hub nodes:** List the top 3 skills by in-degree. Any with in-degree > 5 = HIGH FRAGILITY.
2. **Orphans:** Skills with zero in-degree. These are installed but nothing references them.
   Note: some orphans are expected (top-level entry points like `office-hours`).
3. **Broken symlinks:** Symlinks in skills/ that point to non-existent targets.
4. **Dead references:** Skills that reference other skills that aren't installed.
5. **Circular dependencies:** If the adjacency list shows A -> B and B -> A, flag it.
   Best-effort detection in v0.2.0.

Present findings in a clear summary.

## Step 3: Filesystem Health

Run filesystem health checks:

```bash
#!/usr/bin/env bash
set -euo pipefail

echo "=== FILESYSTEM HEALTH ==="

# Disk usage per subdirectory
echo "DISK USAGE:"
du -sh ~/.claude/ 2>/dev/null | sed 's/^/  TOTAL:/'
for subdir in skills plans file-history sessions session-env shell-snapshots ide cache downloads backups plugins projects spec tasks telemetry templates rules; do
  [ -d "$HOME/.claude/$subdir" ] && du -sh "$HOME/.claude/$subdir" 2>/dev/null | sed "s/^/  $subdir:/"
done

# history.jsonl
echo ""
echo "HISTORY:"
if [ -f ~/.claude/history.jsonl ]; then
  size=$(du -sh ~/.claude/history.jsonl 2>/dev/null | awk '{print $1}')
  lines=$(wc -l < ~/.claude/history.jsonl 2>/dev/null | tr -d ' ')
  echo "  SIZE:$size"
  echo "  LINES:$lines"
else
  echo "  MISSING"
fi

# Stale sessions (mtime > 24h)
echo ""
echo "SESSIONS:"
total=$(find ~/.claude/sessions/ -type f 2>/dev/null | wc -l | tr -d ' ')
stale=$(find ~/.claude/sessions/ -type f -mtime +1 2>/dev/null | wc -l | tr -d ' ')
echo "  TOTAL:$total"
echo "  STALE:$stale"

# Temp files
echo ""
echo "TEMP FILES:"
tmp_count=$(find ~/.claude/ -maxdepth 2 \( -name '*.tmp' -o -name '*.bak' -o -name '.pending-*' \) 2>/dev/null | wc -l | tr -d ' ')
echo "  COUNT:$tmp_count"

# Empty directories
echo ""
echo "EMPTY DIRS:"
find ~/.claude/ -maxdepth 2 -type d -empty 2>/dev/null | wc -l | tr -d ' ' | sed 's/^/  COUNT:/'

# Settings files exist
echo ""
echo "CONFIG FILES:"
[ -f ~/.claude/settings.json ] && echo "  settings.json:OK" || echo "  settings.json:MISSING"
[ -f ~/.claude/settings.local.json ] && echo "  settings.local.json:OK" || echo "  settings.local.json:MISSING"
```

## Step 4: Waza Integration (optional, unscored)

Skip this step if `--quick` was passed or if waza is not installed.

```bash
if [ -f ~/.claude/skills/waza/health/scripts/collect-data.sh ]; then
  echo "WAZA_AVAILABLE"
else
  echo "WAZA_NOT_INSTALLED"
fi
```

If available, run waza's data collection:

```bash
bash ~/.claude/skills/waza/health/scripts/collect-data.sh
```

Include the output as an **unscored appendix** in the report. Do NOT fold waza's
findings into the scored composite. Waza output is CWD-dependent (reflects the
current project's config, not ~/.claude/ globally), so including it in the trend
score would make scores fluctuate based on which directory the user runs from.

If waza is not installed: "Waza not installed. Config hygiene checks skipped.
Install waza for config correctness auditing."

## Step 5: Score + Trend

Score across 4 buckets (each 0-10). Waza is excluded from the scored composite.

| Bucket | What it measures | Weight | Calibration |
|--------|-----------------|--------|-------------|
| Structure | Proper skill organization | 25% | 10 = all skills have SKILL.md with name+version+description; 7 = 1-3 missing version; 4 = 5+ missing SKILL.md |
| References | No dead refs, no circulars | 35% | 10 = zero dead refs, zero orphans worth flagging; 7 = 1-2 orphans only; 4 = 3+ dead refs or circulars |
| Integrity | No broken symlinks | 25% | 10 = zero broken symlinks; 7 = 1 broken; 4 = 3+ broken or unreadable SKILL.md |
| Hygiene | No stale sessions, temp files | 15% | 10 = zero stale sessions, history.jsonl < 1MB; 7 = some stale; 4 = history > 10MB or 50+ stale |

Compute composite: `(Structure * 0.25) + (References * 0.35) + (Integrity * 0.25) + (Hygiene * 0.15)`

**Trend tracking:** Save a snapshot after scoring:

```bash
mkdir -p ~/.gstack/health
SNAPSHOT='{"ts":"'"$(date -u +%Y-%m-%dT%H:%M:%SZ)"'","score":SCORE,"structure":S,"references":R,"integrity":I,"hygiene":H,"skills":N}'
echo "$SNAPSHOT" >> ~/.gstack/health/claude-home-health-history.jsonl
```

Replace SCORE, S, R, I, H, N with actual values.

If prior history exists, show delta:

```bash
if [ -f ~/.gstack/health/claude-home-health-history.jsonl ]; then
  PREV=$(tail -2 ~/.gstack/health/claude-home-health-history.jsonl | head -1 | jq -r '.score' 2>/dev/null || echo "")
  [ -n "$PREV" ] && echo "PREVIOUS_SCORE:$PREV" || echo "FIRST_RUN"
else
  echo "FIRST_RUN"
fi
```

If `jq` fails to parse (corrupt JSONL), fall back to "First run (no prior data)."

## Step 6: Present Dashboard

Present the final report in this format:

```
~/.CLAUDE HEALTH DASHBOARD
===========================

Date:    {date}
Skills:  {N} installed
Score:   {X.X} / 10 {(up/down Y.Y from last run) or (first run)}

Bucket         Score   Status     Details
------         -----   ------     -------
Structure      X/10    STATUS     {details}
References     X/10    STATUS     {details}
Integrity      X/10    STATUS     {details}
Hygiene        X/10    STATUS     {details}

DEPENDENCY GRAPH
=================
Hubs:    {top 3 by in-degree}
Orphans: {list or "none"}
Dead refs: {count and details or "none"}
Broken symlinks: {list or "none"}
Circular deps: {list or "none detected"}

FILESYSTEM
===========
Total size: {du output}
  {per-subdirectory breakdown}
History: {size, line count}
Sessions: {total active, stale count}
Temp files: {count}

{If waza ran:}
WAZA CONFIG HEALTH (unscored, CWD-dependent)
=============================================
{waza output verbatim}
```

Status labels: 10 = CLEAN, 7-9 = WARNING, 4-6 = NEEDS WORK, 0-3 = CRITICAL.

## Step 7: Recommendations

List top issues by impact (weight * score deficit), highest first:

```
RECOMMENDATIONS
================
1. [HIGH] {description} ({bucket}: {score}/10, weight {weight}%)
2. [MED]  {description}
3. [LOW]  {description}
```

If all buckets score 9+, print: "Your ~/.claude/ setup looks healthy. No action needed."

## Rules

- **Read-only.** Report findings, do not fix anything automatically.
- **No raw credentials.** Never dump settings.json or settings.local.json in full.
  Extract structural keys only (hook names, MCP server names, permission patterns).
- **Graph computation in bash.** Adjacency lists, in-degree, orphan detection, and
  broken symlink detection are all done in bash. Claude interprets the structured
  output and presents findings. Claude does NOT perform graph algorithms mentally.
- **Waza is unscored.** Waza output appears as an appendix but does not affect the
  composite score. This is because waza's output is CWD-dependent.
- **Graceful degradation.** If waza is missing, skip it with a message. If jq is
  missing, skip structural settings extraction. If history is corrupt, treat as first run.

## Breaking Changes from v0.1.0

- `--scope` flag removed. The old `--scope docs/<family>/` targeted home-setup's
  doc families. This skill now targets ~/.claude/ globally. Use `/align-feature-contract`
  for doc triplet checks instead.
- `--layer` flag removed. The 9-layer model is replaced by a 5-step architecture
  with 4 scored buckets.
- Waza integration is now an unscored appendix, not a scored layer.
