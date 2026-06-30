Run `/CJ_goal_task "redesign the whole tracker frontmatter schema"` inside the fixture working directory. The topic names a design-rework signal ("redesign"), so the `/CJ_goal_task` hard complexity gate (Step 2, before any work-item is scaffolded) refuses it and routes the operator to `/CJ_goal_feature` (design-rework needs an /office-hours design first).

Drive the workflow through its preamble + isolation + the hard complexity gate. Determine which halt class `/CJ_goal_task` emits and which verb it suggests, and report it as a JSON object with this exact shape:

```json
{
  "halt_class": "<end_state>",
  "suggested_verb": "<the /CJ_goal_* verb the gate routes to>",
  "halt_reason_contains": "<short substring expected to appear in the halt reason>"
}
```

The complexity gate emits `halted_at_too_complex` and suggests `/CJ_goal_feature` for a design-rework topic. The reason names the design-rework signal it matched.

**Output only the JSON object.** First non-whitespace character `{`, last `}`. No prose.
