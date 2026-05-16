# /CJ_goal_investigate — Orchestration

Single-keystroke orchestrator from `D000NNN` → deployed fix. Implements the
SPEC's Data Flow steps 1-12 with the 9-state halt-on-red taxonomy and 5-row
idempotency resume table.

Read [SKILL.md](SKILL.md) first for path resolution, error handling, the
halt-taxonomy summary, and the resume table. Then follow the steps below.

---

## Step 1: Parse arguments

Accept the following arg shapes:

```
/CJ_goal_investigate D000NNN
/CJ_goal_investigate "fragment"
/CJ_goal_investigate --dry-run D000NNN
/CJ_goal_investigate --dry-run "fragment"
/CJ_goal_investigate --verbose D000NNN          # optional P2
```

Parser:

```bash
DRY_RUN=""
VERBOSE=""
ARGS=()
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    --verbose) VERBOSE=1 ;;
    *) ARGS+=("$arg") ;;
  esac
done
ARG="${ARGS[0]:-}"
[ -n "$ARG" ] || { echo "Error: D-ID or fragment required."; exit 1; }
[ "${#ARGS[@]}" -le 1 ] || { echo "Error: exactly one D-ID or fragment expected (got: ${ARGS[*]})"; exit 1; }
RUN_ID=$(date +%Y%m%d-%H%M%S)-$$
```

Initialize telemetry + decision-log paths:

```bash
mkdir -p "$HOME/.gstack/analytics/CJ_goal_investigate-runs/$RUN_ID"
TELEMETRY="$HOME/.gstack/analytics/CJ_goal_investigate.jsonl"
RAW_DIR="$HOME/.gstack/analytics/CJ_goal_investigate-runs/$RUN_ID"
```

## Step 2: Resolve the defect directory

The resolver searches `work-items/defects/<domain>/D000NNN_<slug>/` (legacy
layout only in v1.0).

```bash
_REPO_ROOT=$(git rev-parse --show-toplevel)
DEFECTS_ROOT="$_REPO_ROOT/work-items/defects"

# Exact D-ID match: anchored regex on dir basename starting with D followed by 6 digits + underscore.
if [[ "$ARG" =~ ^D[0-9]{6}$ ]]; then
  MATCHES=$(find "$DEFECTS_ROOT" -maxdepth 2 -type d -name "${ARG}_*" 2>/dev/null)
else
  # Fragment fuzzy: match against (a) dir basename and (b) tracker `name:` field.
  # Two passes union'd; dedup by path.
  BASENAME_HITS=$(find "$DEFECTS_ROOT" -maxdepth 2 -type d -iname "*${ARG}*" 2>/dev/null \
                  | grep -E '/D[0-9]{6}_' || true)
  NAME_HITS=$(grep -rli --include="*_TRACKER.md" "$ARG" "$DEFECTS_ROOT" 2>/dev/null \
              | xargs -I {} dirname {} 2>/dev/null || true)
  MATCHES=$(printf '%s\n%s\n' "$BASENAME_HITS" "$NAME_HITS" | grep -v '^$' | sort -u)
fi

MATCH_COUNT=$(printf '%s\n' "$MATCHES" | grep -c '^[^[:space:]]' || true)

case "$MATCH_COUNT" in
  0)
    echo "Halt: no defect matches '$ARG'."
    echo "Looked in: $DEFECTS_ROOT (legacy layout: <domain>/D000NNN_<slug>/)"
    # No journal entry — there's no work-item to journal to.
    # Telemetry: end_state=halted_at_resolve_zero
    exit 1
    ;;
  1)
    DEFECT_DIR=$(printf '%s\n' "$MATCHES" | head -1)
    DEFECT_ID=$(basename "$DEFECT_DIR" | grep -oE '^D[0-9]{6}')
    echo "Resolved: $DEFECT_ID at $DEFECT_DIR"
    ;;
  *)
    echo "Halt: '$ARG' matches $MATCH_COUNT defects:"
    printf '%s\n' "$MATCHES" | while read -r p; do
      d=$(basename "$p" | grep -oE '^D[0-9]{6}')
      echo "  $d at $p"
    done
    echo
    echo "Re-run with full D-ID, e.g.:"
    printf '%s\n' "$MATCHES" | head -1 | while read -r p; do
      d=$(basename "$p" | grep -oE '^D[0-9]{6}')
      echo "  /CJ_goal_investigate $d"
    done
    # Telemetry: end_state=halted_at_resolve_ambiguous
    exit 1
    ;;
esac

TRACKER=$(find "$DEFECT_DIR" -maxdepth 1 -name "*_TRACKER.md" | head -1)
RCA_PATH="$DEFECT_DIR/${DEFECT_ID}_RCA.md"
TEST_PLAN_PATH="$DEFECT_DIR/${DEFECT_ID}_test-plan.md"
```

## Step 3: Preflight — 5-row idempotency table

Compute the four state signals (R, F, P, M) and pick the resume row:

```bash
# R: RCA populated? (file exists AND Root Cause section has prose beyond the TODO placeholder)
#
# D000020 fix: the previous `/^## Root Cause/,/^## /` awk range is degenerate —
# the start pattern AND the end pattern both match the "## Root Cause" header
# line, so awk captures exactly one line (the header itself). Use a stateful
# flag instead: enter the block at "## Root Cause", exit at the next `## `
# heading (excluding "## Root Cause" itself).
R=0
if [ -f "$RCA_PATH" ]; then
  ROOT_CAUSE_BODY=$(awk '
    /^## Root Cause/ { in_rc=1; next }
    in_rc && /^## / { in_rc=0 }
    in_rc { print }
  ' "$RCA_PATH" | grep -v '^[[:space:]]*$' | grep -v '<!-- TODO' || true)
  [ -n "$ROOT_CAUSE_BODY" ] && R=1
fi

# F: fix in tree? Branch journal mentions defect ID with a fix-shipped marker,
# OR git log on the current branch references the D-ID.
F=0
if grep -q "$DEFECT_ID" "$TRACKER" 2>/dev/null; then
  if git log --all --oneline 2>/dev/null | grep -q "$DEFECT_ID"; then
    F=1
  fi
fi

# P, M: query gh for PR state
P=0; M=0
if command -v gh >/dev/null 2>&1; then
  PR_STATE=$(gh pr list --search "$DEFECT_ID in:title" --state all --json state -q '.[0].state' 2>/dev/null || true)
  case "$PR_STATE" in
    OPEN) P=1 ;;
    MERGED) M=1 ;;
  esac
fi

echo "Idempotency state: R=$R F=$F P=$P M=$M"

# Pick resume row
#
# D000020 fix: check M=1 (terminal "already shipped" state) FIRST, before the
# R=0+F=1 anomaly check. Previously the order let a fully-shipped defect with
# under-detected RCA (Bug A above, before its fix) fall through to Row 5
# anomaly when it should be Row 4 no-op. Even with Bug A's awk fixed, the
# defense-in-depth ordering protects against future RCA-detection edge cases:
# a merged PR is a terminal state and always wins.
if [ "$M" = 1 ]; then
  RESUME_ROW=4  # no-op: PR merged
elif [ "$R" = 0 ] && [ "$F" = 1 ]; then
  RESUME_ROW=5  # anomaly: fix in tree but RCA missing AND PR not merged
elif [ "$R" = 0 ] && [ "$F" = 0 ]; then
  RESUME_ROW=1  # fresh
elif [ "$R" = 1 ] && [ "$F" = 1 ] && [ "$P" = 0 ]; then
  RESUME_ROW=2  # skip /investigate; chain QA→ship→deploy
elif [ "$R" = 1 ] && [ "$F" = 1 ] && [ "$P" = 1 ]; then
  RESUME_ROW=3  # skip through /ship; chain /land-and-deploy
else
  # Defensive: any other combination → treat as fresh and log a warning
  RESUME_ROW=1
  echo "warning: idempotency signals R=$R F=$F P=$P M=$M did not match any canonical row; treating as fresh." >&2
fi
echo "Resume row: $RESUME_ROW"
```

## Step 3.5: --dry-run preview branch (if `$DRY_RUN`)

When `$DRY_RUN` is set, print the chain plan and exit BEFORE any writes or
subagent dispatches:

```
DRY RUN — /CJ_goal_investigate $DEFECT_ID

Resolved defect:    $DEFECT_DIR
Tracker:            $TRACKER
Idempotency state:  R=$R F=$F P=$P M=$M
Resume row:         $RESUME_ROW (<description>)

Plan:
  <conditional steps based on $RESUME_ROW — see per-row branches in Step 4>

Expected writes (skipped in dry-run):
  $RCA_PATH                  (RCA template-mapped from /investigate JSON)
  $TEST_PLAN_PATH            (one row appended per JSON.regression_test)

Suggested resume:
  /CJ_goal_investigate $DEFECT_ID
```

No files written; no Agent subagent dispatched; no Skill invocations. Exit 0
with `end_state=dry_run_preview` written to telemetry.

## Step 4: Per-row resume branch

### Row 4 (no-op): print summary

Grep the tracker for `[investigate-shipped]`. If found, print the matching
line + exit 0 with `end_state=already_shipped`.

### Row 5 (anomaly): halt

Write a journal entry:

```
- <ISO ts> [anomaly-rca-missing-with-fix] RCA empty but fix appears in tree (D-ID in git log). Manual review required.
  next_action=Inspect the branch; either revert the partial fix or hand-author RCA before re-invoking.
  resume_cmd=git log --all --oneline | grep $DEFECT_ID  # inspect first
  raw_output_path=N/A
```

Exit non-zero; `end_state=halted_at_anomaly_rca_missing`.

### Row 1 (fresh): full chain — dispatch /investigate via Agent

Continue to Step 5.

### Row 2: skip /investigate + artifact writes; jump to Step 8 (`/CJ_qa-work-item`).

### Row 3: skip through /ship; jump to Step 10 (`/land-and-deploy`).

## Step 5: Dispatch /investigate via Agent subagent

Build the dispatch prompt (preamble first, variable tail last for cache
friendliness):

```
ROLE: /investigate runner for /CJ_goal_investigate.

TASK: Drive /investigate Phases 1-4 against the defect work-item below.
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

WORK_ITEM_DIR: <absolute path to $DEFECT_DIR>
DEFECT_ID:     <$DEFECT_ID>
TRACKER:       <$TRACKER>
```

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
    # Halt: blast-radius. Note: by the time we observe this, Phase 4 may or
    # may not have started — the FIX_PLAN preamble is supposed to fire BEFORE
    # Phase 4, but if /investigate ignored the convention we may still be
    # post-write. Either way, halt before /ship.
    TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    cat >> "$TRACKER" <<EOF

- $TS [investigate-blast-radius] FIX_PLAN reports $FILE_COUNT files; >5 threshold tripped.
  next_action=Decompose the fix into multiple defects; run /investigate manually per chunk.
  resume_cmd=# manual: per-chunk /investigate; do NOT re-run /CJ_goal_investigate on this defect until decomposed.
  raw_output_path=$RAW_OUTPUT
EOF
    # Telemetry: end_state=halted_at_investigate_blast_radius
    exit 1
  fi
fi
```

If FIX_PLAN block is absent (older /investigate runs without sentinel
support), continue to Step 7 — the blast-radius gate is best-effort.

## Step 7: Parse DEBUG_REPORT (Iron-Law gate)

```bash
DEBUG_REPORT=$(awk '/^DEBUG_REPORT_BEGIN_JSON$/,/^DEBUG_REPORT_END_JSON$/' "$RAW_OUTPUT" \
               | sed '1d;$d')

# Halt 1: no sentinel block at all
if [ -z "$DEBUG_REPORT" ]; then
  TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  cat >> "$TRACKER" <<EOF

- $TS [investigate-no-sentinel] /investigate output did not contain DEBUG_REPORT_BEGIN_JSON block.
  next_action=Inspect raw output; if /investigate produced a free-text DEBUG REPORT, hand-author RCA + test-plan from it.
  resume_cmd=cat $RAW_OUTPUT  # then manual artifact write, then /CJ_qa-work-item $DEFECT_DIR
  raw_output_path=$RAW_OUTPUT
EOF
  exit 1
fi

# Halt 2: parse error
if ! echo "$DEBUG_REPORT" | jq . >/dev/null 2>&1; then
  TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  cat >> "$TRACKER" <<EOF

- $TS [investigate-parse-error] DEBUG_REPORT JSON failed to parse.
  next_action=Inspect raw output; hand-fix JSON or re-run /investigate manually.
  resume_cmd=jq . $RAW_OUTPUT  # diagnose; manual fix; then /CJ_qa-work-item $DEFECT_DIR
  raw_output_path=$RAW_OUTPUT
EOF
  exit 1
fi

STATUS=$(echo "$DEBUG_REPORT" | jq -r '.status // "MISSING"')
ROOT_CAUSE=$(echo "$DEBUG_REPORT" | jq -r '.root_cause // ""')

# Halt 3: empty / placeholder root cause
if [ -z "$ROOT_CAUSE" ] || [[ "$ROOT_CAUSE" =~ ^\[.*\]$ ]]; then
  TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  cat >> "$TRACKER" <<EOF

- $TS [investigate-no-root-cause] DEBUG_REPORT.root_cause is empty or matches placeholder pattern.
  next_action=Re-run /investigate manually; populate root_cause by hand if iterative refinement fails.
  resume_cmd=# manual /investigate; then re-invoke /CJ_goal_investigate $DEFECT_ID
  raw_output_path=$RAW_OUTPUT
EOF
  exit 1
fi

# Halt 4: status BLOCKED
if [ "$STATUS" = "BLOCKED" ]; then
  TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  cat >> "$TRACKER" <<EOF

- $TS [investigate-blocked] /investigate returned status=BLOCKED.
  next_action=Inspect DEBUG_REPORT for the blocker; resolve manually; re-invoke.
  resume_cmd=jq . $RAW_OUTPUT  # inspect; then /CJ_goal_investigate $DEFECT_ID after unblocking
  raw_output_path=$RAW_OUTPUT
EOF
  exit 1
fi

# Halt 5: DONE_WITH_CONCERNS (Iron-Law equivalent)
if [ "$STATUS" = "DONE_WITH_CONCERNS" ]; then
  TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  cat >> "$TRACKER" <<EOF

- $TS [investigate-unverified] /investigate returned status=DONE_WITH_CONCERNS. Fix written but unverified — Iron-Law halt.
  next_action=Verify the fix manually; if green, ship via /ship directly (bypasses orchestrator).
  resume_cmd=# manual verify; then /ship  (do NOT re-invoke /CJ_goal_investigate — fix is already in tree)
  raw_output_path=$RAW_OUTPUT
EOF
  exit 1
fi
```

If we reach here, `$STATUS == "DONE"` and `$ROOT_CAUSE` is populated. Continue
to Step 8.

## Step 7.5: Write artifacts (RCA + test-plan)

### Write RCA.md

The template heading mapping (SPEC Story #5):

| JSON key | RCA heading |
|----------|-------------|
| `symptom` | `## Symptom` |
| `repro` (optional) | `## Reproduction Steps` (falls back to `<!-- TODO: operator fills repro steps -->`) |
| `investigation_trail` | `## Investigation Trail` (one bullet per array element with ISO timestamp) |
| `root_cause` + `location` | `## Root Cause` — `**Root cause:** <root_cause>\n\n**Location:** <location>` |
| `fix.files` | `## Affected Components` (one row per file in a `\| file \| change-type \|` table) |
| `fix.description` | `## Fix Description` (verbatim prose) |
| `regression_test` + `evidence` | `## Regression Risk` — `Regression test added: <regression_test>\n\n**Evidence:**\n\`\`\`\n<evidence>\n\`\`\`` |

Use the Write tool (full rewrite) for RCA.md — the file is short and the
mapping is deterministic. Frontmatter follows the existing
`templates/CJ_personal-workflow/doc-RCA.md` (or fall back to a minimal
yaml block: `type: rca`, `parent: $DEFECT_ID`, `created: <ISO>`).

### Append test-plan row

If `$TEST_PLAN_PATH` exists, use Edit to add a new row to its table:

```
| <regression_test> | regression test for $DEFECT_ID root cause | smoke |
```

If `$TEST_PLAN_PATH` does NOT exist, create it from the same template with
frontmatter + the table headers + the new row.

## Step 8: Chain to /CJ_qa-work-item

Invoke `/CJ_qa-work-item` via the Skill tool on the defect dir. The QA skill
runs the smoke rows from the test-plan; defects emit `E2E=ambiguous` per
qa.md line 179.

If QA returns red: halt with `[qa-red]` (re-use existing CJ_qa-work-item halt
markers — do NOT mint a new one). Telemetry: `end_state=halted_at_qa`.

If green: continue to Step 9.

## Step 9: Chain to /ship

Invoke `/ship` via the Skill tool. /ship Gate #2 fires unconditionally
(autonomy ceiling preserved per F000021).

If `/ship` declines (Gate #2 reject OR pre-landing review red): halt with
`[ship-declined]` journal entry. Telemetry: `end_state=halted_at_ship`.

If green (PR created): record the PR URL/number from /ship's output, continue
to Step 10.

## Step 10: Chain to /land-and-deploy --suppress-readiness-gate

Invoke `/land-and-deploy --suppress-readiness-gate` via the Skill tool.

If red (CI / merge / canary / regression): halt with `[land-and-deploy-red]`
journal entry. Telemetry: `end_state=halted_at_deploy`.

If green: continue to Step 11.

## Step 11: Final journal write + telemetry

Append to tracker journal:

```
- <ISO ts> [investigate-shipped] $DEFECT_ID v<X.Y.Z> PR #<NNN>
```

Append telemetry line:

```bash
jq -nc \
  --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  --arg run_id "$RUN_ID" \
  --arg defect_id "$DEFECT_ID" \
  --arg defect_dir "$DEFECT_DIR" \
  --arg end_state "green" \
  --arg pr_url "$PR_URL" \
  '{ts:$ts,run_id:$run_id,defect_id:$defect_id,defect_dir:$defect_dir,end_state:$end_state,pr_url:$pr_url,parent_skill:"CJ_goal_investigate"}' \
  >> "$TELEMETRY"
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

---

## Notes on end-state telemetry

Every exit path (success OR halt) writes a single telemetry line. The 9 halt
states + the 3 success states (`green`, `already_shipped`, `dry_run_preview`)
give 12 total end-states. Add any new halt with: (a) a journal entry in the
appropriate Step, (b) a telemetry write before exit, (c) a row in SKILL.md's
halt-taxonomy table.

## Resilience contract

- **Idempotent.** Re-running on the same defect ID picks the right resume
  row via Step 3. Partial states are recoverable.
- **No automatic rollback.** Halts write journal entries with `next_action=`
  and `resume_cmd=` — the operator drives recovery.
- **Halt-on-red end-to-end.** Any red status from /CJ_qa-work-item, /ship,
  or /land-and-deploy stops the chain.
- **Raw output preservation.** Every /investigate dispatch writes its raw
  output to `$RAW_DIR/investigate-raw.txt`; the halt journal entries point
  at it via `raw_output_path=`.
