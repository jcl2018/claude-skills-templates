Run `/CJ_goal` (no args) inside the fixture working directory. The fixture's `TODOS.md` contains exactly one active TODO whose body is under 50 characters. /CJ_goal pre-flight gate refuses bodies under 50 chars (per the source design's body-extraction rule).

Determine which halt class /CJ_goal emits and report it as a JSON object with this exact shape:

```json
{
  "halt_class": "<end_state>",
  "halt_reason_contains": "<short substring expected to appear in the halt reason>"
}
```

**Output only the JSON object.** First non-whitespace character `{`, last `}`. No prose.
