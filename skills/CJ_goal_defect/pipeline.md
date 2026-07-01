# /CJ_goal_defect — Orchestration

Single-keystroke orchestrator from a plain `"<bug description>"` → deployed
fix. A ~80% reshape of `/CJ_goal_investigate` v1.1's flat pipeline; the
substantive divergence is the front door: `CJ_goal_defect` has NO defect
resolver. Every run scaffolds a throwaway `.inbox/<slug>/DRAFT.md` (no D-ID),
root-causes it under the Iron-Law, and mints a D-ID only at promotion. The
Iron-Law gate, isolation gate, promotion protocol, artifact writes, chain
dispatch, halt taxonomy, and telemetry are inherited from investigate v1.1.

Read [SKILL.md](SKILL.md) first for path resolution, error handling, the
halt-taxonomy summary, and the idempotency contract. Then follow the steps
below.

Canonical gate sequence: `spec/test-spec.md` (the cross-cj_goal verification contract;
enforced by `validate.sh` Check 24). The gates this pipeline halts at are this
mode's subset of that one declared sequence.

---

## Step 1: Parse arguments

Accept the following arg shapes:

```
/CJ_goal_defect "<bug description>"
/CJ_goal_defect --dry-run "<bug description>"
/CJ_goal_defect --no-worktree "<bug description>"
/CJ_goal_defect --verbose "<bug description>"          # optional P2
```

Parser:

```bash
DRY_RUN=""
VERBOSE=""
NO_WORKTREE=""
ARGS=()
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    --verbose) VERBOSE=1 ;;
    --no-worktree) NO_WORKTREE=1 ;;
    *) ARGS+=("$arg") ;;
  esac
done
BUG_DESC="${ARGS[0]:-}"
[ -n "$BUG_DESC" ] || { echo "Error: a bug description is required."; exit 1; }
[ "${#ARGS[@]}" -le 1 ] || { echo "Error: exactly one quoted bug description expected (got: ${ARGS[*]})"; exit 1; }
RUN_ID=$(date +%Y%m%d-%H%M%S)-$$
# Persist the operator --no-worktree opt-out RUN_ID-scoped, in THIS block —
# the only place NO_WORKTREE (set by the parser loop above) and RUN_ID (just
# generated) are both live. Shell vars do NOT persist across bash tool calls
# (CLAUDE.md), so Step 5.0's isolation gate cannot read $NO_WORKTREE; it
# re-reads this marker via the model-carried RUN_ID (same persistence pattern
# as TELEMETRY / RAW_DIR / $TRACKER).
if [ "${NO_WORKTREE:-}" = "1" ]; then
  mkdir -p "$HOME/.gstack/analytics/CJ_goal_defect-runs/$RUN_ID"
  : > "$HOME/.gstack/analytics/CJ_goal_defect-runs/$RUN_ID/.operator-no-worktree"
fi
```

Initialize telemetry + raw-output paths:

```bash
mkdir -p "$HOME/.gstack/analytics/CJ_goal_defect-runs/$RUN_ID"
TELEMETRY="$HOME/.gstack/analytics/CJ_goal_defect.jsonl"
RAW_DIR="$HOME/.gstack/analytics/CJ_goal_defect-runs/$RUN_ID"
```

## Step 2: Scaffold the bug report (`.inbox/<slug>/DRAFT.md`)

Unlike `/CJ_goal_investigate`, there is **no defect resolver** — `CJ_goal_defect`
always starts from raw text with no pre-existing defect dir. Every run captures
a NON-CANONICAL draft under `work-items/defects/.inbox/<slug>/DRAFT.md`. No D-ID
is allocated here; promotion (Step 7.4) mints the D-ID after the Iron-Law gate
passes. Draft dirs are invisible to the canonical defect layout by construction:
no `D######` basename, `DRAFT.md` (not `*_TRACKER.md`).

```bash
_REPO_ROOT=$(git rev-parse --show-toplevel)
DEFECTS_ROOT="$_REPO_ROOT/work-items/defects"
INBOX="$DEFECTS_ROOT/.inbox"

# Slugify the description: lowercase, non-alnum -> _, collapse, cap 50, trim
# trailing _. The lowercasing is load-bearing (NOT cosmetic): the canonical
# defect layout uses a case-sensitive `D000099_*` basename; a draft dir name
# must never start with a `D[0-9]{6}_` prefix. A description like
# "D000099 broke" must NOT slug to `D000099_broke` and masquerade as canonical.
SLUG=$(printf '%s' "$BUG_DESC" | tr '[:upper:]' '[:lower:]' \
       | sed -E 's/[^a-z0-9]+/_/g; s/^_+|_+$//g' \
       | cut -c1-50 \
       | sed -E 's/_+$//')
[ -z "$SLUG" ] && SLUG="untitled"

# Idempotent re-invocation: an existing draft for this slug wins (no dup). The
# timestamp is NOT in the dir name, so the same description maps to the same
# draft deterministically.
DRAFT_DIR="$INBOX/$SLUG"

if [ "${DRY_RUN:-0}" = "1" ]; then
  mkdir -p "$INBOX" 2>/dev/null  # harmless; --dry-run still writes no DRAFT/defect content
  if [ -d "$DRAFT_DIR" ]; then
    echo "DRY RUN: would resume existing draft: $DRAFT_DIR"
  else
    echo "DRY RUN: would create draft: $DRAFT_DIR"
  fi
  echo "DRY RUN: would dispatch /investigate against the draft (Agent subagent, sentinel JSON)"
  echo "DRY RUN: on a populated root cause, would promote to work-items/defects/uncategorized/D<next>_$SLUG"
  echo "DRY RUN: would write RCA + test-plan, then chain /CJ_qa-work-item (DEFER_AUDIT: true — audit deferred to post-sync) → pre-doc-sync commit (Step 8.4; idempotent) → /CJ_document-release (Step 5.5 doc-sync) → ONE combined read-only post-sync audit (Step 5.6: /CJ_doc_audit + /CJ_test_audit) → QA-audit checkpoint (Step 8.5) on that POST-sync report → portability-audit gate (halt-on-red; cj-goal-common.sh --phase portability-audit) → /ship (Gate #2) → /land-and-deploy --suppress-readiness-gate"
  echo "DRY RUN: writes nothing. Re-running the same phrase later would resume this draft; reworded text would create a different draft."
  echo "Suggested resume: /CJ_goal_defect \"$BUG_DESC\""
  # Telemetry: end_state=dry_run_preview (Step 11 schema; write before exit)
  jq -nc --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" --arg run_id "$RUN_ID" \
    --arg end_state "dry_run_preview" --arg slug "$SLUG" \
    '{ts:$ts,run_id:$run_id,end_state:$end_state,slug:$slug,parent_skill:"CJ_goal_defect"}' \
    >> "$TELEMETRY" 2>/dev/null || true
  exit 0
fi

mkdir -p "$INBOX"

if [ -d "$DRAFT_DIR" ]; then
  # Echo the stored description so a wrong-bug slug collision is visible.
  # DRAFT.md stores it as a double-quoted YAML scalar: description: "<escaped>".
  STORED_DESC=$(sed -n 's/^description: "\(.*\)"$/\1/p' "$DRAFT_DIR/DRAFT.md" 2>/dev/null | head -1 \
                | sed 's/\\"/"/g; s/\\\\/\\/g')
  [ -z "$STORED_DESC" ] && STORED_DESC="$BUG_DESC"
  echo "Resuming the temporary draft at $DRAFT_DIR (originally: \"$STORED_DESC\"). Still no D-ID until the root cause is found."
else
  mkdir -p "$DRAFT_DIR"
  NOW=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  # The description is operator free text — it can contain `:`, `#`, `"`, `\`.
  # Emit it as a double-quoted YAML scalar with `\` and `"` escaped and any
  # CR/LF stripped, so the frontmatter is always valid YAML. (The markdown
  # body below is prose, mid-line — raw $BUG_DESC is fine there.)
  DESC_YAML=$(printf '%s' "$BUG_DESC" | tr -d '\r\n' | sed 's/\\/\\\\/g; s/"/\\"/g')
  # DRAFT.md is the ONLY artifact. Mutable; no frontmatter contract; not a
  # TRACKER; deliberately not matched by the canonical defect layout.
  cat > "$DRAFT_DIR/DRAFT.md" <<DRAFT
---
kind: defect-draft
created: $NOW
description: "$DESC_YAML"
---

# Draft: $BUG_DESC

Captured by /CJ_goal_defect on $NOW from a plain bug description.
No D-ID allocated yet. /investigate runs against this draft; on a populated
root cause it is promoted to work-items/defects/<domain>/D000NNN_<slug>/.

## Bug Report
$BUG_DESC
DRAFT
  echo "Captured the bug as a temporary draft at $DRAFT_DIR (no D-ID yet). Re-run this exact phrase to resume it; it becomes a real D-ID only after the root cause is found. Stale drafts are safe to rm -rf — they are not canonical."
fi

# Wire the rest of the pipeline to operate on the draft. IS_DRAFT=1 makes
# Step 3 short-circuit to fresh and Step 7.4 promote before the chain.
IS_DRAFT=1
DEFECT_DIR="$DRAFT_DIR"
DEFECT_ID=""                       # allocated at promotion (Step 7.4)
DRAFT_SLUG="$SLUG"
DRAFT_DESC="$BUG_DESC"
TRACKER="$DRAFT_DIR/DRAFT.md"      # /investigate gets a working file
RCA_PATH=""                        # set at promotion
TEST_PLAN_PATH=""                  # set at promotion
```

## Step 3: Preflight — fresh by construction

A draft is fresh by construction: no RCA, no D-ID, no PR possible. There is no
R/F/P/M resume ladder to compute on the entry path (the canonical ladder
applies only to an already-promoted defect on a re-run that resolves the
canonical tracker — see SKILL.md Idempotency). So this step is a one-liner:

```bash
# IS_DRAFT=1 always on the entry path → fresh run, dispatch /investigate.
R=0; F=0; P=0; M=0
RESUME_ROW=1
echo "Preflight: draft (IS_DRAFT=1) → fresh run by construction"
```

(If a future version adds canonical-defect resume — e.g. resolving a promoted
`D000NNN_<slug>/` by re-worded description — port investigate v1.1's 5-row
R/F/P/M ladder here. v0.1 does not: verbatim re-runs resume the draft, and a
promoted defect re-run is handled by the canonical resolver investigate
already owns.)

## Step 5: Dispatch /investigate via Agent subagent

(There is no Step 4 per-row branch — Step 3 is always fresh. Numbering keeps
parity with investigate v1.1's pipeline for cross-reference.)

### Step 5.0: Isolation gate (enforced before subagent dispatch)

`/investigate` Phase 4 writes the fix **directly to source** — there is no
separate implement step. Dispatching the subagent from an un-isolated or dirty
checkout means an in-place mutation of unrelated work (the D000024 bug class).
This gate enforces the "clean + isolated" invariant BEFORE the `ROLE:` dispatch
prompt below is ever sent.

Run this bash block first. **Shell vars do NOT persist across bash tool calls**
(only cwd does — see CLAUDE.md), so the helper path is re-resolved here. Prefer
the shared `cj-goal-common.sh` worktree-helper resolution; fall back to the
repo-local / manifest `cj-worktree-init.sh` directly (the gate calls the helper
with `--assert-isolated`, which `cj-goal-common.sh` does not wrap):

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

if [ -z "$_HELPER" ]; then
  # Helper unreachable after BOTH probes. At THIS boundary — immediately
  # before a source-writing subagent dispatch — unreachable means HALT, not
  # silent in-place. This is exactly the D000024 class the gate exists to close.
  TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  cat >> "$TRACKER" <<EOF
- $TS [investigate-not-isolated] worktree helper unreachable (repo-local + deployed _cj-shared both absent); cannot verify clean+isolated before source-writing subagent dispatch. HALT (no silent in-place write).
  next_action=Restore scripts/cj-worktree-init.sh (repo-local) or re-run 'skills-deploy install' to refresh the deployed _cj-shared home; then re-run.
  resume_cmd=/CJ_goal_defect "$DRAFT_DESC"
  pr_url=N/A
  raw_output_path=N/A
EOF
  echo "Why it stopped: the worktree-isolation helper is unreachable, so a clean+isolated checkout can't be verified before /investigate writes the fix to source."
  echo "State preserved: draft retained at $DEFECT_DIR, no D-ID consumed"
  echo "Next: /CJ_goal_defect \"$DRAFT_DESC\""
  # Telemetry: end_state=halted_at_investigate_not_isolated (write per Step 11 schema)
  exit 1
fi

# Forward ONLY --no-worktree, and only if the operator passed it (re-read the
# RUN_ID-scoped marker — $NO_WORKTREE does not persist across bash tool calls).
# NEVER forward --dry-run (already exited at Step 2) or --verbose.
if [ -f "$HOME/.gstack/analytics/CJ_goal_defect-runs/$RUN_ID/.operator-no-worktree" ]; then
  VERDICT_JSON=$("$_HELPER" --caller defect --assert-isolated --no-worktree 2>&1) && _GRC=0 || _GRC=$?
else
  VERDICT_JSON=$("$_HELPER" --caller defect --assert-isolated 2>&1) && _GRC=0 || _GRC=$?
fi
VERDICT_STATE=$(echo "$VERDICT_JSON" | jq -r '.state' 2>/dev/null || echo "")

if [ "$_GRC" -ne 0 ]; then
  # Non-zero verdict: dirty / not_isolated / not_a_repo.
  TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  cat >> "$TRACKER" <<EOF
- $TS [investigate-not-isolated] isolation gate verdict=$VERDICT_STATE — checkout is not clean+isolated; refusing to dispatch the source-writing /investigate subagent (D000024 class).
  next_action=Make the checkout clean+isolated: commit/stash changes, or run from a fresh worktree / clean feature branch; or pass --no-worktree on a clean checkout.
  resume_cmd=/CJ_goal_defect "$DRAFT_DESC"
  pr_url=N/A
  raw_output_path=N/A
EOF
  echo "Why it stopped: the checkout is not clean+isolated (verdict: $VERDICT_STATE), so /investigate would write the fix on top of unrelated work."
  echo "State preserved: draft retained at $DEFECT_DIR, no D-ID consumed"
  echo "Next: /CJ_goal_defect \"$DRAFT_DESC\""
  # Telemetry: end_state=halted_at_investigate_not_isolated
  exit 1
fi

echo "Isolation gate: verdict=$VERDICT_STATE — clean+isolated; proceeding to subagent dispatch."
```

Only on a green (`isolated`, exit 0) verdict does control proceed to build and
send the dispatch prompt below.

### Step 5.1: Build the dispatch prompt

Build the dispatch prompt (preamble first, variable tail last for cache
friendliness). Dispatch via the **Agent** tool — this is the depth-2 leaf
subagent; it does NOT spawn further subagents.

```
ROLE: /investigate runner for /CJ_goal_defect.

TASK: Drive /investigate Phases 1-4 against the bug-report draft below.
Before Phase 4 begins, emit a FIX_PLAN preamble. After Phase 4 completes,
emit a DEBUG REPORT JSON. Both must use sentinel-wrapped JSON blocks
(see below) — free-text DEBUG REPORTs are unparseable by the orchestrator.

OUTPUT CONTRACT — exact sentinel format, no markdown wrapping, no code
fences around the sentinel markers:

Pre-Phase-4 (after Phase 3 hypothesis enumeration, before any source edit):

  FIX_PLAN_BEGIN_JSON
  {
    "files": ["path/one.ext", "path/two.ext", ...],
    "rationale": "one-line description of the planned change"
  }
  FIX_PLAN_END_JSON

Post-Phase-4 (after fix is written + verified):

  DEBUG_REPORT_BEGIN_JSON
  {
    "status": "DONE" | "DONE_WITH_CONCERNS" | "BLOCKED",
    "symptom": "...",
    "repro": "...",                          (optional; orchestrator fills <!-- TODO --> if absent)
    "investigation_trail": ["step 1", "step 2", "step 3"],
    "root_cause": "...",                      (non-empty, non-placeholder)
    "location": "path/to/file.ext:line",
    "fix": {
      "files": ["..."],
      "description": "..."
    },
    "regression_test": "path/to/test.sh",     (path to a NEW or modified test)
    "evidence": "command output proving the fix works"
  }
  DEBUG_REPORT_END_JSON

If you cannot complete Phase 4 — emit DEBUG_REPORT with status="BLOCKED" and
populate as much as you have. The orchestrator will halt with [investigate-blocked].

WORK_ITEM_DIR: <absolute path to $DEFECT_DIR (the draft dir)>
DEFECT_ID:     (draft — none yet; working dir is the draft)
TRACKER:       <$TRACKER (the draft's DRAFT.md)>
BUG_REPORT:    <$BUG_DESC>
```

Because `CJ_goal_defect` always dispatches against a draft, `$DEFECT_ID` is
empty (it is minted only at promotion, Step 7.4). The `DEFECT_ID:` line MUST
read the literal `(draft — none yet; working dir is the draft)` — never an
empty `DEFECT_ID:` that would confuse `/investigate`.

Capture the subagent's stdout to a raw output file:

```bash
RAW_OUTPUT="$RAW_DIR/investigate-raw.txt"
# (the Agent tool call captures output; the orchestrator writes it to disk
#  before parsing)
```

## Step 6: Parse FIX_PLAN (pre-Phase-4 blast-radius gate)

```bash
FIX_PLAN_JSON=$(awk '/^FIX_PLAN_BEGIN_JSON$/,/^FIX_PLAN_END_JSON$/' "$RAW_OUTPUT" \
                | sed '1d;$d')
if [ -n "$FIX_PLAN_JSON" ]; then
  FILE_COUNT=$(echo "$FIX_PLAN_JSON" | jq -r '.files | length' 2>/dev/null || echo 0)
  if [ "$FILE_COUNT" -gt 5 ]; then
    TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    cat >> "$TRACKER" <<EOF

- $TS [investigate-blast-radius] FIX_PLAN reports $FILE_COUNT files; >5 threshold tripped.
  next_action=Decompose the fix into multiple bugs; run /investigate manually per chunk.
  resume_cmd=# manual: per-chunk /investigate; do NOT re-run /CJ_goal_defect on this description until decomposed.
  pr_url=N/A
  raw_output_path=$RAW_OUTPUT
EOF
    echo "Why it stopped: the planned fix touches $FILE_COUNT files (>5), too large for one defect."
    echo "State preserved: draft retained at $DEFECT_DIR, no D-ID consumed"
    echo "Next: decompose into smaller bugs; run /investigate manually per chunk."
    # Telemetry: end_state=halted_at_investigate_blast_radius
    exit 1
  fi
fi
```

If the FIX_PLAN block is absent (older `/investigate` runs without sentinel
support), continue to Step 7 — the blast-radius gate is best-effort.

## Step 7: Parse DEBUG_REPORT (Iron-Law gate)

Every Step 7 halt (and the Step 7.4 lock-timeout) follows the shared halt
contract: a journal heredoc into `$TRACKER` (which is the draft's `DRAFT.md`
pre-promotion, so the entry lands in the draft itself and is recoverable on
resume) PLUS a plain-English 3-line terminal block before `exit 1`:

```
Why it stopped: <one-line plain-English reason for THIS halt>
State preserved: draft retained at $DEFECT_DIR, no D-ID consumed
Next: /CJ_goal_defect "$DRAFT_DESC"
```

The `resume_cmd=` for a draft halt is always `/CJ_goal_defect "$DRAFT_DESC"`
(the description is the only stable pre-promotion re-entry key — there is no
D-ID yet).

```bash
DEBUG_REPORT=$(awk '/^DEBUG_REPORT_BEGIN_JSON$/,/^DEBUG_REPORT_END_JSON$/' "$RAW_OUTPUT" \
               | sed '1d;$d')

# Halt 1: no sentinel block at all
if [ -z "$DEBUG_REPORT" ]; then
  TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  cat >> "$TRACKER" <<EOF

- $TS [investigate-no-sentinel] /investigate output did not contain DEBUG_REPORT_BEGIN_JSON block.
  next_action=Inspect raw output; if /investigate produced a free-text DEBUG REPORT, hand-author RCA + test-plan from it after promoting manually.
  resume_cmd=/CJ_goal_defect "$DRAFT_DESC"
  pr_url=N/A
  raw_output_path=$RAW_OUTPUT
EOF
  echo "Why it stopped: /investigate did not emit the required DEBUG_REPORT sentinel block, so the verdict is unparseable."
  echo "State preserved: draft retained at $DEFECT_DIR, no D-ID consumed"
  echo "Next: /CJ_goal_defect \"$DRAFT_DESC\""
  # Telemetry: end_state=halted_at_investigate_no_sentinel
  exit 1
fi

# Halt 2: parse error
if ! echo "$DEBUG_REPORT" | jq . >/dev/null 2>&1; then
  TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  cat >> "$TRACKER" <<EOF

- $TS [investigate-parse-error] DEBUG_REPORT JSON failed to parse.
  next_action=Inspect raw output; hand-fix JSON or re-run /investigate manually.
  resume_cmd=/CJ_goal_defect "$DRAFT_DESC"
  pr_url=N/A
  raw_output_path=$RAW_OUTPUT
EOF
  echo "Why it stopped: the DEBUG_REPORT JSON is malformed and cannot be parsed."
  echo "State preserved: draft retained at $DEFECT_DIR, no D-ID consumed"
  echo "Next: /CJ_goal_defect \"$DRAFT_DESC\""
  # Telemetry: end_state=halted_at_investigate_parse_error
  exit 1
fi

STATUS=$(echo "$DEBUG_REPORT" | jq -r '.status // "MISSING"')
ROOT_CAUSE=$(echo "$DEBUG_REPORT" | jq -r '.root_cause // ""')

# Halt 3: empty / placeholder root cause (Iron-Law — no D-ID without a root cause)
if [ -z "$ROOT_CAUSE" ] || [[ "$ROOT_CAUSE" =~ ^\[.*\]$ ]]; then
  TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  cat >> "$TRACKER" <<EOF

- $TS [investigate-no-root-cause] DEBUG_REPORT.root_cause is empty or matches placeholder pattern. Iron-Law halt — no D-ID minted.
  next_action=Re-run /investigate manually; populate root_cause by hand if iterative refinement fails, then re-run.
  resume_cmd=/CJ_goal_defect "$DRAFT_DESC"
  pr_url=N/A
  raw_output_path=$RAW_OUTPUT
EOF
  echo "Why it stopped: /investigate did not produce a root cause, so the Iron-Law gate blocks promotion — no defect number is minted on a guess."
  echo "State preserved: draft retained at $DEFECT_DIR, no D-ID consumed"
  echo "Next: /CJ_goal_defect \"$DRAFT_DESC\""
  # Telemetry: end_state=halted_at_investigate_no_root_cause
  exit 1
fi

# Halt 4: status BLOCKED
if [ "$STATUS" = "BLOCKED" ]; then
  TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  cat >> "$TRACKER" <<EOF

- $TS [investigate-blocked] /investigate returned status=BLOCKED.
  next_action=Inspect DEBUG_REPORT for the blocker; resolve manually; re-run.
  resume_cmd=/CJ_goal_defect "$DRAFT_DESC"
  pr_url=N/A
  raw_output_path=$RAW_OUTPUT
EOF
  echo "Why it stopped: /investigate reported it was BLOCKED before completing the fix."
  echo "State preserved: draft retained at $DEFECT_DIR, no D-ID consumed"
  echo "Next: /CJ_goal_defect \"$DRAFT_DESC\""
  # Telemetry: end_state=halted_at_investigate_blocked
  exit 1
fi

# Halt 5: DONE_WITH_CONCERNS (Iron-Law equivalent — fix written but unverified)
if [ "$STATUS" = "DONE_WITH_CONCERNS" ]; then
  TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  cat >> "$TRACKER" <<EOF

- $TS [investigate-unverified] /investigate returned status=DONE_WITH_CONCERNS. Fix written but unverified — Iron-Law halt. No D-ID minted.
  next_action=Verify the fix manually; if green, promote + ship by hand, or re-run after the fix verifies.
  resume_cmd=/CJ_goal_defect "$DRAFT_DESC"
  pr_url=N/A
  raw_output_path=$RAW_OUTPUT
EOF
  echo "Why it stopped: /investigate wrote a fix but flagged it unverified (DONE_WITH_CONCERNS); the Iron-Law gate refuses to auto-advance."
  echo "State preserved: draft retained at $DEFECT_DIR, no D-ID consumed"
  echo "Next: /CJ_goal_defect \"$DRAFT_DESC\""
  # Telemetry: end_state=halted_at_investigate_unverified
  exit 1
fi
```

If we reach here, `$STATUS == "DONE"` and `$ROOT_CAUSE` is populated. The
Iron-Law gate has passed. Continue to Step 7.4 (promotion) then Step 7.5.

## Step 7.4: Promote draft → canonical defect dir (D-ID minted here)

By the time control reaches here, Step 7 guarantees `STATUS=DONE` and
`$ROOT_CAUSE` is populated — the Iron-Law gate has passed, so a D-ID may now be
minted. `CJ_goal_defect` ALWAYS promotes (every run is a draft); there is no
`IS_DRAFT=0` fall-through.

**Atomic promotion protocol (pinned ordering, all inside the mkdir-lock).**
This ordering is BINDING (the illustrative shell below shows it):

1. `DRAFT_OLD="$DEFECT_DIR"` — capture the pre-rebind absolute draft path
   BEFORE any rebind. The final `rm -rf` uses this saved path.
2. Allocate the D-ID (highest-N scan over the UNION of filesystem + git log +
   TODOS.md) and `mkdir -p "$CANON_DIR"`.
3. **Write the canonical TRACKER** containing `name: $DRAFT_DESC`. This is the
   DURABLE COMMIT POINT — once it exists, a re-invocation's canonical resolver
   (investigate's NAME_HITS) resolves the canonical dir by description, so a
   crash here-or-after never mints a second D-ID.
4. Rebind `DEFECT_DIR/DEFECT_ID/TRACKER/RCA_PATH/TEST_PLAN_PATH` to canonical.
5. `rm -rf "$DRAFT_OLD"` — the saved absolute path, last.
6. Release the lock (`rmdir`; restore prior EXIT trap).

The lock-acquisition timeout is a real halt: it appends a
`[promote-lock-timeout]` journal entry to the draft's `DRAFT.md` (with
`next_action=` and `resume_cmd=/CJ_goal_defect "$DRAFT_DESC"`), writes a
telemetry line `end_state=halted_at_promote_lock_timeout`, and prints the C7
3-line terminal block. It is NOT a bare `echo; exit 1`.

```bash
LOCK_DIR="$DEFECTS_ROOT/.scaffold.lock.d"
DRAFT_OLD="$DEFECT_DIR"                      # step 1: save before any rebind
i=0
while ! mkdir "$LOCK_DIR" 2>/dev/null; do
  i=$((i+1))
  if [ $i -gt 50 ]; then
    TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    cat >> "$DRAFT_OLD/DRAFT.md" <<EOF

- $TS [promote-lock-timeout] D-ID allocation lock ($LOCK_DIR) held >10s; promotion aborted.
  next_action=Check for a stale lock dir; rmdir it if no other invocation is live, then re-run.
  resume_cmd=/CJ_goal_defect "$DRAFT_DESC"
  pr_url=N/A
  raw_output_path=$RAW_OUTPUT
EOF
    echo "Why it stopped: another invocation held the D-ID allocation lock for over 10 seconds, so I could not safely mint a defect number."
    echo "State preserved: draft retained at $DRAFT_OLD, no D-ID consumed"
    echo "Next: /CJ_goal_defect \"$DRAFT_DESC\""
    # Telemetry: end_state=halted_at_promote_lock_timeout
    exit 1
  fi
  sleep 0.2
done
# Save any pre-existing EXIT trap and restore it on release instead of a bare
# `trap - EXIT` (which would silently drop a cleanup trap). The trap is
# installed only AFTER the lock is acquired — a crash during the mkdir-wait
# loop must NOT rmdir a lock we do not own.
_PRIOR_EXIT_TRAP=$(trap -p EXIT)
trap 'rmdir "$LOCK_DIR" 2>/dev/null' EXIT

# step 2: allocate the D-ID = max over the UNION of three durable D-ID sources,
# +1. (a) Filesystem scan — NO -maxdepth cap; the `D[0-9]{6}_` basename is
# globally unambiguous, and a depth cap under-counts nested 2-segment domains
# (ops/skills-deploy/, ops/ship/, ops/workflow/ — depth 3) and re-mints a
# colliding D-ID (the D000022 incident). (b) git log + TODOS.md — a D-ID is
# durably recorded in commit subjects + TODOS.md independent of any directory;
# a shipped-and-relocated or deferred/freestanding D-ID is invisible to a
# filesystem-only scan and would be silently re-minted. Union all three; max.
# POSIX/BSD-portable: stock find/sed/git/grep, no GNU-only flags.
_FS_NS=$(find "$DEFECTS_ROOT" -type d -name 'D[0-9][0-9][0-9][0-9][0-9][0-9]_*' 2>/dev/null \
         | sed -E 's|.*/D0*([0-9]+)_.*|\1|')
_GIT_NS=$(git -C "$_REPO_ROOT" log --all --format='%s' 2>/dev/null \
          | grep -oE 'D[0-9]{6}' | sed -E 's|D0*([0-9]+)|\1|')
_TODOS_NS=""
if [ -f "$_REPO_ROOT/TODOS.md" ]; then
  _TODOS_NS=$(grep -oE 'D[0-9]{6}' "$_REPO_ROOT/TODOS.md" 2>/dev/null \
              | sed -E 's|D0*([0-9]+)|\1|')
fi
HIGHEST=$(printf '%s\n%s\n%s\n' "$_FS_NS" "$_GIT_NS" "$_TODOS_NS" \
          | grep -E '^[0-9]+$' | sort -n | tail -1)
NEXT_N=$(( ${HIGHEST:-0} + 1 ))
DEFECT_ID=$(printf "D%06d" "$NEXT_N")

DOMAIN="uncategorized"                       # domain inference deferred
CANON_DIR="$DEFECTS_ROOT/$DOMAIN/${DEFECT_ID}_${DRAFT_SLUG}"
mkdir -p "$CANON_DIR"
NOW=$(date -u +%Y-%m-%dT%H:%M:%SZ)
# The canonical TRACKER is BOTH the durable commit point AND a
# CJ_personal-workflow-validated artifact. The description is operator free
# text; emit `name:` as a double-quoted YAML scalar with `\`/`"` escaped and
# CR/LF stripped so a routine description like `login: 500 on POST` cannot
# produce invalid frontmatter that wedges the promoted work-item.
DRAFT_DESC_YAML=$(printf '%s' "$DRAFT_DESC" | tr -d '\r\n' | sed 's/\\/\\\\/g; s/"/\\"/g')

# step 3 — DURABLE COMMIT POINT. Write the canonical TRACKER as a FULLY
# tracker-defect.md-compliant work-item: all required frontmatter fields
# (name/type/id/status/created/updated/repo/branch/blocked_by) PLUS the full
# section set (## Lifecycle with 3 phases + 11 gate checkboxes, Reproduction
# Steps, Todos, Log, PRs, Files, Insights, Journal). A minimal tracker (only
# frontmatter + Bug Report + Journal) FAILS the `/CJ_personal-workflow check`
# boundary gate that `/CJ_qa-work-item` runs at Step 8 (missing required
# sections / phases / checkbox count / frontmatter fields → "Phase 2
# incomplete" refusal). Phase 1 + Phase 2 gates are marked checked: by here the
# root cause is found and the branch + (imminently, Step 7.5) the RCA/test-plan
# exist, and the Phase-2 `Fix committed` gate is made true by Step 7.6's commit
# (which runs BEFORE Step 8 QA). auto_scaffolded + promoted_from_draft are
# additive keys (the validator is pass-through on extras).
_TRACKER_DATE="${NOW%%T*}"
_TRACKER_REPO=$(git rev-parse --show-toplevel 2>/dev/null || echo "")
case "$_TRACKER_REPO" in */.claude/worktrees/*) _TRACKER_REPO="${_TRACKER_REPO%%/.claude/worktrees/*}" ;; esac
_TRACKER_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
cat > "$CANON_DIR/${DEFECT_ID}_TRACKER.md" <<TRK
---
name: "$DRAFT_DESC_YAML"
type: defect
id: "$DEFECT_ID"
status: active
created: "$_TRACKER_DATE"
updated: "$_TRACKER_DATE"
repo: "$_TRACKER_REPO"
branch: "$_TRACKER_BRANCH"
blocked_by: ""
auto_scaffolded: true
promoted_from_draft: .inbox/$DRAFT_SLUG
---

## Lifecycle

### Phase 1: Track

1. Reproduction documented (see Reproduction Steps + the bug report)
2. Working branch created: $_TRACKER_BRANCH
3. Required docs scaffolded ($DEFECT_ID RCA + test-plan — written at Step 7.5)
4. /investigate populated the root cause (Iron-Law gate passed)

**Gates:**
- [x] Reproduction steps documented
- [x] Working branch created (branch field populated)
- [x] Required docs scaffolded (RCA + test-plan)
- [x] Root cause identified (or best hypothesis logged)

### Phase 2: Implement

1. /investigate Phase 4 wrote the fix directly to source
2. Regression test added covering the defect scenario
3. Fix + work-item artifacts committed (Step 7.6, before QA)
4. RCA updated with the final root cause

**Gates:**
- [x] Fix committed
- [x] RCA doc updated
- [x] Todos section reflects remaining work (no stale items)

### Phase 3: Ship

1. /CJ_qa-work-item — verify the test-plan rows (Step 8)
2. /CJ_document-release — doc-sync (Step 5.5)
3. /ship — open the fix PR (Step 9)
4. /land-and-deploy — merge + verify (Step 10)

**Gates:**
- [ ] /CJ_personal-workflow check — validation passed
- [ ] Test-plan verified (regression scenarios passing)
- [ ] /ship — PR created
- [ ] /land-and-deploy — merged and deployed

## Reproduction Steps

$DRAFT_DESC

## Todos

- [ ] Ship via /ship (Gate #2 human diff review)
- [ ] Land via /land-and-deploy

## Log

- $_TRACKER_DATE: Promoted from draft .inbox/$DRAFT_SLUG after /investigate populated the root cause. Domain defaulted to '$DOMAIN'; relocate to a more specific subdir if needed.

## PRs

<!-- PR links populated at /ship. -->

## Files

<!-- Affected files are listed in the RCA Affected Components table. -->

## Insights

<!-- Root cause + patterns discovered; see the $DEFECT_ID RCA. -->

## Journal
- $NOW [auto-scaffolded] /CJ_goal_defect captured the bug as draft .inbox/$DRAFT_SLUG, then promoted to $DEFECT_ID after /investigate populated the root cause. Domain defaulted to '$DOMAIN'.
TRK

# step 4 — rebind ALL downstream vars to canonical paths. Step 7.5+ is
# unchanged; it just operates on the rebound canonical vars.
DEFECT_DIR="$CANON_DIR"
TRACKER="$CANON_DIR/${DEFECT_ID}_TRACKER.md"
RCA_PATH="$CANON_DIR/${DEFECT_ID}_RCA.md"
TEST_PLAN_PATH="$CANON_DIR/${DEFECT_ID}_test-plan.md"

# step 5 — remove the consumed draft LAST, using the saved absolute path.
rm -rf "$DRAFT_OLD" 2>/dev/null

# step 6 — release the lock; restore the prior EXIT trap, or clear ours.
rmdir "$LOCK_DIR" 2>/dev/null
eval "${_PRIOR_EXIT_TRAP:-trap - EXIT}"

echo "Root cause found, so I converted the draft into defect $DEFECT_ID at $CANON_DIR (was: \"$DRAFT_DESC\"). The .inbox draft is now gone."
```

After Step 7.4, `$DEFECT_DIR`/`$DEFECT_ID`/`$TRACKER`/`$RCA_PATH`/`$TEST_PLAN_PATH`
are the canonical post-promotion values. Steps 7.5 onward operate on these
rebound vars; Step 7.6 (commit the fix before QA) is new.

## Step 7.5: Write artifacts (RCA + test-plan)

### Write RCA.md

The template heading mapping (from the `/investigate` DEBUG_REPORT JSON):

| JSON key | RCA heading |
|----------|-------------|
| `symptom` | `## Symptom` |
| `repro` (optional) | `## Reproduction Steps` (falls back to `<!-- TODO: operator fills repro steps -->`) |
| `investigation_trail` | `## Investigation Trail` (one bullet per array element with ISO timestamp) |
| `root_cause` + `location` | `## Root Cause` — `**Root cause:** <root_cause>\n\n**Location:** <location>` |
| `fix.files` | `## Affected Components` (one row per file in a `\| file \| change-type \|` table) |
| `fix.description` | `## Fix Description` (verbatim prose) |
| `regression_test` + `evidence` | `## Regression Risk` — `Regression test added: <regression_test>\n\n**Evidence:**\n\`\`\`\n<evidence>\n\`\`\`` |

Use the Write tool (full rewrite) for `$RCA_PATH` — the file is short and the
mapping is deterministic. Frontmatter follows
`templates/CJ_personal-workflow/doc-RCA.md` (or fall back to a minimal yaml
block: `type: rca`, `parent: $DEFECT_ID`, `created: <ISO>`).

### Append test-plan row

If `$TEST_PLAN_PATH` exists, use Edit to add a new row to its table:

```
| <regression_test> | regression test for $DEFECT_ID root cause | smoke |
```

If `$TEST_PLAN_PATH` does NOT exist, create it from the same template with
frontmatter + the table headers + the new row.

## Step 7.6: Commit the fix + work-item artifacts (BEFORE Step 8 QA)

`/investigate` Phase 4 wrote the fix DIRECTLY to source but did NOT commit it.
Two downstream gates require a COMMITTED fix on a clean tree, so the commit
happens HERE, before QA:

- **`/CJ_qa-work-item` boundary check (Step 8).** For a defect it runs
  `/CJ_personal-workflow check` and refuses unless the Phase-2 `Fix committed`
  implementer gate is checked — and that gate is only honest once the fix is
  actually committed. (The Step 7.4 tracker pre-marks it checked; this commit
  makes it true.)
- **`/CJ_document-release` clean-tree gate (Step 5.5).** It refuses on any
  uncommitted NON-DOC change; the fix files + the work-item artifacts are
  non-doc.

Commit the investigate-written fix together with the just-scaffolded work-item
artifacts (TRACKER + RCA + test-plan):

```bash
_SUBJ=$(printf '%s' "$DRAFT_DESC" | tr '\n' ' ' | cut -c1-60)
git add -A
git commit -m "fix: $DEFECT_ID $_SUBJ"
```

(`/ship` at Step 9 adds the VERSION/CHANGELOG bump as a follow-on commit; the
squash-merge subject is reconciled at land time per the repo's merge convention.)

## Step 8: Chain to /CJ_qa-work-item

Invoke `/CJ_qa-work-item` via the Skill tool on the canonical defect dir
(`$DEFECT_DIR`), embedding the literal directive `DEFER_AUDIT: true` in the
invocation context so QA DEFERS its three-stage audit (qa.md Step 8.6c/8.6d) —
the orchestrator runs that audit ONCE at the authoritative post-sync point
(Step 5.6). QA still runs its 8.6a/8.6b overlay writes inline and returns
`AUDITS=deferred` with NO `AUDIT_FINDINGS` block. The compliant Step 7.4 tracker
+ the Step 7.6 commit mean the boundary check passes; the QA skill runs the smoke
rows from the test-plan and records a `[qa-pass]` journal entry (defects emit
`E2E=ambiguous`).

Invocation directive (the greppable literal qa.md Step 8.6.0 inspects):

```
/CJ_qa-work-item "$DEFECT_DIR"
DEFER_AUDIT: true   (defer 8.6c/8.6d; the orchestrator runs the post-sync audit at Step 5.6)
```

If QA returns red: halt with `[qa-red]` (re-use the existing CJ_qa-work-item
halt marker — do NOT mint a new one), append a journal entry with `pr_url=N/A`,
print the C7 3-line block. Telemetry: `end_state=halted_at_qa`.

If green: QA (and the deferral journal line) appended entries to the tracker, so
the tree is dirty again with a NON-DOC change. Run the **pre-doc-sync commit**
(Step 8.4 below) to capture it, then continue to Step 5.5 (Doc-sync) → Step 5.6
(the post-sync audit) → Step 8.5 (the QA-audit checkpoint, fed by the post-sync
audit) → Step 5.7 (portability) → Step 9 (/ship).

## Step 8.4: Pre-doc-sync commit (idempotent — captures the post-QA tracker update)

The Step 7.6 commit already captured the investigate-written fix + the scaffolded
artifacts before QA. After QA, the tracker has new journal lines (the QA
`[qa-pass]`, the deferral `[qa-audit]` line) — a still-uncommitted NON-DOC change
that `/CJ_document-release` (Step 5.5) would refuse on (`[doc-sync-red]`). Commit
it here so Step 5.5's clean-tree gate sees a clean non-doc tree. The commit is
**idempotent**: it skips when the tree is already clean at HEAD, so a resume does
not double-commit. It records NO new phase boundary (it is gated on the live tree
state):

```bash
if git -C "$_REPO_ROOT" diff --quiet && git -C "$_REPO_ROOT" diff --cached --quiet; then
  echo "[pre-doc-sync-commit] tree already clean at HEAD — nothing to commit (idempotent skip)."
else
  git -C "$_REPO_ROOT" add -A
  git -C "$_REPO_ROOT" commit -m "chore: $DEFECT_ID post-QA tracker update (pre-doc-sync commit)" >/dev/null
  echo "[pre-doc-sync-commit] committed the post-QA tracker update (clean tree for doc-sync)."
fi
```

Only after a clean tree is established does control proceed to Step 5.5 (doc-sync).

### Step 5.5: Doc-sync (INLINE — CJ_document-release wrapper around upstream /document-release)

Doc-sync runs INLINE between the pre-doc-sync commit and the post-sync audit, so
any doc updates fold into the SAME defect PR as the fix. There is no post-merge
doc-drift window for orchestrator-driven paths: the doc update ships in the same
PR as the fix. Doc-sync now runs **before** the post-sync audit + the Step 8.5
QA-audit checkpoint (F000064 reorder), so the checkpoint decides on the docs that
will actually ship.

Invoke `/CJ_document-release` via the **Skill** tool with NO `--docs` flag
(v1 orchestrator wiring runs a full audit; the per-doc subset flag is for
manual operator invocations). The skill returns one of three RESULTs:

- `RESULT: green` — `/document-release` ran clean and the wrapper
  auto-committed doc-only changes (whitelist: `README|CHANGELOG|CLAUDE|
  ARCHITECTURE.md` + `doc/.+\.md` + `templates/doc-.*\.md`). Continue to
  Step 9 (/ship). The next phase will see a clean tree with a doc commit
  already present.
- `RESULT: green-noop` — `/document-release` ran clean and no doc changes
  were needed. Continue to Step 9 (/ship). The PR will be code-only.
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
    cat >> "$TRACKER" <<EOF

- $TS [doc-sync-red] /CJ_document-release returned RESULT=red; halt class halted_at_doc_sync.
  next_action=Inspect /document-release output; fix doc errors; re-run /CJ_document-release manually, then resume /CJ_goal_defect.
  resume_cmd=/CJ_goal_defect "$DRAFT_DESC"
  pr_url=N/A
  raw_output_path=$RAW_DIR/doc-sync-raw.txt
EOF
    echo "Why it stopped: /CJ_document-release failed (upstream /document-release non-green or pre-run gate refused)."
    echo "State preserved: defect $DEFECT_ID intact at $DEFECT_DIR; doc-sync did NOT commit doc files."
    echo "Next: inspect the failure, fix manually, then /CJ_goal_defect \"$DRAFT_DESC\""
    # Telemetry: end_state=halted_at_doc_sync
    exit 1
    ;;
  *red*\[doc-sync-non-doc-write\]*)
    TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    cat >> "$TRACKER" <<EOF

- $TS [doc-sync-non-doc-write] /CJ_document-release refused to auto-commit because upstream wrote files outside the doc-only whitelist.
  next_action=Inspect uncommitted non-doc files; revert if unexpected; re-run /CJ_document-release manually, then resume /CJ_goal_defect.
  resume_cmd=/CJ_goal_defect "$DRAFT_DESC"
  pr_url=N/A
  raw_output_path=$RAW_DIR/doc-sync-raw.txt
EOF
    echo "Why it stopped: /CJ_document-release refused — upstream /document-release wrote files outside the doc-only whitelist."
    echo "State preserved: defect $DEFECT_ID intact at $DEFECT_DIR; nothing auto-committed."
    echo "Next: inspect the non-doc files, revert if unexpected, then /CJ_goal_defect \"$DRAFT_DESC\""
    # Telemetry: end_state=halted_at_doc_sync_non_doc_write
    exit 1
    ;;
esac
```

Only on green or green-noop does control proceed to Step 5.6 (the post-sync
audit), then Step 8.5 (the QA-audit checkpoint), then the portability gate, then
Step 9 (/ship).

### Step 5.6: Post-sync doc/test audit (NEW — ONE combined read-only subagent)

Now that doc-sync has folded its doc updates into the PR, run the three-stage
doc/test audit ONCE, at the authoritative **post-sync** point. This is the audit
QA deferred (via `DEFER_AUDIT: true`, Step 8) — the orchestrator runs it itself
here so the Step 8.5 checkpoint decides on the docs that will actually ship.

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
ROLE: combined post-sync doc/test auditor for /CJ_goal_defect (READ-ONLY — report, do not fix).
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

## Step 8.5: QA-audit findings checkpoint (ALWAYS — AUQ; consumes the POST-sync audit)

Identical contract to `/CJ_goal_feature` Step 3.4 (the canonical gate row is
`qa-audit`, order 45, in `spec/test-spec-custom.md`). Immediately after the Step 5.6
post-sync audit returns, surface the checkpoint on its report (NOT a pre-sync
audit). The `AUDITS=` digest + the fenced `AUDIT_FINDINGS` block come from
Step 5.6's combined post-sync subagent (the two spec-overlay updates rode the QA
RESULT at 8.6a/8.6b; the doc audit + test audit are now the post-sync results).

**Build-gate auto-answer seam (the dormant local-E2E seam — F000071 Part A).**
BEFORE surfacing the AUQ below, run the deterministic verdict helper on the
post-sync audit digest, then branch on its one-line stdout:

```bash
_E2E_GATE="$_REPO_ROOT/scripts/cj-e2e-gate.sh"
_E2E_VERDICT="AUTO=inactive"
[ -x "$_E2E_GATE" ] && _E2E_VERDICT=$(bash "$_E2E_GATE" --gate qa-audit --digest "$AUDITS" 2>/dev/null || echo "AUTO=inactive")
```

(`$AUDITS` is the compact `doc:<ok|findings:n>,test:<ok|findings:n>` digest from
the post-sync audit. The helper is dormant unless BOTH `CJ_GOAL_E2E_AUTO=1` AND a
`.cj-e2e-sandbox` marker hold AND the gate is in the `{design-gate, qa-audit}`
allowlist — so on any normal run it prints `AUTO=inactive` and nothing changes.)

- `AUTO=continue` — the seam is active and the post-sync digest is fully green
  (`doc:ok` AND `test:ok`): SKIP the AUQ, print a loud
  `[E2E-AUTO] qa-audit auto-continued on a green digest — no human gate fired`
  banner, write NO waiver line (a green digest waives nothing), and proceed to
  the next step exactly as a human Continue would.
- `AUTO=halt` — the seam is active but the digest carries findings: take the
  **On Halt** path below (`[qa-audit-declined]`, end_state `halted_at_qa_audit`),
  exactly as a human Halt. The seam NEVER auto-waives findings.
- `AUTO=inactive` — the seam is dormant (the normal run): fall through and fire
  the AUQ unchanged.

This GENERALIZES `todo_fix`'s existing `--quiet` green-continue into ONE path,
two triggers: the qa-audit auto-continue condition is now
`QUIET=1 OR (the helper prints AUTO=continue)`, both honoring the same green-only
predicate (continue only on `doc:ok,test:ok`; halt on findings; never
auto-waive). A normal run (no `--quiet`, no `CJ_GOAL_E2E_AUTO`/marker) is
behavior-unchanged — the helper prints `inactive` and the AUQ fires as before.

Surface an AskUserQuestion **ALWAYS** — findings or not:

> QA-audit checkpoint for {DEFECT_ID} — AUDITS=doc:<...>,test:<...> (post-sync)
>
> {AUDIT_FINDINGS block, verbatim}
>
> Options:
> - Continue — proceed to the portability gate + /ship
> - Halt — stop the run here; I want to act on these findings first

**On Continue:** if either audit reported findings, append the auditable
waiver line `- $TS [qa-audit-waived] operator continued past audit findings
at the post-QA (post-sync) checkpoint: AUDITS=...` to the defect tracker journal
(a fully-green digest writes nothing). Then, since this waiver line is itself an
uncommitted NON-DOC tracker change, commit it (`git add -A && git commit`, or no-op
on a clean tree) so the portability gate + `/ship` see a clean tree; proceed to
Step 5.7 (portability).

**On Halt:** append `- $TS [qa-audit-declined] operator halted at the
post-QA (post-sync) audit checkpoint.` + the family-contract fields (`next_action=`
act on the audit findings, then resume — QA re-runs, doc-sync + the post-sync
audit re-run, and the checkpoint re-fires; `resume_cmd=/CJ_goal_defect "<bug
description>"`; `pr_url=N/A`; `raw_output_path=$RAW_DIR/post-sync-audit-raw.txt`)
to the journal, write a telemetry line with `end_state=halted_at_qa_audit`, and
exit. The checkpoint is a pure read of the post-sync audit (no phase boundary
recorded).

### Step 5.7: Portability gate (INLINE — halt-on-red before /ship; F000051)

Runs immediately after the Step 8.5 QA-audit checkpoint (which followed doc-sync
+ the post-sync audit) and immediately before `/ship`. The fix + work-item
artifacts are final after Step 7.6's commit and QA; doc-sync only touched docs —
so this is the last readiness check before the PR, and it keeps the verdict fresh
for the Step 9.5 PR-body surfacing. The gate is a **pure read** (records NO state,
unconditionally re-run on resume), so a resume after a `[portability-red]` halt
restarts here, not at ship.

Call the shared `cj-goal-common.sh --phase portability-audit --mode defect` (the
audit is verb-independent; `--mode` is telemetry-only). It runs the
`cj-portability-audit.sh` engine under `PORTABILITY_STRICT=1` and classifies the
result into `ok` / `findings` / `skipped`:

```bash
_COMMON="$_REPO_ROOT/scripts/cj-goal-common.sh"
_PORT_RESULT="skipped"; _PORT_VERDICT=""
if [ -x "$_COMMON" ]; then
  _PORT_OUT=$(bash "$_COMMON" --phase portability-audit --mode defect 2>/dev/null) && _PORT_RC=0 || _PORT_RC=$?
  _PORT_RESULT=$(printf '%s\n' "$_PORT_OUT" | sed -n 's/^PHASE_RESULT=//p' | head -1)
  _PORT_VERDICT=$(printf '%s\n' "$_PORT_OUT" | sed -n 's/^VERDICT_LINE=//p' | head -1)
  [ -z "$_PORT_RESULT" ] && _PORT_RESULT="skipped"
else
  echo "[portability] cj-goal-common.sh unreachable — skipping the portability gate (best-effort)"
fi
```

- On `PHASE_RESULT=ok`: write `VERDICT_LINE` to the scratch file
  `.cj-goal-feature/portability-verdict.md` (the LITERAL path — only
  `.cj-goal-feature/` is gitignored) and continue to Step 9 (/ship):

```bash
if [ "$_PORT_RESULT" = "ok" ]; then
  mkdir -p "$_REPO_ROOT/.cj-goal-feature" 2>/dev/null || true
  printf '### Portability\n\n%s\n' "$_PORT_VERDICT" > "$_REPO_ROOT/.cj-goal-feature/portability-verdict.md"
  echo "[portability] $_PORT_VERDICT — continuing to /ship"
fi
```

- On `PHASE_RESULT=skipped` (engine absent / helper unreachable): echo a visible
  note and continue to Step 9 — no halt, no scratch write:

```bash
if [ "$_PORT_RESULT" = "skipped" ]; then
  echo "[portability] gate skipped (engine absent) — continuing to /ship (best-effort, not halting)"
fi
```

- On `PHASE_RESULT=findings`: **HALT** with `[portability-red]` (end_state
  `halted_at_portability`). A touched skill declares a portability tier it does
  not honor; no PR is created (the gate halts BEFORE `/ship`), so the findings
  live in the canonical tracker journal:

```bash
if [ "$_PORT_RESULT" = "findings" ]; then
  TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  printf '%s\n' "$_PORT_OUT" > "$RAW_DIR/portability-raw.txt" 2>/dev/null || true
  cat >> "$TRACKER" <<EOF

- $TS [portability-red] cj-goal-common.sh --phase portability-audit returned PHASE_RESULT=findings; halt class halted_at_portability. $_PORT_VERDICT
  next_action=A touched skill declares a portability tier it does not honor. Relabel its 'portability' in skills-catalog.json to the tier its deps need, OR add the accepted dep to its 'portability_requires'. Then re-run.
  resume_cmd=/CJ_goal_defect "$DRAFT_DESC"
  pr_url=N/A
  raw_output_path=$RAW_DIR/portability-raw.txt
EOF
  echo "Why it stopped: the portability audit found a skill that declares a portability tier it does not honor (a dishonest declaration); the gate blocks the PR until it is reconciled."
  echo "State preserved: defect $DEFECT_ID intact at $DEFECT_DIR; no PR created."
  echo "Next: relabel the skill's 'portability' (or add to 'portability_requires') in skills-catalog.json, then /CJ_goal_defect \"$DRAFT_DESC\""
  # Telemetry: end_state=halted_at_portability (write per Step 11 schema before exit)
  jq -nc --arg ts "$TS" --arg run_id "$RUN_ID" --arg end_state "halted_at_portability" \
    --arg slug "$DRAFT_SLUG" '{ts:$ts,run_id:$run_id,end_state:$end_state,slug:$slug,parent_skill:"CJ_goal_defect"}' \
    >> "$TELEMETRY" 2>/dev/null || true
  exit 1
fi
```

Only on `ok` or `skipped` does control proceed to Step 9 (/ship).

## Step 9: Chain to /ship

Invoke `/ship` via the Skill tool. /ship Gate #2 fires unconditionally
(autonomy ceiling preserved per F000021) — this is the human diff review and
is NOT bypassed.

If `/ship` declines (Gate #2 reject OR pre-landing review red): halt with a
`[ship-declined]` journal entry (`pr_url=` set if a PR was created before the
decline, else `N/A`) + the C7 3-line block. Telemetry: `end_state=halted_at_ship`.

If green (PR created): record the PR URL/number from /ship's output into
`$PR_URL`, continue to Step 9.5.

## Step 9.5: Surface registered-doc verdicts into the PR body (best-effort; NEVER halts)

The Step 5.5 doc-sync wrapper (`/CJ_document-release`) ran a Registered-doc
requirements audit (its Step 6.7) and wrote the verdict block to the gitignored
scratch file `.cj-goal-feature/registered-doc-verdicts.md`. That block dies in
the wrapper RESULT otherwise — upstream `/ship` Step 18 regenerates the PR body
from a fresh `/document-release` subagent that never sees the wrapper output. So
surface it deterministically here, now that Step 9 has opened the PR and
`$PR_URL` is known: read the scratch file and `gh pr edit "$PR_URL"` to
insert-or-replace a `### Registered-doc requirements` subsection under the PR
body's `## Documentation` section. (`/ship` here captures `$PR_URL` only — there
is no `$PR_NUMBER` in this pipeline; `gh pr view` / `gh pr edit` both accept a
URL, so the guard and both gh calls use `"$PR_URL"`.)

This is **best-effort and NEVER halts the run**: a failed `gh pr edit` (or a
missing scratch file — Step 5.5 may have been a no-op path) logs a one-line note
and control proceeds to Step 10. The verdicts still live in the run output + the
scratch file regardless. There is **NO upstream `/ship` modification** — this is
a workbench-owned pipeline step. All three cj_goal orchestrators surface the
verdict (`/CJ_goal_feature` Step 4.6, `/CJ_goal_defect` here, `/CJ_goal_todo_fix`
Step 5.6); the Step 6.7 producer is shared by all three. The scratch path is the
LITERAL `.cj-goal-feature/registered-doc-verdicts.md` (NOT verb-renamed — only
`.cj-goal-feature/` is gitignored).

The same step ALSO splices the green portability verdict (`### Portability`,
written by the Step 5.7 gate to `.cj-goal-feature/portability-verdict.md`) into
the same `## Documentation` section — identical best-effort posture.

```bash
_VERDICT_FILE="$_REPO_ROOT/.cj-goal-feature/registered-doc-verdicts.md"
_PORT_VERDICT_FILE="$_REPO_ROOT/.cj-goal-feature/portability-verdict.md"
if [ -n "$PR_URL" ] && { [ -f "$_VERDICT_FILE" ] || [ -f "$_PORT_VERDICT_FILE" ]; }; then
  # Read the current PR body, then insert-or-replace the
  # '### Registered-doc requirements' + '### Portability' subsections under
  # '## Documentation'.
  _BODY=$(gh pr view "$PR_URL" --json body -q .body 2>/dev/null || echo "")
  _VERDICTS=""
  [ -f "$_VERDICT_FILE" ] && _VERDICTS=$(cat "$_VERDICT_FILE")
  _PORT=""
  [ -f "$_PORT_VERDICT_FILE" ] && _PORT=$(cat "$_PORT_VERDICT_FILE")
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
    gh pr edit "$PR_URL" --body-file "$_BODY_FILE" 2>/dev/null || true
    _CHECK_LINES=$(gh pr view "$PR_URL" --json body -q .body 2>/dev/null | awk 'END{print NR}')
    [ "${_CHECK_LINES:-0}" -ge "$_FLOOR" ] && { _SPLICED=1; break; }
  done
  rm -f "$_STRIPPED_FILE" "$_INSERT_FILE" "$_BODY_FILE"
  if [ "$_SPLICED" = "1" ]; then
    echo "[registered-doc] surfaced verdicts into PR $PR_URL body (## Documentation → ### Registered-doc requirements + ### Portability)"
  else
    echo "[registered-doc] PR-body splice did not verify after retry — verdicts remain in the run output + the scratch files (best-effort, not halting)"
  fi
else
  echo "[registered-doc] no verdict scratch file (or no PR URL) — skipping PR-body surfacing (best-effort, not halting)"
fi
```

Control always proceeds to Step 10 — this step has no halt path.

## Step 10: Chain to /land-and-deploy --suppress-readiness-gate

**BEFORE-land recap (3-part; advisory — F000068).** `defect` is a landing verb:
it lands in-pipeline, so it emits a recap BEFORE the land (the "about to land"
heads-up) and another AFTER (Step 12). Render the BEFORE block here, just ahead of
the `/land-and-deploy` invocation. YOU (the agent) author the three fields for THIS
fix — the helper only formats. The land has NOT happened yet, so frame `next` as
"the land is about to run":

```bash
_COMMON="$_REPO_ROOT/scripts/cj-goal-common.sh"
if [ -x "$_COMMON" ]; then
  bash "$_COMMON" --phase recap --mode defect --when before \
    --field delivered="<the fix in plain terms: what the bug was + what changed; PR $PR_URL>" \
    --field e2e="<the concrete end-to-end commands/checks that prove the fix — e.g. the test-plan's regression command, scripts/test.sh, or a repro that now passes>" \
    --field next="/land-and-deploy --suppress-readiness-gate is about to merge + deploy PR $PR_URL."
fi
```

**Prose fallback (helper absent).** If `$_COMMON` is missing/unreachable, emit the
same 3-part block as prose under an `=== About to land ===` header (do NOT halt —
the recap is advisory). A missing field renders an empty section.

Then invoke `/land-and-deploy --suppress-readiness-gate` via the Skill tool.

If red (CI / merge / canary / regression): halt with a `[land-and-deploy-red]`
journal entry (`pr_url=$PR_URL`) + the C7 3-line block. Telemetry:
`end_state=halted_at_deploy`.

If green: continue to Step 10.5.

## Step 10.5: Worktree cleanup (best-effort, post-land; NEVER halts)

The PR has landed (Step 10 merged + deployed). Sweep landed cj-* worktrees +
refresh root main via the shared cleanup phase (T000036) — the teardown mirror of
the Step 1 worktree-create phase. This defect run's own `cj-def-*` worktree is now
swept too (its PR is MERGED), along with any other MERGED/CLOSED cj-* worktrees;
the root checkout is pulled current.

Cleanup is strictly best-effort and runs only AFTER the PR is safely landed, so it
can never endanger shipped work. `cj-goal-common.sh --phase cleanup` emits
`PHASE_RESULT=ok|skipped`, never `failed` — a failed sweep logs a note and the run
still reports `green`. There is no halt path here.

```bash
_COMMON="$_REPO_ROOT/scripts/cj-goal-common.sh"
[ -x "$_COMMON" ] && bash "$_COMMON" --phase cleanup --mode defect 2>/dev/null || true
```

Continue to Step 11.

## Step 11: Final journal write + telemetry

Append to the canonical tracker journal:

```
- <ISO ts> [defect-shipped] $DEFECT_ID v<X.Y.Z> PR #<NNN>
  pr_url=$PR_URL
```

Append one telemetry line to the per-verb stream
`~/.gstack/analytics/CJ_goal_defect.jsonl` (written inline so the documented
path is authoritative; the shared `cj-goal-common.sh` is consumed for the
worktree + pr-check phases, not for this canonical end-state line):

```bash
jq -nc \
  --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  --arg run_id "$RUN_ID" \
  --arg defect_id "$DEFECT_ID" \
  --arg defect_dir "$DEFECT_DIR" \
  --arg end_state "green" \
  --arg pr_url "$PR_URL" \
  --arg slug "$DRAFT_SLUG" \
  '{ts:$ts,run_id:$run_id,defect_id:$defect_id,defect_dir:$defect_dir,end_state:$end_state,pr_url:$pr_url,slug:$slug,auto_scaffolded:true,parent_skill:"CJ_goal_defect"}' \
  >> "$TELEMETRY"
```

Optionally also record a deterministic audit receipt via the shared helper
(best-effort; non-blocking — it writes to the `cj-goal-defect.jsonl` stream the
helper owns, distinct from the canonical `CJ_goal_defect.jsonl` above):

```bash
_COMMON="$_REPO_ROOT/scripts/cj-goal-common.sh"
[ -x "$_COMMON" ] && bash "$_COMMON" --phase telemetry --mode defect \
  --field run_id="$RUN_ID" --field defect_id="$DEFECT_ID" \
  --field end_state="green" >/dev/null 2>&1 || true
```

## Step 12: Print summary

```
PIPELINE COMPLETE: end_state=green

Run ID:    $RUN_ID
Defect:    $DEFECT_ID at $DEFECT_DIR
Status:    shipped + deployed
PR:        $PR_URL
RCA:       $RCA_PATH
Test plan: $TEST_PLAN_PATH

Tracker:   $TRACKER
Telemetry: $TELEMETRY
```

**AFTER-land recap (3-part; advisory — F000068).** This is the AFTER half of the
landing-verb before+after pair (the BEFORE block ran in Step 10). The fix has now
merged + deployed, so render the AFTER ("Landed") block via the shared helper. YOU
(the agent) author the three fields for THIS fix; the helper only formats:

```bash
_COMMON="$_REPO_ROOT/scripts/cj-goal-common.sh"
if [ -x "$_COMMON" ]; then
  bash "$_COMMON" --phase recap --mode defect --when after \
    --field delivered="<the fix in plain terms + the version it bumped to + PR $PR_URL + the squash-merge SHA>" \
    --field e2e="<the concrete end-to-end commands/checks that prove the fix is LIVE — e.g. the regression command against origin/main, scripts/test.sh, or a repro that now passes>" \
    --field next="<the concrete next action — typically: confirm the deploy / canary, then nothing else; or a named follow-up>"
fi
```

**Prose fallback (helper absent).** If `$_COMMON` is missing/unreachable, emit the
same 3-part block as prose under a `=== Landed / PR opened ===` header (do NOT halt
— the recap is advisory). A missing field renders an empty section. No
`validate.sh` check asserts the recap fired.

---

## Notes on end-state telemetry

Every exit path (success OR halt) writes a single telemetry line to
`~/.gstack/analytics/CJ_goal_defect.jsonl`. Success states: `green`,
`dry_run_preview`. Halt states (all from investigate v1.1's taxonomy, minus the
canonical-resolve halts that do not apply to an always-draft front door):
`halted_at_no_arg`, `halted_at_investigate_blast_radius`,
`halted_at_investigate_no_sentinel`, `halted_at_investigate_parse_error`,
`halted_at_investigate_no_root_cause`, `halted_at_investigate_blocked`,
`halted_at_investigate_unverified`, `halted_at_investigate_not_isolated`,
`halted_at_promote_lock_timeout`, `halted_at_qa`, `halted_at_qa_audit`,
`halted_at_doc_sync`, `halted_at_portability`, `halted_at_ship`,
`halted_at_deploy`.

Add any new halt with: (a) a journal entry in the appropriate Step, (b) a
telemetry write before exit, (c) a row in SKILL.md's halt-taxonomy table.

## Resilience contract

- **Idempotent.** A verbatim re-run of the same description resumes the draft
  (pre-promotion) or the canonical defect (post-promotion). Partial states are
  recoverable.
- **No automatic rollback.** Halts write journal entries with `next_action=`,
  `resume_cmd=`, and `pr_url=` — the operator drives recovery.
- **Halt-on-red end-to-end.** Any red status from `/investigate`,
  `/CJ_qa-work-item`, `/ship`, or `/land-and-deploy` stops the chain.
- **Iron-Law for free.** A D-ID is never minted for a root-cause-less bug —
  promotion runs only after the Step 7 gate passes.
- **Raw output preservation.** Every `/investigate` dispatch writes its raw
  output to `$RAW_DIR/investigate-raw.txt`; the halt journal entries point at
  it via `raw_output_path=`.
- **Depth ≤ 2.** `/investigate` and `/CJ_qa-work-item` are leaf subagents;
  `/ship` + `/land-and-deploy` run inline. No subagent-spawns-subagent path.
