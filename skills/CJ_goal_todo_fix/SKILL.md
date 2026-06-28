---
name: CJ_goal_todo_fix
description: "Drain TODOs from TODOS.md into shipped PRs. Default mode (no args) drains up to 10 easy-fix TODOs end-to-end via /CJ_implement-from-spec + /CJ_qa-work-item (DEFER_AUDIT: true) + a pre-doc-sync commit + /CJ_document-release + a post-sync doc/test audit + the QA-audit checkpoint + /ship + /land-and-deploy. The post-QA checkpoint surfaces the POST-sync doc/test audit digest (ONE combined read-only subagent run AFTER doc-sync) per drained TODO: interactive runs AUQ ALWAYS (Continue past findings journals [qa-audit-waived]; Halt journals [qa-audit-declined] / halted_at_qa_audit); --quiet auto-continues on doc:ok,test:ok and halts on any findings. Pass a T-ID or fragment for single-TODO mode; --max-drain N caps, --dry-run previews, --quiet for cron / /schedule consumers. /ship Gate #2 still fires per drained PR (autonomy ceiling). Use when: 'fix this TODO', 'clear the TODO backlog', 'auto-resolve TODOs', 'drain TODOs'."
version: 2.2.0
allowed-tools:
  - Bash
  - Read
  - AskUserQuestion
  - Skill
  - Agent
---

## Preamble

Check for collection updates (silent if none, banner if newer):

```bash
_UC="${CJ_SHARED_SCRIPTS:-$HOME/.claude/_cj-shared/scripts}/skills-update-check"
[ -x "$_UC" ] && "$_UC" 2>/dev/null || true
```

## Pre-build skills-sync (F000045 / Fork 2 — BEFORE the Default-worktree block)

Before any worktree is created (single-TODO mode) or drain begins, sync installed
skills to trunk so the drain runs against current skills (not a stale
`~/.claude/`). Delegated to the shared `scripts/cj-goal-common.sh --phase sync`
(reuses `post-land-sync.sh`'s guarded pull+install-from-`.source` core; `--mode`
is a benign required arg — the sync phase is mode-agnostic). **Fail-soft — never
halts the drain:** a guard refusal (`.source` off-main / dirty) or an offline
pull emits `PHASE_RESULT=skipped` and the drain proceeds on the current install.
`--no-sync` opts out of the heavy install (Fork-1's ff in the worktree phase
still runs for single-TODO mode); `--dry-run` forwards as a preview. Runs for
BOTH drain and single-TODO modes (skills-freshness is mode-independent).

```bash
# Pre-build skills-sync (F000045) — runs BEFORE the Default-worktree block.
_SHARED="${CJ_SHARED_SCRIPTS:-$HOME/.claude/_cj-shared/scripts}"
_COMMON=""
_REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo "")
# 2-tier shared-script resolution (F000049/S000088: .source tier dropped):
# repo-local (workbench self-dev) → deployed _cj-shared home (install==clone).
if [ -n "$_REPO_ROOT" ] && [ -x "$_REPO_ROOT/scripts/cj-goal-common.sh" ]; then
  _COMMON="$_REPO_ROOT/scripts/cj-goal-common.sh"
elif [ -x "$_SHARED/cj-goal-common.sh" ]; then
  _COMMON="$_SHARED/cj-goal-common.sh"
fi
if [ -n "$_COMMON" ]; then
  _SYNC_FLAGS=()
  for _ARG in "$@"; do
    case "$_ARG" in
      --no-sync) _SYNC_FLAGS+=(--no-sync) ;;
      --dry-run) _SYNC_FLAGS+=(--dry-run) ;;
    esac
  done
  # Fail-soft: the phase exits 0 on skip; we never halt on its result.
  # --mode feature is a benign required arg (the sync phase is mode-agnostic).
  _SYNC_OUT=$(bash "$_COMMON" --phase sync --mode feature "${_SYNC_FLAGS[@]}" 2>/dev/null || true)
  _SYNC_RESULT=$(printf '%s\n' "$_SYNC_OUT" | sed -n 's/^PHASE_RESULT=//p')
  _SYNC_VB=$(printf '%s\n' "$_SYNC_OUT" | sed -n 's/^VERSION_BEFORE=//p')
  _SYNC_VA=$(printf '%s\n' "$_SYNC_OUT" | sed -n 's/^VERSION_AFTER=//p')
  if [ "${QUIET:-0}" != "1" ]; then
    if [ "$_SYNC_RESULT" = "ok" ]; then
      echo "[sync] skills synced from the in-place checkout (collection_version ${_SYNC_VB:-?} → ${_SYNC_VA:-?})"
    else
      echo "[sync] skipped (--no-sync / guard refusal / offline) — proceeding on current install"
    fi
  fi
fi
```

## Overview

`/CJ_goal_todo_fix` has two modes:

- **Drain mode (default, no args; v4.2.0+).** Enumerates easy-fix TODOs via
  `/CJ_suggest --for-skill cj-goal`, then drains up to `--max-drain N`
  (default 10) end-to-end. One keystroke; no `/loop` wrapper needed.
- **Single-TODO mode (T-ID or fragment).** Fixes exactly one TODO. The
  battle-tested v1.1 behavior; preserved unchanged.

Per-TODO chain (both modes share this):

```
TODOS.md row → /CJ_goal_todo_fix preflight → T-task scaffold
   → /CJ_implement-from-spec → /CJ_qa-work-item [DEFER_AUDIT: true — audit deferred to post-sync] (leaf Agent subagents, halt-on-red between)
   → pre-doc-sync commit (Step 5.4 — NEW; idempotent: commit QA-green fix + 8.6a/8.6b overlays, skip on clean tree)
   → /CJ_document-release (Step 5.5 doc-sync)
   → post-sync audit (Step 5.5b — NEW; ONE combined READ-ONLY subagent: /CJ_doc_audit + /CJ_test_audit over the post-sync tree)
   → QA-audit checkpoint (interactive: AUQ ALWAYS on the POST-sync report; --quiet: auto-continue on doc:ok,test:ok, halt [qa-audit-declined] on findings)
   → portability gate (Step 5.7 — cj-goal-common.sh --phase portability-audit; halt-on-red BEFORE /ship)
   → /ship Gate #2
   → Step 5.6: surface registered-doc + portability verdicts → PR body (post-/ship gh pr edit "$PR_URL"; best-effort)
   → /land-and-deploy → TODOS.md DONE-mark
   → worktree cleanup (best-effort; cj-worktree-cleanup.sh --caller todo) → telemetry line
```

Worktree cleanup is best-effort, post-land, and **never halts the run** — todo
calls `cj-worktree-cleanup.sh --caller todo` directly (it does NOT route through
`cj-goal-common.sh`, same as its create step). Single-TODO mode wires it at the
agent-layer terminal (after `/land-and-deploy` + DONE-mark, see Routing below);
drain mode wires it at `drain-one-todo.sh`'s per-iteration terminal. The
just-shipped TODO's own `cj-todo-*` worktree (PR now MERGED) is swept along with
other landed cj-* worktrees; the root checkout is refreshed.

The T-task scaffold runs in pure bash (`todo_fix.sh:608-693` — ID picker +
`tracker-task.md` template), so the dispatched chain is exactly
`/CJ_implement-from-spec` → `/CJ_qa-work-item` (the `/CJ_goal_feature` Steps
3.2-3.3 pattern, minus the scaffold step). Both run as depth-≤2 leaf Agent
subagents (silent / no-AUQ); a non-green RESULT from either HALTs the chain
(`halted_at_impl` / `halted_at_qa`). QA is dispatched with `DEFER_AUDIT: true`, so
it defers the three-stage audit; the orchestrator then runs the pre-doc-sync
commit (pipeline.md Step 5.4), doc-sync (Step 5.5), and the post-sync audit
(Step 5.5b) BEFORE running the **QA-audit checkpoint** (below) on that POST-sync
report.

## QA-audit findings checkpoint (per drained TODO — AFTER Step 5.5 doc-sync + the Step 5.5b post-sync audit)

Identical contract to `/CJ_goal_feature` Step 3.4 (canonical gate row:
`qa-audit`, order 45, in `spec/test-spec-custom.md`). The checkpoint consumes the
**post-sync** audit (pipeline.md Step 5.5b), NOT a pre-sync QA RESULT field: that
combined read-only subagent emits
`AUDITS=doc:<ok|findings:n>,test:<ok|findings:n>` plus the fenced `AUDIT_FINDINGS`
block (`/CJ_doc_audit` + `/CJ_test_audit` over the post-doc-sync tree). The two
spec-overlay updates rode the QA RESULT inline at qa.md 8.6a/8.6b (they shipped in
the pre-doc-sync commit).

- **Interactive runs (no `--quiet`):** surface an AskUserQuestion **ALWAYS**
  — findings or not — showing the post-sync `AUDITS=` digest + the `AUDIT_FINDINGS`
  block, options **Continue** (→ portability gate + /ship; if findings>0 append
  `- $TS [qa-audit-waived] operator continued past audit findings at the
  post-QA (post-sync) checkpoint: AUDITS=...` to the T-task tracker journal, then
  commit that tracker line so the tree stays clean) / **Halt**
  (append `- $TS [qa-audit-declined] operator halted at the post-QA (post-sync)
  audit checkpoint.` + the family fields `next_action=` / `resume_cmd=` /
  `pr_url=N/A` / `raw_output_path=`; telemetry `end_state=halted_at_qa_audit`;
  STOP the chain).
- **`--quiet` runs (cron / `/schedule`):** NO AUQ. Auto-continue when the
  digest is fully green (`doc:ok` AND `test:ok`); on ANY findings, halt with
  `[qa-audit-declined]` + `end_state=halted_at_qa_audit` (no waiver is ever
  auto-written — a waiver requires a human).

The checkpoint is a pure read of the post-sync audit (no phase boundary recorded);
a resume re-runs QA → pre-doc-sync commit (idempotent) → doc-sync → the post-sync
audit, and the checkpoint re-fires on the fresh post-sync digest.

Net new logic vs the upstream phase skills: pre-flight gate stack, TODOS.md
parser (handles both `## Active work` and domain-grouped shapes), T-task
scaffold writes (TRACKER + test-plan), the impl→qa direct-dispatch chain,
per-session skip-list mechanic, hash-verify TODOS.md DONE-mark, shared lockfile
(cross-skill drain race protection), and telemetry. Everything else is reuse.

**Input shapes:**
- `/CJ_goal_todo_fix` — no args; drain mode; enumerates via /CJ_suggest and drains up to `--max-drain` (default 10).
- `/CJ_goal_todo_fix --max-drain N` — drain mode; cap at N. `N=0` errors (use `--dry-run` for preview).
- `/CJ_goal_todo_fix T000022` — single-TODO mode (exact T-ID lookup).
- `/CJ_goal_todo_fix "fragment"` — single-TODO mode (fuzzy match against active headings).
- `/CJ_goal_todo_fix --dry-run` — preview without writes. Combines with all input shapes
  (`--dry-run T000022`, `--dry-run --max-drain 3`, etc.).
- `/CJ_goal_todo_fix --no-sync` — skip the pre-build skills-sync (F000045 / Fork 2).
  The `Pre-build skills-sync` preamble's heavy `skills-deploy install` is skipped
  (`PHASE_RESULT=skipped`) for a faster start; Fork-1's local-main fast-forward in
  the worktree phase (single-TODO mode) still runs. Combines with all input shapes.
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
      └── orchestrator dispatches /CJ_implement-from-spec → /CJ_qa-work-item [DEFER_AUDIT: true] (leaf subagents, halt-on-red) → pre-doc-sync commit (Step 5.4) → /CJ_document-release (Step 5.5) → post-sync audit (Step 5.5b; ONE combined read-only subagent) → QA-audit checkpoint on the POST-sync report (AUQ / --quiet auto-decide) → portability gate (Step 5.7; halt-on-red) → /ship → /land-and-deploy
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
- Design-needed keyword (`needs design` / `investigate` / `spike` / `redesign` / `re-do` / `re-ground` / `rewrite` / `rescope` / `/office-hours` / etc.) — v1.2 (S000044) added the re-design-rework signals after a "Re-do brief-mode" TODO (T000031; body step 1: "/office-hours from a new worktree") slipped past the original `investigate|spike|...` regex
- Idempotency hit (T-tracker already exists for this heading)

**Loop semantics.** `/loop /CJ_goal_todo_fix` continues on `end_state ∈ {green,
idempotent_skip, halted_at_preflight, halted_at_sensitive_surface_auto_declined}`.
The sensitive-surface auto-default joins `halted_at_preflight` in the continue
set because under bash there is no AUQ tool — the gate fires regardless of
whether a human is present, so `/loop` should defer the row (skip-list) and
keep iterating. Substantive halts (`halted_at_impl`, `halted_at_qa`,
`halted_at_qa_audit`, `halted_at_portability`,
`halted_at_ship`, `halted_at_deploy`, `halted_at_sensitive_surface_user_declined`
(reserved for future interactive AUQ; not emitted in v1.1), `halted_at_resolve`,
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

## Step 5.7: Portability gate (per drained TODO — halt-on-red before /ship; F000051)

After the Step 5.5b post-sync audit + the QA-audit checkpoint (which followed
Step 5.5 doc-sync) and before `/ship`, the orchestrator runs a
shared portability gate for EACH drained TODO (single-TODO AND drain mode — the
gate is orchestrator-layer; `scripts/drain-one-todo.sh` is NOT modified). It
calls `cj-goal-common.sh --phase portability-audit --mode feature` (the same
`--mode feature` value todo already passes for `--phase sync` — the audit is
verb-independent and there is no `todo` mode). The phase runs the
`cj-portability-audit.sh` engine under `PORTABILITY_STRICT=1` and classifies the
result into `ok` / `findings` / `skipped`. The gate is a **pure read** (records
no state; re-running on a resume is safe).

```bash
# Per-TODO portability gate — orchestrator runs this after /CJ_document-release
# (Step 5.5) and before /ship, for the current TODO's tracker ($TRACKER).
_SHARED="${CJ_SHARED_SCRIPTS:-$HOME/.claude/_cj-shared/scripts}"
_RR=$(git rev-parse --show-toplevel 2>/dev/null || echo "")
_COMMON=""
# 2-tier shared-script resolution (F000049/S000088: .source tier dropped): repo-local → _cj-shared
if [ -n "$_RR" ] && [ -x "$_RR/scripts/cj-goal-common.sh" ]; then _COMMON="$_RR/scripts/cj-goal-common.sh";
elif [ -x "$_SHARED/cj-goal-common.sh" ]; then _COMMON="$_SHARED/cj-goal-common.sh"; fi

_PORT_RESULT="skipped"; _PORT_VERDICT=""
if [ -n "$_COMMON" ]; then
  _PORT_OUT=$(bash "$_COMMON" --phase portability-audit --mode feature 2>/dev/null) && _PORT_RC=0 || _PORT_RC=$?
  _PORT_RESULT=$(printf '%s\n' "$_PORT_OUT" | sed -n 's/^PHASE_RESULT=//p' | head -1)
  _PORT_VERDICT=$(printf '%s\n' "$_PORT_OUT" | sed -n 's/^VERDICT_LINE=//p' | head -1)
  [ -z "$_PORT_RESULT" ] && _PORT_RESULT="skipped"
else
  [ "${QUIET:-0}" != "1" ] && echo "[portability] cj-goal-common.sh unreachable — skipping the portability gate (best-effort)"
fi
```

- On `PHASE_RESULT=ok`: write `VERDICT_LINE` to `.cj-goal-feature/portability-verdict.md`
  (the LITERAL path — only `.cj-goal-feature/` is gitignored, NOT verb-renamed)
  and continue to `/ship`:

```bash
if [ "$_PORT_RESULT" = "ok" ]; then
  mkdir -p "$_RR/.cj-goal-feature" 2>/dev/null || true
  printf '### Portability\n\n%s\n' "$_PORT_VERDICT" > "$_RR/.cj-goal-feature/portability-verdict.md"
  [ "${QUIET:-0}" != "1" ] && echo "[portability] $_PORT_VERDICT — continuing to /ship"
fi
```

- On `PHASE_RESULT=skipped` (engine absent / helper unreachable): echo a note
  (gated by `--quiet`) and continue to `/ship` — no halt, no scratch write.

- On `PHASE_RESULT=findings`: **HALT** the per-TODO chain with `[portability-red]`
  (end_state `halted_at_portability`). A touched skill declares a portability
  tier it does not honor; no PR is created (the gate halts BEFORE `/ship`). Write
  a tracker journal entry + telemetry line; under `/loop` this is a **substantive
  halt that STOPS the loop** (a dishonest declaration is real work, not a benign
  skip):

```bash
if [ "$_PORT_RESULT" = "findings" ]; then
  TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  cat >> "$TRACKER" <<EOF

- $TS [portability-red] cj-goal-common.sh --phase portability-audit returned PHASE_RESULT=findings; halt class halted_at_portability. $_PORT_VERDICT
  next_action=A touched skill declares a portability tier it does not honor. Relabel its 'portability' in skills-catalog.json to the tier its deps need, OR add the accepted dep to its 'portability_requires'. Then re-run.
  resume_cmd=/CJ_goal_todo_fix "$TODO_HEADING"
  pr_url=N/A
  raw_output_path=N/A
EOF
  [ "${QUIET:-0}" != "1" ] && echo "Why it stopped: the portability audit found a skill that declares a portability tier it does not honor; the gate blocks the PR until it is reconciled."
  jq -nc --arg ts "$TS" --arg heading "$TODO_HEADING" --arg end_state "halted_at_portability" \
    '{ts:$ts,todo_heading:$heading,end_state:$end_state,pr_url:"N/A",parent_skill:"CJ_goal_todo_fix"}' \
    >> "$HOME/.gstack/analytics/CJ_goal_todo_fix.jsonl" 2>/dev/null || true
  # Single-TODO: stop here. Drain mode: this is a halt-on-red → STOP the drain (drained_partial).
  exit 1
fi
```

Only on `ok` or `skipped` does the chain proceed to `/ship`. The green
`### Portability` verdict is surfaced into the PR body by the Step 5.6 step
(below) alongside the registered-doc verdicts.

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
  _SHARED="${CJ_SHARED_SCRIPTS:-$HOME/.claude/_cj-shared/scripts}"
  _RR=$(git rev-parse --show-toplevel 2>/dev/null || echo "")
  # 2-tier shared-script resolution (F000049/S000088: .source tier dropped): repo-local → _cj-shared
  _WT_INIT=""
  if [ -n "$_RR" ] && [ -x "$_RR/scripts/cj-worktree-init.sh" ]; then _WT_INIT="$_RR/scripts/cj-worktree-init.sh";
  elif [ -x "$_SHARED/cj-worktree-init.sh" ]; then _WT_INIT="$_SHARED/cj-worktree-init.sh"; fi
  if [ -n "$_WT_INIT" ]; then
    _WT_JSON=$("$_WT_INIT" --caller todo "$@" 2>/dev/null)
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

### Agent-layer terminal: worktree cleanup (best-effort, post-land; NEVER halts)

After the orchestrator consumes the `CJ_GOAL_HANDOFF` block and drives the chain
to completion — `/CJ_implement-from-spec` → `/CJ_qa-work-item` → `/CJ_document-release`
→ **portability gate (Step 5.7; halt-on-red BEFORE `/ship`)** → `/ship` →
**(Step 5.6: surface registered-doc + portability verdicts into the PR
body via `gh pr edit "$PR_URL"`, best-effort, NEVER halts — runs right after
`/ship` opens the PR and before `/land-and-deploy` merges it; reads both
`.cj-goal-feature/registered-doc-verdicts.md` and `.cj-goal-feature/portability-verdict.md`,
splicing `### Registered-doc requirements` + `### Portability` under the PR body's
`## Documentation` section — the same splice the feature/defect pipeline.md Step
4.6/9.5 use)** → `/land-and-deploy`
→ the `TODOS.md` DONE-mark — it runs the post-run
worktree janitor (T000036). This is the teardown mirror of the single-TODO
worktree-create preamble above. **todo does NOT route through `cj-goal-common.sh`**
(it already calls `cj-worktree-init.sh` directly at create time), so it calls
`cj-worktree-cleanup.sh --caller todo` **directly** — same convention as its
create step. Resolve the helper via the manifest `.source` (the same probe the
single-TODO worktree preamble uses), then:

```bash
# Agent-layer terminal — AFTER /land-and-deploy + TODOS.md DONE-mark, NOT inside
# todo_fix.sh (which only emits a handoff + exits 0 before land happens).
_SHARED="${CJ_SHARED_SCRIPTS:-$HOME/.claude/_cj-shared/scripts}"
_RR=$(git rev-parse --show-toplevel 2>/dev/null || echo "")
_CLEAN=""
# 2-tier shared-script resolution (F000049/S000088: .source tier dropped): repo-local → _cj-shared
if [ -n "$_RR" ] && [ -x "$_RR/scripts/cj-worktree-cleanup.sh" ]; then
  _CLEAN="$_RR/scripts/cj-worktree-cleanup.sh"
elif [ -x "$_SHARED/cj-worktree-cleanup.sh" ]; then
  _CLEAN="$_SHARED/cj-worktree-cleanup.sh"
fi
[ -n "$_CLEAN" ] && bash "$_CLEAN" --caller todo 2>/dev/null || true
```

The just-shipped TODO's own `cj-todo-*` worktree is swept too (its PR is MERGED),
along with any other MERGED/CLOSED cj-* worktrees; the root checkout is refreshed.
Cleanup is strictly best-effort: a failed sweep is ignored and the run still
reports `green`. It runs only AFTER the PR is safely landed, so it can never
endanger shipped work. This is the single-TODO-mode seam; drain mode wires the
same `cj-worktree-cleanup.sh --caller todo` call at `drain-one-todo.sh`'s
per-iteration terminal instead.

### Agent-layer terminal: AFTER-land recap (3-part; advisory — F000068)

`todo_fix` is a landing verb, so it completes the before+after recap pair: the
BEFORE block ran in `pipeline.md` Step 5.6 (right after `/ship`, before
`/land-and-deploy`); the AFTER block runs HERE — after `/land-and-deploy` merged +
deployed and the `TODOS.md` DONE-mark landed, **per drained TODO** (once per
shipped PR; in drain mode `drain-one-todo.sh`'s per-iteration terminal is the same
seam). YOU (the agent) author the three fields for THIS TODO's change; the shared
helper only formats. Render the AFTER ("Landed") block:

```bash
_COMMON="${_RR:-$(git rev-parse --show-toplevel 2>/dev/null)}/scripts/cj-goal-common.sh"
if [ -x "$_COMMON" ]; then
  bash "$_COMMON" --phase recap --mode feature --when after \
    --field delivered="<this TODO's change in plain terms + the version it bumped to + the TODOS row closed + PR $PR_URL + the squash-merge SHA>" \
    --field e2e="<the concrete end-to-end commands/checks that prove it is LIVE — e.g. scripts/test.sh against origin/main, a specific scripts/*.sh invocation, or git show origin/main:<file>>" \
    --field next="<the concrete next action — typically: confirm the deploy, then drain the next TODO (or nothing if this was the last)>"
fi
```

(`--mode feature` matches this pipeline's other `cj-goal-common.sh` calls — the
block shape is verb-neutral.) **Prose fallback (helper absent):** emit the same
3-part block as prose under a `=== Landed / PR opened ===` header (do NOT halt —
the recap is advisory; a missing field renders an empty section). No `validate.sh`
check asserts the recap fired.

## Halt classes / end states

Canonical gate sequence: `spec/test-spec.md` (the cross-cj_goal verification contract;
enforced by `validate.sh` Check 24). The classes below are this mode's subset of
that declared sequence — the registry is the source of truth for the ordering.
(todo runs inside the drain worktree, so it has no isolation gate; its QA + ship
gates are `enforced_by` a subagent / AUQ rather than a bracket marker.)

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
| `halted_at_impl` | /CJ_implement-from-spec leaf subagent returned non-green | STOP |
| `halted_at_qa` | /CJ_qa-work-item leaf subagent returned non-green | STOP |
| `halted_at_qa_audit` | QA-audit checkpoint declined ([qa-audit-declined] — interactive Halt, or `--quiet` auto-halt on any doc/test audit findings; Continue past findings journals [qa-audit-waived]) | STOP |
| `halted_at_doc_sync` | Step 5.5 doc-sync: /CJ_document-release returned non-green ([doc-sync-red] — upstream /document-release failed, base-branch refusal, or pre-run non-doc dirty tree) | STOP |
| `halted_at_doc_sync_no_config` | Step 5.5 doc-sync: doc-spec.md registry missing the yaml block / invalid / schema_version-unsupported / entry out-of-enum ([doc-sync-no-config]; a simply-absent doc-spec.md self-bootstraps, not halts) | STOP |
| `halted_at_doc_sync_non_doc_write` | Step 5.5 doc-sync: /CJ_document-release refused to auto-commit because upstream wrote files outside the doc-only whitelist ([doc-sync-non-doc-write] — upstream-misbehaved) | STOP |
| `halted_at_portability` | Step 5.7 portability gate: `cj-goal-common.sh --phase portability-audit` returned `PHASE_RESULT=findings` ([portability-red] — a touched skill declares a portability tier it does not honor; halt BEFORE /ship, no PR). `skipped`/engine-absent never halts. | STOP |
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

**Sunset trip-wire.** The `telemetry_invocation_count` helper in
`scripts/todo_fix.sh` counts invocation lines in the primary file for v1.1
sunset trip-wire calibration (deferred until 8+ real invocations exist;
threshold TBD).

## Notes

- **Shared drain helper (v4.2.0+).** `scripts/drain-one-todo.sh` is the
  per-TODO inner loop, called by BOTH `/CJ_goal_todo_fix` Phase 2 (drain
  mode) AND `/CJ_goal_run` Phase 5 (post-deploy TODO drain). One source of
  truth for: shared lockfile acquire/release, todo_fix.sh delegation, and
  the CJ_GOAL_HANDOFF block contract that lets the orchestrator dispatch
  `/CJ_implement-from-spec` → `/CJ_qa-work-item` (leaf subagents) + `/ship` +
  `/land-and-deploy` via the Agent/Skill tools.
- **Script-extracted (D000017 pattern).** All load-bearing logic lives in
  `scripts/todo_fix.sh` with a `#!/usr/bin/env bash` shebang. Inline bash blocks
  inside SKILL.md routing crash under zsh (`status=` is read-only).
- **Task-type chain.** /CJ_goal_todo_fix scaffolds a `type: task` T-task and
  dispatches /CJ_implement-from-spec → /CJ_qa-work-item (leaf subagents) +
  /ship + /land-and-deploy directly — the same depth-≤2 flatten as
  /CJ_goal_feature Steps 3.2-3.3, minus the scaffold step (todo_fix scaffolds
  in bash).
- **Workbench is the source-of-truth, but the skill is portable.** v1 was
  developed and tested in the `claude-skills-templates` workbench — `TODOS.md`
  source convention lives here and gets curated here. The skill itself works
  in any repo with a `TODOS.md` and a `work-items/` tree: the post-scaffold
  workbench-coupled `validate.sh` check was removed from `scripts/todo_fix.sh`
  (T000028 / Approach D); the dispatched leaf phase skills
  (`/CJ_implement-from-spec`, `/CJ_qa-work-item`) run only the portable
  `/CJ_personal-workflow check` at their boundaries, so they degrade gracefully
  in repos without `scripts/validate.sh`. Downstream `/loop /CJ_goal_todo_fix`
  drains are supported as of T000028.
- **ID-picker source-of-truth.** v1 copy-pastes /CJ_scaffold-work-item Step 5's
  two-source picker block into `scripts/todo_fix.sh`. v1.1 will extract to
  `scripts/cj-id-picker.sh` (Open Q #1 in source design).
## Permission policy

This orchestrator's permissions are declared in one artifact: `permission-policy.md`
(parsed by `scripts/permission-policy.sh`). The two live enforcement points are
governed by it — the `allowed-tools` frontmatter above is the **allow** surface,
and the sensitive-surface AskUserQuestion (catalog / manifest / validator / skill
/ template / git-hook edits) is the **ask** surface. The riskiest operations
(direct push to `main`, autonomous `gh pr merge`, `rm`, network egress) are
**deny**; an unenumerated verb resolves to `deny` (fail closed). The dormant
`cj-handoff-gate.sh` denylist derives from the policy's `ask` globs, and
`scripts/validate.sh` Check 21 flags policy↔enforcement drift (advisory).
