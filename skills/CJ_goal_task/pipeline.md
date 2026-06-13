# /CJ_goal_task — Orchestration

Single-keystroke orchestrator from a plain `"<small task>"` → a reviewable PR. A
flat sibling of `/CJ_goal_feature` that DROPS the `/office-hours` interactive
design phase and the design-summary gate, and instead runs a **hard complexity
gate** (it refuses anything that needs design or investigation, routing it to the
right verb) + a bash scaffold. The build is silent past the gate except for one
checkpoint AUQ (the post-QA audit findings — Step 4.5); `/ship` runs
inline. The pipeline STOPs at the PR — the PR is the human review.

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
/CJ_goal_task "<small task>"
/CJ_goal_task --dry-run "<small task>"
/CJ_goal_task --no-worktree "<small task>"
/CJ_goal_task                              # no-arg resume on the current branch
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
    --no-sync) ;;   # handled in the SKILL.md sync preamble; ignored here
    *) ARGS+=("$arg") ;;
  esac
done
TOPIC="${ARGS[0]:-}"
[ "${#ARGS[@]}" -le 1 ] || { echo "Error: exactly one quoted task expected (got: ${ARGS[*]})"; exit 1; }
RUN_ID=$(date +%Y%m%d-%H%M%S)-$$
# Persist the operator --no-worktree opt-out RUN_ID-scoped (shell vars do NOT
# persist across bash tool calls; Step 1.9 re-reads this marker). Mirrors
# /CJ_goal_feature Step 1 exactly.
if [ "${NO_WORKTREE:-}" = "1" ]; then
  mkdir -p "$HOME/.gstack/analytics/CJ_goal_task-runs/$RUN_ID"
  : > "$HOME/.gstack/analytics/CJ_goal_task-runs/$RUN_ID/.operator-no-worktree"
fi
```

Initialize telemetry + raw-output paths:

```bash
mkdir -p "$HOME/.gstack/analytics/CJ_goal_task-runs/$RUN_ID"
TELEMETRY="$HOME/.gstack/analytics/CJ_goal_task.jsonl"
RAW_DIR="$HOME/.gstack/analytics/CJ_goal_task-runs/$RUN_ID"
```

**Resume state file.** State is keyed to the worktree branch. Resolve it
deterministically:

```bash
_REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
_BRANCH=$(git -C "$_REPO_ROOT" branch --show-current 2>/dev/null | tr '/' '-')
RESUME_DIR="$_REPO_ROOT/.cj-goal-task"
RESUME_STATE="$RESUME_DIR/${_BRANCH}.state"
```

The state file is a small KEY=VALUE file carrying:

```
last_completed_phase=<none|scaffold|impl|qa|ship>
phase_sha=<the HEAD SHA recorded at the last completed phase boundary>
work_item_dir=<absolute path to the scaffolded work-item dir, recorded at the scaffold boundary>
pr_number=<the PR number, recorded at the ship boundary>
topic=<the original task string>
```

A fresh run (no state file) starts at `last_completed_phase=none`. The file is
written via a `mktemp` + `mv` atomic-write at each phase boundary.
`.cj-goal-task/` is workbench-local scratch — add it to `.gitignore` if not
already ignored; it is never committed.

If `--dry-run`: print the planned chain and exit before any mutation —

```bash
if [ "${DRY_RUN:-0}" = "1" ]; then
  echo "DRY RUN: topic=\"$TOPIC\""
  echo "DRY RUN: would create a cj-task-* worktree (cj-goal-common.sh --mode task)"
  echo "DRY RUN: would run the HARD complexity gate (scripts/cj-task-scaffold.sh --dry-run) — refuses design/bug/large topics"
  # Surface the real gate verdict + planned T-ID/dir without writing anything.
  _SCAFFOLD=""
  for p in "$_REPO_ROOT/skills/CJ_goal_task/scripts/cj-task-scaffold.sh" \
           "$HOME/.claude/skills/CJ_goal_task/scripts/cj-task-scaffold.sh"; do
    [ -x "$p" ] && { _SCAFFOLD="$p"; break; }
  done
  [ -n "$_SCAFFOLD" ] && bash "$_SCAFFOLD" --topic "$TOPIC" --dry-run 2>&1 | sed 's/^/DRY RUN: /'
  echo "DRY RUN: on gate PASS, would dispatch /CJ_implement-from-spec → /CJ_qa-work-item (with DEFER_AUDIT: true — audit deferred to post-sync) as SILENT leaf Agent subagents (no AUQ)"
  echo "DRY RUN: would make an idempotent pre-doc-sync commit (Step 4.4; skip on a clean tree), then run /CJ_document-release INLINE (Step 5.5 doc-sync; halt-on-red), then ONE combined read-only post-sync audit subagent (Step 5.6: /CJ_doc_audit + /CJ_test_audit), then the QA-audit checkpoint (Step 4.5) on that POST-sync report"
  echo "DRY RUN: would run the portability-audit gate (halt-on-red) before /ship"
  echo "DRY RUN: would run /ship INLINE with the diff-review AUQ suppressed, opening a PR, then STOP at the PR"
  echo "DRY RUN: writes nothing. Re-run without --dry-run to execute."
  echo "Suggested resume: /CJ_goal_task \"$TOPIC\""
  jq -nc --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" --arg run_id "$RUN_ID" \
    --arg end_state "dry_run_preview" --arg topic "$TOPIC" \
    '{ts:$ts,run_id:$run_id,end_state:$end_state,topic:$topic,parent_skill:"CJ_goal_task"}' \
    >> "$TELEMETRY" 2>/dev/null || true
  exit 0
fi
```

(The worktree phase already ran in SKILL.md's Default-worktree block before this
file is read; `--dry-run` was forwarded there too, so no worktree was created.)

If a no-arg invocation finds no resume state AND no topic: HALT
`halted_at_no_arg` ("Error: a task description is required.") on stderr.

## Step 1.5: Load + validate resume state (validate-before-skip)

Read the resume state file if it exists. The cardinal rule: **never trust
`last_completed_phase` blindly** — validate the recorded SHA and PR against the
live tree first, and restart the affected phase on any mismatch.

```bash
LAST_PHASE="none"; PHASE_SHA=""; WORK_ITEM_DIR=""; PR_NUMBER=""
if [ -f "$RESUME_STATE" ]; then
  LAST_PHASE=$(sed -n 's/^last_completed_phase=//p' "$RESUME_STATE" | head -1)
  PHASE_SHA=$(sed -n 's/^phase_sha=//p' "$RESUME_STATE" | head -1)
  WORK_ITEM_DIR=$(sed -n 's/^work_item_dir=//p' "$RESUME_STATE" | head -1)
  PR_NUMBER=$(sed -n 's/^pr_number=//p' "$RESUME_STATE" | head -1)
  [ -z "$TOPIC" ] && TOPIC=$(sed -n 's/^topic=//p' "$RESUME_STATE" | head -1)
  [ -z "$LAST_PHASE" ] && LAST_PHASE="none"
fi

# A no-arg invocation with no resume state + no topic is a usage halt.
if [ "$LAST_PHASE" = "none" ] && [ -z "$TOPIC" ]; then
  echo "Error: a task description is required." >&2
  jq -nc --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" --arg run_id "$RUN_ID" \
    --arg end_state "halted_at_no_arg" '{ts:$ts,run_id:$run_id,end_state:$end_state,parent_skill:"CJ_goal_task"}' \
    >> "$TELEMETRY" 2>/dev/null || true
  exit 1
fi

# Validation 1 — recorded SHA must be an ancestor of (or equal to) current HEAD.
if [ "$LAST_PHASE" != "none" ] && [ -n "$PHASE_SHA" ]; then
  if ! git -C "$_REPO_ROOT" merge-base --is-ancestor "$PHASE_SHA" HEAD 2>/dev/null; then
    echo "[resume] recorded SHA stale (tree moved); restarting the '$LAST_PHASE' phase instead of skipping ahead."
    case "$LAST_PHASE" in
      ship) LAST_PHASE="qa" ;;
      qa)   LAST_PHASE="impl" ;;
      impl) LAST_PHASE="scaffold" ;;
      scaffold) LAST_PHASE="none" ;;
    esac
  fi
fi

# Validation 2 — any recorded PR must still resolve to OPEN.
if [ "$LAST_PHASE" = "ship" ] && [ -n "$PR_NUMBER" ]; then
  _COMMON="$_REPO_ROOT/scripts/cj-goal-common.sh"
  _PR_OUT=$(bash "$_COMMON" --phase pr-check --mode task 2>/dev/null)
  _PR_STATE=$(printf '%s\n' "$_PR_OUT" | sed -n 's/^PR_STATE=//p')
  case "$_PR_STATE" in
    MERGED|CLOSED)
      echo "Already shipped: PR #$PR_NUMBER is $_PR_STATE. Nothing to do (end_state=already_shipped)."
      jq -nc --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" --arg run_id "$RUN_ID" \
        --arg end_state "already_shipped" --arg pr "$PR_NUMBER" --arg topic "$TOPIC" \
        '{ts:$ts,run_id:$run_id,end_state:$end_state,pr_url:$pr,topic:$topic,parent_skill:"CJ_goal_task"}' \
        >> "$TELEMETRY" 2>/dev/null || true
      exit 0
      ;;
    OPEN)
      echo "Resume: PR #$PR_NUMBER still OPEN; the run already reached the PR-stop (end_state=green_pr_opened)."
      ;;
    *)
      echo "[resume] could not confirm PR #$PR_NUMBER OPEN (state='$_PR_STATE'); restarting the ship phase."
      LAST_PHASE="qa"
      ;;
  esac
fi
```

After Step 1.5, `LAST_PHASE` is the validated resume point. The phase dispatch
below skips only phases at or before a *validated* `LAST_PHASE`.

## Step 1.9: Isolation gate (the worktree phase is MANDATORY — enforced before any source write)

The silent build (Step 2 scaffold + Step 3 implement) **writes to repo source** (a
new work-item dir and code). Dispatching it from an un-isolated or dirty checkout
means an in-place mutation of unrelated work — the D000024 bug class. The SKILL.md
"Default-worktree" block is supposed to have already created (or detected) a
`cj-task-*` worktree; this gate **verifies** that invariant held and **refuses to
proceed** otherwise. This is **not a judgment call** — mirrors the
`/CJ_goal_feature` Step 1.9 gate.

```bash
# Re-resolve cj-worktree-init.sh: repo-local first, then deployed _cj-shared home.
_SHARED="${CJ_SHARED_SCRIPTS:-$HOME/.claude/_cj-shared/scripts}"
_REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo "")
_HELPER=""
if [ -n "$_REPO_ROOT" ] && [ -x "$_REPO_ROOT/scripts/cj-worktree-init.sh" ]; then
  _HELPER="$_REPO_ROOT/scripts/cj-worktree-init.sh"
elif [ -x "$_SHARED/cj-worktree-init.sh" ]; then
  _HELPER="$_SHARED/cj-worktree-init.sh"
fi

RESUME_DIR="$_REPO_ROOT/.cj-goal-task"
mkdir -p "$RESUME_DIR" 2>/dev/null || true

if [ -z "$_HELPER" ]; then
  TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  cat >> "$RESUME_DIR/.resume.log" <<EOF
- $TS [task-not-isolated] worktree helper unreachable (repo-local + deployed _cj-shared both absent); cannot verify clean+isolated before the source-writing build. HALT.
  next_action=Restore scripts/cj-worktree-init.sh or re-run 'skills-deploy install'; then re-run.
  resume_cmd=/CJ_goal_task "$TOPIC"
  pr_url=N/A
  raw_output_path=N/A
EOF
  echo "Why it stopped: the worktree-isolation helper is unreachable, so a clean+isolated checkout can't be verified before the build writes to source."
  echo "Next: /CJ_goal_task \"$TOPIC\""
  jq -nc --arg ts "$TS" --arg run_id "$RUN_ID" --arg end_state "halted_at_not_isolated" \
    --arg topic "$TOPIC" '{ts:$ts,run_id:$run_id,end_state:$end_state,topic:$topic,parent_skill:"CJ_goal_task"}' \
    >> "$TELEMETRY" 2>/dev/null || true
  exit 1
fi

# Forward ONLY --no-worktree, and only if the operator passed it (re-read the
# RUN_ID-scoped marker — $NO_WORKTREE does not persist across bash tool calls).
if [ -f "$HOME/.gstack/analytics/CJ_goal_task-runs/$RUN_ID/.operator-no-worktree" ]; then
  VERDICT_JSON=$("$_HELPER" --caller task --assert-isolated --no-worktree 2>&1) && _GRC=0 || _GRC=$?
else
  VERDICT_JSON=$("$_HELPER" --caller task --assert-isolated 2>&1) && _GRC=0 || _GRC=$?
fi
VERDICT_STATE=$(echo "$VERDICT_JSON" | jq -r '.state' 2>/dev/null || echo "")

if [ "$_GRC" -ne 0 ]; then
  TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  cat >> "$RESUME_DIR/.resume.log" <<EOF
- $TS [task-not-isolated] isolation gate verdict=$VERDICT_STATE — checkout is not clean+isolated; refusing to run the source-writing build (D000024 class).
  next_action=Run /CJ_goal_task from a clean main checkout (it auto-creates a cj-task-* worktree), or from a clean feature branch / worktree; or pass --no-worktree on a clean checkout.
  resume_cmd=/CJ_goal_task "$TOPIC"
  pr_url=N/A
  raw_output_path=N/A
EOF
  echo "Why it stopped: the checkout is not clean+isolated (verdict: $VERDICT_STATE), so the build would write on top of unrelated work."
  echo "Next: /CJ_goal_task \"$TOPIC\"  (from a clean main checkout — it creates the worktree automatically)"
  jq -nc --arg ts "$TS" --arg run_id "$RUN_ID" --arg end_state "halted_at_not_isolated" \
    --arg topic "$TOPIC" '{ts:$ts,run_id:$run_id,end_state:$end_state,topic:$topic,parent_skill:"CJ_goal_task"}' \
    >> "$TELEMETRY" 2>/dev/null || true
  exit 1
fi

echo "Isolation gate: verdict=$VERDICT_STATE — clean+isolated; proceeding to the complexity gate + silent build."
```

Only on a green (`isolated`, exit 0) verdict does control proceed to Step 2.

## Step 2: Hard complexity gate + scaffold the T-task (skip if validated LAST_PHASE ∈ {scaffold, impl, qa, ship})

This step REPLACES the `/CJ_goal_feature` office-hours design phase. There is NO
interactive AUQ: the complexity gate is automatic, and on PASS the scaffold runs
silently. Both live in `scripts/cj-task-scaffold.sh` — the gate runs FIRST (so a
refused topic scaffolds nothing), then the script ID-picks a T-ID and writes a
`type: task` work-item from the topic.

Resolve + run the scaffold helper:

```bash
_SCAFFOLD=""
for p in "$_REPO_ROOT/skills/CJ_goal_task/scripts/cj-task-scaffold.sh" \
         "$HOME/.claude/skills/CJ_goal_task/scripts/cj-task-scaffold.sh"; do
  [ -x "$p" ] && { _SCAFFOLD="$p"; break; }
done
if [ -z "$_SCAFFOLD" ]; then
  TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  echo "[scaffold] ERROR: cj-task-scaffold.sh unreachable (repo-local + deployed both absent)."
  cat >> "$RESUME_DIR/.resume.log" <<EOF
- $TS [scaffold-red] cj-task-scaffold.sh unreachable; cannot scaffold the task work-item.
  next_action=Re-run 'skills-deploy install' to restore the skill's scripts; then re-run.
  resume_cmd=/CJ_goal_task "$TOPIC"
  pr_url=N/A
  raw_output_path=N/A
EOF
  jq -nc --arg ts "$TS" --arg run_id "$RUN_ID" --arg end_state "halted_at_scaffold" \
    --arg topic "$TOPIC" '{ts:$ts,run_id:$run_id,end_state:$end_state,topic:$topic,parent_skill:"CJ_goal_task"}' \
    >> "$TELEMETRY" 2>/dev/null || true
  exit 1
fi
```

Run it ONLY when the build has not started (`LAST_PHASE = none`); otherwise the
work-item already exists and `$WORK_ITEM_DIR` is the validated resume value.

```bash
if [ "$LAST_PHASE" = "none" ]; then
  SC_OUT=$(bash "$_SCAFFOLD" --topic "$TOPIC" 2>&1) && SC_RC=0 || SC_RC=$?
  printf '%s\n' "$SC_OUT" > "$RAW_DIR/scaffold-raw.txt" 2>/dev/null || true
  SC_RESULT=$(printf '%s\n' "$SC_OUT" | sed -n 's/^CJ_TASK_RESULT=//p' | head -1)

  if [ "$SC_RESULT" = "too-complex" ]; then
    # ---- THE HARD COMPLEXITY GATE refused. HALT halted_at_too_complex. ----
    TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    SC_SUGGEST=$(printf '%s\n' "$SC_OUT" | sed -n 's/^SUGGEST=//p' | head -1)
    SC_REASON=$(printf '%s\n' "$SC_OUT" | sed -n 's/^REASON=//p' | head -1)
    cat >> "$RESUME_DIR/.resume.log" <<EOF
- $TS [task-too-complex] $SC_REASON
  next_action=This task is not small/mechanical enough for /CJ_goal_task. Use $SC_SUGGEST instead.
  resume_cmd=$SC_SUGGEST "$TOPIC"
  pr_url=N/A
  raw_output_path=$RAW_DIR/scaffold-raw.txt
EOF
    echo "Why it stopped: the complexity gate refused this topic — $SC_REASON"
    echo "Next: $SC_SUGGEST \"$TOPIC\"  (the right verb for this kind of work)"
    jq -nc --arg ts "$TS" --arg run_id "$RUN_ID" --arg end_state "halted_at_too_complex" \
      --arg topic "$TOPIC" --arg suggest "$SC_SUGGEST" \
      '{ts:$ts,run_id:$run_id,end_state:$end_state,topic:$topic,suggest:$suggest,parent_skill:"CJ_goal_task"}' \
      >> "$TELEMETRY" 2>/dev/null || true
    exit 1
  fi

  if [ "$SC_RC" -ne 0 ] || [ "$SC_RESULT" != "ok" ]; then
    # ---- scaffold error (template missing / write failure). HALT [scaffold-red]. ----
    TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    SC_REASON=$(printf '%s\n' "$SC_OUT" | sed -n 's/^REASON=//p' | head -1)
    cat >> "$RESUME_DIR/.resume.log" <<EOF
- $TS [scaffold-red] cj-task-scaffold.sh failed (rc=$SC_RC result=$SC_RESULT): ${SC_REASON:-see raw output}
  next_action=Inspect $RAW_DIR/scaffold-raw.txt; fix the cause (e.g. missing tracker-task.md template); re-run.
  resume_cmd=/CJ_goal_task "$TOPIC"
  pr_url=N/A
  raw_output_path=$RAW_DIR/scaffold-raw.txt
EOF
    echo "Why it stopped: the task scaffold failed (${SC_REASON:-see raw output})."
    echo "Next: /CJ_goal_task \"$TOPIC\""
    jq -nc --arg ts "$TS" --arg run_id "$RUN_ID" --arg end_state "halted_at_scaffold" \
      --arg topic "$TOPIC" '{ts:$ts,run_id:$run_id,end_state:$end_state,topic:$topic,parent_skill:"CJ_goal_task"}' \
      >> "$TELEMETRY" 2>/dev/null || true
    exit 1
  fi

  # ---- scaffold OK: parse the handoff block, record the scaffold boundary. ----
  WORK_ITEM_DIR=$(printf '%s\n' "$SC_OUT" | sed -n 's/^WORK_ITEM_DIR=//p' | head -1)
  T_ID=$(printf '%s\n' "$SC_OUT" | sed -n 's/^T_ID=//p' | head -1)
  echo "[scaffold] complexity gate PASSED; scaffolded $T_ID at $WORK_ITEM_DIR"

  mkdir -p "$RESUME_DIR"
  HEAD_SHA=$(git -C "$_REPO_ROOT" rev-parse HEAD 2>/dev/null)
  _TMP=$(mktemp "$RESUME_DIR/.state.XXXXXX")
  cat > "$_TMP" <<EOF
last_completed_phase=scaffold
phase_sha=$HEAD_SHA
work_item_dir=$WORK_ITEM_DIR
pr_number=$PR_NUMBER
topic=$TOPIC
EOF
  mv "$_TMP" "$RESUME_STATE"
else
  echo "[scaffold] resume: work-item already scaffolded at $WORK_ITEM_DIR (skipping scaffold)."
fi
```

The work-item is workbench-tracked source. `.cj-goal-task/` is gitignored scratch;
the work-item dir itself IS committed (it ships in the PR).

## Step 3: implement (leaf Agent subagent — skip if validated LAST_PHASE ∈ {impl, qa, ship})

Dispatch `/CJ_implement-from-spec` via the **Agent** tool (`subagent_type:
general-purpose`) against `$WORK_ITEM_DIR` in **auto-equivalent** mode (subagents
have no AUQ tool):

```
ROLE: /CJ_implement-from-spec runner for /CJ_goal_task (silent — no AUQ).
TASK: Invoke /CJ_implement-from-spec on the work-item dir in <inputs>, auto mode.
If you hit a sensitive-surface AUQ you cannot answer in subagent context, halt and
return a non-green RESULT (do NOT silently proceed). Return the RESULT line
verbatim: RESULT: STATUS=<...>; FILES_CHANGED=<n>.
<inputs>WORK_ITEM_DIR: <absolute $WORK_ITEM_DIR></inputs>
```

If the implement subagent crashed (no RESULT line) or returned a non-green
status, **HALT** with `[impl-red]` (end_state `halted_at_impl`, `pr_url=N/A`,
`raw_output_path=$RAW_DIR/impl-raw.txt`) + the 3-line terminal block + a telemetry
line. resume_cmd is `/CJ_goal_task "$TOPIC"`.

On green: record the impl boundary (atomic-write with
`last_completed_phase=impl` + a fresh `phase_sha`).

## Step 4: qa (ALWAYS re-dispatched on resume)

Do NOT phase-skip QA when the validated `LAST_PHASE ∈ {qa, ship}` — a same-SHA
resume must re-verify. Always re-dispatch `/CJ_qa-work-item` here; `qa.md`'s
receipt-based re-validation keeps that cheap (same contract as `/CJ_goal_feature`
Step 3.3).

Dispatch `/CJ_qa-work-item` via the **Agent** tool against `$WORK_ITEM_DIR`. The
dispatch prompt carries the literal directive `DEFER_AUDIT: true` so QA defers its
three-stage audit (qa.md Step 8.6c/8.6d) — the orchestrator runs that audit ONCE
at the authoritative post-sync point (Step 5.6). QA still runs its 8.6a/8.6b
overlay writes inline and returns `AUDITS=deferred` with NO `AUDIT_FINDINGS`
block:

```
ROLE: /CJ_qa-work-item runner for /CJ_goal_task (silent — no AUQ).
DEFER_AUDIT: true
TASK: Invoke /CJ_qa-work-item on the work-item dir in <inputs>. A `type: task`
work-item runs its test-plan rows as smoke-equivalent. The literal DEFER_AUDIT:
true directive above tells QA to run its Step 8.6a/8.6b overlay writes inline but
DEFER the 8.6c/8.6d three-stage audit (the orchestrator runs the post-sync audit
itself at Step 5.6). Return the RESULT line verbatim — including the AUDITS= field
(it will read AUDITS=deferred,spec_updates:<...>); do NOT expect an
AUDIT_FINDINGS block on the deferred path:
RESULT: SMOKE=<...>; PHASE2_GATES=<...>; AUDITS=deferred,spec_updates:<...>
<inputs>WORK_ITEM_DIR: <absolute $WORK_ITEM_DIR></inputs>
```

If QA returns red: **HALT** with `[qa-red]` (re-use the existing CJ_qa-work-item
halt marker), end_state `halted_at_qa`, `pr_url=N/A`,
`raw_output_path=$RAW_DIR/qa-raw.txt`, + the 3-line block + telemetry.

On green: record the qa boundary, then continue to Step 4.4 (the pre-doc-sync
commit), then Step 5.5 (Doc-sync), then Step 5.6 (the post-sync audit), then
Step 4.5 (the QA-audit checkpoint, fed by the post-sync audit), then Step 5.7
(portability), then Step 6 (/ship).

## Step 4.4: Pre-doc-sync commit (NEW — automated, idempotent; closes the F000038 gotcha)

The implement + QA leaf subagents WRITE the QA-green code and the qa.md 8.6a/8.6b
spec-overlay refreshes but do NOT commit them; `/ship` (the committer) runs after
doc-sync. `/CJ_document-release` (Step 5.5) hard-refuses on an uncommitted NON-DOC
change (`[doc-sync-red]`). This NEW step commits the QA-green tree so doc-sync
never hits the uncommitted-non-doc refusal during an autonomous build.

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
  git -C "$_REPO_ROOT" commit -m "task: $_SUBJ (QA-green; pre-doc-sync commit)" >/dev/null
  echo "[pre-doc-sync-commit] committed the QA-green code + 8.6a/8.6b overlay writes (clean tree for doc-sync)."
fi
```

(`/ship` at Step 6 adds the VERSION/CHANGELOG bump as a follow-on commit.) Only
after a clean tree is established does control proceed to Step 5.5 (doc-sync).

## Step 5.5: Doc-sync (INLINE — CJ_document-release wrapper)

Identical to `/CJ_goal_feature` Step 5.5. Doc-sync runs **before** the post-sync
audit + the Step 4.5 QA-audit checkpoint (F000064 reorder), so the checkpoint
decides on the docs that will actually ship. Invoke `/CJ_document-release` via the
**Skill** tool with NO `--docs` flag (full audit). It returns one of:

- `RESULT: green` — ran clean and auto-committed doc-only changes. Continue.
- `RESULT: green-noop` — ran clean, no doc changes needed. Continue.
- `RESULT: red; HALT_MARKER=[doc-sync-red]` — non-green. **HALT** `halted_at_doc_sync`.
- `RESULT: red; HALT_MARKER=[doc-sync-no-config]` — registry missing/invalid. **HALT** `halted_at_doc_sync_no_config`.
- `RESULT: red; HALT_MARKER=[doc-sync-non-doc-write]` — upstream wrote outside the
  whitelist. **HALT** `halted_at_doc_sync_non_doc_write`.

Each halt writes the family contract journal entry (`next_action=` / `resume_cmd=`
/ `pr_url=N/A` / `raw_output_path=$RAW_DIR/doc-sync-raw.txt`) + a telemetry line
with the matching end_state, then exits. Only on green / green-noop does control
proceed to Step 5.6 (the post-sync audit), then Step 4.5 (the QA-audit
checkpoint), then the portability gate.

## Step 5.6: Post-sync doc/test audit (NEW — ONE combined read-only subagent)

Now that doc-sync has folded its doc updates into the PR, run the three-stage
doc/test audit ONCE, at the authoritative **post-sync** point. This is the audit
QA deferred (via `DEFER_AUDIT: true`, Step 4) — the orchestrator runs it itself
here so the Step 4.5 checkpoint decides on the docs that will actually ship.

Dispatch ONE combined depth-2 fresh-context subagent via the **Agent** tool
(`subagent_type: general-purpose`) that runs BOTH `/CJ_doc_audit` and
`/CJ_test_audit` over the post-sync tree. It is **READ-ONLY** — it reports, it
writes NO overlay/doc fixes (preserving the "everything in the PR is
post-sync-clean" invariant; a needed fix surfaces at the checkpoint, where the
operator Halts and re-runs so the fix lands pre-sync on the next pass). Dispatch
ONE subagent, not two — the audit skills' standalone contract lets one
fresh-context subagent judge both audits, and two would double the cost this
mechanism exists to avoid:

```
ROLE: combined post-sync doc/test auditor for /CJ_goal_task (READ-ONLY — report, do not fix).
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
digest and capture the fenced `AUDIT_FINDINGS` block for the checkpoint. This step
is a **pure read** (records NO phase boundary, writes no fixes), so a resume
re-runs it. If the audit subagent crashes (no parseable report), treat it as
`AUDITS=doc:audit-error,test:audit-error` and surface the raw output at the
checkpoint — do NOT halt here (the checkpoint owns the decision).

## Step 4.5: QA-audit findings checkpoint (ALWAYS — the one AUQ in the chain; consumes the POST-sync audit)

Identical contract to `/CJ_goal_feature` Step 3.4 (the canonical gate row is
`qa-audit`, order 45, in `spec/test-spec-custom.md`). Immediately after the Step 5.6
post-sync audit returns, surface the checkpoint on its report (NOT a pre-sync
audit). The `AUDITS=` digest + the fenced `AUDIT_FINDINGS` block come from Step
5.6's combined post-sync subagent (the two spec-overlay updates rode the QA RESULT
at 8.6a/8.6b; the doc audit + test audit are now the post-sync results). Surface
an AskUserQuestion ALWAYS — findings or not:

> QA-audit checkpoint for {WORK_ITEM_ID} — AUDITS=doc:<...>,test:<...> (post-sync)
>
> {AUDIT_FINDINGS block, verbatim}
>
> Options:
> - Continue — proceed to the portability gate + /ship
> - Halt — stop the run here; I want to act on these findings first

**On Continue:** if either audit reported findings, append the auditable
waiver line `- $TS [qa-audit-waived] operator continued past audit findings
at the post-QA (post-sync) checkpoint: AUDITS=...` to the work-item tracker
journal (a fully-green digest writes nothing). Then, since this waiver line is an
uncommitted NON-DOC tracker change, commit it (`git add -A && git commit`, or
no-op on a clean tree) so the portability gate + `/ship` see a clean tree.
Continue to Step 5.7 (portability).

**On Halt:** append `- $TS [qa-audit-declined] operator halted at the
post-QA (post-sync) audit checkpoint.` + the family-contract fields
(`next_action=` act on the findings, then resume — QA re-runs, doc-sync + the
post-sync audit re-run, and the checkpoint re-fires;
`resume_cmd=/CJ_goal_task "$TOPIC"`; `pr_url=N/A`;
`raw_output_path=$RAW_DIR/post-sync-audit-raw.txt`) to `$RESUME_DIR/.resume.log`,
write a telemetry line with end_state `halted_at_qa_audit`, and exit 1. The
checkpoint is a pure read of the post-sync audit (no phase boundary recorded).

## Step 5.7: Portability gate (INLINE — halt-on-red before /ship)

Identical to `/CJ_goal_feature` Step 5.7 (the audit is verb-independent; `--mode
task` is telemetry-only). Call `cj-goal-common.sh --phase portability-audit
--mode task`:

```bash
_COMMON="$_REPO_ROOT/scripts/cj-goal-common.sh"
_PORT_RESULT="skipped"; _PORT_VERDICT=""
if [ -x "$_COMMON" ]; then
  _PORT_OUT=$(bash "$_COMMON" --phase portability-audit --mode task 2>/dev/null) && _PORT_RC=0 || _PORT_RC=$?
  _PORT_RESULT=$(printf '%s\n' "$_PORT_OUT" | sed -n 's/^PHASE_RESULT=//p' | head -1)
  _PORT_VERDICT=$(printf '%s\n' "$_PORT_OUT" | sed -n 's/^VERDICT_LINE=//p' | head -1)
  [ -z "$_PORT_RESULT" ] && _PORT_RESULT="skipped"
else
  echo "[portability] cj-goal-common.sh unreachable — skipping the portability gate (best-effort)"
fi

if [ "$_PORT_RESULT" = "ok" ]; then
  mkdir -p "$_REPO_ROOT/.cj-goal-task" 2>/dev/null || true
  printf '### Portability\n\n%s\n' "$_PORT_VERDICT" > "$_REPO_ROOT/.cj-goal-task/portability-verdict.md"
  echo "[portability] $_PORT_VERDICT — continuing to /ship"
elif [ "$_PORT_RESULT" = "skipped" ]; then
  echo "[portability] gate skipped (engine absent) — continuing to /ship (best-effort, not halting)"
else
  # PHASE_RESULT=findings → HALT halted_at_portability (BEFORE /ship; no PR).
  TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  printf '%s\n' "$_PORT_OUT" > "$RAW_DIR/portability-raw.txt" 2>/dev/null || true
  cat >> "$RESUME_DIR/.resume.log" <<EOF
- $TS [portability-red] --phase portability-audit returned findings; halt class halted_at_portability. $_PORT_VERDICT
  next_action=A touched skill declares a portability tier it does not honor. Relabel its 'portability' (or add to 'portability_requires') in skills-catalog.json. Then re-run.
  resume_cmd=/CJ_goal_task "$TOPIC"
  pr_url=N/A
  raw_output_path=$RAW_DIR/portability-raw.txt
EOF
  echo "Why it stopped: the portability audit found a skill that declares a tier it does not honor; the gate blocks the PR until it is reconciled."
  echo "Next: relabel the skill's 'portability' in skills-catalog.json, then /CJ_goal_task \"$TOPIC\""
  jq -nc --arg ts "$TS" --arg run_id "$RUN_ID" --arg end_state "halted_at_portability" \
    --arg topic "$TOPIC" '{ts:$ts,run_id:$run_id,end_state:$end_state,topic:$topic,parent_skill:"CJ_goal_task"}' \
    >> "$TELEMETRY" 2>/dev/null || true
  exit 1
fi
```

Only on `ok` or `skipped` does control proceed to Step 6.

## Step 6: /ship (INLINE — diff-review AUQ suppressed; opens a PR)

Invoke `/ship` via the **Skill** tool with the diff-review AUQ **suppressed**.
The opened PR is the human review (PR-stop only), so `/ship`'s mid-flight
diff-review AUQ is relocated to the PR on GitHub. This is NOT a bypass of review.

> Invoke /ship with its pre-PR diff-review AUQ suppressed (the opened PR is the
> review). /ship runs its pre-landing review, bumps VERSION, updates CHANGELOG,
> commits, pushes, and creates a PR. It MUST stop after creating the PR — do NOT
> merge, do NOT run any deploy step.

`/ship` still surfaces its own native pre-flight halts (a red pre-landing review,
a dirty-tree refusal, a version-queue collision) — those pass through.

- If `/ship` declines or cannot open a PR: **HALT** with `[ship-declined]`
  (end_state `halted_at_ship`; `pr_url=` set if a PR was created before the
  decline, else `N/A`) + the 3-line block + telemetry.
- On green (PR created): capture the PR number/URL into `$PR_NUMBER` / `$PR_URL`,
  record the ship boundary (`last_completed_phase=ship`, `pr_number=$PR_NUMBER`,
  fresh `phase_sha`), and continue to Step 6.6.

There is **no automatic merge and no `/land-and-deploy`** — the pipeline STOPs at
the PR. The merge + deploy are separate human steps.

## Step 6.6: Surface registered-doc + portability verdicts into the PR body (best-effort; NEVER halts)

Identical to `/CJ_goal_feature` Step 4.6. The Step 5.5 doc-sync wrapper wrote the
registered-doc verdict block to `.cj-goal-task/registered-doc-verdicts.md` and the
Step 5.7 gate wrote `.cj-goal-task/portability-verdict.md`. Read both scratch
files and `gh pr edit <PR#>` to insert-or-replace a `### Registered-doc
requirements` + `### Portability` subsection under the PR body's `##
Documentation` section. Best-effort: a failed `gh pr edit` (or a missing scratch
file) logs a one-line note and control proceeds to Step 7. There is NO upstream
`/ship` modification.

```bash
_VERDICT_FILE="$_REPO_ROOT/.cj-goal-task/registered-doc-verdicts.md"
_PORT_VERDICT_FILE="$_REPO_ROOT/.cj-goal-task/portability-verdict.md"
if [ -n "$PR_NUMBER" ] && { [ -f "$_VERDICT_FILE" ] || [ -f "$_PORT_VERDICT_FILE" ]; }; then
  _BODY=$(gh pr view "$PR_NUMBER" --json body -q .body 2>/dev/null || echo "")
  _VERDICTS=""; [ -f "$_VERDICT_FILE" ] && _VERDICTS=$(cat "$_VERDICT_FILE")
  _PORT=""; [ -f "$_PORT_VERDICT_FILE" ] && _PORT=$(cat "$_PORT_VERDICT_FILE")
  if [ -n "$_VERDICTS" ] && [ -n "$_PORT" ]; then
    _INSERT=$(printf '%s\n\n%s' "$_VERDICTS" "$_PORT")
  else
    _INSERT="${_VERDICTS}${_PORT}"
  fi
  _NEW_BODY=$(printf '%s\n' "$_BODY" | awk '
    /^### Registered-doc requirements/ {skip=1; next}
    /^### Portability/ {skip=1; next}
    skip && /^#{2,3} / {skip=0}
    !skip {print}
  ')
  if printf '%s\n' "$_NEW_BODY" | grep -q '^## Documentation'; then
    _NEW_BODY=$(printf '%s\n' "$_NEW_BODY" | awk -v v="$_INSERT" '
      {print}
      /^## Documentation/ && !done {print ""; print v; done=1}
    ')
  else
    _NEW_BODY=$(printf '%s\n\n## Documentation\n\n%s\n' "$_NEW_BODY" "$_INSERT")
  fi
  if gh pr edit "$PR_NUMBER" --body "$_NEW_BODY" 2>/dev/null; then
    echo "[registered-doc] surfaced verdicts into PR #$PR_NUMBER body"
  else
    echo "[registered-doc] gh pr edit failed for PR #$PR_NUMBER — verdicts remain in the run output + scratch files (best-effort)"
  fi
else
  echo "[registered-doc] no verdict scratch file (or no PR#) — skipping PR-body surfacing (best-effort)"
fi
```

Control always proceeds to Step 7 — this step has no halt path.

## Step 7: STOP at the PR

The pipeline is complete the moment `/ship` opens the PR. The end-state is
`green_pr_opened`. Do NOT advance to merge or deploy.

## Step 8: Final journal + telemetry + worktree cleanup + summary

If a work-item tracker exists (`$WORK_ITEM_DIR`), append a final journal entry:

```
- <ISO ts> [task-pr-opened] $T_ID PR #<NNN>
  pr_url=$PR_URL
```

Append one telemetry line to `~/.gstack/analytics/CJ_goal_task.jsonl`:

```bash
jq -nc \
  --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  --arg run_id "$RUN_ID" \
  --arg work_item_dir "$WORK_ITEM_DIR" \
  --arg end_state "green_pr_opened" \
  --arg pr_url "$PR_URL" \
  --arg topic "$TOPIC" \
  '{ts:$ts,run_id:$run_id,work_item_dir:$work_item_dir,end_state:$end_state,pr_url:$pr_url,topic:$topic,parent_skill:"CJ_goal_task"}' \
  >> "$TELEMETRY"
```

### Step 8.5: Worktree cleanup (best-effort, post-PR; NEVER halts)

Sweep landed cj-* worktrees + refresh root main via the shared cleanup phase
(T000036), the teardown mirror of the Step 1 worktree-create phase. **This task
run's OWN worktree is never removed** — it is the current dir AND its PR is still
OPEN. Strictly best-effort: a failed sweep logs a note and the run still ends
`green_pr_opened`.

```bash
_COMMON="$_REPO_ROOT/scripts/cj-goal-common.sh"
_CLEAN_OUT=""
[ -x "$_COMMON" ] && _CLEAN_OUT=$(bash "$_COMMON" --phase cleanup --mode task 2>/dev/null || true)
_CLEAN_REMOVED=$(printf '%s\n' "$_CLEAN_OUT" | sed -n 's/^REMOVED=//p' | head -1)
_CLEAN_REFRESH=$(printf '%s\n' "$_CLEAN_OUT" | sed -n 's/^ROOT_REFRESH=//p' | head -1)
echo "[cleanup] worktree janitor: removed ${_CLEAN_REMOVED:-0}, root main refresh=${_CLEAN_REFRESH:-skipped}"
```

Print the summary:

```
PIPELINE COMPLETE: end_state=green_pr_opened — STOPPED at the PR for human review.

Run ID:     $RUN_ID
Topic:      $TOPIC
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

## Resilience contract

- **Idempotent.** A verbatim (or no-arg) re-run on the same branch resumes from
  the validated `last_completed_phase`. A re-scaffold with the same topic reuses
  the existing work-item dir (footer-keyed).
- **Validate-before-skip.** The recorded per-phase SHA must be an ancestor of (or
  equal to) current HEAD, and any recorded PR must still resolve to OPEN, before a
  phase is skipped. A stale SHA restarts the affected phase; a MERGED/CLOSED PR is
  an `already_shipped` exit.
- **The complexity gate is a hard refusal.** A topic that needs design or
  investigation HALTs `halted_at_too_complex` and routes to the right verb — it
  never scaffolds.
- **QA always re-runs on resume** (never phase-skipped).
- **Halt-on-red end-to-end.** Any red status from scaffold, implement, qa,
  doc-sync, portability, or `/ship` stops the chain.
- **PR-stop.** No automatic merge, no `/land-and-deploy`. The PR is the human gate.
- **Depth ≤ 2.** implement / qa are leaf subagents; the scaffold is bash and
  `/ship` runs inline. No subagent-spawns-subagent path.
