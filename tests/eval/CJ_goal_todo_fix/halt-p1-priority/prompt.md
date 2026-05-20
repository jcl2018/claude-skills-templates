Run `/CJ_goal_todo_fix` (no args) inside the fixture working directory. The fixture's `TODOS.md` contains exactly one active TODO heading, and that heading carries the `(P1, M)` priority/size suffix. The /CJ_goal_todo_fix pre-flight gates refuse priority P1 (per the source design's priority/size cap rule).

Determine which halt class /CJ_goal_todo_fix emits and report it as a JSON object with this exact shape:

```json
{
  "halt_class": "halted_at_preflight" | "halted_at_resolve" | "halted_at_sensitive_surface_user_declined" | "...",
  "halt_reason_contains": "<short substring expected to appear in the halt reason>"
}
```

Field rules:
- `halt_class` MUST be the exact end_state /CJ_goal_todo_fix writes to telemetry / stderr.
- `halt_reason_contains` is a short substring you'd expect to appear in the halt's reason line (e.g. "P1", "size", "vague").

**Output only the JSON object.** First non-whitespace character `{`, last `}`. No prose.
