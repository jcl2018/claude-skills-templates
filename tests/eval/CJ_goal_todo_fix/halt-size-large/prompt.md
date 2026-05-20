Run `/CJ_goal` (no args) inside the fixture working directory. The fixture's `TODOS.md` contains exactly one active TODO heading sized `L`. The /CJ_goal pre-flight gates refuse size in {L, XL} (per the source design's priority/size cap rule — size is the load-bearing risk control).

Determine which halt class /CJ_goal emits and report it as a JSON object with this exact shape:

```json
{
  "halt_class": "<end_state>",
  "halt_reason_contains": "<short substring expected to appear in the halt reason>"
}
```

**Output only the JSON object.** First non-whitespace character `{`, last `}`. No prose.
