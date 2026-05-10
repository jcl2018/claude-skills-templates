---
name: CJ_qa-work-item
description: "QA a CJ_personal-workflow work-item (user-story, defect, or task) per its test rows. For user-stories: runs Smoke Tests then dispatches a QA engineer subagent (fresh context, 5-min cap) for E2E verification per TEST-SPEC. For defects/tasks: runs test-plan rows as smoke-equivalent (no E2E subagent in v1). Writes findings to tracker journal; transitions Phase 2 qa-owned gates for user-stories; records [qa-pass] for defects/tasks. Idempotent (re-run on green work-item is NO-OP). Boundary check refuses on incomplete Phase 2."
version: 1.0.0
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

If `NOT_A_GIT_REPO`: tell the user "Error: /CJ_qa-work-item requires a git repository." and stop.

## Update Nudge Handling (skip silently if preamble printed nothing about updates)

Same as /CJ_personal-workflow: if preamble output contains `SKILLS_UPGRADE_AVAILABLE <old> <new>`, follow the upgrade flow defined in `~/.claude/skills/CJ_personal-workflow/SKILL.md` (debounce by session, branch-state precondition, AskUserQuestion 3 options). If `SKILLS_JUST_UPGRADED <from> <to>`, print "claude-skills-templates upgraded to v\<to\> (was v\<from\>)" and continue.

## Path Resolution

Resolve skill assets and templates using a 2-level fallback chain. This skill
depends on `CJ_personal-workflow`'s manifest + WORKFLOW.md as runtime source of
truth (boundary check via `/CJ_personal-workflow check`).

```bash
_REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
_SKILL_DIR=""        # this skill's own dir (for qa.md, fixtures/)
_PW_SKILL_DIR=""     # CJ_personal-workflow's dir (for manifest, WORKFLOW.md)

# Level 1: workbench repo
if [ -n "$_REPO_ROOT" ] && [ -f "$_REPO_ROOT/skills/CJ_qa-work-item/qa.md" ]; then
  _SKILL_DIR="$_REPO_ROOT/skills/CJ_qa-work-item"
fi
if [ -n "$_REPO_ROOT" ] && [ -f "$_REPO_ROOT/skills/CJ_personal-workflow/personal-artifact-manifests.json" ]; then
  _PW_SKILL_DIR="$_REPO_ROOT/skills/CJ_personal-workflow"
fi

# Level 2: deployed location
if [ -z "$_SKILL_DIR" ] && [ -f "$HOME/.claude/skills/CJ_qa-work-item/qa.md" ]; then
  _SKILL_DIR="$HOME/.claude/skills/CJ_qa-work-item"
fi
if [ -z "$_PW_SKILL_DIR" ] && [ -f "$HOME/.claude/skills/CJ_personal-workflow/personal-artifact-manifests.json" ]; then
  _PW_SKILL_DIR="$HOME/.claude/skills/CJ_personal-workflow"
fi

if [ -z "$_SKILL_DIR" ] || [ -z "$_PW_SKILL_DIR" ]; then
  echo "ERROR: Could not find skill assets."
  echo "Need: CJ_qa-work-item AND CJ_personal-workflow assets."
  echo "Run: ./scripts/skills-deploy install (workbench) or check repo structure."
  echo "NOT_FOUND"
else
  echo "SKILL_DIR: $_SKILL_DIR"
  echo "PW_SKILL_DIR: $_PW_SKILL_DIR"
fi
```

If `NOT_FOUND`: tell the user "Error: CJ_qa-work-item or CJ_personal-workflow skill assets not found. Run `skills-deploy install` or check the repo structure." and stop.

## Overview

This skill takes a single argument — the path to a work-item directory of any
type (user-story, defect, task, feature) — and runs QA per the type-appropriate
test rows:

- **Per-type test-row source** (resolved from `_TRACKER.md` frontmatter `type:` field):

  | Type | Test rows source | E2E subagent dispatch (v1) |
  |---|---|---|
  | user-story | `TEST-SPEC.md` (`## Smoke Tests` + `## E2E Tests`) | YES (existing path) |
  | defect | `test-plan.md` (`## Regression Test Cases` table) — all rows treated as smoke-equivalent | NO (defer to v2) |
  | task | `test-plan.md` (`## Regression Test Cases` table) — all rows treated as smoke-equivalent | NO (defer to v2) |
  | feature | (delegates to a child work-item via AUQ) | (per chosen child's type) |

- **Smoke phase:** executes each row's Script/Command (or test-plan row's Steps), captures exit codes + stdout/stderr. For test-plan rows, run the steps as a sequence; for TEST-SPEC Smoke rows, the Script/Command column is the runnable.
- **E2E phase (user-story only, on green smoke):** dispatches a QA engineer subagent via the Agent tool. Subagent reads TEST-SPEC, verifies each E2E row's Expected Outcome, writes detailed findings to the TRACKER journal, returns a 1-2 sentence summary. For defect/task: skipped in v1 (test-plan rows are the verification layer).
- **Phase 2 gate transition (per type):**
  - user-story (on green smoke + green E2E): marks `Smoke tests pass` + `Acceptance criteria verified met`.
  - defect / task: no qa-owned Phase 2 gates per template. Records `[qa-pass]` journal entry on green; the Phase 3 `Test-plan verified` gate is marked at `/ship` time or by `/CJ_personal-workflow check --update` post-merge.
- **Boundary check at start (Premise 1.3):** runs `/CJ_personal-workflow check` on the work-item dir; refuses if the type's Phase 2 implementer-owned gates aren't met. The skill validates completed implementation, not a half-built work-item.
- **Boundary check at end (Premise 1.3):** runs `/CJ_personal-workflow check` after writes; surfaces violations via AskUserQuestion.
- **Idempotency (Premise 1.1):** re-running on a work-item whose qa state already converged (gates marked / `[qa-pass]` journal entry exists for current commit) is a NO-OP.

The subagent's response is bounded: 1-2 sentences + file pointers (≤ 200 tokens). Detailed findings are written to the tracker by the subagent itself, not returned through the Agent tool result. This keeps the parent skill's context small (Premise 1).

For the full step-by-step logic, see [qa.md](qa.md).

## Usage

```
/CJ_qa-work-item <work-item-dir>
```

The skill accepts any work-item type. The `type:` field in the work-item's
`_TRACKER.md` frontmatter dispatches to the per-type test-row source. If a
feature directory is provided, the skill lists its child work-items and
AskUserQuestion which one to QA.

Examples (per type):

```
# user-story (today's path; unchanged — TEST-SPEC, smoke + E2E subagent)
/CJ_qa-work-item work-items/features/CJ_personal-workflow/F000010_pipeline_skills/S000019_qa_work_item

# defect (new path; runs test-plan rows as smoke-equivalent)
/CJ_qa-work-item work-items/defects/CJ_personal-workflow/D000016_test_deploy_stale_templates

# task (new path; same shape as defect)
/CJ_qa-work-item work-items/tasks/CJ_personal-workflow/T000005_some_task

# feature (delegates to a child work-item via AUQ)
/CJ_qa-work-item work-items/features/CJ_personal-workflow/F000012_pipeline_parity
```

## Routing

Read [qa.md](qa.md) and follow its instructions. The full QA orchestration
logic lives there: input validation, boundary check at start, idempotency
detection, smoke run, smoke-red short-circuit, subagent dispatch, finding
processing, gate transitions, boundary check at end.

## Error Handling

| Error | Message | Recovery |
|---|---|---|
| Not a git repo | "Error: /CJ_qa-work-item requires a git repository." | Run inside a repo |
| Skill assets not found | "Error: CJ_qa-work-item or CJ_personal-workflow skill assets not found." | Run `skills-deploy install` or check repo structure |
| Work-item dir not found | "Error: work-item dir not found at {path}" | Verify path |
| Not a work-item dir (no TRACKER) | "Error: {path} is not a work-item directory (no TRACKER.md)" | Provide a path to a scaffolded work-item |
| Frontmatter type missing or malformed | "Error: TRACKER.md frontmatter missing or malformed `type:` field; cannot dispatch." | Edit TRACKER.md to set `type: {feature\|user-story\|task\|defect}`; re-run |
| Unknown type | "Error: TRACKER.md `type: {value}` is not recognized; expected feature/user-story/task/defect" | Fix the type field or extend the per-type dispatch table in qa.md |
| Required test-row source missing | "Error: {artifact}.md not found in {dir} (required for type {type} QA)" | Run `/CJ_scaffold-work-item` first; or fill the missing artifact manually |
| Boundary check at start fails | "Error: Phase 2 incomplete; run /CJ_implement-from-spec first." | Complete Phase 2 implementation gates, then re-run |
| Smoke red | "Smoke red: {N} failures. Fix smoke before E2E." | Fix the failing smoke tests, re-run |
| Subagent timeout (5-min cap) | "Subagent timed out after 5 minutes." | AskUserQuestion: re-run / skip E2E / abort |
| Boundary check at end fails | "Error: QA writes broke compliance. See /CJ_personal-workflow check output." | Inspect and fix, or report bug |
| Already QA'd green (idempotency) | "INFO: {ID} already QA'd green; nothing to do." | None — safe NO-OP |
