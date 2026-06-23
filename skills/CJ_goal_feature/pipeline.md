# /CJ_goal_feature — Orchestration

Single-keystroke orchestrator from a plain `"<topic>"` → a reviewable PR. A
flat reshape of `/CJ_goal_run`: it DROPS the pre-build plan-review phase, DROPS
the `/land-and-deploy` tail, and DROPS the automatic merge; it ADDS
`/office-hours` inline (the interactive design phase) + a Step 2.7
design-summary approval gate, and a strengthened resume state file. office-hours + `/ship` run inline at the top level; scaffold /
implement / qa run as depth-≤2 leaf Agent subagents. The pipeline STOPs at the
PR — the PR is the human architecture gate.

Read [SKILL.md](SKILL.md) first for path resolution, error handling, the
halt-taxonomy summary, the resume contract, and the idempotency contract. Then
follow the steps below.

Canonical gate sequence: `spec/test-spec.md` (the cross-cj_goal verification contract;
enforced by `validate.sh` Check 24). The gates this pipeline halts at are this
mode's subset of that one declared sequence.

---

## Step 1: Parse arguments + resolve the resume state file

Accept the following arg shapes:

```
/CJ_goal_feature "<topic>"
/CJ_goal_feature --dry-run "<topic>"
/CJ_goal_feature --no-worktree "<topic>"
/CJ_goal_feature                          # no-arg resume on the current branch
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
# Persist the operator --no-worktree opt-out RUN_ID-scoped, in THIS block —
# the only place NO_WORKTREE (set by the parser loop above) and RUN_ID (just
# generated) are both live. Shell vars do NOT persist across bash tool calls
# (CLAUDE.md), so Step 1.9's isolation gate cannot read $NO_WORKTREE; it
# re-reads this marker via the model-carried RUN_ID (same persistence pattern
# as TELEMETRY / RAW_DIR). Mirrors /CJ_goal_defect Step 1 exactly.
if [ "${NO_WORKTREE:-}" = "1" ]; then
  mkdir -p "$HOME/.gstack/analytics/CJ_goal_feature-runs/$RUN_ID"
  : > "$HOME/.gstack/analytics/CJ_goal_feature-runs/$RUN_ID/.operator-no-worktree"
fi
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
office_hours_receipt=<absolute path to the compact office-hours phase receipt, recorded at the office-hours boundary — F000053/S000095>
work_item_dir=<absolute path to the scaffolded work-item dir, recorded at the scaffold boundary>
pr_number=<the PR number, recorded at the ship boundary>
topic=<the original topic string>
```

A fresh run (no state file) starts at `last_completed_phase=none`. The file is
written via a `mktemp` + `mv` atomic-write helper at each phase boundary
(Step 2.5 / 4.x / 5.x). `.cj-goal-feature/` is workbench-local scratch — add it
to `.gitignore` if not already ignored; it is never committed.

**Within-phase receipt chain (F000053 / S000095 — P1 context curation).** The
`${branch}.state` file above is the resume-state surface; alongside it, the
office-hours boundary writes ONE compact *phase receipt* into the same
`.cj-goal-feature/` chain — `${branch}.office-hours.receipt` — carrying the
distilled design digest. The state file's `office_hours_receipt=` key is a
single-line pointer to it (so the resume-state surface stays one flat file — no
second state surface — while the multi-line digest lives in its own receipt). The
post-office-hours step (Step 2.7) sources its design-summary digest FROM that
receipt rather than re-reading the full design doc or depending on the resident
office-hours transcript. The receipt reuses S000093's locked receipt-envelope
schema (`phase` / `commit` / `completed_at`) — one schema, not two. Scope is the
office-hours boundary ONLY; there is no generic per-phase compaction hook.

If `--dry-run`: print the planned chain and exit before any mutation —

```bash
if [ "${DRY_RUN:-0}" = "1" ]; then
  echo "DRY RUN: topic=\"$TOPIC\""
  echo "DRY RUN: would create a cj-feat-* worktree (cj-goal-common.sh --mode feature)"
  echo "DRY RUN: would run /office-hours INLINE; on Approve, record the APPROVED design doc path + HEAD SHA to $RESUME_STATE"
  echo "DRY RUN: would write a compact office-hours phase receipt to .cj-goal-feature/<branch>.office-hours.receipt and source the Step 2.7 design-summary digest FROM it (F000053/S000095)"
  echo "DRY RUN: would dispatch /CJ_scaffold-work-item → /CJ_implement-from-spec → /CJ_qa-work-item (with DEFER_AUDIT: true — audit deferred to post-sync) as SILENT leaf Agent subagents (no AUQ)"
  echo "DRY RUN: would make an idempotent pre-doc-sync commit (Step 3.5; skip on a clean tree), then run /CJ_document-release INLINE (Step 5.5 doc-sync; halt-on-red), then ONE combined read-only post-sync audit subagent (Step 5.6: /CJ_doc_audit + /CJ_test_audit), then the QA-audit checkpoint (Step 3.4) on that POST-sync report"
  echo "DRY RUN: would run the portability-audit gate (halt-on-red) before /ship (cj-goal-common.sh --phase portability-audit)"
  echo "DRY RUN: would run /ship INLINE with the diff-review AUQ suppressed, opening a PR, then STOP at the PR (the merge stays manual; no deploy)"
  echo "DRY RUN: writes nothing. Re-run without --dry-run to execute; a verbatim re-run resumes from the recorded phase."
  echo "Suggested resume: /CJ_goal_feature \"$TOPIC\""
  jq -nc --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" --arg run_id "$RUN_ID" \
    --arg end_state "dry_run_preview" --arg topic "$TOPIC" \
    '{ts:$ts,run_id:$run_id,end_state:$end_state,topic:$topic,parent_skill:"CJ_goal_feature"}' \
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
LAST_PHASE="none"; PHASE_SHA=""; DESIGN_DOC=""; OH_RECEIPT=""; WORK_ITEM_DIR=""; PR_NUMBER=""
if [ -f "$RESUME_STATE" ]; then
  LAST_PHASE=$(sed -n 's/^last_completed_phase=//p' "$RESUME_STATE" | head -1)
  PHASE_SHA=$(sed -n 's/^phase_sha=//p' "$RESUME_STATE" | head -1)
  DESIGN_DOC=$(sed -n 's/^design_doc=//p' "$RESUME_STATE" | head -1)
  OH_RECEIPT=$(sed -n 's/^office_hours_receipt=//p' "$RESUME_STATE" | head -1)
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
        '{ts:$ts,run_id:$run_id,end_state:$end_state,pr_url:$pr,topic:$topic,parent_skill:"CJ_goal_feature"}' \
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

## Step 1.9: Isolation gate (the worktree phase is MANDATORY — enforced before any source write)

The silent build (Step 3) dispatches `/CJ_scaffold-work-item` +
`/CJ_implement-from-spec` as subagents that **write to repo source** (a new
work-item dir and code). Dispatching them from an un-isolated or dirty checkout
means an in-place mutation of unrelated work — the D000024 bug class. The
SKILL.md "Default-worktree" block is supposed to have already created (or
detected) a `cj-feat-*` worktree; this gate **verifies** that invariant held and
**refuses to proceed** otherwise.

This is **not a judgment call.** There is no "feature branch on the primary
checkout" shortcut — either the checkout is clean+isolated (a `cj-feat-*`
worktree, a clean feature branch, or `--no-worktree` on a clean tree) or the run
HALTs here. The gate is placed before office-hours (not just before the build)
so an un-isolated run fails fast instead of after the interactive phase. It
mirrors the proven `/CJ_goal_defect` Step 5.0 gate.

Run this bash block before office-hours. **Shell vars do NOT persist across bash
tool calls** (only cwd does — see CLAUDE.md), so `$RUN_ID` / `$TELEMETRY` /
`$TOPIC` are the same model-carried values from Step 1, and the helper path is
re-resolved here. The gate calls the helper with `--assert-isolated` (a
read-only verdict mode `cj-goal-common.sh` does not wrap):

```bash
# Re-resolve cj-worktree-init.sh: (1) repo-local first (workbench self-dev),
# then (2) the deployed _cj-shared home (install==clone; F000049/S000088).
_SHARED="${CJ_SHARED_SCRIPTS:-$HOME/.claude/_cj-shared/scripts}"
_REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo "")
_HELPER=""
if [ -n "$_REPO_ROOT" ] && [ -x "$_REPO_ROOT/scripts/cj-worktree-init.sh" ]; then
  _HELPER="$_REPO_ROOT/scripts/cj-worktree-init.sh"
elif [ -x "$_SHARED/cj-worktree-init.sh" ]; then
  _HELPER="$_SHARED/cj-worktree-init.sh"
fi

RESUME_DIR="$_REPO_ROOT/.cj-goal-feature"
mkdir -p "$RESUME_DIR" 2>/dev/null || true

if [ -z "$_HELPER" ]; then
  # Helper unreachable after BOTH probes. Immediately before a source-writing
  # subagent dispatch, unreachable means HALT, not silent in-place. This is
  # exactly the D000024 class the gate exists to close.
  TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  cat >> "$RESUME_DIR/.resume.log" <<EOF
- $TS [feature-not-isolated] worktree helper unreachable (repo-local + deployed _cj-shared both absent); cannot verify clean+isolated before the source-writing build. HALT (no silent in-place write).
  next_action=Restore scripts/cj-worktree-init.sh (repo-local) or re-run 'skills-deploy install' to refresh the deployed _cj-shared home; then re-run.
  resume_cmd=/CJ_goal_feature "$TOPIC"
  pr_url=N/A
  raw_output_path=N/A
EOF
  echo "Why it stopped: the worktree-isolation helper is unreachable, so a clean+isolated checkout can't be verified before the build writes to source."
  echo "State preserved: no work-item scaffolded; resume state under $RESUME_DIR."
  echo "Next: /CJ_goal_feature \"$TOPIC\""
  jq -nc --arg ts "$TS" --arg run_id "$RUN_ID" --arg end_state "halted_at_not_isolated" \
    --arg topic "$TOPIC" '{ts:$ts,run_id:$run_id,end_state:$end_state,topic:$topic,parent_skill:"CJ_goal_feature"}' \
    >> "$TELEMETRY" 2>/dev/null || true
  exit 1
fi

# Forward ONLY --no-worktree, and only if the operator passed it (re-read the
# RUN_ID-scoped marker — $NO_WORKTREE does not persist across bash tool calls).
# NEVER forward --dry-run (already exited at Step 1).
if [ -f "$HOME/.gstack/analytics/CJ_goal_feature-runs/$RUN_ID/.operator-no-worktree" ]; then
  VERDICT_JSON=$("$_HELPER" --caller feature --assert-isolated --no-worktree 2>&1) && _GRC=0 || _GRC=$?
else
  VERDICT_JSON=$("$_HELPER" --caller feature --assert-isolated 2>&1) && _GRC=0 || _GRC=$?
fi
VERDICT_STATE=$(echo "$VERDICT_JSON" | jq -r '.state' 2>/dev/null || echo "")

if [ "$_GRC" -ne 0 ]; then
  # Non-zero verdict: dirty / not_isolated / not_a_repo.
  TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  cat >> "$RESUME_DIR/.resume.log" <<EOF
- $TS [feature-not-isolated] isolation gate verdict=$VERDICT_STATE — checkout is not clean+isolated; refusing to run the source-writing build (D000024 class). The cj-feat-* worktree was not created (or was bypassed for a primary-checkout branch).
  next_action=Run /CJ_goal_feature from a clean main checkout (it auto-creates a cj-feat-* worktree), or from a clean feature branch / worktree; or pass --no-worktree on a clean checkout.
  resume_cmd=/CJ_goal_feature "$TOPIC"
  pr_url=N/A
  raw_output_path=N/A
EOF
  echo "Why it stopped: the checkout is not clean+isolated (verdict: $VERDICT_STATE), so the build would write on top of unrelated work. The mandatory cj-feat-* worktree was not in place."
  echo "State preserved: no work-item scaffolded; resume state under $RESUME_DIR."
  echo "Next: /CJ_goal_feature \"$TOPIC\"  (from a clean main checkout — it creates the worktree automatically)"
  jq -nc --arg ts "$TS" --arg run_id "$RUN_ID" --arg end_state "halted_at_not_isolated" \
    --arg topic "$TOPIC" '{ts:$ts,run_id:$run_id,end_state:$end_state,topic:$topic,parent_skill:"CJ_goal_feature"}' \
    >> "$TELEMETRY" 2>/dev/null || true
  exit 1
fi

echo "Isolation gate: verdict=$VERDICT_STATE — clean+isolated; proceeding to office-hours + the silent build."
```

Only on a green (`isolated`, exit 0) verdict does control proceed to Step 2.

## Step 2: /office-hours (INLINE — the interactive design phase)

office-hours is the design checkpoint up front (Step 2.7's gate is the second
human touchpoint). It runs INLINE at the
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
  next_action=Resume /office-hours, accept the final Approve, then re-run /CJ_goal_feature.
  resume_cmd=/CJ_goal_feature "$TOPIC"
  pr_url=N/A
  raw_output_path=N/A
EOF
echo "Why it stopped: /office-hours did not reach an APPROVED design doc, so there is nothing to build yet."
echo "State preserved: no work-item scaffolded; resume state at $RESUME_STATE."
echo "Next: /office-hours \"$TOPIC\"  (accept the final Approve), then /CJ_goal_feature \"$TOPIC\""
# Telemetry: end_state=halted_at_officehours (write per Step 6 schema before exit)
jq -nc --arg ts "$TS" --arg run_id "$RUN_ID" --arg end_state "halted_at_officehours" \
  --arg topic "$TOPIC" '{ts:$ts,run_id:$run_id,end_state:$end_state,topic:$topic,parent_skill:"CJ_goal_feature"}' \
  >> "$TELEMETRY" 2>/dev/null || true
exit 1
```

## Step 2.5: Record the office-hours boundary

On a successful Approve (or a validated resume short-circuit), record the
office-hours phase boundary atomically. The `office_hours_receipt` path is
deterministic (`${branch}.office-hours.receipt`, the F000053/S000095 phase
receipt Step 2.6 populates); record the pointer here so a resume re-locates the
receipt by the recorded path (mirroring how `design_doc` is recorded):

```bash
mkdir -p "$RESUME_DIR"
HEAD_SHA=$(git -C "$_REPO_ROOT" rev-parse HEAD 2>/dev/null)
OH_RECEIPT="$RESUME_DIR/${_BRANCH}.office-hours.receipt"
_TMP=$(mktemp "$RESUME_DIR/.state.XXXXXX")
cat > "$_TMP" <<EOF
last_completed_phase=office-hours
phase_sha=$HEAD_SHA
design_doc=$DESIGN_DOC
office_hours_receipt=$OH_RECEIPT
work_item_dir=$WORK_ITEM_DIR
pr_number=$PR_NUMBER
topic=$TOPIC
EOF
mv "$_TMP" "$RESUME_STATE"
echo "[resume] recorded office-hours boundary (doc=$DESIGN_DOC, sha=$HEAD_SHA)"
```

## Step 2.6: Write the compact office-hours phase receipt (F000053 / S000095 — P1 within-phase receipt)

The office-hours transcript is large and resident in the orchestrator window. To
continue from a compact receipt rather than the transcript (P1 context
curation), distill the APPROVED design doc into a short digest ONCE here and
persist it to `$OH_RECEIPT` via the atomic `mktemp` + `mv` write. Step 2.7 and
every resume then read the digest FROM this receipt — the full design doc and the
resident office-hours transcript need not stay in context for the gate or the
build. This is the ONLY within-phase receipt this pipeline writes: there is no
generic per-phase compaction hook (AC3 — scoped to the office-hours boundary).

**Skip-on-resume (receipt vouches for HEAD).** Reuse the existing receipt instead
of re-distilling when it already vouches for the current HEAD — the same
validate-before-skip contract S000093's `receipts.qa` uses (`commit` is the SHA
the receipt vouches for):

```bash
OH_RECEIPT="${OH_RECEIPT:-$RESUME_DIR/${_BRANCH}.office-hours.receipt}"
OH_RECEIPT_FRESH=0
if [ -f "$OH_RECEIPT" ]; then
  _OH_COMMIT=$(sed -n 's/^commit=//p' "$OH_RECEIPT" | head -1)
  if [ -n "$_OH_COMMIT" ] && git -C "$_REPO_ROOT" merge-base --is-ancestor "$_OH_COMMIT" HEAD 2>/dev/null; then
    OH_RECEIPT_FRESH=1
    echo "[receipt] office-hours receipt vouches for HEAD (commit=$_OH_COMMIT); reusing it (no re-distill)."
  fi
fi
```

When `OH_RECEIPT_FRESH=0` (fresh run, missing receipt, or a stale `commit`):

1. **Read the APPROVED design doc** at `$DESIGN_DOC` ONCE and distill the
   decision-relevant headlines — the same six the gate needs: **Topic / title**,
   **Goal / problem**, **Approach**, **Scope**, **Test plan**, **Open questions /
   risks**. Keep it to ~10–15 lines: this is the compact digest, not a copy of the
   doc.
2. **Write the receipt atomically** — a flat `key=value` envelope reusing
   S000093's locked receipt schema (`phase` / `commit` / `completed_at`), a
   `--- digest ---` delimiter, then the distilled digest body. Substitute the
   real distillation from step 1 for the angle-bracketed placeholder:

```bash
_TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)
_HEAD=$(git -C "$_REPO_ROOT" rev-parse HEAD 2>/dev/null)
_TMP=$(mktemp "$RESUME_DIR/.ohreceipt.XXXXXX")
cat > "$_TMP" <<EOF
phase=office-hours
commit=$_HEAD
completed_at=$_TS
design_doc=$DESIGN_DOC
ready_for_ship=false
--- digest ---
<the ~10–15-line distilled digest from step 1 — Topic / title, Goal / problem,
 Approach, Scope, Test plan, Open questions / risks>
EOF
mv "$_TMP" "$OH_RECEIPT"
echo "[receipt] wrote compact office-hours phase receipt → $OH_RECEIPT (commit=$_HEAD)"
```

The envelope keys (`phase` / `commit` / `completed_at`) are S000093's shared
receipt schema — one schema, not two (AC4). `.cj-goal-feature/` is gitignored, so
the receipt is workbench-local scratch, never committed.

## Step 2.7: Design-summary approval gate (the post-office-hours checkpoint)

Runs immediately after the office-hours boundary is recorded, before the silent
build. office-hours emits the APPROVED doc and the orchestrator used to proceed
**silently** ("doc is done") straight into scaffold/implement/qa — this gate
replaces that silent hand-off with a **chat summary of the design + an explicit
go/no-go**. It is the operator's go-ahead to spend the autonomous build budget
(scaffold → implement → qa → `/ship`), a distinct decision from the office-hours
Approve (which approved the *design doc content*). The orchestrator runs at the
top level, so AskUserQuestion is available here (subagents are not yet
dispatched).

**Skip-on-resume.** Run this gate ONLY while the build has not yet started —
i.e. the validated `LAST_PHASE` (Step 1.5) is exactly `office-hours`. If
`LAST_PHASE ∈ {scaffold, impl, qa, ship}` the operator already approved on an
earlier invocation and the build progressed; do NOT re-ask — skip to Step 3. A
fresh office-hours run sets `LAST_PHASE=office-hours` at Step 2.5, so the gate
fires once after a fresh design doc and re-fires on every resume still parked at
the gate.

```bash
# Gate applies only while parked at the office-hours boundary (build not started).
RUN_DESIGN_GATE=0
[ "$LAST_PHASE" = "office-hours" ] && RUN_DESIGN_GATE=1
```

When `RUN_DESIGN_GATE=1`:

1. **Source the digest from the office-hours phase receipt** at `$OH_RECEIPT`
   (written at Step 2.6; recorded in the resume state as `office_hours_receipt=`).
   Read the digest body — everything after the `--- digest ---` delimiter — NOT
   the full `$DESIGN_DOC`, and NOT the resident office-hours transcript. This is
   the P1 within-phase-receipt contract: the design-summary digest is SOURCED FROM
   the receipt file (F000053/S000095, AC2), so the orchestrator continues from the
   compact receipt rather than transcript-resident context.

   ```bash
   if [ -f "$OH_RECEIPT" ]; then
     OH_DIGEST=$(sed -n '/^--- digest ---$/,$p' "$OH_RECEIPT" | sed '1d')
     echo "[receipt] sourced design-summary digest from $OH_RECEIPT"
   else
     OH_DIGEST=""   # pre-S000095 fallback: re-distill from $DESIGN_DOC below
     echo "[receipt] no office-hours receipt found; re-distilling from $DESIGN_DOC (pre-S000095 fallback)"
   fi
   ```
2. **Print the digest as the chat summary** — NOT a dump of the full file, and
   NOT a bare "doc is done". The receipt's digest already carries the
   decision-relevant headlines (**Topic / title**, **Goal / problem**,
   **Approach**, **Scope**, **Test plan**, **Open questions / risks**); print them
   so the gate reads at a glance (~10–15 lines). ONLY on the pre-S000095 fallback
   (`$OH_RECEIPT` absent) distill these inline from `$DESIGN_DOC`, falling back to
   the nearest heading when a label differs.
3. **Surface the approval AUQ** (AskUserQuestion). Recommend A:

```
Design ready for "<topic>" — APPROVED doc at <DESIGN_DOC>.
The summary above is the digest; the full doc has the detail.
Proceeding kicks off the SILENT autonomous build (scaffold → implement → qa)
and opens a PR via /ship. Nothing merges automatically — the PR is the review.

A) Approve & build (Recommended) — run the silent build and open the PR.
B) Abort — stop here; the APPROVED doc + office-hours boundary are saved.
   Resume later with /CJ_goal_feature "<topic>" (this gate re-fires on resume).
```

**On A (Approve & build):** continue to Step 3. No state change is needed — the
office-hours boundary is already recorded, and Step 3 records the scaffold
boundary once the build starts, which moves the resume point past this gate (so
a later resume skips it).

**On B (Abort):** HALT with `[design-gate-declined]` (end_state
`halted_at_design_gate`). The APPROVED doc and the recorded office-hours
boundary are preserved, so a re-run short-circuits office-hours (Step 2 resume:
recorded doc still APPROVED) and re-shows this gate — the build never started:

```bash
TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)
mkdir -p "$RESUME_DIR"
cat >> "$RESUME_DIR/.resume.log" <<EOF
- $TS [design-gate-declined] operator declined the design-summary approval gate; the silent build was not dispatched. APPROVED design doc preserved at $DESIGN_DOC.
  next_action=Re-run /CJ_goal_feature to re-show the summary + gate; edit the doc (or re-run /office-hours) first if the design needs changes.
  resume_cmd=/CJ_goal_feature "$TOPIC"
  pr_url=N/A
  raw_output_path=N/A
EOF
echo "Why it stopped: you declined the design-summary approval gate, so the autonomous build was not started."
echo "State preserved: APPROVED design doc at $DESIGN_DOC; office-hours boundary recorded at $RESUME_STATE."
echo "Next: /CJ_goal_feature \"$TOPIC\"  (re-shows the summary + gate; the build has not started)."
jq -nc --arg ts "$TS" --arg run_id "$RUN_ID" --arg end_state "halted_at_design_gate" \
  --arg topic "$TOPIC" '{ts:$ts,run_id:$run_id,end_state:$end_state,topic:$topic,parent_skill:"CJ_goal_feature"}' \
  >> "$TELEMETRY" 2>/dev/null || true
exit 1
```

Only on A (Approve & build) does control proceed to Step 3.

## Step 3: Silent build — scaffold → implement → qa (leaf Agent subagents)

The build runs with **zero AUQ** (P0 #2). Each phase is a depth-2 leaf Agent
subagent (it does NOT spawn further subagents — depth ≤ 2). The orchestrator
dispatches them in sequence, recording a phase boundary after each green return.

A phase is **skipped** only when the validated `LAST_PHASE` (Step 1.5) is at or
past that phase. Otherwise it runs. **Exception (F000053 / S000093): the `qa`
phase (Step 3.3) is NEVER skipped on resume — it always re-dispatches** so a
same-SHA resume re-verifies; `qa.md`'s receipt-based re-validation keeps that
cheap (see Step 3.3).

### Step 3.1: scaffold (skip if validated LAST_PHASE ∈ {scaffold, impl, qa, ship})

Dispatch `/CJ_scaffold-work-item` via the **Agent** tool (`subagent_type:
general-purpose`) with the recorded design-doc path:

```
ROLE: /CJ_scaffold-work-item runner for /CJ_goal_feature (silent — no AUQ).
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
`/CJ_goal_feature "$TOPIC"`.

On green: record the scaffold boundary (same atomic-write as Step 2.5, with
`last_completed_phase=scaffold`, the new `work_item_dir=$WORK_ITEM_DIR`, and a
fresh `phase_sha`).

### Step 3.2: implement (skip if validated LAST_PHASE ∈ {impl, qa, ship})

Dispatch `/CJ_implement-from-spec` via the **Agent** tool against
`$WORK_ITEM_DIR` in **auto-equivalent** mode (subagents have no AUQ tool, so the
implement skill runs without AUQ attempts):

```
ROLE: /CJ_implement-from-spec runner for /CJ_goal_feature (silent — no AUQ).
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

### Step 3.3: qa (ALWAYS re-dispatched on resume — F000053 / S000093)

**Resume policy (GAP A path 2).** Do NOT phase-skip QA when the validated
`LAST_PHASE ∈ {qa, ship}`. A same-SHA resume must re-verify, so always
re-dispatch `/CJ_qa-work-item` here. This is cheap and bounded: `qa.md` Step 3
re-validates against the SHA-anchored `receipts.qa` execution receipt — it
re-runs the smoke rows and reuses the receipt's E2E verdict, re-running the
~5-min E2E subagent ONLY when the receipt is missing, incomplete, or does not
vouch for HEAD. (Previously this step was skipped on `LAST_PHASE ∈ {qa, ship}`,
so a resume where untracked / generated / fixture state changed could reach
`/ship` without re-verifying — the hole S000093 closes.)

Dispatch `/CJ_qa-work-item` via the **Agent** tool against `$WORK_ITEM_DIR`. The
dispatch prompt carries the literal directive `DEFER_AUDIT: true` so QA defers
its three-stage audit (qa.md Step 8.6c/8.6d) — the orchestrator runs that audit
ONCE at the authoritative post-sync point (Step 5.6). QA still runs the overlay
WRITES (8.6a/8.6b) inline and returns `AUDITS=deferred` with **no**
`AUDIT_FINDINGS` block:

```
ROLE: /CJ_qa-work-item runner for /CJ_goal_feature (silent — no AUQ).
DEFER_AUDIT: true
TASK: Invoke /CJ_qa-work-item on the work-item dir in <inputs>. The literal
DEFER_AUDIT: true directive above tells QA to run its Step 8.6a/8.6b overlay
writes inline but DEFER the 8.6c/8.6d three-stage audit (the orchestrator runs
the post-sync audit itself at Step 5.6). Return the RESULT line verbatim —
including the AUDITS= field (it will read AUDITS=deferred,spec_updates:<...>);
do NOT expect an AUDIT_FINDINGS block on the deferred path:
RESULT: SMOKE=<...>; E2E=<...>; PHASE2_GATES=<...>; AUDITS=deferred,spec_updates:<...>
<inputs>WORK_ITEM_DIR: <absolute $WORK_ITEM_DIR></inputs>
```

If QA returns red: **HALT** with `[qa-red]` (re-use the existing CJ_qa-work-item
halt marker — do NOT mint a new one), end_state `halted_at_qa`, `pr_url=N/A`,
`raw_output_path=$RAW_DIR/qa-raw.txt`, + the 3-line block + telemetry.

On green: record the qa boundary, then continue to Step 3.5 (the pre-doc-sync
commit), then Step 5.5 (Doc-sync), then Step 5.6 (the post-sync audit), then
Step 3.4 (the QA-audit checkpoint, fed by the post-sync audit), then Step 5.7
(portability), then Step 4 (/ship).

### Step 3.5: Pre-doc-sync commit (NEW — automated, idempotent; closes the F000038 gotcha)

The implement + QA leaf subagents WRITE the QA-green code and the qa.md
8.6a/8.6b spec-overlay refreshes but do NOT commit them; `/ship` (the committer)
runs after doc-sync. `/CJ_document-release` (Step 5.5) hard-refuses on an
uncommitted NON-DOC change (`[doc-sync-red]`). Historically the feature pipeline
only avoided that halt via the operator manually committing (the F000038 gotcha,
PR #195). This NEW step formalizes the commit so doc-sync never hits the
uncommitted-non-doc refusal during an autonomous build.

The commit is **idempotent**: it skips when the tree is already clean at HEAD, so
a resume after the commit already ran does NOT double-commit. It records NO new
`last_completed_phase` boundary — it is gated on the live tree state, not on
resume state, so a resume re-enters it harmlessly (clean tree ⇒ skip):

```bash
if git -C "$_REPO_ROOT" diff --quiet && git -C "$_REPO_ROOT" diff --cached --quiet; then
  echo "[pre-doc-sync-commit] tree already clean at HEAD — nothing to commit (idempotent skip)."
else
  _SUBJ=$(printf '%s' "${WORK_ITEM_ID:-$TOPIC}" | tr '\n' ' ' | cut -c1-60)
  git -C "$_REPO_ROOT" add -A
  git -C "$_REPO_ROOT" commit -m "feat: $_SUBJ (QA-green; pre-doc-sync commit)" >/dev/null
  echo "[pre-doc-sync-commit] committed the QA-green code + 8.6a/8.6b overlay writes (clean tree for doc-sync)."
fi
```

(`/ship` at Step 4 adds the VERSION/CHANGELOG bump as a follow-on commit; the
squash-merge subject is reconciled at land time per the repo's merge
convention.) Only after a clean tree is established does control proceed to
Step 5.5 (doc-sync).

### Step 5.5: Doc-sync (INLINE — CJ_document-release wrapper around upstream /document-release)

Doc-sync runs INLINE between the pre-doc-sync commit and the post-sync audit, so
any doc updates fold into the SAME code PR as the implementation. There is no
post-merge doc-drift window for orchestrator-driven paths: the doc update ships
in the same PR as the code. Doc-sync now runs **before** the post-sync audit + the
QA-audit checkpoint (F000064 reorder), so the checkpoint decides on the docs that
will actually ship.

Invoke `/CJ_document-release` via the **Skill** tool with NO `--docs` flag
(v1 orchestrator wiring runs a full audit; the per-doc subset flag is for
manual operator invocations). The skill returns one of three RESULTs:

- `RESULT: green` — `/document-release` ran clean and the wrapper
  auto-committed doc-only changes (whitelist: `README|CHANGELOG|CLAUDE|
  ARCHITECTURE.md` + `doc/.+\.md` + `templates/doc-.*\.md`). Continue to
  Step 4 (/ship). The next phase will see a clean tree with a doc commit
  already present.
- `RESULT: green-noop` — `/document-release` ran clean and no doc changes
  were needed. Continue to Step 4 (/ship). The PR will be code-only.
- `RESULT: red; HALT_MARKER=[doc-sync-red]` — `/document-release` itself
  returned non-green (audit error, mid-write failure, hard-abort, base-
  branch refusal, or a pre-run non-doc dirty tree). **HALT** with halt
  class `halted_at_doc_sync`; the orchestrator writes a journal entry and
  exits.
- `RESULT: red; HALT_MARKER=[doc-sync-non-doc-write]` — `/document-release`
  succeeded but wrote files OUTSIDE the doc-only whitelist (upstream-
  misbehaved). **HALT** with halt class `halted_at_doc_sync_non_doc_write`;
  the orchestrator writes a journal entry naming the non-doc files and
  exits.

Halt-marker shape (mirrors the family contract — `next_action=` /
`resume_cmd=` / `pr_url=`):

```bash
# Pseudocode — the orchestrator's Step 5.5 dispatch handler:
case "$DOC_SYNC_RESULT" in
  green|green-noop)
    echo "[doc-sync] $DOC_SYNC_RESULT — continuing to /ship"
    # No state change beyond the doc commit /CJ_document-release made.
    ;;
  *red*\[doc-sync-red\]*)
    TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    cat >> "$RESUME_DIR/.resume.log" <<EOF
- $TS [doc-sync-red] /CJ_document-release returned RESULT=red; halt class halted_at_doc_sync.
  next_action=Inspect /document-release output; fix doc errors; re-run /CJ_document-release manually, then resume /CJ_goal_feature.
  resume_cmd=/CJ_goal_feature "$TOPIC"
  pr_url=N/A
  raw_output_path=$RAW_DIR/doc-sync-raw.txt
EOF
    echo "Why it stopped: /CJ_document-release failed (upstream /document-release non-green or pre-run gate refused)."
    echo "State preserved: code commits intact; doc-sync did NOT commit doc files; resume state at $RESUME_STATE."
    echo "Next: inspect the failure, fix manually, then /CJ_goal_feature \"$TOPIC\""
    jq -nc --arg ts "$TS" --arg run_id "$RUN_ID" --arg end_state "halted_at_doc_sync" \
      --arg topic "$TOPIC" '{ts:$ts,run_id:$run_id,end_state:$end_state,topic:$topic,parent_skill:"CJ_goal_feature"}' \
      >> "$TELEMETRY" 2>/dev/null || true
    exit 1
    ;;
  *red*\[doc-sync-non-doc-write\]*)
    TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    cat >> "$RESUME_DIR/.resume.log" <<EOF
- $TS [doc-sync-non-doc-write] /CJ_document-release refused to auto-commit because upstream wrote files outside the doc-only whitelist.
  next_action=Inspect uncommitted non-doc files; revert if unexpected; re-run /CJ_document-release manually, then resume /CJ_goal_feature.
  resume_cmd=/CJ_goal_feature "$TOPIC"
  pr_url=N/A
  raw_output_path=$RAW_DIR/doc-sync-raw.txt
EOF
    echo "Why it stopped: /CJ_document-release refused — upstream /document-release wrote files outside the doc-only whitelist."
    echo "State preserved: code commits intact; nothing auto-committed; resume state at $RESUME_STATE."
    echo "Next: inspect the non-doc files, revert if unexpected, then /CJ_goal_feature \"$TOPIC\""
    jq -nc --arg ts "$TS" --arg run_id "$RUN_ID" --arg end_state "halted_at_doc_sync_non_doc_write" \
      --arg topic "$TOPIC" '{ts:$ts,run_id:$run_id,end_state:$end_state,topic:$topic,parent_skill:"CJ_goal_feature"}' \
      >> "$TELEMETRY" 2>/dev/null || true
    exit 1
    ;;
esac
```

Only on green or green-noop does control proceed to Step 5.6 (the post-sync
audit), then Step 3.4 (the QA-audit checkpoint), then the portability gate, then
Step 4 (/ship).

### Step 5.6: Post-sync doc/test audit (NEW — ONE combined read-only subagent)

Now that doc-sync has folded its doc updates into the PR, run the three-stage
doc/test audit ONCE, at the authoritative **post-sync** point. This is the audit
QA deferred (via `DEFER_AUDIT: true`, Step 3.3) — the orchestrator runs it itself
here so the Step 3.4 checkpoint decides on the docs that will actually ship.

Dispatch ONE combined depth-2 fresh-context subagent via the **Agent** tool
(`subagent_type: general-purpose`) that runs BOTH `/CJ_doc_audit` and
`/CJ_test_audit` over the post-sync tree. It is **READ-ONLY** — it reports, it
writes NO overlay/doc fixes (that preserves the "everything in the PR is
post-sync-clean" invariant; a needed fix surfaces at the checkpoint, where the
operator Halts and re-runs so the fix lands pre-sync on the next pass). Dispatch
ONE subagent, not two — the audit skills' standalone contract lets one
fresh-context subagent judge both audits, and two would double the cost this
mechanism exists to avoid:

```
ROLE: combined post-sync doc/test auditor for /CJ_goal_feature (READ-ONLY — report, do not fix).
TASK: Run /CJ_doc_audit and then /CJ_test_audit over the CURRENT (post-doc-sync)
repo tree, standalone (all three stages each). Do NOT write any doc/overlay
fixes — this is a read-only report. Return BOTH skills' full per-stage reports
verbatim: the DOC_AUDIT: headline (FINDINGS= + STAGE1/2/3_FINDINGS= +
DOCS_AUDITED= + seeded: + the three --- stage N --- sections) and the
TEST_AUDIT: headline (FINDINGS= + STAGE1/2/3_FINDINGS= + UNITS_AUDITED= +
seeded: + the three --- stage N --- sections), then emit a single fenced
AUDIT_FINDINGS block combining both for the checkpoint to print verbatim.
<inputs>REPO_ROOT: <absolute $_REPO_ROOT></inputs>
```

Capture the subagent's output to `$RAW_DIR/post-sync-audit-raw.txt`. Parse the
two `FINDINGS=` lines into a compact `AUDITS=doc:<ok|findings:n>,test:<ok|findings:n>`
digest and capture the fenced `AUDIT_FINDINGS` block for the checkpoint.

This step is a **pure read** (it records NO phase boundary and writes no fixes),
so a resume re-runs it. If the audit subagent crashes (no parseable report),
treat it as `AUDITS=doc:audit-error,test:audit-error` and surface the raw output
at the checkpoint — do NOT halt here (the checkpoint owns the decision).

### Step 3.4: QA-audit findings checkpoint (ALWAYS — the one AUQ past the design gate; consumes the POST-sync audit)

Immediately after the Step 5.6 post-sync audit returns, surface the checkpoint
on its report (NOT a pre-sync audit). The `AUDITS=` digest + the fenced
`AUDIT_FINDINGS` block come from Step 5.6's combined post-sync subagent (the two
spec-overlay updates rode the QA RESULT at 8.6a/8.6b; the doc audit + test audit
are now the post-sync results). Surface an AskUserQuestion **ALWAYS** — findings
or not (the operator explicitly sees the post-sync outcome before the run spends
ship budget; a green digest is a one-glance Continue):

> QA-audit checkpoint for {WORK_ITEM_ID} — AUDITS=doc:<...>,test:<...> (post-sync)
>
> {AUDIT_FINDINGS block, verbatim}
>
> Options:
> - Continue — proceed to the portability gate + /ship
> - Halt — stop the run here; I want to act on these findings first

**On Continue:** if either audit reported findings (`doc:findings:n` or
`test:findings:n` with n>0), append the auditable waiver line to the
work-item tracker journal BEFORE proceeding:

```
- $TS [qa-audit-waived] operator continued past audit findings at the post-QA (post-sync) checkpoint: AUDITS=doc:<...>,test:<...>
```

(on a fully-green digest no waiver line is written — there is nothing to
waive). Continue to Step 5.7 (portability).

**On Halt:** append the decline + the family-contract fields to
`$RESUME_DIR/.resume.log`, write telemetry, and exit:

```bash
TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)
cat >> "$RESUME_DIR/.resume.log" <<EOF
- $TS [qa-audit-declined] operator halted at the post-QA (post-sync) audit checkpoint. AUDITS digest preserved at $RAW_DIR/post-sync-audit-raw.txt.
  next_action=Act on the audit findings (fix docs / units rows / stale requirements), then resume; QA re-runs per the always-re-dispatch rule, doc-sync + the post-sync audit re-run, and the checkpoint re-fires.
  resume_cmd=/CJ_goal_feature "$TOPIC"
  pr_url=N/A
  raw_output_path=$RAW_DIR/post-sync-audit-raw.txt
EOF
jq -nc --arg ts "$TS" --arg run_id "$RUN_ID" --arg end_state "halted_at_qa_audit" \
  --arg topic "$TOPIC" '{ts:$ts,run_id:$run_id,end_state:$end_state,topic:$topic,parent_skill:"CJ_goal_feature"}' \
  >> "$TELEMETRY" 2>/dev/null || true
exit 1
```

The checkpoint is a **pure read** of the post-sync audit (it records NO phase
boundary): a resume after `[qa-audit-declined]` re-dispatches QA (the existing
always-re-dispatch rule), re-runs the pre-doc-sync commit (idempotent),
doc-sync, and the post-sync audit, and the checkpoint re-fires on the fresh
post-sync digest. Canonical gate row: `qa-audit` (order 45) in
`spec/test-spec-custom.md`.

### Step 5.7: Portability gate (INLINE — halt-on-red before /ship; F000051)

Runs immediately after the Step 5.5 doc-sync handler and immediately before
`/ship`. The catalog/skills are final after implement; doc-sync only touched
docs — so this is the last readiness check before the PR, and it keeps the
verdict fresh for the Step 4.6 PR-body surfacing. The gate is a **pure read**
(it records NO phase boundary and is unconditionally re-run on every resume),
so a resume after a `[portability-red]` halt restarts here, not at ship; no
`last_completed_phase` value is added for it.

Call the shared `cj-goal-common.sh --phase portability-audit --mode feature`
(the audit is verb-independent; `--mode` is telemetry-only here). It runs the
`cj-portability-audit.sh` engine under `PORTABILITY_STRICT=1` and classifies the
result into `ok` / `findings` / `skipped`:

```bash
_COMMON="$_REPO_ROOT/scripts/cj-goal-common.sh"
_PORT_RESULT="skipped"; _PORT_VERDICT=""
if [ -x "$_COMMON" ]; then
  _PORT_OUT=$(bash "$_COMMON" --phase portability-audit --mode feature 2>/dev/null) && _PORT_RC=0 || _PORT_RC=$?
  _PORT_RESULT=$(printf '%s\n' "$_PORT_OUT" | sed -n 's/^PHASE_RESULT=//p' | head -1)
  _PORT_VERDICT=$(printf '%s\n' "$_PORT_OUT" | sed -n 's/^VERDICT_LINE=//p' | head -1)
  [ -z "$_PORT_RESULT" ] && _PORT_RESULT="skipped"
else
  echo "[portability] cj-goal-common.sh unreachable — skipping the portability gate (best-effort)"
fi
```

- On `PHASE_RESULT=ok`: write `VERDICT_LINE` to the scratch file
  `.cj-goal-feature/portability-verdict.md` (sibling of
  `registered-doc-verdicts.md`, gitignored) and continue to Step 4 (/ship):

```bash
if [ "$_PORT_RESULT" = "ok" ]; then
  mkdir -p "$_REPO_ROOT/.cj-goal-feature" 2>/dev/null || true
  printf '### Portability\n\n%s\n' "$_PORT_VERDICT" > "$_REPO_ROOT/.cj-goal-feature/portability-verdict.md"
  echo "[portability] $_PORT_VERDICT — continuing to /ship"
fi
```

- On `PHASE_RESULT=skipped` (engine absent / helper unreachable): echo a visible
  note and continue to Step 4 — no halt, no scratch write:

```bash
if [ "$_PORT_RESULT" = "skipped" ]; then
  echo "[portability] gate skipped (engine absent) — continuing to /ship (best-effort, not halting)"
fi
```

- On `PHASE_RESULT=findings`: **HALT** with `[portability-red]` (end_state
  `halted_at_portability`). A touched skill declares a portability tier it does
  not honor; no PR is created (the gate halts BEFORE `/ship`), so the findings
  live in the halt journal:

```bash
if [ "$_PORT_RESULT" = "findings" ]; then
  TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  mkdir -p "$RESUME_DIR" 2>/dev/null || true
  printf '%s\n' "$_PORT_OUT" > "$RAW_DIR/portability-raw.txt" 2>/dev/null || true
  cat >> "$RESUME_DIR/.resume.log" <<EOF
- $TS [portability-red] cj-goal-common.sh --phase portability-audit returned PHASE_RESULT=findings; halt class halted_at_portability. $_PORT_VERDICT
  next_action=A touched skill declares a portability tier it does not honor. Relabel its 'portability' in skills-catalog.json to the tier its deps need, OR add the accepted dep to its 'portability_requires'. Then re-run.
  resume_cmd=/CJ_goal_feature "$TOPIC"
  pr_url=N/A
  raw_output_path=$RAW_DIR/portability-raw.txt
EOF
  echo "Why it stopped: the portability audit found a skill that declares a portability tier it does not honor (a dishonest declaration); the gate blocks the PR until it is reconciled."
  echo "State preserved: code + doc commits intact; no PR created; resume state at $RESUME_STATE."
  echo "Next: relabel the skill's 'portability' (or add to 'portability_requires') in skills-catalog.json, then /CJ_goal_feature \"$TOPIC\""
  jq -nc --arg ts "$TS" --arg run_id "$RUN_ID" --arg end_state "halted_at_portability" \
    --arg topic "$TOPIC" '{ts:$ts,run_id:$run_id,end_state:$end_state,topic:$topic,parent_skill:"CJ_goal_feature"}' \
    >> "$TELEMETRY" 2>/dev/null || true
  exit 1
fi
```

Only on `ok` or `skipped` does control proceed to Step 4 (/ship).

## Step 4: /ship (INLINE — diff-review AUQ suppressed; opens a PR)

Invoke `/ship` via the **Skill** tool with the diff-review AUQ **suppressed**.
The opened PR is the human review (P0 #2 amended: the only AUQ between the
office-hours Approve and the PR is the Step 2.7 design-summary gate; past it the
build is silent), so `/ship`'s mid-flight diff-review AUQ is relocated to the
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

## Step 4.6: Surface registered-doc verdicts into the PR body (best-effort; NEVER halts)

The Step 5.5 doc-sync wrapper (`/CJ_document-release`) ran a Registered-doc
requirements audit (its Step 6.7) and wrote the verdict block to the gitignored
scratch file `.cj-goal-feature/registered-doc-verdicts.md`. That block dies in
the wrapper RESULT otherwise — upstream `/ship` Step 18 regenerates the PR body
from a fresh `/document-release` subagent that never sees the wrapper output. So
surface it deterministically here, now that Step 4 has opened the PR and
`$PR_NUMBER` is known: read the scratch file and `gh pr edit <PR#>` to
insert-or-replace a `### Registered-doc requirements` subsection under the PR
body's `## Documentation` section.

This is **best-effort and NEVER halts the run**: a failed `gh pr edit` (or a
missing scratch file — Step 5.5 may have been a no-op path) logs a one-line note
and control proceeds to Step 5. The verdicts still live in the run output + the
scratch file regardless. There is **NO upstream `/ship` modification** — this is
a workbench-owned pipeline step. All three cj_goal orchestrators surface the
verdict (`/CJ_goal_feature` here, `/CJ_goal_defect` Step 9.5,
`/CJ_goal_todo_fix` Step 5.6 — the latter two auto-land, so their PR-body verdict
has a short review window; the verdict also lands in the run output + the scratch
file + `/ship` Gate #2). The Step 6.7 producer is shared by all three regardless.

The same step ALSO splices the green portability verdict (`### Portability`,
written by the Step 5.7 gate to `.cj-goal-feature/portability-verdict.md`) into
the same `## Documentation` section — identical best-effort posture.

```bash
_VERDICT_FILE="$_REPO_ROOT/.cj-goal-feature/registered-doc-verdicts.md"
_PORT_VERDICT_FILE="$_REPO_ROOT/.cj-goal-feature/portability-verdict.md"
if [ -n "$PR_NUMBER" ] && { [ -f "$_VERDICT_FILE" ] || [ -f "$_PORT_VERDICT_FILE" ]; }; then
  # Read the current PR body, then insert-or-replace the
  # '### Registered-doc requirements' + '### Portability' subsections under
  # '## Documentation'.
  _BODY=$(gh pr view "$PR_NUMBER" --json body -q .body 2>/dev/null || echo "")
  _VERDICTS=""
  [ -f "$_VERDICT_FILE" ] && _VERDICTS=$(cat "$_VERDICT_FILE")
  _PORT=""
  [ -f "$_PORT_VERDICT_FILE" ] && _PORT=$(cat "$_PORT_VERDICT_FILE")
  # Combine the two blocks (either may be empty) into one insert payload.
  if [ -n "$_VERDICTS" ] && [ -n "$_PORT" ]; then
    _INSERT=$(printf '%s\n\n%s' "$_VERDICTS" "$_PORT")
  else
    _INSERT="${_VERDICTS}${_PORT}"
  fi

  # Idempotent splice (replace-if-present): strip any existing
  # '### Registered-doc requirements' OR '### Portability' block (each up to the
  # next '###'/'##' or EOF), then insert the fresh blocks under the
  # '## Documentation' heading (appending the section if absent). Composed in
  # temp files + applied via `gh pr edit --body-file` — NEVER `awk -v v="$_INSERT"`
  # with a multi-line payload: BSD/macOS awk rejects a newline in a -v value
  # ("newline in string"), which empties the substitution and lets the edit WIPE
  # the PR body (hit live on PR #259; fixed by T000053).
  _STRIPPED_FILE=$(mktemp); _INSERT_FILE=$(mktemp); _BODY_FILE=$(mktemp)
  printf '%s\n' "$_BODY" | awk '
    /^### Registered-doc requirements/ {skip=1; next}
    /^### Portability/ {skip=1; next}
    skip && /^#{2,3} / {skip=0}
    !skip {print}
  ' > "$_STRIPPED_FILE"
  printf '%s\n' "$_INSERT" > "$_INSERT_FILE"
  if grep -q '^## Documentation' "$_STRIPPED_FILE"; then
    # The only -v is a newline-free FILENAME, so BSD awk is happy; the multi-line
    # payload is read from the file, never carried through -v.
    awk -v insert_file="$_INSERT_FILE" '
      {print}
      /^## Documentation/ && !done {print ""; while ((getline line < insert_file) > 0) print line; done=1}
    ' "$_STRIPPED_FILE" > "$_BODY_FILE"
  else
    { cat "$_STRIPPED_FILE"; printf '\n## Documentation\n\n'; cat "$_INSERT_FILE"; } > "$_BODY_FILE"
  fi

  # Apply via --body-file + a post-edit sanity assert: re-fetch the body and
  # require a line-count floor (catch a wipe), retry once, stay best-effort.
  _FLOOR=$(awk 'END{print (NR>3)?NR-3:1}' "$_BODY_FILE")
  _SPLICED=0
  for _attempt in 1 2; do
    gh pr edit "$PR_NUMBER" --body-file "$_BODY_FILE" 2>/dev/null || true
    _CHECK_LINES=$(gh pr view "$PR_NUMBER" --json body -q .body 2>/dev/null | awk 'END{print NR}')
    [ "${_CHECK_LINES:-0}" -ge "$_FLOOR" ] && { _SPLICED=1; break; }
  done
  rm -f "$_STRIPPED_FILE" "$_INSERT_FILE" "$_BODY_FILE"
  if [ "$_SPLICED" = "1" ]; then
    echo "[registered-doc] surfaced verdicts into PR #$PR_NUMBER body (## Documentation → ### Registered-doc requirements + ### Portability)"
  else
    echo "[registered-doc] PR-body splice did not verify after retry — verdicts remain in the run output + the scratch files (best-effort, not halting)"
  fi
else
  echo "[registered-doc] no verdict scratch file (or no PR#) — skipping PR-body surfacing (best-effort, not halting)"
fi
```

Control always proceeds to Step 5 — this step has no halt path.

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
  '{ts:$ts,run_id:$run_id,work_item_dir:$work_item_dir,design_doc:$design_doc,end_state:$end_state,pr_url:$pr_url,topic:$topic,parent_skill:"CJ_goal_feature"}' \
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

### Step 6.5: Worktree cleanup (best-effort, post-PR; NEVER halts)

Sweep landed cj-* worktrees + refresh root main via the shared cleanup phase
(T000036). This is the teardown mirror of the Step 1 worktree-create phase: now
that the PR is open, the janitor removes *other* MERGED/CLOSED cj-* worktrees and
pulls the root checkout current. **This feature run's OWN worktree is never
removed** — it is `$_CURRENT` (the current-dir rail) AND its PR is still OPEN (the
PR-state gate), so it fails both removal conditions. The session stays exactly
where it is.

The cleanup is strictly best-effort: a failed sweep logs a note and the run still
ends `green_pr_opened`. `cj-goal-common.sh --phase cleanup` emits
`PHASE_RESULT=ok|skipped`, never `failed` — there is no halt path here.

```bash
_COMMON="$_REPO_ROOT/scripts/cj-goal-common.sh"
_CLEAN_OUT=""
[ -x "$_COMMON" ] && _CLEAN_OUT=$(bash "$_COMMON" --phase cleanup --mode feature 2>/dev/null || true)
# Surface a one-line summary in the final report (best-effort parse).
_CLEAN_REMOVED=$(printf '%s\n' "$_CLEAN_OUT" | sed -n 's/^REMOVED=//p' | head -1)
_CLEAN_REFRESH=$(printf '%s\n' "$_CLEAN_OUT" | sed -n 's/^ROOT_REFRESH=//p' | head -1)
echo "[cleanup] worktree janitor: removed ${_CLEAN_REMOVED:-0}, root main refresh=${_CLEAN_REFRESH:-skipped}"
```

Print the summary (the cleanup line above precedes it; the "session is still in
<worktree>" framing below is preserved verbatim):

```
PIPELINE COMPLETE: end_state=green_pr_opened — STOPPED at the PR for human review.

Run ID:     $RUN_ID
Topic:      $TOPIC
Design doc: $DESIGN_DOC
Work item:  $WORK_ITEM_DIR
PR:         $PR_URL   (review + merge on GitHub)

Worktree cleanup: removed N other landed cj-* worktrees, root main refreshed.
  (Your session is still in this run's own worktree — it is never swept while
   its PR is open.)

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
`halted_at_no_arg`, `halted_at_not_isolated`, `halted_at_officehours`,
`halted_at_design_gate`, `halted_at_scaffold`, `halted_at_impl`,
`halted_at_qa`, `halted_at_qa_audit`, `halted_at_doc_sync`,
`halted_at_portability`, `halted_at_ship`.

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
- **Continue from the office-hours receipt, not the transcript (P1 — F000053 /
  S000095).** At the office-hours boundary the design digest is distilled ONCE
  into a compact phase receipt (`${branch}.office-hours.receipt` — S000093's
  shared envelope schema, atomic `mktemp`+`mv`, pointed to by the state file's
  `office_hours_receipt=` key). Step 2.7 and every resume source the
  design-summary digest FROM that receipt — the full design doc and the resident
  office-hours transcript need not stay in context. A resume reuses the receipt
  when its `commit` vouches for HEAD (validate-before-skip); otherwise it
  re-distills. Scope is the office-hours boundary only — no generic per-phase
  compaction hook.
- **One approval gate between the office-hours Approve and the PR (P0 #2,
  amended), plus one checkpoint.** office-hours is the interactive design phase;
  Step 2.7 then shows a design summary + a single go/no-go gate before the build
  budget is spent. Past that gate the build is silent except for ONE checkpoint
  AUQ — the Step 3.4 QA-audit findings checkpoint, now fed by the POST-sync audit
  (it fires ALWAYS, after QA green → pre-doc-sync commit → doc-sync → the
  post-sync audit) — and `/ship` runs with its diff-review AUQ suppressed (the PR
  is the review). The human touchpoints are: the office-hours Approve, the Step
  2.7 design-summary gate, the Step 3.4 QA-audit checkpoint, and the PR.
- **No automatic rollback.** Halts write entries with `next_action=`,
  `resume_cmd=`, and `pr_url=` — the operator drives recovery.
- **Halt-on-red end-to-end.** Any red status from office-hours, scaffold,
  implement, qa, or `/ship` stops the chain.
- **PR-stop (P0 #3).** No plan-review phase, no automatic merge, no
  `/land-and-deploy`. The PR is the human architecture gate.
- **Depth ≤ 2.** scaffold / implement / qa are leaf subagents; office-hours +
  `/ship` run inline. No subagent-spawns-subagent path.
