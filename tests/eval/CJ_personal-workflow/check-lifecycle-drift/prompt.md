/CJ_personal-workflow check work-items/features/F999002_drift/F999002_TRACKER.md

The fixture at `work-items/features/F999002_drift/F999002_TRACKER.md` is a feature tracker whose `## Lifecycle` section has **all three Phase headers present** (`### Phase 1: Track`, `### Phase 2: Implement`, `### Phase 3: Ship`), but each phase has **fewer gate checkboxes than the `tracker-feature.md` template requires**. This is gate-row drift — distinct from a missing phase.

Run the standard `/CJ_personal-workflow check` validation in **File Mode** on this tracker (Steps 2–7 of `check.md`). Step 6.5 (Check Lifecycle) compares phase headers and counts gate checkboxes against the template-derived `min_checkboxes`.

Then output a JSON object summarizing what you found, matching exactly this shape:

```json
{
  "overall": "PASS" | "FAIL",
  "checks": {
    "lifecycle": {
      "status": "PASS" | "FAIL",
      "missing_phases": ["Track" | "Implement" | "Ship", ...],
      "checkbox_count": <integer>,
      "min_checkboxes": <integer>,
      "below_minimum": true | false
    }
  }
}
```

Field rules:

- `overall` = `"PASS"` only if `checks.lifecycle.status` is `"PASS"`; otherwise `"FAIL"`.
- `checks.lifecycle.missing_phases` = list of Phase names absent from the instance's `## Lifecycle` section. For this fixture, every phase is present, so this list **must be empty**.
- `checks.lifecycle.checkbox_count` = total count of `- [ ]` and `- [x]` patterns inside the instance's `## Lifecycle` section.
- `checks.lifecycle.min_checkboxes` = the template's minimum (count of `- [ ]` and `- [x]` patterns in `tracker-feature.md`'s `## Lifecycle` section).
- `checks.lifecycle.below_minimum` = `true` iff `checkbox_count < min_checkboxes`. The fixture has fewer gates than the template, so this must be `true`.
- `checks.lifecycle.status` = `"PASS"` only if `missing_phases` is empty AND `below_minimum` is `false`. For this fixture, `below_minimum` is `true`, so status must be `"FAIL"`.

**Output only the JSON object.** Do not include prose explanations, markdown fences, or any text outside the JSON. The first non-whitespace character of your response must be `{` and the last must be `}`.
