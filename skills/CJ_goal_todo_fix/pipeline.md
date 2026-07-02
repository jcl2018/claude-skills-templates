# /CJ_goal_todo_fix — Orchestration (impl→qa dispatch + Step 5.5 reference)

The bulk of `/CJ_goal_todo_fix`'s orchestration lives in
`scripts/todo_fix.sh` (single-TODO mode) and `scripts/drain-one-todo.sh`
(drain-mode inner loop). See [SKILL.md](SKILL.md) for the full per-TODO
chain (TODOS.md row → preflight → T-task scaffold → /CJ_implement-from-spec
→ /CJ_qa-work-item → /ship Gate #2 → /land-and-deploy → TODOS.md DONE-mark
→ telemetry).

This file documents the two orchestrator-layer steps the bash scripts
cannot run themselves: **Step 4** (the flattened impl→qa leaf-subagent
dispatch, which replaced the retired middle-layer pipeline skill — F000039)
and the workbench-introduced **Step 5.5: Doc-sync** that runs INLINE
per-TODO between the QA-green boundary and `/ship`. The wiring matches
`/CJ_goal_feature` and `/CJ_goal_defect` exactly, modulo the `<verb>`
(`todo_fix`) in the resume_cmd.

### Step 4: Dispatch impl→qa (flattened — leaf Agent subagents)

`scripts/todo_fix.sh` emits a `CJ_GOAL_HANDOFF_BEGIN/END` block whose
`WORK_ITEM_DIR=<path>` names the scaffolded T-task dir (the bash scaffold at
`todo_fix.sh:608-693` already did the scaffold work, so the dispatched chain
is impl→qa only — no separate scaffold step). The orchestrator parses that
path, then
dispatches the two leaf phase skills in sequence — exactly
`/CJ_goal_feature/pipeline.md` Steps 3.2-3.3 (both **Agent**-tool,
silent / no-AUQ), minus the scaffold step (3.1):

1. **Implement.** Dispatch `/CJ_implement-from-spec` via the **Agent** tool
   against `$WORK_ITEM_DIR` in auto-equivalent mode (subagents have no AUQ
   tool):

   ```
   ROLE: /CJ_implement-from-spec runner for /CJ_goal_todo_fix (silent — no AUQ).
   TASK: Invoke /CJ_implement-from-spec on the work-item dir in <inputs>, auto
   mode. Return the RESULT line verbatim: RESULT: STATUS=<...>; FILES_CHANGED=<n>.
   <inputs>WORK_ITEM_DIR: <absolute $WORK_ITEM_DIR></inputs>
   ```

   On crash / non-green RESULT (including a sensitive-surface AUQ the subagent
   cannot answer): **HALT** with end_state `halted_at_impl`, write a journal
   entry to the per-TODO T-task tracker, and stop. In drain mode the loop STOPs
   on halt-on-red regardless of `--quiet`.

2. **QA.** On impl green, dispatch `/CJ_qa-work-item` via the **Agent** tool
   against the same `$WORK_ITEM_DIR`. The dispatch prompt carries the literal
   directive `DEFER_AUDIT: true` so QA DEFERS its three-stage audit (qa.md Step
   8.6c/8.6d) — the orchestrator runs that audit ONCE at the authoritative
   post-sync point (Step 5.5b). QA still runs its 8.6a/8.6b overlay writes inline
   and returns `AUDITS=deferred` with NO `AUDIT_FINDINGS` block:

   ```
   ROLE: /CJ_qa-work-item runner for /CJ_goal_todo_fix (silent — no AUQ).
   DEFER_AUDIT: true
   TASK: Invoke /CJ_qa-work-item on the work-item dir in <inputs>. The literal
   DEFER_AUDIT: true directive above tells QA to run its Step 8.6a/8.6b overlay
   writes inline but DEFER the 8.6c/8.6d three-stage audit (the orchestrator runs
   the post-sync audit itself at Step 5.5b). Return the RESULT line verbatim —
   including the AUDITS= field (it will read AUDITS=deferred,spec_updates:<...>);
   do NOT expect an AUDIT_FINDINGS block on the deferred path:
   RESULT: SMOKE=<...>; E2E=<...>; PHASE2_GATES=<...>; AUDITS=deferred,spec_updates:<...>
   <inputs>WORK_ITEM_DIR: <absolute $WORK_ITEM_DIR></inputs>
   ```

   On QA red: **HALT** with end_state `halted_at_qa` (re-use the CJ_qa-work-item
   halt marker — do NOT mint a new one), write the journal entry, and stop.

Only on QA green does control proceed to Step 5.4 (the pre-doc-sync commit),
then Step 5.5 (Doc-sync), then Step 5.5b (the post-sync audit), then the
QA-audit checkpoint (consuming the post-sync report; SKILL.md), then `/ship`.
Both subagents are depth-≤2 leaves (they do NOT
spawn further subagents — the F000027 wall).

### Step 5.4: Pre-doc-sync commit (NEW — automated, idempotent; closes the F000038 gotcha)

`scripts/todo_fix.sh` bash-scaffolds the T-task but does NOT commit, and the
impl + QA leaf subagents WRITE the fix + the qa.md 8.6a/8.6b spec-overlay
refreshes without committing; `/ship` (the committer) runs after doc-sync.
`/CJ_document-release` (Step 5.5) hard-refuses on an uncommitted NON-DOC change
(`[doc-sync-red]`). This NEW orchestrator-layer step commits the QA-green tree so
doc-sync never hits the uncommitted-non-doc refusal during a drain.

The commit is **idempotent**: it skips when the tree is already clean at HEAD, so
a resume after the commit already ran does NOT double-commit. It records NO new
phase boundary — it is gated on the live tree state:

```bash
_REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo "")
if git -C "$_REPO_ROOT" diff --quiet && git -C "$_REPO_ROOT" diff --cached --quiet; then
  echo "[pre-doc-sync-commit] tree already clean at HEAD — nothing to commit (idempotent skip)."
else
  git -C "$_REPO_ROOT" add -A
  git -C "$_REPO_ROOT" commit -m "fix: $T_ID $TODO_HEADING_OR_T_ID (QA-green; pre-doc-sync commit)" >/dev/null
  echo "[pre-doc-sync-commit] committed the QA-green fix + 8.6a/8.6b overlay writes (clean tree for doc-sync)."
fi
```

(`/ship` adds the VERSION/CHANGELOG bump as a follow-on commit.) Only after a
clean tree is established does control proceed to Step 5.5 (doc-sync).

### Step 5.5: Doc-sync (INLINE — CJ_document-release wrapper around upstream /document-release)

Doc-sync runs INLINE between the pre-doc-sync commit (Step 5.4) and the post-sync
audit (Step 5.5b), so any doc updates fold into the SAME per-TODO PR as the TODO
fix. There is no post-merge doc-drift window for orchestrator-driven paths: the
doc update ships in the same PR as the TODO fix. Doc-sync now runs **before** the
post-sync audit + the QA-audit checkpoint (F000064 reorder), so the checkpoint
decides on the docs that will actually ship.

Invoke `/CJ_document-release` via the **Skill** tool with NO `--docs` flag
(v1 orchestrator wiring runs a full audit; the per-doc subset flag is for
manual operator invocations). The skill returns one of three RESULTs:

- `RESULT: green` — `/document-release` ran clean and the wrapper
  auto-committed doc-only changes (whitelist: `README|CHANGELOG|CLAUDE|
  ARCHITECTURE.md` + `doc/.+\.md` + `templates/doc-.*\.md`). Continue to
  `/ship` Gate #2. The next phase will see a clean tree with a doc commit
  already present.
- `RESULT: green-noop` — `/document-release` ran clean and no doc changes
  were needed. Continue to `/ship` Gate #2. The PR will be code-only.
- `RESULT: red; HALT_MARKER=[doc-sync-red]` — `/document-release` itself
  returned non-green (audit error, mid-write failure, hard-abort, base-
  branch refusal, or a pre-run non-doc dirty tree). **HALT** with halt
  class `halted_at_doc_sync`; the orchestrator writes a journal entry to
  the per-TODO T-task tracker and exits. In drain mode the loop STOPs on
  halt-on-red regardless of `--quiet` (cron operator inspects journal).
- `RESULT: red; HALT_MARKER=[doc-sync-non-doc-write]` — `/document-release`
  succeeded but wrote files OUTSIDE the doc-only whitelist (upstream-
  misbehaved). **HALT** with halt class `halted_at_doc_sync_non_doc_write`;
  the orchestrator writes a journal entry naming the non-doc files and
  exits.

Halt-marker shape (mirrors the family contract — `next_action=` /
`resume_cmd=` / `pr_url=`):

```bash
# Pseudocode — the per-TODO Step 5.5 dispatch handler (single-TODO mode
# and drain-mode per-iteration both use this shape):
case "$DOC_SYNC_RESULT" in
  green|green-noop)
    echo "[doc-sync] $DOC_SYNC_RESULT — continuing to /ship"
    # No state change beyond the doc commit /CJ_document-release made.
    ;;
  *red*\[doc-sync-red\]*)
    TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    cat >> "$T_TRACKER" <<EOF

- $TS [doc-sync-red] /CJ_document-release returned RESULT=red; halt class halted_at_doc_sync.
  next_action=Inspect /document-release output; fix doc errors; re-run /CJ_document-release manually, then resume /CJ_goal_todo_fix.
  resume_cmd=/CJ_goal_todo_fix "$TODO_HEADING_OR_T_ID"
  pr_url=N/A
  raw_output_path=$RAW_DIR/doc-sync-raw.txt
EOF
    echo "Why it stopped: /CJ_document-release failed (upstream /document-release non-green or pre-run gate refused)."
    echo "State preserved: T-task $T_ID intact; doc-sync did NOT commit doc files."
    echo "Next: inspect the failure, fix manually, then /CJ_goal_todo_fix \"$TODO_HEADING_OR_T_ID\""
    # Telemetry: end_state=halted_at_doc_sync
    # Drain mode: STOP the loop (matches the existing halt-on-red drain contract)
    exit 1
    ;;
  *red*\[doc-sync-non-doc-write\]*)
    TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    cat >> "$T_TRACKER" <<EOF

- $TS [doc-sync-non-doc-write] /CJ_document-release refused to auto-commit because upstream wrote files outside the doc-only whitelist.
  next_action=Inspect uncommitted non-doc files; revert if unexpected; re-run /CJ_document-release manually, then resume /CJ_goal_todo_fix.
  resume_cmd=/CJ_goal_todo_fix "$TODO_HEADING_OR_T_ID"
  pr_url=N/A
  raw_output_path=$RAW_DIR/doc-sync-raw.txt
EOF
    echo "Why it stopped: /CJ_document-release refused — upstream /document-release wrote files outside the doc-only whitelist."
    echo "State preserved: T-task $T_ID intact; nothing auto-committed."
    echo "Next: inspect the non-doc files, revert if unexpected, then /CJ_goal_todo_fix \"$TODO_HEADING_OR_T_ID\""
    # Telemetry: end_state=halted_at_doc_sync_non_doc_write
    exit 1
    ;;
esac
```

Only on green or green-noop does control proceed to Step 5.5b (the post-sync
audit), then the QA-audit checkpoint (SKILL.md), then `/ship` Gate #2.

### Step 5.5b: Post-sync doc/test audit (NEW — ONE combined read-only subagent)

Now that doc-sync has folded its doc updates into the per-TODO PR, run the
three-stage doc/test audit ONCE, at the authoritative **post-sync** point. This
is the audit QA deferred (via `DEFER_AUDIT: true`, Step 4) — the orchestrator runs
it itself here so the QA-audit checkpoint decides on the docs that will actually
ship.

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
ROLE: combined post-sync doc/test auditor for /CJ_goal_todo_fix (READ-ONLY — report, do not fix).
TASK: Run /CJ_doc_audit and then /CJ_test_audit over the CURRENT (post-doc-sync)
repo tree, standalone (all three stages each). Do NOT write any doc/overlay
fixes — this is a read-only report. Return BOTH skills' full per-stage reports
verbatim: the DOC_AUDIT: headline (FINDINGS= + STAGE1/2/3_FINDINGS= +
DOCS_AUDITED= + seeded: + the three --- stage N --- sections) and the
TEST_AUDIT: headline (FINDINGS= + STAGE1/2/3_FINDINGS= + UNITS_AUDITED= +
seeded: + the three --- stage N --- sections), then emit a single fenced
AUDIT_FINDINGS block combining both for the checkpoint to print verbatim.
<inputs>REPO_ROOT: <absolute repo root></inputs>
```

Capture the subagent's output to `$RAW_DIR/post-sync-audit-raw.txt`. Parse the
two `FINDINGS=` lines into a compact `AUDITS=doc:<ok|findings:n>,test:<ok|findings:n>`
digest and capture the fenced `AUDIT_FINDINGS` block for the checkpoint. This step
is a **pure read** (records NO phase boundary, writes no fixes), so a resume
re-runs it. If the audit subagent crashes (no parseable report), treat it as
`AUDITS=doc:audit-error,test:audit-error` and surface the raw output at the
checkpoint — do NOT halt here (the checkpoint owns the decision). The QA-audit
checkpoint (described in [SKILL.md](SKILL.md)) then consumes THIS post-sync digest
+ AUDIT_FINDINGS block (NOT a pre-sync QA RESULT field).

### --quiet mode interaction

The cron-eligible `--quiet` mode (v4.3.0+) suppresses summary banners +
AUQs only; it does NOT suppress the `[doc-sync-red]` or
`[doc-sync-non-doc-write]` halt contracts. Drain mode STOPs the loop on
either marker; the cron operator inspects the halt journal at their
convenience. Silently swallowing doc-sync failures would defeat the
purpose of the halt-on-red contract.

### Step 5.6: Surface registered-doc verdicts (post-`/ship`, pre-`/land-and-deploy`)

The Step 5.5 doc-sync wrapper (`/CJ_document-release`) ran a Registered-doc
requirements audit (its Step 6.7) and wrote the verdict block to the gitignored
scratch file `.cj-goal-feature/registered-doc-verdicts.md`. That block dies in
the wrapper RESULT otherwise — upstream `/ship` Step 18 regenerates the PR body
from a fresh `/document-release` subagent that never sees the wrapper output. So
the agent surfaces it deterministically here, in the agent-driven `/ship` →
`/land-and-deploy` tail (this pipeline has no pipeline-step auto-invoke past
Step 5.5; the `/ship` → `/land-and-deploy` → DONE-mark sequence is described in
SKILL.md Routing). Right AFTER `/ship` opens the PR (PR identifier known) and
BEFORE `/land-and-deploy` merges it, read the scratch file and
`gh pr edit "$PR_URL"` to insert-or-replace a `### Registered-doc requirements`
subsection under the PR body's `## Documentation` section. Use the `$PR_URL` from
`/ship`'s output (the agent has it at this point in the Routing chain — like
defect, this pipeline has no `$PR_NUMBER`; `gh pr view` / `gh pr edit` both accept
a URL).

**ONE site covers both single-TODO and drain mode** — they converge on the same
agent-driven post-handoff `/ship` → `/land-and-deploy` chain, so the surfacing
runs once per shipped PR right after that PR's `/ship`. (In drain mode the
producer re-writes the scratch per iteration at that TODO's Step 5.5, so reading
it right after the same iteration's `/ship` keeps it correct for that PR.)
`drain-one-todo.sh` is **NOT** a surfacing site — it only emits
`RESULT: … PR_URL=<url>`; the surfacing lives in the agent-driven tail, not in
that script.

This is **best-effort and NEVER halts the run**: a failed `gh pr edit` (or a
missing scratch file — Step 5.5 may have been a no-op path) logs a one-line note
and control proceeds to `/land-and-deploy`. The verdicts still live in the run
output + the scratch file regardless. There is **NO upstream `/ship`
modification** — this is a workbench-owned step. All three cj_goal orchestrators
surface the verdict (`/CJ_goal_feature` Step 4.6, `/CJ_goal_defect` Step 9.5,
`/CJ_goal_todo_fix` here); the Step 6.7 producer is shared by all three. The
scratch path is the LITERAL `.cj-goal-feature/registered-doc-verdicts.md` (NOT
verb-renamed — only `.cj-goal-feature/` is gitignored).

```bash
_REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo "")
_VERDICT_FILE="$_REPO_ROOT/.cj-goal-feature/registered-doc-verdicts.md"
if [ -n "$PR_URL" ] && [ -f "$_VERDICT_FILE" ]; then
  # Read the current PR body, then insert-or-replace the
  # '### Registered-doc requirements' subsection under '## Documentation'.
  _BODY=$(gh pr view "$PR_URL" --json body -q .body 2>/dev/null || echo "")
  _VERDICTS=$(cat "$_VERDICT_FILE")

  # Idempotent splice (replace-if-present): strip any existing
  # '### Registered-doc requirements' block (up to the next '###'/'##' or EOF),
  # then insert the fresh block under the '## Documentation' heading (appending
  # the section if absent). Composed in temp files + applied via `gh pr edit
  # --body-file` — NEVER `awk -v v="$_VERDICTS"` with a multi-line payload: BSD/macOS
  # awk rejects a newline in a -v value ("newline in string"), which empties the
  # substitution and lets the edit WIPE the PR body (PR #259; fixed by T000053).
  _STRIPPED_FILE=$(mktemp); _INSERT_FILE=$(mktemp); _BODY_FILE=$(mktemp)
  printf '%s\n' "$_BODY" | awk '
    /^### Registered-doc requirements/ {skip=1; next}
    skip && /^#{2,3} / {skip=0}
    !skip {print}
  ' > "$_STRIPPED_FILE"
  printf '%s\n' "$_VERDICTS" > "$_INSERT_FILE"
  if grep -q '^## Documentation' "$_STRIPPED_FILE"; then
    # The only -v is a newline-free FILENAME; the payload is read from the file.
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
    echo "[registered-doc] surfaced verdicts into PR $PR_URL body (## Documentation → ### Registered-doc requirements)"
  else
    echo "[registered-doc] PR-body splice did not verify after retry — verdicts remain in the run output + $_VERDICT_FILE (best-effort, not halting)"
  fi
else
  echo "[registered-doc] no verdict scratch file (or no PR URL) — skipping PR-body surfacing (best-effort, not halting)"
fi
```

**BEFORE-land recap (3-part; advisory — F000068).** `todo_fix` is a landing verb:
it drains each TODO end-to-end through `/ship → /land-and-deploy`, so it emits a
recap BEFORE the land and another AFTER (the AFTER half runs in SKILL.md's
Agent-layer terminal, after `/land-and-deploy` + the DONE-mark). Render the BEFORE
block HERE — right after `/ship` opened the PR and before `/land-and-deploy` merges
it — **per drained TODO** (this site runs once per shipped PR, same as the Step 5.6
surfacing above). YOU (the agent) author the three fields for THIS TODO's change;
the helper only formats:

```bash
_COMMON="$_REPO_ROOT/scripts/cj-goal-common.sh"
if [ -x "$_COMMON" ]; then
  bash "$_COMMON" --phase recap --mode feature --when before \
    --field delivered="<this TODO's change in plain terms + the TODOS row it closes; PR $PR_URL>" \
    --field e2e="<the concrete end-to-end commands/checks that prove THIS change — e.g. scripts/test.sh, a specific scripts/*.sh invocation, or 'open PR and read section X'>" \
    --field next="/land-and-deploy is about to merge + deploy PR $PR_URL, then the TODOS.md DONE-mark."
fi
```

(`--mode feature` matches this pipeline's `--phase sync` calls
— the block shape is verb-neutral and `--mode` is labelling-only.) **Prose fallback
(helper absent):** emit the same 3-part block as prose under an
`=== About to land ===` header (do NOT halt — the recap is advisory; a missing
field renders an empty section).

Control always proceeds to `/land-and-deploy` — this step has no halt path.
