---
name: implement-from-spec
description: "Implement a personal-workflow user-story from its SPEC. Reads SPEC + DESIGN + TRACKER, plans the change against the SPEC's Components Affected and Data Flow, writes code via Read/Edit/Write tools. Sensitive-surface AUQ (catalog/manifest/validator). Propose-and-confirm by default; --auto for trivial changes (≤2 files, no sensitive surface). Idempotent (re-run on completed story is NO-OP). Boundary check refuses on incomplete Phase 1; verifies post-write compliance."
version: 0.1.0
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

If `NOT_A_GIT_REPO`: tell the user "Error: /implement-from-spec requires a git repository." and stop.

## Update Nudge Handling (skip silently if preamble printed nothing about updates)

Same as /personal-workflow: if preamble output contains `SKILLS_UPGRADE_AVAILABLE <old> <new>`, follow the upgrade flow defined in `~/.claude/skills/personal-workflow/SKILL.md`. If `SKILLS_JUST_UPGRADED <from> <to>`, print "claude-skills-templates upgraded to v\<to\> (was v\<from\>)" and continue.

## Path Resolution

Resolve skill assets using a 2-level fallback chain. This skill depends on
`personal-workflow`'s manifest + WORKFLOW.md as its runtime source of truth
(boundary check via `/personal-workflow check`).

```bash
_REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
_SKILL_DIR=""        # this skill's own dir (for implement.md, fixtures/)
_PW_SKILL_DIR=""     # personal-workflow's dir

# Level 1: workbench repo
if [ -n "$_REPO_ROOT" ] && [ -f "$_REPO_ROOT/skills/implement-from-spec/implement.md" ]; then
  _SKILL_DIR="$_REPO_ROOT/skills/implement-from-spec"
fi
if [ -n "$_REPO_ROOT" ] && [ -f "$_REPO_ROOT/skills/personal-workflow/personal-artifact-manifests.json" ]; then
  _PW_SKILL_DIR="$_REPO_ROOT/skills/personal-workflow"
fi

# Level 2: deployed location
if [ -z "$_SKILL_DIR" ] && [ -f "$HOME/.claude/skills/implement-from-spec/implement.md" ]; then
  _SKILL_DIR="$HOME/.claude/skills/implement-from-spec"
fi
if [ -z "$_PW_SKILL_DIR" ] && [ -f "$HOME/.claude/skills/personal-workflow/personal-artifact-manifests.json" ]; then
  _PW_SKILL_DIR="$HOME/.claude/skills/personal-workflow"
fi

if [ -z "$_SKILL_DIR" ] || [ -z "$_PW_SKILL_DIR" ]; then
  echo "ERROR: Could not find skill assets."
  echo "Need: implement-from-spec AND personal-workflow assets."
  echo "Run: ./scripts/skills-deploy install (workbench) or check repo structure."
  echo "NOT_FOUND"
else
  echo "SKILL_DIR: $_SKILL_DIR"
  echo "PW_SKILL_DIR: $_PW_SKILL_DIR"
fi
```

If `NOT_FOUND`: tell the user "Error: implement-from-spec or personal-workflow skill assets not found. Run `skills-deploy install` or check the repo structure." and stop.

## Overview

This skill takes a user-story work-item directory and writes the code that
the user-story's SPEC describes:

- **Read context:** SPEC.md (primary — requirements, acceptance criteria, architecture), DESIGN.md (parent-feature context), TRACKER.md (lifecycle state), parent feature's DESIGN.md.
- **Plan the implementation:** parse SPEC's Components Affected and Data Flow. Detect SPEC gaps (`{placeholder}` values, missing sections) and AUQ before proceeding.
- **Sensitive-surface AUQ:** if the SPEC's Components Affected names `skills-catalog.json`, any `personal-artifact-manifests.json` / `company-artifact-manifests.json`, or any validator script, AskUserQuestion before committing those writes.
- **Default mode is propose-and-confirm:** the skill writes a diff preview to chat and AskUserQuestion to approve / modify / cancel. `--auto` skips the preview for trivial changes (heuristic: ≤2 files touched AND no sensitive-surface change). `--auto` is per-invocation only in v1.
- **Write code:** Read/Edit/Write tools per the SPEC's architecture decisions.
- **Update tracker:** category-grouped journal entries (`[impl-decision]`, `[impl-finding]`, `[impl]`, `[impl-auto]`); transition Phase 2 implementer-owned gates (`Todos section reflects remaining work`, `Files section updated with changed files`) on green. The QA-owned gates (`Acceptance criteria verified met`, `Smoke tests pass`) are owned by `/qa-work-item` and remain UNCHECKED — that's the next pipeline step.
- **Boundary check at start (Premise 1.3):** runs `/personal-workflow check` on the user-story dir; refuses if Phase 1 isn't fully green.
- **Boundary check at end (Premise 1.3):** runs `/personal-workflow check` after writes; surfaces violations via AskUserQuestion.
- **Idempotency (Premise 1.1):** re-running on a user-story whose Phase 2 implementer-owned gates are already marked AND has a `[impl-pass]` journal entry is a NO-OP.

For the full step-by-step logic, see [implement.md](implement.md).

## Usage

```
/implement-from-spec <user-story-dir>
/implement-from-spec <user-story-dir> --auto
```

The skill operates on user-story directories only. If a feature directory is
provided, the skill lists its child user-stories and AskUserQuestion which one
to implement.

`--auto` skips the propose-and-confirm preview when the change is trivial. The
skill ignores `--auto` and falls through to propose-mode if the change touches
a sensitive surface OR more than 2 files; the safety override is non-negotiable.

Example:

```
/implement-from-spec work-items/features/personal-workflow/F000010_pipeline_skills/S000018_implement_from_spec
/implement-from-spec work-items/features/personal-workflow/F000010_pipeline_skills/S000018_implement_from_spec --auto
```

## Routing

Read [implement.md](implement.md) and follow its instructions. The full
implementation logic lives there: input validation, boundary check at start,
idempotency, read context, SPEC gap check, plan, sensitive-surface AUQ,
propose-and-confirm preview, write code, tracker updates, boundary check at end.

## Error Handling

| Error | Message | Recovery |
|---|---|---|
| Not a git repo | "Error: /implement-from-spec requires a git repository." | Run inside a repo |
| Skill assets not found | "Error: implement-from-spec or personal-workflow skill assets not found." | Run `skills-deploy install` or check repo structure |
| User-story dir not found | "Error: user-story dir not found at {path}" | Verify path |
| Not a work-item dir (no TRACKER) | "Error: {path} is not a work-item directory (no TRACKER.md)" | Run `/scaffold-work-item` first |
| Wrong type (not user-story) | "Error: /implement-from-spec operates on user-story dirs only; got {type}" | Pass a user-story dir, or pass a feature dir to get a child-selection AUQ |
| SPEC missing | "Error: SPEC.md not found in {dir}" | Run `/scaffold-work-item` first |
| Boundary check at start fails | "Error: Phase 1 incomplete; resolve before implementing." | Complete Phase 1 gates (or run `/scaffold-work-item` if structural drift) |
| SPEC has unresolved placeholders or missing sections | "SPEC has gaps: {summary}. Fill them before implementing." | Edit SPEC.md to resolve placeholders or add missing sections, then re-run |
| User cancels at propose-and-confirm | "Aborted: user cancelled at preview." | Re-run when ready (idempotency: prior partial writes are recoverable) |
| User declines sensitive-surface AUQ | "Aborted: sensitive surface change declined." | Re-run after revising SPEC scope, or accept the AUQ on next run |
| Boundary check at end fails | "Error: implementation broke compliance. See /personal-workflow check output." | Inspect and fix; the implementation may need partial rollback |
| Already implemented (idempotency) | "INFO: {ID} already implemented; nothing to do." | None — safe NO-OP |
