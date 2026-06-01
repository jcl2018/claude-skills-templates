---
skill-name: "CJ_system-health"
version: 2.0.0
status: active
created: "2026-06-01"
last-updated: "2026-06-01"
---

# Skill Usage: CJ_system-health

## When to use

- "check installed skills", "skill system health", "skills status" (routing rule)
- You want a scored snapshot of `~/.claude/` — dependency graph, filesystem health, usage
  analytics with behavioral topology, optional waza config hygiene
- Periodic checkup before/after a `skills-deploy install` or upstream `git pull`
- Quick variant: `/CJ_system-health --quick` skips the heavy waza pass

## When NOT to use

- You want to know what work to do next — that's `/CJ_suggest`, not a health dashboard
- You want to fix `~/.claude/` drift, not just report it — run `skills-deploy install` or
  `skills-deploy doctor`; this skill flags drift but does not mutate
- You're inside a worktree subagent on a leaf task — health checks are operator-facing,
  not pipeline-step inputs

## Mental model

Read-only dashboard over `~/.claude/`. Walks the manifest, the installed skill set, and
the analytics log, then renders a scored report. The output is human-reading; nothing
downstream consumes the score programmatically. Trend tracking persists between runs so
you can see whether the workbench got healthier or noisier since last week.

## Common pitfalls

- Forgetting that the score is advisory. A 7/10 with no errors is fine; chase the
  individual findings, not the number.
- Running it inside a worktree expecting per-worktree health — the scope is global
  `~/.claude/`, not the cwd repo.
- Confusing this with `skills-deploy doctor` (template/manifest drift) — they overlap
  but doctor is the deployment-side tool, this is the dashboard.

## Related skills

- `/CJ_suggest` — sibling read-only utility; suggests next work, not health
- `skills-deploy doctor` — adjacent deployment health check (script, not a skill)
- `/CJ_improve-queue audit` — repo-side self-scan for stale skills / missing
  frontmatter; complements the `~/.claude/`-side view this skill renders
