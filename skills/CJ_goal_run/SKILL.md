---
name: CJ_goal_run
description: "DEPRECATED ALIAS (F000027, sunsets v6.0.0) — superseded by the two-verb refactor. This thin alias prints a one-line deprecation banner then routes to /cj_goal_feature. Use /cj_goal_feature to build a feature end-to-end (topic → reviewable PR) or /cj_goal_defect to fix a bug (description → shipped fix). Removal is deferred to v6.0.0; in-flight pipelines finish under the old skill via skills-deploy install --include-deprecated."
version: 5.0.6
allowed-tools:
  - Skill
---

## Deprecation Banner

This skill is a thin alias retained for backwards-compatible muscle memory. The
F000027 two-verb refactor split the cluttered `/CJ_goal_run` front door into two
intent-named verbs: `/cj_goal_feature` (build a feature) and `/cj_goal_defect`
(fix a bug).

Print this banner before doing anything else:

```
[DEPRECATED] /CJ_goal_run is deprecated; use /cj_goal_feature instead (or /cj_goal_defect for a bug fix). Sunsets in v6.0.0.
See CHANGELOG.md (F000027 two-verb refactor) for the rationale and migration guidance.
```

## Routing

Delegate to `/cj_goal_feature` with the same arguments. Use the Skill tool to
invoke the canonical verb:

```
Skill: cj_goal_feature, args: "$@"
```

`/cj_goal_feature` (`skills/cj_goal_feature/SKILL.md`) runs the feature pipeline
(worktree → `/office-hours` inline → scaffold/impl/qa leaf subagents → `/ship` →
STOP at the PR; it creates its own worktree, so this shim does not). If the work
is a bug fix rather than a feature, stop and tell the user to invoke
`/cj_goal_defect "<bug description>"` instead. Telemetry for the new verb writes
to `~/.gstack/analytics/CJ_goal_feature.jsonl`.

The legacy orchestration logic remains at `skills/CJ_goal_run/run.md` for
reference until the v6.0.0 removal; it is no longer the active entry point.
