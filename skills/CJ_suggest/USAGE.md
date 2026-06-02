---
skill-name: "CJ_suggest"
version: 1.2.0
status: experimental
created: "2026-06-01"
last-updated: "2026-06-01"
---

# Skill Usage: CJ_suggest

## When to use

- "what's next", "what should I work on", "suggest next work item", "top 5 work items"
- Lost track and need a ranked candidate list pulled from TODOS.md + tracker
  frontmatter
- `--for-skill <name>` pre-filters for a downstream caller (e.g.
  `/CJ_goal_todo_fix` uses `--for-skill cj-goal`)
- `--limit N` extends the candidate window beyond the default top-5
- `--include-internal` surfaces internal phase-step rows otherwise filtered out

## When NOT to use

- You already know what TODO to drain — call `/CJ_goal_todo_fix T000NNN` directly
- You want to fix a bug from scratch — that's `/CJ_goal_defect`
- You want execution, not ranking — this skill is read-only and stateless
- You want repo health, not work ranking — that's `/CJ_system-health`

## Mental model

A pure scorer. Reads `TODOS.md` (candidate set) and joins it against
`work-items/**/*_TRACKER.md` YAML frontmatter (live status / blocked_by /
updated). Filters out internal phase-step skills + draft rows (`<!--impr-draft-->`)
by default. Output is a markdown table. Read-only, stateless, portable across
two TODOS.md conventions (CJ_personal-workflow shape and a generic shape).

## Common pitfalls

- Treating the ranking as prescriptive — it's a suggestion based on priority +
  size, not a workflow plan
- Forgetting that strikethrough'd or PARTIAL rows are excluded — if a row keeps
  appearing after the work shipped, fix the TODOS hygiene (see CLAUDE.md
  "TODOS.md hygiene conventions")
- Expecting it to show in-flight drafts — `<!--impr-draft-->`-marked rows from
  `/CJ_improve-queue` are filtered until promoted

## Related skills

- `/CJ_goal_todo_fix` — primary downstream caller; drain mode calls
  `/CJ_suggest --for-skill cj-goal` to pick rows
- `/CJ_system-health` — sibling read-only utility (health, not ranking)
- `/CJ_improve-queue` — produces draft TODO rows that this skill filters until
  the operator promotes them
