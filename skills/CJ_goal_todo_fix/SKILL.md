---
name: CJ_goal_todo_fix
description: "Drain TODOs from TODOS.md into shipped PRs. Default mode (no args) drains up to 10 easy-fix TODOs end-to-end via /CJ_personal-pipeline + /ship + /land-and-deploy. Pass a T-ID or fragment for single-TODO mode; --max-drain N caps, --dry-run previews, --quiet for cron / /schedule consumers. /ship Gate #2 still fires per drained PR (autonomy ceiling). Use when: 'fix this TODO', 'clear the TODO backlog', 'auto-resolve TODOs', 'drain TODOs'."
version: 2.2.0
allowed-tools:
  - Bash
  - Read
  - AskUserQuestion
  - Skill
  - Agent
---

## Overview

`/CJ_goal_todo_fix` has two modes:

- **Drain mode (default, no args; v4.2.0+).** Enumerates easy-fix TODOs via
  `/CJ_suggest --for-skill cj-goal`, then drains up to `--max-drain N`
  (default 10) end-to-end. One keystroke; no `/loop` wrapper needed.
- **Single-TODO mode (T-ID or fragment).** Fixes exactly one TODO. The
  battle-tested v1.1 behavior; preserved unchanged.

Per-TODO chain (both modes share this):

```
TODOS.md row → /CJ_goal_todo_fix preflight → T-task scaffold → /CJ_personal-pipeline
   → /ship Gate #2 → /land-and-deploy → TODOS.md DONE-mark → telemetry line
```

Net new logic vs the upstream pipeline: pre-flight gate stack, TODOS.md parser
(handles both `## Active work` and domain-grouped shapes), T-task scaffold
writes (TRACKER + test-plan), direct-dispatch chain, per-session skip-list
mechanic, hash-verify TODOS.md DONE-mark, shared lockfile (cross-skill drain
race protection), and telemetry. Everything else is reuse.

**Input shapes:**
- `/CJ_goal_todo_fix` — no args; drain mode; enumerates via /CJ_suggest and drains up to `--max-drain` (default 10).
- `/CJ_goal_todo_fix --max-drain N` — drain mode; cap at N. `N=0` errors (use `--dry-run` for preview).
- `/CJ_goal_todo_fix T000022` — single-TODO mode (exact T-ID lookup).
- `/CJ_goal_todo_fix "fragment"` — single-TODO mode (fuzzy match against active headings).
- `/CJ_goal_todo_fix --dry-run` — preview without writes. Combines with all input shapes
  (`--dry-run T000022`, `--dry-run --max-drain 3`, etc.).
- `/CJ_goal_todo_fix --quiet` (v4.3.0+) — schedule-friendly mode for cron / `/schedule` consumers.
  Suppresses the Phase 3 summary AUQ + start-of-run banner; writes a
  `[scheduled-drain-summary]` journal entry to `~/.gstack/analytics/CJ_goal_todo_fix-sessions.jsonl`
  instead. Telemetry gains `scheduled_run: true` for retro attribution.
  Composes with `--max-drain N` and single-TODO mode. **Does NOT suppress
  /ship Gate #2** — per F000021 constraint, the autonomy ceiling stays intact:
  drained PRs queue for human review at the operator's cadence. Halt-on-red
  entries are unaffected (still written to tracker journals).

**Cron pattern (v4.3.0+):**

```
/schedule create "/CJ_goal_todo_fix --max-drain 3 --quiet" daily 9am
```

At 9am every day, drains up to 3 easy-fix TODOs into PRs. No interactive
prompts surface in the cron output (operator notifications stay clean).
PRs queue for review; the operator approves them via `gh pr list`
+ /ship Gate #2 at their cadence. **Schedule prepares PRs for review at
your cadence, NOT autonomous merge** — /ship Gate #2 fires per drained
TODO regardless of `--quiet`.

**Drain mode flow (v4.2.0):**

```
Phase 1: Enumerate easy-fix TODOs (delegate to /CJ_suggest --for-skill cj-goal --limit 2*max)
Phase 2: Drain loop (cap = --max-drain)
  For each TODO up to cap:
    drain-one-todo.sh dispatch <heading> <session_id>
      ├── acquire shared lockfile entry (cross-skill race protection)
      ├── delegate to todo_fix.sh single-TODO mode (preflight → scaffold T-task)
      ├── emit CJ_GOAL_HANDOFF_BEGIN/END block
      └── orchestrator drives /CJ_personal-pipeline → /ship → /land-and-deploy
    Halt-on-red → STOP, drained_partial
Phase 3: Summary + telemetry
  "Drained N of M attempted. PRs: [...]. Remaining easy-fix: K."
```

**Shared lockfile** (resilience):

```
/tmp/cj-goal-active-headings-$(date +%Y%m%d).txt   # per-day TTL, self-cleaning
```

Both `/CJ_goal_run` Phase 5 and `/CJ_goal_todo_fix` Phase 2 acquire a
lockfile entry before scaffolding. Loser of a cross-skill race emits
`STATUS=lock_skip` and continues with the next eligible TODO.

**Pre-flight gates (halt the run; under `/loop /CJ_goal_todo_fix` skip-and-continue):**
- Body too vague (< 50 chars)
- Missing `(P[1-4], [SMLX]+)` suffix on heading
- Priority P1 OR size in {L, XL} (run /office-hours instead)
- Sensitive surface AUQ (catalog / manifest / validator / `skills/*/scripts/` / `skills/*/*.md` / git-hook / templates) — v1.2 (S000044) added markdown skill files (SKILL.md, pipeline.md, etc.) since editing them is just as load-bearing as editing scripts
- Design-needed keyword (`needs design` / `investigate` / `spike` / `redesign` / `re-do` / `re-ground` / `rewrite` / `rescope` / `/office-hours` / etc.) — v1.2 (S000044) added the re-design-rework signals after T000031 ("Re-do brief-mode for /CJ_personal-pipeline", body step 1: "/office-hours from a new worktree") slipped past the original `investigate|spike|...` regex
- Idempotency hit (T-tracker already exists for this heading)

**Loop semantics.** `/loop /CJ_goal_todo_fix` continues on `end_state ∈ {green,
idempotent_skip, halted_at_preflight, halted_at_sensitive_surface_auto_declined}`.
The sensitive-surface auto-default joins `halted_at_preflight` in the continue
set because under bash there is no AUQ tool — the gate fires regardless of
whether a human is present, so `/loop` should defer the row (skip-list) and
keep iterating. Substantive halts (`halted_at_pipeline_*`, `halted_at_ship`,
`halted_at_deploy`, `halted_at_sensitive_surface_user_declined` (reserved for
future interactive AUQ; not emitted in v1.1), `halted_at_resolve`,
`halted_at_scaffold`, `halted_at_todos_md`) stop the loop. Per-session
skip-list at `/tmp/cj-goal-skip-${RUN_ID}.txt` prevents re-hitting
already-skipped TODOs within a `/loop` session.

**Practical fit.** Best for 1-5 small TODOs per session, each with a quick
/ship Gate #2 diff review. Not for unattended overnight clearance — /ship's
diff-review fires per TODO that reaches it (upstream gstack constraint).
For scheduled (cron / `/schedule`) drains, pair with `--quiet` (v4.3.0+):
PRs queue silently for the operator's next review window.

**`--quiet` mode (v4.3.0+).** Schedule-friendly: suppresses the Phase 3
summary AUQ + start-of-run banner; emits `scheduled_run: true` in telemetry;
writes `[scheduled-drain-summary]` journal entries to
`~/.gstack/analytics/CJ_goal_todo_fix-sessions.jsonl` instead of surfacing an
interactive prompt. Halt-on-red entries are unaffected (still written to
work-item tracker journals; the loop still STOPS on red). The orchestrator
parses `QUIET=1` from the `CJ_GOAL_DRAIN_HANDOFF` block and suppresses its
own Phase 3 summary AUQ when set. **Critical: `--quiet` does NOT suppress
/ship Gate #2** — drained PRs queue for human review at the operator's
cadence (per F000021 autonomy ceiling). Cron pattern documented in the
workbench `CLAUDE.md` Schedule-friendly drain section.

## Default-worktree (single-TODO mode only — drain mode handled in drain-one-todo.sh)

Per F000025/S000054: when invoked in **single-TODO mode** (a positional T-ID or
fragment is present), auto-create `.claude/worktrees/cj-todo-{YYYYMMDD-HHMMSS}-
{PID}/` on `main` and `cd` into it. **Drain mode** (no positional args or
`--max-drain N`) skips the preamble entirely — `scripts/drain-one-todo.sh`
creates one worktree per drained TODO via `--force-create --quiet`. Conductor-
managed sessions (already inside a worktree) detect + no-op. `--no-worktree`
opts out; `--quiet` gates the `[worktree]` echo.

```bash
# Detect single-TODO mode: at least one positional non-flag arg present.
_HAS_POSITIONAL=0
for _ARG in "$@"; do
  case "$_ARG" in
    --*|-*) ;;
    *) _HAS_POSITIONAL=1; break ;;
  esac
done

if [ "$_HAS_POSITIONAL" = "1" ]; then  # single-TODO mode only
  _S=$(jq -r '.source // empty' "$HOME/.claude/.skills-templates.json" 2>/dev/null)
  if [ -n "$_S" ] && [ -x "$_S/scripts/cj-worktree-init.sh" ]; then
    _WT_JSON=$("$_S/scripts/cj-worktree-init.sh" --caller todo "$@" 2>/dev/null)
    if [ -n "$_WT_JSON" ]; then
      _WT_STATE=$(echo "$_WT_JSON" | jq -r '.state // "failed"' 2>/dev/null)
      _WT_PATH=$(echo "$_WT_JSON" | jq -r '.path // empty' 2>/dev/null)
      _WT_NOTE=$(echo "$_WT_JSON" | jq -r '.note // empty' 2>/dev/null)
      if [ "$_WT_STATE" = "created" ] || [ "$_WT_STATE" = "detected" ]; then
        cd "$_WT_PATH" || { echo "[worktree] ERROR: cd $_WT_PATH failed"; exit 1; }
      elif [ "$_WT_STATE" = "failed" ]; then
        echo "[worktree] ERROR: $_WT_NOTE"
        exit 1
      fi
      # On opted_out / skipped: no cd, no halt; just continue
      [ "${QUIET:-0}" != "1" ] && [ -n "$_WT_NOTE" ] && echo "[worktree] $_WT_NOTE"
    fi
  else
    # Visible warning (NOT silent no-op) — per F000025 Decision Audit Trail #11
    [ "${QUIET:-0}" != "1" ] && echo "[worktree] WARN: helper unreachable; running on current branch"
  fi
fi
```

## Routing

Run the bash script below from the repo root and pass through the user's
positional argument verbatim. The shebang pins execution to bash regardless
of harness shell (per D000017's `/CJ_suggest` lesson: zsh treats `status` /
`pipestatus` / `LINENO` as read-only and chokes on inline bash blocks).

```bash
bash "$HOME/.claude/skills/CJ_goal_todo_fix/scripts/todo_fix.sh" "$@"
```

Resolution rationale: the script always runs from the deployed location at
`~/.claude/skills/CJ_goal_todo_fix/scripts/todo_fix.sh` (`skills-deploy install` puts it
there). The script reads the current repo's `TODOS.md`, `work-items/`, and
writes to the same. Workbench developers iterating on the script must
`./scripts/skills-deploy install` to sync changes (the existing convention)
or invoke `bash skills/CJ_goal_todo_fix/scripts/todo_fix.sh` directly while testing.

## Halt classes / end states

Per-TODO end states (single-TODO mode and inside drain mode's per-iteration):

| Class | Meaning | Loop behavior |
|-------|---------|---------------|
| `green` | Full chain shipped; PR merged; TODOS.md marked DONE | continue |
| `idempotent_skip` | Tracker existed; dispatched chain | continue |
| `halted_at_preflight` | Benign per-TODO halt (suffix / size / body-too-short / design-keyword) | continue (skip-list) |
| `halted_at_resolve` | No actionable TODOs from /CJ_suggest, or T-ID/fragment didn't match | STOP |
| `halted_at_sensitive_surface_auto_declined` | Bash auto-default at sensitive-surface gate (no AUQ tool reachable; honest disposition name). Mirrors `halted_at_preflight` semantics for `/loop` continuity. | continue (skip-list) |
| `halted_at_sensitive_surface_user_declined` | (reserved for future interactive AUQ; not emitted in v1.1) Human at the AUQ explicitly declined the sensitive-surface gate. | STOP |
| `halted_at_scaffold` | /CJ_personal-workflow check refused the scaffolded dir | STOP |
| `halted_at_pipeline_implement` / `halted_at_pipeline_qa` | /CJ_personal-pipeline returned non-green | STOP |
| `halted_at_doc_sync` | Step 5.5 doc-sync: /CJ_document-release returned non-green ([doc-sync-red] — upstream /document-release failed, base-branch refusal, or pre-run non-doc dirty tree) | STOP |
| `halted_at_doc_sync_no_config` | Step 5.5 doc-sync: cj-document-release.json missing/invalid/schema_version-unsupported ([doc-sync-no-config] — F000037 strict-required) | STOP |
| `halted_at_doc_sync_non_doc_write` | Step 5.5 doc-sync: /CJ_document-release refused to auto-commit because upstream wrote files outside the doc-only whitelist ([doc-sync-non-doc-write] — upstream-misbehaved) | STOP |
| `halted_at_ship` | /ship Gate #2 declined or pre-landing review red | STOP |
| `halted_at_deploy` | /land-and-deploy red (CI / merge / canary / regression) | STOP |
| `halted_at_todos_md` | Post-ship hash collision; PR merged but TODOS.md write failed; manual reconcile | STOP |

Drain-mode-specific end states (v4.2.0+):

| Class | Meaning | Exit code |
|-------|---------|-----------|
| `nothing_to_drain` | Phase 1 returned empty (no actionable TODOs OR all candidates skipped). "No work today." Cron-friendly success. | 0 |
| `drain_handoff_pending` | Phase 1 enumerated N headings; orchestrator drives the per-TODO chain. Transitional state — emitted before the Phase 2 loop runs. | 0 |
| `drained_complete` | Phase 2 drained all attempted TODOs green. (Emitted by orchestrator at Phase 3, not by todo_fix.sh directly.) | 0 |
| `drained_partial` | Phase 2 halt-on-red or cap-reached with remaining work. | 0 |

`nothing_to_drain` exits 0 so `cron` / `/schedule` jobs don't alert on empty
backlogs. Distinguish via the telemetry `end_state` field.

## Telemetry

**Primary write target.** Each invocation appends one JSONL line to
`~/.gstack/analytics/CJ_goal_todo_fix.jsonl`:

```json
{"ts":"...","todo_heading":"...","t_id":"T000NNN","end_state":"green",
 "pr_url":"https://...","duration_s":123,"parent_skill":"CJ_goal_todo_fix",
 "scheduled_run":false}
```

The `scheduled_run` field (v4.3.0+) is `true` when invoked with `--quiet`,
`false` otherwise. Distinguishes cron-driven drain from operator-driven
drain for retro tooling — `jq 'select(.scheduled_run == true)'` filters
to scheduled runs.

**Session log (v4.3.0+).** When `--quiet` is set, `[scheduled-drain-summary]`
entries are also appended to `~/.gstack/analytics/CJ_goal_todo_fix-sessions.jsonl`:

```json
{"ts":"...","run_id":"...","marker":"scheduled-drain-summary",
 "summary":"nothing_to_drain — /CJ_suggest returned no actionable items"}
```

This is the post-cron-readable replacement for the suppressed Phase 3
summary AUQ.

**Fallback read (v4.2.0+).** Sunset-trip-wire consumers MUST also read
`~/.gstack/analytics/CJ_goal.jsonl` (the pre-rename path) so historical
invocations across the v4.0.0 rename window are not lost. The
`telemetry_invocation_count` helper in `scripts/todo_fix.sh` performs the
merged read; current-run writes go only to the new path.

Used for v1.1 sunset trip-wire calibration (deferred until 8+ real invocations
exist; threshold TBD).

## Notes

- **Shared drain helper (v4.2.0+).** `scripts/drain-one-todo.sh` is the
  per-TODO inner loop, called by BOTH `/CJ_goal_todo_fix` Phase 2 (drain
  mode) AND `/CJ_goal_run` Phase 5 (post-deploy TODO drain). One source of
  truth for: shared lockfile acquire/release, todo_fix.sh delegation, and
  the CJ_GOAL_HANDOFF block contract that lets the orchestrator drive
  `/CJ_personal-pipeline` + `/ship` + `/land-and-deploy` via the Skill tool.
- **Script-extracted (D000017 pattern).** All load-bearing logic lives in
  `scripts/todo_fix.sh` with a `#!/usr/bin/env bash` shebang. Inline bash blocks
  inside SKILL.md routing crash under zsh (`status=` is read-only).
- **/CJ_goal_run bypass.** /CJ_goal_run Branch(f) explicitly rejects `type: task`
  (run.md:214). /CJ_goal_todo_fix follows that guidance and chains /CJ_personal-pipeline
  + /ship + /land-and-deploy directly.
- **Workbench is the source-of-truth, but the skill is portable.** v1 was
  developed and tested in the `claude-skills-templates` workbench — `TODOS.md`
  source convention lives here and gets curated here. The skill itself works
  in any repo with a `TODOS.md` and a `work-items/` tree: the post-scaffold
  workbench-coupled `validate.sh` check was removed from `scripts/todo_fix.sh`
  (T000028 / Approach D), and `/CJ_personal-pipeline` Step 6 silently skips
  `validate.sh` when the file is absent or non-executable. Downstream
  `/loop /CJ_goal_todo_fix` drains are supported as of T000028.
- **ID-picker source-of-truth.** v1 copy-pastes /CJ_scaffold-work-item Step 5's
  two-source picker block into `scripts/todo_fix.sh`. v1.1 will extract to
  `scripts/cj-id-picker.sh` (Open Q #1 in source design).
