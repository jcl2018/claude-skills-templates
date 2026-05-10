/personal-workflow check work-items/features/F999001_broken/F999001_TRACKER.md

The fixture at `work-items/features/F999001_broken/F999001_TRACKER.md` is a feature tracker with **deliberately incomplete frontmatter**. The frontmatter has only `name` and `type` — it is missing the other required fields that the `tracker-feature.md` template defines (e.g., `id`, `status`, `created`, `updated`, `repo`, `branch`, `blocked_by`).

Run the standard `/personal-workflow check` validation in **File Mode** (Steps 2–7 of `check.md`) on this tracker file. Step 5 (Check Frontmatter) compares the instance's frontmatter keys against `required_fields` derived from the template; missing fields produce VIOLATIONs.

Then output a JSON object summarizing what you found, matching exactly this shape:

```json
{
  "overall": "PASS" | "FAIL",
  "checks": {
    "frontmatter": {
      "status": "PASS" | "FAIL",
      "missing_fields": [<field names>]
    }
  }
}
```

Field rules:

- `overall` = `"FAIL"` if `checks.frontmatter.status` is `"FAIL"`; otherwise `"PASS"`.
- `checks.frontmatter.status` = `"PASS"` if every required frontmatter field per the `tracker-feature.md` template is present in the instance, AND no unresolved `\{[A-Z_]+\}` placeholder patterns are found. Otherwise `"FAIL"`.
- `checks.frontmatter.missing_fields` = the list of frontmatter keys that the template requires but the instance is missing. Empty list `[]` if none missing. Order does not matter.

**Output only the JSON object.** Do not include prose explanations, markdown fences, or any text outside the JSON. The first non-whitespace character of your response must be `{` and the last must be `}`.
