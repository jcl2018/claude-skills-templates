# /CJ_goal_run — Orchestration

Unified pipeline entry point with three input shapes:

```
/CJ_goal_run <design-doc-path>       → Branches (a/b/c/d): full pipeline
/CJ_goal_run <work-item-dir>         → Branch (f): phase-detect + dispatch
/CJ_goal_run                         → Branch (g): scan branch + auto-resume
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

Design-doc mode (Branch c) flow:

```
/office-hours (manual, separate)
    ↓ produces APPROVED design doc
/CJ_goal_run <design-doc-path>
    ├── Phase 1: /autoplan          (Skill, inline)  [GATE #1: final-approval AUQ]
    ├── Phase 2: CJ_personal-pipeline (Agent subagent, --suppress-final-gate)
    │              └── scaffold → impl → QA (8.5 + 9.2 AUQs suppressed)
    ├── Phase 3: /ship               (Skill, inline)  [GATE #2: diff-review AUQ]
    └── Phase 4: /land-and-deploy    (Skill, inline)  [auto on green; alert on red]
```

Branch(f) (work-item-dir) and Branch(g) (no-arg) are added in v0.2.0. Branch(f)
full impl_qa_ship dispatch depends on CJ_personal-pipeline's `--work-item-dir` flag
(F000016/S000036). Branch(g) implementation is in this file (S000038); Branch(f)
implementation lands in S000039.

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

## Step 1: Validate Input + Dispatch + Initialize state file

Detect the input shape and dispatch to the appropriate branch. **All state lives in a per-run
state file** (`/tmp/cj-run-$RUN_ID.env`) — every subsequent step's bash
block starts by sourcing this file. This solves the "bash variables don't cross
orchestrator-model Bash tool calls" problem (the failure mode PR1 caught at v2.1.4).

### Step 1.0: Input shape detection

Pre-pass for the Phase 5 escape hatch (`--no-drain`). Reuses the same
"accepted-and-discarded flag" pattern that `/CJ_personal-pipeline` uses for
`--auto`/`--manual` (see SKILL.md Usage). The flag is recognized at any
position in the arg list and stripped before input-shape detection; the
remaining positional arg(s) are passed through unchanged.

```bash
# Phase 5 flag parsing: --no-drain skips Phase 5 entirely.
# Default: NO_DRAIN_FLAG=0 (Phase 5 runs as designed).
#
# Handoff flags (F000026 / S000056 / /CJ_goal_auto integration):
# Two SEPARATE flags with distinct semantics:
#   --handoff               -> HANDOFF_FLAG=1            (signals "called via /CJ_goal_auto")
#   --auto-merge-small-diffs -> AUTO_MERGE_SMALL_DIFFS=1 (operator opted into auto-merge)
#
# Default (legacy direct /CJ_goal_run, neither flag): Step 4.5 is a no-op;
# /ship creates the PR and Phase 4 /land-and-deploy --suppress-readiness-gate
# runs as usual. Behavior is UNCHANGED from pre-F000026.
#
# /CJ_goal_auto default mode (--handoff alone, NO --auto-merge-small-diffs):
# Step 4.5 HALTS after /ship — the PR is review-ready, operator merges
# manually via `gh pr diff` / `gh pr merge`. This is the "exactly one
# mandatory human touchpoint" promised by the /CJ_goal_auto design.
#
# /CJ_goal_auto auto-merge mode (BOTH --handoff AND --auto-merge-small-diffs):
# Step 4.5 runs scripts/cj-handoff-gate.sh. Exit 0 -> proceed to Phase 4
# (auto-merge); non-zero -> halt for human review (PR exists; operator merges
# manually).
NO_DRAIN_FLAG=0
HANDOFF_FLAG=0
AUTO_MERGE_SMALL_DIFFS=0
_FILTERED_ARGS=()
for _A in "$@"; do
  case "$_A" in
    --no-drain) NO_DRAIN_FLAG=1 ;;
    --handoff) HANDOFF_FLAG=1 ;;
    --auto-merge-small-diffs) AUTO_MERGE_SMALL_DIFFS=1 ;;
    *) _FILTERED_ARGS+=("$_A") ;;
  esac
done
# Re-bind positional args to the filtered list (drops --no-drain/--handoff/--auto-merge-small-diffs if present).
set -- "${_FILTERED_ARGS[@]}"

ARG="${1:-}"

if [ -z "$ARG" ]; then
  INPUT_MODE="no-arg"
elif [ -f "$ARG" ] && [[ "$ARG" == *.md ]]; then
  INPUT_MODE="design-doc"
elif [ -d "$ARG" ]; then
  # Verify it's a work-item dir (contains a *_TRACKER.md)
  if find "$ARG" -maxdepth 1 -name "*_TRACKER.md" 2>/dev/null | grep -q .; then
    INPUT_MODE="work-item-dir"
  else
    echo "Error: $ARG is not a work-item directory (no TRACKER.md). Run /CJ_scaffold-work-item first."
    exit 1
  fi
else
  echo "Error: cannot identify input. Pass a design-doc path (*.md), a work-item dir, or no arg."
  exit 1
fi
echo "INPUT_MODE: $INPUT_MODE"
echo "NO_DRAIN_FLAG: $NO_DRAIN_FLAG"
echo "HANDOFF_FLAG: $HANDOFF_FLAG"
echo "AUTO_MERGE_SMALL_DIFFS: $AUTO_MERGE_SMALL_DIFFS"
```

### Step 1.0.g: Branch(g) — no-arg branch scan (S000038, T000026)

Runs when `INPUT_MODE = no-arg`. Scans `work-items/` for in-progress user-story
TRACKERs on the current worktree. Scope: user-story TRACKERs only (gate strings
below are user-story-specific; defect/task TRACKERs use different phrasing —
v0.3 may extend).

Bash 3.2 compatible: uses `while IFS= read -r` (not `mapfile -t`).

Gate strings are verbatim from `templates/CJ_personal-workflow/tracker-user-story.md`
Phase 2 Gates: `Todos section reflects remaining work`. If those strings change in
the template, this scan breaks silently — keep an eye on template drift.

**PR-state dedup (T000026):** After the gate-state filter, each remaining
candidate is checked against its PR state via `gh pr view --json state` and
excluded if `MERGED`. PR URLs are read from either the optional `pr:` frontmatter
field (machine-readable shortcut) OR the canonical `## PRs` section markdown
links — same dual-convention pattern Branch(f) uses at line ~225. The dedup
exists to catch the edge case where a tracker was force-merged or hand-edited
past the gate-state filter (e.g. Phase 3 `/ship` / `/land-and-deploy` gates
left unchecked even though the PR is merged); without it, Branch(g) would
auto-resume a work-item that's actually shipped. `gh pr view` is best-effort
— offline / unauthenticated / unknown-state responses fall back to "include
the candidate" (default-permissive on lookup failure; the operator gets to
choose at the multi-candidate AUQ rather than getting a silent exclusion).
Results are cached in an associative array keyed by PR URL to avoid N
round-trips when the same URL appears across multiple candidates (rare but
cheap to memoize).

```bash
if [ "$INPUT_MODE" = "no-arg" ]; then
  REPO_ROOT=$(git rev-parse --show-toplevel)
  if [ ! -d "$REPO_ROOT/work-items" ]; then
    echo "No work-items/ found. Run /office-hours or /CJ_scaffold-work-item first."
    exit 0
  fi

  # PR-state cache (T000026): keyed by PR URL → state string (MERGED/OPEN/DRAFT/UNKNOWN).
  # Bash 3.2 compatible: simple parallel-array memo (no associative arrays).
  PR_CACHE_URLS=()
  PR_CACHE_STATES=()
  pr_cache_lookup() {
    local url="$1"
    local i=0
    while [ "$i" -lt "${#PR_CACHE_URLS[@]}" ]; do
      if [ "${PR_CACHE_URLS[$i]}" = "$url" ]; then
        echo "${PR_CACHE_STATES[$i]}"
        return 0
      fi
      i=$((i + 1))
    done
    return 1
  }
  pr_cache_store() {
    PR_CACHE_URLS+=("$1")
    PR_CACHE_STATES+=("$2")
  }

  CANDIDATES=()
  while IFS= read -r f; do
    [ -z "$f" ] && continue
    # Type filter: user-story only in v0.2 (gate strings below are user-story-specific)
    TYPE=$(grep "^type:" "$f" | head -1 | sed 's/type: *//' | tr -d '"' | tr -d ' ')
    [ "$TYPE" != "user-story" ] && continue
    # Phase 1 Gates block: scope to "**Gates:**" sub-block under "### Phase 1:"
    # Pattern: extract Phase 1 section, then within it extract the Gates sub-block
    P1_GATES=$(sed -n '/### Phase 1:/,/^### Phase [^1]/p' "$f" | sed -n '/\*\*Gates:\*\*/,/^$/p')
    P1_TOTAL=$(echo "$P1_GATES" | grep -c "^- \[.\]")
    P1_DONE=$(echo "$P1_GATES" | grep -c "^- \[x\]")
    # Phase 2 implementer-owned gates: BOTH must be [x] for impl to be done
    P2_IMPL=$(grep "Todos section reflects remaining work" "$f" | grep -c "\[x\]")
    P2_FILES=$(grep "Files section updated with changed files" "$f" | grep -c "\[x\]")
    # Phase 2 QA-owned gates: if BOTH checked AND a [qa-pass] entry exists, story is QA'd
    # If story is QA'd OR Phase 3 ship gates are checked, exclude (it's shipped or shipping)
    P2_AC=$(grep "Acceptance criteria verified met" "$f" | grep -c "\[x\]")
    P3_SHIP=$(grep -E "\`/ship\` — PR created|/ship — PR created" "$f" | grep -c "\[x\]")
    P3_DEPLOY=$(grep -E "\`/land-and-deploy\` — merged|/land-and-deploy — merged" "$f" | grep -c "\[x\]")
    # In-progress = Phase 1 fully green AND impl not started (no implementer-owned gates checked)
    # AND not yet QA'd AND not yet shipped/deployed
    if [ "$P1_TOTAL" = "$P1_DONE" ] && [ "$P1_TOTAL" -gt 0 ] \
       && [ "$P2_IMPL" = "0" ] && [ "$P2_FILES" = "0" ] \
       && [ "$P2_AC" = "0" ] && [ "$P3_SHIP" = "0" ] && [ "$P3_DEPLOY" = "0" ]; then
      # PR-state dedup (T000026): explicit MERGED check.
      # PR URL: check frontmatter `pr:`/`PR:` field first (machine-readable shortcut),
      # then ## PRs section markdown links (canonical). Mirrors Branch(f) at line ~225.
      C_PR_URL=$(grep -E "^pr: |^PR: " "$f" 2>/dev/null | head -1 | sed -E 's/^[pP][rR]: *//' | tr -d '"' | tr -d ' ')
      if [ -z "$C_PR_URL" ]; then
        C_PR_URL=$(awk '/^## PRs/,/^## [^P]/' "$f" 2>/dev/null | grep -oE 'https?://[^ )]+/pull/[0-9]+' | head -1)
      fi
      if [ -n "$C_PR_URL" ]; then
        # Cache lookup; populate on miss via `gh pr view`. Best-effort: any failure
        # path (offline, unauthenticated, unknown URL) yields UNKNOWN → include
        # the candidate (default-permissive).
        C_PR_STATE=$(pr_cache_lookup "$C_PR_URL")
        if [ -z "$C_PR_STATE" ]; then
          C_PR_STATE=$(gh pr view "$C_PR_URL" --json state -q .state 2>/dev/null || echo "UNKNOWN")
          pr_cache_store "$C_PR_URL" "$C_PR_STATE"
        fi
        if [ "$C_PR_STATE" = "MERGED" ]; then
          # PR is merged but tracker gates weren't transitioned → force-merged or
          # hand-edited. Exclude. Print an audit line so the operator sees why.
          echo "BRANCH_G_EXCLUDE: $f (PR $C_PR_URL is MERGED but tracker gates open)"
          continue
        fi
      fi
      CANDIDATES+=("$f")
    fi
  done < <(find "$REPO_ROOT/work-items" -name "*_TRACKER.md" 2>/dev/null)

  N_CANDIDATES=${#CANDIDATES[@]}
  echo "BRANCH_G_CANDIDATES: $N_CANDIDATES"
  for c in "${CANDIDATES[@]}"; do echo "  $c"; done

  if [ "$N_CANDIDATES" -eq 0 ]; then
    echo "Nothing to resume. Run /office-hours or /CJ_scaffold-work-item first."
    exit 0
  elif [ "$N_CANDIDATES" -eq 1 ]; then
    # Single candidate: extract work-item dir and switch to work-item-dir mode
    PICKED_TRACKER="${CANDIDATES[0]}"
    ARG=$(dirname "$PICKED_TRACKER")
    INPUT_MODE="work-item-dir"
    echo "Branch(g) auto-picked: $ARG"
  else
    # Multiple candidates: orchestrator-mediated AUQ required.
    # SKILL-level bash blocks cannot invoke AskUserQuestion directly; the
    # orchestrator (model) reads this output and renders the AUQ. The
    # MULTI_CANDIDATE_AUQ_REQUIRED marker tells the orchestrator to
    # call AskUserQuestion before continuing. Exit non-zero to signal
    # "not auto-resumed; needs interactive selection" — distinguishing this
    # path from the single-candidate "auto-picked and proceeding" path.
    echo "MULTI_CANDIDATE_AUQ_REQUIRED N=$N_CANDIDATES"
    echo "Candidates:"
    for c in "${CANDIDATES[@]}"; do echo "  $(dirname "$c")"; done
    echo ""
    echo "Orchestrator: render AskUserQuestion with each candidate as an option."
    echo "On user selection, re-invoke /CJ_goal_run <selected-path> explicitly."
    exit 2
  fi
fi
```

### Step 1.1: Branch(f) — work-item-dir entry (S000039)

If `INPUT_MODE = work-item-dir` at this point (either passed directly OR set
by Branch(g) above), Branch(f) takes over: reads TRACKER phase state, resolves
MODE, dispatches to the right sub-pipeline. Self-contained — does NOT fall through
to Step 1.2 (design-doc branches).

**Type filter:** v0.2 supports user-story TRACKERs only. Gate strings are
verbatim from `templates/CJ_personal-workflow/tracker-user-story.md` Phase 2
Gates; defect/task TRACKERs use different phrasing (extend in v0.3).

**Gate strings** (canonical, must match the template):
- IMPL gate: `Todos section reflects remaining work`
- QA gate: `Acceptance criteria verified met`

If these strings change in the template, Branch(f) breaks silently.

```bash
if [ "$INPUT_MODE" = "work-item-dir" ]; then
  WORK_ITEM_DIR=$(realpath "$ARG")
  TRACKER=$(find "$WORK_ITEM_DIR" -maxdepth 1 \( -name "*_TRACKER.md" -o -name "TRACKER.md" \) 2>/dev/null | head -1)
  [ -z "$TRACKER" ] && { echo "Error: $WORK_ITEM_DIR is not a work-item directory (no TRACKER.md)"; exit 1; }
  WORK_ITEM_ID=$(basename "$TRACKER" | sed 's/_TRACKER\.md$//')

  # Type filter: user-story only in v0.2
  TRACKER_TYPE=$(grep "^type:" "$TRACKER" | head -1 | sed 's/type: *//' | tr -d '"' | tr -d ' ')
  if [ "$TRACKER_TYPE" != "user-story" ]; then
    echo "Error: Branch(f) v0.2 supports user-story TRACKERs only (got: $TRACKER_TYPE)"
    echo "Invoke sub-skills directly for defect/task types."
    exit 1
  fi

  # Phase state from canonical gate strings (verbatim from tracker-user-story.md)
  IMPL_GATE=$(grep "Todos section reflects remaining work" "$TRACKER" | grep -c "\[x\]")
  QA_GATE=$(grep "Acceptance criteria verified met" "$TRACKER" | grep -c "\[x\]")

  # PR URL: check frontmatter `pr:`/`PR:` field first, then ## PRs section markdown links.
  # Either convention is acceptable; check both for portability.
  PR_URL=$(grep -E "^pr: |^PR: " "$TRACKER" 2>/dev/null | head -1 | sed -E 's/^[pP][rR]: *//' | tr -d '"' | tr -d ' ')
  if [ -z "$PR_URL" ]; then
    PR_URL=$(awk '/^## PRs/,/^## [^P]/' "$TRACKER" 2>/dev/null | grep -oE 'https?://[^ )]+/pull/[0-9]+' | head -1)
  fi

  # Resolve MODE via case ladder
  if [ "$IMPL_GATE" = "0" ]; then
    MODE="impl_qa_ship"
  elif [ "$QA_GATE" = "0" ]; then
    MODE="qa_ship"
  elif [ -z "$PR_URL" ]; then
    MODE="ship"
  else
    # `gh pr view` is best-effort; offline/unauthenticated → UNKNOWN → pr_unknown_state
    PR_STATE=$(gh pr view "$PR_URL" --json state -q .state 2>/dev/null || echo "UNKNOWN")
    case "$PR_STATE" in
      MERGED) MODE="already_shipped" ;;
      OPEN|DRAFT) MODE="open_pr" ;;
      *) MODE="pr_unknown_state" ;;
    esac
  fi

  echo "Branch(f) phase-detection: $WORK_ITEM_ID → MODE=$MODE (IMPL=$IMPL_GATE QA=$QA_GATE PR_URL=${PR_URL:-none})"

  # Telemetry skeleton (Branch(f) writes telemetry at end; END_STATE filled per-dispatch).
  # The orchestrator (model) reads $MODE and dispatches per the table below, then
  # writes the telemetry line at exit.
fi
```

### Step 1.1.dispatch: Branch(f) dispatch table

The orchestrator (model) reads `$MODE` from the bash output above and dispatches
based on this table. The dispatch is prose-level: bash variables don't persist
across orchestrator Bash calls, so the model carries `$MODE`, `$WORK_ITEM_DIR`,
`$PR_URL` as prose state.

| MODE | Action |
|---|---|
| `impl_qa_ship` | Dispatch `CJ_personal-pipeline` via **Agent** tool (subagent_type: general-purpose) with prompt: `Invoke CJ_personal-pipeline --work-item-dir "<WORK_ITEM_DIR>" --suppress-final-gate. Return the RESULT line.` After Agent returns: parse `PIPELINE_END_STATE`. On green, invoke `/ship` via Skill, then `/land-and-deploy` via Skill. Each step inherits the orchestrator's AUQ flow (Gate #2 at /ship review). |
| `qa_ship` | Invoke `/CJ_qa-work-item <WORK_ITEM_DIR>` via **Skill** tool. On green QA exit, invoke `/ship` via Skill, then `/land-and-deploy` via Skill. |
| `ship` | Invoke `/ship` via **Skill** tool. On success, invoke `/land-and-deploy` via Skill. |
| `open_pr` | Parse PR number inline (duplicate of Step 5's parsing block — see "Branch(f) open_pr PR_NUM parsing" below). Print `PR already open at $PR_URL. Continuing into /land-and-deploy...` for audit. Invoke `/land-and-deploy --suppress-readiness-gate #<PR_NUM>` via the **Skill** tool (or `/land-and-deploy --suppress-readiness-gate` if PR_NUM is empty — /land-and-deploy auto-detects from branch). Continue to Step 5's Branch (a/b/c) handling for verdict-based END_STATE assignment. Telemetry write happens at Step 6 (do NOT exit 0 here). |
| `already_shipped` | Print: `Already shipped at $PR_URL. Nothing to do.` Set `END_STATE=already_shipped`. Write telemetry. Exit 0. |
| `pr_unknown_state` | Present AskUserQuestion: `PR state for $WORK_ITEM_ID is unexpected (gh returned: $PR_STATE). What now?` Options: A) Retry /ship — assume PR is gone/closed (re-create), B) Treat as already shipped — exit clean, C) Abort. **No auto-decide.** Default to C (abort) for safety. |

#### Branch(f) `open_pr` PR_NUM parsing

The `open_pr` row above references "Parse PR number inline." This is a verbatim
duplicate of Step 5's PR_NUM parsing block (run.md ~lines 749-766). Duplicating
is the taste decision over extracting a /CJ_goal_run-internal helper: ~15 lines
duplicated is cheaper than introducing the abstraction for a single re-use
site.

```bash
# Parse PR number from $PR_URL (typically the last path segment, e.g. ".../pull/95")
PR_NUM="${PR_URL##*/}"
# Validate: must be numeric. Bail if not (PR_URL may be unusable).
if ! printf '%s' "$PR_NUM" | grep -qE '^[0-9]+$'; then
  # Try to recover via gh
  CURRENT_BRANCH=$(git branch --show-current)
  PR_NUM=$(gh pr list --head "$CURRENT_BRANCH" --state all --json number -q '.[0].number' 2>/dev/null || echo "")
fi
if ! printf '%s' "$PR_NUM" | grep -qE '^[0-9]+$'; then
  echo "WARNING: could not determine PR number. Invoking /land-and-deploy without arg (it will auto-detect from branch)."
  PR_NUM=""
fi
```

After parsing, the dispatch invokes `/land-and-deploy --suppress-readiness-gate
#<PR_NUM>` (or without the PR arg if PR_NUM is empty) via the **Skill** tool.
The verdict-handling Branches (a/b/c) defined in Step 5 apply: green verdict →
`END_STATE=green`; canary-revert → `END_STATE=deploy_red`; halted pre-merge →
`END_STATE=halted_at_deploy`. Step 6 writes the telemetry line.

After dispatch completes (or for graceful-exit modes), write the telemetry line:

```bash
# Run this after dispatch flow completes. END_STATE values:
#   green | halted_at_pipeline | halted_at_ship | halted_at_deploy
#   open_pr | already_shipped | user_aborted | subagent_crashed
RUN_ID="$(date +%Y%m%d-%H%M%S)-$$"
mkdir -p ~/.gstack/analytics
echo "{\"run_id\":\"$RUN_ID\",\"design_doc\":\"\",\"work_item\":\"$WORK_ITEM_DIR\",\"pr_url\":\"${PR_URL:-}\",\"end_state\":\"$END_STATE\",\"mode\":\"$MODE\",\"multi_story_mode\":false,\"multi_story_children_shipped\":0,\"ts\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}" >> ~/.gstack/analytics/CJ_goal_run.jsonl
```

Branch(f) exits after telemetry — does NOT fall through to Step 1.2 (design-doc branches).

```bash
if [ "$INPUT_MODE" = "work-item-dir" ]; then
  # All Branch(f) logic above completes here; exit cleanly.
  exit 0
fi
```

### Step 1.2: Branch(a/b/c/d) — design-doc input (existing behavior)

Continues only when `INPUT_MODE = design-doc`.

```bash
DESIGN_DOC="$ARG"
[ -f "$DESIGN_DOC" ] || { echo "Error: design doc not found at $DESIGN_DOC"; exit 1; }

# Must be under ~/.gstack/projects/ (the canonical /office-hours output location)
case "$DESIGN_DOC" in
  "$HOME/.gstack/projects/"*) ;;
  *) echo "Error: design doc must be under ~/.gstack/projects/ (got: $DESIGN_DOC)"; exit 1 ;;
esac

# MUST have Status: APPROVED somewhere in the body (typically near top of doc) — Branch (d) error
grep -q '^Status: APPROVED' "$DESIGN_DOC" || {
  echo "Error: design doc lacks 'Status: APPROVED'. Run /office-hours, accept the final approval option, then re-invoke /CJ_goal_run."
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
STATE_FILE="/tmp/cj-run-$RUN_ID.env"
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
CHILDREN_TOTAL=0
CHILDREN_DONE=0
CHILDREN_FAILED=""
CHILD_PR_URLS=""
NO_DRAIN_FLAG=$NO_DRAIN_FLAG
NEW_TODOS_COUNT=0
DRAINED_COUNT=0
DRAINED_PR_URLS=""
EOF

echo "STATE_FILE: $STATE_FILE"
echo "RUN_ID: $RUN_ID"
```

**State-file contract** (every subsequent bash block in run.md MUST
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
CHILDREN_TOTAL=$CHILDREN_TOTAL
CHILDREN_DONE=$CHILDREN_DONE
CHILDREN_FAILED="$CHILDREN_FAILED"
CHILD_PR_URLS="$CHILD_PR_URLS"
NO_DRAIN_FLAG=${NO_DRAIN_FLAG:-0}
HANDOFF_FLAG=${HANDOFF_FLAG:-0}
AUTO_MERGE_SMALL_DIFFS=${AUTO_MERGE_SMALL_DIFFS:-0}
PIPELINE_END_STATE="${PIPELINE_END_STATE:-}"
NEW_TODOS_COUNT=${NEW_TODOS_COUNT:-0}
DRAINED_COUNT=${DRAINED_COUNT:-0}
DRAINED_PR_URLS="$DRAINED_PR_URLS"
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

**Subagent prompt template** (XML-tag delimited per Anthropic prompt-engineering
guidance; substitute `$DESIGN_DOC` literally at dispatch time — bash variables
don't cross orchestrator-model Bash calls, so the prompt template carries the
literal path):

```
<role>
Pipeline runner for /CJ_goal_run wrapper.
</role>

<task>
Invoke /CJ_personal-pipeline in --suppress-final-gate mode and report its end
state.

Steps:
1. Invoke the slash command (via the Skill tool):
     /CJ_personal-pipeline --suppress-final-gate "<literal $DESIGN_DOC path>"
2. The pipeline runs its full lifecycle (Phase 1 scaffold → Phase 2 impl →
   Phase 3 QA + post-phase gates). It will SKIP Step 8.5's AUQ and Step 9.2's
   sunset AUQ per the --suppress-final-gate contract. Its tracker journal
   will record [auto-pipeline-clean] (zero-decision run) or
   [auto-final-gate-suppressed] N mechanical, M taste, K
   user-challenge-approved (non-zero).
3. At pipeline completion, the pipeline prints a "PIPELINE COMPLETE:
   end_state=<X>" line as its final output (Step 9.3 of pipeline.md).
4. Read that end_state value. Map it to the wrapper's RESULT contract:
     pipeline's end_state=green                 → PIPELINE_END_STATE=green
     pipeline's end_state=halted_at_gate         → PIPELINE_END_STATE=halted_at_gate
     pipeline's end_state=user_aborted           → PIPELINE_END_STATE=user_aborted (shouldn't fire under --suppress-final-gate; defensive)
     pipeline's end_state=subagent_crashed       → PIPELINE_END_STATE=subagent_crashed
5. Also extract the work-item directory path from the pipeline's "Work item:
   <path>" output line.
</task>

<return-contract>
End your FINAL assistant message with this EXACT line on its own:
  RESULT: PIPELINE_END_STATE=<value>; WORK_ITEM_DIR=<absolute_path>

Example (literal, this is the expected format):
  RESULT: PIPELINE_END_STATE=green; WORK_ITEM_DIR=/Users/chjiang/Documents/projects/claude-skills-templates/work-items/features/F000016_example/

No prose, no markdown wrapping, no code fence around the RESULT line itself.
If pipeline crashed and you cannot read end_state, emit:
  RESULT: PIPELINE_END_STATE=subagent_crashed; WORK_ITEM_DIR=
(empty WORK_ITEM_DIR is acceptable when scaffold didn't complete.)
</return-contract>

<inputs>
DESIGN_DOC: <literal $DESIGN_DOC path>
</inputs>
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
# Persist PIPELINE_END_STATE so Step 4.5's gate predicate (Defect 2) can read it
# across bash-call boundaries via source $STATE_FILE.
PIPELINE_END_STATE=green
write_state
```

If `MULTI_STORY=0`: store `WORK_ITEM_DIR`; continue to Step 4.

### Branch (b): green + multi-story — auto-iterate children

`PIPELINE_END_STATE=green; WORK_ITEM_DIR=<path>` AND `CHILD_TRACKERS >= 1`.

Pipeline correctly halted at scaffold gate per its existing multi-story branch
(end_state=green, scaffolded only — no impl/QA on the feature itself). Branch (b)
now auto-iterates each child user-story: per-child branch off `origin/main`,
copies scaffold from the feature branch, dispatches the pipeline with
`--work-item-dir`, runs `/ship` + `/land-and-deploy` per child.

**Preamble** — enumerate children and validate count:

```bash
source "$STATE_FILE"
MULTI_STORY=1
write_state

FEATURE_BRANCH=$(git branch --show-current)
MAIN_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||' || echo main)
FEATURE_NAME=$(basename "$WORK_ITEM_DIR")

# Enumerate child user-story dirs. Naming: S[0-9]* per WORKFLOW.md.
CHILDREN=()
while IFS= read -r d; do
  [ -z "$d" ] && continue
  CHILDREN+=("$d")
done < <(find "$WORK_ITEM_DIR" -maxdepth 1 -mindepth 1 -type d -name 'S[0-9]*' 2>/dev/null | sort)

CHILDREN_TOTAL=${#CHILDREN[@]}
write_state

echo "Branch(b) multi-story: $FEATURE_NAME has $CHILDREN_TOTAL children"
for c in "${CHILDREN[@]}"; do echo "  - $(basename "$c")"; done
```

**v1 guard** — if more than 3 children, AskUserQuestion before proceeding. Inline
Skills for `/ship` + `/land-and-deploy` accumulate ~3K tokens per child; 4+ children
risk context overflow for the orchestrator. v2 will dispatch each child as an Agent
subagent to amortize.

```
If $CHILDREN_TOTAL > 3:
  AUQ: "Branch(b) about to iterate $CHILDREN_TOTAL children inline. Each child's
        /ship + /land-and-deploy adds ~3K tokens to this session. Proceed?"
  Options:
    A) Proceed (inline) — recommended for ≤6 children
    B) Halt — re-design as N separate /CJ_goal_run invocations
```

**Loop body** — for each child, run git setup → pipeline dispatch → ship → deploy:

```bash
source "$STATE_FILE"

for CHILD_DIR in "${CHILDREN[@]}"; do
  CHILD_NAME=$(basename "$CHILD_DIR")
  CHILD_REL=$(realpath --relative-to=. "$CHILD_DIR" 2>/dev/null || python3 -c "import os.path; print(os.path.relpath('$CHILD_DIR'))")
  TIMESTAMP=$(date +%Y%m%d-%H%M%S)
  CHILD_BRANCH="${FEATURE_NAME}--${CHILD_NAME}-${TIMESTAMP}"

  echo "Branch(b) child $((CHILDREN_DONE + 1))/$CHILDREN_TOTAL: $CHILD_NAME"

  # Resume guard: if a prior /CJ_goal_run run already merged this child, skip.
  # Matches branch name prefix to detect prior merges.
  PRIOR_PR=$(gh pr list --state merged --search "head:${FEATURE_NAME}--${CHILD_NAME}-" --limit 1 --json url,headRefName -q '.[0].url' 2>/dev/null || echo "")
  if [ -n "$PRIOR_PR" ]; then
    echo "  Child $CHILD_NAME: already merged at $PRIOR_PR. Skipping."
    CHILDREN_DONE=$((CHILDREN_DONE + 1))
    CHILD_PR_URLS="$CHILD_PR_URLS$PRIOR_PR "
    write_state
    continue
  fi

  # Git setup: branch off origin/main, sparse-copy scaffold from feature branch, commit.
  git fetch origin "$MAIN_BRANCH" >/dev/null 2>&1
  if ! git checkout -b "$CHILD_BRANCH" "origin/$MAIN_BRANCH" 2>&1; then
    echo "  ERROR: failed to create branch $CHILD_BRANCH off origin/$MAIN_BRANCH"
    END_STATE="halted_at_pipeline"
    CHILDREN_FAILED="$CHILDREN_FAILED$CHILD_NAME "
    write_state
    git checkout "$FEATURE_BRANCH" 2>/dev/null || true
    break
  fi
  # Sparse-copy the child dir tree from the feature branch
  git checkout "$FEATURE_BRANCH" -- "$CHILD_REL" 2>&1 || {
    echo "  ERROR: failed to copy $CHILD_REL from $FEATURE_BRANCH"
    END_STATE="halted_at_pipeline"
    CHILDREN_FAILED="$CHILDREN_FAILED$CHILD_NAME "
    write_state
    git checkout "$FEATURE_BRANCH" 2>/dev/null || true
    break
  }
  git add "$CHILD_REL"
  git commit -m "scaffold: ${CHILD_NAME} (from ${FEATURE_NAME} feature scaffold)" --no-verify 2>&1 | tail -2

  # Pipeline dispatch via Agent (fresh-context subagent).
  # Set up per-run decision log to avoid co-mingling in standalone log.
  CHILD_DECISION_LOG="/tmp/cj-run-${RUN_ID}-${CHILD_NAME}-decisions.jsonl"
  echo "  Dispatching pipeline for $CHILD_NAME (--work-item-dir, --suppress-final-gate)..."
  echo "  Pipeline decision log: $CHILD_DECISION_LOG"
done
```

After the bash loop block, the orchestrator-model dispatches the pipeline via
the **Agent** tool (one subagent per child), then `/ship` + `/land-and-deploy`
via **Skill** tool. The dispatch prose:

> **For each child in `CHILDREN` (continuing the loop above):**
>
> 1. Dispatch CJ_personal-pipeline as Agent subagent (general-purpose) with prompt:
>    `Invoke /CJ_personal-pipeline --work-item-dir "<CHILD_DIR>" --suppress-final-gate. Return the RESULT line verbatim.`
>    Set env `GSTACK_PIPELINE_DECISION_LOG_PATH=<CHILD_DECISION_LOG>` so the
>    pipeline's auto-decisions log per-child, not into the global log.
>
> 2. Parse the Agent's RESULT line for `PIPELINE_END_STATE` (using the same
>    `parse_result` pattern as Step 3 Branch (a)).
>
> 3. **If `PIPELINE_END_STATE=green`:** invoke `/ship` via **Skill** tool
>    (Gate #2 fires — diff review AUQ scoped to this child's PR). On `/ship`
>    success, invoke `/land-and-deploy` via **Skill** tool. Capture the PR URL
>    from `/ship` output. Update state:
>    ```bash
>    CHILDREN_DONE=$((CHILDREN_DONE + 1))
>    CHILD_PR_URLS="$CHILD_PR_URLS<pr_url> "
>    write_state
>    git checkout "$FEATURE_BRANCH"
>    ```
>
> 4. **If `PIPELINE_END_STATE != green`:** halt the loop.
>    ```bash
>    CHILDREN_FAILED="$CHILDREN_FAILED$CHILD_NAME "
>    END_STATE="halted_at_pipeline"
>    write_state
>    git checkout "$FEATURE_BRANCH"
>    break
>    ```
>
> 5. **If subagent crashes (no RESULT line):** halt the loop with
>    `END_STATE="subagent_crashed"`; same cleanup as failure path.

**Post-loop finalization:**

```bash
source "$STATE_FILE"

if [ "$CHILDREN_DONE" = "$CHILDREN_TOTAL" ]; then
  END_STATE="green"
  echo "Branch(b) complete: $CHILDREN_DONE/$CHILDREN_TOTAL children shipped"
  echo "Child PRs: $CHILD_PR_URLS"
else
  # END_STATE already set to halted_at_pipeline or subagent_crashed by the loop
  REMAINING=$((CHILDREN_TOTAL - CHILDREN_DONE))
  echo "Branch(b) halted: $CHILDREN_DONE/$CHILDREN_TOTAL shipped, $REMAINING remaining"
  echo "Failed children: $CHILDREN_FAILED"
  echo "Re-run /CJ_goal_run on the design doc to resume (already-merged children will skip)."
fi
write_state
```

**Skip Steps 4-5 in Branch (b)** — per-child /ship + /land-and-deploy already
ran inside the loop. Flow directly to Step 6 (finalize: telemetry + summary).

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
# (no RESULT line emitted). Re-invoke /CJ_goal_run; pipeline's Branch (a)
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

PR created, `$PR_URL` captured. Continue to Step 4.5 (handoff gate; semantics depend on flag combination) → Step 5.

### Step 4.5: GATE #2 — scripts/cj-handoff-gate.sh (handoff-aware)

Three-way branch on the `(HANDOFF_FLAG, AUTO_MERGE_SMALL_DIFFS)` combination:

1. `HANDOFF_FLAG=0` (legacy direct `/CJ_goal_run`, no `--handoff`): **no-op**,
   fall through to Step 5 with the normal merge flow. Behavior UNCHANGED from
   pre-F000026. `--auto-merge-small-diffs` alone (without `--handoff`) is also
   treated as legacy mode and falls through — the flag pair is only meaningful
   when invoked via `/CJ_goal_auto`, which always passes `--handoff` first.

2. `HANDOFF_FLAG=1` AND `AUTO_MERGE_SMALL_DIFFS=1` (`/CJ_goal_auto
   --auto-merge-small-diffs`): run `scripts/cj-handoff-gate.sh`. Exit 0 →
   proceed to Step 5 (auto-merge); non-zero → halt for human review.

3. `HANDOFF_FLAG=1` AND `AUTO_MERGE_SMALL_DIFFS=0` (`/CJ_goal_auto` default
   mode): **HALT** — do NOT proceed to Step 5. The PR is review-ready;
   operator merges manually via `gh pr diff` / `gh pr merge`. This is the
   "exactly one mandatory human touchpoint in v1" promised by the
   /CJ_goal_auto design.

The sentinel line `CJ_GOAL_AUTO_HANDOFF_SENTINEL=v1` below is intentionally
co-located with the gate invocation that follows — `/CJ_goal_auto`'s Stage 0
capability check greps it, and `scripts/test.sh` test 9 asserts the line-distance ≤20.

```bash
if [ "$HANDOFF_FLAG" = "1" ] && [ "$AUTO_MERGE_SMALL_DIFFS" = "0" ]; then
  # /CJ_goal_auto default human-gated mode: halt after /ship.
  source "$STATE_FILE"
  cat >&2 <<EOF

[stage4.5-handoff-default-halt]
next_action=Default /CJ_goal_auto mode: PR is created and review-ready at $PR_URL. Run \`gh pr diff\` and merge manually. To auto-merge small/safe diffs, pass \`--auto-merge-small-diffs\`.
resume_cmd=gh pr diff $PR_NUM  # then: gh pr merge $PR_NUM --squash --delete-branch
pr_url=$PR_URL
EOF
  END_STATE="halted_at_handoff"
  write_state
  # Flow to Step 6 — do NOT proceed to Step 5 (/land-and-deploy).
elif [ "$HANDOFF_FLAG" = "1" ] && [ "$AUTO_MERGE_SMALL_DIFFS" = "1" ]; then
  # /CJ_goal_auto --auto-merge-small-diffs: run the gate helper.
  source "$STATE_FILE"
  _REPO_ROOT=$(git rev-parse --show-toplevel)
  _GATE_HELPER="$_REPO_ROOT/scripts/cj-handoff-gate.sh"
  [ -x "$_GATE_HELPER" ] || _GATE_HELPER="$HOME/.claude/scripts/cj-handoff-gate.sh"

  if [ ! -x "$_GATE_HELPER" ]; then
    echo "[gate2-helper-missing] scripts/cj-handoff-gate.sh not found or not executable." >&2
    END_STATE="halted_at_pipeline"
    write_state
    # Flow to Step 6 (finalize)
  else
    # Write Phase-2 markers file (read by helper). PIPELINE_END_STATE is
    # persisted across bash calls via write_state (Defect 2 fix); the
    # granular SMOKE/E2E/PHASE2_GATES markers are intentionally omitted
    # from the predicate — PIPELINE_END_STATE=green is already a strict
    # superset (CJ_personal-pipeline only returns green when all phases
    # passed). Helper still reads the file shape it expects; the granular
    # keys are emitted as `unknown` so the helper's parser sees them but
    # the gate predicate keys on PIPELINE_END_STATE.
    _MARKERS_DIR="$_REPO_ROOT/.gstack"
    mkdir -p "$_MARKERS_DIR"
    _MARKERS_FILE="$_MARKERS_DIR/phase2-markers.txt"
    {
      echo "PIPELINE_END_STATE=${PIPELINE_END_STATE:-unknown}"
      echo "SMOKE=unknown"
      echo "E2E=unknown"
      echo "PHASE2_GATES=unknown"
    } > "$_MARKERS_FILE"

    # CJ_GOAL_AUTO_HANDOFF_SENTINEL=v1 — co-located with the gate invocation
    # below for the Stage 0 capability self-check (see scripts/test.sh test 9).
    _GATE_OUT=$("$_GATE_HELPER" --markers-file "$_MARKERS_FILE" 2>&1)
    _GATE_RC=$?

    # Surface the KV stdout for audit (CJ_goal_auto's Stage 3 greps for these).
    echo "$_GATE_OUT"

    if [ "$_GATE_RC" != "0" ]; then
      # Halt: structured stop block. The helper already wrote the `[gate2-*]`
      # marker to stderr (the orchestrator-model sees it in $_GATE_OUT via 2>&1).
      # If the failure cited PIPELINE_END_STATE, name it directly.
      cat >&2 <<EOF

[stage4.5-gate2-halt]
next_action=inspect the PR; merge manually if good (gate predicate keys on PIPELINE_END_STATE=green; see helper output above for which marker tripped)
resume_cmd=gh pr diff $PR_NUM  # then: gh pr merge $PR_NUM --squash --delete-branch
pr_url=$PR_URL
gate_output: see KV lines printed above
EOF
      END_STATE="halted_at_pipeline"
      write_state
      # Flow to Step 6 — do NOT proceed to Step 5 (/land-and-deploy).
    else
      [ "${QUIET:-0}" != "1" ] && echo "[stage4.5] gate green — proceeding to /land-and-deploy" >&2
      # END_STATE stays unset (Step 5 will set it); fall through to Step 5.
    fi
  fi
fi
```

Continue to Step 5 (skipped when `END_STATE` was just set to `halted_at_pipeline` or `halted_at_handoff`).

### Branch (b): /ship halted or aborted

Set state and flow to Step 6 (finalize). The halt-print template will surface
the "/ship halt is healthy — not wrapper brittleness" framing:

```bash
source "$STATE_FILE"
END_STATE="halted_at_ship"
write_state
# PROCEED TO STEP 6 — finalizer prints standard halt tail; note halted_at_ship
# is healthy (review caught a real issue), excluded from sunset trip-wire by
# Step 7's filter. Re-invoke /CJ_goal_run after fix, or invoke /ship
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

Invoke `/land-and-deploy` via the **Skill tool**, always passing
`--suppress-readiness-gate` to skip /land-and-deploy's Step 3.5a-bis (stale-review
offer) + Step 3.5e (pre-merge readiness AUQ) on green runs. The flag is opt-in
upstream (gstack); direct callers of /land-and-deploy keep today's behavior.
Forward-compat: if the running gstack version doesn't recognize the flag yet,
its arg parser warns-and-continues — the invocation falls back to today's
behavior with no regression. Hard stops (CI red, merge conflict, free-test
regression at Step 3.5b, deploy failure, canary red) are unaffected — they
remain pre-3.5 STOPs or post-3.5 AUQs and still halt /CJ_goal_run cleanly.

- If `PR_NUM` is set: `/land-and-deploy --suppress-readiness-gate #<PR_NUM>` (literal value).
- If `PR_NUM` is empty: `/land-and-deploy --suppress-readiness-gate` (no PR arg —
  `/land-and-deploy` will auto-detect from current branch per its Step 1).

`/land-and-deploy` waits for CI, merges the PR, monitors any post-merge deploy
workflow, runs canary verification if a production URL was configured, and
writes its own deploy report. Its terminal verdict is one of:
`DEPLOYED AND VERIFIED`, `DEPLOYED (UNVERIFIED)`, `STAGING VERIFIED`, or `REVERTED`.

### Branch (a): green deploy

`/land-and-deploy` ends with verdict `DEPLOYED AND VERIFIED`,
`DEPLOYED (UNVERIFIED)`, or `STAGING VERIFIED`. All three count as green.

Set `END_STATE=green`; call `write_state`. Continue to **Step 5.5 (Phase 5 TODO drain)** before falling through to Step 6.

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
diagnostic output. **Phase 5 is skipped on any non-green Step 5 exit** —
drain only fires after a green deploy.

---

## Step 5.5: Phase 5 — TODO drain (post-deploy forward-iteration)

Reached **only** on Step 5 Branch (a) (green deploy). Skipped on Branches (b) /
(c) — drain assumes the feature PR landed cleanly. Phase 5 diffs the merged
PR's TODOS.md additions, counts new top-level headings, and (when warranted)
forward-iterates the new debt through `/CJ_goal_todo_fix` so the run that
created the debt closes it.

### Step 5.5.0: Skip-if-flagged

If `NO_DRAIN_FLAG=1` (operator passed `--no-drain` at invocation), record the
escape hatch and fall through to Step 6 with `END_STATE=green` preserved:

```bash
source "$STATE_FILE"
if [ "${NO_DRAIN_FLAG:-0}" = "1" ]; then
  echo "Phase 5: --no-drain flag set; skipping drain phase."
  # END_STATE stays "green" from Step 5 Branch (a); telemetry will carry
  # no_drain_flag=true so the silent-skip path is distinguishable from
  # "happy path zero TODOs".
  NEW_TODOS_COUNT=0
  DRAINED_COUNT=0
  DRAINED_PR_URLS=""
  write_state
  # PROCEED TO STEP 6
fi
```

### Step 5.5.1: Diff parser — count new TODO headings

Compute `N` = count of newly-added top-level (`### `) headings in TODOS.md
between the PR base and HEAD. Uses `gh pr view --json baseRefOid` to resolve
the PR's base SHA; falls back to `origin/main` if the gh lookup fails
(best-effort; the count just needs to be a sane non-negative integer for the
threshold check).

```bash
source "$STATE_FILE"
# Only run if we got here on a green deploy (preserves END_STATE=green invariant).
if [ "$END_STATE" != "green" ] || [ "${NO_DRAIN_FLAG:-0}" = "1" ]; then
  : # Skip silently; handled by upstream guards / Step 5.5.0
else
  # Resolve PR base SHA. PR_NUM is set in Step 5 (or earlier via Branch(f) open_pr).
  PR_BASE_SHA=""
  if [ -n "${PR_NUM:-}" ]; then
    PR_BASE_SHA=$(gh pr view "$PR_NUM" --json baseRefOid -q .baseRefOid 2>/dev/null || echo "")
  fi
  # Fallback: origin/main^ (one commit before tip) is a reasonable approximation
  # for the parent. Better than nothing when gh lookup is offline.
  if [ -z "$PR_BASE_SHA" ]; then
    PR_BASE_SHA=$(git rev-parse origin/main 2>/dev/null || echo "HEAD~1")
  fi

  # Count new top-level headings in TODOS.md. `^\+### ` catches added lines only
  # (excludes context `^ ` and removed `^\-`). Empty / missing TODOS.md yields 0.
  if [ -f "TODOS.md" ]; then
    NEW_TODOS_COUNT=$(git diff "$PR_BASE_SHA"..HEAD -- TODOS.md 2>/dev/null \
      | grep -cE '^\+### ' || echo 0)
  else
    NEW_TODOS_COUNT=0
  fi
  NEW_TODOS_COUNT=${NEW_TODOS_COUNT:-0}

  # Capture the actual headings for the show-list AUQ option (Step 5.5.3).
  # Stored as newline-separated string in a per-run file; the state file
  # stays shell-safe (no embedded newlines).
  PHASE5_HEADINGS_FILE="/tmp/cj-run-phase5-headings-$RUN_ID.txt"
  git diff "$PR_BASE_SHA"..HEAD -- TODOS.md 2>/dev/null \
    | grep -E '^\+### ' \
    | sed 's/^\+### //' \
    > "$PHASE5_HEADINGS_FILE" 2>/dev/null || true

  echo "Phase 5: NEW_TODOS_COUNT=$NEW_TODOS_COUNT (parent=$PR_BASE_SHA)"
  write_state
fi
```

### Step 5.5.2: N == 0 — silent skip

When no new TODOs were added by this run's PR, drain has nothing to do.
Emit green with `new_todos_count: 0`; do NOT surface an AUQ.

```bash
source "$STATE_FILE"
if [ "$END_STATE" = "green" ] && [ "${NO_DRAIN_FLAG:-0}" != "1" ] \
   && [ "${NEW_TODOS_COUNT:-0}" = "0" ]; then
  echo "Phase 5: no new TODOs detected. Done."
  # END_STATE stays "green"; telemetry will carry new_todos_count=0,
  # drained_count=0, drained_pr_urls=[]. This is the silent-skip path.
  DRAINED_COUNT=0
  DRAINED_PR_URLS=""
  write_state
  # PROCEED TO STEP 6
fi
```

### Step 5.5.3: N > 0 — AUQ with recommendation

When `NEW_TODOS_COUNT > 0`, surface an AUQ asking whether to drain. The
orchestrator (model) renders the AUQ using `AskUserQuestion`; the bash blocks
above prepared the heading list at `$PHASE5_HEADINGS_FILE` for the show-list
option.

**Cap policy**: `cap=5` is hardcoded (greppable / P5-explicit per the design
tradeoffs table). Recommendation is `yes` iff `N <= cap`; `no` otherwise.

```
AskUserQuestion:
  Question: "Phase 5 drain: this run added N new TODOs. Drain them now?"
  Body:
    /CJ_goal_run Phase 5 detected $NEW_TODOS_COUNT new TODO heading(s)
    added to TODOS.md by this run's PR ($PR_URL).

    Cap: 5 TODOs per drain phase (hardcoded). Drain invokes
    /CJ_goal_todo_fix once per heading, sequentially.

    Recommendation:
      - yes      (if N <= 5; achievable in one pass)
      - no       (if N > 5; partial drain is not completeness — defer to
                  manual /loop /CJ_goal_todo_fix)

  Options (orchestrator presents based on N):
    [N <= 5]
      A) Yes, drain all $N TODOs               <-- recommended
      B) No, skip drain (mark green, defer)
      C) Show list of headings, then decide

    [N > 5]
      A) Drain top 5, defer the rest
      B) No, skip drain (mark green, defer)    <-- recommended
      C) Show list of headings, then decide
```

**Show-list flow**: when the operator picks `C`, the orchestrator reads
`$PHASE5_HEADINGS_FILE`, prints the list with line numbers, then re-renders
the AUQ with options A/B only (the show-list branch collapses to the binary
choice on the second round).

**Operator choice → END_STATE branches**:
- **A (drain)**: continue to Step 5.5.4. `DRAIN_TARGET_COUNT=min(N, 5)`.
- **B (skip)**: set `END_STATE=green` (unchanged); record `DRAINED_COUNT=0`;
  flow to Step 6. The new TODOs remain as active rows in TODOS.md (operator
  manually invokes `/CJ_goal_todo_fix` later or queues via `/loop`).

### Step 5.5.4: Per-TODO drain loop (cap=5)

For each of the first `DRAIN_TARGET_COUNT` headings, invoke `/CJ_goal_todo_fix`
as a subroutine via the **Skill** tool. Each invocation runs its own
preflight → scaffold T-task → `/CJ_personal-pipeline` → `/ship` Gate #2 →
`/land-and-deploy` → TODOS.md DONE-mark sub-flow. Halt-on-red: any child red
stops the loop; remaining headings are left as active TODOS rows.

```bash
source "$STATE_FILE"
# Only enter the loop when the operator picked "drain" (A) above. The
# orchestrator carries the AUQ answer as prose state; this block is the
# implementation skeleton, invoked by the orchestrator after Option A.
DRAIN_CAP=5
DRAIN_TARGET_COUNT=$NEW_TODOS_COUNT
if [ "$DRAIN_TARGET_COUNT" -gt "$DRAIN_CAP" ]; then
  DRAIN_TARGET_COUNT=$DRAIN_CAP
fi
echo "Phase 5: draining $DRAIN_TARGET_COUNT of $NEW_TODOS_COUNT TODOs (cap=$DRAIN_CAP)"

# Read headings from the per-run file (first $DRAIN_TARGET_COUNT lines).
DRAINED_COUNT=0
DRAINED_PR_URLS=""
HEADING_IDX=0
while IFS= read -r heading; do
  HEADING_IDX=$((HEADING_IDX + 1))
  if [ "$HEADING_IDX" -gt "$DRAIN_TARGET_COUNT" ]; then
    break
  fi
  echo "Phase 5 child $HEADING_IDX/$DRAIN_TARGET_COUNT: $heading"
  # Per-TODO inner loop is owned by the shared helper at:
  #   skills/CJ_goal_todo_fix/scripts/drain-one-todo.sh
  # (S000046, v4.2.0). Both /CJ_goal_run Phase 5 and /CJ_goal_todo_fix Phase 2
  # call this single helper so the lockfile + preflight + scaffold + chain
  # behavior has one source of truth.
  #
  # Invocation contract (orchestrator drives the chain; helper handles lock +
  # preflight + scaffold-handoff):
  #   bash skills/CJ_goal_todo_fix/scripts/drain-one-todo.sh dispatch "$heading" "$RUN_ID"
  #
  # Helper outputs:
  #   - "RESULT: STATUS=lock_skip; ..."          → skip this heading silently
  #   - CJ_GOAL_HANDOFF_BEGIN ... END + handoff_pending RESULT → orchestrator
  #     dispatches /CJ_personal-pipeline + /ship + /land-and-deploy via Skill
  #     tool, captures PR URL, then calls:
  #       bash skills/CJ_goal_todo_fix/scripts/drain-one-todo.sh release "$heading" "$RUN_ID"
  #   - "RESULT: STATUS=halted; ..."             → child red; STOP the loop
  #
  # On child green: append the captured PR URL to DRAINED_PR_URLS
  # (space-separated). On child red (STATUS=halted or any chain stage failure
  # other than `green` / `already_shipped`): STOP the loop, set
  # END_STATE=drained_partial, break out.
done < "$PHASE5_HEADINGS_FILE"

# After loop: classify END_STATE.
# - If DRAINED_COUNT == DRAIN_TARGET_COUNT: drained_complete (all green).
# - If 0 < DRAINED_COUNT < DRAIN_TARGET_COUNT: drained_partial (mid-loop halt).
# - If DRAINED_COUNT == 0 and loop entered: drained_partial (first child red).
#
# Note: drained_partial covers both halt-on-red and cap-reached cases. When
# N > 5 and operator picked "Drain top 5, defer rest", the post-loop state
# is drained_complete (5 of 5 drained) — the deferred rest count is
# captured separately via NEW_TODOS_COUNT - DRAINED_COUNT in the summary.

if [ "$DRAINED_COUNT" = "$DRAIN_TARGET_COUNT" ]; then
  END_STATE="drained_complete"
else
  END_STATE="drained_partial"
fi
write_state
# Cleanup per-run headings file
rm -f "$PHASE5_HEADINGS_FILE" 2>/dev/null
echo "Phase 5 complete: end_state=$END_STATE drained=$DRAINED_COUNT/$DRAIN_TARGET_COUNT"
```

**Orchestrator contract for the loop**: the bash block above is the skeleton.
The orchestrator (model) carries `$PHASE5_HEADINGS_FILE` and `$DRAIN_TARGET_COUNT`
as prose state, and renders one Skill-tool `/CJ_goal_todo_fix <heading>`
invocation per iteration. After each child:
1. Parse the child's summary block for the PR URL.
2. Append to `DRAINED_PR_URLS` (space-separated).
3. Increment `DRAINED_COUNT`.
4. Call `write_state` (so a Ctrl-C / crash mid-loop leaves recoverable state).
5. On child red (any halt class other than `green` / `already_shipped`): STOP
   the loop, set `END_STATE=drained_partial`, write_state, fall through to
   Step 6.

After the loop completes (green or red), END_STATE is one of `drained_complete`
/ `drained_partial`. Proceed to Step 6 (finalize) — Step 6's telemetry write
already records the new fields via the schema-tolerant jq invocation.

### Step 5.5.5: Halt-on-red — error → drained_partial

If any child `/CJ_goal_todo_fix` invocation halts red, the orchestrator
short-circuits the loop and sets `END_STATE=drained_partial`. The state file
captures `DRAINED_COUNT` (how many shipped before the halt) and `DRAINED_PR_URLS`
(URLs of the successful children). The remaining TODOs stay as active rows in
TODOS.md and can be picked up by a later `/CJ_goal_todo_fix` or `/loop` run.

This is the standard halt-on-red contract: Phase 5 inherits it from the
parent /CJ_goal_run skill's "halt-on-red default" rule. No new error
handling required beyond setting END_STATE before flowing to Step 6.

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
CHILDREN_DONE=${CHILDREN_DONE:-0}

# Phase 5 telemetry fields (S000045). new_todos_count and drained_count are
# numeric; drained_pr_urls is an array (split from the space-separated state
# string); no_drain_flag is bool.
NO_DRAIN_BOOL=$([ "${NO_DRAIN_FLAG:-0}" = "1" ] && echo "true" || echo "false")
NEW_TODOS_COUNT=${NEW_TODOS_COUNT:-0}
DRAINED_COUNT=${DRAINED_COUNT:-0}

if command -v jq >/dev/null 2>&1; then
  # Build drained_pr_urls as a JSON array from the space-separated state.
  # Empty string yields []. Mapped through jq's `split` for robustness.
  DRAINED_URLS_JSON=$(printf '%s' "${DRAINED_PR_URLS:-}" \
    | jq -Rc 'split(" ") | map(select(length > 0))' 2>/dev/null || echo "[]")
  jq -nc \
    --arg run_id "$RUN_ID" \
    --arg design_doc "$DESIGN_DOC" \
    --arg work_item "${WORK_ITEM_DIR:-}" \
    --arg pr_url "${PR_URL:-}" \
    --arg end_state "$END_STATE" \
    --argjson multi_story_mode "$MULTI_STORY_BOOL" \
    --argjson multi_story_children_shipped "$CHILDREN_DONE" \
    --argjson new_todos_count "$NEW_TODOS_COUNT" \
    --argjson drained_count "$DRAINED_COUNT" \
    --argjson drained_pr_urls "$DRAINED_URLS_JSON" \
    --argjson no_drain_flag "$NO_DRAIN_BOOL" \
    --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    '{run_id:$run_id,design_doc:$design_doc,work_item:$work_item,pr_url:$pr_url,end_state:$end_state,multi_story_mode:$multi_story_mode,multi_story_children_shipped:$multi_story_children_shipped,new_todos_count:$new_todos_count,drained_count:$drained_count,drained_pr_urls:$drained_pr_urls,no_drain_flag:$no_drain_flag,ts:$ts}' \
    >> "$HOME/.gstack/analytics/CJ_goal_run.jsonl"
else
  # Fallback when jq is missing (workbench declared dep, so unlikely).
  # Lossy on paths with quotes/backslashes but never invalid JSON.
  _SAFE_DOC=$(printf '%s' "$DESIGN_DOC" | tr -d '\\"')
  _SAFE_WORK=$(printf '%s' "${WORK_ITEM_DIR:-}" | tr -d '\\"')
  _SAFE_PR=$(printf '%s' "${PR_URL:-}" | tr -d '\\"')
  # drained_pr_urls: space-separated → "url1","url2","url3" → ["url1","url2","url3"]
  _DRAINED_ARRAY="[]"
  if [ -n "${DRAINED_PR_URLS:-}" ]; then
    _DRAINED_ARRAY="["
    _FIRST=1
    for _U in $DRAINED_PR_URLS; do
      _SAFE_U=$(printf '%s' "$_U" | tr -d '\\"')
      if [ "$_FIRST" = "1" ]; then
        _DRAINED_ARRAY="${_DRAINED_ARRAY}\"$_SAFE_U\""
        _FIRST=0
      else
        _DRAINED_ARRAY="${_DRAINED_ARRAY},\"$_SAFE_U\""
      fi
    done
    _DRAINED_ARRAY="${_DRAINED_ARRAY}]"
  fi
  echo "{\"run_id\":\"$RUN_ID\",\"design_doc\":\"$_SAFE_DOC\",\"work_item\":\"$_SAFE_WORK\",\"pr_url\":\"$_SAFE_PR\",\"end_state\":\"$END_STATE\",\"multi_story_mode\":$MULTI_STORY_BOOL,\"multi_story_children_shipped\":$CHILDREN_DONE,\"new_todos_count\":$NEW_TODOS_COUNT,\"drained_count\":$DRAINED_COUNT,\"drained_pr_urls\":$_DRAINED_ARRAY,\"no_drain_flag\":$NO_DRAIN_BOOL,\"ts\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}" \
    >> "$HOME/.gstack/analytics/CJ_goal_run.jsonl"
fi
```

### Step 6.2: Print summary — header depends on END_STATE

If `END_STATE=green` AND `MULTI_STORY=1` (multi-story auto-iterate):

```
/CJ_goal_run COMPLETE (green)  multi_story=1  children_shipped=$CHILDREN_DONE/$CHILDREN_TOTAL

Run ID:        $RUN_ID
Design:        $DESIGN_DOC
Feature:       ${WORK_ITEM_DIR:-N/A}
Child PRs:     $CHILD_PR_URLS
Pipeline log:  $PIPELINE_DECISION_LOG (filter by run_id=$RUN_ID for this run's decisions)
Telemetry:     ~/.gstack/analytics/CJ_goal_run.jsonl
```

Else if `END_STATE=green` (single-story):

```
/CJ_goal_run COMPLETE (green)  multi_story=0

Run ID:        $RUN_ID
Design:        $DESIGN_DOC
Work item:     ${WORK_ITEM_DIR:-N/A}
PR:            ${PR_URL:-N/A}
Tracker:       ${TRACKER_PATH:-N/A}
Phase 5:       new_todos=$NEW_TODOS_COUNT  drained=$DRAINED_COUNT  no_drain_flag=${NO_DRAIN_FLAG:-0}
Pipeline log:  $PIPELINE_DECISION_LOG (filter by run_id=$RUN_ID for this run's decisions)
Telemetry:     ~/.gstack/analytics/CJ_goal_run.jsonl
```

Else if `END_STATE=drained_complete` or `drained_partial` (Phase 5 outcome):

```
/CJ_goal_run COMPLETE ($END_STATE)  drained=$DRAINED_COUNT/$NEW_TODOS_COUNT

Run ID:        $RUN_ID
Design:        $DESIGN_DOC
Work item:     ${WORK_ITEM_DIR:-N/A}
Feature PR:    ${PR_URL:-N/A}
Drain PRs:     ${DRAINED_PR_URLS:-N/A}
Tracker:       ${TRACKER_PATH:-N/A}
Pipeline log:  $PIPELINE_DECISION_LOG (filter by run_id=$RUN_ID)
Telemetry:     ~/.gstack/analytics/CJ_goal_run.jsonl
```

For `drained_partial`: include the line
"Remaining: $((NEW_TODOS_COUNT - DRAINED_COUNT)) TODOs not drained — run /CJ_goal_todo_fix or /loop to clear."

Otherwise (any halt or `deploy_red`):

If `MULTI_STORY=1`:

```
/CJ_goal_run HALTED at end_state=$END_STATE  multi_story=1  children_shipped=$CHILDREN_DONE/$CHILDREN_TOTAL

Run ID:        $RUN_ID
Design:        $DESIGN_DOC
Feature:       ${WORK_ITEM_DIR:-N/A}
Shipped PRs:   $CHILD_PR_URLS
Failed:        $CHILDREN_FAILED
Pipeline log:  $PIPELINE_DECISION_LOG (filter by run_id=$RUN_ID)
Telemetry:     ~/.gstack/analytics/CJ_goal_run.jsonl

Resume: re-invoke /CJ_goal_run on the same design doc — already-merged children
are skipped via the resume guard (gh pr list --state merged).
```

Else (single-story halt):

```
/CJ_goal_run HALTED at end_state=$END_STATE

Run ID:        $RUN_ID
Design:        $DESIGN_DOC
Work item:     ${WORK_ITEM_DIR:-N/A (halt before work-item created)}
PR:            ${PR_URL:-N/A (halt before PR created)}
Tracker:       ${TRACKER_PATH:-N/A}
Pipeline log:  $PIPELINE_DECISION_LOG (filter by run_id=$RUN_ID)
Telemetry:     ~/.gstack/analytics/CJ_goal_run.jsonl

Resume: re-invoke /CJ_goal_run on the same design doc, OR continue manually
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
TELEMETRY="$HOME/.gstack/analytics/CJ_goal_run.jsonl"
# v4.0.0 rename fallback: include legacy CJ_run.jsonl history in the count.
# Writes go to the new path only; reads merge both. Removed in v5.0.0.
LEGACY_TELEMETRY="$HOME/.gstack/analytics/CJ_run.jsonl"

# This run's telemetry line was just appended by Step 6.1 to the new path.
# INVOCATION_COUNT includes this run AND any legacy entries.
NEW_COUNT=$(wc -l < "$TELEMETRY" 2>/dev/null | tr -d ' ')
NEW_COUNT=${NEW_COUNT:-0}
LEGACY_COUNT=0
if [ -f "$LEGACY_TELEMETRY" ]; then
  LEGACY_COUNT=$(wc -l < "$LEGACY_TELEMETRY" 2>/dev/null | tr -d ' ')
  LEGACY_COUNT=${LEGACY_COUNT:-0}
fi
INVOCATION_COUNT=$(( NEW_COUNT + LEGACY_COUNT ))

# Fire on invocation 6, then every 5 thereafter (11, 16, 21, ...).
SHOULD_FIRE=0
if [ "$INVOCATION_COUNT" -ge 6 ] && [ $(( (INVOCATION_COUNT - 6) % 5 )) -eq 0 ]; then
  SHOULD_FIRE=1
fi

if [ "$SHOULD_FIRE" = "1" ]; then
  # Take the 5 runs immediately before THIS one (the latest line is current run).
  # v4.0.0 fallback: concatenate legacy then new (chronological order), then
  # tail -6 head -5 picks the prior 5 spanning the rename window.
  if [ -f "$LEGACY_TELEMETRY" ]; then
    PRIOR_5=$(cat "$LEGACY_TELEMETRY" "$TELEMETRY" 2>/dev/null | tail -6 | head -5)
  else
    PRIOR_5=$(tail -6 "$TELEMETRY" | head -5)
  fi

  # Brittleness signal: halted_at_(autoplan|pipeline|deploy) or subagent_crashed.
  # Excludes: green (happy path), halted_at_ship (review caught real issue),
  # deploy_red (production state, not wrapper brittleness), multi_story rows.
  #
  # F4 FIX: separate grep -c from the || fallback. grep -c always emits a count
  # (even 0) and may exit 1 on no-matches; the outer `|| echo 0` would APPEND
  # a second "0" producing "0\n0" which fails integer comparison. Pattern below
  # captures grep's exit explicitly without ever appending.
  # Multi-story rows excluded from brittleness trip-wire. v3.2.0 renamed
  # `multi_story_scaffold_only` -> `multi_story_mode`; check both for backward
  # compat with pre-v3.2.0 log entries.
  HALT_COUNT=$(echo "$PRIOR_5" \
    | jq -r 'select(((.multi_story_mode // .multi_story_scaffold_only) // false) == false) | .end_state' 2>/dev/null \
    | grep -cE '^(halted_at_autoplan|halted_at_pipeline|halted_at_deploy|subagent_crashed)$') || HALT_COUNT=0
  HALT_COUNT=${HALT_COUNT:-0}

  if [ "$HALT_COUNT" -ge 3 ]; then
    SUNSET_REC="DELETE"
  else
    SUNSET_REC="KEEP"
  fi

  # Render human-readable PRIOR_5 summary for the AUQ body.
  PRIOR_5_SUMMARY=$(echo "$PRIOR_5" | jq -r '"  - end_state=\(.end_state)  multi_story=\((.multi_story_mode // .multi_story_scaffold_only) // false)  design=\(.design_doc | split("/") | last)"' 2>/dev/null || echo "  (unable to parse PRIOR_5)")

  # AskUserQuestion (wrapper-rendered checkpoint AUQ — NOT a sub-skill pass-through).
  # Surfaces only on the 6th invocation and every 5 thereafter; rendered by the
  # wrapper itself (AskUserQuestion is in SKILL.md allowed-tools).
  #
  # AUQ body:
  #   /CJ_goal_run sunset checkpoint (invocation $INVOCATION_COUNT). Prior 5 runs:
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
To delete /CJ_goal_run:
  rm -rf <workbench>/skills/CJ_goal_run/
  Strike the row from <workbench>/skills-catalog.json
  cd <workbench> && ./scripts/skills-deploy install
```

### Step 7.1: Exit with appropriate code

```bash
source "$STATE_FILE"
# Cleanup state file (optional; tmpfiles will eventually reap it)
rm -f "$STATE_FILE" 2>/dev/null

# green and drained_complete both exit 0 (Phase 5 fully shipped + drained).
# drained_partial exits 0 too: the feature shipped green, drain ran some
# children — the per-loop halt-on-red was a within-Phase-5 partial-success
# (Phase 4 already returned green; we don't want to retroactively poison
# the run's exit code). The DRAINED_COUNT < NEW_TODOS_COUNT signal lives in
# telemetry + summary, not exit code.
case "$END_STATE" in
  green|drained_complete|drained_partial|already_shipped)
    exit 0
    ;;
  *)
    exit 1
    ;;
esac
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
