---
name: CJ_personal-workflow
description: "Personal work item validation. Validates tracker files and work item directories against personal templates and personal-artifact-manifests.json. Templates + WORKFLOW.md are the single source of truth for structural rules."
version: 4.0.0
allowed-tools:
  - Bash
  - Read
  - Write
  - Glob
  - Grep
  - AskUserQuestion
---

## Preamble

Check for collection updates (silent if none, banner if a newer version is available):

```bash
_UC="${CJ_SHARED_SCRIPTS:-$HOME/.claude/_cj-shared/scripts}/skills-update-check"
[ -x "$_UC" ] && "$_UC" 2>/dev/null || true
```

Verify this is a git repository:

```bash
git rev-parse --show-toplevel 2>/dev/null || echo "NOT_A_GIT_REPO"
```

## Update Nudge Handling (skip silently if preamble printed nothing about updates)

**If preamble output contains `SKILLS_UPGRADE_AVAILABLE <old> <new>`:**

1. Parse the two version tokens from the banner line. The banner is whitespace-separated: `marker old new`.
2. Resolve session: `SESSION="${CLAUDE_SESSION_ID:-$PPID}"` (Claude Code may not surface a session id; PPID is the stable fallback within one Claude Code window).
3. Resolve script path: `_S=$(jq -r '.source // empty' "$HOME/.claude/.skills-templates.json" 2>/dev/null)`. If empty, skip the prompt and continue.
4. Debounce: run `"$_S/scripts/skills-update-check" --should-prompt "$SESSION"`. Exit code 1 means "already prompted in this session" — suppress the prompt and continue with the workflow. Exit code 0 means "ok to prompt".
5. Branch-state precondition for upgrade: all of these must hold for `git pull --ff-only origin main` to succeed.
   - Working tree clean: `git -C "$_S" diff --quiet && git -C "$_S" diff --cached --quiet`
   - On `main`: `[ "$(git -C "$_S" rev-parse --abbrev-ref HEAD)" = "main" ]`
   - No local commits ahead of origin: `[ "$(git -C "$_S" rev-list --count "@{upstream}..HEAD" 2>/dev/null || echo 0)" = "0" ]`

   If any check fails, print: `Skills upgrade requires clean main with no local commits. Run: cd "$_S" && git checkout main && git pull --ff-only && ./scripts/skills-deploy install` Then call `"$_S/scripts/skills-update-check" --snooze 1` (1-hour snooze) and continue with the workflow.

6. Otherwise, AskUserQuestion with three options:
   - A) Upgrade now (recommended) — runs `git -C "$_S" pull --ff-only origin main && "$_S/scripts/skills-deploy" install --from-upgrade <old>`
   - B) Snooze 24h — runs `"$_S/scripts/skills-update-check" --snooze 24`
   - C) Skip this version — runs `"$_S/scripts/skills-update-check" --skip <new>`

7. Mark the session as prompted regardless of choice: `"$_S/scripts/skills-update-check" --prompted "$SESSION"`. Then continue with the workflow.

**If preamble output contains `SKILLS_JUST_UPGRADED <from> <to>`:** print "claude-skills-templates upgraded to v\<to\> (was v\<from\>)" and continue. The marker file has already been removed by skills-update-check itself.

If `NOT_A_GIT_REPO`: tell the user "Error: /CJ_personal-workflow requires a git repository." and stop.

## Path Resolution

Resolve skill assets using a 2-level fallback chain. This ensures the skill
works both in the workbench repo and on machines where it's deployed via
`skills-deploy`.

```bash
_REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
_SKILL_DIR=""
_TMPL_DIR=""

# Level 1: workbench repo
if [ -n "$_REPO_ROOT" ] && [ -f "$_REPO_ROOT/skills/CJ_personal-workflow/personal-artifact-manifests.json" ]; then
  _SKILL_DIR="$_REPO_ROOT/skills/CJ_personal-workflow"
  _TMPL_DIR="$_REPO_ROOT/templates/CJ_personal-workflow"
fi

# Level 2: deployed location
if [ -z "$_SKILL_DIR" ] && [ -f "$HOME/.claude/skills/CJ_personal-workflow/personal-artifact-manifests.json" ]; then
  _SKILL_DIR="$HOME/.claude/skills/CJ_personal-workflow"
  _TMPL_DIR="$HOME/.claude/templates/CJ_personal-workflow"
fi

if [ -z "$_SKILL_DIR" ]; then
  echo "ERROR: Could not find CJ_personal-workflow skill assets."
  echo "Checked: $_REPO_ROOT/skills/CJ_personal-workflow/ and ~/.claude/skills/CJ_personal-workflow/"
  echo "NOT_FOUND"
else
  echo "SKILL_DIR: $_SKILL_DIR"
  echo "TMPL_DIR: $_TMPL_DIR"
fi
```

If `NOT_FOUND`: tell the user "Error: CJ_personal-workflow skill assets not found.
Run `skills-deploy install` or check the repo structure." and stop.

## Stale Rules Detection

```bash
[ -f "$HOME/.claude/rules/work-items.md" ] && echo "WARNING: stale ~/.claude/rules/work-items.md detected. Scaffolding rules now live in this skill's WORKFLOW.md. Remove the old file: rm ~/.claude/rules/work-items.md"
```

## Overview

Personal work item validation skill. Enforces the personal-dev work item standard:
structural validation derived directly from the templates in
`templates/CJ_personal-workflow/`, artifact completeness via
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
/CJ_personal-workflow check                # full work-items/ scan (Tier 1 + Tier 2)
/CJ_personal-workflow check <file>         # Tier 1 File Mode only
/CJ_personal-workflow check <dir>          # Tier 1 Directory Mode + Tier 2
```

## Subcommand Routing

Detect the subcommand from the user's input:

- `/CJ_personal-workflow check [path]` — validation (read check.md and follow it)
- `/CJ_personal-workflow` with no subcommand — show the usage table above

For each subcommand, read the corresponding .md file in this skill directory
and follow its instructions.

## Error Handling

| Error | Message | Recovery |
|---|---|---|
| Not a git repo | "Error: /CJ_personal-workflow requires a git repository." | Run inside a repo |
| Skill assets not found | "Error: CJ_personal-workflow skill assets not found." | Run `skills-deploy install` or check repo structure |
| Target file not found | "Error: file not found: {path}" | Check the path |
| Unparseable frontmatter | "VIOLATION: could not parse YAML frontmatter in {path}" | Fix the frontmatter |
| Template not found | "Error: template tracker-{type}.md not found." | Run `skills-deploy install` or check template deployment |
| Unknown type | "VIOLATION: unknown type \"{value}\" in {path}" | Fix the `type` field |
| No TRACKER.md in directory | "Error: no TRACKER.md found in {directory}. Not a work item directory." | Check the path |
| Manifest missing | "Error: personal-artifact-manifests.json not found." | Reinstall skill |
| Template not found | "Warning: template {filename} not found. Skipping frontmatter validation." | Check template deployment |
| No work-items/ directory | "INFO: no work-items/ directory found. Skipping validation." | Create work-items/ or check path |
