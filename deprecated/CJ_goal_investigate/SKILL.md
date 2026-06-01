---
name: CJ_goal_investigate
description: "DEPRECATED ALIAS (F000027 closure, sunsets v6.0.0) — superseded by /CJ_goal_defect once defect proved out (D000026 / v5.0.14 / PR #184). Thin alias prints a one-line deprecation banner then delegates to /CJ_goal_defect for non-D-id args. Bare D-id args (`^D[0-9]{6}$`) are rejected — forwarding would slug the D-id as a description and mint a new D-id. To ship a fix for an existing D-id, install the deprecated skill directly via `skills-deploy install --include-deprecated`. Removal at v6.0.0."
version: 5.0.15
allowed-tools:
  - Skill
  - Bash
---

## Deprecation Banner

This skill is a thin alias retained for backwards-compatible muscle memory. The
F000027 two-verb refactor split the cluttered front door into two intent-named
verbs: `/CJ_goal_feature` (build a feature) and `/CJ_goal_defect` (fix a bug).
`/CJ_goal_investigate` was kept open-fate until `/CJ_goal_defect` proved out;
defect earned its first green ship (D000026 / v5.0.14 / PR #184), so investigate
retires here as the F000027 closure.

Print this banner before doing anything else:

```
[DEPRECATED] /CJ_goal_investigate is deprecated; use /CJ_goal_defect instead. Sunsets in v6.0.0.
See CHANGELOG.md (F000027 closure) for the rationale and migration guidance.
```

## Routing

`/CJ_goal_investigate` takes a `D-id` or fragment as its sole positional arg.
`/CJ_goal_defect` takes a bug description. The two argument shapes are NOT
interchangeable: forwarding a bare `D-id` (e.g. `D000019`) to `/CJ_goal_defect`
would slug it as a description and mint a NEW D-id — corrupting work-item
tracking.

The shim therefore branches on argument shape BEFORE delegating:

```bash
# Inspect the first positional argument (after flags like --dry-run).
_ARG="${1-}"

# Trim leading/trailing whitespace — hardens the D-id rejection gate against
# clipboard-paste artifacts (" D000019", "D000019 ") that would otherwise slip
# past the anchored regex and get slugged as a description by /CJ_goal_defect.
_ARG="${_ARG#"${_ARG%%[![:space:]]*}"}"
_ARG="${_ARG%"${_ARG##*[![:space:]]}"}"

# D-id rejection regex: ^D[0-9]{6}$ (case-insensitive).
if printf '%s' "$_ARG" | grep -qiE '^D[0-9]{6}$'; then
  cat <<'EOF'
[DEPRECATED] /CJ_goal_investigate has been retired. D-id args cannot be forwarded to /CJ_goal_defect (would slug as description and mint a new D-id). To ship a fix for an existing D-id, run the deprecated skill directly: skills-deploy install --include-deprecated && /CJ_goal_investigate <D-id>. To root-cause and ship a NEW bug: /CJ_goal_defect "<bug description>".
EOF
  exit 0
fi
```

On any non-D-id-shaped arg (a fragment, a free-text description, or no arg),
print the banner above and delegate to `/CJ_goal_defect` with the verbatim
arguments via the Skill tool:

```
Skill: CJ_goal_defect, args: "$@"
```

`/CJ_goal_defect` (`skills/CJ_goal_defect/SKILL.md`) runs the full defect
pipeline (worktree → scaffold draft → `/investigate` subagent under Iron-Law →
promote draft to canonical D000NNN → RCA + test-plan → `/CJ_qa-work-item` →
`/ship` Gate #2 → `/land-and-deploy`). This shim does NOT create its own
worktree — the canonical skill does that.

The legacy v1.1 pipeline + test scripts remain alongside this SKILL.md
(`deprecated/CJ_goal_investigate/pipeline.md` + `scripts/`) as archival
reference until the v6.0.0 removal; they are NOT catalog-registered and NOT
deployed.
