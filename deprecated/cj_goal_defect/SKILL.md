---
name: cj_goal_defect
description: "DEPRECATED ALIAS (casing-fix follow-up to F000027, sunsets v6.0.0) — superseded by uppercase /CJ_goal_defect for family-name consistency with CJ_goal_investigate / CJ_goal_todo_fix. This thin alias prints a one-line deprecation banner then routes to /CJ_goal_defect. Removal is deferred to v6.0.0; in-flight pipelines finish under the lowercase name via skills-deploy install --include-deprecated."
version: 5.0.12
allowed-tools:
  - Skill
---

## Deprecation Banner

This skill is a thin alias retained for backwards-compatible muscle memory. The
casing-fix refactor (v5.0.12, F000031) flipped the F000027 verbs from lowercase
to uppercase for consistency with the rest of the CJ_* family
(CJ_personal-workflow, CJ_system-health, CJ_goal_investigate, CJ_goal_todo_fix,
etc.).

Print this banner before doing anything else:

```
[DEPRECATED] /cj_goal_defect is deprecated; use /CJ_goal_defect instead. Sunsets in v6.0.0.
See CHANGELOG.md (v5.0.12 casing-fix) for the rationale and migration guidance.
```

## Routing

Delegate to `/CJ_goal_defect` with the same arguments. Use the Skill tool to
invoke the canonical verb:

```
Skill: CJ_goal_defect, args: "$@"
```

`/CJ_goal_defect` (`skills/CJ_goal_defect/SKILL.md`) runs the full defect
pipeline (worktree → scaffold draft → `/investigate` subagent under Iron-Law →
promote draft to canonical D000NNN → RCA + test-plan → `/CJ_qa-work-item` →
`/ship` Gate #2 → `/land-and-deploy`). This shim does NOT create its own
worktree — the canonical skill does that.
