---
name: company-workflow
description: "Company work item specification with structural validation. Validates tracker files and work item directories against company templates and company-artifact-manifests.json. Templates are the single source of truth for structural rules."
version: 3.0.0
allowed-tools:
  - Bash
  - Read
  - Glob
  - Grep
---

## Getting Started

For the complete doc-driven development workflow (generating docs, scaffolding
conventions, installation), see [WORKFLOW.md](WORKFLOW.md).

This skill provides the `validate` command. WORKFLOW.md provides everything else.

## Preamble

Verify this is a git repository:

```bash
git rev-parse --show-toplevel 2>/dev/null || echo "NOT_A_GIT_REPO"
```

If `NOT_A_GIT_REPO`: tell the user "Error: /company-workflow requires a git repository." and stop.

## Overview

Company work item specification skill. Enforces the company's formal work item
standard: structural validation derived directly from the templates in
`templates/company-workflow/`, artifact completeness via
`company-artifact-manifests.json`, and frontmatter compliance against templates.

This skill is independent from the workbench's personal-dev templates and from
`/docs check`. It owns its own templates, manifest, reference guides, and
validation logic.

**Templates are the single source of truth.** The validator derives every
structural rule (required frontmatter, required sections, section order,
lifecycle phases, minimum checkbox count) by parsing the matching template at
runtime. There is no separate `contract.json` to drift from the templates.

## Path Resolution

Resolve skill assets using a 2-level fallback chain. This ensures the skill
works both in the workbench repo and on company machines where it's deployed
via `skills-deploy`.

```bash
_REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
_SKILL_DIR=""
_TMPL_DIR=""

# Level 1: workbench repo
if [ -n "$_REPO_ROOT" ] && [ -f "$_REPO_ROOT/skills/company-workflow/company-artifact-manifests.json" ]; then
  _SKILL_DIR="$_REPO_ROOT/skills/company-workflow"
  _TMPL_DIR="$_REPO_ROOT/templates/company-workflow"
fi

# Level 2: deployed location
if [ -z "$_SKILL_DIR" ] && [ -f "$HOME/.claude/skills/company-workflow/company-artifact-manifests.json" ]; then
  _SKILL_DIR="$HOME/.claude/skills/company-workflow"
  _TMPL_DIR="$HOME/.claude/templates/company-workflow"
fi

if [ -z "$_SKILL_DIR" ]; then
  echo "ERROR: Could not find company-workflow skill assets."
  echo "Checked: $_REPO_ROOT/skills/company-workflow/ and ~/.claude/skills/company-workflow/"
  echo "NOT_FOUND"
else
  echo "SKILL_DIR: $_SKILL_DIR"
  echo "TMPL_DIR: $_TMPL_DIR"
fi
```

If `NOT_FOUND`: tell the user "Error: company-workflow skill assets not found.
Run `skills-deploy install` or check the repo structure." and stop.

## Knowledge Resolution

After Path Resolution, the skill resolves an OPTIONAL external knowledge
directory via the `AI_KNOWLEDGE_DIR` environment variable. When set to a
valid directory, downstream features (always-on loading, on-demand matching —
see F000004 user-stories S000005 and S000006) consume its contents. When unset
or invalid, the skill still functions; only knowledge features are disabled.

```bash
_KNOWLEDGE_DIR=""
if [ -z "${AI_KNOWLEDGE_DIR:-}" ]; then
  echo "Warning: AI_KNOWLEDGE_DIR not set — knowledge features disabled. See WORKFLOW.md." >&2
elif [ ! -e "$AI_KNOWLEDGE_DIR" ]; then
  echo "Warning: AI_KNOWLEDGE_DIR=\"$AI_KNOWLEDGE_DIR\" not found — knowledge features disabled." >&2
elif [ ! -d "$AI_KNOWLEDGE_DIR" ]; then
  echo "Warning: AI_KNOWLEDGE_DIR=\"$AI_KNOWLEDGE_DIR\" is not a directory — knowledge features disabled." >&2
else
  _KNOWLEDGE_DIR="$AI_KNOWLEDGE_DIR"
fi
```

Behavior contract:
- The warning is written to **stderr**; exit code is unchanged (0 on success).
- `$_KNOWLEDGE_DIR` is an **empty string** on failure; downstream blocks guard
  with `[ -n "$_KNOWLEDGE_DIR" ]` before enumerating categories.
- The warning fires every invocation when the variable is missing or bad.
  This is intentional — it nudges configuration rather than silently losing
  the feature. Suppression is deliberately out of scope in v1.
- Resolution runs **after** Path Resolution so the skill's own discovery
  cannot fail because of a user-configured knowledge dir.

See [WORKFLOW.md §Knowledge Configuration](WORKFLOW.md#knowledge-configuration)
for setup instructions, the layout convention, and the `.knowledge.yml` schema.

## Template Registry

This skill reads `template-registry.json` at the repo root to discover its
template set. The registry declares all template sets with their paths, types,
and validation contracts.

```bash
_REGISTRY="$_REPO_ROOT/template-registry.json"
if [ -f "$_REGISTRY" ]; then
  echo "REGISTRY: $_REGISTRY"
else
  echo "NO_REGISTRY"
fi
```

If `NO_REGISTRY`: the skill can still function using `_TMPL_DIR` from path
resolution. The registry is metadata, not a runtime dependency.

## Template-Derived Rules

Every structural rule the validator enforces comes from parsing the matching
template at runtime. The derivation contract:

| Rule | Derivation |
|---|---|
| Required frontmatter fields | All keys present in the template's YAML frontmatter |
| Required sections | All `## ` headers in the template, in document order |
| Expected section order | The template's `##` header order |
| Required lifecycle phases | All `### Phase N: {name}` headers in the template's `## Lifecycle` section |
| Minimum checkbox count | Count of `- [ ]` and `- [x]` patterns inside the template's `## Lifecycle` section |
| Optional sections (per type) | Inferred structurally — if the per-type template includes the section, it's required for that type; if absent, it's not allowed (extras flagged as advisory `[EXTRA]`) |
| Unresolved placeholder detection | Scan the instance's frontmatter values for `\{[A-Z_]+\}` patterns — these indicate the scaffolder didn't substitute a placeholder |

When the template changes, the validator's expectations change automatically.
When a new section, phase, or gate is added to a template, instances that
predate the change are flagged. There is no separate spec to keep in sync.

## Command: validate

One command with two modes. Pass a file path for structural validation. Pass a
directory path for artifact completeness validation.

### Usage

```
/company-workflow validate <path>
```

If `<path>` is a file: run **File Mode**.
If `<path>` is a directory: run **Directory Mode**.

---

### File Mode

Validates a single tracker file against its template-derived rules.

#### Steps

1. Read the target file and parse its YAML frontmatter (between `---` markers).
   If frontmatter cannot be parsed: `VIOLATION: could not parse YAML frontmatter in {path}` and stop.

2. If the file does not contain a `## Lifecycle` section, warn:
   `Warning: {path} does not look like a tracker file. File-mode validation only validates trackers — for doc artifacts (PRD, RCA, test-plan, etc.), use Directory Mode on the parent directory.`
   Then stop (do not produce false positives by validating a doc against a tracker template).

3. Read the `type` field from frontmatter. Normalize spelling: `userstory` and
   `user-story` both normalize to `user-story`. Verify type is one of
   `feature`, `defect`, `task`, `user-story`, `review`. If unknown:
   `VIOLATION: unknown type "{value}" in {path}` and stop.

4. Resolve the matching template at `$_TMPL_DIR/tracker-{type}.md` via the
   2-level fallback chain. If the template cannot be found:
   `Error: template tracker-{type}.md not found at {_TMPL_DIR} or ~/.claude/templates/company-workflow/. Run skills-deploy install.` and stop.

5. Parse the template:
   - Frontmatter keys → `required_fields`
   - `##` headers in document order → `expected_sections`
   - `### Phase N:` headers in document order under the template's Lifecycle section → `required_phases`
   - Count of `- [ ]` and `- [x]` patterns inside the template's Lifecycle section → `min_checkboxes`

6. Parse the instance:
   - Frontmatter keys → `present_fields`
   - `##` headers in document order → `present_sections`
   - `### Phase N:` headers under the instance's Lifecycle section → `present_phases`
   - Count of `- [ ]` and `- [x]` patterns inside the instance's Lifecycle section → `present_checkbox_count`

7. Compare and emit violations:

   **Frontmatter:**
   - For each field in `required_fields`: if missing from `present_fields` → `VIOLATION: missing required field "{field}" in {path}`
   - For each frontmatter value in the instance: scan for `\{[A-Z_]+\}` placeholder patterns. If found → `VIOLATION: unresolved placeholder "{placeholder}" in frontmatter of {path}`

   **Sections:**
   - For each section in `expected_sections`: if missing from `present_sections` → `VIOLATION: missing section "{section}" in {path}`
   - For each section in `present_sections` not in `expected_sections` → `[EXTRA] unexpected section "{section}" in {path}` (advisory only, not a hard violation)
   - Filter `expected_sections` to only sections actually present in the instance, then assert `present_sections` matches that filtered list in order. If not → `VIOLATION: section order mismatch — "{section}" appears before "{other}" in {path}`

   **Lifecycle:**
   - For each phase in `required_phases`: if not in `present_phases` → `VIOLATION: missing phase "{phase}" in {path}`
   - If `present_checkbox_count` < `min_checkboxes` → `VIOLATION: lifecycle has {N} checkboxes, minimum is {min} (per template) in {path}`

8. Report results:
   - Exit 0 if no violations: `VALID: {path}`
   - Exit 1 if any violations: print each to stderr, then a summary

---

### Directory Mode

Validates an entire work item directory for artifact completeness, frontmatter
compliance, and lifecycle structure. Validates the **immediate directory only**
(no recursive descent into child directories). To validate a feature and its
children, run validate on each directory separately.

#### Filename Matching Rule

Strip the leading ID prefix (regex `^[A-Z]\d+_`) to get the canonical filename,
then compare against the manifest's `filename` field. Examples:
- `S000003_PRD.md` -> strip `S000003_` -> `PRD.md` (matches manifest)
- `F000003_TRACKER.md` -> strip `F000003_` -> `TRACKER.md` (matches manifest)
- `T000002_test-plan.md` -> strip `T000002_` -> `test-plan.md` (matches manifest)

#### Per-Artifact Validation

For each required artifact in the manifest, after locating the file, validate
its frontmatter against ITS template (looked up from the manifest's `template`
field):

1. Resolve the template file from `$_TMPL_DIR/{template}` (using the 2-level
   fallback chain from Path Resolution)
2. Parse the template's YAML frontmatter to extract its key names
3. Parse the artifact's YAML frontmatter
4. For each key present in the template's frontmatter: check that the same key
   exists in the artifact. Comparison is key-presence only (values contain
   placeholders in templates).
   - Missing key: `[DRIFT] {artifact} — missing required field "{field}"`
5. Check for unresolved placeholders: scan frontmatter values for `\{[A-Z_]+\}` patterns.
   If found: `[DRIFT] {artifact} — unresolved placeholder "{placeholder}" in frontmatter`

For tracker artifacts (the file matching `TRACKER.md`), additionally apply the
full File Mode validation flow above (sections, lifecycle, phases, checkboxes).

#### Directory Mode Error Handling

- No TRACKER.md found: `"Error: no TRACKER.md found in {directory}. Not a work item directory."`
- company-artifact-manifests.json missing: `"Error: company-artifact-manifests.json not found at {path}. Run skills-deploy install or check skill structure."`
- Template file missing: `"Warning: template {filename} not found at {path}. Skipping frontmatter validation for {artifact}."`

#### Steps

Path Resolution runs first (same as file mode). `$_SKILL_DIR` and `$_TMPL_DIR`
are available for config and template lookup throughout directory mode.

1. **Locate TRACKER.md** — Find files matching `*_TRACKER.md` or `TRACKER.md` in
   the directory. If multiple matches, use the first one alphabetically.

2. **Read type** — Parse frontmatter `type` field. Normalize spelling:
   `userstory` and `user-story` are both accepted (normalized to `user-story`).
   Verify type is one of the 5 known types (feature, defect, task, user-story,
   review). If unknown:
   `[WARN] — type "{value}" not recognized`

3. **Load manifest** — Read `$_SKILL_DIR/company-artifact-manifests.json`. Find
   the type entry in the `types` object.

4. **Check artifact completeness** — For each required artifact in the manifest:
   - List all `.md` files in the directory
   - Match files using the Filename Matching Rule above
   - If missing: `[MISSING] {artifact} — required artifact not found`
   - If found: validate frontmatter using Per-Artifact Validation above
     (including placeholder detection)

5. **Check tracker structure** — Apply File Mode steps 5-7 to the TRACKER.md
   file (template-derived sections, phases, and checkbox count). Same violation
   messages as File Mode, but emitted under the directory report's `LIFECYCLE:`
   block.

6. **Report** — Emit structured output:
   ```
   COMPANY-WORKFLOW VALIDATE: {directory}
     Type: {type}
     ARTIFACTS:
       [PASS]    TRACKER.md — all required fields present
       [PASS]    PRD.md — all required fields and sections present
       [MISSING] test-plan.md — required artifact not found
       [DRIFT]   ARCHITECTURE.md — missing required field "repo"
     LIFECYCLE:
       [PASS]    4 phases present, 12 checkboxes (min 12 per template)
     SUMMARY: 4 artifacts checked, 1 missing, 1 drift
   ```

## Reference Guides

Generation guides for AI doc creation live at `$_SKILL_DIR/reference/`:

| Guide | Purpose |
|---|---|
| guide-general.md | General generation instructions |
| guide-prd.md | PRD generation from user input |
| guide-architecture.md | Architecture doc generation |
| guide-test-spec.md | Test spec generation |
| guide-rca.md | Root cause analysis generation |
| guide-task.md | Task doc generation |
| guide-review-notes.md | Review notes generation |

## Philosophy

Design rationale for the lifecycle system lives at `$_SKILL_DIR/philosophy/`:

| Doc | Purpose |
|---|---|
| rationale-PRD.md | Why the PRD structure works this way |
| rationale-ARCHITECTURE.md | Why the architecture doc is structured this way |
| rationale-TEST-SPEC.md | Why the two-tier test model |

## Fixtures

Validation test fixtures live at `$_SKILL_DIR/fixtures/`:

### File Mode Fixtures

| Fixture | What it tests |
|---|---|
| invalid-bad-frontmatter.md | Missing or malformed YAML frontmatter |
| invalid-missing-lifecycle.md | Tracker without Lifecycle section |
| invalid-wrong-order.md | Sections in wrong order |

### Directory Mode Fixtures

| Fixture | What it tests |
|---|---|
| valid-feature-dir/ | Complete feature with all 3 required artifacts (tracker + feature-summary + milestones) |
| invalid-missing-artifact-dir/ | Feature with only TRACKER.md — should produce [MISSING] for feature-summary and milestones |

Use these to verify the `validate` command catches violations correctly.

## Error Handling

| Error | Message | Recovery |
|---|---|---|
| Not a git repo | "Error: /company-workflow requires a git repository." | Run inside a repo |
| Skill assets not found | "Error: company-workflow skill assets not found." | Run `skills-deploy install` or check repo structure |
| Target file not found | "Error: file not found: {path}" | Check the path |
| Unparseable frontmatter | "VIOLATION: could not parse YAML frontmatter in {path}" | Fix the frontmatter |
| Template not found | "Error: template tracker-{type}.md not found." | Run `skills-deploy install` or check template deployment |
| Unknown type | "VIOLATION: unknown type \"{value}\" in {path}" | Fix the `type` field |
| Not a tracker | "Warning: {path} does not look like a tracker file." | Use Directory Mode for doc artifacts |
| No TRACKER.md in directory | "Error: no TRACKER.md found in {directory}. Not a work item directory." | Check the path |
| Manifest missing | "Error: company-artifact-manifests.json not found." | Reinstall skill |
