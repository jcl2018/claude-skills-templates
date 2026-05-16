---
name: CJ_run
description: "DEPRECATED ALIAS — renamed to /CJ_goal_run in v4.0.0. This thin alias prints a one-line deprecation banner then delegates to /CJ_goal_run with the same args. Will be removed in v5.0.0."
version: 4.0.0
allowed-tools:
  - Skill
---

## Deprecation Banner

This skill is a thin alias retained for backwards-compatible muscle memory.

```
[DEPRECATED] /CJ_run renamed to /CJ_goal_run; will be removed in v5.0.0.
See CHANGELOG.md v4.0.0 for the rename rationale and migration guidance.
```

## Routing

Delegate to `/CJ_goal_run` with the same arguments. Use the Skill tool to invoke
the canonical skill:

```
Skill: CJ_goal_run, args: "$@"
```

The canonical skill at `skills/CJ_goal_run/SKILL.md` runs the unified pipeline
(autoplan → scaffold → impl → QA → ship → deploy). Telemetry writes go to
`~/.gstack/analytics/CJ_goal_run.jsonl`; the sunset trip-wire reads both the new
path and the legacy `CJ_run.jsonl` so historical invocations are preserved
during the v4.x grace window.
