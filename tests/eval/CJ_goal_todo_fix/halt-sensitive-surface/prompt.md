Run `/CJ_goal_todo_fix` (no args) inside the fixture working directory. The fixture's `TODOS.md` contains exactly one active TODO whose body mentions `skills-catalog.json` — a sensitive surface per the /CJ_goal_todo_fix preflight sensitive-surface scan. /CJ_goal_todo_fix defaults to halt at sensitive-surface match (user-declined is the default option per source design).

Determine which halt class /CJ_goal_todo_fix emits and report it as a JSON object with this exact shape:

```json
{
  "halt_class": "<end_state>",
  "halt_reason_contains": "<short substring expected to appear in the halt reason>"
}
```

**Output only the JSON object.** First non-whitespace character `{`, last `}`. No prose.
