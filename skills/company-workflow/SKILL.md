---
name: company-workflow
description: "Company work item specification with structural validation. Scaffolds work items from company templates and validates tracker frontmatter, section ordering, and lifecycle phases against contract.json."
version: 1.0.0
allowed-tools:
  - Bash
  - Read
  - Glob
  - Grep
---

## Preamble

Log skill usage:

```bash
mkdir -p ~/.gstack/analytics
echo '{"skill":"company-workflow","ts":"'"$(date -u +%Y-%m-%dT%H:%M:%SZ)"'","repo":"'"$(basename "$(git rev-parse --show-toplevel 2>/dev/null)" 2>/dev/null || echo unknown)"'"}' >> ~/.gstack/analytics/skill-usage.jsonl 2>/dev/null || true
```

Verify this is a git repository:

```bash
git rev-parse --show-toplevel 2>/dev/null || echo "NOT_A_GIT_REPO"
```

If `NOT_A_GIT_REPO`: tell the user "Error: /company-workflow requires a git repository." and stop.

## Overview

Company work item specification skill. Enforces the company's formal work item
standard: structural validation via contract.json, tracker templates with
`workflow_type` and `url` fields, verbose lifecycle sub-gate checkboxes, and
five work item types (feature, defect, task, userstory, review).

This skill is independent from the workbench's personal-dev templates and from
`/docs check`. It owns its own templates, contract, reference guides, and
validation logic.

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

## Routing Table

Map branch naming patterns to company work item types:

| Branch pattern | Type | Tracker template |
|---|---|---|
| `feature-*`, `feat-*`, `feat/*` | feature | tracker-feature.md |
| `defect-*`, `fix-*`, `fix/*`, `bugfix-*` | defect | tracker-defect.md |
| `task-*`, `chore-*`, `chore/*` | task | tracker-task.md |
| `story-*`, `userstory-*` | userstory | tracker-user-story.md |
| `review-*` | review | tracker-review.md |

Required artifacts per type:

| Type | Required artifacts | Count |
|---|---|---|
| feature | tracker, PRD, ARCHITECTURE, TEST-SPEC, milestones | 5 |
| defect | tracker, RCA, test-plan | 3 |
| task | tracker, test-plan | 2 |
| userstory | tracker, PRD, ARCHITECTURE, TEST-SPEC, milestones | 5 |
| review | tracker, review-notes | 2 |

## Subcommand: validate

Validates a single work item file against `contract.json`.

### Usage

```
/company-workflow validate <path-to-tracker>
```

### Steps

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
     Lifecycle, Todos, Log, PRs, Files, Meetings, Insights, Journal, Handoff

5. Check lifecycle structure:
   - Find the `## Lifecycle` section
   - Count checkboxes (`- [ ]` and `- [x]` patterns)
   - Verify at least `min_checkboxes` (4) exist
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

| Fixture | What it tests |
|---|---|
| invalid-bad-frontmatter.md | Missing or malformed YAML frontmatter |
| invalid-missing-lifecycle.md | Tracker without Lifecycle section |
| invalid-wrong-order.md | Sections in wrong order |

Use these to verify the `validate` subcommand catches violations correctly.

## Usage

```bash
# Validate a company work item tracker
/company-workflow validate work-items/F000003_company_spec_system/F000003_TRACKER.md

# Check a fixture (should fail)
/company-workflow validate skills/company-workflow/fixtures/invalid-bad-frontmatter.md
```

## Error Handling

| Error | Message | Recovery |
|---|---|---|
| Not a git repo | "Error: /company-workflow requires a git repository." | Run inside a repo |
| Skill assets not found | "Error: company-workflow skill assets not found." | Run `skills-deploy install` or check repo structure |
| Target file not found | "Error: file not found: {path}" | Check the path |
| Unparseable frontmatter | "VIOLATION: could not parse YAML frontmatter in {path}" | Fix the frontmatter |
| contract.json missing | "Error: contract.json not found at {path}" | Reinstall skill |
