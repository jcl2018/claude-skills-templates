---
name: CJ_goal_feature
description: "One-line-topic-to-reviewable-PR feature orchestrator (F000027 `feature` verb; experimental). Takes a plain feature topic, creates a `cj-feat-*` worktree, runs /office-hours INLINE (the one interactive design phase; emits an APPROVED design doc — on not-APPROVED/abandoned it HALTs), then shows a design-summary approval gate in chat (a concise digest of the APPROVED doc + a single go/no-go before the autonomous build budget is spent — Abort HALTs as halted_at_design_gate and preserves the doc for resume), then SILENTLY (zero AUQ past the gate) dispatches /CJ_scaffold-work-item → /CJ_implement-from-spec → /CJ_qa-work-item as depth-≤2 leaf Agent subagents, folds doc updates via /CJ_document-release INLINE (Step 5.5 doc-sync), and runs /ship INLINE with the diff-review AUQ suppressed to open a PR — then STOPs at the PR. The PR is the architecture gate (human review). No plan-review phase, no automatic merge, no /land-and-deploy (deploy is a separate human step). Strengthened resume: a state file records `last_completed_phase` + per-phase HEAD SHA + PR number and validates-before-skipping (recorded SHA must be ancestor-of/equal-to current HEAD AND any open PR must still be OPEN, else the affected phase restarts); office-hours resume re-locates the doc by the RECORDED PATH and re-confirms `Status: APPROVED` rather than a blind newest-glob; the design-summary gate re-fires on resume while still parked at the office-hours boundary and is skipped once the build has progressed. Consumes scripts/cj-goal-common.sh --mode feature for the deterministic worktree + pr-check phases; telemetry appends one JSONL line to ~/.gstack/analytics/CJ_goal_feature.jsonl. Halt taxonomy (green_pr_opened, halted_at_officehours/design_gate/scaffold/impl/qa/ship, already_shipped) with next_action= / resume_cmd= / pr_url= journal entries. --dry-run previews the chain plan without mutation. Workbench-only (macOS). An automatic merge-and-deploy path is unsafe-by-construction here (the handoff-gate denylist blocks exactly the skill surfaces every feature touches) and is parked, not deferred. Use when: 'build this feature end-to-end from a topic', 'one-line idea to a reviewable PR', 'scaffold + implement + qa from a topic and stop at the PR'."
version: 0.2.0
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
_S=$(jq -r '.source // empty' "$HOME/.claude/.skills-templates.json" 2>/dev/null)
[ -n "$_S" ] && [ -x "$_S/scripts/skills-update-check" ] && "$_S/scripts/skills-update-check" 2>/dev/null || true
```

Verify this is a git repository:

```bash
git rev-parse --show-toplevel 2>/dev/null || echo "NOT_A_GIT_REPO"
```

If `NOT_A_GIT_REPO`: print `Error: /CJ_goal_feature requires a git repository.` and stop.

## Pre-build skills-sync (F000045 / Fork 2 — BEFORE the Default-worktree block)

Before the worktree is created, sync installed skills to trunk so the build runs
against current skills (not a stale `~/.claude/`). Delegated to the shared
`scripts/cj-goal-common.sh --phase sync --mode feature`, which reuses
`post-land-sync.sh`'s guarded pull+install-from-`.source` core. **Fail-soft —
never halts the orchestrator:** a guard refusal (`.source` off-main / dirty) or
an offline pull emits `PHASE_RESULT=skipped` and the build proceeds on the
current install. `--no-sync` opts out of the heavy install (Fork-1's ff in the
worktree phase still runs); `--dry-run` forwards as a preview.

```bash
# Pre-build skills-sync (F000045) — runs BEFORE the Default-worktree block.
_S=$(jq -r '.source // empty' "$HOME/.claude/.skills-templates.json" 2>/dev/null)
_SHARED="${CJ_SHARED_SCRIPTS:-$HOME/.claude/_cj-shared/scripts}"
_COMMON=""
_REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo "")
# 3-tier shared-script resolution (F000049/S000085): repo-local (workbench
# self-dev) → deployed _cj-shared home → manifest .source (legacy fallback).
if [ -n "$_REPO_ROOT" ] && [ -x "$_REPO_ROOT/scripts/cj-goal-common.sh" ]; then
  _COMMON="$_REPO_ROOT/scripts/cj-goal-common.sh"
elif [ -x "$_SHARED/cj-goal-common.sh" ]; then
  _COMMON="$_SHARED/cj-goal-common.sh"
elif [ -n "$_S" ] && [ -x "$_S/scripts/cj-goal-common.sh" ]; then
  _COMMON="$_S/scripts/cj-goal-common.sh"
fi
if [ -n "$_COMMON" ]; then
  _SYNC_FLAGS=()
  for _ARG in "$@"; do
    case "$_ARG" in
      --no-sync) _SYNC_FLAGS+=(--no-sync) ;;
      --dry-run) _SYNC_FLAGS+=(--dry-run) ;;
    esac
  done
  # Fail-soft: the phase exits 0 on skip; we never halt on its result.
  _SYNC_OUT=$(bash "$_COMMON" --phase sync --mode feature "${_SYNC_FLAGS[@]}" 2>/dev/null || true)
  _SYNC_RESULT=$(printf '%s\n' "$_SYNC_OUT" | sed -n 's/^PHASE_RESULT=//p')
  _SYNC_VB=$(printf '%s\n' "$_SYNC_OUT" | sed -n 's/^VERSION_BEFORE=//p')
  _SYNC_VA=$(printf '%s\n' "$_SYNC_OUT" | sed -n 's/^VERSION_AFTER=//p')
  if [ "$_SYNC_RESULT" = "ok" ]; then
    echo "[sync] skills synced from .source (collection_version ${_SYNC_VB:-?} → ${_SYNC_VA:-?})"
  else
    echo "[sync] skipped (--no-sync / guard refusal / offline) — proceeding on current install"
  fi
fi
```

## Default-worktree (BEFORE Path Resolution — variables get re-resolved post-cd)

Per F000027 (reshape of F000025/S000054): when invoked with a positional
`<topic>`, auto-create a `cj-feat-{YYYYMMDD-HHMMSS}-{PID}/` worktree and `cd`
into it. The worktree phase is delegated to the shared
`scripts/cj-goal-common.sh --phase worktree --mode feature` helper (S000057),
which in turn shells out to the vetted `cj-worktree-init.sh --caller feature`
(branch prefix `cj-feat`). Conductor-managed sessions (already inside a
worktree) detect + no-op. `--no-worktree` opts out; `--dry-run` forwards
through the helper and creates nothing.

The positional-arg guard means a flag-only invocation (e.g. a bare `--dry-run`
with no topic) skips the helper and errors on the missing argument as usual —
no empty worktree is spun up. Mirrors the `/CJ_goal_defect` wiring exactly; the
only difference is `--mode feature` (branch prefix `cj-feat`).

**This phase is MANDATORY — not a judgment call.** Do NOT reason about whether a
worktree is "worth it," and do NOT substitute a feature branch on the primary
checkout. The worktree IS the mitigation for concurrent-session tree collisions
(it is not a risk to weigh against), and QA runs the test suite *inside* the
worktree ([pipeline.md](pipeline.md) Step 3.3) — so there is no test-isolation
reason to stay on the primary checkout. The only operator opt-out is the
explicit `--no-worktree` flag (on a clean checkout). [pipeline.md](pipeline.md)
Step 1.9 re-verifies the clean+isolated invariant via `cj-worktree-init.sh
--assert-isolated` and HALTs (`[feature-not-isolated]`) if it does not hold — so
a skipped worktree phase fails loudly instead of silently building on the
primary checkout (the D000024 in-place-source-write bug class).

```bash
# Default-worktree (BEFORE path resolution — variables get re-resolved post-cd)
# Detect a positional topic arg: at least one non-flag arg present.
_HAS_POSITIONAL=0
for _ARG in "$@"; do
  case "$_ARG" in
    --*|-*) ;;
    *) _HAS_POSITIONAL=1; break ;;
  esac
done

if [ "$_HAS_POSITIONAL" = "1" ]; then  # only when a topic is present
  _S=$(jq -r '.source // empty' "$HOME/.claude/.skills-templates.json" 2>/dev/null)
  _SHARED="${CJ_SHARED_SCRIPTS:-$HOME/.claude/_cj-shared/scripts}"
  _COMMON=""
  _REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo "")
  # 3-tier shared-script resolution (F000049/S000085): repo-local (workbench
  # self-dev) → deployed _cj-shared home → manifest .source (legacy fallback).
  if [ -n "$_REPO_ROOT" ] && [ -x "$_REPO_ROOT/scripts/cj-goal-common.sh" ]; then
    _COMMON="$_REPO_ROOT/scripts/cj-goal-common.sh"
  elif [ -x "$_SHARED/cj-goal-common.sh" ]; then
    _COMMON="$_SHARED/cj-goal-common.sh"
  elif [ -n "$_S" ] && [ -x "$_S/scripts/cj-goal-common.sh" ]; then
    _COMMON="$_S/scripts/cj-goal-common.sh"
  fi

  if [ -n "$_COMMON" ]; then
    # Forward --no-worktree / --dry-run when present so the helper honors them.
    _WT_FLAGS=()
    for _ARG in "$@"; do
      case "$_ARG" in
        --no-worktree) _WT_FLAGS+=(--no-worktree) ;;
        --dry-run)     _WT_FLAGS+=(--dry-run) ;;
      esac
    done
    _WT_OUT=$(bash "$_COMMON" --phase worktree --mode feature "${_WT_FLAGS[@]}" 2>/dev/null)
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
    # Visible warning (NOT silent no-op) — per F000025 Decision Audit Trail #11.
    echo "[worktree] WARN: cj-goal-common.sh unreachable; running on current branch"
  fi
fi
```

## Path Resolution

Resolve skill assets using a 2-level fallback chain:

```bash
_REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
_SKILL_DIR=""

if [ -n "$_REPO_ROOT" ] && [ -f "$_REPO_ROOT/skills/CJ_goal_feature/pipeline.md" ]; then
  _SKILL_DIR="$_REPO_ROOT/skills/CJ_goal_feature"
fi
if [ -z "$_SKILL_DIR" ] && [ -f "$HOME/.claude/skills/CJ_goal_feature/pipeline.md" ]; then
  _SKILL_DIR="$HOME/.claude/skills/CJ_goal_feature"
fi

if [ -z "$_SKILL_DIR" ]; then
  echo "ERROR: CJ_goal_feature skill assets not found."
  echo "Run: ./scripts/skills-deploy install"
  echo "NOT_FOUND"
else
  echo "SKILL_DIR: $_SKILL_DIR"
fi
```

If `NOT_FOUND`: surface the error and stop.

## Overview

`/CJ_goal_feature "<topic>"` is the one-keystroke path from a plain feature
topic to a **reviewable PR**. It is the `feature` verb of the F000027 two-verb
refactor — a flat orchestrator that runs the one interactive design phase up
front, then silently builds and STOPs at a PR for human review. The chain:

```
"<topic>"
   │  cj-goal-common.sh --phase worktree --mode feature   (S000057 → cj-worktree-init.sh --caller feature, prefix cj-feat)
   ▼
/office-hours   [INLINE — interactive; emits an APPROVED design doc]
   │   ↳ not APPROVED / abandoned → HALT (halted_at_officehours; next_action=resume /office-hours)
   ▼
capture doc path → resume state file: last_completed_phase + HEAD SHA + PR#
   │
   ▼
design-summary approval gate   [INLINE AUQ — digest of the APPROVED doc + go/no-go]
   │   ↳ Abort → HALT (halted_at_design_gate; doc preserved; re-run re-shows the gate)
   ▼  Approve & build →  SILENT, NO AUQ — depth-≤2 leaf Agent subagents
/CJ_scaffold-work-item  →  /CJ_implement-from-spec  →  /CJ_qa-work-item
   │
   ▼
/CJ_document-release   [INLINE Step 5.5 — doc-sync folds doc edits into the PR; halt-on-red]
   │
   ▼
/ship   [INLINE — diff-review AUQ suppressed; opens a PR]
   │
   ▼
Step 4.6 — registered-doc verdicts → PR body   [post-/ship gh pr edit; best-effort; T000038]
   │
   ▼
STOP at PR   (human reviews + merges on GitHub; /land-and-deploy is a SEPARATE human step)
   │
   ▼
worktree cleanup   [best-effort — cj-goal-common.sh --phase cleanup --mode feature]
   │   sweeps OTHER landed cj-* worktrees + refreshes root main; this run's own
   │   worktree is never swept (current dir + OPEN PR). NEVER halts the run.
   ▼
telemetry append → ~/.gstack/analytics/CJ_goal_feature.jsonl
```

Worktree cleanup is best-effort, post-PR, and **never halts the run** — a failed
sweep logs a note and the run still ends `green_pr_opened` ([pipeline.md](pipeline.md)
Step 6.5; the post-run teardown mirror of the Step 1 worktree-create phase).

**Why office-hours runs inline (not as a subagent).** office-hours is the
primary interactive phase — six forcing questions, a premise gate, a terminal
Approve. Subagents have no AskUserQuestion tool, so office-hours MUST run at the
orchestrator (top) level. The same is true of the Step 2.7 design-summary
approval gate, which also runs inline at the top level (the operator is still at
the keyboard from office-hours). The leaf build skills (scaffold/impl/qa) emit
no AUQ in subagent context, so they dispatch as silent depth-2 leaf subagents.

**Why a design-summary gate after office-hours.** office-hours' terminal Approve
approves the *design doc content*; the orchestrator then used to proceed
silently ("doc is done") into the autonomous build. Step 2.7 replaces that
silent hand-off with a chat digest of the APPROVED doc + a single go/no-go — the
operator's explicit green-light to spend the build budget (scaffold → implement
→ qa → `/ship`) without re-reading the full doc. It is the only AUQ between the
office-hours Approve and the PR; past it the build is silent.

**Why PR-stop, no plan-review phase, no automatic merge.** Auto-deploy of
skill-work is unsafe-by-construction here: `scripts/cj-handoff-gate.sh`'s
denylist blocks `skills-catalog.json`, `tests/`, `validate.sh`, `test.sh`, and
skill dirs on purpose — exactly the surfaces every feature touches. So the
automatically-mergeable subset is "features that change nothing important."
PR-stop is correct, not a v1 shortcut (D3 REVISED at GATE #1). With auto-deploy
gone, the human PR review IS the architecture gate, so a pre-build plan-review
(the CEO/design/eng review chain `/CJ_goal_run` runs) is redundant and dropped
(Open Question 2 RESOLVED). `/land-and-deploy` is a separate human step the
operator runs after reviewing + merging the PR.

**Why a reshape, not a wrapper.** Wrapping `/CJ_goal_run` would re-inherit the
nested-subagent wall (an orchestrator subagent cannot spawn its own subagent).
This skill is flat: it dispatches scaffold/impl/qa as depth-≤2 leaf subagents
and runs office-hours + `/ship` inline. It DROPS `/CJ_goal_run`'s pre-build
plan-review phase, DROPS the `/land-and-deploy` tail, and DROPS the automatic
merge; it ADDS office-hours-inline (the interactive front door) and the
strengthened resume.
The deterministic worktree + pr-check phases come from `cj-goal-common.sh`
(S000057); the Skill-tool invocations stay inline (Approach A, F000027_DESIGN
Big Decision #4), mirroring `/CJ_goal_defect`.

## Usage

```
/CJ_goal_feature "<topic>"               # worktree → office-hours → silent build → /ship PR → STOP
/CJ_goal_feature --dry-run "<topic>"     # preview the chain plan + write paths; no writes, no subagents, no Skill calls
/CJ_goal_feature --no-worktree "<topic>" # run in place on a clean checkout (opt out of the auto cj-feat-* worktree)
```

A re-invocation with the SAME topic (or with no positional arg, on the same
branch) RESUMES from the recorded resume state — see Resume below.

**Flags:**
- `--dry-run` — preview only; print the planned worktree, the office-hours
  inline phase, the would-create resume-state path, the silent
  scaffold→impl→qa dispatch plan, and the `/ship` PR-stop. NO files written,
  NO subagent dispatched, NO Skill invocations. Output includes a copy-paste
  suggested resume command (drop the `--dry-run`).
- `--no-worktree` — operator opt-out: run in place on a clean checkout instead
  of auto-creating a `cj-feat-*` worktree. Forwarded to the worktree phase.
- `--no-sync` — skip the pre-build skills-sync (F000045 / Fork 2). The
  `Pre-build skills-sync` preamble's heavy `skills-deploy install` from `.source`
  is skipped (`PHASE_RESULT=skipped`) for a faster start; Fork-1's local-main
  fast-forward in the worktree phase still runs (so the build base stays fresh).
  The sync phase is always fail-soft regardless — `--no-sync` only suppresses the
  install attempt.

**Out of scope** (parked / deferred per SPEC Tradeoffs + the parent F000027
design):
- **Automatic merge + deploy** — parked, unsafe-by-construction (the
  handoff-gate denylist blocks exactly the skill surfaces every feature
  touches). No feature-specific gate profile, no automatic-merge or deploy path
  in v1. Re-opened only by the author at approval (Open Question 1).
- **`/CJ_goal_auto`'s no-office-hours fast path** — office-hours always runs
  inline as the interactive design phase (followed by the Step 2.7 gate).
- **A machine-readable design-doc pointer from office-hours** — deferred
  follow-up; v1 recovers the doc by the recorded path + `Status: APPROVED`
  re-confirm.
- **Multi-story design docs** — v1 expects a single-story APPROVED doc (the
  silent build dispatches one scaffold→impl→qa chain).

## Routing

Read [pipeline.md](pipeline.md) and follow the step-by-step orchestration. The
pipeline file owns: arg parsing, the office-hours inline phase + its halt, the
resume state file (`last_completed_phase` + per-phase HEAD SHA + PR number)
with validate-before-skip, the Step 2.7 design-summary approval gate (digest of
the APPROVED doc + go/no-go, with its `[design-gate-declined]` halt and
skip-on-resume), the silent scaffold/impl/qa leaf-subagent dispatch, the inline
`/ship` with the diff-review AUQ suppressed, the PR-stop, the halt taxonomy, and
telemetry.

## Error Handling

| Error | Message | Recovery |
|-------|---------|----------|
| Not a git repo | "Error: /CJ_goal_feature requires a git repository." | Run inside a repo |
| Skill assets not found | "Error: CJ_goal_feature skill assets not found." | Run `skills-deploy install` |
| No argument | "Error: a feature topic is required." | Pass a quoted topic |
| Worktree phase failed | `[worktree] ERROR: ...` | Inspect `cj-goal-common.sh` output; pass `--no-worktree` on a clean checkout |
| Checkout not clean+isolated | `[feature-not-isolated]` (Step 1.9 gate) | Run from a clean `main` checkout (auto-worktree), a clean feature branch / worktree, or pass `--no-worktree` on a clean tree |
| office-hours not APPROVED / abandoned | `[officehours-not-approved]` (Step 3 halt) | Resume `/office-hours`, accept the final Approve, then re-run `/CJ_goal_feature` |
| Design-summary gate declined | `[design-gate-declined]` (Step 2.7 halt) | Re-run `/CJ_goal_feature` to re-show the summary + gate; edit the doc / re-run `/office-hours` first if the design needs changes |
| Resume SHA stale (not ancestor of HEAD) | `[resume-sha-stale]` (restarts the affected phase, not a hard halt) | None — the affected phase re-runs automatically |
| Resume PR no longer OPEN | `[resume-pr-not-open]` (restarts the ship phase or reports already-shipped) | If MERGED/CLOSED → `already_shipped`; else the ship phase re-runs |
| scaffold subagent crash / red | `[scaffold-red]` | Inspect subagent output; fix; re-run (resumes from scaffold) |
| implement subagent crash / red | `[impl-red]` | Inspect subagent output; fix; re-run (resumes from implement) |
| /CJ_qa-work-item red | `[qa-red]` (re-use the existing CJ_qa-work-item marker) | Inspect QA output; fix; re-run |
| /ship declined / pre-landing review red | `[ship-declined]` | Address feedback; re-run when ready (the PR is the review — the merge stays manual) |

## Halt-on-Red Taxonomy (P1 #6)

All halts write a structured journal entry to the active tracker (the resume
state file pre-scaffold, or the canonical `*_TRACKER.md` once a work-item
exists) with the family contract fields:

- `[<halt-id>]` — bracket-tagged marker for grep
- `next_action=<one-line description>` — what the operator should do
- `resume_cmd=<copy-paste shell command>` — how to resume after fixing
- `pr_url=<url or N/A>` — set when a PR exists (post-/ship)
- `raw_output_path=<path or N/A>` — pointer to raw subagent output where applicable

| End-state | Halt marker | When |
|-----------|-------------|------|
| `green_pr_opened` | (no journal — success; summary printed) | office-hours APPROVED, silent build green, `/ship` opened a PR; pipeline STOPPED at the PR |
| `halted_at_no_arg` | (no journal — usage halt; output on stderr) | No topic passed |
| `halted_at_not_isolated` | `[feature-not-isolated]` | Step 1.9 isolation gate: checkout not clean+isolated (verdict `dirty`/`not_isolated`/`not_a_repo`) OR the worktree helper is unreachable after both probes. Pre-build halt; the source-writing scaffold/implement subagents are provably NOT dispatched. |
| `halted_at_officehours` | `[officehours-not-approved]` | office-hours did not emit an APPROVED design doc (declined / abandoned / `Status` != APPROVED) |
| `halted_at_design_gate` | `[design-gate-declined]` | Step 2.7 design-summary approval gate: operator chose Abort. The APPROVED doc + office-hours boundary are preserved; the silent build never started. Re-run re-shows the gate. |
| `halted_at_scaffold` | `[scaffold-red]` | scaffold leaf subagent crashed or returned a non-green RESULT |
| `halted_at_impl` | `[impl-red]` | implement leaf subagent crashed or returned a non-green RESULT |
| `halted_at_qa` | `[qa-red]` | /CJ_qa-work-item red |
| `halted_at_doc_sync` | `[doc-sync-red]` | Step 5.5 doc-sync: /CJ_document-release returned non-green (upstream /document-release failed, base-branch refusal, or pre-run non-doc dirty tree) |
| `halted_at_doc_sync_no_config` | `[doc-sync-no-config]` | Step 5.5 doc-sync: cj-document-release.json missing/invalid/schema_version-unsupported (F000037 strict-required) |
| `halted_at_doc_sync_non_doc_write` | `[doc-sync-non-doc-write]` | Step 5.5 doc-sync: /CJ_document-release refused to auto-commit because upstream wrote files outside the doc-only whitelist (upstream-misbehaved) |
| `halted_at_ship` | `[ship-declined]` | /ship declined (the merge stays manual — the PR review is the gate) or pre-landing review red |
| `already_shipped` | (no journal — idempotency exit; summary printed) | Resume found a MERGED/CLOSED PR for this work; nothing to do |

Success end-states: `green_pr_opened`, `already_shipped`, `dry_run_preview`.

There is deliberately **no** deploy-phase or plan-review-phase end-state —
`feature` PR-stops, so neither phase exists on the path.

## Resume (P0 #4 / #5) — validate-before-skip

`/CJ_goal_feature` records a resume state file per run (path resolved in
pipeline.md Step 1). It tracks:

- `last_completed_phase` ∈ {`none`, `office-hours`, `scaffold`, `impl`, `qa`, `ship`}
- a per-phase HEAD SHA recorded at each phase boundary
- the design-doc path (recorded at the office-hours boundary)
- the PR number (recorded at the ship boundary)

On re-invocation, the orchestrator **validates before skipping** rather than
trusting the flag:

1. The recorded per-phase HEAD SHA must be an **ancestor of (or equal to)**
   current HEAD (`git merge-base --is-ancestor <sha> HEAD`). If the tree moved
   underneath the run (force-push, amend, manual edits) so the recorded SHA is
   no longer reachable, the affected phase **restarts** (`[resume-sha-stale]`)
   — the pipeline never skips into a later phase on stale state.
2. Any recorded PR must still resolve to **OPEN** (via `cj-goal-common.sh
   --phase pr-check`). A MERGED/CLOSED PR ⇒ `already_shipped` (idempotency
   exit); a vanished PR ⇒ the ship phase restarts (`[resume-pr-not-open]`).
3. **office-hours resume (P0 #5)** re-locates the design doc by the **recorded
   path** (NOT a blind newest-glob) and re-confirms `Status: APPROVED` in the
   doc body. If the recorded doc still reads APPROVED, office-hours is **not**
   re-run — the build proceeds from scaffold. If the recorded path is missing
   or no longer APPROVED, office-hours restarts.
4. **Design-summary gate re-fire (Step 2.7).** While the validated resume point
   is still `office-hours` (the doc was approved but the build never started —
   e.g. a prior Abort at the gate), the design-summary gate **re-fires** on
   resume. Once the build has progressed (`last_completed_phase ∈ {scaffold,
   impl, qa, ship}`), the gate is skipped — the operator already green-lit it.

## Idempotency

- **Verbatim re-run / no-arg re-run on the same branch** resumes from the
  recorded `last_completed_phase`, gated by the validate-before-skip checks
  above. A green-and-shipped run re-resolves the PR; if it is still OPEN the
  run reports `green_pr_opened` (the PR already exists), if MERGED/CLOSED it
  reports `already_shipped`.
- **Halts** write `next_action=` / `resume_cmd=` and preserve state (resume
  file + any scaffolded work-item); re-running resumes from the first
  incomplete phase.
- The recorded SHA / PR validation means a stale resume file can never cause a
  skip into a later phase — the worst case is a redundant phase re-run, which
  the leaf skills are themselves idempotent against.

## Notes

- **One AUQ between the office-hours Approve and the PR: the design-summary
  gate.** office-hours itself is interactive (the design checkpoint up front);
  Step 2.7 then shows a digest of the APPROVED doc + a single go/no-go before
  the build budget is spent. Past that gate the silent build emits no AUQ
  (subagents have no AUQ tool), and `/ship` runs with its diff-review AUQ
  suppressed — the PR itself is the review. The three human touchpoints are the
  office-hours Approve, the Step 2.7 design-summary gate, and the PR.
- **`/ship` diff-review AUQ is suppressed** on this path because the opened PR
  is the human review. This is NOT a bypass of review — it relocates the review
  from a mid-flight AUQ to the PR on GitHub.
- **No plan-review phase, no automatic merge, no `/land-and-deploy`.** The
  pipeline STOPS at the PR. Deploy is a separate human step (`/land-and-deploy`)
  the operator runs after merging.
- **Telemetry path** is `~/.gstack/analytics/CJ_goal_feature.jsonl` (one JSONL
  line per run), matching the family convention (`CJ_goal_defect.jsonl`,
  `CJ_goal_auto.jsonl`, `CJ_goal_run.jsonl`). The shared `cj-goal-common.sh` is
  consumed for the deterministic worktree + pr-check phases; the canonical
  end-state telemetry line is written inline by the final step so the
  documented per-verb stream is authoritative.
- **Depth ≤ 2.** Orchestrator → leaf subagent (`/CJ_scaffold-work-item`,
  `/CJ_implement-from-spec`, `/CJ_qa-work-item`). No subagent-spawns-subagent
  path; `/office-hours` + `/ship` run inline at the top level.
