# /CJ_goal_todo_fix — Orchestration (Step 5.5 reference)

The bulk of `/CJ_goal_todo_fix`'s orchestration lives in
`scripts/todo_fix.sh` (single-TODO mode) and `scripts/drain-one-todo.sh`
(drain-mode inner loop). See [SKILL.md](SKILL.md) for the full per-TODO
chain (TODOS.md row → preflight → T-task scaffold → /CJ_personal-pipeline
→ /ship Gate #2 → /land-and-deploy → TODOS.md DONE-mark → telemetry).

This file documents the workbench-introduced **Step 5.5: Doc-sync**
that runs INLINE per-TODO between QA pass (the /CJ_personal-pipeline
green return) and `/ship`. The wiring matches `/CJ_goal_feature` and
`/CJ_goal_defect` exactly, modulo the `<verb>` (`todo_fix`) in the
resume_cmd.

### Step 5.5: Doc-sync (INLINE — CJ_document-release wrapper around upstream /document-release)

Doc-sync runs INLINE between the QA-green boundary (returned from
`/CJ_personal-pipeline`) and `/ship`, so any doc updates fold into the
SAME per-TODO PR as the TODO fix. There is no post-merge doc-drift window
for orchestrator-driven paths: the doc update ships in the same PR as the
TODO fix.

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

Only on green or green-noop does control proceed to `/ship` Gate #2.

### --quiet mode interaction

The cron-eligible `--quiet` mode (v4.3.0+) suppresses summary banners +
AUQs only; it does NOT suppress the `[doc-sync-red]` or
`[doc-sync-non-doc-write]` halt contracts. Drain mode STOPs the loop on
either marker; the cron operator inspects the halt journal at their
convenience. Silently swallowing doc-sync failures would defeat the
purpose of the halt-on-red contract.
