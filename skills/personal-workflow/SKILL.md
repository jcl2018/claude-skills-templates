---
name: personal-workflow
description: "Personal work item validation with structural completeness checks. Validates tracker files and work item directories against personal templates and personal-artifact-manifests.json. Templates are the single source of truth for structural rules."
version: 2.0.0
allowed-tools:
  - Bash
  - Read
  - Write
  - Glob
  - Grep
---

## Preamble

Verify this is a git repository:

```bash
git rev-parse --show-toplevel 2>/dev/null || echo "NOT_A_GIT_REPO"
```

If `NOT_A_GIT_REPO`: tell the user "Error: /personal-workflow requires a git repository." and stop.

## Path Resolution

Resolve skill assets using a 2-level fallback chain. This ensures the skill
works both in the workbench repo and on machines where it's deployed via
`skills-deploy`.

```bash
_REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
_SKILL_DIR=""
_TMPL_DIR=""

# Level 1: workbench repo
if [ -n "$_REPO_ROOT" ] && [ -f "$_REPO_ROOT/skills/personal-workflow/personal-artifact-manifests.json" ]; then
  _SKILL_DIR="$_REPO_ROOT/skills/personal-workflow"
  _TMPL_DIR="$_REPO_ROOT/templates/personal-workflow"
fi

# Level 2: deployed location
if [ -z "$_SKILL_DIR" ] && [ -f "$HOME/.claude/skills/personal-workflow/personal-artifact-manifests.json" ]; then
  _SKILL_DIR="$HOME/.claude/skills/personal-workflow"
  _TMPL_DIR="$HOME/.claude/templates/personal-workflow"
fi

if [ -z "$_SKILL_DIR" ]; then
  echo "ERROR: Could not find personal-workflow skill assets."
  echo "Checked: $_REPO_ROOT/skills/personal-workflow/ and ~/.claude/skills/personal-workflow/"
  echo "NOT_FOUND"
else
  echo "SKILL_DIR: $_SKILL_DIR"
  echo "TMPL_DIR: $_TMPL_DIR"
fi
```

If `NOT_FOUND`: tell the user "Error: personal-workflow skill assets not found.
Run `skills-deploy install` or check the repo structure." and stop.

## Stale Rules Detection

```bash
[ -f "$HOME/.claude/rules/work-items.md" ] && echo "WARNING: stale ~/.claude/rules/work-items.md detected. Scaffolding rules now live in this skill's WORKFLOW.md. Remove the old file: rm ~/.claude/rules/work-items.md"
```

## Overview

Personal work item validation skill. Enforces the personal-dev work item standard:
structural validation derived directly from the templates in
`templates/personal-workflow/`, artifact completeness via
`personal-artifact-manifests.json`, and frontmatter compliance against templates.

Uses a 3-phase lifecycle (Track, Implement, Ship) and a 2-level template
fallback chain (repo root, then ~/.claude/).

**Templates are the single source of truth.** The validator derives every
structural rule (required frontmatter, required sections, section order,
lifecycle phases, minimum checkbox count) by parsing the matching template at
runtime. There is no separate `contract.json` to drift from the templates.

For the complete doc-driven development workflow (generating docs, scaffolding
conventions, installation), see [WORKFLOW.md](WORKFLOW.md).

## Usage

```
/personal-workflow check                # full work-items/ scan (Tier 1 + Tier 2)
/personal-workflow check <file>         # Tier 1 File Mode only
/personal-workflow check <dir>          # Tier 1 Directory Mode + Tier 2
/personal-workflow tree                 # quick hierarchy view with structural badges
```

## Subcommand Routing

Detect the subcommand from the user's input:

- `/personal-workflow check [path]` — validation (read check.md and follow it)
- `/personal-workflow tree` — quick hierarchy view (read tree.md and follow it)
- `/personal-workflow` with no subcommand — show the usage table above

For each subcommand, read the corresponding .md file in this skill directory
and follow its instructions.

## Error Handling

| Error | Message | Recovery |
|---|---|---|
| Not a git repo | "Error: /personal-workflow requires a git repository." | Run inside a repo |
| Skill assets not found | "Error: personal-workflow skill assets not found." | Run `skills-deploy install` or check repo structure |
| Target file not found | "Error: file not found: {path}" | Check the path |
| Unparseable frontmatter | "VIOLATION: could not parse YAML frontmatter in {path}" | Fix the frontmatter |
| Template not found | "Error: template tracker-{type}.md not found." | Run `skills-deploy install` or check template deployment |
| Unknown type | "VIOLATION: unknown type \"{value}\" in {path}" | Fix the `type` field |
| No TRACKER.md in directory | "Error: no TRACKER.md found in {directory}. Not a work item directory." | Check the path |
| Manifest missing | "Error: personal-artifact-manifests.json not found." | Reinstall skill |
| Template not found | "Warning: template {filename} not found. Skipping frontmatter validation." | Check template deployment |
| No work-items/ directory | "INFO: no work-items/ directory found. Skipping hierarchy checks." | Create work-items/ or check path |
