---
name: personal-pipeline
description: "Single orchestrator over the 3 personal-workflow pipeline skills (scaffold-work-item, implement-from-spec, qa-work-item). Takes a design-doc path, dispatches each phase as a fresh-context Agent subagent with file-only handoff, runs independent inter-step quality gates, pre-collects AUQs at orchestrator (subagents have no AUQ tool). One keystroke for the full personal-workflow phase 2-4 loop. Halt-on-red default; idempotent; sunset criterion built in."
version: 0.1.0
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Agent
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

If `NOT_A_GIT_REPO`: tell the user "Error: /personal-pipeline requires a git repository." and stop.

## Update Nudge Handling (skip silently if preamble printed nothing about updates)

Same as /personal-workflow: if preamble output contains `SKILLS_UPGRADE_AVAILABLE <old> <new>`, follow the upgrade flow defined in `~/.claude/skills/personal-workflow/SKILL.md`. If `SKILLS_JUST_UPGRADED <from> <to>`, print "claude-skills-templates upgraded to v\<to\> (was v\<from\>)" and continue.

## Path Resolution

Resolve skill assets using a 2-level fallback chain. This skill depends on
the 3 underlying pipeline skills (scaffold-work-item, implement-from-spec,
qa-work-item) plus personal-workflow.

```bash
_REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
_SKILL_DIR=""

if [ -n "$_REPO_ROOT" ] && [ -f "$_REPO_ROOT/skills/personal-pipeline/pipeline.md" ]; then
  _SKILL_DIR="$_REPO_ROOT/skills/personal-pipeline"
fi
if [ -z "$_SKILL_DIR" ] && [ -f "$HOME/.claude/skills/personal-pipeline/pipeline.md" ]; then
  _SKILL_DIR="$HOME/.claude/skills/personal-pipeline"
fi

# Verify upstream skills exist (we dispatch to them via Agent tool)
for _UPSTREAM in scaffold-work-item implement-from-spec qa-work-item personal-workflow; do
  if [ ! -f "$HOME/.claude/skills/$_UPSTREAM/SKILL.md" ] && [ ! -f "$_REPO_ROOT/skills/$_UPSTREAM/SKILL.md" ]; then
    echo "ERROR: required upstream skill '$_UPSTREAM' not found."
    echo "Run: ./scripts/skills-deploy install (workbench)"
    echo "MISSING_UPSTREAM"
    exit 1
  fi
done

if [ -z "$_SKILL_DIR" ]; then
  echo "ERROR: personal-pipeline skill assets not found."
  echo "Run: ./scripts/skills-deploy install (workbench) or check repo structure."
  echo "NOT_FOUND"
else
  echo "SKILL_DIR: $_SKILL_DIR"
fi
```

If `NOT_FOUND` or `MISSING_UPSTREAM`: tell the user the matching error and stop.

## Overview

This skill takes a single argument — the path to an `/office-hours` design doc
in `~/.gstack/projects/{slug}/...-design-*.md` — and runs the personal-workflow
phase 2-4 loop end-to-end:

1. **Pre-scaffold idempotency check** (orchestrator) — read design-doc footer; route to one of 4 branches (footer+path / footer-no-path / no-footer-but-tracker-references / clean-slate).
2. **Phase 1 — scaffold subagent** dispatched via `Agent` tool with `subagent_type: general-purpose`. Subagent invokes `/scaffold-work-item`. Returns `RESULT: WORK_ITEM_DIR=<path>`.
3. **Post-scaffold gate** (orchestrator) — `/personal-workflow check` + footer-write-back confirm + multi-story-feature halt branch + AskUserQuestion to confirm shape.
4. **Phase 2 — implement subagent** with PRE-COLLECTED AUQs. Orchestrator scans the work-item's SPEC for sensitive-surface paths AND Tradeoffs taste-fork rows, AUQs the human up front, threads answers into the subagent prompt. Subagent invokes `/implement-from-spec` in `--auto`-equivalent mode (no AUQ attempts; AUQ tool is unreachable inside Agent subagents per S000026 spike). Subagent returns `RESULT: STATUS=...; FILES_CHANGED=<n>`.
5. **Post-implement gate** — `/personal-workflow check` + `scripts/validate.sh` (drops `scripts/test.sh` in v1).
6. **Phase 3 — qa subagent** invokes `/qa-work-item`. Returns `RESULT: SMOKE=...; E2E=...; PHASE2_GATES=...`.
7. **Post-QA gate** — parse tracker journal entries for `[smoke-pass]`/`[qa-pass]`; halt on red.
8. **Final summary + telemetry write** to `~/.gstack/analytics/personal-pipeline.jsonl`.

The orchestrator's own context stays under ~5K tokens; each subagent prompt is
under 500 tokens; each subagent return is under 200 tokens. RESULT-line parsing
is **lenient** (strips markdown blockquote prefixes and code fences) per S000026
spike findings — subagents reliably produce RESULT content but inconsistently
format the final line.

Sunset criterion baked in: the skill writes one telemetry line per invocation
to `~/.gstack/analytics/personal-pipeline.jsonl` with `{run_id, design_doc, end_state}`
where `end_state ∈ {green, halted_at_gate, user_aborted, subagent_crashed}`. On
the 6th invocation, the orchestrator AskUserQuestions for keep/delete based on
the trip-wire (≥3 of 5 `halted_at_gate` recommends delete; otherwise keep).

For the full step-by-step logic, see [pipeline.md](pipeline.md).

## Usage

```
/personal-pipeline <design-doc-path>
```

Example:

```
/personal-pipeline ~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-main-design-20260509-135305.md
```

The skill accepts a single positional argument (the design-doc path). No flags
in v1; sunset behavior is automatic on the 6th invocation. To force re-running
through the full pipeline on a re-scaffolded work-item, delete the design-doc's
`Status: SCAFFOLDED → ...` footer before re-invoking.

## Routing

Read [pipeline.md](pipeline.md) and follow its instructions. The full
orchestration logic lives there: input validation, pre-scaffold idempotency
(4 branches), Phase 1-3 dispatch, gate execution, sensitive-surface pre-scan
+ AUQ pre-collection for Phase 2, lenient RESULT-line parsing, telemetry
write, and the 6th-run sunset checkpoint.

## Error Handling

| Error | Message | Recovery |
|---|---|---|
| Not a git repo | "Error: /personal-pipeline requires a git repository." | Run inside a repo |
| Skill assets not found | "Error: personal-pipeline skill assets not found." | Run `skills-deploy install` |
| Required upstream skill missing | "Error: required upstream skill '{name}' not found." | Run `skills-deploy install`; verify all 4 upstream skills are deployed |
| Design doc not found | "Error: design doc not found at {path}" | Verify path; run `/office-hours` first if no design doc exists |
| Design doc not under ~/.gstack/projects/ | "Error: design doc must be under ~/.gstack/projects/ (got: {path})" | Move the design doc to the canonical location, or invoke `/office-hours` to produce one |
| Pre-scaffold check finds footer with missing path (branch b) | "Halt: design doc claims SCAFFOLDED → {path} but the path does not exist." | Either restore the dir or remove the footer line, then re-run |
| Pre-scaffold check finds partial-write state (branch c) | "Halt: scaffold appears to have halted between Step 9 and Step 12 — partial dir at {path} references this design doc but no footer present." | Either delete the partial dir or hand-write the footer pointing to it, then re-run |
| Subagent crash mid-phase | "Halt: {phase} subagent crashed; halt state written to tracker journal as `[subagent-crash]`." | Re-invoke the orchestrator (it will resume from the first incomplete phase via pre-scaffold check) or invoke the next individual skill manually |
| Gate red without override | "Halt at {gate}: {reason}. End state: halted_at_gate." | Inspect tracker journal `[gate-red]` entry; fix the issue; re-invoke |
| User cancels at AUQ | "Aborted: user cancelled at {decision_point}. End state: user_aborted." | Re-invoke when ready (idempotency: prior partial writes are recoverable) |
| Sensitive-surface pre-scan miss (subagent escalates) | "Phase 2 subagent escalated: {reason}. AUQ to operator." | Answer the AUQ; orchestrator threads answer into subagent re-dispatch |
| Boundary check at end fails | "Halt: post-{phase} gate found compliance break. See /personal-workflow check output." | Inspect, fix, re-invoke |

## Sunset Criterion

This skill carries an explicit sunset criterion. On the 6th invocation, the
orchestrator reads `~/.gstack/analytics/personal-pipeline.jsonl` and counts
`end_state == "halted_at_gate"` lines among the prior 5. If the count is ≥3,
the orchestrator AskUserQuestions a delete recommendation. The user keeps or
deletes; no qualitative leg (no "do you remember falling back to manual?"
self-report). The decision is fully observable from telemetry.

To delete: remove `skills/personal-pipeline/`, strike the `skills-catalog.json`
entry, run `skills-deploy install` to sync.
