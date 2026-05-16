Read `skills/CJ_goal_run/run.md` Step 5.5 (Phase 5 drain). The fixture's `TODOS.md` is identical to the pre-PR base: no new `^### ` headings were added.

Simulate Phase 5 in this scenario. Based on the documented logic in Step 5.5.1 and Step 5.5.2:

1. The diff parser computes `NEW_TODOS_COUNT = ?`
2. The orchestrator takes which branch (silent-skip / AUQ / drain-loop)?
3. The final `end_state` is what?
4. The telemetry line records `new_todos_count: ?`, `drained_count: ?`, `no_drain_flag: ?`

Report your simulation as a JSON object with this exact shape:

```json
{
  "new_todos_count": <int>,
  "drained_count": <int>,
  "end_state": "<string>",
  "no_drain_flag": <bool>,
  "auq_surfaced": <bool>
}
```

**Output only the JSON object.** First non-whitespace character `{`, last `}`. No prose.
