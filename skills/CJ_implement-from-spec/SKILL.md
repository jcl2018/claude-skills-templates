---
name: CJ_implement-from-spec
description: "Implement a CJ_personal-workflow work-item from its input artifacts. Reads per-type spec (SPEC+DESIGN for user-stories, RCA+test-plan for defects, TRACKER+test-plan for tasks; features delegate to a child user-story via AUQ), plans against Components Affected / Data Flow, writes code via Read/Edit/Write. Sensitive-surface AUQ for catalog/manifest/validator edits; propose-and-confirm by default (--auto for trivial ≤2-file changes). Idempotent. Use when: 'implement this work-item', 'write the code for this spec'."
version: 1.0.0
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

If `NOT_A_GIT_REPO`: tell the user "Error: /CJ_implement-from-spec requires a git repository." and stop.

## Update Nudge Handling (skip silently if preamble printed nothing about updates)

Same as /CJ_personal-workflow: if preamble output contains `SKILLS_UPGRADE_AVAILABLE <old> <new>`, follow the upgrade flow defined in `~/.claude/skills/CJ_personal-workflow/SKILL.md`. If `SKILLS_JUST_UPGRADED <from> <to>`, print "claude-skills-templates upgraded to v\<to\> (was v\<from\>)" and continue.

## Path Resolution

Resolve skill assets using a 2-level fallback chain. This skill depends on
`CJ_personal-workflow`'s manifest + WORKFLOW.md as its runtime source of truth
(boundary check via `/CJ_personal-workflow check`).

```bash
_REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
_SKILL_DIR=""        # this skill's own dir (for implement.md, fixtures/)
_PW_SKILL_DIR=""     # CJ_personal-workflow's dir

# Level 1: workbench repo
if [ -n "$_REPO_ROOT" ] && [ -f "$_REPO_ROOT/skills/CJ_implement-from-spec/implement.md" ]; then
  _SKILL_DIR="$_REPO_ROOT/skills/CJ_implement-from-spec"
fi
if [ -n "$_REPO_ROOT" ] && [ -f "$_REPO_ROOT/skills/CJ_personal-workflow/personal-artifact-manifests.json" ]; then
  _PW_SKILL_DIR="$_REPO_ROOT/skills/CJ_personal-workflow"
fi

# Level 2: deployed location
if [ -z "$_SKILL_DIR" ] && [ -f "$HOME/.claude/skills/CJ_implement-from-spec/implement.md" ]; then
  _SKILL_DIR="$HOME/.claude/skills/CJ_implement-from-spec"
fi
if [ -z "$_PW_SKILL_DIR" ] && [ -f "$HOME/.claude/skills/CJ_personal-workflow/personal-artifact-manifests.json" ]; then
  _PW_SKILL_DIR="$HOME/.claude/skills/CJ_personal-workflow"
fi

if [ -z "$_SKILL_DIR" ] || [ -z "$_PW_SKILL_DIR" ]; then
  echo "ERROR: Could not find skill assets."
  echo "Need: CJ_implement-from-spec AND CJ_personal-workflow assets."
  echo "Run: ./scripts/skills-deploy install (workbench) or check repo structure."
  echo "NOT_FOUND"
else
  echo "SKILL_DIR: $_SKILL_DIR"
  echo "PW_SKILL_DIR: $_PW_SKILL_DIR"
fi
```

If `NOT_FOUND`: tell the user "Error: CJ_implement-from-spec or CJ_personal-workflow skill assets not found. Run `skills-deploy install` or check the repo structure." and stop.

## Overview

This skill takes a work-item directory of any type (user-story, defect, task,
feature) and writes the code that its input artifacts describe:

- **Per-type input artifacts** (resolved from `_TRACKER.md` frontmatter `type:` field):

  | Type | Input artifacts | Plan source |
  |---|---|---|
  | user-story | `SPEC.md` + `DESIGN.md` (this story's + parent feature's) | SPEC's Components Affected + Data Flow |
  | defect | `RCA.md` + `test-plan.md` + `TRACKER.md` | RCA's Affected Components + Fix Description; test-plan rows define post-fix behavior |
  | task | `TRACKER.md` + `test-plan.md` | Tracker's Acceptance Criteria + Todos; test-plan rows define expected behavior |
  | feature | AUQ to pick a child user-story; delegate to that user-story's path | (delegated) |

- **Read context:** input artifacts (per type) plus the parent feature's DESIGN.md if applicable.
- **Plan the implementation:** parse the input artifact's Components Affected (or equivalent) and the desired behavior. Detect input gaps (`{placeholder}` values, missing sections) and AUQ before proceeding.
- **Sensitive-surface AUQ:** if the input artifact names `skills-catalog.json`, any `personal-artifact-manifests.json` / `company-artifact-manifests.json`, or any validator script, AskUserQuestion before committing those writes.
- **Default mode is propose-and-confirm:** the skill writes a diff preview to chat and AskUserQuestion to approve / modify / cancel. `--auto` skips the preview for trivial changes (heuristic: ≤2 files touched AND no sensitive-surface change). `--auto` is per-invocation only in v1.
- **Write code:** Read/Edit/Write tools per the input artifact's architecture decisions.
- **Update tracker:** category-grouped journal entries (`[impl-decision]`, `[impl-finding]`, `[impl]`, `[impl-auto]`); transition Phase 2 implementer-owned gates on green per the work-item's tracker template. For user-stories: `Todos section reflects remaining work` + `Files section updated with changed files` (the QA-owned gates `Acceptance criteria verified met` / `Smoke tests pass` are owned by `/CJ_qa-work-item`). For defects/tasks: per-template implementer-owned Phase 2 gates.
- **Boundary check at start (Premise 1.3):** runs `/CJ_personal-workflow check` on the work-item dir; refuses if Phase 1 isn't fully green.
- **Boundary check at end (Premise 1.3):** runs `/CJ_personal-workflow check` after writes; surfaces violations via AskUserQuestion.
- **Idempotency (Premise 1.1):** re-running on a work-item whose Phase 2 implementer-owned gates are already marked AND has a `[impl-pass]` journal entry is a NO-OP.

For the full step-by-step logic, see [implement.md](implement.md).

## Usage

```
/CJ_implement-from-spec <work-item-dir>
/CJ_implement-from-spec <work-item-dir> --auto
```

The skill accepts any work-item type. The `type:` field in the work-item's
`_TRACKER.md` frontmatter dispatches to the per-type input artifacts (see
Overview table). If a feature directory is provided, the skill lists its
child user-stories and AskUserQuestion which one to implement (preserves
the v1.10.0 path).

`--auto` skips the propose-and-confirm preview when the change is trivial. The
skill ignores `--auto` and falls through to propose-mode if the change touches
a sensitive surface OR more than 2 files; the safety override is non-negotiable.

Examples (per type):

```
# user-story (today's path; unchanged)
/CJ_implement-from-spec work-items/features/CJ_personal-workflow/F000010_pipeline_skills/S000018_implement_from_spec
/CJ_implement-from-spec work-items/features/CJ_personal-workflow/F000010_pipeline_skills/S000018_implement_from_spec --auto

# defect (new path; reads RCA + test-plan)
/CJ_implement-from-spec work-items/defects/CJ_personal-workflow/D000016_test_deploy_stale_templates

# task (new path; reads TRACKER + test-plan)
/CJ_implement-from-spec work-items/tasks/CJ_personal-workflow/T000005_some_task

# feature (delegates to a child user-story via AUQ)
/CJ_implement-from-spec work-items/features/CJ_personal-workflow/F000012_pipeline_parity
```

## Routing

Read [implement.md](implement.md) and follow its instructions. The full
implementation logic lives there: input validation, boundary check at start,
idempotency, read context, SPEC gap check, plan, sensitive-surface AUQ,
propose-and-confirm preview, write code, tracker updates, boundary check at end.

## Error Handling

| Error | Message | Recovery |
|---|---|---|
| Not a git repo | "Error: /CJ_implement-from-spec requires a git repository." | Run inside a repo |
| Skill assets not found | "Error: CJ_implement-from-spec or CJ_personal-workflow skill assets not found." | Run `skills-deploy install` or check repo structure |
| Work-item dir not found | "Error: work-item dir not found at {path}" | Verify path |
| Not a work-item dir (no TRACKER) | "Error: {path} is not a work-item directory (no TRACKER.md)" | Run `/CJ_scaffold-work-item` first |
| Frontmatter type missing or malformed | "Error: TRACKER.md frontmatter missing or malformed `type:` field; cannot dispatch." | Edit TRACKER.md to set `type: {feature\|user-story\|task\|defect}`; re-run |
| Unknown type | "Error: TRACKER.md `type: {value}` is not recognized; expected feature/user-story/task/defect" | Fix the type field or extend the per-type dispatch table in implement.md |
| Required input artifact missing | "Error: {artifact}.md not found in {dir} (required for type {type})" | Run `/CJ_scaffold-work-item` first; or fill the missing artifact manually |
| Boundary check at start fails | "Error: Phase 1 incomplete; resolve before implementing." | Complete Phase 1 gates (or run `/CJ_scaffold-work-item` if structural drift) |
| SPEC has unresolved placeholders or missing sections | "SPEC has gaps: {summary}. Fill them before implementing." | Edit SPEC.md to resolve placeholders or add missing sections, then re-run |
| User cancels at propose-and-confirm | "Aborted: user cancelled at preview." | Re-run when ready (idempotency: prior partial writes are recoverable) |
| User declines sensitive-surface AUQ | "Aborted: sensitive surface change declined." | Re-run after revising SPEC scope, or accept the AUQ on next run |
| Boundary check at end fails | "Error: implementation broke compliance. See /CJ_personal-workflow check output." | Inspect and fix; the implementation may need partial rollback |
| Already implemented (idempotency) | "INFO: {ID} already implemented; nothing to do." | None — safe NO-OP |
