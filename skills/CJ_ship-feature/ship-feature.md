# /CJ_ship-feature — Orchestration

End-to-end wrapper from APPROVED `/office-hours` design doc to verified deploy:

```
/office-hours (manual, separate)
    ↓ produces APPROVED design doc
/CJ_ship-feature <design-doc-path>
    ├── Phase 1: /autoplan          (Skill, inline)  [GATE #1: final-approval AUQ]
    ├── Phase 2: CJ_personal-pipeline (Agent subagent, --suppress-final-gate)
    │              └── scaffold → impl → QA (8.5 + 9.2 AUQs suppressed)
    ├── Phase 3: /ship               (Skill, inline)  [GATE #2: diff-review AUQ]
    └── Phase 4: /land-and-deploy    (Skill, inline)  [auto on green; alert on red]
```

This file is the step-by-step logic invoked from [SKILL.md](SKILL.md). Read
SKILL.md first for path resolution, error handling, and usage; then follow the
steps below.

---

## Subagent Return Contract (Phase 2 only)

The Phase 2 subagent dispatch (CJ_personal-pipeline) must end its final
assistant message with a line of the form:

```
RESULT: PIPELINE_END_STATE=<green|halted_at_gate|user_aborted|subagent_crashed>; WORK_ITEM_DIR=<absolute_path>
```

Parse with the lenient parser (mirrors CJ_personal-pipeline's parse_result):

```bash
parse_result() {
  local output="$1"
  echo "$output" \
    | grep -E 'RESULT: [A-Z_]+=' \
    | tail -1 \
    | sed -E 's/^[[:space:]>]*//;s/```//g;s/~~~//g'
}
```

If `parse_result` returns empty: subagent did not emit a RESULT line at all →
halt with `end_state=subagent_crashed` and exit.

Phases 1, 3, 4 run inline (via Skill tool) and do NOT need a RESULT contract —
their state is observable directly in the orchestrator's conversation context.

---

## Step 1: Validate Input + Initialize state file

Parse the user's argument and set up shared state. **All state lives in a per-run
state file** (`/tmp/cj-ship-feature-$RUN_ID.env`) — every subsequent step's bash
block starts by sourcing this file. This solves the "bash variables don't cross
orchestrator-model Bash tool calls" problem (the failure mode PR1 caught at v2.1.4).

```bash
# Single positional arg: <design-doc-path>
DESIGN_DOC="${1:-}"
[ -n "$DESIGN_DOC" ] || { echo "Error: design-doc path required"; exit 1; }
[ -f "$DESIGN_DOC" ] || { echo "Error: design doc not found at $DESIGN_DOC"; exit 1; }

# Must be under ~/.gstack/projects/ (the canonical /office-hours output location)
case "$DESIGN_DOC" in
  "$HOME/.gstack/projects/"*) ;;
  *) echo "Error: design doc must be under ~/.gstack/projects/ (got: $DESIGN_DOC)"; exit 1 ;;
esac

# MUST have Status: APPROVED somewhere in the body (typically near top of doc)
grep -q '^Status: APPROVED' "$DESIGN_DOC" || {
  echo "Error: design doc lacks 'Status: APPROVED'. Run /office-hours, accept the final approval option, then re-invoke /CJ_ship-feature."
  exit 1
}

# Capture absolute path; generate stable RUN_ID.
# NOTE: $$ here is the ephemeral bash shell's PID — fine for RUN_ID uniqueness
# in practice (date+PID collision requires same-second + PID reuse). The RUN_ID
# is written to the state file below; subsequent steps read the file, not $$.
DESIGN_DOC=$(realpath "$DESIGN_DOC")
RUN_ID="$(date +%Y%m%d-%H%M%S)-$$"

# Initialize state file. Every subsequent step `source`s this at the start of
# any bash block to recover state. Variables: RUN_ID, DESIGN_DOC, END_STATE,
# MULTI_STORY, WORK_ITEM_DIR, PR_URL, PIPELINE_DECISION_LOG.
STATE_FILE="/tmp/cj-ship-feature-$RUN_ID.env"
PIPELINE_DECISION_LOG="$HOME/.gstack/analytics/CJ_personal-pipeline-auto-decisions.jsonl"
# NOTE: PIPELINE_DECISION_LOG points to the pipeline's standalone log. The
# wrapper does NOT redirect the pipeline's log via env var (that mechanism
# doesn't propagate cleanly across Skill-tool boundaries — F2 in PR2 review).
# Wrapper reads from the standalone log post-pipeline and filters by RUN_ID.
# Pipeline's Step 1 will emit a soft-warning about co-mingling; accepted.

mkdir -p "$HOME/.gstack/analytics"
cat > "$STATE_FILE" <<EOF
RUN_ID="$RUN_ID"
DESIGN_DOC="$DESIGN_DOC"
PIPELINE_DECISION_LOG="$PIPELINE_DECISION_LOG"
STATE_FILE="$STATE_FILE"
END_STATE="green"
MULTI_STORY=0
WORK_ITEM_DIR=""
PR_URL=""
PR_NUM=""
EOF

echo "STATE_FILE: $STATE_FILE"
echo "RUN_ID: $RUN_ID"
```

**State-file contract** (every subsequent bash block in ship-feature.md MUST
begin with this):

```bash
# Recover state from the per-run state file. STATE_FILE path is the literal
# computed at Step 1 — model carries the path through as prose.
source "$STATE_FILE" || { echo "ERROR: state file missing at $STATE_FILE — aborting"; exit 1; }
```

**State-mutation contract**: any step that updates a state variable (e.g., sets
`END_STATE=halted_at_pipeline` or `MULTI_STORY=1`) MUST rewrite the state file
before continuing. Use this helper pattern:

```bash
write_state() {
  cat > "$STATE_FILE" <<EOF
RUN_ID="$RUN_ID"
DESIGN_DOC="$DESIGN_DOC"
PIPELINE_DECISION_LOG="$PIPELINE_DECISION_LOG"
STATE_FILE="$STATE_FILE"
END_STATE="$END_STATE"
MULTI_STORY=$MULTI_STORY
WORK_ITEM_DIR="$WORK_ITEM_DIR"
PR_URL="$PR_URL"
PR_NUM="$PR_NUM"
EOF
}
# Call write_state after any field update.
```

**Cleanup**: the state file is in `/tmp/`; tmpfiles cleanup will reap it. The
final telemetry write (Step 6 helper below) is durable; state file is
working-state-only.

---

## Step 2: Phase 1 — `/autoplan` (inline, GATE #1)

Invoke `/autoplan` via the **Skill tool** with the design-doc path as argument.
`/autoplan` runs its CEO + design + eng + DX review chain, accumulates auto-decisions
per its 6 principles, and surfaces its native final-approval AUQ (this is GATE #1
in the wrapper's accounting).

`/autoplan` may also surface additional native AUQs along the way (premise-confirmation
gate in Phase 1 when codex disagrees with the user-stated direction; User Challenges
in Phase 4 when both review models agree the user should change course). The wrapper
does NOT pre-collect or pass-through these — they fire natively in /autoplan's
context, which is the wrapper's own context.

After `/autoplan` completes, branch:

- **/autoplan completed with final-approval AUQ → Approve**: continue to Step 3.
- **/autoplan aborted at final-approval AUQ or pre-flight halt**: set state and flow to Step 6 (finalize). Do NOT exit directly:
  ```bash
  source "$STATE_FILE"
  END_STATE="halted_at_autoplan"
  write_state
  # PROCEED TO STEP 6 — Step 6.2 will print the halt summary; Step 6.4 → Step 7.1 will exit non-zero.
  ```
  Step 6.2's halt-print template will surface the "Wrapper halted at /autoplan final gate. Re-invoke when ready; /autoplan re-runs (3-10 min cost — wrapper-level skip-if-reviewed is deferred to v1.1)." message as part of its standard halt tail.

**Re-entry note**: on wrapper re-invocation, /autoplan re-runs its full review — it
appends a new `## GSTACK REVIEW REPORT` block on each invocation. v1 accepts this
cost; v1.1 will add wrapper-level skip-if-reviewed (grep design doc for the report
header before invoking).

---

## Step 3: Phase 2 — `CJ_personal-pipeline` (Agent subagent, suppress-final-gate)

First source the state file to recover the design-doc path:

```bash
source "$STATE_FILE"
```

Then spawn an Agent subagent via the Agent tool with `subagent_type: "general-purpose"`.
The subagent invokes `/CJ_personal-pipeline` with `--suppress-final-gate`. The pipeline
writes its decision log to its standalone path (`~/.gstack/analytics/CJ_personal-pipeline-auto-decisions.jsonl`)
— wrapper does NOT redirect via env var (env vars don't propagate across Skill-tool
boundaries cleanly; F2 fix in PR2 review).

The pipeline's Step 1 will emit a soft-warning to stderr about co-mingling decisions
with standalone-run history. That's accepted v1 behavior — Step 6.3 of the wrapper
filters by run_id when reading the audit.

**Subagent prompt template** (substitute `$DESIGN_DOC` literally at dispatch time —
bash variables don't cross orchestrator-model Bash calls; the prompt template carries
the literal path):

```
ROLE: pipeline runner for /CJ_ship-feature wrapper.
TASK: invoke /CJ_personal-pipeline in --suppress-final-gate mode and report its end state.

STEPS:
1. Invoke the slash command (via the Skill tool):
     /CJ_personal-pipeline --suppress-final-gate "<literal $DESIGN_DOC path>"
2. The pipeline runs its full lifecycle (Phase 1 scaffold → Phase 2 impl → Phase 3 QA + post-phase gates).
   It will SKIP Step 8.5's AUQ and Step 9.2's sunset AUQ per the --suppress-final-gate contract.
   Its tracker journal will record [auto-pipeline-clean] (zero-decision run) or
   [auto-final-gate-suppressed] N mechanical, M taste, K user-challenge-approved (non-zero).
3. At pipeline completion, the pipeline prints a "PIPELINE COMPLETE: end_state=<X>" line as its final output (Step 9.3 of pipeline.md).
4. Read that end_state value. Map it to the wrapper's RESULT contract:
     pipeline's end_state=green                 → PIPELINE_END_STATE=green
     pipeline's end_state=halted_at_gate         → PIPELINE_END_STATE=halted_at_gate
     pipeline's end_state=user_aborted           → PIPELINE_END_STATE=user_aborted (shouldn't fire under --suppress-final-gate; defensive)
     pipeline's end_state=subagent_crashed       → PIPELINE_END_STATE=subagent_crashed
5. Also extract the work-item directory path from the pipeline's "Work item: <path>" output line.

RETURN CONTRACT — end your FINAL assistant message with this EXACT line on its own:
  RESULT: PIPELINE_END_STATE=<value>; WORK_ITEM_DIR=<absolute_path>

Example (literal, this is the expected format):
  RESULT: PIPELINE_END_STATE=green; WORK_ITEM_DIR=/Users/chjiang/Documents/projects/claude-skills-templates/work-items/features/F000016_example/

No prose, no markdown wrapping, no code fence around the RESULT line itself.
If pipeline crashed and you cannot read end_state, emit:
  RESULT: PIPELINE_END_STATE=subagent_crashed; WORK_ITEM_DIR=
(empty WORK_ITEM_DIR is acceptable when scaffold didn't complete.)
```

After the Agent tool returns, the subagent's full output is in `$SUBAGENT_OUTPUT`. The lenient parser from the Subagent Return Contract section finds the RESULT line.

Capture stdout/stderr to `PIPELINE_OUTPUT`. Parse with `parse_result`. Branch:

### Branch (a): green + single-story shape

`PIPELINE_END_STATE=green; WORK_ITEM_DIR=<path>` AND the work-item is single-story.

**Multi-story shape check** (run AFTER green return; before flowing into /ship):

```bash
# Count nested TRACKER files at depth 2 (children of WORK_ITEM_DIR/<child>/)
CHILD_TRACKERS=$(find "$WORK_ITEM_DIR" -maxdepth 2 -mindepth 2 \
  \( -name "*_TRACKER.md" -o -name "TRACKER.md" \) 2>/dev/null | wc -l | tr -d ' ')
if [ "$CHILD_TRACKERS" -ge 1 ]; then
  MULTI_STORY=1
else
  MULTI_STORY=0
fi
```

If `MULTI_STORY=0`: store `WORK_ITEM_DIR`; continue to Step 4.

### Branch (b): green + multi-story scaffold-only

`PIPELINE_END_STATE=green; WORK_ITEM_DIR=<path>` AND `CHILD_TRACKERS >= 1`.

Pipeline correctly halted at scaffold gate per its existing multi-story branch
(end_state=green, scaffolded only — no impl/QA). Flowing into /ship would try to
ship an empty scaffold. SKIP Steps 4-5 entirely; jump to Step 6 with:

- `END_STATE=green`
- `MULTI_STORY=1` (telemetry field will reflect this)
- Tail summary printed:

```
Multi-story feature scaffolded. Per-child invocation needed:
  /CJ_ship-feature <design-doc-for-child-1>
  /CJ_ship-feature <design-doc-for-child-2>
  ...
(Or invoke /CJ_personal-pipeline on each child design doc if you want the
inner loop only.)
```

The per-child paths can be derived from the work-item tree: read each child
TRACKER's frontmatter `source_design` field (if present) or list child dirs
under `$WORK_ITEM_DIR/`.

### Branch (c): non-green

`PIPELINE_END_STATE` is `halted_at_gate`, `user_aborted`, or anything other than green.

Set state and flow to Step 6 (finalize). Step 6.2's halt-print template will name
the pipeline_end_state value:

```bash
source "$STATE_FILE"
END_STATE="halted_at_pipeline"
WORK_ITEM_DIR="<value parsed from RESULT line>"
write_state
# PROCEED TO STEP 6 — finalizer prints "Wrapper halted at CJ_personal-pipeline.
# Pipeline end_state: <PIPELINE_END_STATE>" + tracker path + pipeline decision
# log location; exits non-zero via Step 7.1.
```

### Branch (d): empty / no RESULT

`parse_result` returned empty (subagent crashed without emitting RESULT line).

```bash
source "$STATE_FILE"
END_STATE="subagent_crashed"
# WORK_ITEM_DIR may have been created before crash but we don't know — leave as ""
write_state
# PROCEED TO STEP 6 — finalizer prints "CJ_personal-pipeline subagent crashed
# (no RESULT line emitted). Re-invoke /CJ_ship-feature; pipeline's Branch (a)
# idempotency will resume from disk state if the work-item dir was created."
```

---

## Step 4: Phase 3 — `/ship` (inline, GATE #2)

Reached only on Branch (a) of Step 3 (green + single-story).

Invoke `/ship` via the **Skill tool**. No arguments needed — `/ship` operates on the
current branch in the workbench's cwd. CJ_personal-pipeline's QA phase committed work
to the feature branch; `/ship` picks up from there.

`/ship` runs its full sequence: pre-flight (test suite, base-branch sync, scope-drift
detection, version bump, CHANGELOG check), staged commits, optional review-army
(Greptile / codex / adversarial review), pre-PR diff review AUQ (GATE #2 in the
wrapper's accounting), then `gh pr create`.

`/ship` may surface multiple native AUQs depending on findings (test failures →
triage AUQ; scope drift → confirmation; review-army findings → fix/ack/false-positive
AUQs; final diff review). The wrapper does NOT pre-collect — `/ship`'s diff review
is the canonical surface for code-level decisions including the suppressed pipeline
8.5 decisions (which are visible in the same diff).

### Capture PR URL

After `/ship` completes successfully (PR created), capture the URL. Primary method:
parse the `gh pr create` stdout that `/ship` surfaces. Fallback (since inline /ship's
bash stdout isn't reliably retained in the wrapper's narrative context after the
Skill tool returns):

```bash
PR_URL=$(gh pr list --head "$(git branch --show-current)" --json url -q '.[0].url' 2>/dev/null || echo "")
[ -z "$PR_URL" ] && PR_URL="<see branch on origin>"
```

### Branch (a): /ship green

PR created, `$PR_URL` captured. Continue to Step 5.

### Branch (b): /ship halted or aborted

Set state and flow to Step 6 (finalize). The halt-print template will surface
the "/ship halt is healthy — not wrapper brittleness" framing:

```bash
source "$STATE_FILE"
END_STATE="halted_at_ship"
write_state
# PROCEED TO STEP 6 — finalizer prints standard halt tail; note halted_at_ship
# is healthy (review caught a real issue), excluded from sunset trip-wire by
# Step 7's filter. Re-invoke /CJ_ship-feature after fix, or invoke /ship
# directly to continue (commits exist locally; /ship's idempotency resumes).
```

---

## Step 5: Phase 4 — `/land-and-deploy` (inline, non-AUQ on green)

Reached only on Branch (a) of Step 4 (/ship green, PR created).

First, source the state file and parse the PR number from `$PR_URL`:

```bash
source "$STATE_FILE"
# Parse PR number from URL (typically the last path segment, e.g. ".../pull/95")
PR_NUM="${PR_URL##*/}"
# Validate: must be numeric. Bail if not (PR_URL may be the "<see branch on origin>" fallback from Step 4).
if ! printf '%s' "$PR_NUM" | grep -qE '^[0-9]+$'; then
  # Try to recover via gh
  CURRENT_BRANCH=$(git branch --show-current)
  PR_NUM=$(gh pr list --head "$CURRENT_BRANCH" --state all --json number -q '.[0].number' 2>/dev/null || echo "")
fi
if ! printf '%s' "$PR_NUM" | grep -qE '^[0-9]+$'; then
  echo "WARNING: could not determine PR number. Invoking /land-and-deploy without arg (it will auto-detect from branch)."
  PR_NUM=""
fi
write_state  # persist PR_NUM
```

Invoke `/land-and-deploy` via the **Skill tool**:

- If `PR_NUM` is set: `/land-and-deploy #<PR_NUM>` (literal value).
- If `PR_NUM` is empty: `/land-and-deploy` (no arg — `/land-and-deploy` will
  auto-detect from current branch per its Step 1).

`/land-and-deploy` waits for CI, merges the PR, monitors any post-merge deploy
workflow, runs canary verification if a production URL was configured, and
writes its own deploy report. Its terminal verdict is one of:
`DEPLOYED AND VERIFIED`, `DEPLOYED (UNVERIFIED)`, `STAGING VERIFIED`, or `REVERTED`.

### Branch (a): green deploy

`/land-and-deploy` ends with verdict `DEPLOYED AND VERIFIED`,
`DEPLOYED (UNVERIFIED)`, or `STAGING VERIFIED`. All three count as green.

Set `END_STATE=green`; call `write_state`. Continue to Step 6 (finalize).

### Branch (b): merge reverted (canary red caused user-revert)

`/land-and-deploy` ends with verdict `REVERTED` (user reverted post-merge after
canary or another failure). The PR was merged then reverted; the wrapper's
work is partially live but rolled back.

Set `END_STATE=deploy_red`; call `write_state`. Continue to Step 6 (finalize)
to record telemetry, then the finalizer exits non-zero with this tail:

```
Deploy reverted post-merge. See /land-and-deploy report.
  PR: <PR_URL> (merged then reverted)
  Manual action needed: investigate the revert reason; fix-forward when ready.

Note: deploy_red is excluded from the sunset trip-wire — production health
concerns are separate from wrapper orchestration brittleness.
```

### Branch (c): /land-and-deploy halted pre-merge

CI red, merge conflict, user aborted at /land-and-deploy's readiness gate,
or any other pre-merge halt that did not produce a terminal verdict above.

Set `END_STATE=halted_at_deploy`; call `write_state`. Continue to Step 6
(finalize). The finalizer's tail names the halt reason from /land-and-deploy's
diagnostic output.

---

## Step 6: Finalize (telemetry + summary) — every exit path calls this

**Every halt branch in Steps 2-5 ends by jumping to Step 6**, with `END_STATE`
set to the appropriate halt value via `write_state`. The green path also
reaches Step 6 after Step 5 Branch (a). Step 6 → Step 7 is the universal exit
path; the orchestrator does NOT exit directly from a halt branch.

This step has 3 sub-blocks: 6.1 telemetry write (always runs), 6.2 final
summary print (branches on green/halt), 6.3 pipeline-decision audit tail
(if log has content). Every sub-block sources `$STATE_FILE` to recover state.

### Step 6.1: Telemetry write (universal)

```bash
source "$STATE_FILE"
TRACKER_PATH=""
if [ -n "$WORK_ITEM_DIR" ]; then
  # Union of personal-workflow conventions: prefixed (D000017_TRACKER.md) OR
  # bare (TRACKER.md). Pipeline.md Step 2 branch-c uses bare; scaffold typically
  # produces prefixed. Match either.
  TRACKER_PATH=$(find "$WORK_ITEM_DIR" -maxdepth 1 \( -name '*_TRACKER.md' -o -name 'TRACKER.md' \) -print -quit 2>/dev/null)
  [ -z "$TRACKER_PATH" ] && TRACKER_PATH="$WORK_ITEM_DIR (TRACKER not found)"
fi

MULTI_STORY_BOOL=$([ "$MULTI_STORY" = "1" ] && echo "true" || echo "false")

if command -v jq >/dev/null 2>&1; then
  jq -nc \
    --arg run_id "$RUN_ID" \
    --arg design_doc "$DESIGN_DOC" \
    --arg work_item "${WORK_ITEM_DIR:-}" \
    --arg pr_url "${PR_URL:-}" \
    --arg end_state "$END_STATE" \
    --argjson multi_story_scaffold_only "$MULTI_STORY_BOOL" \
    --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    '{run_id:$run_id,design_doc:$design_doc,work_item:$work_item,pr_url:$pr_url,end_state:$end_state,multi_story_scaffold_only:$multi_story_scaffold_only,ts:$ts}' \
    >> "$HOME/.gstack/analytics/CJ_ship-feature.jsonl"
else
  # Fallback when jq is missing (workbench declared dep, so unlikely).
  # Lossy on paths with quotes/backslashes but never invalid JSON.
  _SAFE_DOC=$(printf '%s' "$DESIGN_DOC" | tr -d '\\"')
  _SAFE_WORK=$(printf '%s' "${WORK_ITEM_DIR:-}" | tr -d '\\"')
  _SAFE_PR=$(printf '%s' "${PR_URL:-}" | tr -d '\\"')
  echo "{\"run_id\":\"$RUN_ID\",\"design_doc\":\"$_SAFE_DOC\",\"work_item\":\"$_SAFE_WORK\",\"pr_url\":\"$_SAFE_PR\",\"end_state\":\"$END_STATE\",\"multi_story_scaffold_only\":$MULTI_STORY_BOOL,\"ts\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}" \
    >> "$HOME/.gstack/analytics/CJ_ship-feature.jsonl"
fi
```

### Step 6.2: Print summary — header depends on END_STATE

If `END_STATE=green`:

```
/CJ_ship-feature COMPLETE (green)  multi_story=$MULTI_STORY

Run ID:        $RUN_ID
Design:        $DESIGN_DOC
Work item:     ${WORK_ITEM_DIR:-N/A}
PR:            ${PR_URL:-N/A}
Tracker:       ${TRACKER_PATH:-N/A}
Pipeline log:  $PIPELINE_DECISION_LOG (filter by run_id=$RUN_ID for this run's decisions)
Telemetry:     ~/.gstack/analytics/CJ_ship-feature.jsonl
```

Otherwise (any halt or `deploy_red`):

```
/CJ_ship-feature HALTED at end_state=$END_STATE

Run ID:        $RUN_ID
Design:        $DESIGN_DOC
Work item:     ${WORK_ITEM_DIR:-N/A (halt before work-item created)}
PR:            ${PR_URL:-N/A (halt before PR created)}
Tracker:       ${TRACKER_PATH:-N/A}
Pipeline log:  $PIPELINE_DECISION_LOG (filter by run_id=$RUN_ID)
Telemetry:     ~/.gstack/analytics/CJ_ship-feature.jsonl

Resume: re-invoke /CJ_ship-feature on the same design doc, OR continue manually
from the failed phase (each sub-skill has its own idempotent re-entry).
```

### Step 6.3: Pipeline-decision audit tail

If `$PIPELINE_DECISION_LOG` exists and has entries with this run's `run_id`,
print the count summary. Informational only — not an AUQ.

```bash
source "$STATE_FILE"
if [ -s "$PIPELINE_DECISION_LOG" ] && command -v jq >/dev/null 2>&1; then
  # Filter to this run only (the pipeline writes to the shared standalone log
  # tagged with its OWN run_id, which equals the wrapper's RUN_ID because we
  # don't override it — the pipeline computes its run_id at its Step 1 and
  # writes to the standalone log per its default behavior with the soft-warning
  # acknowledging co-mingling).
  THIS_RUN=$(jq -cs --arg rid "$RUN_ID" 'map(select(.run_id == $rid))' "$PIPELINE_DECISION_LOG" 2>/dev/null || echo "[]")
  COUNT_MECHANICAL=$(echo "$THIS_RUN" | jq 'map(select(.classification == "mechanical")) | length' 2>/dev/null || echo 0)
  COUNT_TASTE=$(echo "$THIS_RUN" | jq 'map(select(.classification == "taste")) | length' 2>/dev/null || echo 0)
  COUNT_UC_APPROVED=$(echo "$THIS_RUN" | jq 'map(select(.classification == "user_challenge_approved")) | length' 2>/dev/null || echo 0)
  TOTAL=$((COUNT_MECHANICAL + COUNT_TASTE + COUNT_UC_APPROVED))
  if [ "$TOTAL" -gt 0 ]; then
    cat <<EOF

Suppressed-gate pipeline decisions (this run only):
  - $COUNT_MECHANICAL mechanical (silent, see log for details)
  - $COUNT_TASTE taste
  - $COUNT_UC_APPROVED user-challenge-approved
Filter: jq -c '. | select(.run_id == "$RUN_ID")' $PIPELINE_DECISION_LOG
EOF
  fi
fi
```

**NOTE on the pipeline's run_id**: the wrapper does NOT override the pipeline's
decision log path via env var (env vars don't propagate cleanly across
Skill-tool boundaries — see F2 fix in PR2 review). The pipeline writes to its
standalone log (`~/.gstack/analytics/CJ_personal-pipeline-auto-decisions.jsonl`)
with its own run_id, which is computed independently inside the pipeline's
Step 1. The wrapper filters by THE PIPELINE'S run_id, NOT the wrapper's
RUN_ID — they're different. To find the pipeline's run_id, parse the tracker
journal entry written by the suppress-final-gate path:
`grep '\[auto-final-gate-suppressed\]' "$TRACKER_PATH"` (the entry includes
the decision log path which embeds the pipeline's run_id pattern). For v1,
audit-tail print accepts that finding the right entries may require a manual
`jq` filter; the path is documented for the user. **v1 accepts this minor
audit-discovery friction; v1.1 may pass RUN_ID explicitly via pipeline CLI arg.**

### Step 6.4: Exit appropriately

After Step 6.1-6.3 complete, proceed to Step 7 (sunset check — also universal).
Step 7 finishes by exiting with code 0 on `END_STATE=green` or non-zero
otherwise.

---

## Step 7: Sunset checkpoint — runs on every exit path

**Always runs after Step 6**, regardless of `END_STATE`. The sunset trip-wire
needs to see halted runs to detect brittleness; gating it on green-only would
neuter its purpose.

```bash
source "$STATE_FILE"
TELEMETRY="$HOME/.gstack/analytics/CJ_ship-feature.jsonl"

# This run's telemetry line was just appended by Step 6.1.
# INVOCATION_COUNT includes this run.
INVOCATION_COUNT=$(wc -l < "$TELEMETRY" 2>/dev/null | tr -d ' ')
INVOCATION_COUNT=${INVOCATION_COUNT:-0}

# Fire on invocation 6, then every 5 thereafter (11, 16, 21, ...).
SHOULD_FIRE=0
if [ "$INVOCATION_COUNT" -ge 6 ] && [ $(( (INVOCATION_COUNT - 6) % 5 )) -eq 0 ]; then
  SHOULD_FIRE=1
fi

if [ "$SHOULD_FIRE" = "1" ]; then
  # Take the 5 runs immediately before THIS one (the latest line is current run).
  PRIOR_5=$(tail -6 "$TELEMETRY" | head -5)

  # Brittleness signal: halted_at_(autoplan|pipeline|deploy) or subagent_crashed.
  # Excludes: green (happy path), halted_at_ship (review caught real issue),
  # deploy_red (production state, not wrapper brittleness), multi_story rows.
  #
  # F4 FIX: separate grep -c from the || fallback. grep -c always emits a count
  # (even 0) and may exit 1 on no-matches; the outer `|| echo 0` would APPEND
  # a second "0" producing "0\n0" which fails integer comparison. Pattern below
  # captures grep's exit explicitly without ever appending.
  HALT_COUNT=$(echo "$PRIOR_5" \
    | jq -r 'select((.multi_story_scaffold_only // false) == false) | .end_state' 2>/dev/null \
    | grep -cE '^(halted_at_autoplan|halted_at_pipeline|halted_at_deploy|subagent_crashed)$') || HALT_COUNT=0
  HALT_COUNT=${HALT_COUNT:-0}

  if [ "$HALT_COUNT" -ge 3 ]; then
    SUNSET_REC="DELETE"
  else
    SUNSET_REC="KEEP"
  fi

  # Render human-readable PRIOR_5 summary for the AUQ body.
  PRIOR_5_SUMMARY=$(echo "$PRIOR_5" | jq -r '"  - end_state=\(.end_state)  multi_story=\(.multi_story_scaffold_only // false)  design=\(.design_doc | split("/") | last)"' 2>/dev/null || echo "  (unable to parse PRIOR_5)")

  # AskUserQuestion (wrapper-rendered checkpoint AUQ — NOT a sub-skill pass-through).
  # Surfaces only on the 6th invocation and every 5 thereafter; rendered by the
  # wrapper itself (AskUserQuestion is in SKILL.md allowed-tools).
  #
  # AUQ body:
  #   /CJ_ship-feature sunset checkpoint (invocation $INVOCATION_COUNT). Prior 5 runs:
  #   $PRIOR_5_SUMMARY
  #
  #   Trip-wire: $HALT_COUNT/5 brittleness-signal end_states
  #   (halted_at_autoplan | halted_at_pipeline | halted_at_deploy | subagent_crashed).
  #   Excluded: green, halted_at_ship (healthy review catch), deploy_red (prod
  #   state), multi-story rows.
  #
  #   Recommendation: $SUNSET_REC.
  #
  #   Options:
  #   - Keep (skill stays as-is; checkpoint recurs every 5 invocations)
  #   - Delete (recommended if HALT_COUNT >= 3; otherwise honest opt-out)
fi
```

On Delete: print instructions to delete the skill (orchestrator does NOT
auto-delete — destructive actions require explicit user execution):

```
To delete /CJ_ship-feature:
  rm -rf <workbench>/skills/CJ_ship-feature/
  Strike the row from <workbench>/skills-catalog.json
  cd <workbench> && ./scripts/skills-deploy install
```

### Step 7.1: Exit with appropriate code

```bash
source "$STATE_FILE"
# Cleanup state file (optional; tmpfiles will eventually reap it)
rm -f "$STATE_FILE" 2>/dev/null

if [ "$END_STATE" = "green" ]; then
  exit 0
else
  exit 1
fi
```

---

## Error / Abort Contract

- **Idempotent**: each sub-skill owns its own re-entry path. Wrapper re-invocation
  on the same design doc:
  - /autoplan re-reviews (v1 cost; v1.1 skip-if-reviewed deferred).
  - CJ_personal-pipeline branch (a) check reuses work-item dir if scaffolded.
  - /ship checks for existing PR via `gh pr list --head <branch>`.
  - /land-and-deploy checks deploy state.
- **Halt-on-red, no auto-rollback**: any non-green outcome exits non-zero with diagnostic. User resumes manually per phase.
- **Cancel (Ctrl-C)**: kills wrapper; sub-skill state is whatever was last written to disk. Re-invoke to resume. Note: telemetry write happens only at Step 6 — Ctrl-C aborts before that leave no telemetry line. (Documented limitation; sunset cadence treats this as "didn't count.")

## Decision Gates (AskUserQuestion)

The wrapper-orchestrated AUQ count is **2 wrapper-gated decisions** (autoplan
final + /ship diff review) plus 1 occasional checkpoint:

- **GATE #1 — /autoplan final-approval AUQ** (Step 2) — design-level decisions (sub-skill native; surfaces in wrapper's conversation context)
- **GATE #2 — /ship pre-PR diff-review AUQ** (Step 4) — code-level decisions (sub-skill native)
- **Wrapper-rendered checkpoint AUQ — sunset (Step 7)** — fires on invocations 6, 11, 16, ... Not a per-run gate; only fires every 5th run after invocation 6. Rendered by the wrapper itself (AskUserQuestion is declared in SKILL.md `allowed-tools`).

**Sub-skill native AUQs that pass through** (wrapper doesn't introduce; sub-skill surfaces them naturally): /autoplan premise gate, /ship pre-flight halts (test red, scope drift, etc.), /land-and-deploy readiness gate (Step 3.5 of /land-and-deploy).

CJ_personal-pipeline's 8.5 + 9.2 AUQs are SUPPRESSED via the
`--suppress-final-gate` contract shipped in v2.1.4 (PR #95). Decisions are
written to `$PIPELINE_DECISION_LOG` and surfaced in the Step 6 final-summary tail
(informational, not an AUQ).

## Token Budget Notes

- /autoplan inline load: ~3-5K tokens for autoplan SKILL.md + sub-skill chain.
- /ship inline load: ~3K tokens for ship SKILL.md.
- /land-and-deploy inline load: ~1K tokens.
- CJ_personal-pipeline subagent: own fresh context, returns ~200 tokens (RESULT line + journal pointer).

Wrapper context grows by ~7-9K tokens across phases. If the wrapper hits
compaction mid-run on a real first try, refactor /autoplan to subagent dispatch
in v1.1 (requires gstack-side accommodation for AUQ relay, out of scope for v1).
