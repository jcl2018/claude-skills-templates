---
name: CJ_goal_task
description: "Small-ad-hoc-task-to-reviewable-PR orchestrator (F000054 `task` verb; experimental). The lightweight sibling of /CJ_goal_feature: takes a plain free-text `\"<small task>\"` (refine a doc, add a file, clean up some files, a one-line fix), runs a HARD complexity gate (refuses design-rework topics → routes to /CJ_goal_feature, refuses bug/investigation topics → routes to /CJ_goal_defect, refuses explicit-large-scope topics; HALTs as halted_at_too_complex), creates a `cj-task-*` worktree, then SILENTLY (one checkpoint AUQ — the QA audit findings) bash-scaffolds a `type: task` work-item (T-ID) directly from the topic via scripts/cj-task-scaffold.sh — NO /office-hours, NO design doc, NO pre-existing TODOS row — and dispatches /CJ_implement-from-spec → /CJ_qa-work-item (with DEFER_AUDIT: true — the three-stage audit is deferred to the post-sync point) as depth-≤2 leaf Agent subagents, makes an idempotent pre-doc-sync commit, folds doc updates via /CJ_document-release INLINE (Step 5.5 doc-sync), runs ONE combined read-only post-sync doc/test audit (Step 5.6), surfaces the post-QA audit checkpoint AUQ on that POST-sync report (ALWAYS; Continue past findings journals [qa-audit-waived], Halt journals [qa-audit-declined] / halted_at_qa_audit), runs a pre-ship portability gate (cj-goal-common.sh --phase portability-audit; halts [portability-red]), and runs /ship INLINE with the diff-review AUQ suppressed to open a PR — then STOPs at the PR. PR-stop only (like /CJ_goal_feature): no automatic merge, no /land-and-deploy; the PR is the review. Strengthened resume: a state file records `last_completed_phase` + per-phase HEAD SHA + work-item dir + PR number and validates-before-skipping (recorded SHA must be ancestor-of/equal-to current HEAD AND any open PR must still be OPEN, else the affected phase restarts); QA always re-runs on resume. Consumes scripts/cj-goal-common.sh --mode task for the deterministic worktree / sync / portability / pr-check / cleanup phases; telemetry appends one JSONL line to ~/.gstack/analytics/CJ_goal_task.jsonl. Halt taxonomy (green_pr_opened, halted_at_too_complex/not_isolated/scaffold/impl/qa/doc_sync/qa_audit/portability/ship, already_shipped) with next_action= / resume_cmd= / pr_url= journal entries. --dry-run previews the chain plan without mutation. Workbench-only (macOS). Use when: 'do this small task end-to-end', 'refine a doc / add a file / clean up files to a PR', 'fix this small thing and stop at the PR', 'a small ad-hoc cleanup that does not need design or investigation'."
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

Check for collection updates (silent if none, banner if newer):

```bash
_UC="${CJ_SHARED_SCRIPTS:-$HOME/.claude/_cj-shared/scripts}/skills-update-check"
[ -x "$_UC" ] && "$_UC" 2>/dev/null || true
```

Verify this is a git repository:

```bash
git rev-parse --show-toplevel 2>/dev/null || echo "NOT_A_GIT_REPO"
```

If `NOT_A_GIT_REPO`: print `Error: /CJ_goal_task requires a git repository.` and stop.

## Pre-build skills-sync (F000045 / Fork 2 — BEFORE the Default-worktree block)

Identical to the `/CJ_goal_feature` Fork 2 wiring, with `--mode task`. Before the
worktree is created, sync installed skills to trunk so the build runs against
current skills. Delegated to the shared `cj-goal-common.sh --phase sync --mode
task`. **Fail-soft — never halts the orchestrator:** a guard refusal or an
offline pull emits `PHASE_RESULT=skipped` and the build proceeds on the current
install. `--no-sync` opts out of the heavy install; `--dry-run` forwards as a
preview.

```bash
# Pre-build skills-sync (F000045) — runs BEFORE the Default-worktree block.
_SHARED="${CJ_SHARED_SCRIPTS:-$HOME/.claude/_cj-shared/scripts}"
_COMMON=""
_REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo "")
# 2-tier shared-script resolution: repo-local (workbench self-dev) → deployed
# _cj-shared home (install==clone; F000049/S000088).
if [ -n "$_REPO_ROOT" ] && [ -x "$_REPO_ROOT/scripts/cj-goal-common.sh" ]; then
  _COMMON="$_REPO_ROOT/scripts/cj-goal-common.sh"
elif [ -x "$_SHARED/cj-goal-common.sh" ]; then
  _COMMON="$_SHARED/cj-goal-common.sh"
fi
if [ -n "$_COMMON" ]; then
  _SYNC_FLAGS=()
  for _ARG in "$@"; do
    case "$_ARG" in
      --no-sync) _SYNC_FLAGS+=(--no-sync) ;;
      --dry-run) _SYNC_FLAGS+=(--dry-run) ;;
    esac
  done
  _SYNC_OUT=$(bash "$_COMMON" --phase sync --mode task "${_SYNC_FLAGS[@]}" 2>/dev/null || true)
  _SYNC_RESULT=$(printf '%s\n' "$_SYNC_OUT" | sed -n 's/^PHASE_RESULT=//p')
  _SYNC_VB=$(printf '%s\n' "$_SYNC_OUT" | sed -n 's/^VERSION_BEFORE=//p')
  _SYNC_VA=$(printf '%s\n' "$_SYNC_OUT" | sed -n 's/^VERSION_AFTER=//p')
  if [ "$_SYNC_RESULT" = "ok" ]; then
    echo "[sync] skills synced from the in-place checkout (collection_version ${_SYNC_VB:-?} → ${_SYNC_VA:-?})"
  else
    echo "[sync] skipped (--no-sync / guard refusal / offline) — proceeding on current install"
  fi
fi
```

## Default-worktree (BEFORE Path Resolution — variables get re-resolved post-cd)

Mirrors the `/CJ_goal_feature` wiring exactly; the only difference is `--mode
task` (branch prefix `cj-task`). When invoked with a positional `<topic>`,
auto-create a `cj-task-{YYYYMMDD-HHMMSS}-{PID}/` worktree and `cd` into it.
Conductor-managed sessions (already inside a worktree) detect + no-op.
`--no-worktree` opts out; `--dry-run` creates nothing.

**This phase is MANDATORY — not a judgment call.** The worktree IS the mitigation
for concurrent-session tree collisions and the D000024 in-place-source-write bug
class. The only operator opt-out is the explicit `--no-worktree` flag (on a clean
checkout). [pipeline.md](pipeline.md) Step 1.9 re-verifies the clean+isolated
invariant via `cj-worktree-init.sh --assert-isolated` and HALTs
(`[task-not-isolated]`) if it does not hold.

```bash
# Default-worktree (BEFORE path resolution — variables get re-resolved post-cd)
_HAS_POSITIONAL=0
for _ARG in "$@"; do
  case "$_ARG" in
    --*|-*) ;;
    *) _HAS_POSITIONAL=1; break ;;
  esac
done

if [ "$_HAS_POSITIONAL" = "1" ]; then  # only when a topic is present
  _SHARED="${CJ_SHARED_SCRIPTS:-$HOME/.claude/_cj-shared/scripts}"
  _COMMON=""
  _REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo "")
  if [ -n "$_REPO_ROOT" ] && [ -x "$_REPO_ROOT/scripts/cj-goal-common.sh" ]; then
    _COMMON="$_REPO_ROOT/scripts/cj-goal-common.sh"
  elif [ -x "$_SHARED/cj-goal-common.sh" ]; then
    _COMMON="$_SHARED/cj-goal-common.sh"
  fi

  if [ -n "$_COMMON" ]; then
    _WT_FLAGS=()
    for _ARG in "$@"; do
      case "$_ARG" in
        --no-worktree) _WT_FLAGS+=(--no-worktree) ;;
        --dry-run)     _WT_FLAGS+=(--dry-run) ;;
      esac
    done
    _WT_OUT=$(bash "$_COMMON" --phase worktree --mode task "${_WT_FLAGS[@]}" 2>/dev/null)
    _WT_STATE=$(printf '%s\n' "$_WT_OUT" | sed -n 's/^WT_STATE=//p')
    _WT_PATH=$(printf '%s\n' "$_WT_OUT" | sed -n 's/^WT_PATH=//p')
    _WT_RESULT=$(printf '%s\n' "$_WT_OUT" | sed -n 's/^PHASE_RESULT=//p')
    if [ "$_WT_STATE" = "created" ] || [ "$_WT_STATE" = "detected" ]; then
      [ -n "$_WT_PATH" ] && { cd "$_WT_PATH" || { echo "[worktree] ERROR: cd $_WT_PATH failed"; exit 1; }; }
      echo "[worktree] $_WT_STATE: $_WT_PATH"
    elif [ "$_WT_RESULT" = "failed" ]; then
      echo "[worktree] ERROR: cj-goal-common.sh worktree phase failed (state=$_WT_STATE)"
      exit 1
    fi
    # On skipped / opted_out / unavailable-but-soft: no cd, no halt; continue.
  else
    echo "[worktree] WARN: cj-goal-common.sh unreachable; running on current branch"
  fi
fi
```

## Path Resolution

Resolve skill assets using a 2-level fallback chain:

```bash
_REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
_SKILL_DIR=""

if [ -n "$_REPO_ROOT" ] && [ -f "$_REPO_ROOT/skills/CJ_goal_task/pipeline.md" ]; then
  _SKILL_DIR="$_REPO_ROOT/skills/CJ_goal_task"
fi
if [ -z "$_SKILL_DIR" ] && [ -f "$HOME/.claude/skills/CJ_goal_task/pipeline.md" ]; then
  _SKILL_DIR="$HOME/.claude/skills/CJ_goal_task"
fi

if [ -z "$_SKILL_DIR" ]; then
  echo "ERROR: CJ_goal_task skill assets not found."
  echo "Run: ./scripts/skills-deploy install"
  echo "NOT_FOUND"
else
  echo "SKILL_DIR: $_SKILL_DIR"
fi
```

If `NOT_FOUND`: surface the error and stop.

## Overview

`/CJ_goal_task "<small task>"` is the one-keystroke path from a small, well-scoped
**ad-hoc** task to a **reviewable PR** — without the design ceremony of
`/CJ_goal_feature` or the investigation of `/CJ_goal_defect`. It is the `task`
verb of the cj_goal family: a flat orchestrator with **no interactive phase at
all** (the eligibility check is the automatic complexity gate, not an AUQ), that
silently builds and STOPs at a PR for human review. The chain:

```
"<small task>"
   │  cj-goal-common.sh --phase sync --mode task   (pre-build skills-sync; fail-soft → skipped)
   ▼
cj-goal-common.sh --phase worktree --mode task   (auto cj-task-* worktree; base-freshness ff)
   │
   ▼
isolation gate   (cj-worktree-init.sh --caller task --assert-isolated)
   │   ↳ not clean+isolated → HALT (halted_at_not_isolated)
   ▼
HARD complexity gate + scaffold   [INLINE — scripts/cj-task-scaffold.sh --topic "<task>"]
   │   ↳ design-rework signal  → HALT (halted_at_too_complex; suggest /CJ_goal_feature)
   │   ↳ bug/investigation     → HALT (halted_at_too_complex; suggest /CJ_goal_defect)
   │   ↳ explicit-large-scope  → HALT (halted_at_too_complex; suggest /CJ_goal_feature)
   │   on PASS → scaffold a `type: task` work-item (T-ID) from the topic
   ▼  record scaffold boundary → resume state file (last_completed_phase + HEAD SHA + work-item dir)
   ▼  SILENT depth-≤2 leaf Agent subagents (one checkpoint AUQ below)
/CJ_implement-from-spec  →  /CJ_qa-work-item [DEFER_AUDIT: true — audit deferred to post-sync]
   │
   ▼
pre-doc-sync commit   [INLINE Step 4.4 — NEW; idempotent: commit QA-green code + 8.6a/8.6b overlays, skip on clean tree]
   │
   ▼
/CJ_document-release   [INLINE Step 5.5 — doc-sync folds doc edits into the PR; halt-on-red]
   │
   ▼
post-sync audit   [INLINE Step 5.6 — NEW; ONE combined READ-ONLY subagent: /CJ_doc_audit + /CJ_test_audit over the post-sync tree]
   │
   ▼
QA-audit checkpoint   [INLINE Step 4.5 — AUQ ALWAYS; consumes the POST-sync AUDIT_FINDINGS digest; Continue / Halt]
   │   ↳ Halt → HALT (halted_at_qa_audit; [qa-audit-declined]); Continue past findings journals [qa-audit-waived]
   ▼
portability gate   [INLINE Step 5.7 — cj-goal-common.sh --phase portability-audit; halt-on-red BEFORE /ship]
   │   ↳ findings → HALT (halted_at_portability; no PR)
   ▼
/ship   [INLINE — diff-review AUQ suppressed; opens a PR]
   │
   ▼
Step 6.6 — registered-doc + portability verdicts → PR body   [post-/ship gh pr edit; best-effort]
   │
   ▼
STOP at PR   (human reviews + merges on GitHub; /land-and-deploy is a SEPARATE human step)
   │
   ▼
worktree cleanup   [best-effort — cj-goal-common.sh --phase cleanup --mode task]
   ▼
telemetry append → ~/.gstack/analytics/CJ_goal_task.jsonl
```

**Why no interactive phase.** `/CJ_goal_feature` runs `/office-hours` + a
design-summary gate because a feature needs design. `/CJ_goal_task` is for tasks
small enough to skip design *by definition* — so the design phase is replaced by
an automatic **hard complexity gate** that REFUSES anything that needs design or
investigation (routing it to the right verb) and otherwise proceeds silently.
There is zero AskUserQuestion on the happy path; the PR is the human review.

**Why PR-stop, no automatic merge.** Auto-deploy of skill-work is
unsafe-by-construction in this workbench (`scripts/cj-handoff-gate.sh`'s denylist
blocks `skills-catalog.json`, `tests/`, `validate.sh`, `test.sh`, and skill dirs
on purpose). PR-stop is correct, identical to `/CJ_goal_feature`. The
sensitive-surface backstop holds too: a task that touches a sensitive surface
makes the silent `/CJ_implement-from-spec` subagent halt (its sensitive-surface
AskUserQuestion auto-defaults conservatively in subagent context), surfacing as
`[impl-red]` rather than a silent in-place mutation.

**Why a fresh flat orchestrator (not a `/CJ_goal_todo_fix` mode).** `cj_goal_task`
is essentially `todo_fix` minus the TODOS-row gate, plus a free-text topic. But
wrapping `todo_fix` would re-inherit the nested-subagent wall (an orchestrator
subagent cannot spawn its own subagent). This skill is flat: it bash-scaffolds
via `scripts/cj-task-scaffold.sh` (a topic-driven sibling of `todo_fix.sh`'s
scaffold path) and dispatches implement/qa as depth-≤2 leaf subagents, running
`/ship` inline. The deterministic worktree / sync / portability / pr-check /
cleanup phases come from `cj-goal-common.sh --mode task` (shared with the family).

## Usage

```
/CJ_goal_task "<small task>"               # complexity gate → worktree → silent build → /ship PR → STOP
/CJ_goal_task --dry-run "<small task>"     # preview the chain plan + write paths; no writes, no subagents
/CJ_goal_task --no-worktree "<small task>" # run in place on a clean checkout (opt out of the cj-task-* worktree)
/CJ_goal_task --no-sync "<small task>"     # skip the pre-build skills-sync for a faster start
```

A re-invocation with the SAME topic (or no positional arg, on the same branch)
RESUMES from the recorded resume state — see Resume below.

**Flags:**
- `--dry-run` — preview only; print the planned worktree, the complexity-gate
  verdict + would-scaffold T-ID/dir, the silent implement→qa dispatch plan, and
  the `/ship` PR-stop. NO files written, NO subagent dispatched, NO Skill calls.
- `--no-worktree` — run in place on a clean checkout instead of auto-creating a
  `cj-task-*` worktree.
- `--no-sync` — skip the pre-build skills-sync (Fork-1's local-main fast-forward
  in the worktree phase still runs).

**Out of scope** (route elsewhere — the complexity gate enforces this):
- **Anything that needs design** — use `/CJ_goal_feature` (it runs `/office-hours`).
- **Anything that needs root-cause investigation** — use `/CJ_goal_defect`.
- **Large / multi-skill / epic work** — use `/CJ_goal_feature`.
- **Automatic merge + deploy** — parked, unsafe-by-construction (PR-stop only).

## Routing

Read [pipeline.md](pipeline.md) and follow the step-by-step orchestration. The
pipeline file owns: arg parsing, the resume state file
(`last_completed_phase` + per-phase HEAD SHA + work-item dir + PR number) with
validate-before-skip, the isolation gate, the hard complexity gate + bash
scaffold (`scripts/cj-task-scaffold.sh`), the silent implement/qa leaf-subagent
dispatch, the inline doc-sync + portability gate, the inline `/ship` with the
diff-review AUQ suppressed, the PR-stop, the halt taxonomy, and telemetry.

## Error Handling

| Error | Message | Recovery |
|-------|---------|----------|
| Not a git repo | "Error: /CJ_goal_task requires a git repository." | Run inside a repo |
| Skill assets not found | "Error: CJ_goal_task skill assets not found." | Run `skills-deploy install` |
| No argument | "Error: a task description is required." | Pass a quoted task |
| Worktree phase failed | `[worktree] ERROR: ...` | Inspect `cj-goal-common.sh` output; pass `--no-worktree` on a clean checkout |
| Checkout not clean+isolated | `[task-not-isolated]` (Step 1.9 gate) | Run from a clean `main` checkout (auto-worktree), a clean feature branch / worktree, or pass `--no-worktree` on a clean tree |
| Topic too complex for a task | `[task-too-complex]` (Step 2 gate) | Use the suggested verb (`/CJ_goal_feature` for design, `/CJ_goal_defect` for bugs) |
| Resume SHA stale (not ancestor of HEAD) | `[resume-sha-stale]` (restarts the affected phase) | None — the affected phase re-runs automatically |
| Resume PR no longer OPEN | `[resume-pr-not-open]` (restarts ship or reports already-shipped) | MERGED/CLOSED → `already_shipped`; else the ship phase re-runs |
| scaffold error | `[scaffold-red]` | Inspect `cj-task-scaffold.sh` output; fix; re-run |
| implement subagent crash / red | `[impl-red]` | Inspect subagent output; fix; re-run (resumes from implement) |
| /CJ_qa-work-item red | `[qa-red]` | Inspect QA output; fix; re-run |
| Doc-sync red | `[doc-sync-red]` / `[doc-sync-no-config]` / `[doc-sync-non-doc-write]` | Inspect `/CJ_document-release` output; fix; re-run |
| Portability gate findings | `[portability-red]` (Step 5.7; halt before /ship) | Relabel the skill's `portability` (or `portability_requires`) in skills-catalog.json; re-run |
| /ship declined / pre-landing review red | `[ship-declined]` | Address feedback; re-run when ready (the PR is the review — the merge stays manual) |

## Halt-on-Red Taxonomy

Canonical gate sequence: `spec/test-spec.md` (the cross-cj_goal verification contract;
enforced by `validate.sh` Check 24). The halts below are this mode's subset of
that declared sequence — the registry is the source of truth for the ordering.

All halts write a structured journal entry (the resume state dir pre-scaffold, or
the canonical `*_TRACKER.md` once a work-item exists) with the family contract
fields: `[<halt-id>]`, `next_action=`, `resume_cmd=`, `pr_url=`, `raw_output_path=`.

| End-state | Halt marker | When |
|-----------|-------------|------|
| `green_pr_opened` | (no journal — success) | complexity gate passed, silent build green, `/ship` opened a PR; STOPPED at the PR |
| `halted_at_no_arg` | (no journal — usage halt) | No task passed |
| `halted_at_not_isolated` | `[task-not-isolated]` | Step 1.9 isolation gate: checkout not clean+isolated OR the worktree helper is unreachable. Pre-build halt; the source-writing subagents are provably NOT dispatched. |
| `halted_at_too_complex` | `[task-too-complex]` | Step 2 complexity gate: the topic names a design-rework / bug-investigation / explicit-large-scope signal. No work-item scaffolded; the halt names the verb to use instead. |
| `halted_at_scaffold` | `[scaffold-red]` | `cj-task-scaffold.sh` could not scaffold (template missing / write error) |
| `halted_at_impl` | `[impl-red]` | implement leaf subagent crashed or returned a non-green RESULT |
| `halted_at_qa` | `[qa-red]` | /CJ_qa-work-item red |
| `halted_at_qa_audit` | `[qa-audit-declined]` | Step 4.5 QA-audit checkpoint: operator chose Halt on the POST-sync AUDIT_FINDINGS digest (the Step 5.6 doc/test audit run AFTER doc-sync; the spec-overlay updates rode the QA RESULT). Continue past findings journals `[qa-audit-waived]`. Fires ALWAYS after QA green → pre-doc-sync commit → doc-sync → the post-sync audit — the one AUQ in the chain, and now decides on the docs that will ship. |
| `halted_at_doc_sync` | `[doc-sync-red]` | Step 5.5 doc-sync: /CJ_document-release returned non-green |
| `halted_at_doc_sync_no_config` | `[doc-sync-no-config]` | Step 5.5 doc-sync: doc-spec.md registry missing/invalid |
| `halted_at_doc_sync_non_doc_write` | `[doc-sync-non-doc-write]` | Step 5.5 doc-sync: upstream wrote files outside the doc-only whitelist |
| `halted_at_portability` | `[portability-red]` | Step 5.7 portability gate: `--phase portability-audit` returned findings; halt BEFORE `/ship`, so no PR |
| `halted_at_ship` | `[ship-declined]` | /ship declined (merge stays manual) or pre-landing review red |
| `already_shipped` | (no journal — idempotency exit) | Resume found a MERGED/CLOSED PR for this work |

Success end-states: `green_pr_opened`, `already_shipped`, `dry_run_preview`.

There is deliberately **no** deploy-phase end-state — `task` PR-stops.

## Resume — validate-before-skip

`/CJ_goal_task` records a resume state file per run (path resolved in
pipeline.md Step 1, keyed to the worktree branch). It tracks:

- `last_completed_phase` ∈ {`none`, `scaffold`, `impl`, `qa`, `ship`}
- a per-phase HEAD SHA recorded at each phase boundary
- the scaffolded work-item dir (recorded at the scaffold boundary)
- the PR number (recorded at the ship boundary)
- the original topic string

On re-invocation, the orchestrator **validates before skipping**:

1. The recorded per-phase HEAD SHA must be an **ancestor of (or equal to)**
   current HEAD. If the tree moved underneath the run, the affected phase
   **restarts** (`[resume-sha-stale]`).
2. Any recorded PR must still resolve to **OPEN**. MERGED/CLOSED ⇒
   `already_shipped`; vanished ⇒ the ship phase restarts (`[resume-pr-not-open]`).
3. The `qa` phase is **never** skipped on resume — it always re-dispatches so a
   same-SHA resume re-verifies (the `qa.md` receipt keeps that cheap).

## Idempotency

- **Verbatim re-run / no-arg re-run on the same branch** resumes from the
  recorded `last_completed_phase`, gated by the validate-before-skip checks.
- **Re-scaffold is a no-op:** `cj-task-scaffold.sh` keys on a `<!-- Source:
  /CJ_goal_task: <topic> -->` footer, so a re-run with the same topic reuses the
  existing work-item dir instead of minting a second T-ID.
- **Halts** write `next_action=` / `resume_cmd=` and preserve state; re-running
  resumes from the first incomplete phase.

## Notes

- **Zero AUQ on the happy path.** Unlike `/CJ_goal_feature` (office-hours +
  design gate) this verb has no interactive phase: the complexity gate is
  automatic, the build is silent, and `/ship` runs with its diff-review AUQ
  suppressed — the PR is the review. The single human touchpoint is the PR.
- **Telemetry path** is `~/.gstack/analytics/CJ_goal_task.jsonl` (one JSONL line
  per run), matching the family convention.
- **Depth ≤ 2.** Orchestrator → leaf subagent (`/CJ_implement-from-spec`,
  `/CJ_qa-work-item`). No subagent-spawns-subagent path; the scaffold is bash and
  `/ship` runs inline at the top level.

## Permission policy

This orchestrator's permissions are declared in one artifact: `permission-policy.md`
(parsed by `scripts/permission-policy.sh`). The two live enforcement points are
governed by it — the `allowed-tools` frontmatter above is the **allow** surface,
and the sensitive-surface AskUserQuestion (catalog / manifest / validator / skill
/ template / git-hook edits) is the **ask** surface. The riskiest operations
(direct push to `main`, autonomous `gh pr merge`, `rm`, network egress) are
**deny**; an unenumerated verb resolves to `deny` (fail closed). The dormant
`cj-handoff-gate.sh` denylist derives from the policy's `ask` globs, and
`scripts/validate.sh` Check 21 flags policy↔enforcement drift (advisory).
