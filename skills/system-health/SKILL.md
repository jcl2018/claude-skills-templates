---
name: system-health
description: "~/.claude/ health dashboard with dependency graph and usage trends. Scans installed skills, builds a dependency graph, checks filesystem health, and surfaces skill usage analytics with behavioral topology overlay. Produces a scored report with trend tracking."
version: 0.3.0
allowed-tools:
  - Bash
  - Read
  - Glob
  - Grep
  - AskUserQuestion
---

## Preamble

Log skill usage so the usage trends section can track this skill too:

```bash
mkdir -p ~/.gstack/analytics
echo '{"skill":"system-health","ts":"'"$(date -u +%Y-%m-%dT%H:%M:%SZ)"'","repo":"'"$(basename "$(git rev-parse --show-toplevel 2>/dev/null)" 2>/dev/null || echo unknown)"'"}' >> ~/.gstack/analytics/skill-usage.jsonl 2>/dev/null || true
```

# /system-health — ~/.claude/ Health Dashboard

Checks the physical health of your `~/.claude/` folder and surfaces skill usage
trends. Scans all installed skills, builds a dependency graph, detects orphans and
broken references, checks filesystem hygiene, overlays actual usage data from
`~/.gstack/analytics/` to show which skills you use (and which you don't), and
**Not** a per-repo code quality check (that's gstack `/health`).
This is the filesystem, topology, and usage analytics layer.

## Usage

- `/system-health` — full health check with dependency graph
- `/system-health --quick` — filesystem checks only, skip usage trends

## Step 0: Parse arguments

Check if the user passed `--quick`. If so, skip Step 4.5 (usage trends).

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

## Step 4.5: Usage Trends (unscored)

Reads `~/.gstack/analytics/skill-usage.jsonl` and produces a usage analytics
dashboard. This section is **unscored** because the data
lives in `~/.gstack/`, not `~/.claude/`. Does not affect the 4-bucket composite.

Skip this step if `--quick` was passed. Skip if jq is not available (print:
"jq required for usage trends. Install jq to enable.").

### Data Model

The JSONL contains three schemas plus non-run events that must be filtered out:

- **Simple:** `{"skill":"X","ts":"...","repo":"Y"}` — no duration or outcome
- **Intermediate:** `{"skill":"X","ts":"...","duration_s":N,"outcome":"...","browse":"...","session":"..."}` — has duration/outcome but no `v` field, no repo field
- **v1:** `{"v":1,"skill":"X","ts":"...","duration_s":N,"outcome":"...","_repo_slug":"...","event_type":"skill_run",...}` — v1 entries may also have `event_type: "upgrade_prompted"` which are NOT skill runs

**Filter rule:** Exclude any entry where `event` is present, OR `event_type` is present
and not equal to `"skill_run"`, OR `skill` is empty/null/missing.

**Duration sanitization:** Some entries contain Unix timestamps instead of actual
durations in the `duration_s` field (a known upstream bug). Any `duration_s > 86400`
(24 hours) is treated as null. This prevents corrupt values from skewing averages.

**Repo normalization:** `.repo // (._repo_slug | sub("^[^-]+-"; "")) // "unknown"`

### Bash/jq Reducer

Run a single bash script that normalizes, aggregates, and emits structured lines.
Claude interprets the output. Claude does NOT compute stats.

```bash
#!/usr/bin/env bash
set -euo pipefail

USAGE_FILE="${HOME}/.gstack/analytics/skill-usage.jsonl"

if [ ! -f "$USAGE_FILE" ] || [ ! -s "$USAGE_FILE" ]; then
  echo "USAGE_NO_DATA"
  exit 0
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "USAGE_NO_JQ"
  exit 0
fi

# Collect installed skill names from ~/.claude/skills/
INSTALLED_SKILLS=""
for d in ~/.claude/skills/*/; do
  [ -d "$d" ] && INSTALLED_SKILLS="$INSTALLED_SKILLS $(basename "$d")"
done
INSTALLED_COUNT=$(echo $INSTALLED_SKILLS | wc -w | tr -d ' ')

# Normalize and filter all entries into a clean stream, then aggregate
jq -r --arg now "$(date -u +%Y-%m-%dT%H:%M:%SZ)" --arg installed "$INSTALLED_SKILLS" '
# Filter: must be a skill run
select(
  (.event | not) and
  ((.event_type | not) or .event_type == "skill_run") and
  (.skill | length > 0)
) |
# Normalize repo
(.repo // (._repo_slug | if . then sub("^[^-]+-"; "") else null end) // "unknown") as $repo |
# Normalize duration (may be string or number, sanitize timestamps > 24h)
(if .duration_s then
  ((.duration_s | tostring | tonumber) as $d | if $d <= 86400 then $d else null end)
else null end) as $dur |
# Output normalized record
{
  skill: .skill,
  ts: .ts,
  repo: $repo,
  duration_s: $dur,
  outcome: (.outcome // null),
  hour: (.ts | split("T")[1] | split(":")[0]),
  day: (.ts | split("T")[0])
}
' "$USAGE_FILE" 2>/dev/null | jq -s '
# Now we have an array of normalized records

# Date calculations
(now | split("T")[0]) as $today |
(map(.day) | sort) as $days |
($days | first) as $first_day |
($days | last) as $last_day |
([$days | unique | length] | first) as $date_range |

# 7-day comparison: compute cutoff dates
# We use string comparison since dates are ISO format
($days | last) as $end |

# Total overview
{
  total_runs: length,
  unique_skills: ([.[].skill] | unique | length),
  date_range: $date_range,
  unique_repos: ([.[].repo] | unique | length),
  first_day: $first_day,
  last_day: $last_day
} as $overview |

# Per-skill breakdown
(group_by(.skill) | map({
  skill: .[0].skill,
  runs: length,
  pct: ((length * 1000 / ($overview.total_runs)) | floor / 10),
  last: ([.[].day] | sort | last),
  durations: [.[] | select(.duration_s != null) | .duration_s],
  outcomes: [.[] | select(.outcome != null) | .outcome]
}) | sort_by(-.runs)) as $skills |

# Per-skill with computed stats
($skills | map(. + {
  avg_dur: (if (.durations | length) > 0 then ((.durations | add) / (.durations | length) | floor) else null end),
  min_dur: (if (.durations | length) > 0 then (.durations | min) else null end),
  max_dur: (if (.durations | length) > 0 then (.durations | max) else null end),
  success_pct: (if (.outcomes | length) > 0 then ((([.outcomes[] | select(. == "success")] | length) * 100 / (.outcomes | length)) | floor) else null end),
  error_pct: (if (.outcomes | length) > 0 then ((([.outcomes[] | select(. == "error")] | length) * 100 / (.outcomes | length)) | floor) else null end),
  abort_pct: (if (.outcomes | length) > 0 then ((([.outcomes[] | select(. == "abort")] | length) * 100 / (.outcomes | length)) | floor) else null end),
  has_dur: ((.durations | length) > 0)
})) as $skill_stats |

# Per-repo breakdown
(group_by(.repo) | map({
  repo: .[0].repo,
  runs: length,
  top_skill: (group_by(.skill) | sort_by(-length) | first | .[0].skill),
  top_pct: (group_by(.skill) | sort_by(-length) | first | ((length * 100 / (. as $parent | $parent | length)) | floor))
}) | sort_by(-.runs)) as $repos |

# Fix repo top_pct calculation
(group_by(.repo) | map(
  (length) as $repo_total |
  {
    repo: .[0].repo,
    runs: $repo_total,
    top_skill: (group_by(.skill) | sort_by(-length) | first | .[0].skill),
    top_pct: (group_by(.skill) | sort_by(-length) | first | ((length * 100 / $repo_total) | floor))
  }
) | sort_by(-.runs)) as $repos |

# Peak hours
(group_by(.hour) | map({hour: .[0].hour, runs: length}) | sort_by(-.runs) | .[0:6]) as $hours |

# 7-day comparison
([.[] | select(.day > ($last_day | split("-") | .[0:2] | join("-")) + "-" + (($last_day | split("-")[2] | tonumber) - 6 | tostring | if length == 1 then "0" + . else . end))] | length) as $last_7d |
# This is approximate; exact date math in jq is hard. We do string compare.

# Installed vs used
($installed | split(" ") | map(select(length > 0))) as $inst_list |
([$skill_stats[].skill] | unique) as $used_list |
($inst_list | map(select(. as $s | $used_list | index($s) | not))) as $never_used |

# Anomaly: stopped-using (active 14-28 days ago, zero in last 14 days)
# Approximate with day string comparison
($skill_stats | map(select(.runs >= 3)) | map(
  {skill: .skill, last: .last, runs: .runs}
)) as $candidates |

# Anomaly: long-and-failing
($skill_stats | map(select(.has_dur and (.durations | length) >= 5))) as $dur_skills |
(if ($dur_skills | length) > 0 then
  ([$dur_skills[].avg_dur] | sort | .[length/2 | floor]) 
else 0 end) as $median_dur |
($dur_skills | map(select(.avg_dur > $median_dur and .success_pct != null and .success_pct < 80))) as $long_failing |

# Anomaly: discovery-gap (repos with 10+ runs but no review/health/investigate)
($repos | map(select(.runs >= 10))) as $active_repos |

# Output structured lines
"USAGE_OVERVIEW: total_runs=\($overview.total_runs), unique_skills=\($overview.unique_skills), date_range=\($overview.date_range)d, unique_repos=\($overview.unique_repos), first_day=\($overview.first_day), last_day=\($overview.last_day)",
"USAGE_INSTALLED_VS_USED: installed=\($inst_list | length), ever_used=\($used_list | length), never_used=\($never_used | length)",
(if ($never_used | length) > 0 then "USAGE_NEVER_USED: \($never_used | join(","))" else empty end),
($skill_stats[] | "USAGE_SKILL: skill=\(.skill), runs=\(.runs), pct=\(.pct)%, last=\(.last), avg_dur=\(.avg_dur // "N/A"), min_dur=\(.min_dur // "N/A"), max_dur=\(.max_dur // "N/A"), success=\(.success_pct // "N/A"), error=\(.error_pct // "N/A"), abort=\(.abort_pct // "N/A")"),
($repos[] | "USAGE_REPO: repo=\(.repo), runs=\(.runs), top_skill=\(.top_skill), top_pct=\(.top_pct)%"),
($hours[] | "USAGE_HOUR: hour=\(.hour), runs=\(.runs)"),
($long_failing[] | "USAGE_ANOMALY: type=long-and-failing, skill=\(.skill), avg_dur=\(.avg_dur)s, success=\(.success_pct)%"),
"USAGE_END"
' 2>/dev/null || echo "USAGE_PARSE_ERROR"

# Discovery gap detection (separate pass — needs per-repo skill lists)
jq -r '
select(
  (.event | not) and
  ((.event_type | not) or .event_type == "skill_run") and
  (.skill | length > 0)
) |
(.repo // (._repo_slug | if . then sub("^[^-]+-"; "") else null end) // "unknown") as $repo |
{skill: .skill, repo: $repo}
' "$USAGE_FILE" 2>/dev/null | jq -s '
group_by(.repo) | map(
  select(length >= 10) |
  {
    repo: .[0].repo,
    total: length,
    skills: ([.[].skill] | unique)
  } |
  select(
    (.skills | index("review") | not) and
    (.skills | index("health") | not) and
    (.skills | index("investigate") | not)
  )
) | .[] | "USAGE_ANOMALY: type=discovery-gap, repo=\(.repo), total_runs=\(.total), missing=review,health,investigate"
' 2>/dev/null || true
```

If the output is `USAGE_NO_DATA`: print "No usage data found at ~/.gstack/analytics/skill-usage.jsonl. Run skills with gstack to start collecting." and skip to Step 5.

If the output is `USAGE_NO_JQ`: print "jq required for usage trends. Install jq to enable." and skip to Step 5.

If the output is `USAGE_PARSE_ERROR`: print "Failed to parse usage data. File may be corrupt." and skip to Step 5.

### Interpreting the Output

Claude reads the structured `USAGE_*` lines and presents findings. Claude does NOT
recompute any numbers. Specific interpretation guidance:

1. **USAGE_OVERVIEW**: Present as the header line of the usage section.
2. **USAGE_INSTALLED_VS_USED**: Calculate the gap. If never_used > 50% of installed,
   note this prominently. Some never-used skills are expected (framework internals
   like `gstack`, `connect-chrome`). Only flag user-invokable skills.
3. **USAGE_SKILL**: Present as a sorted table. Format `avg_dur` as human-readable
   (seconds -> "Xm Ys"). Show "N/A" when duration/success data is missing.
4. **USAGE_REPO**: Present as a per-repo breakdown table.
5. **USAGE_HOUR**: Present as a simple bar chart using block characters (█).
   Top 4-6 hours only.
6. **USAGE_ANOMALY**: Present under an "INSIGHTS" heading with `!` prefix.
   - `stopped-using`: "STOPPED USING: /{skill} — last used {days} ago (was active before)"
   - `long-and-failing`: "LONG & FAILING: /{skill} — avg {dur}, {success}% success rate"
   - `discovery-gap`: "DISCOVERY GAP: {repo} repo has no /review, /health, or /investigate usage"
7. **USAGE_NEVER_USED**: List under the INSTALLED vs USED section. Truncate to first
   10 skills if the list is long, with "(+N more)" suffix.

## Step 5: Score + Trend

Score across 4 buckets (each 0-10). Usage trends are excluded from the scored composite.

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

{If Step 4.5 ran:}
SKILL USAGE TRENDS (unscored, from ~/.gstack/analytics/)
=========================================================
Period:    {first_day} to {last_day} ({date_range} days, {total_runs} skill runs)
Skills:    {ever_used} active / {installed} installed ({never_used} never used)
Trend:     Last 7d: {N} runs | Prior 7d: {N} runs ({delta}%)

TOP SKILLS
Skill              Runs    %     Last Used    Avg Dur   Success
-----              ----    -     ---------    -------   -------
{rows from USAGE_SKILL lines, duration as "Xm Ys" or "N/A"}

PER-REPO BREAKDOWN
Repo                 Runs   Top Skill         %
----                 ----   ---------         -
{rows from USAGE_REPO lines}

PEAK HOURS (UTC)
{hour}  {bar}  {runs} runs
{top 4-6 hours from USAGE_HOUR lines, bars using █ characters}

INSTALLED vs USED
Installed: {N} | Ever used: {N} | Never used: {N}
Never used: {comma-separated list from USAGE_NEVER_USED, max 10 with (+N more)}

INSIGHTS
{! lines from USAGE_ANOMALY, or "No anomalies detected." if none}
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

If usage trends ran (Step 4.5), also include usage-based recommendations after the
scored recommendations. These are **unscored** and appear under a separate heading:

```
USAGE INSIGHTS (unscored)
==========================
{If USAGE_ANOMALY lines exist, list each as a recommendation with context:}
- [INFO] Stopped using /review 13 days ago. Consider adding it back to your workflow.
- [INFO] /autoplan has a 60% success rate with 12m avg duration. Check for recurring errors.
- [INFO] exploration repo has no /review or /health usage. These skills may help.
{If never_used > 50% of installed:}
- [INFO] {N} of {installed} skills have never been used. Run '/system-health' with
  individual skill names to learn what they do, or remove unused skills to reduce clutter.
```

## Rules

- **Read-only.** Report findings, do not fix anything automatically.
- **No raw credentials.** Never dump settings.json or settings.local.json in full.
  Extract structural keys only (hook names, MCP server names, permission patterns).
- **Graph computation in bash.** Adjacency lists, in-degree, orphan detection, and
  broken symlink detection are all done in bash. Claude interprets the structured
  output and presents findings. Claude does NOT perform graph algorithms mentally.
- **Usage trends are unscored.** Usage data lives in `~/.gstack/analytics/`, not
  `~/.claude/`. Unscored appendix with separate recommendations.
- **Usage computation in bash/jq.** All aggregation, normalization, and anomaly
  detection is done in the bash/jq reducer script. Claude interprets the structured
  `USAGE_*` output lines. Claude does NOT compute stats, percentages, or anomalies.
- **Graceful degradation.** If jq is missing, skip structural settings extraction
  and usage trends. If history is corrupt, treat as first run. If usage data is
  missing or corrupt, skip with message.

## Changes in v0.3.0

- Added Step 4.5: Usage Trends (unscored). Reads `~/.gstack/analytics/skill-usage.jsonl`
  and surfaces skill usage analytics with per-skill breakdown, per-repo breakdown,
  peak hours, installed-vs-used overlay, and three rule-based insights.
- Added usage-based recommendations (unscored) to Step 7.
- No breaking changes from v0.2.0.

## Breaking Changes from v0.1.0

- `--scope` flag removed. The old `--scope docs/<family>/` targeted home-setup's
  doc families. This skill now targets ~/.claude/ globally. Use `/align-feature-contract`
  for doc triplet checks instead.
- `--layer` flag removed. The 9-layer model is replaced by a 5-step architecture
  with 4 scored buckets.
- Waza integration removed (was an unscored appendix in v0.2.0).
