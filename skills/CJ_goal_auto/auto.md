# /CJ_goal_auto — Orchestration

Full-handoff one-liner-to-deployed pipeline. This file is the step-by-step
logic invoked from [SKILL.md](SKILL.md). Read SKILL.md first for path
resolution, error handling, and usage; then follow the steps below.

---

## Step 1: Arg parsing + mode resolution

Parse the user's arguments. The CLI shape is `/CJ_goal_auto [flags] [<idea>]`
where `<idea>` is a single positional (quoted) string. `--audit` /
`--list-handoffs` skip the idea requirement (read-only mode).

```bash
# Default-worktree (BEFORE path resolution) already ran in SKILL.md preamble.
# Variables get re-resolved post-cd here.

DRY_RUN=0
AUTO_MERGE=0
HANDOFF_ALIAS=0      # 1 if user passed deprecated --handoff
AUDIT_MODE=0
NO_WORKTREE=0        # passed-through; SKILL.md preamble handled the actual cd
QUIET="${QUIET:-0}"
IDEA=""

for _A in "$@"; do
  case "$_A" in
    --dry-run) DRY_RUN=1 ;;
    --auto-merge-small-diffs) AUTO_MERGE=1 ;;
    --handoff) AUTO_MERGE=1; HANDOFF_ALIAS=1 ;;
    --audit|--list-handoffs) AUDIT_MODE=1 ;;
    --no-worktree) NO_WORKTREE=1 ;;
    --quiet) QUIET=1 ;;
    --*) echo "[arg] WARN: unknown flag '$_A' (ignored)" >&2 ;;
    *) IDEA="$_A" ;;  # positional; only one accepted (later positional wins)
  esac
done

# Resolve mode
if [ "$AUDIT_MODE" = "1" ]; then
  MODE="audit"
elif [ "$DRY_RUN" = "1" ]; then
  MODE="dry-run"
elif [ "$AUTO_MERGE" = "1" ]; then
  MODE="auto-merge-small"
else
  MODE="human-gated"
fi

# Deprecation banner for --handoff alias
if [ "$HANDOFF_ALIAS" = "1" ]; then
  echo "[deprecation] --handoff is a deprecated alias for --auto-merge-small-diffs. Same behavior." >&2
fi

# Idea requirement (skipped in audit mode)
if [ "$MODE" != "audit" ] && [ -z "$IDEA" ]; then
  echo "Error: idea required. Use \`/CJ_goal_auto \"<one-liner>\"\` or \`--audit\` for read-only mode." >&2
  exit 1
fi
```

**Resolved-mode echo to stderr** (AC-2 — the load-bearing "operator confirms
Claude understood my intent" signal; printed UNCONDITIONALLY at run start, BEFORE
any work happens):

```bash
case "$MODE" in
  human-gated)
    echo "mode=human-gated handoff=0 max_files=5 max_lines=120" >&2
    ;;
  auto-merge-small)
    echo "mode=auto-merge-small handoff=1 max_files=5 max_lines=120" >&2
    ;;
  dry-run)
    echo "mode=dry-run handoff=0 max_files=5 max_lines=120 (no writes)" >&2
    ;;
  audit)
    echo "mode=audit (read-only)" >&2
    ;;
esac
```

If `MODE=audit`: jump directly to **Step 8 (audit handler)**. Otherwise continue
to Step 2.

Generate a run id for telemetry: `RUN_ID=$(date +%Y%m%d-%H%M%S)-$$`.

---

## Step 2: Stage 0 — worktree + version-queue + capability self-check

The worktree step ran in `SKILL.md`'s default-worktree block; the `cd` is already
done (or skipped per `--no-worktree`). Here we run the remaining Stage 0 checks.

### 2.1 Version-queue preflight (AC-3)

Run `scripts/check-version-queue.sh` if present. The script scans open PRs on
origin/main for `v<X.Y.Z>` prefixes and prints the next free VERSION slot. If
exit non-zero with a collision message: halt with `[version-queue-collision]`.

```bash
_REPO_ROOT=$(git rev-parse --show-toplevel)
if [ -x "$_REPO_ROOT/scripts/check-version-queue.sh" ]; then
  _VQ_OUT=$("$_REPO_ROOT/scripts/check-version-queue.sh" 2>&1) || _VQ_RC=$?
  _VQ_RC=${_VQ_RC:-0}
  if [ "$_VQ_RC" != "0" ]; then
    cat >&2 <<EOF
[version-queue-collision] halt
next_action=wait for the colliding PR to merge OR rebase the colliding branch
resume_cmd=/CJ_goal_auto $([ "$AUTO_MERGE" = "1" ] && echo "--auto-merge-small-diffs ")"$IDEA"

Detail:
$_VQ_OUT
EOF
    # Stage 3 audit receipt with halt state
    "$_SKILL_DIR/auto.md" >/dev/null 2>&1 || true   # no-op placeholder; actual receipt written below
    _write_receipt "halted_at_version_queue" "$IDEA" "" "" "" "" "" "" "" "" ""
    exit 1
  fi
else
  [ "$QUIET" != "1" ] && echo "[stage0] check-version-queue.sh not present; skipping (best-effort)" >&2
fi
```

### 2.2 `--handoff` capability self-check (AC-3, AC-19)

Grep the resolved `CJ_goal_run/run.md` for the support sentinel that the bootstrap
PR planted at the post-`/ship` / pre-`/land-and-deploy` seam. If absent: the
deployed `/CJ_goal_run` predates this skill and the gate is at risk of being
silently bypassed — fail closed.

The sentinel is a literal string the bootstrap PR adds to `run.md` immediately
adjacent to the gate call (test 9 in `scripts/test.sh` asserts the co-location).
The sentinel text:

```
CJ_GOAL_AUTO_HANDOFF_SENTINEL=v1
```

```bash
# Resolve CJ_goal_run/run.md (prefer in-repo over deployed copy).
_CJGR_RUN=""
if [ -f "$_REPO_ROOT/skills/CJ_goal_run/run.md" ]; then
  _CJGR_RUN="$_REPO_ROOT/skills/CJ_goal_run/run.md"
elif [ -f "$HOME/.claude/skills/CJ_goal_run/run.md" ]; then
  _CJGR_RUN="$HOME/.claude/skills/CJ_goal_run/run.md"
fi
if [ -z "$_CJGR_RUN" ]; then
  cat >&2 <<EOF
[capability-missing] halt
next_action=run \`./scripts/skills-deploy install\` from the workbench, then re-invoke
resume_cmd=/CJ_goal_auto $([ "$AUTO_MERGE" = "1" ] && echo "--auto-merge-small-diffs ")"$IDEA"

Detail: CJ_goal_run/run.md not found at workbench OR ~/.claude/skills/ path.
EOF
  _write_receipt "halted_at_capability" "$IDEA" "" "" "" "" "" "" "" "" ""
  exit 1
fi
if ! grep -qF 'CJ_GOAL_AUTO_HANDOFF_SENTINEL=v1' "$_CJGR_RUN"; then
  cat >&2 <<EOF
[capability-missing] halt
next_action=the deployed \`/CJ_goal_run\` predates this skill (no \`--handoff\` sentinel). Run \`./scripts/skills-deploy install\` from the workbench, then re-invoke.
resume_cmd=cd "$_REPO_ROOT" && ./scripts/skills-deploy install && /CJ_goal_auto $([ "$AUTO_MERGE" = "1" ] && echo "--auto-merge-small-diffs ")"$IDEA"

Detail: sentinel \`CJ_GOAL_AUTO_HANDOFF_SENTINEL=v1\` not found in $_CJGR_RUN.
EOF
  _write_receipt "halted_at_capability" "$IDEA" "" "" "" "" "" "" "" "" ""
  exit 1
fi
```

If `MODE=dry-run`: print the would-create paths and GATE #2 caps now (before
Stage 1 would run); skip to **Step 7 (audit receipt + summary)** with
`gate_result=dry_run_preview`. NO writes anywhere.

---

## Step 3: Stage 0.5 — classifier (small-unambiguous gate)

The classifier reads ONLY the one-liner (no other context) and returns one of
three verdicts:

- `small-unambiguous` — single concrete change, ≤5 files, no taste call, no
  cross-cutting refactor, no test-machinery touch. Proceeds.
- `needs-human-taste` — design choice / aesthetic decision / multiple plausible
  implementations. Halts.
- `too-big` — multi-file refactor / new subsystem / cross-cutting change. Halts.

Run as a fresh-context Agent subagent (`subagent_type: general-purpose`) with
this prompt:

```
<role>
Scope classifier. ONLY job: read the one-liner, return one verdict.
</role>

<task>
Classify the user's one-line idea into exactly one of:
  small-unambiguous | needs-human-taste | too-big

Decision rule (strict):
- small-unambiguous: ONE concrete change, fits in ≤5 files, ≤120 added lines,
  no taste/design call, no cross-cutting refactor, no shipping/test machinery touch,
  no security-sensitive surface change, no new dependency.
- needs-human-taste: requires picking between multiple plausible approaches OR
  involves UX/aesthetic/design judgment.
- too-big: multi-file refactor, new subsystem, schema change, dependency change,
  or scope clearly exceeds the small-unambiguous bar.

When uncertain, lean toward needs-human-taste (NOT small-unambiguous).
</task>

<return-contract>
End your final assistant message with a line in this exact form:
  RESULT: VERDICT=<small-unambiguous|needs-human-taste|too-big>; REASON=<one short sentence>
The line must be on its own. No prose after it.
</return-contract>

<inputs>
ONE_LINER: <IDEA verbatim>
</inputs>
```

Capture the subagent's output. Parse with the lenient parser (mirrors
`/CJ_personal-pipeline`'s `parse_result`):

```bash
parse_classifier() {
  local output="$1"
  echo "$output" \
    | grep -E 'RESULT: VERDICT=' \
    | tail -1 \
    | sed -E 's/^[[:space:]>]*//;s/```//g;s/~~~//g'
}
```

Append the verdict to `~/.gstack/analytics/cj-goal-auto-classifier.jsonl`
(orchestrator-owned write, AC-5):

```bash
mkdir -p ~/.gstack/analytics
_CLS_LOG=~/.gstack/analytics/cj-goal-auto-classifier.jsonl
_TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)
if command -v jq >/dev/null 2>&1; then
  jq -nc --arg ts "$_TS" --arg one_liner "$IDEA" --arg verdict "$VERDICT" --arg reason "$REASON" \
    '{ts:$ts,one_liner:$one_liner,verdict:$verdict,reason:$reason}' >> "$_CLS_LOG"
else
  _safe_idea=$(printf '%s' "$IDEA" | tr -d '\\"')
  _safe_reason=$(printf '%s' "$REASON" | tr -d '\\"')
  echo "{\"ts\":\"$_TS\",\"one_liner\":\"$_safe_idea\",\"verdict\":\"$VERDICT\",\"reason\":\"$_safe_reason\"}" >> "$_CLS_LOG"
fi
```

Branch on verdict:

- `small-unambiguous`: continue to Step 4.
- `needs-human-taste` or `too-big`: halt with `[classifier-halted]`:

```
[classifier-halted] verdict=$VERDICT reason="$REASON"
next_action=run /office-hours for taste-needing or larger changes; then /CJ_goal_run <doc>
resume_cmd=/office-hours "$IDEA"
```

Then `_write_receipt "halted_at_classifier" "$IDEA" "" "" "" "" "" "" "" "" "$VERDICT"` and exit.

- empty / no RESULT line: halt with `[classifier-halted]` verdict=unknown,
  reason="subagent did not emit RESULT line". Same receipt + exit.

---

## Step 4: Stage 1 — workbench-owned design-doc generator

Compute the doc path. The orchestrator is the source-of-truth for naming
(mirrors `/office-hours`):

```bash
_SLUG_USER=$(git config user.name | tr ' ' '-' | tr '[:upper:]' '[:lower:]' | tr -cd '[:alnum:]-')
[ -z "$_SLUG_USER" ] && _SLUG_USER="$(whoami)"
_BRANCH=$(git rev-parse --abbrev-ref HEAD)
_BRANCH_SLUG=$(printf '%s' "$_BRANCH" | tr '/' '-' | tr '[:upper:]' '[:lower:]' | tr -cd '[:alnum:]-')
_DT=$(date +%Y%m%d-%H%M%S)
_REPO_BASENAME=$(basename "$_REPO_ROOT")
_PROJECT_SLUG="${_SLUG_USER}-${_REPO_BASENAME}"
_GSTACK_DIR="$HOME/.gstack/projects/$_PROJECT_SLUG"
mkdir -p "$_GSTACK_DIR"
DOC_PATH="$_GSTACK_DIR/${_SLUG_USER}-${_BRANCH_SLUG}-design-${_DT}.md"
```

Render the doc from the **fixed template** below using string substitution. The
template is intentionally minimal (six headed sections plus the `Status:
APPROVED` line). `/CJ_goal_run`'s preflight only requires `Status: APPROVED`
under `~/.gstack/projects/` — autoplan reads the body and is the load-bearing
review surface anyway.

```markdown
# {AUTO_TITLE}

Status: APPROVED

## Problem Statement

{AUTO_PROBLEM}

## Premises

- Single one-liner intent, small blast radius (classifier verdict: small-unambiguous).
- Operator opted into this autonomous path (or human-gated review at GATE #2 if no flag).
- All safety controls (GATE #1 autoplan, GATE #2 cj-handoff-gate.sh, denylist, size cap) still fire.

## Recommended Approach

{AUTO_APPROACH}

## Success Criteria

- Operator approves at GATE #1 (autoplan final-approval AUQ).
- /CJ_personal-pipeline's Phase-2 markers all green (PIPELINE_END_STATE, SMOKE, E2E, PHASE2_GATES).
- GATE #2 (cj-handoff-gate.sh) exits 0 OR operator merges the PR by hand after structured halt.
- Deploy completes without canary red.

## Distribution Plan

- Workbench-internal change; no external rollout required.
- PR body carries the auto-merge audit line (when applicable) for traceability.
```

The four `{AUTO_*}` placeholders are filled by the orchestrator using simple
prose generation FROM the one-liner; no subagent dispatch needed (the substance
is the one-liner itself, padded for autoplan to chew on):

- `{AUTO_TITLE}` = the first 80 chars of `IDEA`, with trailing period stripped.
- `{AUTO_PROBLEM}` = `IDEA` verbatim (one sentence is fine; autoplan will probe it).
- `{AUTO_APPROACH}` = `"Smallest, most direct change that satisfies the one-liner: <IDEA>. Implementation details to be planned by autoplan + /CJ_personal-pipeline."`

Write the doc:

```bash
cat > "$DOC_PATH" <<EOF
# $AUTO_TITLE

Status: APPROVED

## Problem Statement

$AUTO_PROBLEM

## Premises

- Single one-liner intent, small blast radius (classifier verdict: small-unambiguous).
- Operator opted into this autonomous path (or human-gated review at GATE #2 if no flag).
- All safety controls (GATE #1 autoplan, GATE #2 cj-handoff-gate.sh, denylist, size cap) still fire.

## Recommended Approach

$AUTO_APPROACH

## Success Criteria

- Operator approves at GATE #1 (autoplan final-approval AUQ).
- /CJ_personal-pipeline's Phase-2 markers all green (PIPELINE_END_STATE, SMOKE, E2E, PHASE2_GATES).
- GATE #2 (cj-handoff-gate.sh) exits 0 OR operator merges the PR by hand after structured halt.
- Deploy completes without canary red.

## Distribution Plan

- Workbench-internal change; no external rollout required.
- PR body carries the auto-merge audit line (when applicable) for traceability.
EOF
```

---

## Step 5: Stage 1.5 — fail-closed post-condition doc gate (AC-7)

Verify the generator's output. ANY miss → abort + receipt + manual route.
**Stage 2 is NEVER invoked** if this gate fails.

Required sections (the same six headers the template wrote, in any order):

```
Problem Statement
Premises
Recommended Approach
Success Criteria
Distribution Plan
```

Required string: `Status: APPROVED` (anywhere in the body).

```bash
_REQUIRED_SECTIONS=("Problem Statement" "Premises" "Recommended Approach" "Success Criteria" "Distribution Plan")
_MISSING=()

if [ ! -f "$DOC_PATH" ]; then
  cat >&2 <<EOF
[doc-gate-fail] halt
next_action=Stage 1 generator did not write the doc; inspect /tmp + retry
resume_cmd=/CJ_goal_auto $([ "$AUTO_MERGE" = "1" ] && echo "--auto-merge-small-diffs ")"$IDEA"

Detail: expected $DOC_PATH; missing.
EOF
  _write_receipt "halted_at_doc_gate" "$IDEA" "$DOC_PATH" "" "" "" "" "" "" "" "$VERDICT"
  exit 1
fi

if ! grep -qF "Status: APPROVED" "$DOC_PATH"; then
  _MISSING+=("Status: APPROVED")
fi
for _SEC in "${_REQUIRED_SECTIONS[@]}"; do
  if ! grep -qE "^## $_SEC$" "$DOC_PATH"; then
    _MISSING+=("## $_SEC")
  else
    # Section header present; verify body is non-empty (next non-blank line after the header is NOT another ## header).
    _NEXT_NONBLANK=$(awk -v sec="$_SEC" '
      $0 == "## " sec {hit=1; next}
      hit && /^## /  {exit}
      hit && NF      {print; exit}
    ' "$DOC_PATH")
    if [ -z "$_NEXT_NONBLANK" ]; then
      _MISSING+=("## $_SEC (section body empty)")
    fi
  fi
done

if [ "${#_MISSING[@]}" -gt 0 ]; then
  cat >&2 <<EOF
[doc-gate-fail] halt — Stage 2 NEVER invoked
next_action=inspect $DOC_PATH; fix the generator template if recurring
resume_cmd=/CJ_goal_auto $([ "$AUTO_MERGE" = "1" ] && echo "--auto-merge-small-diffs ")"$IDEA"

Missing:
$(printf '  - %s\n' "${_MISSING[@]}")
EOF
  _write_receipt "halted_at_doc_gate" "$IDEA" "$DOC_PATH" "" "" "" "" "" "" "" "$VERDICT"
  exit 1
fi

[ "$QUIET" != "1" ] && echo "[stage1.5] doc gate green: $DOC_PATH" >&2
```

---

## Step 6: Stage 2 — invoke /CJ_goal_run --handoff --no-drain

Invoke `/CJ_goal_run` via the **Skill tool** with the generated doc path and
the `--handoff` + `--no-drain` flags (only the `--handoff` is added when
`AUTO_MERGE=1`; default human-gated mode skips it so `/CJ_goal_run` doesn't
auto-merge).

**Informed GATE #1 (AC-17)**: BEFORE invoking `/CJ_goal_run` (which will fire
autoplan's final-approval AUQ as GATE #1), print the doc's Problem Statement +
Recommended Approach to the operator. This is the "operator actually reads what
they're approving" surface.

```bash
echo "" >&2
echo "=== Generated design doc (for GATE #1 review) ===" >&2
echo "Path: $DOC_PATH" >&2
echo "" >&2
awk '/^## Problem Statement$/,/^## /' "$DOC_PATH" | sed '$d' >&2
awk '/^## Recommended Approach$/,/^## /' "$DOC_PATH" | sed '$d' >&2
echo "===" >&2
echo "" >&2
```

Then invoke (via Skill tool):

```
/CJ_goal_run <DOC_PATH> --handoff [--auto-merge-small-diffs] --no-drain
```

The flag set:
- `<DOC_PATH>` — the generated design doc.
- `--handoff` — **always passed**. Signals "called via /CJ_goal_auto"; tells
  `/CJ_goal_run`'s Step 4.5 to apply /CJ_goal_auto handoff semantics (halt
  after /ship in default mode; run gate helper in auto-merge mode) instead
  of the legacy direct-invocation pass-through.
- `--auto-merge-small-diffs` — passed ONLY in `auto-merge-small` mode
  (`AUTO_MERGE=1`). Tells `/CJ_goal_run` to invoke `scripts/cj-handoff-gate.sh`
  at the post-`/ship` / pre-`/land-and-deploy` seam (instead of halting for
  manual merge).
- `--no-drain` — always passed. Phase 5 (post-deploy TODO drain) is out of scope
  for the auto path; the operator runs `/CJ_goal_todo_fix` separately if desired.

`/CJ_goal_run` handles the rest: autoplan → GATE #1 → scaffold/impl/qa → /ship
(creates PR) → Step 4.5 (default mode: HALT after /ship for manual merge;
auto-merge mode: cj-handoff-gate.sh GATE #2 → /land-and-deploy on green).

In **default human-gated mode** (no `--auto-merge-small-diffs`), `/CJ_goal_run`
will halt at Step 4.5 with `END_STATE=halted_at_handoff` and a structured stop
block naming the PR URL. The operator merges manually via `gh pr diff` /
`gh pr merge`. This is the "exactly one mandatory human touchpoint" promised
by this skill's design (the GATE #2 diff review the operator performs by hand
on the created PR).

Capture `/CJ_goal_run`'s exit + final summary. Specifically extract:
- `PR_URL` (from `/CJ_goal_run`'s summary or `gh pr list --head $(git branch --show-current)`)
- `WORK_ITEM_DIR` (from `/CJ_goal_run`'s summary)
- `END_STATE` (`/CJ_goal_run`'s reported end_state, e.g. `green`, `halted_at_autoplan`, `halted_at_ship`, ...)
- `BASE_SHA` (from the gate helper's stdout, if it ran — or recompute as
  `git merge-base origin/main HEAD` for the receipt)

If `/CJ_goal_run` reported any halt: surface it pass-through under
`[stage2-halt]` AND the matching `[gate2-*]` if the halt originated in
`cj-handoff-gate.sh`:

```bash
case "$CJGR_END_STATE" in
  green)
    GATE_RESULT="auto-approved"   # auto-merge mode green path
    [ "$AUTO_MERGE" != "1" ] && GATE_RESULT="human-gated"
    ;;
  halted_at_handoff)
    # Step 4.5 default human-gated halt: PR is created and review-ready.
    # In AUTO_MERGE=0 mode this IS the expected outcome (the operator merges
    # manually). In AUTO_MERGE=1 mode this should never fire (the flag pair
    # would have routed to the gate helper instead) — surface it as a halt
    # so the operator notices the wiring drift.
    if [ "$AUTO_MERGE" = "1" ]; then
      GATE_RESULT="halted_at_stage2"   # defensive: unexpected in auto-merge mode
    else
      GATE_RESULT="human-gated"        # expected outcome for default mode
    fi
    ;;
  halted_at_autoplan|halted_at_pipeline|halted_at_ship)
    GATE_RESULT="halted_at_stage2"
    ;;
  halted_at_deploy|deploy_red)
    GATE_RESULT="halted_at_deploy"
    ;;
  *)
    # GATE #2 specific halts: the gate helper writes a single-line marker to
    # stderr that /CJ_goal_run surfaces; auto.md greps for it after the run.
    if echo "$CJGR_OUTPUT" | grep -qE '\[gate2-(denylist|size-cap|qa-marker|symlink|rename-denylist)\]'; then
      GATE_RESULT="halted_at_gate2"
    else
      GATE_RESULT="halted_at_stage2"
    fi
    ;;
esac
```

---

## Step 7: Stage 3 — audit receipt + retro AUQ + final summary

### 7.1 Write per-run audit receipt (AC-13)

Append a single JSON line to `~/.gstack/analytics/CJ_goal_auto.jsonl` via jq for
JSON-safe escaping (falls back to a sanitized echo if jq is absent):

```bash
mkdir -p ~/.gstack/analytics
_RCPT=~/.gstack/analytics/CJ_goal_auto.jsonl
_TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)

# Re-collect the gate fields the helper printed (best-effort; missing fields are empty strings).
# DENYLIST_RESULT, FILES_CHANGED, LINES_ADDED, SMOKE_MARK, E2E_MARK, PIPELINE_END_MARK, PHASE2_GATES_MARK come from CJGR_OUTPUT grep.

_write_receipt() {
  # args: gate_result idea doc_path work_item_dir pr_url base_sha files_changed lines_added denylist_result phase2_markers verdict
  local gate_result="$1" idea="$2" doc_path="$3" work_item_dir="$4" pr_url="$5"
  local base_sha="$6" files_changed="$7" lines_added="$8" denylist_result="$9" phase2_markers="${10}" verdict="${11}"
  local resume_cmd=""
  if [ -n "$pr_url" ] && [ "$gate_result" != "auto-approved" ] && [ "$gate_result" != "human-gated" ]; then
    local pr_num="${pr_url##*/}"
    resume_cmd="gh pr diff $pr_num  # then: gh pr merge $pr_num --squash --delete-branch (if good)"
  fi
  if command -v jq >/dev/null 2>&1; then
    jq -nc \
      --arg run_id "$RUN_ID" --arg ts "$_TS" --arg mode "$MODE" \
      --arg gate_result "$gate_result" --arg idea "$idea" --arg doc_path "$doc_path" \
      --arg work_item_dir "$work_item_dir" --arg pr_url "$pr_url" \
      --arg base_sha "$base_sha" --arg files_changed "$files_changed" --arg lines_added "$lines_added" \
      --arg denylist_result "$denylist_result" --arg phase2_markers "$phase2_markers" \
      --arg classifier_verdict "$verdict" --arg resume_cmd "$resume_cmd" \
      '{run_id:$run_id,ts:$ts,mode:$mode,gate_result:$gate_result,idea:$idea,doc_path:$doc_path,work_item_dir:$work_item_dir,pr_url:$pr_url,base_sha:$base_sha,files_changed:$files_changed,lines_added:$lines_added,denylist_result:$denylist_result,phase2_markers:$phase2_markers,classifier_verdict:$classifier_verdict,resume_cmd:$resume_cmd}' \
      >> "$_RCPT"
  else
    local safe_idea=$(printf '%s' "$idea" | tr -d '\\"')
    echo "{\"run_id\":\"$RUN_ID\",\"ts\":\"$_TS\",\"mode\":\"$MODE\",\"gate_result\":\"$gate_result\",\"idea\":\"$safe_idea\",\"doc_path\":\"$doc_path\",\"work_item_dir\":\"$work_item_dir\",\"pr_url\":\"$pr_url\",\"base_sha\":\"$base_sha\",\"files_changed\":\"$files_changed\",\"lines_added\":\"$lines_added\",\"denylist_result\":\"$denylist_result\",\"phase2_markers\":\"$phase2_markers\",\"classifier_verdict\":\"$verdict\",\"resume_cmd\":\"$resume_cmd\"}" >> "$_RCPT"
  fi
}

_write_receipt "$GATE_RESULT" "$IDEA" "$DOC_PATH" "$WORK_ITEM_DIR" "$PR_URL" "$BASE_SHA" "$FILES_CHANGED" "$LINES_ADDED" "$DENYLIST_RESULT" "$PHASE2_MARKERS" "$VERDICT"
```

### 7.2 Every-run retro AUQ (AC-18; auto-merge mode + green only)

Skip in dry-run / audit / human-gated / halted runs. Only fires when
`GATE_RESULT=auto-approved` (the merge actually happened).

```bash
if [ "$GATE_RESULT" = "auto-approved" ]; then
  # Count cumulative auto-approved entries
  _AUTO_COUNT=$(grep -c '"gate_result":"auto-approved"' "$_RCPT" 2>/dev/null || echo 0)
  _FIRE=0
  if [ "$_AUTO_COUNT" -le 5 ]; then
    _FIRE=1   # every run for first 5
  elif [ $(( _AUTO_COUNT % 5 )) -eq 0 ]; then
    _FIRE=1   # every 5th after that
  fi
  if [ "$_FIRE" = "1" ]; then
    # Surface a single AskUserQuestion: "Confirm this auto-merged change did NOT need human review."
    # Options:
    #   A) Confirmed — looks right (no follow-up)
    #   B) Should have been human-reviewed (note in classifier log for tuning)
    # On B: append to ~/.gstack/analytics/cj-goal-auto-classifier.jsonl a
    # {ts, verdict:"false-negative-flagged-by-retro", pr_url} line.
    :
  fi
fi
```

The actual AUQ is rendered by the orchestrator-model (not in bash) using the
AskUserQuestion tool when `_FIRE=1` is observed. The skill spec is: a single
question presenting the diff URL + ELI10 of what was changed, with the two
options above. On B, append the false-negative flag to the classifier log
(no other action — this is signal for tuning, not for revert).

### 7.3 Final summary

Print a single block to stderr (mirrors `/CJ_goal_run`'s summary shape):

```
CJ_GOAL_AUTO COMPLETE: gate_result=<GATE_RESULT>  mode=<MODE>

Run ID:        <RUN_ID>
Idea:          <IDEA>
Classifier:    <VERDICT> — <REASON>
Doc:           <DOC_PATH>
Work item:     <WORK_ITEM_DIR>
PR:            <PR_URL>
Pinned BASE:   <BASE_SHA>
Files:         <FILES_CHANGED>  Lines added: <LINES_ADDED>
Denylist:      <DENYLIST_RESULT>
Phase-2:       <PHASE2_MARKERS>
Receipt:       ~/.gstack/analytics/CJ_goal_auto.jsonl (run_id=<RUN_ID>)

Next:
  gh pr view <PR_NUM>                  # see the PR
  /CJ_goal_auto --audit                # review recent receipts
  /CJ_goal_todo_fix                    # drain any TODOs added by this run (skipped at --no-drain)
```

For halted runs, replace the body with the structured stop block + `next_action=`
+ `resume_cmd=` + `pr_url=` lines.

---

## Step 8: Audit handler (--audit / --list-handoffs read-only)

Reached only when `MODE=audit`. Print the last 10 entries in human-readable form:

```bash
_RCPT=~/.gstack/analytics/CJ_goal_auto.jsonl
if [ ! -f "$_RCPT" ]; then
  echo "No receipts yet. (Run /CJ_goal_auto \"<idea>\" first.)"
  exit 0
fi

echo "Last 10 /CJ_goal_auto receipts (most recent first):"
echo ""
if command -v jq >/dev/null 2>&1; then
  tail -10 "$_RCPT" | tac 2>/dev/null || tail -10 "$_RCPT" | tail -r 2>/dev/null || tail -10 "$_RCPT"
  echo ""
  tail -10 "$_RCPT" | jq -r '"\(.ts)  \(.gate_result)  mode=\(.mode)\n  idea: \(.idea)\n  pr: \(.pr_url // "—")\n  base: \(.base_sha // "—")  files=\(.files_changed // "—") lines=\(.lines_added // "—")\n  phase2: \(.phase2_markers // "—")\n  classifier: \(.classifier_verdict // "—")\n"'
else
  tail -10 "$_RCPT"
fi

# Write an audit_view receipt (for trace completeness, optional)
_write_receipt "audit_view" "" "" "" "" "" "" "" "" "" ""
exit 0
```

`tac` is GNU; macOS has `tail -r`. The fallback chain handles both; final
fallback (plain `tail -10`) preserves chronological order but never crashes.

---

## Step 9: Notes

- **Sentinel co-location** (AC-19, test 9): the bootstrap PR plants
  `CJ_GOAL_AUTO_HANDOFF_SENTINEL=v1` within 20 lines of the
  `scripts/cj-handoff-gate.sh` invocation in `skills/CJ_goal_run/run.md`. The
  Stage 0 capability check greps the sentinel only — the test validates the
  distance.

- **No GATE #1 auto-approve** (deferred per parent DESIGN "Not in scope"):
  autoplan's final-approval AUQ is ALWAYS human in v1.0. The Stage 2 informed
  block helps the operator make an informed decision; it does not bypass.

- **`/ship` Gate #2 (diff review) still fires under `--handoff`** when
  `/CJ_goal_run` invokes `/ship` — the gate ordering is: `/ship` diff review
  (operator-facing, F000021-ceiling-preserved-by-design) → THEN
  `scripts/cj-handoff-gate.sh` (deterministic, no AUQ) → `/land-and-deploy`.
  The auto-merge surface starts AFTER `/ship`'s diff review.

- **Concurrent-run handling** (parent SPEC Tradeoffs row): advisory only via
  `scripts/check-version-queue.sh`. Two unattended runs started seconds apart
  can both pass preflight and race for the same VERSION slot — documented v1
  limitation; single-developer personal tooling. v2 prerequisite (atomic slot
  reservation) lands with Approach C scheduled drain if/when that lands.

- **Post-deploy detection** (parent SPEC Coverage Gaps): for skill-markdown
  changes, `/land-and-deploy`'s web canary / health checks are near-vacuous
  (built for a web app). Real mitigation is size cap + denylist + per-invocation
  opt-in + audit log. "Revert is one command" but the expensive part is
  noticing — accepted with eyes open. The every-run retro AUQ for the first 5
  auto-merges is the primary catch.

- **Cross-machine portability** is out of v1 scope. v1.0 is workbench-only
  (macOS, this repo). No Copilot bundle surface; no portability tests.
