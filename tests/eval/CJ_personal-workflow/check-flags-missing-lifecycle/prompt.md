/CJ_personal-workflow check work-items/tasks/T000099_broken/

The fixture at `work-items/tasks/T000099_broken/T000099_TRACKER.md` is a task tracker that is **missing required lifecycle gate rows** in its `## Lifecycle` section. The standard `tracker-task.md` template requires three lifecycle phases (Track, Implement, Ship), each with `**Gates:**` checkbox lists. Some of those gate lines are deliberately removed in this fixture.

Run the standard `/CJ_personal-workflow check` validation on this task directory. Then output a JSON object summarizing what you found, matching exactly this shape:

```json
{
  "overall": "PASS" | "FAIL",
  "checks": {
    "frontmatter": { "status": "PASS" | "FAIL" },
    "sections": { "status": "PASS" | "FAIL" },
    "lifecycle": {
      "status": "PASS" | "FAIL",
      "missing_phases": ["Track" | "Implement" | "Ship", ...],
      "checkbox_count": <integer>,
      "below_minimum": true | false
    }
  }
}
```

Field rules:

- `overall` = "PASS" only if every nested `checks.*.status` is "PASS"; otherwise "FAIL".
- `checks.lifecycle.missing_phases`: list every Phase header (`### Phase 1: Track`, `### Phase 2: Implement`, `### Phase 3: Ship`) that is **absent** from the tracker. Empty list `[]` if all three phases are present.
- `checks.lifecycle.checkbox_count`: total count of `- [ ]` and `- [x]` checkbox patterns inside the tracker's `## Lifecycle` section.
- `checks.lifecycle.below_minimum`: `true` if `checkbox_count` is below the template's minimum (the `tracker-task.md` template's count of lifecycle checkboxes); else `false`. The minimum for `task` type is the count of checkbox lines inside `## Lifecycle` in the template at `templates/CJ_personal-workflow/tracker-task.md` (or `~/.claude/templates/CJ_personal-workflow/tracker-task.md` if the workbench template isn't reachable from this fixture).

**Output only the JSON object.** Do not include prose explanations, markdown fences, or any text outside the JSON. The first non-whitespace character of your response must be `{` and the last must be `}`.
