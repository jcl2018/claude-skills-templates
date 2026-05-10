---
mode: agent
description: "Validate a work item tracker (file) or work item directory against the CJ_company-workflow manifest and templates."
tools: ['codebase', 'search', 'searchResults', 'findTestFiles']
---

# /validate

Validate work items against the CJ_company-workflow spec. Templates are the single
source of truth — every structural rule is derived by reading the matching
template at runtime.

## Usage

```
/validate <path>
```

- If `<path>` is a file → **File Mode** (validates one tracker)
- If `<path>` is a directory → **Directory Mode** (validates artifact completeness + tracker structure)
- If `<path>` is omitted → print the usage block above and stop

## Bundle paths (relative to repo root)

- Manifest: `.github/work-copilot/copilot-artifact-manifests.json`
- Templates: `.github/work-copilot/templates/`

**Anti-hallucination rule:** Use your file-read tool to Read these files.
Do NOT recall their contents from memory. The whole point of this command is
to compare real files against real templates — hallucinated rules defeat it.

## File Mode

1. Read the target file. Parse YAML frontmatter (between `---` markers).
   - If frontmatter cannot be parsed: emit `VIOLATION: could not parse YAML frontmatter in {path}` and stop.

2. If the file has no `## Lifecycle` section, warn and stop:
   `Warning: {path} does not look like a tracker file. File-mode validation only validates trackers — for doc artifacts (PRD, RCA, test-plan, etc.), use Directory Mode on the parent directory.`

3. Read the `type` field. Normalize `userstory` → `user-story`. Valid types:
   `feature`, `defect`, `task`, `user-story`, `review`. Unknown type → emit
   `VIOLATION: unknown type "{value}" in {path}` and stop.

4. Read the matching template from `.github/work-copilot/templates/tracker-{type}.md`.
   If missing → emit `Error: template tracker-{type}.md not found. Run copilot-deploy install.` and stop.

5. Parse the template:
   - Frontmatter keys → `required_fields`
   - All `## ` headers in document order → `expected_sections`
   - All `### Phase N: {name}` headers under the template's `## Lifecycle` → `required_phases`
   - Count of `- [ ]` and `- [x]` bullets inside the template's `## Lifecycle` → `min_checkboxes`

6. Parse the instance (the target file) the same way → `present_fields`,
   `present_sections`, `present_phases`, `present_checkbox_count`.

7. Compare and emit violations:

   **Frontmatter:**
   - Missing required field → `VIOLATION: missing required field "{field}" in {path}`
   - Any frontmatter value matches the regex `\{[A-Z_]+\}` (unresolved scaffolder placeholder) → `VIOLATION: unresolved placeholder "{placeholder}" in frontmatter of {path}`

   **Sections:**
   - Missing expected section → `VIOLATION: missing section "{section}" in {path}`
   - Present section not in template → `[EXTRA] unexpected section "{section}" in {path}` (advisory, not a hard failure)
   - Filter `expected_sections` to only those actually present in the instance; if their order in the instance does not match that filtered list → `VIOLATION: section order mismatch — "{section}" appears before "{other}" in {path}`

   **Lifecycle:**
   - Missing phase → `VIOLATION: missing phase "{phase}" in {path}`
   - `present_checkbox_count < min_checkboxes` → `VIOLATION: lifecycle has {N} checkboxes, minimum is {min} (per template) in {path}`

8. Report:
   - No violations → print `VALID: {path}`
   - One or more violations → print each violation, one per line, then a one-line summary `SUMMARY: {N} violations in {path}`

## Directory Mode

Validates the **immediate directory only** — no recursive descent into child
directories. For a feature with children, call `/validate` on each child
directory separately.

### Filename matching

Strip a leading ID prefix matching `^[A-Z]\d+_` from each file, then compare
to the manifest's `filename` field. Examples:
- `S000003_PRD.md` → `PRD.md` (matches `PRD.md`)
- `F000004_TRACKER.md` → `TRACKER.md` (matches `TRACKER.md`)
- `T000008_test-plan.md` → `test-plan.md` (matches `test-plan.md`)

### Steps

1. List all `*.md` files in the target directory (no recursion).

2. Find the tracker: a file whose stripped name is `TRACKER.md`. If none →
   `Error: no TRACKER.md found in {directory}. Not a work item directory.` and stop.

3. Read the tracker's `type` frontmatter field. Normalize as in File Mode.
   Unknown type → emit `[WARN] type "{value}" not recognized` and stop.

4. Read `.github/work-copilot/copilot-artifact-manifests.json`. Find the entry
   for this type. If missing → `Error: manifest has no entry for type "{type}".`

5. For each required artifact in the manifest's `required` list:
   - Find the matching file by stripping the ID prefix and comparing to `filename`.
   - If not found → emit `[MISSING] {artifact} — required artifact not found`.
   - If found → read the artifact's frontmatter AND the artifact's template
     (`.github/work-copilot/templates/{template}`). For every key present in
     the template's frontmatter, check the artifact has the same key. Missing
     key → `[DRIFT] {artifact} — missing required field "{field}"`. Scan
     frontmatter values for `\{[A-Z_]+\}` placeholders → `[DRIFT] {artifact} — unresolved placeholder "{placeholder}" in frontmatter`.
   - If the artifact is the tracker, additionally run File Mode steps 5–7
     against it (section order, phases, checkbox count) and emit those
     violations under a `LIFECYCLE:` block.

6. Print the report in this exact format:

   ```
   COPILOT-WORKFLOW VALIDATE: {directory}
     Type: {type}
     ARTIFACTS:
       [PASS]    TRACKER.md — all required fields present
       [PASS]    PRD.md — all required fields and sections present
       [MISSING] test-plan.md — required artifact not found
       [DRIFT]   ARCHITECTURE.md — missing required field "repo"
     LIFECYCLE:
       [PASS]    4 phases present, 12 checkboxes (min 12 per template)
     SUMMARY: {N} artifacts checked, {M} missing, {K} drift
   ```

## Output contract (do not deviate)

Status tags are the grep-able surface. Match exactly:

| Tag | Meaning |
|-----|---------|
| `[PASS]` | Artifact found and frontmatter complete |
| `[MISSING]` | Required artifact not found in directory |
| `[DRIFT]` | Artifact found but frontmatter doesn't match its template |
| `[EXTRA]` | Section in instance not in template (advisory, not a failure) |
| `[WARN]` | Non-fatal issue (e.g. unknown type) |
| `VALID` | File Mode success on a tracker |
| `VIOLATION` | File Mode failure line (prefix for each specific issue) |

**Do not** invent new tags, reorder the report blocks, or translate
`[MISSING]` into plain English. Grep parity with `/CJ_company-workflow check`
(Claude Code) is the acceptance test.

## Parity check

This prompt produces the same output as
`deprecated/CJ_company-workflow/SKILL.md` §"Command: validate" in the upstream
`claude-skills-templates` repo. If behavior diverges, fix the prompt — do not
fix the CJ_company-workflow skill to match.
