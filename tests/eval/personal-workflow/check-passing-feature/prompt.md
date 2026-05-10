/personal-workflow check work-items/features/F999999_test_feature/

The fixture at `work-items/features/F999999_test_feature/` is a canonical valid feature work-item directory. It contains the three required feature artifacts (`F999999_TRACKER.md`, `F999999_DESIGN.md`, `F999999_ROADMAP.md`), all with valid frontmatter, all required sections present, lifecycle phases complete, and no unresolved placeholders.

Run the standard `/personal-workflow check` directory-mode validation on this feature directory (Tier 1 Directory Mode — Steps 8 through 13 of `check.md`).

Then output a JSON object summarizing what you found, matching exactly this shape:

```json
{
  "overall": "PASS" | "FAIL",
  "checks": {
    "frontmatter": { "status": "PASS" | "FAIL" },
    "sections":    { "status": "PASS" | "FAIL" },
    "lifecycle":   { "status": "PASS" | "FAIL" },
    "artifacts":   { "status": "PASS" | "FAIL", "missing": [<artifact filenames>] }
  }
}
```

Field rules:

- `overall` = `"PASS"` only if every nested `checks.*.status` is `"PASS"`; otherwise `"FAIL"`.
- `checks.frontmatter.status` = `"PASS"` if all required frontmatter fields are present in TRACKER.md, DESIGN.md, ROADMAP.md and no unresolved `{PLACEHOLDER}` patterns appear. Otherwise `"FAIL"`.
- `checks.sections.status` = `"PASS"` if every required `## ` section is present and in the expected order across all three artifacts. Otherwise `"FAIL"`.
- `checks.lifecycle.status` = `"PASS"` if `## Lifecycle` contains all three required phase headers (`### Phase 1: Track`, `### Phase 2: Implement`, `### Phase 3: Ship`) and the checkbox count meets the template's minimum. Otherwise `"FAIL"`.
- `checks.artifacts.status` = `"PASS"` if every required artifact for `type: feature` (TRACKER, DESIGN, ROADMAP per `personal-artifact-manifests.json`) is present in the directory. Otherwise `"FAIL"`. `missing` lists any missing artifact filenames; empty list `[]` if none missing.

**Output only the JSON object.** Do not include prose explanations, markdown fences, or any text outside the JSON. The first non-whitespace character of your response must be `{` and the last must be `}`.
