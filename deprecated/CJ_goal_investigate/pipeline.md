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
/CJ_goal_investigate --no-worktree D000NNN      # operator opt-out: run in place on a clean checkout
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
ARG="${ARGS[0]:-}"
[ -n "$ARG" ] || { echo "Error: D-ID or fragment required."; exit 1; }
[ "${#ARGS[@]}" -le 1 ] || { echo "Error: exactly one D-ID or fragment expected (got: ${ARGS[*]})"; exit 1; }
RUN_ID=$(date +%Y%m%d-%H%M%S)-$$
# Persist the operator --no-worktree opt-out RUN_ID-scoped, in THIS block —
# the only place NO_WORKTREE (set by the parser loop above) and RUN_ID (just
# generated) are both live. Shell vars do NOT persist across bash tool calls
# (CLAUDE.md), so Step 5.0's isolation gate cannot read $NO_WORKTREE; it
# re-reads this marker via the model-carried RUN_ID (same persistence pattern
# as TELEMETRY / RAW_DIR / $TRACKER). RUN_ID-scoped dir = no cross-run leak;
# written post-RUN_ID = no pre-RUN_ID handoff problem (why design Approach B
# was rejected does not apply: one bit set post-RUN_ID, not a JSON handoff).
if [ "${NO_WORKTREE:-}" = "1" ]; then
  mkdir -p "$HOME/.gstack/analytics/CJ_goal_investigate-runs/$RUN_ID"
  : > "$HOME/.gstack/analytics/CJ_goal_investigate-runs/$RUN_ID/.operator-no-worktree"
fi
```

Initialize telemetry + decision-log paths:

```bash
mkdir -p "$HOME/.gstack/analytics/CJ_goal_investigate-runs/$RUN_ID"
TELEMETRY="$HOME/.gstack/analytics/CJ_goal_investigate.jsonl"
RAW_DIR="$HOME/.gstack/analytics/CJ_goal_investigate-runs/$RUN_ID"
```

## Step 2: Resolve the defect directory

The resolver searches `work-items/defects/<domain...>/D000NNN_<slug>/`
(dir-based layout only in v1.x — freestanding `D<NNN>_bug-report.md` is a
later-version helper swap). `<domain...>` may be ONE or MORE path segments —
the repo has organically nested 2-segment domains (e.g.
`ops/skills-deploy/`, `ops/ship/`). The find scans are unbounded-depth and
anchored on the globally-unambiguous `D[0-9]{6}_` basename, so nested
domains resolve correctly (D000022 fix).

```bash
_REPO_ROOT=$(git rev-parse --show-toplevel)
DEFECTS_ROOT="$_REPO_ROOT/work-items/defects"

# v1.1: IS_DRAFT defaults to 0 so the canonical 1) and *) branches leave it
# zero. Only the 0) (zero-match) branch sets IS_DRAFT=1. The canonical
# if/MATCHES/MATCH_COUNT block below keeps its v1.0 match SEMANTICS; the only
# v1.1 change is a defensive literal/option-safe hardening of the fuzzy
# matchers (`grep -rliF --`, glob-escaped `-iname`) that the C3 re-entry
# guarantee depends on. Drafts stay invisible to it by construction (no
# D###### basename, DRAFT.md not *_TRACKER.md), so neither BASENAME_HITS nor
# NAME_HITS can match them.
IS_DRAFT=0
DRAFT_SLUG=""
DRAFT_FRAGMENT=""

# Exact D-ID match: anchored regex on dir basename starting with D followed by 6 digits + underscore.
# D000022 fix: NO -maxdepth cap. The `D######_` basename is globally
# unambiguous, so an unbounded `find -type d -name "${ARG}_*"` is safe and
# correct. A -maxdepth 2 cap silently encoded a now-false assumption that
# every defect domain is exactly one segment under work-items/defects/; the
# repo grew nested 2-segment domains (ops/skills-deploy/, ops/ship/,
# ops/workflow/ — depth 3) whose defects were unresolvable by exact D-ID.
if [[ "$ARG" =~ ^D[0-9]{6}$ ]]; then
  MATCHES=$(find "$DEFECTS_ROOT" -type d -name "${ARG}_*" 2>/dev/null)
else
  # Fragment fuzzy: match against (a) dir basename and (b) tracker `name:` field.
  # Two passes union'd; dedup by path.
  # Glob-escape the fragment for `find -iname`: a raw `*`/`?`/`[` in the
  # fragment would change glob semantics (over-match → false ambiguity or
  # wrong-defect resume). Backslash-escape the three glob metacharacters.
  ARG_GLOB=$(printf '%s' "$ARG" | sed 's/[][*?]/\\&/g')
  # D000022 fix: NO -maxdepth cap (same rationale as the exact-D-ID find
  # above). The `grep -E '/D[0-9]{6}_'` post-filter still constrains hits to
  # real defect dirs, so removing the depth cap only widens reach to nested
  # 2-segment domains — every other semantic (glob-escaping, the grep filter)
  # is preserved.
  BASENAME_HITS=$(find "$DEFECTS_ROOT" -type d -iname "*${ARG_GLOB}*" 2>/dev/null \
                  | grep -E '/D[0-9]{6}_' || true)
  # `-F` + `--`: treat the fragment as a literal string (not a basic regex),
  # and stop option parsing so a fragment starting with `-` is not consumed as
  # a grep flag (option injection). Without `-F` a fragment with regex
  # metachars (`a[b`, `500 on.*body`) makes grep exit 2 or match unintended
  # trackers — a spurious zero-match then routes an already-canonical defect
  # into the draft path and (post-promotion) mints a SECOND D-ID. The v1.1 C3
  # re-entry guarantee ("the written canonical TRACKER is found by NAME_HITS on
  # re-invocation") depends on this literal, option-safe match.
  NAME_HITS=$(grep -rliF --include="*_TRACKER.md" -- "$ARG" "$DEFECTS_ROOT" 2>/dev/null \
              | xargs -I {} dirname {} 2>/dev/null || true)
  MATCHES=$(printf '%s\n%s\n' "$BASENAME_HITS" "$NAME_HITS" | grep -v '^$' | sort -u)
fi

MATCH_COUNT=$(printf '%s\n' "$MATCHES" | grep -c '^[^[:space:]]' || true)

case "$MATCH_COUNT" in
  0)
    # v1.1: zero canonical match → resolve-or-create a NON-CANONICAL draft.
    # No D-ID is allocated here. Promotion (Step 7.4) mints the D-ID after the
    # Iron-Law gate passes. Draft dirs are invisible to the canonical resolver
    # above: no D###### basename, DRAFT.md (not *_TRACKER.md).
    INBOX="$DEFECTS_ROOT/.inbox"
    mkdir -p "$INBOX"

    # Slugify fragment: lowercase, non-alnum -> _, collapse, cap 50, trim trailing _.
    # C6 (slug isolation is load-bearing): the lowercasing here is NOT cosmetic.
    # The canonical resolver at Step 2 line ~62 uses a case-sensitive
    # `find -name "D000099_*"` for exact D-ID matches; the draft model relies on
    # draft dir names never starting with a `D[0-9]{6}_` prefix. If a future
    # change "preserves case", a fragment like "D000099 broke" could slug to
    # `D000099_broke` and collide with that case-sensitive find — silently
    # turning a non-canonical draft into a resolver match. Keep the lowercase.
    SLUG=$(printf '%s' "$ARG" | tr '[:upper:]' '[:lower:]' \
           | sed -E 's/[^a-z0-9]+/_/g; s/^_+|_+$//g' \
           | cut -c1-50 \
           | sed -E 's/_+$//')
    [ -z "$SLUG" ] && SLUG="untitled"

    # Idempotent re-invocation: an existing draft for this slug wins (no dup).
    # The timestamp is NOT in the dir name, so the same fragment maps to the
    # same draft deterministically.
    DRAFT_DIR="$INBOX/$SLUG"

    if [ "${DRY_RUN:-0}" = "1" ]; then
      if [ -d "$DRAFT_DIR" ]; then
        echo "DRY RUN: would resume existing draft: $DRAFT_DIR"
      else
        echo "DRY RUN: would create draft: $DRAFT_DIR"
      fi
      echo "DRY RUN: would promote to work-items/defects/uncategorized/D<next>_$SLUG after /investigate populates a root cause"
      # C7 (--dry-run on a zero-match fragment): plain-English, no internal jargon.
      echo "DRY RUN: writes nothing. Re-running the same phrase later would resume this draft; reworded text would create a different draft."
      # Telemetry: end_state=dry_run_preview
      exit 0
    fi

    if [ -d "$DRAFT_DIR" ]; then
      # C5: echo the stored fragment so a wrong-bug slug collision is visible.
      # DRAFT.md stores it as a double-quoted YAML scalar: fragment: "<escaped>".
      # Strip the `fragment: "` prefix + trailing `"`, then best-effort unescape
      # (\" -> ", \\ -> \). Display-only; an off-by-an-escape on a pathological
      # fragment is cosmetic. The OLD `awk -F': '` split mangled any fragment
      # containing `: ` (e.g. "auth: token expired") even with no collision.
      STORED_FRAGMENT=$(sed -n 's/^fragment: "\(.*\)"$/\1/p' "$DRAFT_DIR/DRAFT.md" 2>/dev/null | head -1 \
                        | sed 's/\\"/"/g; s/\\\\/\\/g')
      [ -z "$STORED_FRAGMENT" ] && STORED_FRAGMENT="$ARG"
      # C7 (draft resume): plain-English, echoes the original fragment.
      echo "Resuming the temporary draft at $DRAFT_DIR (originally: \"$STORED_FRAGMENT\"). Still no D-ID until the root cause is found."
    else
      mkdir -p "$DRAFT_DIR"
      NOW=$(date -u +%Y-%m-%dT%H:%M:%SZ)
      # F1: the fragment is operator free text — it can contain `:`, `#`, `"`,
      # `\`. Emit it as a double-quoted YAML scalar with `\` and `"` escaped
      # and any CR/LF stripped, so the frontmatter is always valid YAML. (The
      # markdown body below is prose, mid-line — raw `$ARG` is fine there.)
      ARG_YAML=$(printf '%s' "$ARG" | tr -d '\r\n' | sed 's/\\/\\\\/g; s/"/\\"/g')
      # DRAFT.md is the ONLY artifact. Mutable; no frontmatter contract; not a
      # TRACKER; deliberately not matched by the canonical resolver above.
      cat > "$DRAFT_DIR/DRAFT.md" <<DRAFT
---
kind: defect-draft
created: $NOW
fragment: "$ARG_YAML"
---

# Draft: $ARG

Captured by /CJ_goal_investigate on $NOW from a zero-match fragment.
No D-ID allocated yet. /investigate runs against this draft; on a populated
root cause it is promoted to work-items/defects/<domain>/D000NNN_<slug>/.
DRAFT
      # C7 (draft capture): plain-English, names the path + the rm -rf safety.
      echo "No existing defect matched \"$ARG\", so I created a temporary draft at $DRAFT_DIR (no D-ID yet). Re-run this exact phrase to resume it; it becomes a real D-ID only after the root cause is found. Stale drafts are safe to rm -rf — they are not canonical."
    fi

    # Wire the rest of the pipeline to operate on the draft. IS_DRAFT=1 makes
    # Step 3 short-circuit to Row 1 and Step 7.4 promote before the chain.
    IS_DRAFT=1
    DEFECT_DIR="$DRAFT_DIR"
    DEFECT_ID=""                       # allocated at promotion (Step 7.4)
    DRAFT_SLUG="$SLUG"
    DRAFT_FRAGMENT="$ARG"
    TRACKER="$DRAFT_DIR/DRAFT.md"      # /investigate gets a working file
    RCA_PATH=""                        # set at promotion
    TEST_PLAN_PATH=""                  # set at promotion
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

# C1 (Step 2 var-clobber guard, CRITICAL): this post-`case` recompute is
# correct for the canonical 1)/*) branches but would CLOBBER the 0)-branch
# draft values — an empty TRACKER (no *_TRACKER.md in a draft dir) and a
# malformed RCA_PATH/TEST_PLAN_PATH built from an empty $DEFECT_ID. Guard it
# so the draft path keeps TRACKER="$DRAFT_DIR/DRAFT.md", RCA_PATH="",
# TEST_PLAN_PATH="" until Step 7.4 rebinds them to canonical post-promotion.
if [ "${IS_DRAFT:-0}" != "1" ]; then
  TRACKER=$(find "$DEFECT_DIR" -maxdepth 1 -name "*_TRACKER.md" | head -1)
  RCA_PATH="$DEFECT_DIR/${DEFECT_ID}_RCA.md"
  TEST_PLAN_PATH="$DEFECT_DIR/${DEFECT_ID}_test-plan.md"
fi
```

## Step 3: Preflight — 5-row idempotency table

Compute the four state signals (R, F, P, M) and pick the resume row:

```bash
# v1.1 draft short-circuit: a draft is fresh by construction — no RCA, no
# D-ID, no PR possible. Skip the R/F/P/M computation entirely and resume at
# Row 1 (fresh: dispatch /investigate). The canonical R/F/P/M ladder below
# is unchanged for non-draft (IS_DRAFT=0) invocations.
if [ "${IS_DRAFT:-0}" = "1" ]; then
  R=0; F=0; P=0; M=0
  RESUME_ROW=1
  echo "Idempotency: draft (IS_DRAFT=1) → Row 1 (fresh) by construction"
else

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
fi  # end v1.1 draft short-circuit (IS_DRAFT=1 → Row 1; else canonical R/F/P/M ladder)
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

### Step 5.0: Isolation gate (T000033 — enforced before subagent dispatch)

`/investigate` Phase 4 writes the fix **directly to source** — there is no
separate implement step. Dispatching the subagent from an un-isolated or
dirty checkout means an in-place mutation of unrelated work (the D000024
bug class). This gate enforces the "clean + isolated" invariant BEFORE the
`ROLE:` dispatch prompt below is ever sent.

Run this bash block first. **Shell vars do NOT persist across bash tool
calls** (only cwd does — see CLAUDE.md), so the helper path is re-resolved
here via the *manifest-`source` idiom* (NOT the SKILL.md "Path Resolution"
idiom, which resolves skill assets and contains no `scripts/`):

```bash
# Hard idempotency guard (defense-in-depth — Rows 2/3/4/5 already jump past
# Step 5 via their Step 4 per-row branches; this makes the gate robust to
# prose-jump drift instead of inheriting the model-discipline dependency).
# The gate runs IFF this is a fresh run (RESUME_ROW == 1).
if [ "${RESUME_ROW:-1}" = "1" ]; then

  # Re-resolve the helper: (1) repo-local first (workbench self-development —
  # there may be NO deployed manifest, but scripts/cj-worktree-init.sh is
  # present repo-local; trying manifest first would false-halt here), then
  # (2) the deployed manifest .source path.
  _REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo "")
  _HELPER=""
  if [ -n "$_REPO_ROOT" ] && [ -x "$_REPO_ROOT/scripts/cj-worktree-init.sh" ]; then
    _HELPER="$_REPO_ROOT/scripts/cj-worktree-init.sh"
  else
    _SRC=$(jq -r '.source // empty' "$HOME/.claude/.skills-templates.json" 2>/dev/null || echo "")
    if [ -n "$_SRC" ] && [ -x "$_SRC/scripts/cj-worktree-init.sh" ]; then
      _HELPER="$_SRC/scripts/cj-worktree-init.sh"
    fi
  fi

  if [ -z "$_HELPER" ]; then
    # Helper unreachable after BOTH probes. Scoped revision of F000025
    # Decision #11 (which lets a missing helper WARN-and-continue): at THIS
    # boundary — immediately before a source-writing subagent dispatch —
    # unreachable means HALT, not silent in-place. This is exactly the
    # D000024 class the gate exists to close.
    TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    cat >> "$TRACKER" <<EOF
- $TS [investigate-not-isolated] worktree helper unreachable (repo-local + manifest .source both absent); cannot verify clean+isolated before source-writing subagent dispatch. HALT (no silent in-place write).
  next_action=Restore scripts/cj-worktree-init.sh (repo-local) or fix \$HOME/.claude/.skills-templates.json .source; then re-run.
  resume_cmd=$([ "${IS_DRAFT:-0}" = "1" ] && echo "/CJ_goal_investigate \"$DRAFT_FRAGMENT\"" || echo "/CJ_goal_investigate $DEFECT_ID")
  raw_output_path=N/A
EOF
    echo "Why it stopped: the worktree-isolation helper is unreachable, so a clean+isolated checkout can't be verified before /investigate writes the fix to source."
    if [ "${IS_DRAFT:-0}" = "1" ]; then
      echo "State preserved: draft retained at $DEFECT_DIR, no D-ID consumed"
      echo "Next: /CJ_goal_investigate \"$DRAFT_FRAGMENT\""
    else
      echo "State preserved: tracker at $TRACKER"
      echo "Next: /CJ_goal_investigate $DEFECT_ID"
    fi
    # Telemetry: end_state=halted_at_investigate_not_isolated
    exit 1
  fi

  # Exact gate argv. Forward ONLY --no-worktree, and only if the operator
  # passed it. NEVER forward --dry-run / --quiet / --force-create:
  #   - --dry-run already exited upstream at Step 3.5 (never reaches Step 5).
  #   - --quiet must NOT downgrade the isolation verdict (the helper ladder
  #     deliberately has no --quiet rule; forwarding it would be inert here
  #     but is omitted to keep the contract unambiguous).
  # The operator opt-out cannot ride a shell var ($NO_WORKTREE does NOT
  # persist across bash tool calls — CLAUDE.md; the prior code read an
  # always-unset var, making the documented escape hatch dead code). Step 1
  # persisted the opt-out RUN_ID-scoped; re-read that marker via the
  # model-carried RUN_ID (the same persistence pattern as TELEMETRY / RAW_DIR
  # / $TRACKER used elsewhere in this block).
  if [ -f "$HOME/.gstack/analytics/CJ_goal_investigate-runs/$RUN_ID/.operator-no-worktree" ]; then
    VERDICT_JSON=$("$_HELPER" --caller investigate --assert-isolated --no-worktree 2>&1) && _GRC=0 || _GRC=$?
  else
    VERDICT_JSON=$("$_HELPER" --caller investigate --assert-isolated 2>&1) && _GRC=0 || _GRC=$?
  fi
  VERDICT_STATE=$(echo "$VERDICT_JSON" | jq -r '.state' 2>/dev/null || echo "")

  if [ "$_GRC" -ne 0 ]; then
    # Non-zero verdict: dirty / not_isolated / not_a_repo. Append the halt
    # journal entry with a draft-aware resume_cmd, emit the C7 block, exit 1.
    TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    cat >> "$TRACKER" <<EOF
- $TS [investigate-not-isolated] isolation gate verdict=$VERDICT_STATE — checkout is not clean+isolated; refusing to dispatch the source-writing /investigate subagent (D000024 class).
  next_action=Make the checkout clean+isolated: commit/stash changes, or run from a fresh worktree / clean feature branch; or pass --no-worktree on a clean checkout.
  resume_cmd=$([ "${IS_DRAFT:-0}" = "1" ] && echo "/CJ_goal_investigate \"$DRAFT_FRAGMENT\"" || echo "/CJ_goal_investigate $DEFECT_ID")
  raw_output_path=N/A
EOF
    echo "Why it stopped: the checkout is not clean+isolated (verdict: $VERDICT_STATE), so /investigate would write the fix on top of unrelated work."
    if [ "${IS_DRAFT:-0}" = "1" ]; then
      echo "State preserved: draft retained at $DEFECT_DIR, no D-ID consumed"
      echo "Next: /CJ_goal_investigate \"$DRAFT_FRAGMENT\""
    else
      echo "State preserved: tracker at $TRACKER"
      echo "Next: /CJ_goal_investigate $DEFECT_ID"
    fi
    # Telemetry: end_state=halted_at_investigate_not_isolated
    exit 1
  fi

  echo "Isolation gate: verdict=$VERDICT_STATE — clean+isolated; proceeding to subagent dispatch."
fi
```

Only on a green (`isolated`, exit 0) verdict — or a legitimate resume where
`RESUME_ROW != 1` (the gate is skipped, Rows 2/3/4/5 already bypass Step 5
via their Step 4 branches) — does control proceed to build and send the
dispatch prompt below.

### Step 5.1: Build the dispatch prompt

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

**C2 (blank `$DEFECT_ID` leaks into Step 5, HIGH).** For a draft,
`$DEFECT_ID` is empty (it is allocated only at promotion, Step 7.4).
Interpolating an empty `DEFECT_ID:` line confuses `/investigate`. When
`IS_DRAFT=1`, the dispatch prompt's `DEFECT_ID:` line MUST read the literal:

```
DEFECT_ID:     (draft — none yet; working dir is the draft)
```

and `WORK_ITEM_DIR` is the draft dir (`$DEFECT_DIR`, which the 0) branch set
to `$DRAFT_DIR`), `TRACKER` is `$DRAFT_DIR/DRAFT.md`. The orchestrator-model
substitutes this draft-aware form when `IS_DRAFT=1`, the `$DEFECT_ID`-based
form otherwise.

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

**C2 + C7 — shared halt contract for EVERY Step 7 halt (and the Step 7.4
lock-timeout).** Two rules apply uniformly to Halt 1-5 below:

1. **C2 (blank `$DEFECT_ID` in `resume_cmd=`, HIGH).** Every halt's
   `resume_cmd=` interpolates `$DEFECT_ID`, which is empty for a draft. When
   `IS_DRAFT=1`, the halt's `resume_cmd=` MUST be the fragment-based form
   `resume_cmd=/CJ_goal_investigate "$DRAFT_FRAGMENT"` (the fragment is the
   only stable pre-promotion re-entry key — there is no D-ID yet). When
   `IS_DRAFT=0`, use the existing `$DEFECT_ID`-based command unchanged. The
   `cat >> "$TRACKER"` heredocs below show the canonical (non-draft) form;
   the orchestrator-model substitutes the fragment-based `resume_cmd=` line
   when `IS_DRAFT=1`. (For a draft, `$TRACKER` is `$DRAFT_DIR/DRAFT.md`, so
   the journal entry lands in the draft itself — recoverable on resume.)

2. **C7 (narrate the halt in plain English, HIGH).** In ADDITION to the
   journal heredoc, every halt MUST print a 3-line block to the terminal
   (stdout), in plain English, before `exit 1`:

   ```bash
   echo "Why it stopped: <one-line plain-English reason for THIS halt>"
   if [ "${IS_DRAFT:-0}" = "1" ]; then
     echo "State preserved: draft retained at $DEFECT_DIR, no D-ID consumed"
     echo "Next: /CJ_goal_investigate \"$DRAFT_FRAGMENT\""
   else
     echo "State preserved: tracker at $TRACKER"
     echo "Next: <the resume_cmd for this halt, verbatim, copy-pasteable>"
   fi
   ```

   The `Next:` line is verbatim copy-pasteable. The orchestrator-model emits
   this block for each of Halt 1-5 (and the Step 7.4 lock-timeout) with the
   halt-specific reason filled into `Why it stopped:`.

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

If we reach here, `$STATUS == "DONE"` and `$ROOT_CAUSE` is populated. The
Iron-Law gate has passed. Continue to Step 7.4 (promotion, only if this run
is a draft) then Step 7.5.

## Step 7.4: Promote draft → canonical defect dir (v1.1; only if `IS_DRAFT=1`)

Inserted between Step 7 (Iron-Law gate) and Step 7.5 (artifact writes). Runs
ONLY when `IS_DRAFT=1`. By the time control reaches here, Step 7 guarantees
`STATUS=DONE` and `$ROOT_CAUSE` is populated — so the Iron-Law gate has
passed and a D-ID may now be minted. If `IS_DRAFT=0` (canonical resolve),
this entire step is a NO-OP and control falls through to Step 7.5 unchanged.

**C3 — atomic promotion protocol (pinned ordering, all inside the
mkdir-lock).** This ordering is BINDING. The illustrative snippet below shows
it; the binding contract is the numbered ordering, not the exact shell:

1. `DRAFT_OLD="$DEFECT_DIR"` — capture the pre-rebind absolute draft path
   BEFORE any rebind. Step 5 (`rm -rf "$DRAFT_OLD"`) uses this saved path;
   never reconstruct from `$INBOX/$DRAFT_SLUG` (which may be out of scope).
2. Allocate the D-ID (highest-N scan) and `mkdir -p "$CANON_DIR"`.
3. **Write the canonical TRACKER** containing `name: $DRAFT_FRAGMENT`. **This
   is the DURABLE COMMIT POINT** — once it exists, the canonical resolver's
   `grep -rli --include="*_TRACKER.md" "$ARG"` (NAME_HITS, Step 2) resolves
   the canonical dir by fragment, so a re-invocation resumes the canonical
   defect with NO second D-ID.
4. Rebind `DEFECT_DIR/DEFECT_ID/TRACKER/RCA_PATH/TEST_PLAN_PATH` to canonical.
5. `rm -rf "$DRAFT_OLD"` — the saved absolute path from step 1, last.
6. Release the lock (`rmdir`; `trap - EXIT`).

Crash semantics:
- **Crash before step 3** → an empty `D000NNN_<slug>/` orphan dir. This is
  *not* a duplicate: the highest-N scan counts it, so the next promotion
  gets N+1. It is a harmless `rm -rf`-able artifact. Accepted.
- **Crash after step 3** → re-invocation's canonical resolver finds the
  D-ID dir (NAME_HITS via the written TRACKER), normal resume, no second
  D-ID.

**C4 — lock-timeout halt needs full bookkeeping.** The lock-acquisition
timeout path is a real halt: it MUST append a `[promote-lock-timeout]`
journal entry to the draft's `DRAFT.md` (with `next_action=` and
`resume_cmd=/CJ_goal_investigate "$DRAFT_FRAGMENT"`), write a telemetry line
with `end_state=halted_at_promote_lock_timeout`, and is the **13th
end-state** added to SKILL.md's halt-taxonomy table. It is NOT a bare
`echo; exit 1`. It also prints the C7 3-line terminal block (per the Step 7
shared C2+C7 contract — the lock-timeout is explicitly covered there).

```bash
if [ "${IS_DRAFT:-0}" = "1" ]; then
  # Allocate the D-ID under an mkdir-based lock (POSIX-atomic; stock macOS
  # has no flock). The highest-existing-N scan + the new mkdir are both
  # inside the lock so concurrent invocations cannot collide on a D-ID.
  LOCK_DIR="$DEFECTS_ROOT/.scaffold.lock.d"
  DRAFT_OLD="$DEFECT_DIR"                      # C3 step 1: save before any rebind
  i=0
  while ! mkdir "$LOCK_DIR" 2>/dev/null; do
    i=$((i+1))
    if [ $i -gt 50 ]; then
      # C4: full halt bookkeeping, not a bare echo/exit.
      TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)
      cat >> "$DRAFT_OLD/DRAFT.md" <<EOF

- $TS [promote-lock-timeout] D-ID allocation lock ($LOCK_DIR) held >10s; promotion aborted.
  next_action=Check for a stale lock dir; rmdir it if no other invocation is live, then re-invoke.
  resume_cmd=/CJ_goal_investigate "$DRAFT_FRAGMENT"
  raw_output_path=$RAW_OUTPUT
EOF
      # C7 3-line terminal block (per Step 7 shared contract).
      echo "Why it stopped: another invocation held the D-ID allocation lock for over 10 seconds, so I could not safely mint a defect number."
      echo "State preserved: draft retained at $DRAFT_OLD, no D-ID consumed"
      echo "Next: /CJ_goal_investigate \"$DRAFT_FRAGMENT\""
      # Telemetry: end_state=halted_at_promote_lock_timeout (13th end-state)
      exit 1
    fi
    sleep 0.2
  done
  # F3: save any pre-existing EXIT trap and restore it on release instead of a
  # bare `trap - EXIT` (which would silently drop a cleanup trap installed by
  # an earlier step or a future edit). The trap is installed only AFTER the
  # lock is acquired — a crash during the mkdir-wait loop must NOT rmdir a
  # lock we do not own.
  _PRIOR_EXIT_TRAP=$(trap -p EXIT)
  trap 'rmdir "$LOCK_DIR" 2>/dev/null' EXIT

  # C3 step 2: allocate D-ID. D000022 fix — the next D-ID is the max over the
  # UNION of three durable D-ID sources, +1. Two distinct root causes are
  # addressed here:
  #
  #  (a) Filesystem scan: NO -maxdepth cap. A -maxdepth 2 cap under-counted
  #      the highest D-ID whenever the max lived in a nested 2-segment domain
  #      (ops/skills-deploy/, ops/ship/, ops/workflow/ — depth 3), re-minting
  #      a colliding D-ID (the real D000022 incident, PR #161). The
  #      `D[0-9]{6}_` basename is globally unambiguous so an unbounded
  #      `find -type d -name 'D[0-9][0-9][0-9][0-9][0-9][0-9]_*'` is correct.
  #  (b) Git log + TODOS.md: a D-ID is durably recorded in git commit
  #      subjects and TODOS.md independent of any directory. A shipped-and-
  #      relocated defect, or a deferred/freestanding tracked-but-no-dir
  #      defect (e.g. a deferred D-ID that only ever appears in git/TODOS),
  #      is invisible to a filesystem-only scan and would be silently
  #      re-minted. Union all three integer sets; take the max.
  #
  # POSIX/BSD-portable: stock `find`/`sed`/`git`/`grep`, no GNU-only flags.
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

  DOMAIN="uncategorized"                       # domain inference is v1.2
  CANON_DIR="$DEFECTS_ROOT/$DOMAIN/${DEFECT_ID}_${DRAFT_SLUG}"
  mkdir -p "$CANON_DIR"
  NOW=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  # F1 (CRITICAL): the canonical TRACKER is BOTH the C3 durable commit point
  # AND a CJ_personal-workflow-validated artifact. The fragment is operator
  # free text; emit `name:` as a double-quoted YAML scalar with `\`/`"`
  # escaped and CR/LF stripped so a routine fragment like
  # `login: 500 on POST` cannot produce invalid frontmatter that wedges the
  # promoted work-item (validator/qa reject, draft already deleted).
  DRAFT_FRAGMENT_YAML=$(printf '%s' "$DRAFT_FRAGMENT" | tr -d '\r\n' | sed 's/\\/\\\\/g; s/"/\\"/g')

  # C3 step 3 — DURABLE COMMIT POINT. Write the canonical TRACKER. Once this
  # file exists, NAME_HITS (Step 2) resolves the canonical dir by fragment so
  # a crash here-or-after never allocates a second D-ID. auto_scaffolded +
  # promoted_from_draft are additive frontmatter keys; the CJ_personal-workflow
  # validator is pass-through on extra keys (check.md Step 16: "Extra key: no
  # flag") so no manifest/allowlist change is required.
  cat > "$CANON_DIR/${DEFECT_ID}_TRACKER.md" <<TRK
---
type: defect
id: $DEFECT_ID
name: "$DRAFT_FRAGMENT_YAML"
status: phase-1-investigating
created: $NOW
auto_scaffolded: true
promoted_from_draft: .inbox/$DRAFT_SLUG
---

# $DEFECT_ID: $DRAFT_FRAGMENT

## Bug Report
$DRAFT_FRAGMENT

## Journal
- $NOW [auto-scaffolded] /CJ_goal_investigate captured fragment "$DRAFT_FRAGMENT" as draft .inbox/$DRAFT_SLUG, then promoted to $DEFECT_ID after /investigate populated the root cause. Domain defaulted to '$DOMAIN'; \`mv\` to a more specific subdir if needed.
TRK

  # C3 step 4 — rebind ALL downstream vars to canonical paths. Step 7.5+ is
  # unchanged; it just operates on the rebound canonical vars. (TRACKER was
  # already written above as the durable commit point; this rebind points
  # the var at it.)
  DEFECT_DIR="$CANON_DIR"
  TRACKER="$CANON_DIR/${DEFECT_ID}_TRACKER.md"
  RCA_PATH="$CANON_DIR/${DEFECT_ID}_RCA.md"
  TEST_PLAN_PATH="$CANON_DIR/${DEFECT_ID}_test-plan.md"

  # C3 step 5 — remove the consumed draft LAST, using the saved absolute path.
  rm -rf "$DRAFT_OLD" 2>/dev/null

  # C3 step 6 — release the lock; restore the prior EXIT trap (F3), or clear
  # ours if there was none.
  rmdir "$LOCK_DIR" 2>/dev/null
  eval "${_PRIOR_EXIT_TRAP:-trap - EXIT}"

  # C7 (promotion success echo): plain-English, names the new D-ID + path.
  echo "Root cause found, so I converted the draft into defect $DEFECT_ID at $CANON_DIR (was: \"$DRAFT_FRAGMENT\"). The .inbox draft is now gone."
fi
```

After Step 7.4, `$DEFECT_DIR`/`$DEFECT_ID`/`$TRACKER`/`$RCA_PATH`/`$TEST_PLAN_PATH`
are the canonical post-promotion values (or the original canonical values
when `IS_DRAFT=0`). Steps 7.5-12 are unchanged.

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
# v1.1: auto_scaffolded is true iff this run promoted a draft (IS_DRAFT=1
# reached Step 7.4 successfully). Additive key — existing consumers read
# named fields, so no schema break.
jq -nc \
  --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  --arg run_id "$RUN_ID" \
  --arg defect_id "$DEFECT_ID" \
  --arg defect_dir "$DEFECT_DIR" \
  --arg end_state "green" \
  --arg pr_url "$PR_URL" \
  --argjson auto_scaffolded "$([ "${IS_DRAFT:-0}" = "1" ] && echo true || echo false)" \
  '{ts:$ts,run_id:$run_id,defect_id:$defect_id,defect_dir:$defect_dir,end_state:$end_state,pr_url:$pr_url,auto_scaffolded:$auto_scaffolded,parent_skill:"CJ_goal_investigate"}' \
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

Every exit path (success OR halt) writes a single telemetry line. v1.0 had 9
halt states + 3 success states (`green`, `already_shipped`,
`dry_run_preview`) = 12. v1.1 adds the `halted_at_promote_lock_timeout`
halt (Step 7.4 C4) → **13 total end-states**. Add any new halt with: (a) a
journal entry in the appropriate Step, (b) a telemetry write before exit,
(c) a row in SKILL.md's halt-taxonomy table.

| End-state | Halt marker | When |
|-----------|-------------|------|
| `halted_at_investigate_not_isolated` | `[investigate-not-isolated]` | T000033 — Step 5.0 isolation gate: checkout not clean+isolated (verdict `dirty`/`not_isolated`/`not_a_repo`) OR the worktree helper is unreachable after both probes. Pre-dispatch halt; the source-writing /investigate subagent is provably NOT dispatched. |

(The pre-existing inconsistent count strings in this file and SKILL.md —
"9-state", "13-state", "10+2", "14 named", "13-total" — are deliberately
NOT reconciled here; that is tracked as a separate cleanup. This row is
purely additive.)

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
