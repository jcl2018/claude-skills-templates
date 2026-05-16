Read `skills/CJ_goal_run/run.md` Step 5.5 (Phase 5 drain). The fixture's `TODOS.md` has 3 new top-level `^### ` headings that were added by the simulated feature PR (compared to the pre-PR baseline of zero active rows). The orchestrator has just completed Phase 4 with a green deploy.

Simulate Phase 5 in this scenario, assuming the operator answers "yes, drain all 3 TODOs" at the AUQ (Step 5.5.3) and all 3 child `/CJ_goal_todo_fix` invocations succeed. Based on the documented logic in Steps 5.5.1–5.5.4:

1. The diff parser computes `NEW_TODOS_COUNT = ?`
2. The AUQ recommendation per cap=5 policy is `yes` or `no`?
3. The drain loop runs how many child invocations?
4. The final `end_state` is what?
5. The telemetry line records `new_todos_count: ?`, `drained_count: ?`, `drained_pr_urls.length: ?`

Report your simulation as a JSON object with this exact shape:

```json
{
  "new_todos_count": <int>,
  "drained_count": <int>,
  "drained_pr_urls_length": <int>,
  "auq_recommendation": "<yes|no>",
  "end_state": "<string>"
}
```

**Output only the JSON object.** First non-whitespace character `{`, last `}`. No prose.
