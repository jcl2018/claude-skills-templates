---
skill-name: "CJ_goal_todo_fix"
version: 2.2.0
status: active
created: "2026-06-01"
last-updated: "2026-06-02T19:35:31Z"
---

# Skill Usage: CJ_goal_todo_fix

## When to use

- "fix this TODO", "clear the TODO backlog", "auto-resolve TODOs", "drain TODOs"
- Default no-args mode drains up to 10 easy-fix TODOs end-to-end
- Single-TODO mode: `/CJ_goal_todo_fix T000NNN` or `/CJ_goal_todo_fix "<fragment>"`
- Cron/schedule cadence: pair `--quiet` with `/schedule` to drain at a fixed time
- `--max-drain N` caps the batch; `--dry-run` previews without mutation; `/loop`
  wrapper for continuous drain

## When NOT to use

- The work is a new feature topic, not an existing TODO row — use `/CJ_goal_feature`
- The work is a bug-from-description — use `/CJ_goal_defect`
- The TODO row is multi-item or non-trivial — drain mode skips hard rows by design;
  scaffold the work as a proper feature/defect instead
- You want autonomous merge — `/ship` Gate #2 still fires per drained PR (the
  workbench's autonomy ceiling per F000021)

## Mental model

A TODOS.md backlog drainer that chains `/CJ_suggest` (rank) →
`/CJ_personal-pipeline` (scaffold → impl → QA) → `/ship` (open PR) →
`/land-and-deploy` (merge + verify) per drained row. Drain mode creates one
worktree per TODO inside `scripts/drain-one-todo.sh`; single mode creates one
`cj-todo-*` worktree on `main`. Halt-on-red stops the loop and writes the
finding to the tracker journal.

## Common pitfalls

- Forgetting that `/ship` Gate #2 is human — drain mode prepares PRs at your cadence,
  it does not auto-merge them
- TODOS hygiene debt: a row whose work shipped but wasn't strikethrough'd will keep
  ranking active and burn `/loop` iterations on idempotent skips (see CLAUDE.md
  "TODOS.md hygiene conventions")
- Treating PARTIAL closes the same as full closes — partial fixes need an explicit
  `~~strikethrough~~ PARTIAL —` annotation or `/CJ_suggest` will re-pick the row
- Running drain in a session that's already inside a worktree — drain creates
  per-TODO worktrees and parent-session collisions are confusing

## Related skills

- `/CJ_suggest` — ranks TODOS.md rows; drain mode calls it with `--for-skill cj-goal`
- `/CJ_personal-pipeline` — internal scaffold→impl→QA engine called per drained TODO
- `/ship` (upstream gstack) — opens PR with Gate #2 diff-review AUQ
- `/land-and-deploy` (upstream gstack) — merges and verifies deploy
- `/schedule` (upstream gstack) — pair with `--quiet` for cron-style drains
