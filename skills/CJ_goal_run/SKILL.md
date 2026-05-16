---
name: CJ_goal_run
description: "Unified pipeline entry point (formerly /CJ_run; renamed v4.0.0). Accepts (a) an APPROVED /office-hours design doc → full pipeline (autoplan → scaffold → impl → QA → PR → deploy), (b) a work-item directory → Branch(f) full phase-detection + dispatch (impl_qa_ship / qa_ship / ship / open_pr / already_shipped / pr_unknown_state) using verbatim Phase 2 gate strings + gh PR-state check with graceful UNKNOWN fallback, or (c) no argument → Branch(g) scans current branch's work-items/ for in-progress user-stories and hands off to Branch(f). Phase 4 invokes /land-and-deploy with --suppress-readiness-gate (opt-in upstream flag mirroring CJ_personal-pipeline's --suppress-final-gate pattern) so green end-to-end runs surface only the autoplan + /ship AUQs; red signals (CI, merge conflict, free-test regression, deploy/canary failure) still halt. Branch(f) open_pr mode auto-continues into /land-and-deploy with the same flag + inline-parsed PR_NUM (verbatim duplicate of Step 5's parsing block). Replaces /CJ_ship-feature (renamed) and the public /CJ_personal-pipeline routing (now internal). Halt-on-red default; idempotent via each sub-skill's own re-entry path; sunset criterion at 6th invocation."
version: 1.0.0
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

If `NOT_A_GIT_REPO`: tell the user "Error: /CJ_goal_run requires a git repository." and stop.

## Update Nudge Handling (skip silently if preamble printed nothing about updates)

Same as /CJ_personal-pipeline: if preamble output contains `SKILLS_UPGRADE_AVAILABLE <old> <new>`, follow the upgrade flow defined in `~/.claude/skills/CJ_personal-workflow/SKILL.md`. If `SKILLS_JUST_UPGRADED <from> <to>`, print "claude-skills-templates upgraded to v\<to\> (was v\<from\>)" and continue.

## Path Resolution

Resolve skill assets using a 2-level fallback chain. This skill depends on
`/CJ_personal-pipeline` (subagent dispatch with `--suppress-final-gate`) plus
three gstack skills loaded inline (`/autoplan`, `/ship`, `/land-and-deploy`).

```bash
_REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
_SKILL_DIR=""

if [ -n "$_REPO_ROOT" ] && [ -f "$_REPO_ROOT/skills/CJ_goal_run/run.md" ]; then
  _SKILL_DIR="$_REPO_ROOT/skills/CJ_goal_run"
fi
if [ -z "$_SKILL_DIR" ] && [ -f "$HOME/.claude/skills/CJ_goal_run/run.md" ]; then
  _SKILL_DIR="$HOME/.claude/skills/CJ_goal_run"
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
  echo "ERROR: CJ_goal_run skill assets not found."
  echo "Run: ./scripts/skills-deploy install (workbench) or check repo structure."
  echo "NOT_FOUND"
else
  echo "SKILL_DIR: $_SKILL_DIR"
fi
```

If `NOT_FOUND` or `MISSING_UPSTREAM`: tell the user the matching error and stop.

## Overview

This skill is the single public entry point for running the CJ pipeline. It
accepts three input shapes; the input determines which branch fires:

```
/CJ_goal_run <design-doc-path>   → full pipeline (Branches a/b/c/d)
/CJ_goal_run <work-item-dir>     → phase-detect + dispatch (Branch f)
/CJ_goal_run                     → scan branch's work-items/ + auto-resume (Branch g)
```

**Branch summary:**

| Branch | Trigger | Behavior |
|---|---|---|
| (a) | design-doc mode, work already shipped | idempotency skip |
| (b) | design-doc mode, MULTI_STORY=1 | auto-iterate children via per-child work-item-dir mode |
| (c) | design-doc mode, single-story | full pipeline: autoplan → scaffold → impl → QA → PR → deploy |
| (d) | design-doc arg, Status != APPROVED | error: "Design doc is not APPROVED" |
| (f) | work-item-dir arg | detect phase from TRACKER state, dispatch sub-pipeline |
| (g) | no arg | scan work-items/, detect candidate, auto-dispatch to Branch(f) |

Per phase for design-doc mode (Branch c):

1. **Pre-flight** (orchestrator) — validate the design doc exists, is under `~/.gstack/projects/`, and has `Status: APPROVED`. Set up shared decision-log path.
2. **Phase 1 — /autoplan** (Skill, inline) — review the design doc via /autoplan's CEO + design + eng + DX review chain. /autoplan's native final-approval AUQ is **GATE #1**.
3. **Phase 2 — /CJ_personal-pipeline** (Agent subagent, `--suppress-final-gate`) — scaffold → impl → QA. 8.5 + 9.2 AUQs suppressed; decisions logged to wrapper-specified path.
4. **Phase 3 — /ship** (Skill, inline) — diff review, version bump confirm, PR creation. /ship's native diff-review AUQ is **GATE #2**.
5. **Phase 4 — /land-and-deploy** (Skill, inline, `--suppress-readiness-gate`) — merge PR, verify deploy. AUQ-free on green (Step 3.5a-bis stale-review offer + Step 3.5e readiness gate suppressed); alerts on red (CI, merge conflict, free-test regression at Step 3.5b, deploy failure, canary). Forward-compat: if gstack doesn't recognize the flag yet, it's silently ignored — legacy AUQs fire, no regression.
6. **Final summary + telemetry** — write to `~/.gstack/analytics/CJ_goal_run.jsonl` (with fallback-read of legacy `CJ_run.jsonl` during v4.x). Sunset checkpoint on invocation 6, then every 5.

For Branch(f) (work-item-dir input): reads TRACKER phase state and dispatches to
the right sub-pipeline (CJ_personal-pipeline `--work-item-dir`, /CJ_qa-work-item,
/ship + /land-and-deploy, or graceful exit if already shipped).

For Branch(g) (no arg): scans `work-items/` for in-progress user-story TRACKERs
on the current branch and dispatches into Branch(f) for the single candidate, or
AUQs to pick when multiple exist.

**2 wrapper-orchestrated AUQ gates** (/autoplan final + /ship diff review) plus 1 occasional wrapper-rendered checkpoint AUQ (sunset, fires on invocations 6, 11, 16, ...). Sub-skills may also surface their own native AUQs (autoplan premise gate, /ship pre-flight halts, /land-and-deploy deploy-failure / canary-red halts) — those pass through; wrapper does not pre-collect. /land-and-deploy's pre-merge readiness gate (Step 3.5a-bis + Step 3.5e) is **suppressed under /CJ_goal_run** via the `--suppress-readiness-gate` flag passed in Step 5; only red signals halt.

The orchestrator's own context grows by the sum of /autoplan + /ship + /land-and-deploy
when those skills are loaded inline (~5-10K tokens combined). CJ_personal-pipeline runs
as Agent subagent to keep its own context fresh and to leverage S000026's
suppress-final-gate path. See `run.md` for the full step-by-step logic.

Sunset criterion baked in: the skill writes one telemetry line per invocation
to `~/.gstack/analytics/CJ_goal_run.jsonl` (legacy `CJ_run.jsonl` is fallback-read during v4.x; writes go to the new path only) with `{run_id, design_doc, work_item,
pr_url, end_state, multi_story_scaffold_only, ts}` where `end_state ∈ {green,
halted_at_autoplan, halted_at_pipeline, halted_at_ship, halted_at_deploy,
deploy_red, subagent_crashed}`. On the 6th invocation, the orchestrator
AskUserQuestions for keep/delete based on a brittleness trip-wire (≥3 of 5
prior runs in `halted_at_(autoplan|pipeline|deploy)` or `subagent_crashed` →
recommend delete). Excluded from the count: `green` (happy path), `halted_at_ship`
(review caught a real issue — gate doing its job), `deploy_red` (production
state, not wrapper brittleness), and any line with `multi_story_scaffold_only: true`
(correct halt at scaffold gate per design).

For the full step-by-step logic, see [run.md](run.md).

## Usage

```
/CJ_goal_run <design-doc-path>      # Branches (a/b/c/d)
/CJ_goal_run <work-item-dir>        # Branch (f)
/CJ_goal_run                        # Branch (g)
```

Examples:

```
# Design-doc input: full pipeline from APPROVED design
/CJ_goal_run ~/.gstack/projects/jcl2018-knowledge-base/chjiang-claude-stupefied-ellis-2949b6-design-20260511-220642.md

# Work-item-dir input: resume from current phase
/CJ_goal_run work-items/features/ops/F000017_cj_run_entry_point/S000038_rename_and_branch_g

# No-arg: scan current branch and auto-resume the single in-progress user-story
/CJ_goal_run
```

For design-doc input: the path MUST be under `~/.gstack/projects/` and the design doc
MUST contain `Status: APPROVED` somewhere in its body. For work-item-dir input: the
directory must contain a `*_TRACKER.md` with `type: user-story`. For no-arg: scans
`work-items/` for user-story TRACKERs with Phase 1 complete + Phase 2 impl-gate
unchecked + no merged PR.

Sunset behavior is automatic on the 6th invocation. To force re-running through
the full pipeline on a re-scaffolded work-item, delete the design-doc's
`Status: SCAFFOLDED → ...` footer before re-invoking (this re-triggers
CJ_personal-pipeline's Phase 1 scaffold via its Branch (d) clean-slate path).

## Routing

Read [run.md](run.md) and follow its instructions. The full
orchestration logic lives there: input detection (design-doc / work-item-dir / no-arg),
phase detection for work-item-dir mode, /autoplan inline call, CJ_personal-pipeline
subagent dispatch with suppress-final-gate, multi-story shape detection, /ship inline call,
/land-and-deploy inline call, telemetry write, and the 6th-run sunset checkpoint.

## Error Handling

| Error | Message | Recovery |
|---|---|---|
| Not a git repo | "Error: /CJ_goal_run requires a git repository." | Run inside a repo |
| Skill assets not found | "Error: CJ_goal_run skill assets not found." | Run `skills-deploy install` |
| CJ_personal-pipeline missing | "Error: required upstream skill 'CJ_personal-pipeline' not found." | Run `skills-deploy install` |
| Design doc not found | "Error: design doc not found at {path}" | Verify path; run `/office-hours` first |
| Design doc outside ~/.gstack/projects/ | "Error: design doc must be under ~/.gstack/projects/ (got: {path})" | Move the doc, or invoke `/office-hours` |
| Design doc lacks `Status: APPROVED` | "Error: design doc lacks 'Status: APPROVED'. Run /office-hours, accept the final approval, then re-invoke." | Resume /office-hours; accept final approval |
| Work-item dir has no TRACKER | "Error: {path} is not a work-item directory (no TRACKER.md)" | Run `/CJ_scaffold-work-item` first |
| Work-item dir TRACKER type ≠ user-story | "Error: Branch(f) v0.2 supports user-story TRACKERs only" | Invoke sub-skills directly for defect/task types |
| No work-items/ found (Branch g) | "No work-items/ found. Run /office-hours or /CJ_scaffold-work-item first." | Scaffold a work-item first |
| No in-progress candidates (Branch g) | "Nothing to resume. Run /office-hours or /CJ_scaffold-work-item first." | Scaffold or implement an existing work-item |
| /autoplan aborted | "Wrapper halted at /autoplan final gate. end_state=halted_at_autoplan." | Re-invoke when ready; /autoplan re-runs |
| CJ_personal-pipeline halted | "Wrapper halted at CJ_personal-pipeline. Tracker at {path}. Pipeline decision log: {path}." | Inspect tracker; fix; re-invoke OR invoke /ship + /land-and-deploy manually if pipeline state is green-enough |
| Multi-story feature scaffold-only | "Multi-story feature scaffolded. Per-child invocation needed: ..." + per-child instructions | Invoke /CJ_goal_run on each child design doc |
| /ship aborted | "Wrapper halted at /ship review. Commits at {branch} not yet pushed as PR. Pipeline decision log: {path}." | Manually invoke /ship later; commits already exist |
| /land-and-deploy halted | "Wrapper halted at /land-and-deploy. {error}." | Fix root cause; manually invoke /land-and-deploy |
| Canary red post-deploy | "Canary red — see report at {path}. No auto-rollback." | Manual: rollback OR fix-forward |
| Subagent crash mid-pipeline | "CJ_personal-pipeline subagent crashed (no RESULT line). end_state=subagent_crashed." | Re-invoke; pipeline branch (a) skip path resumes from work-item dir on disk |

## Sunset Criterion

Mirrors `/CJ_personal-pipeline`'s pattern. On the 6th invocation (and every 5
thereafter), the orchestrator reads `~/.gstack/analytics/CJ_goal_run.jsonl`
(with fallback-read of legacy `CJ_run.jsonl` during v4.x)
and counts brittleness-signal `end_state` lines among the prior 5:

- **Counts toward trip-wire**: `halted_at_autoplan`, `halted_at_pipeline`,
  `halted_at_deploy`, `subagent_crashed` (orchestration health signals).
- **Excluded**: `green` (happy path), `halted_at_ship` (review caught real
  issue — gate doing its job), `deploy_red` (production state, not wrapper
  brittleness), lines with `multi_story_scaffold_only: true` (correct halt
  per design).

If the brittleness count is ≥3 of 5, the orchestrator AskUserQuestions for
keep/delete. The user keeps or deletes; no qualitative self-report leg.

To delete: remove `skills/CJ_goal_run/`, strike the catalog entry,
run `skills-deploy install`.
