/personal-workflow check work-items/features/F999003_untested/S999003_two_p0/

The fixture at `work-items/features/F999003_untested/S999003_two_p0/` is a user-story whose SPEC has **two P0 stories** (#1, #2). The TEST-SPEC's `## Smoke Tests` and `## E2E Tests` tables together produce an `ac_set` containing only `AC-1` — `AC-2` is **deliberately absent** from every row's AC column.

Apply Step 18 (Cross-Reference Traceability) of `/personal-workflow check`. For each P0 story #n in SPEC, check whether the literal `AC-<n>` is in `ac_set`. If not, flag the story as `[UNTESTED]`.

Then output a JSON object summarizing what you found, matching exactly this shape:

```json
{
  "overall": "PASS" | "FAIL",
  "p0_stories": {
    "1": { "covered": true | false },
    "2": { "covered": true | false }
  },
  "untested_p0_stories": [<P0 numbers as integers>],
  "ac_set": ["AC-1", ...]
}
```

Field rules:

- `p0_stories.<n>.covered` = `true` iff the literal string `AC-<n>` is in `ac_set` after the comma-split + trim + placeholder filter described in `check.md` Step 18.
- `untested_p0_stories` = list of P0 numbers (integers) that have `covered: false`. Empty list `[]` if none. For this fixture, must contain `2` and not contain `1`.
- `overall` = `"PASS"` only if `untested_p0_stories` is empty; otherwise `"FAIL"`. For this fixture, must be `"FAIL"` because P0 #2 is uncovered.
- `ac_set` = the deduplicated list of AC tokens extracted from TEST-SPEC's AC columns. For this fixture, must equal `["AC-1"]` (only one row, only one token).

**Output only the JSON object.** Do not include prose explanations, markdown fences, or any text outside the JSON. The first non-whitespace character of your response must be `{` and the last must be `}`.
