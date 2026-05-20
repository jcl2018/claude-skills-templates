Run `/CJ_goal_todo_fix` (no args) inside the fixture working directory. The fixture's `TODOS.md` contains exactly one active TODO whose body contains a design-needed keyword (`investigate`). /CJ_goal_todo_fix halts on any of: `needs design`, `figure out`, `investigate`, `spike`, `unclear`, `need to decide`, `TBD`.

Determine which halt class /CJ_goal_todo_fix emits and report it as a JSON object with this exact shape:

```json
{
  "halt_class": "<end_state>",
  "halt_reason_contains": "<short substring expected to appear in the halt reason>"
}
```

**Output only the JSON object.** First non-whitespace character `{`, last `}`. No prose.
