---
skill-name: "CJ_improve-queue"
version: 0.2.0
status: experimental
created: "2026-06-01"
last-updated: "2026-06-01"
---

# Skill Usage: CJ_improve-queue

## When to use

- "evaluate this URL", "is this a good Claude pattern", "should we adopt this",
  "check this Anthropic article", "add this pattern to TODOS"
- `/CJ_improve-queue evaluate <url>` — fetch an Anthropic best-practices article,
  classify pattern fit, append a draft TODOS.md row if novel/conflict
- `/CJ_improve-queue audit` — offline repo self-scan for stale skills + missing
  frontmatter; emits draft rows directly
- `/CJ_improve-queue research <topic>` — orchestrator-driven WebSearch + per-result
  evaluate, with privacy gate

## When NOT to use

- You want to act on a draft, not produce one — promote the row by deleting the
  `<!--impr-draft-->` marker, then route to `/CJ_goal_todo_fix`
- You want to fix workbench drift, not log it — `audit` flags only; the fix path is
  `/CJ_goal_todo_fix` after the row is promoted
- The URL is outside the domain allowlist — the privacy gate refuses; this is by
  design, not a bug
- You're on a non-macOS host — the skill is workbench-only (macOS)

## Mental model

A backlog producer. Three modes (evaluate / audit / research) all converge on
appending `<!--impr-draft-->`-marked rows to `TODOS.md`. The marker hides the row
from `/CJ_suggest` until the operator promotes it (delete the marker token). Atomic
writes via `mktemp` + `mv`; mkdir-based write lock prevents concurrent corruption;
backup rotation keeps prior TODOS.md versions.

## Common pitfalls

- Forgetting that draft rows don't rank — `/CJ_suggest` skips them until the
  marker is deleted
- Running `evaluate` on a URL outside the domain allowlist and being surprised by
  the refusal — this is the privacy gate, not a network error
- Treating `audit` output as authoritative — it produces draft rows for human
  review, not auto-fixes

## Related skills

- `/CJ_suggest` — downstream ranker; filters draft rows until promoted
- `/CJ_goal_todo_fix` — downstream consumer; drains promoted rows
- `/CJ_system-health` — adjacent read-only utility (`~/.claude/` health, not
  pattern fit)
