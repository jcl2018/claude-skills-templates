/CJ_personal-workflow check work-items/features/F999000_canonical/S999000_multi_ac/

The fixture at `work-items/features/F999000_canonical/S999000_multi_ac/` is a user-story with **three P0 stories** (#1, #2, #3) and a TEST-SPEC.md whose AC column contains **multi-AC cells** like `AC-1, AC-2, AC-3` and `AC-1, AC-2`. Per Step 18 of `/CJ_personal-workflow check`, multi-AC cells must be **comma-split** and **trimmed** so that each token contributes one value to `ac_set`.

**Caveat:** This case tests that Claude faithfully executes the comma-split spec as written in `check.md` Step 18. It does NOT test the comma-split logic in isolation — that's covered (or scheduled) under V2's parser-extraction work.

Apply Step 18 of the `/CJ_personal-workflow check` validation to this user-story. Walk the SPEC's `### P0 (Must-Have)` table and the TEST-SPEC's `## Smoke Tests` + `## E2E Tests` tables. Comma-split each AC cell, trim whitespace, drop placeholders matching `^AC-\{[a-zA-Z_]+\}$`, build `ac_set`, and check whether `AC-1`, `AC-2`, `AC-3` are each present in `ac_set`.

Then output a JSON object summarizing what you found, matching exactly this shape:

```json
{
  "overall": "PASS" | "FAIL",
  "p0_stories": {
    "1": { "covered": true | false },
    "2": { "covered": true | false },
    "3": { "covered": true | false }
  },
  "all_p0_covered": true | false,
  "ac_set": ["AC-1", "AC-2", ...]
}
```

Field rules:

- `p0_stories.<n>.covered` = `true` iff the literal string `AC-<n>` is in `ac_set` after the comma-split + trim + placeholder filter.
- `all_p0_covered` = `true` iff every P0 story (#1, #2, #3) has `covered: true`.
- `overall` = `"PASS"` iff `all_p0_covered` is `true`; otherwise `"FAIL"`.
- `ac_set` = the deduplicated list of AC tokens you extracted from the AC columns (after split + trim + placeholder filter). Order does not matter.

**Output only the JSON object.** Do not include prose explanations, markdown fences, or any text outside the JSON. The first non-whitespace character of your response must be `{` and the last must be `}`.
