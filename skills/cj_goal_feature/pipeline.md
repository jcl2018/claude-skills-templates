# /cj_goal_feature — Orchestration

Single-keystroke orchestrator from a plain `"<topic>"` → a reviewable PR. A
flat reshape of `/CJ_goal_run`: it DROPS the pre-build plan-review phase, DROPS
the `/land-and-deploy` tail, and DROPS the automatic merge; it ADDS
`/office-hours` inline (the one interactive phase) and a strengthened resume
state file. office-hours + `/ship` run inline at the top level; scaffold /
implement / qa run as depth-≤2 leaf Agent subagents. The pipeline STOPs at the
PR — the PR is the human architecture gate.

Read [SKILL.md](SKILL.md) first for path resolution, error handling, the
halt-taxonomy summary, the resume contract, and the idempotency contract. Then
follow the steps below.

---

## Step 1: Parse arguments + resolve the resume state file

Accept the following arg shapes:

```
/cj_goal_feature "<topic>"
/cj_goal_feature --dry-run "<topic>"
/cj_goal_feature --no-worktree "<topic>"
/cj_goal_feature                          # no-arg resume on the current branch
```

Parser:

```bash
DRY_RUN=""
NO_WORKTREE=""
ARGS=()
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    --no-worktree) NO_WORKTREE=1 ;;
    *) ARGS+=("$arg") ;;
  esac
done
TOPIC="${ARGS[0]:-}"
# A no-arg invocation is a resume on the current branch (Step 1.5 reads the
# resume state file). A positional arg is a fresh topic (or a verbatim resume).
[ "${#ARGS[@]}" -le 1 ] || { echo "Error: exactly one quoted topic expected (got: ${ARGS[*]})"; exit 1; }
RUN_ID=$(date +%Y%m%d-%H%M%S)-$$
```

Initialize telemetry + raw-output paths:

```bash
mkdir -p "$HOME/.gstack/analytics/CJ_goal_feature-runs/$RUN_ID"
TELEMETRY="$HOME/.gstack/analytics/CJ_goal_feature.jsonl"
RAW_DIR="$HOME/.gstack/analytics/CJ_goal_feature-runs/$RUN_ID"
```

**Resume state file.** State is keyed to the worktree branch (stable across
re-invocation on the same branch). Resolve it deterministically:

```bash
_REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
_BRANCH=$(git -C "$_REPO_ROOT" branch --show-current 2>/dev/null | tr '/' '-')
RESUME_DIR="$_REPO_ROOT/.cj-goal-feature"
RESUME_STATE="$RESUME_DIR/${_BRANCH}.state"
```

The state file is a small KEY=VALUE file (one field per line) carrying:

```
last_completed_phase=<none|office-hours|scaffold|impl|qa|ship>
phase_sha=<the HEAD SHA recorded at the last completed phase boundary>
design_doc=<absolute path to the APPROVED design doc, recorded at the office-hours boundary>
work_item_dir=<absolute path to the scaffolded work-item dir, recorded at the scaffold boundary>
pr_number=<the PR number, recorded at the ship boundary>
topic=<the original topic string>
```

A fresh run (no state file) starts at `last_completed_phase=none`. The file is
written via a `mktemp` + `mv` atomic-write helper at each phase boundary
(Step 2.5 / 4.x / 5.x). `.cj-goal-feature/` is workbench-local scratch — add it
to `.gitignore` if not already ignored; it is never committed.

If `--dry-run`: print the planned chain and exit before any mutation —

```bash
if [ "${DRY_RUN:-0}" = "1" ]; then
  echo "DRY RUN: topic=\"$TOPIC\""
  echo "DRY RUN: would create a cj-feat-* worktree (cj-goal-common.sh --mode feature)"
  echo "DRY RUN: would run /office-hours INLINE; on Approve, record the APPROVED design doc path + HEAD SHA to $RESUME_STATE"
  echo "DRY RUN: would dispatch /CJ_scaffold-work-item → /CJ_implement-from-spec → /CJ_qa-work-item as SILENT leaf Agent subagents (no AUQ)"
  echo "DRY RUN: would run /ship INLINE with the diff-review AUQ suppressed, opening a PR, then STOP at the PR (the merge stays manual; no deploy)"
  echo "DRY RUN: writes nothing. Re-run without --dry-run to execute; a verbatim re-run resumes from the recorded phase."
  echo "Suggested resume: /cj_goal_feature \"$TOPIC\""
  jq -nc --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" --arg run_id "$RUN_ID" \
    --arg end_state "dry_run_preview" --arg topic "$TOPIC" \
    '{ts:$ts,run_id:$run_id,end_state:$end_state,topic:$topic,parent_skill:"cj_goal_feature"}' \
    >> "$TELEMETRY" 2>/dev/null || true
  exit 0
fi
```

(The worktree phase already ran in SKILL.md's Default-worktree block before this
file is read; `--dry-run` was forwarded there too, so no worktree was created.)

## Step 1.5: Load + validate resume state (validate-before-skip)

Read the resume state file if it exists. The cardinal rule (P0 #4): **never
trust `last_completed_phase` blindly** — validate the recorded SHA and PR
against the live tree first, and restart the affected phase on any mismatch.

```bash
LAST_PHASE="none"; PHASE_SHA=""; DESIGN_DOC=""; WORK_ITEM_DIR=""; PR_NUMBER=""
if [ -f "$RESUME_STATE" ]; then
  LAST_PHASE=$(sed -n 's/^last_completed_phase=//p' "$RESUME_STATE" | head -1)
  PHASE_SHA=$(sed -n 's/^phase_sha=//p' "$RESUME_STATE" | head -1)
  DESIGN_DOC=$(sed -n 's/^design_doc=//p' "$RESUME_STATE" | head -1)
  WORK_ITEM_DIR=$(sed -n 's/^work_item_dir=//p' "$RESUME_STATE" | head -1)
  PR_NUMBER=$(sed -n 's/^pr_number=//p' "$RESUME_STATE" | head -1)
  [ -z "$LAST_PHASE" ] && LAST_PHASE="none"
fi

# Validation 1 — recorded SHA must be an ancestor of (or equal to) current HEAD.
# If the tree moved underneath the run (force-push / amend / manual edits) so
# the recorded SHA is unreachable, the recorded phase is untrustworthy: demote
# LAST_PHASE to the start of the affected phase so it RE-RUNS rather than skips.
if [ "$LAST_PHASE" != "none" ] && [ -n "$PHASE_SHA" ]; then
  if ! git -C "$_REPO_ROOT" merge-base --is-ancestor "$PHASE_SHA" HEAD 2>/dev/null; then
    TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    echo "- $TS [resume-sha-stale] recorded phase_sha=$PHASE_SHA is not an ancestor of HEAD; restarting phase after '$LAST_PHASE' (no skip on stale state)." >> "${WORK_ITEM_DIR:-$RESUME_DIR}/.resume.log" 2>/dev/null || true
    echo "[resume] recorded SHA stale (tree moved); restarting the '$LAST_PHASE' phase instead of skipping ahead."
    # Demote one phase back so the affected phase re-runs. office-hours is
    # special-cased in Validation 3 (recorded-path re-confirm), so only demote
    # the build phases here.
    case "$LAST_PHASE" in
      ship) LAST_PHASE="qa" ;;
      qa)   LAST_PHASE="impl" ;;
      impl) LAST_PHASE="scaffold" ;;
      scaffold) LAST_PHASE="office-hours" ;;
    esac
  fi
fi

# Validation 2 — any recorded PR must still resolve to OPEN. A MERGED/CLOSED PR
# is an idempotency exit (already_shipped); a vanished PR restarts the ship phase.
if [ "$LAST_PHASE" = "ship" ] && [ -n "$PR_NUMBER" ]; then
  _COMMON="$_REPO_ROOT/scripts/cj-goal-common.sh"
  _PR_OUT=$(bash "$_COMMON" --phase pr-check --mode feature 2>/dev/null)
  _PR_STATE=$(printf '%s\n' "$_PR_OUT" | sed -n 's/^PR_STATE=//p')
  case "$_PR_STATE" in
    MERGED|CLOSED)
      echo "Already shipped: PR #$PR_NUMBER is $_PR_STATE. Nothing to do (end_state=already_shipped)."
      jq -nc --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" --arg run_id "$RUN_ID" \
        --arg end_state "already_shipped" --arg pr "$PR_NUMBER" --arg topic "${TOPIC:-$DESIGN_DOC}" \
        '{ts:$ts,run_id:$run_id,end_state:$end_state,pr_url:$pr,topic:$topic,parent_skill:"cj_goal_feature"}' \
        >> "$TELEMETRY" 2>/dev/null || true
      exit 0
      ;;
    OPEN)
      echo "Resume: PR #$PR_NUMBER still OPEN; the run already reached the PR-stop (end_state=green_pr_opened)."
      # Fall through to Step 6 summary — the green end state already holds.
      ;;
    *)
      # PR_CHECK skipped (gh offline) OR PR vanished: restart the ship phase.
      echo "[resume] could not confirm PR #$PR_NUMBER OPEN (state='$_PR_STATE'); restarting the ship phase."
      LAST_PHASE="qa"
      ;;
  esac
fi
```

After Step 1.5, `LAST_PHASE` is the validated resume point. The phase dispatch
below skips only phases at or before a *validated* `LAST_PHASE`.

## Step 2: /office-hours (INLINE — the one interactive phase)

office-hours is the single human checkpoint up front. It runs INLINE at the
orchestrator (top) level — NOT as a subagent — because it is AUQ-heavy (six
forcing questions, a premise gate, a terminal Approve) and subagents have no
AskUserQuestion tool.

### Step 2 resume short-circuit (P0 #5 — recorded-path re-confirm)

If `LAST_PHASE` is past `none` AND a `design_doc` is recorded, re-locate the doc
by the **recorded path** (NOT a blind newest-glob) and re-confirm it still reads
`Status: APPROVED`. On success, office-hours is **not** re-run:

```bash
if [ "$LAST_PHASE" != "none" ] && [ -n "$DESIGN_DOC" ]; then
  if [ -f "$DESIGN_DOC" ] && grep -q '^Status: APPROVED' "$DESIGN_DOC"; then
    echo "[resume] office-hours already complete: $DESIGN_DOC is still APPROVED. Skipping office-hours."
    # Proceed to the build phases (Step 3+) with the recorded doc.
  else
    echo "[resume] recorded design doc missing or no longer APPROVED ($DESIGN_DOC); re-running office-hours."
    LAST_PHASE="none"   # force office-hours to re-run
  fi
fi
```

### Step 2 run (fresh, or office-hours restart)

If `LAST_PHASE = none`: invoke `/office-hours` via the **Skill** tool with the
topic. office-hours runs its full interactive flow and, on the terminal Approve,
writes an APPROVED design doc under `~/.gstack/projects/`.

After `/office-hours` returns, capture the design-doc path and confirm approval:

- The design doc lives under `~/.gstack/projects/` and contains
  `Status: APPROVED` in its body (the same contract `/CJ_goal_run` Branch (d)
  enforces). Capture the path office-hours reports into `$DESIGN_DOC`.
- If office-hours was declined / abandoned, or no doc with `Status: APPROVED`
  is produced, **HALT** with `[officehours-not-approved]`:

```bash
# HALT path — office-hours did not produce an APPROVED design doc.
TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)
mkdir -p "$RESUME_DIR"
cat >> "$RESUME_DIR/.resume.log" <<EOF
- $TS [officehours-not-approved] /office-hours did not emit an APPROVED design doc (declined / abandoned / Status != APPROVED).
  next_action=Resume /office-hours, accept the final Approve, then re-run /cj_goal_feature.
  resume_cmd=/cj_goal_feature "$TOPIC"
  pr_url=N/A
  raw_output_path=N/A
EOF
echo "Why it stopped: /office-hours did not reach an APPROVED design doc, so there is nothing to build yet."
echo "State preserved: no work-item scaffolded; resume state at $RESUME_STATE."
echo "Next: /office-hours \"$TOPIC\"  (accept the final Approve), then /cj_goal_feature \"$TOPIC\""
# Telemetry: end_state=halted_at_officehours (write per Step 6 schema before exit)
jq -nc --arg ts "$TS" --arg run_id "$RUN_ID" --arg end_state "halted_at_officehours" \
  --arg topic "$TOPIC" '{ts:$ts,run_id:$run_id,end_state:$end_state,topic:$topic,parent_skill:"cj_goal_feature"}' \
  >> "$TELEMETRY" 2>/dev/null || true
exit 1
```

## Step 2.5: Record the office-hours boundary

On a successful Approve (or a validated resume short-circuit), record the
office-hours phase boundary atomically:

```bash
mkdir -p "$RESUME_DIR"
HEAD_SHA=$(git -C "$_REPO_ROOT" rev-parse HEAD 2>/dev/null)
_TMP=$(mktemp "$RESUME_DIR/.state.XXXXXX")
cat > "$_TMP" <<EOF
last_completed_phase=office-hours
phase_sha=$HEAD_SHA
design_doc=$DESIGN_DOC
work_item_dir=$WORK_ITEM_DIR
pr_number=$PR_NUMBER
topic=$TOPIC
EOF
mv "$_TMP" "$RESUME_STATE"
echo "[resume] recorded office-hours boundary (doc=$DESIGN_DOC, sha=$HEAD_SHA)"
```

## Step 3: Silent build — scaffold → implement → qa (leaf Agent subagents)

The build runs with **zero AUQ** (P0 #2). Each phase is a depth-2 leaf Agent
subagent (it does NOT spawn further subagents — depth ≤ 2). The orchestrator
dispatches them in sequence, recording a phase boundary after each green return.

A phase is **skipped** only when the validated `LAST_PHASE` (Step 1.5) is at or
past that phase. Otherwise it runs.

### Step 3.1: scaffold (skip if validated LAST_PHASE ∈ {scaffold, impl, qa, ship})

Dispatch `/CJ_scaffold-work-item` via the **Agent** tool (`subagent_type:
general-purpose`) with the recorded design-doc path:

```
ROLE: /CJ_scaffold-work-item runner for /cj_goal_feature (silent — no AUQ).
TASK: Invoke /CJ_scaffold-work-item with the APPROVED design doc in <inputs>.
If it would ask for a slug/title/scope AUQ you cannot answer mechanically,
choose the mechanical default from the design doc and proceed (subagents have
no AUQ tool). Return the RESULT line verbatim: RESULT: WORK_ITEM_DIR=<path>.
<inputs>DESIGN_DOC: <absolute $DESIGN_DOC></inputs>
```

Parse `WORK_ITEM_DIR=<path>` from the subagent's RESULT line into
`$WORK_ITEM_DIR`. If the subagent crashed (no RESULT line) or returned a
non-green status, **HALT** with `[scaffold-red]` (end_state
`halted_at_scaffold`, `pr_url=N/A`, `raw_output_path=$RAW_DIR/scaffold-raw.txt`)
+ the 3-line terminal block + a telemetry line. resume_cmd is
`/cj_goal_feature "$TOPIC"`.

On green: record the scaffold boundary (same atomic-write as Step 2.5, with
`last_completed_phase=scaffold`, the new `work_item_dir=$WORK_ITEM_DIR`, and a
fresh `phase_sha`).

### Step 3.2: implement (skip if validated LAST_PHASE ∈ {impl, qa, ship})

Dispatch `/CJ_implement-from-spec` via the **Agent** tool against
`$WORK_ITEM_DIR` in **auto-equivalent** mode (subagents have no AUQ tool, so the
implement skill runs without AUQ attempts):

```
ROLE: /CJ_implement-from-spec runner for /cj_goal_feature (silent — no AUQ).
TASK: Invoke /CJ_implement-from-spec on the work-item dir in <inputs>, auto
mode. Return the RESULT line verbatim: RESULT: STATUS=<...>; FILES_CHANGED=<n>.
<inputs>WORK_ITEM_DIR: <absolute $WORK_ITEM_DIR></inputs>
```

If the implement subagent encounters a sensitive-surface AUQ it cannot answer
in subagent context, it halts and returns a non-green RESULT — the orchestrator
then HALTs with `[impl-red]` (this is the correct conservative behavior; the
operator re-runs after resolving). On crash / non-green: **HALT** with
`[impl-red]` (end_state `halted_at_impl`, `pr_url=N/A`,
`raw_output_path=$RAW_DIR/impl-raw.txt`) + the 3-line block + telemetry.

On green: record the impl boundary.

### Step 3.3: qa (skip if validated LAST_PHASE ∈ {qa, ship})

Dispatch `/CJ_qa-work-item` via the **Agent** tool against `$WORK_ITEM_DIR`:

```
ROLE: /CJ_qa-work-item runner for /cj_goal_feature (silent — no AUQ).
TASK: Invoke /CJ_qa-work-item on the work-item dir in <inputs>. Return the
RESULT line verbatim: RESULT: SMOKE=<...>; E2E=<...>; PHASE2_GATES=<...>.
<inputs>WORK_ITEM_DIR: <absolute $WORK_ITEM_DIR></inputs>
```

If QA returns red: **HALT** with `[qa-red]` (re-use the existing CJ_qa-work-item
halt marker — do NOT mint a new one), end_state `halted_at_qa`, `pr_url=N/A`,
`raw_output_path=$RAW_DIR/qa-raw.txt`, + the 3-line block + telemetry.

On green: record the qa boundary, then continue to Step 4.

## Step 4: /ship (INLINE — diff-review AUQ suppressed; opens a PR)

Invoke `/ship` via the **Skill** tool with the diff-review AUQ **suppressed**.
The opened PR is the human review (P0 #2: zero AUQ between the office-hours
Approve and the PR), so `/ship`'s mid-flight diff-review AUQ is relocated to the
PR on GitHub rather than fired inline. This is NOT a bypass of review.

> Invoke /ship with its pre-PR diff-review AUQ suppressed (the opened PR is the
> review). /ship runs its pre-landing review (greptile / codex / adversarial),
> bumps VERSION, updates CHANGELOG, commits, pushes, and creates a PR. It MUST
> stop after creating the PR — do NOT merge, do NOT run any deploy step.

`/ship` still surfaces its own native pre-flight halts (a genuinely red
pre-landing review, a dirty-tree refusal, a version-queue collision) — those
pass through and are real halts, not suppressed.

- If `/ship` declines (a red pre-landing review the operator must address) or
  cannot open a PR: **HALT** with `[ship-declined]` (end_state
  `halted_at_ship`; `pr_url=` set if a PR was created before the decline, else
  `N/A`) + the 3-line block + telemetry.
- On green (PR created): capture the PR number/URL into `$PR_NUMBER` /
  `$PR_URL`, record the ship boundary (`last_completed_phase=ship`,
  `pr_number=$PR_NUMBER`, fresh `phase_sha`), and continue to Step 5.

There is **no pre-build plan-review Step, no automatic merge, and no
`/land-and-deploy`** — the pipeline STOPs at the PR (P0 #3). The merge + deploy
are separate human steps the operator performs after reviewing the PR.

## Step 5: STOP at the PR

The pipeline is complete the moment `/ship` opens the PR. The end-state is
`green_pr_opened`. Do NOT advance to merge or deploy.

## Step 6: Final journal + telemetry + summary

If a work-item tracker exists (`$WORK_ITEM_DIR`), append a final journal entry:

```
- <ISO ts> [feature-pr-opened] $WORK_ITEM_ID v<X.Y.Z> PR #<NNN>
  pr_url=$PR_URL
```

Append one telemetry line to the per-verb stream
`~/.gstack/analytics/CJ_goal_feature.jsonl` (written inline so the documented
path is authoritative; the shared `cj-goal-common.sh` is consumed for the
worktree + pr-check phases, not for this canonical end-state line):

```bash
jq -nc \
  --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  --arg run_id "$RUN_ID" \
  --arg work_item_dir "$WORK_ITEM_DIR" \
  --arg design_doc "$DESIGN_DOC" \
  --arg end_state "green_pr_opened" \
  --arg pr_url "$PR_URL" \
  --arg topic "$TOPIC" \
  '{ts:$ts,run_id:$run_id,work_item_dir:$work_item_dir,design_doc:$design_doc,end_state:$end_state,pr_url:$pr_url,topic:$topic,parent_skill:"cj_goal_feature"}' \
  >> "$TELEMETRY"
```

Optionally also record a deterministic audit receipt via the shared helper
(best-effort; non-blocking — it writes to the `cj-goal-feature.jsonl` stream the
helper owns, distinct from the canonical `CJ_goal_feature.jsonl` above):

```bash
_COMMON="$_REPO_ROOT/scripts/cj-goal-common.sh"
[ -x "$_COMMON" ] && bash "$_COMMON" --phase telemetry --mode feature \
  --field run_id="$RUN_ID" --field end_state="green_pr_opened" \
  --field pr_url="$PR_URL" >/dev/null 2>&1 || true
```

Print the summary:

```
PIPELINE COMPLETE: end_state=green_pr_opened — STOPPED at the PR for human review.

Run ID:     $RUN_ID
Topic:      $TOPIC
Design doc: $DESIGN_DOC
Work item:  $WORK_ITEM_DIR
PR:         $PR_URL   (review + merge on GitHub)

Next (separate human steps):
  1. Review the PR on GitHub.
  2. Merge it (the merge is manual — there is no automatic merge on this path).
  3. /land-and-deploy   (deploy is a separate human step after merge)

Resume state: $RESUME_STATE
Telemetry:    $TELEMETRY
```

---

## Notes on end-state telemetry

Every exit path (success OR halt) writes a single telemetry line to
`~/.gstack/analytics/CJ_goal_feature.jsonl`. Success states: `green_pr_opened`,
`already_shipped`, `dry_run_preview`. Halt states (P1 #6):
`halted_at_no_arg`, `halted_at_officehours`, `halted_at_scaffold`,
`halted_at_impl`, `halted_at_qa`, `halted_at_ship`.

Add any new halt with: (a) a journal / `.resume.log` entry in the appropriate
Step, (b) a telemetry write before exit, (c) a row in SKILL.md's halt-taxonomy
table.

## Resilience contract

- **Idempotent.** A verbatim (or no-arg) re-run on the same branch resumes from
  the validated `last_completed_phase`. Partial states are recoverable.
- **Validate-before-skip (P0 #4).** The recorded per-phase SHA must be an
  ancestor of (or equal to) current HEAD, and any recorded PR must still resolve
  to OPEN, before a phase is skipped. A stale SHA restarts the affected phase; a
  MERGED/CLOSED PR is an `already_shipped` exit; a vanished PR restarts ship.
  The pipeline never skips into a later phase on stale state.
- **office-hours never re-runs on an unchanged APPROVED doc (P0 #5).** Resume
  re-locates the doc by the recorded path and re-confirms `Status: APPROVED`;
  recovery is a recorded-path lookup, not a blind newest-glob.
- **No AUQ between the office-hours Approve and the PR (P0 #2).** office-hours is
  the one interactive phase; the silent build emits no AUQ; `/ship` runs with
  its diff-review AUQ suppressed (the PR is the review).
- **No automatic rollback.** Halts write entries with `next_action=`,
  `resume_cmd=`, and `pr_url=` — the operator drives recovery.
- **Halt-on-red end-to-end.** Any red status from office-hours, scaffold,
  implement, qa, or `/ship` stops the chain.
- **PR-stop (P0 #3).** No plan-review phase, no automatic merge, no
  `/land-and-deploy`. The PR is the human architecture gate.
- **Depth ≤ 2.** scaffold / implement / qa are leaf subagents; office-hours +
  `/ship` run inline. No subagent-spawns-subagent path.
