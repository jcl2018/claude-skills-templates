Run `/CJ_goal_todo_fix` (no args) inside the fixture working directory. The fixture's `TODOS.md` contains exactly one active TODO heading WITHOUT a priority/size suffix `(P[1-4], [SMLX]+)`. /CJ_goal_todo_fix pre-flight gate requires explicit annotation; missing suffix → halt at preflight.

Determine which halt class /CJ_goal_todo_fix emits and report it as a JSON object with this exact shape:

```json
{
  "halt_class": "<end_state>",
  "halt_reason_contains": "<short substring expected to appear in the halt reason>"
}
```

**Output only the JSON object.** First non-whitespace character `{`, last `}`. No prose.
