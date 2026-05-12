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

## Step 1: Validate Input

Parse the user's argument and set up shared state.

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

# Capture absolute path + generate run id
DESIGN_DOC=$(realpath "$DESIGN_DOC")
RUN_ID="$(date +%Y%m%d-%H%M%S)-$$"

# Shared decision log paths
# - WRAPPER_DECISION_LOG: reserved for v1.1+ wrapper-level auto-decisions (zero in v1)
# - PIPELINE_DECISION_LOG: per-run, consumed from the pipeline subagent
mkdir -p "$HOME/.gstack/analytics"
WRAPPER_DECISION_LOG="$HOME/.gstack/analytics/CJ_ship-feature-decisions.jsonl"
PIPELINE_DECISION_LOG="/tmp/cj-ship-feature-$RUN_ID-pipeline-decisions.jsonl"

# Initialize end_state; updated as phases complete or halt.
END_STATE="green"
MULTI_STORY=0
WORK_ITEM_DIR=""
PR_URL=""
```

Remember `$RUN_ID`, `$DESIGN_DOC`, `$PIPELINE_DECISION_LOG`, `$END_STATE`,
`$MULTI_STORY`, `$WORK_ITEM_DIR`, `$PR_URL` as prose state throughout the run —
bash variables don't persist across orchestrator-model Bash calls; the model
threads literal values into subsequent commands.

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
- **/autoplan aborted at final-approval AUQ or pre-flight halt**: set `END_STATE=halted_at_autoplan`; write telemetry (Step 6 with `WORK_ITEM_DIR=""` and `PR_URL=""`); exit non-zero with tail summary:
  ```
  Wrapper halted at /autoplan final gate.
  Re-invoke /CJ_ship-feature when ready; /autoplan re-runs (3-10 min cost — wrapper-level skip-if-reviewed is deferred to v1.1).
  ```

**Re-entry note**: on wrapper re-invocation, /autoplan re-runs its full review — it
appends a new `## GSTACK REVIEW REPORT` block on each invocation. v1 accepts this
cost; v1.1 will add wrapper-level skip-if-reviewed (grep design doc for the report
header before invoking).

---

## Step 3: Phase 2 — `CJ_personal-pipeline` (Agent subagent, suppress-final-gate)

Spawn an Agent subagent via the Agent tool with `subagent_type: "general-purpose"`.
The subagent invokes `/CJ_personal-pipeline` with `--suppress-final-gate` and exports
`GSTACK_PIPELINE_DECISION_LOG_PATH` pointing at our per-run path.

**Subagent prompt** (substitute `$PIPELINE_DECISION_LOG` and `$DESIGN_DOC` literally
at dispatch time — bash variables don't cross orchestrator-model Bash calls, so the
prompt template carries the literal path):

```
ROLE: pipeline runner for /CJ_ship-feature wrapper.
TASK: invoke /CJ_personal-pipeline in --suppress-final-gate mode. The wrapper
is consuming the decision log; do NOT surface Step 8.5 or Step 9.2 AUQs.

STEPS:
1. Run this bash command first:
   export GSTACK_PIPELINE_DECISION_LOG_PATH="<literal $PIPELINE_DECISION_LOG path>"
2. Then invoke the slash command:
   /CJ_personal-pipeline --suppress-final-gate "<literal $DESIGN_DOC path>"
3. Follow the pipeline through its normal phases (scaffold → impl → QA + post-phase
   gates). It will skip 8.5 + 9.2 AUQs per the suppress-final-gate contract; tracker
   journal will record [auto-pipeline-clean] (zero-decision) or
   [auto-final-gate-suppressed] (non-zero).

RETURN CONTRACT: end your final assistant message with this exact line on its own:
  RESULT: PIPELINE_END_STATE=<green|halted_at_gate|user_aborted|subagent_crashed>; WORK_ITEM_DIR=<absolute_path>

No prose after the RESULT line. If the pipeline halts mid-flow, set
PIPELINE_END_STATE accordingly and include the work-item dir path that was created
(even on halt, scaffold may have completed).
```

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

Set `END_STATE=halted_at_pipeline`; write telemetry; exit non-zero with tail summary:

```
Wrapper halted at CJ_personal-pipeline.
  Pipeline end_state:    <PIPELINE_END_STATE>
  Work item:             <WORK_ITEM_DIR>
  Tracker:               <WORK_ITEM_DIR>/<TRACKER>.md (find via *_TRACKER.md)
  Pipeline decision log: <PIPELINE_DECISION_LOG>

Inspect the tracker journal for halt reason. Re-invoke /CJ_ship-feature to resume
(pipeline's Branch (a) skip path reuses the existing scaffold). If pipeline halted
mid-impl with green-enough state, you can manually invoke /ship + /land-and-deploy
to finish from here.
```

### Branch (d): empty / no RESULT

`parse_result` returned empty (subagent crashed without emitting RESULT line).

Set `END_STATE=subagent_crashed`; write telemetry; exit non-zero with:

```
CJ_personal-pipeline subagent crashed (no RESULT line emitted).
Re-invoke /CJ_ship-feature — pipeline's Branch (a) idempotency will resume from
disk state if the work-item dir was created before the crash.
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

Set `END_STATE=halted_at_ship`; write telemetry; exit non-zero with tail summary:

```
Wrapper halted at /ship.
  Work item:             <WORK_ITEM_DIR>
  Branch (commits exist but no PR): <current branch>
  Pipeline decision log: <PIPELINE_DECISION_LOG>

Commits from CJ_personal-pipeline are local on the branch. /ship may have done
partial work (version bump, CHANGELOG entry, even a draft commit) before halting.
To resume: manually invoke /ship (its idempotency will detect existing commits
and the in-progress state).

Note: halted_at_ship is treated as a healthy outcome by the sunset trip-wire —
it means /ship's review caught a real issue. Re-invoke /CJ_ship-feature after the
issue is fixed, or invoke /ship directly to continue.
```

---

## Step 5: Phase 4 — `/land-and-deploy` (inline, non-AUQ on green)

Reached only on Branch (a) of Step 4 (/ship green, PR created).

Invoke `/land-and-deploy` via the **Skill tool** with the PR number as argument:

```
/land-and-deploy #<PR_NUMBER>
```

(Parse PR number from `$PR_URL` — typically the last path segment.)

`/land-and-deploy` waits for CI, merges the PR, monitors any post-merge deploy
workflow, runs canary verification if a production URL was configured, and
writes its own deploy report.

### Branch (a): green deploy

`/land-and-deploy` completes with verdict `DEPLOYED AND VERIFIED` (or
`DEPLOYED (UNVERIFIED)` if no URL was configured — both count as green).

`END_STATE=green`. Continue to Step 6.

### Branch (b): canary red

`/land-and-deploy` completes with verdict `DEPLOY_RED` (canary failed
post-merge).

Set `END_STATE=deploy_red`; write telemetry; exit non-zero with tail summary:

```
Canary red post-merge. See /land-and-deploy report.
  PR: <PR_URL> (merged)
  Manual action needed: rollback OR fix-forward.

Note: deploy_red is excluded from the sunset trip-wire — production health
concerns are separate from wrapper orchestration brittleness.
```

### Branch (c): /land-and-deploy halted pre-merge

CI red, merge conflict, or user aborted at /land-and-deploy's readiness gate.

Set `END_STATE=halted_at_deploy`; write telemetry; exit non-zero with summary
naming the halt reason.

---

## Step 6: Final summary + telemetry

Resolve the tracker path lazily from `WORK_ITEM_DIR`:

```bash
TRACKER_PATH=""
if [ -n "$WORK_ITEM_DIR" ]; then
  TRACKER_PATH=$(find "$WORK_ITEM_DIR" -maxdepth 1 -name '*_TRACKER.md' -print -quit 2>/dev/null)
  [ -z "$TRACKER_PATH" ] && TRACKER_PATH="$WORK_ITEM_DIR (TRACKER not found)"
fi
```

Print the summary:

```
/CJ_ship-feature COMPLETE: end_state=$END_STATE  multi_story=$MULTI_STORY

Run ID:        $RUN_ID
Design:        $DESIGN_DOC
Work item:     ${WORK_ITEM_DIR:-N/A}
PR:            ${PR_URL:-N/A}
Tracker:       ${TRACKER_PATH:-N/A}
Pipeline log:  $PIPELINE_DECISION_LOG (suppressed-gate decisions from this run)
Telemetry:     ~/.gstack/analytics/CJ_ship-feature.jsonl
```

Then write the telemetry line. Use jq for JSON-safe escaping:

```bash
MULTI_STORY_BOOL=$([ "$MULTI_STORY" = "1" ] && echo "true" || echo "false")

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
```

If jq is unavailable (shouldn't happen — workbench declared dep), fall back to a
sanitized echo (strip backslashes + double-quotes from paths).

### Final-summary tail — suppressed pipeline decisions

After telemetry write, print the suppressed-gate decision audit for this run
(informational, NOT an AUQ — user can spot-check post-deploy if anything looks
off; revert is via normal git):

```bash
if [ -s "$PIPELINE_DECISION_LOG" ]; then
  COUNT_MECHANICAL=$(jq -s 'map(select(.classification == "mechanical")) | length' "$PIPELINE_DECISION_LOG" 2>/dev/null || echo 0)
  COUNT_TASTE=$(jq -s 'map(select(.classification == "taste")) | length' "$PIPELINE_DECISION_LOG" 2>/dev/null || echo 0)
  COUNT_UC_APPROVED=$(jq -s 'map(select(.classification == "user_challenge_approved")) | length' "$PIPELINE_DECISION_LOG" 2>/dev/null || echo 0)
  cat <<EOF
Suppressed-gate pipeline decisions (this run):
  - $COUNT_MECHANICAL mechanical (silent, see log for details)
  - $COUNT_TASTE taste
  - $COUNT_UC_APPROVED user-challenge-approved
Review at: $PIPELINE_DECISION_LOG
EOF
fi
```

---

## Step 7: Sunset checkpoint (6th invocation, every 5 thereafter)

Mirror `/CJ_personal-pipeline`'s pattern.

```bash
TELEMETRY="$HOME/.gstack/analytics/CJ_ship-feature.jsonl"
INVOCATION_COUNT=$(wc -l < "$TELEMETRY" | tr -d ' ')

# Fire on invocation 6, then every 5 thereafter (11, 16, 21, ...)
if [ "$INVOCATION_COUNT" -ge 6 ] && [ $(( (INVOCATION_COUNT - 6) % 5 )) -eq 0 ]; then
  PRIOR_5=$(tail -6 "$TELEMETRY" | head -5)  # 5 runs immediately before this one

  # Brittleness signal: halted_at_(autoplan|pipeline|deploy) or subagent_crashed.
  # Excludes: green (happy path), halted_at_ship (review caught real issue),
  # deploy_red (production state, not wrapper brittleness), multi_story rows.
  HALT_COUNT=$(echo "$PRIOR_5" \
    | jq -r 'select(.multi_story_scaffold_only != true) | .end_state' \
    | grep -cE '^(halted_at_autoplan|halted_at_pipeline|halted_at_deploy|subagent_crashed)$' \
    || echo 0)

  if [ "$HALT_COUNT" -ge 3 ]; then
    SUNSET_REC="DELETE"
  else
    SUNSET_REC="KEEP"
  fi
fi
```

If `INVOCATION_COUNT >= 6` AND the modulo condition fires, AskUserQuestion:

> /CJ_ship-feature sunset checkpoint (invocation $INVOCATION_COUNT). Prior 5 runs:
> <human-readable summary of $PRIOR_5: one line per run with end_state + design doc basename>
>
> Trip-wire: $HALT_COUNT/5 brittleness-signal end_states (halted_at_autoplan / halted_at_pipeline / halted_at_deploy / subagent_crashed).
> Excluded from count: green, halted_at_ship (healthy review catch), deploy_red (prod state), multi-story rows.
>
> Recommendation: $SUNSET_REC.
>
> Options:
> - Keep (skill stays as-is; checkpoint recurs every 5 invocations)
> - Delete (recommended if $HALT_COUNT >= 3; otherwise honest opt-out)

On Delete: print instructions to delete the skill:

```
To delete /CJ_ship-feature:
  rm -rf <workbench>/skills/CJ_ship-feature/
  Strike the row from <workbench>/skills-catalog.json
  cd <workbench> && ./scripts/skills-deploy install
```

The orchestrator does NOT auto-delete — destructive actions require explicit user execution.

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

The wrapper itself introduces NO AUQs in v1 — every decision is owned by a
sub-skill and surfaces naturally in the orchestrator's conversation context:

- **GATE #1 — /autoplan final-approval AUQ** (Step 2) — design-level decisions
- **GATE #2 — /ship pre-PR diff-review AUQ** (Step 4) — code-level decisions
- **Sub-skill native AUQs** that pass through: /autoplan premise gate, /ship pre-flight halts, /land-and-deploy readiness gate, sunset-checkpoint AUQ (Step 7)

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
