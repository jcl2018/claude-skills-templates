---
name: qa-work-item
description: "QA a personal-workflow user-story per its TEST-SPEC. Runs smoke tests from the Smoke Tests table first; on green, dispatches a QA engineer subagent (fresh context, 5-min cap) for E2E verification per the E2E Tests table. Writes findings to tracker journal, transitions Phase 2 gates on green smoke + green E2E. Idempotent (re-run on green user-story is NO-OP). Boundary check refuses on incomplete Phase 2."
version: 0.1.0
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - AskUserQuestion
  - Agent
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

If `NOT_A_GIT_REPO`: tell the user "Error: /qa-work-item requires a git repository." and stop.

## Update Nudge Handling (skip silently if preamble printed nothing about updates)

Same as /personal-workflow: if preamble output contains `SKILLS_UPGRADE_AVAILABLE <old> <new>`, follow the upgrade flow defined in `~/.claude/skills/personal-workflow/SKILL.md` (debounce by session, branch-state precondition, AskUserQuestion 3 options). If `SKILLS_JUST_UPGRADED <from> <to>`, print "claude-skills-templates upgraded to v\<to\> (was v\<from\>)" and continue.

## Path Resolution

Resolve skill assets and templates using a 2-level fallback chain. This skill
depends on `personal-workflow`'s manifest + WORKFLOW.md as runtime source of
truth (boundary check via `/personal-workflow check`).

```bash
_REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
_SKILL_DIR=""        # this skill's own dir (for qa.md, fixtures/)
_PW_SKILL_DIR=""     # personal-workflow's dir (for manifest, WORKFLOW.md)

# Level 1: workbench repo
if [ -n "$_REPO_ROOT" ] && [ -f "$_REPO_ROOT/skills/qa-work-item/qa.md" ]; then
  _SKILL_DIR="$_REPO_ROOT/skills/qa-work-item"
fi
if [ -n "$_REPO_ROOT" ] && [ -f "$_REPO_ROOT/skills/personal-workflow/personal-artifact-manifests.json" ]; then
  _PW_SKILL_DIR="$_REPO_ROOT/skills/personal-workflow"
fi

# Level 2: deployed location
if [ -z "$_SKILL_DIR" ] && [ -f "$HOME/.claude/skills/qa-work-item/qa.md" ]; then
  _SKILL_DIR="$HOME/.claude/skills/qa-work-item"
fi
if [ -z "$_PW_SKILL_DIR" ] && [ -f "$HOME/.claude/skills/personal-workflow/personal-artifact-manifests.json" ]; then
  _PW_SKILL_DIR="$HOME/.claude/skills/personal-workflow"
fi

if [ -z "$_SKILL_DIR" ] || [ -z "$_PW_SKILL_DIR" ]; then
  echo "ERROR: Could not find skill assets."
  echo "Need: qa-work-item AND personal-workflow assets."
  echo "Run: ./scripts/skills-deploy install (workbench) or check repo structure."
  echo "NOT_FOUND"
else
  echo "SKILL_DIR: $_SKILL_DIR"
  echo "PW_SKILL_DIR: $_PW_SKILL_DIR"
fi
```

If `NOT_FOUND`: tell the user "Error: qa-work-item or personal-workflow skill assets not found. Run `skills-deploy install` or check the repo structure." and stop.

## Overview

This skill takes a single argument — the path to a user-story work-item
directory — and runs QA per the user-story's TEST-SPEC.md:

- **Smoke phase:** executes each row's Script/Command in `## Smoke Tests`, captures exit codes + stdout/stderr.
- **E2E phase (only on green smoke):** dispatches a QA engineer subagent via the Agent tool. Subagent reads TEST-SPEC, verifies each E2E row's Expected Outcome, writes detailed findings to the TRACKER journal, and returns a 1-2 sentence summary.
- **Phase 2 gate transition:** on green smoke + green E2E, marks the user-story tracker's `Smoke tests pass` and `Acceptance criteria verified met` Phase 2 gates.
- **Boundary check at start (Premise 1.3):** runs `/personal-workflow check` on the user-story dir; refuses if Phase 2 implementation gates (`Todos section reflects remaining work`, `Files section updated with changed files`) aren't met. The skill's job is to validate completed implementation work, not to QA a half-built user-story.
- **Boundary check at end (Premise 1.3):** runs `/personal-workflow check` after writes; surfaces violations via AskUserQuestion.
- **Idempotency (Premise 1.1):** re-running on a user-story whose Phase 2 gates are already marked by a prior `/qa-work-item` green run is a NO-OP.

The subagent's response is bounded: 1-2 sentences + file pointers (≤ 200 tokens). Detailed findings are written to the tracker by the subagent itself, not returned through the Agent tool result. This keeps the parent skill's context small (Premise 1).

For the full step-by-step logic, see [qa.md](qa.md).

## Usage

```
/qa-work-item <user-story-dir>
```

The skill operates on user-story directories only. If a feature directory is
provided, the skill lists its child user-stories and AskUserQuestion which one
to QA.

Example:

```
/qa-work-item work-items/features/personal-workflow/F000010_pipeline_skills/S000019_qa_work_item
```

## Routing

Read [qa.md](qa.md) and follow its instructions. The full QA orchestration
logic lives there: input validation, boundary check at start, idempotency
detection, smoke run, smoke-red short-circuit, subagent dispatch, finding
processing, gate transitions, boundary check at end.

## Error Handling

| Error | Message | Recovery |
|---|---|---|
| Not a git repo | "Error: /qa-work-item requires a git repository." | Run inside a repo |
| Skill assets not found | "Error: qa-work-item or personal-workflow skill assets not found." | Run `skills-deploy install` or check repo structure |
| User-story dir not found | "Error: user-story dir not found at {path}" | Verify path |
| Not a work-item dir (no TRACKER) | "Error: {path} is not a work-item directory (no TRACKER.md)" | Provide a path to a scaffolded user-story |
| Wrong type (not user-story) | "Error: /qa-work-item operates on user-story dirs only; got {type}" | Pass a user-story dir, or pass a feature dir to get a child-selection AUQ |
| TEST-SPEC missing | "Error: TEST-SPEC.md not found in {dir}" | Run `/scaffold-work-item` first |
| Boundary check at start fails | "Error: Phase 2 incomplete; run /implement-from-spec first." | Complete Phase 2 implementation gates, then re-run |
| Smoke red | "Smoke red: {N} failures. Fix smoke before E2E." | Fix the failing smoke tests, re-run |
| Subagent timeout (5-min cap) | "Subagent timed out after 5 minutes." | AskUserQuestion: re-run / skip E2E / abort |
| Boundary check at end fails | "Error: QA writes broke compliance. See /personal-workflow check output." | Inspect and fix, or report bug |
| Already QA'd green (idempotency) | "INFO: {ID} already QA'd green; nothing to do." | None — safe NO-OP |
