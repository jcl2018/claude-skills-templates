Run `/CJ_goal` (no args) inside the fixture working directory. The fixture's `TODOS.md` has an empty `## Active work` section (only a Deferred section with one entry that /CJ_suggest correctly excludes). /CJ_suggest returns "No actionable items." and /CJ_goal halts at resolve.

Determine which halt class /CJ_goal emits and report it as a JSON object with this exact shape:

```json
{
  "halt_class": "<end_state>",
  "halt_reason_contains": "<short substring expected to appear in the halt reason>"
}
```

**Output only the JSON object.** First non-whitespace character `{`, last `}`. No prose.
