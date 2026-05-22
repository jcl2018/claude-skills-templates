---
name: CJ_goal_auto
description: "DEPRECATED ALIAS (F000027, sunsets v6.0.0) — superseded by the two-verb refactor. This thin alias prints a one-line deprecation banner then routes to /cj_goal_feature. Use /cj_goal_feature to build a feature end-to-end (topic → reviewable PR) or /cj_goal_defect to fix a bug (description → shipped fix). Removal is deferred to v6.0.0; in-flight items finish under the old skill via skills-deploy install --include-deprecated."
version: 5.0.6
allowed-tools:
  - Skill
---

## Deprecation Banner

This skill is a thin alias retained for backwards-compatible muscle memory. The
F000027 two-verb refactor replaced the one-liner-to-deployed `/CJ_goal_auto`
front door with two intent-named verbs: `/cj_goal_feature` (build a feature) and
`/cj_goal_defect` (fix a bug). The PR is the human gate in the new verbs — there
is no automatic merge/deploy (it was unsafe-by-construction here; see F000027).

Print this banner before doing anything else:

```
[DEPRECATED] /CJ_goal_auto is deprecated; use /cj_goal_feature instead (or /cj_goal_defect for a bug fix). Sunsets in v6.0.0.
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
STOP at the PR). If the work is a bug fix rather than a feature, stop and tell
the user to invoke `/cj_goal_defect "<bug description>"` instead.

The legacy orchestration logic remains at `skills/CJ_goal_auto/auto.md` (and the
GATE #2 helper `scripts/cj-handoff-gate.sh`) for reference until the v6.0.0
removal; it is no longer the active entry point.
