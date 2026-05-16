---
name: CJ_goal
description: "DEPRECATED ALIAS — renamed to /CJ_goal_todo_fix in v4.0.0. This thin alias prints a one-line deprecation banner then delegates to /CJ_goal_todo_fix with the same args. Will be removed in v5.0.0."
version: 4.0.0
allowed-tools:
  - Skill
---

## Deprecation Banner

This skill is a thin alias retained for backwards-compatible muscle memory.

```
[DEPRECATED] /CJ_goal renamed to /CJ_goal_todo_fix; will be removed in v5.0.0.
See CHANGELOG.md v4.0.0 for the rename rationale and migration guidance.
```

## Routing

Delegate to `/CJ_goal_todo_fix` with the same arguments. Use the Skill tool to
invoke the canonical skill:

```
Skill: CJ_goal_todo_fix, args: "$@"
```

The canonical skill at `skills/CJ_goal_todo_fix/SKILL.md` runs the TODO-to-PR
auto-resolve drain. Telemetry writes go to
`~/.gstack/analytics/CJ_goal_todo_fix.jsonl`; the legacy `CJ_goal.jsonl` history
is preserved on disk during the v4.x grace window (not actively read in v4.0
since the canonical skill does not yet implement a sunset trip-wire).
