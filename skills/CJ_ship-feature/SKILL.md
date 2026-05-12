---
name: CJ_ship-feature
description: "End-to-end orchestrator from an APPROVED /office-hours design doc to a verified production deploy. Chains /autoplan (review) → /CJ_personal-pipeline (scaffold→impl→QA, with --suppress-final-gate) → /ship (PR creation) → /land-and-deploy (merge + verify). Exactly 2 wrapper-orchestrated gates: /autoplan final-approval + /ship diff review. Sub-skill native AUQs (autoplan premise, ship pre-flight) pass through. Halt-on-red default; idempotent via each sub-skill's own re-entry path; sunset criterion at 6th invocation."
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
  - Skill
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

If `NOT_A_GIT_REPO`: tell the user "Error: /CJ_ship-feature requires a git repository." and stop.

## Update Nudge Handling (skip silently if preamble printed nothing about updates)

Same as /CJ_personal-pipeline: if preamble output contains `SKILLS_UPGRADE_AVAILABLE <old> <new>`, follow the upgrade flow defined in `~/.claude/skills/CJ_personal-workflow/SKILL.md`. If `SKILLS_JUST_UPGRADED <from> <to>`, print "claude-skills-templates upgraded to v\<to\> (was v\<from\>)" and continue.

## Path Resolution

Resolve skill assets using a 2-level fallback chain. This skill depends on
`/CJ_personal-pipeline` (subagent dispatch with `--suppress-final-gate`) plus
three gstack skills loaded inline (`/autoplan`, `/ship`, `/land-and-deploy`).

```bash
_REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
_SKILL_DIR=""

if [ -n "$_REPO_ROOT" ] && [ -f "$_REPO_ROOT/skills/CJ_ship-feature/ship-feature.md" ]; then
  _SKILL_DIR="$_REPO_ROOT/skills/CJ_ship-feature"
fi
if [ -z "$_SKILL_DIR" ] && [ -f "$HOME/.claude/skills/CJ_ship-feature/ship-feature.md" ]; then
  _SKILL_DIR="$HOME/.claude/skills/CJ_ship-feature"
fi

# Verify upstream skills exist
# - CJ_personal-pipeline: dispatched as Agent subagent with --suppress-final-gate
# - autoplan / ship / land-and-deploy: invoked inline via Skill tool
for _UPSTREAM in CJ_personal-pipeline; do
  if [ ! -f "$HOME/.claude/skills/$_UPSTREAM/SKILL.md" ] && [ ! -f "$_REPO_ROOT/skills/$_UPSTREAM/SKILL.md" ]; then
    echo "ERROR: required upstream skill '$_UPSTREAM' not found."
    echo "Run: ./scripts/skills-deploy install"
    echo "MISSING_UPSTREAM"
    exit 1
  fi
done

# Gstack skills are resolved at runtime via the Skill tool; presence not pre-checked
# here (Skill tool will surface "skill not found" naturally if any are missing).

if [ -z "$_SKILL_DIR" ]; then
  echo "ERROR: CJ_ship-feature skill assets not found."
  echo "Run: ./scripts/skills-deploy install (workbench) or check repo structure."
  echo "NOT_FOUND"
else
  echo "SKILL_DIR: $_SKILL_DIR"
fi
```

If `NOT_FOUND` or `MISSING_UPSTREAM`: tell the user the matching error and stop.

## Overview

This skill takes a single argument — the path to an APPROVED `/office-hours` design doc
in `~/.gstack/projects/{slug}/...-design-*.md` — and runs the full feature lifecycle
end-to-end:

1. **Pre-flight** (orchestrator) — validate the design doc exists, is under `~/.gstack/projects/`, and has `Status: APPROVED`. Set up shared decision-log path.
2. **Phase 1 — /autoplan** (Skill, inline) — review the design doc via /autoplan's CEO + design + eng + DX review chain. /autoplan's native final-approval AUQ is **GATE #1**.
3. **Phase 2 — /CJ_personal-pipeline** (Agent subagent, `--suppress-final-gate`) — scaffold → impl → QA. 8.5 + 9.2 AUQs suppressed; decisions logged to wrapper-specified path.
4. **Phase 3 — /ship** (Skill, inline) — diff review, version bump confirm (already done if pipeline output is at 2.1.x), PR creation. /ship's native diff-review AUQ is **GATE #2**.
5. **Phase 4 — /land-and-deploy** (Skill, inline) — merge PR, verify deploy. Auto-passes on green canary; alerts on red.
6. **Final summary + telemetry** — write to `~/.gstack/analytics/CJ_ship-feature.jsonl`. Sunset checkpoint on invocation 6, then every 5.

Exactly **2 wrapper-orchestrated AUQs** (/autoplan final + /ship diff review). Sub-skills may surface their own native AUQs (autoplan premise gate, /ship pre-flight halts) — those pass through; wrapper does not pre-collect.

The orchestrator's own context grows by the sum of /autoplan + /ship + /land-and-deploy
when those skills are loaded inline (~5-10K tokens combined). CJ_personal-pipeline runs
as Agent subagent to keep its own context fresh and to leverage S000026's
suppress-final-gate path. See `ship-feature.md` for the full step-by-step logic.

Sunset criterion baked in: the skill writes one telemetry line per invocation
to `~/.gstack/analytics/CJ_ship-feature.jsonl` with `{run_id, design_doc, work_item,
end_state, multi_story_scaffold_only, ts}` where `end_state ∈ {green,
halted_at_autoplan, halted_at_pipeline, halted_at_ship, halted_at_deploy,
deploy_red, subagent_crashed}`. On the 6th invocation, the orchestrator
AskUserQuestions for keep/delete based on a brittleness trip-wire (≥3 of 5
prior runs in `halted_at_(autoplan|pipeline|deploy)` or `subagent_crashed` →
recommend delete). `halted_at_ship` and `deploy_red` are excluded — those are
healthy outcomes (review caught a real issue; production health concern).

For the full step-by-step logic, see [ship-feature.md](ship-feature.md).

## Usage

```
/CJ_ship-feature <design-doc-path>
```

Example:

```
/CJ_ship-feature ~/.gstack/projects/jcl2018-knowledge-base/chjiang-claude-stupefied-ellis-2949b6-design-20260511-220642.md
```

Positional arg: `<design-doc-path>`. The path MUST be under `~/.gstack/projects/`
and the design doc MUST contain `Status: APPROVED` somewhere in its body
(typically near the top frontmatter; the wrapper greps the whole file).

Sunset behavior is automatic on the 6th invocation. To force re-running through
the full pipeline on a re-scaffolded work-item, delete the design-doc's
`Status: SCAFFOLDED → ...` footer before re-invoking (this re-triggers
CJ_personal-pipeline's Phase 1 scaffold via its Branch (d) clean-slate path).

## Routing

Read [ship-feature.md](ship-feature.md) and follow its instructions. The full
orchestration logic lives there: input validation, /autoplan inline call,
CJ_personal-pipeline subagent dispatch with suppress-final-gate, multi-story
shape detection, /ship inline call, /land-and-deploy inline call, telemetry
write, and the 6th-run sunset checkpoint.

## Error Handling

| Error | Message | Recovery |
|---|---|---|
| Not a git repo | "Error: /CJ_ship-feature requires a git repository." | Run inside a repo |
| Skill assets not found | "Error: CJ_ship-feature skill assets not found." | Run `skills-deploy install` |
| CJ_personal-pipeline missing | "Error: required upstream skill 'CJ_personal-pipeline' not found." | Run `skills-deploy install` |
| Design doc not found | "Error: design doc not found at {path}" | Verify path; run `/office-hours` first |
| Design doc outside ~/.gstack/projects/ | "Error: design doc must be under ~/.gstack/projects/ (got: {path})" | Move the doc, or invoke `/office-hours` |
| Design doc lacks `Status: APPROVED` | "Error: design doc lacks 'Status: APPROVED'. Run /office-hours, accept the final approval, then re-invoke." | Resume /office-hours; accept final approval |
| /autoplan aborted | "Wrapper halted at /autoplan final gate. end_state=halted_at_autoplan." | Re-invoke when ready; /autoplan re-runs |
| CJ_personal-pipeline halted | "Wrapper halted at CJ_personal-pipeline. Tracker at {path}. Pipeline decision log: {path}." | Inspect tracker; fix; re-invoke OR invoke /ship + /land-and-deploy manually if pipeline state is green-enough |
| Multi-story feature scaffold-only | "Multi-story feature scaffolded. Per-child invocation needed: ..." + per-child instructions | Invoke /CJ_ship-feature OR /CJ_personal-pipeline on each child design doc |
| /ship aborted | "Wrapper halted at /ship review. Commits at {branch} not yet pushed as PR. Pipeline decision log: {path}." | Manually invoke /ship later; commits already exist |
| /land-and-deploy halted | "Wrapper halted at /land-and-deploy. {error}." | Fix root cause; manually invoke /land-and-deploy |
| Canary red post-deploy | "Canary red — see report at {path}. No auto-rollback." | Manual: rollback OR fix-forward |
| Subagent crash mid-pipeline | "CJ_personal-pipeline subagent crashed (no RESULT line). end_state=subagent_crashed." | Re-invoke; pipeline branch (a) skip path resumes from work-item dir on disk |

## Sunset Criterion

Mirrors `/CJ_personal-pipeline`'s pattern. On the 6th invocation (and every 5
thereafter), the orchestrator reads `~/.gstack/analytics/CJ_ship-feature.jsonl`
and counts brittleness-signal `end_state` lines among the prior 5:

- **Counts toward trip-wire**: `halted_at_autoplan`, `halted_at_pipeline`,
  `halted_at_deploy`, `subagent_crashed` (orchestration health signals).
- **Excluded**: `green` (happy path), `halted_at_ship` (review caught real
  issue — gate doing its job), `deploy_red` (production state, not wrapper
  brittleness), lines with `multi_story_scaffold_only: true` (correct halt
  per design).

If the brittleness count is ≥3 of 5, the orchestrator AskUserQuestions for
keep/delete. The user keeps or deletes; no qualitative self-report leg.

To delete: remove `skills/CJ_ship-feature/`, strike the catalog entry,
run `skills-deploy install`.
