---
name: company-workflow
description: "Company work item specification with structural validation. Validates tracker files and work item directories against company templates, contract.json, and company-artifact-manifests.json."
version: 2.0.0
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
standard: structural validation via contract.json, artifact completeness via
company-artifact-manifests.json, and frontmatter compliance against templates.

This skill is independent from the workbench's personal-dev templates and from
`/docs check`. It owns its own templates, contract, manifest, reference guides,
and validation logic.

## Path Resolution

Resolve skill assets using a 2-level fallback chain. This ensures the skill
works both in the workbench repo and on company machines where it's deployed
via `skills-deploy`.

```bash
_REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
_SKILL_DIR=""
_TMPL_DIR=""

# Level 1: workbench repo
if [ -n "$_REPO_ROOT" ] && [ -f "$_REPO_ROOT/skills/company-workflow/contract.json" ]; then
  _SKILL_DIR="$_REPO_ROOT/skills/company-workflow"
  _TMPL_DIR="$_REPO_ROOT/templates/company-workflow"
fi

# Level 2: deployed location
if [ -z "$_SKILL_DIR" ] && [ -f "$HOME/.claude/skills/company-workflow/contract.json" ]; then
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

Validates a single work item file against `contract.json`.

#### Steps

1. Read `$_SKILL_DIR/contract.json`:

```bash
cat "$_SKILL_DIR/contract.json"
```

2. Read the target file and parse its YAML frontmatter (between `---` markers).

3. Check required frontmatter fields from `contract.json`:
   - Required: `name`, `type`, `status`, `created`, `updated`
   - Recommended: `repo`, `branch`
   - Company-specific (check template): `workflow_type`, `url`

4. Check required sections. Extract all `## ` headings from the file and verify:
   - Required sections exist: Lifecycle, Todos, Log, PRs, Files, Journal
   - Optional sections: Meetings, Insights
   - Section order matches `expected_order` in contract.json:
     Lifecycle, Todos, Log, PRs, Files, Meetings, Insights, Journal

5. Check lifecycle structure:
   - Find the `## Lifecycle` section
   - Count checkboxes (`- [ ]` and `- [x]` patterns)
   - Verify at least `min_checkboxes` (4) exist (total across all phases)
   - Verify all 4 phases are present as `### Phase N: {name}` headings:
     Track, Implement, Review, Ship

6. Report results:
   - Exit 0: all checks pass. Print "VALID: {path}"
   - Exit 1: one or more violations. Print each violation to stderr:
     ```
     VIOLATION: missing required field "workflow_type" in {path}
     VIOLATION: missing section "Journal" in {path}
     VIOLATION: section order mismatch — "Files" appears before "PRs" in {path}
     VIOLATION: lifecycle has 3 checkboxes, minimum is 4 in {path}
     VIOLATION: missing phase "Ship" in {path}
     ```

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

#### Template Frontmatter Comparison

To validate an artifact's frontmatter against its template:
1. Resolve the template file from `$_TMPL_DIR/{template}` (using the 2-level
   fallback chain from Path Resolution)
2. Parse the template's YAML frontmatter to extract its key names
3. Parse the artifact's YAML frontmatter
4. For each key present in the template's frontmatter: check that the same key
   exists in the artifact. Comparison is key-presence only (values contain
   placeholders in templates).
5. Check for unresolved placeholders: scan frontmatter values for `{...}` patterns
   (regex `\{[A-Za-z_]+\}`). If found: flag `[DRIFT] {artifact} — unresolved
   placeholder "{placeholder}" in frontmatter`

#### Directory Mode Error Handling

- No TRACKER.md found: `"Error: no TRACKER.md found in {directory}. Not a work item directory."`
- company-artifact-manifests.json missing: `"Error: company-artifact-manifests.json not found at {path}. Run skills-deploy install or check skill structure."`
- Template file missing during frontmatter comparison: `"Warning: template {filename} not found at {path}. Skipping frontmatter validation for {artifact}."`

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
   - If found: validate frontmatter using the Template Frontmatter Comparison
     above (including placeholder detection)
   - Missing key: `[DRIFT] {artifact} — missing required field "{field}"`

5. **Check lifecycle** — Read TRACKER.md lifecycle section:
   - Verify all 4 phases exist (Track, Implement, Review, Ship)
   - Verify min 4 checkboxes total (across all phases) per contract.json
   - Verify required sections exist per contract.json

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
       [PASS]    4 phases present, 12 checkboxes
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
| contract.json missing | "Error: contract.json not found at {path}" | Reinstall skill |
| No TRACKER.md in directory | "Error: no TRACKER.md found in {directory}. Not a work item directory." | Check the path |
| Manifest missing | "Error: company-artifact-manifests.json not found." | Reinstall skill |
| Template not found | "Warning: template {filename} not found. Skipping frontmatter validation." | Check template deployment |
