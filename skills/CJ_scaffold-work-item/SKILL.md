---
name: CJ_scaffold-work-item
description: "Scaffold a CJ_personal-workflow work item from an /office-hours design doc. Reads design + templates + manifest + WORKFLOW.md, produces a compliant work-item directory tree with all required artifacts. Runs /CJ_personal-workflow check at boundaries; idempotent (re-run on same input is NO-OP)."
version: 1.0.1
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - AskUserQuestion
---

## Preamble

Check for collection updates (silent if none, banner if a newer version is available):

```bash
_S=$(jq -r '.source // empty' "$HOME/.claude/.skills-templates.json" 2>/dev/null)
[ -n "$_S" ] && [ -x "$_S/scripts/skills-update-check" ] && "$_S/scripts/skills-update-check" 2>/dev/null || true
```

Verify this is a git repository:

```bash
git rev-parse --show-toplevel 2>/dev/null || echo "NOT_A_GIT_REPO"
```

If `NOT_A_GIT_REPO`: tell the user "Error: /CJ_scaffold-work-item requires a git repository." and stop.

## Update Nudge Handling (skip silently if preamble printed nothing about updates)

Same as /CJ_personal-workflow: if preamble output contains `SKILLS_UPGRADE_AVAILABLE <old> <new>`, follow the same upgrade flow defined in `~/.claude/skills/CJ_personal-workflow/SKILL.md` (debounce by session, branch-state precondition, AskUserQuestion 3 options). If `SKILLS_JUST_UPGRADED <from> <to>`, print "claude-skills-templates upgraded to v\<to\> (was v\<from\>)" and continue.

## Path Resolution

Resolve skill assets and templates using a 2-level fallback chain. This skill
depends on `CJ_personal-workflow`'s templates + manifest + WORKFLOW.md as its
runtime source of truth.

```bash
_REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
_SKILL_DIR=""        # this skill's own dir (for scaffold.md, fixtures/)
_PW_SKILL_DIR=""     # CJ_personal-workflow's dir (for manifest, WORKFLOW.md)
_TMPL_DIR=""         # CJ_personal-workflow templates

# Level 1: workbench repo
if [ -n "$_REPO_ROOT" ] && [ -f "$_REPO_ROOT/skills/CJ_scaffold-work-item/scaffold.md" ]; then
  _SKILL_DIR="$_REPO_ROOT/skills/CJ_scaffold-work-item"
fi
if [ -n "$_REPO_ROOT" ] && [ -f "$_REPO_ROOT/skills/CJ_personal-workflow/personal-artifact-manifests.json" ]; then
  _PW_SKILL_DIR="$_REPO_ROOT/skills/CJ_personal-workflow"
  _TMPL_DIR="$_REPO_ROOT/templates/CJ_personal-workflow"
fi

# Level 2: deployed location
if [ -z "$_SKILL_DIR" ] && [ -f "$HOME/.claude/skills/CJ_scaffold-work-item/scaffold.md" ]; then
  _SKILL_DIR="$HOME/.claude/skills/CJ_scaffold-work-item"
fi
if [ -z "$_PW_SKILL_DIR" ] && [ -f "$HOME/.claude/skills/CJ_personal-workflow/personal-artifact-manifests.json" ]; then
  _PW_SKILL_DIR="$HOME/.claude/skills/CJ_personal-workflow"
  _TMPL_DIR="$HOME/.claude/templates/CJ_personal-workflow"
fi

if [ -z "$_SKILL_DIR" ] || [ -z "$_PW_SKILL_DIR" ]; then
  echo "ERROR: Could not find skill assets."
  echo "Need: CJ_scaffold-work-item AND CJ_personal-workflow assets."
  echo "Run: ./scripts/skills-deploy install (workbench) or check repo structure."
  echo "NOT_FOUND"
else
  echo "SKILL_DIR: $_SKILL_DIR"
  echo "PW_SKILL_DIR: $_PW_SKILL_DIR"
  echo "TMPL_DIR: $_TMPL_DIR"
fi
```

If `NOT_FOUND`: tell the user "Error: CJ_scaffold-work-item or CJ_personal-workflow skill assets not found. Run `skills-deploy install` or check the repo structure." and stop.

## Overview

This skill takes a single argument — the path to an `/office-hours` design doc
in `~/.gstack/projects/{slug}/...-design-*.md` — and produces a compliant
work-item directory tree under `./work-items/`. It reads:

- The design doc (input)
- `personal-artifact-manifests.json` from `CJ_personal-workflow` (per-type artifact list)
- `WORKFLOW.md` from `CJ_personal-workflow` (hierarchy + scaffolding rules)
- Templates from `templates/CJ_personal-workflow/` (artifact structure)

It writes:

- A directory at `work-items/{type}s/{component}/{ID}_{slug}/` with all required artifacts
- For features, also nested user-story child directories (per WORKFLOW.md)

It runs `/CJ_personal-workflow check` at start (gate input drift) and end (gate
output compliance) — Premise 1.3 from the design.

It is idempotent (Premise 1.1): re-running on the same design doc whose work
item already exists with valid structure is a NO-OP.

For the full step-by-step logic, see [scaffold.md](scaffold.md).

## Usage

```
/CJ_scaffold-work-item <design-doc-path>                   # type derived from branch
/CJ_scaffold-work-item <design-doc-path> --type {feature|user-story|task|defect}
```

Example:

```
/CJ_scaffold-work-item ~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-main-design-20260508-102829.md
```

## Routing

Read [scaffold.md](scaffold.md) and follow its instructions. The full scaffolding
logic lives there: input validation, type detection, ID generation, multi-story
decomposition (for features), tree write, boundary checks, and the optional
SCAFFOLDED footer append on the source design doc.

## Error Handling

| Error | Message | Recovery |
|---|---|---|
| Not a git repo | "Error: /CJ_scaffold-work-item requires a git repository." | Run inside a repo |
| Skill assets not found | "Error: CJ_scaffold-work-item or CJ_personal-workflow skill assets not found." | Run `skills-deploy install` or check repo structure |
| Design doc not found | "Error: design doc not found at {path}" | Verify path; run `/office-hours` first if no design doc exists |
| Unparseable design doc | "Error: could not extract title/mode/recommended-approach from {path}" | Verify the design doc was produced by `/office-hours` |
| Manifest missing | "Error: personal-artifact-manifests.json not found." | Reinstall CJ_personal-workflow skill |
| Template not found | "Error: template {filename} not found at {_TMPL_DIR} or ~/.claude/templates/CJ_personal-workflow/. Run skills-deploy install." | Run `skills-deploy install` |
| Branch type unmatched + user cancels AskUserQuestion | "Aborted: type required to proceed" | Re-run after switching branches or providing `--type` argument |
| Boundary check at start fails | "Error: existing state in work-items/ has drift; refusing to scaffold on top. See /CJ_personal-workflow check output above." | Resolve drift, then re-run |
| Boundary check at end fails | "Error: scaffolded directory failed /CJ_personal-workflow check. See output above." | Inspect, fix the violation, or report bug |
| Already-scaffolded (idempotency) | "INFO: {ID} already scaffolded at {path}; nothing to do." | None — safe NO-OP |
