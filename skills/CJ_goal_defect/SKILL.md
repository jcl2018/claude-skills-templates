---
name: CJ_goal_defect
description: "Bug-description-to-shipped-fix orchestrator (F000027 `defect` verb; experimental). Takes a plain bug description with NO pre-existing defect dir, scaffolds a throwaway `.inbox/<slug>/DRAFT.md`, root-causes it via /investigate as an Agent subagent (sentinel-wrapped JSON, Iron-Law: no root cause ⇒ HALT, nothing promoted or shipped), then on a populated root cause writes RCA + test-plan, promotes the draft to a canonical `work-items/defects/uncategorized/D000NNN_<slug>/` dir (D-ID minted only after the Iron-Law gate passes), runs /CJ_qa-work-item (leaf subagent), and ships on the proven human-gated tail: /ship (Gate #2 always human) → /land-and-deploy --suppress-readiness-gate. A ~80% reshape of /CJ_goal_investigate v1.1's flat pipeline; depth ≤ 2 (no subagent-spawns-subagent). Consumes scripts/cj-goal-common.sh --mode defect for the deterministic worktree + pr-check phases. Inherits investigate v1.1's halt taxonomy with next_action= / resume_cmd= / pr_url= journal entries; telemetry appends one JSONL line to ~/.gstack/analytics/CJ_goal_defect.jsonl. --dry-run previews the chain plan + write paths without mutation. Workbench-only (macOS). Drain mode / family-drain lock / --quiet / sunset criterion all deferred. Use when: 'fix this bug end-to-end from a description', 'bug report to deployed fix', 'root-cause and ship a fix'."
version: 0.1.0
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Agent
  - AskUserQuestion
  - Skill
---

## Preamble

Check for collection updates (silent if none, banner if newer):

```bash
_S=$(jq -r '.source // empty' "$HOME/.claude/.skills-templates.json" 2>/dev/null)
[ -n "$_S" ] && [ -x "$_S/scripts/skills-update-check" ] && "$_S/scripts/skills-update-check" 2>/dev/null || true
```

Doc-sync pending check (F000028 follow-up — silent if no marker, prints `DOC_SYNC_PENDING <path>` if F000028's hook dropped a marker since last pull):

```bash
_DSC=$(jq -r '.source // empty' "$HOME/.claude/.skills-templates.json" 2>/dev/null)
_DSC_OUT=$([ -n "$_DSC" ] && [ -x "$_DSC/scripts/skills-doc-sync-check" ] && "$_DSC/scripts/skills-doc-sync-check" 2>/dev/null || true)
[ -n "$_DSC_OUT" ] && echo "$_DSC_OUT"
```

**If the preamble's `skills-doc-sync-check` output contains `DOC_SYNC_PENDING <marker-path>`:**

1. Read the marker: `jq -r '.head_sha, .main_moved_at, .changed_files' <marker-path>` to extract head_sha, main_moved_at, and changed_files for the AUQ display.
2. Detect current branch: `_BRANCH=$(git symbolic-ref --short HEAD 2>/dev/null)`.
3. Surface this AUQ verbatim (substitute the captured fields). On **main**, "A" is recommended; on a feature branch / worktree, "B" is recommended (A would run `/document-release` on the non-main branch which produces wrong doc state):

```
D? — Doc-sync pending for repo <slug> (main moved <main_moved_at>; <changed_files> files since).
ELI10: F000028's hook noticed main moved and dropped a marker. /document-release reads
the merged diff and updates README/ARCHITECTURE/CLAUDE.md. On main, running it now folds
doc updates into your next commit. On a feature branch, defer (it'd run on the wrong state).
Stakes if wrong: skip means doc drift continues; A on a feature branch pollutes the branch.
A) Run /document-release now (recommended on main; NOT recommended on feature branch)
B) Snooze 1h — bash "<script-path>" --snooze 1   (silences for 1 hour)
C) Snooze 24h — bash "<script-path>" --snooze 24
D) Skip this marker forever — bash "<script-path>" --skip <head_sha>
```

**On A (and on main):**
1. Invoke `/document-release` via the Skill tool (no args). It runs at the current cwd (root, on main).
2. On Skill green: `git status -s` — if uncommitted doc-only changes present (README/CHANGELOG/ARCHITECTURE/CLAUDE.md/CONTRIBUTING.md), auto-commit them:
   `git add <touched-doc-files> && git commit -m "docs: post-merge sync for <slug> (auto via doc-sync-check)"`
   This is REQUIRED to prevent the next-step Step 1.9 isolation gate from HALTing on a dirty checkout (reviewer-flagged P0 collision).
3. `bash "<script-path>" --resolved` (deletes marker + clears snooze/skip cache).
4. Continue with the cj_goal pipeline (worktree creation, etc.).

**On A (when on a feature branch / non-main worktree):** print a warning ("/document-release on a non-main branch would produce wrong doc state; recommend Snooze 1h instead"), then fall back to AUQ option B (snooze 1h). Do NOT invoke `/document-release` here.

**On B / C / D:** the script subcommand updates cache state; continue with the cj_goal pipeline.

**If `/document-release` returns non-green / errors mid-write:** do NOT auto-commit (the docs are half-updated). Print error, leave the marker in place (operator will retry next session), apply `--snooze 1h` so this shell isn't nagged, then continue with the cj_goal pipeline. Operator can resolve manually via `git checkout -- <files>` to revert partial writes, or commit them by hand.

Verify this is a git repository:

```bash
git rev-parse --show-toplevel 2>/dev/null || echo "NOT_A_GIT_REPO"
```

If `NOT_A_GIT_REPO`: print `Error: /CJ_goal_defect requires a git repository.` and stop.

## Default-worktree (BEFORE Path Resolution — variables get re-resolved post-cd)

Per F000027 (reshape of F000025/S000054): when invoked with a positional
`<bug description>`, auto-create a `cj-def-{YYYYMMDD-HHMMSS}-{PID}/` worktree
and `cd` into it. The worktree phase is delegated to the shared
`scripts/cj-goal-common.sh --phase worktree --mode defect` helper (S000057),
which in turn shells out to the vetted `cj-worktree-init.sh --caller defect`
(branch prefix `cj-def`). Conductor-managed sessions (already inside a
worktree) detect + no-op. `--no-worktree` opts out; `--dry-run` forwards
through the helper and creates nothing.

The positional-arg guard means a flag-only invocation (e.g. a bare
`--dry-run` with no bug description) skips the helper and errors on the
missing argument as usual — no empty worktree is spun up. Mirrors the
`/CJ_goal_investigate` wiring; the only difference is the verb-shared
`cj-goal-common.sh` indirection (Approach A, F000027_DESIGN Big Decision #4).

```bash
# Default-worktree (BEFORE path resolution — variables get re-resolved post-cd)
# Detect a positional bug-description arg: at least one non-flag arg present.
_HAS_POSITIONAL=0
for _ARG in "$@"; do
  case "$_ARG" in
    --*|-*) ;;
    *) _HAS_POSITIONAL=1; break ;;
  esac
done

if [ "$_HAS_POSITIONAL" = "1" ]; then  # only when a bug description is present
  _S=$(jq -r '.source // empty' "$HOME/.claude/.skills-templates.json" 2>/dev/null)
  _COMMON=""
  _REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo "")
  # Repo-local first (workbench self-development), then deployed manifest .source.
  if [ -n "$_REPO_ROOT" ] && [ -x "$_REPO_ROOT/scripts/cj-goal-common.sh" ]; then
    _COMMON="$_REPO_ROOT/scripts/cj-goal-common.sh"
  elif [ -n "$_S" ] && [ -x "$_S/scripts/cj-goal-common.sh" ]; then
    _COMMON="$_S/scripts/cj-goal-common.sh"
  fi

  if [ -n "$_COMMON" ]; then
    # Forward --no-worktree / --dry-run when present so the helper honors them.
    _WT_FLAGS=()
    for _ARG in "$@"; do
      case "$_ARG" in
        --no-worktree) _WT_FLAGS+=(--no-worktree) ;;
        --dry-run)     _WT_FLAGS+=(--dry-run) ;;
      esac
    done
    _WT_OUT=$(bash "$_COMMON" --phase worktree --mode defect "${_WT_FLAGS[@]}" 2>/dev/null)
    _WT_STATE=$(printf '%s\n' "$_WT_OUT" | sed -n 's/^WT_STATE=//p')
    _WT_PATH=$(printf '%s\n' "$_WT_OUT" | sed -n 's/^WT_PATH=//p')
    _WT_RESULT=$(printf '%s\n' "$_WT_OUT" | sed -n 's/^PHASE_RESULT=//p')
    if [ "$_WT_STATE" = "created" ] || [ "$_WT_STATE" = "detected" ]; then
      [ -n "$_WT_PATH" ] && { cd "$_WT_PATH" || { echo "[worktree] ERROR: cd $_WT_PATH failed"; exit 1; }; }
      echo "[worktree] $_WT_STATE: $_WT_PATH"
    elif [ "$_WT_RESULT" = "failed" ]; then
      echo "[worktree] ERROR: cj-goal-common.sh worktree phase failed (state=$_WT_STATE)"
      exit 1
    fi
    # On skipped / opted_out / unavailable-but-soft: no cd, no halt; continue.
  else
    # Visible warning (NOT silent no-op) — per F000025 Decision Audit Trail #11.
    echo "[worktree] WARN: cj-goal-common.sh unreachable; running on current branch"
  fi
fi
```

## Path Resolution

Resolve skill assets using a 2-level fallback chain:

```bash
_REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
_SKILL_DIR=""

if [ -n "$_REPO_ROOT" ] && [ -f "$_REPO_ROOT/skills/CJ_goal_defect/pipeline.md" ]; then
  _SKILL_DIR="$_REPO_ROOT/skills/CJ_goal_defect"
fi
if [ -z "$_SKILL_DIR" ] && [ -f "$HOME/.claude/skills/CJ_goal_defect/pipeline.md" ]; then
  _SKILL_DIR="$HOME/.claude/skills/CJ_goal_defect"
fi

if [ -z "$_SKILL_DIR" ]; then
  echo "ERROR: CJ_goal_defect skill assets not found."
  echo "Run: ./scripts/skills-deploy install"
  echo "NOT_FOUND"
else
  echo "SKILL_DIR: $_SKILL_DIR"
fi
```

If `NOT_FOUND`: surface the error and stop.

## Overview

`/CJ_goal_defect "<bug description>"` is the one-keystroke path from a plain bug
report — with NO pre-existing defect dir — to a deployed fix. It reshapes
`/CJ_goal_investigate` v1.1's flat pipeline (~80% reuse) but starts from raw
text instead of a resolved D-ID, so there is no defect resolver: every run
begins by scaffolding a throwaway draft. The chain:

```
"<bug description>"
   │  cj-goal-common.sh --phase worktree --mode defect   (S000057 → cj-worktree-init.sh --caller defect)
   ▼
scaffold .inbox/<slug>/DRAFT.md   (no D-ID; idempotent — same phrase resumes the same draft)
   │
   ▼  Agent: /investigate dispatch (sentinel-wrapped JSON instruction)
   │        FIX_PLAN_BEGIN_JSON / DEBUG_REPORT_BEGIN_JSON output blocks
   │
   ▼  parse FIX_PLAN → halt if >5 files ([investigate-blast-radius] pre-write halt)
   │
   ▼  parse DEBUG_REPORT → halt-on-red taxonomy (Iron-Law gate)
   │        ([investigate-no-sentinel], [investigate-parse-error],
   │         [investigate-no-root-cause], [investigate-blocked],
   │         [investigate-unverified])
   │
   ▼  PROMOTE: .inbox/<slug>/ → work-items/defects/uncategorized/D000NNN_<slug>/
   │        (D-ID minted ONLY after the Iron-Law gate passes; mkdir-lock)
   │
   ▼  write RCA.md (template-heading-mapped) + test-plan.md (row append)
   │
   ▼  /CJ_qa-work-item <defect-dir>           (Skill / leaf subagent)
   │
   ▼  /ship                                    (Gate #2 fires; halt on [ship-declined])
   │
   ▼  /land-and-deploy --suppress-readiness-gate   (Skill invocation)
   │
   ▼  tracker journal: [defect-shipped] D000NNN vX.Y.Z PR #NNN
   │
   ▼  telemetry append → ~/.gstack/analytics/CJ_goal_defect.jsonl
```

Iron-Law gate is enforced by design: `/investigate` Phase 4 writes the fix
DIRECTLY to source — there is NO separate `/CJ_implement-from-spec` step. RCA
+ test-plan are post-investigate audit artifacts. A D-ID is **never** minted
for a root-cause-less bug: promotion (Step 7.4) runs only after the gate
passes. `DONE_WITH_CONCERNS` (`[investigate-unverified]`) halts pre-ship: a
"fix written but unverified" never auto-advances, and the draft is retained
(no D-ID consumed) so a re-run resumes.

**Why a reshape, not a wrapper.** Wrapping `/CJ_goal_investigate` would
re-inherit the nested-subagent wall (an orchestrator subagent cannot spawn
its own subagent). This skill is flat: it dispatches `/investigate` and
`/CJ_qa-work-item` as depth-≤2 leaf subagents and runs `/ship` +
`/land-and-deploy` inline. The deterministic worktree + pr-check phases come
from `cj-goal-common.sh` (S000057); the Skill-tool invocations stay inline
(Approach A, F000027_DESIGN Big Decision #4).

## Usage

```
/CJ_goal_defect "login form throws a 500 on empty password"   # scaffold → root-cause → ship
/CJ_goal_defect --dry-run "login form throws a 500"           # preview chain plan + write paths; no writes
/CJ_goal_defect --no-worktree "..."                           # run in place on a clean checkout (opt out of auto-worktree)
```

**Flags:**
- `--dry-run` — preview only; print the slug/draft path, the expected
  `/investigate` dispatch plan, the would-promote canonical path, and the
  expected RCA / test-plan write paths. NO files written, NO subagent
  dispatched, NO Skill invocations. Output includes a copy-paste suggested
  resume command (drop the `--dry-run`).
- `--no-worktree` — operator opt-out: run in place on a clean checkout instead
  of auto-creating a `cj-def-*` worktree. Forwarded to the worktree phase.
- `--verbose` *(P2, optional)* — emit the raw `/investigate` transcript to
  `~/.gstack/analytics/CJ_goal_defect-runs/<RUN_ID>/investigate-raw.txt` in
  addition to the structured halt journal entries' `raw_output_path=`.

**Out of scope** (deferred to a later version per SPEC Tradeoffs and the parent
F000027 design):
- Drain mode (`--max-drain N`)
- `--quiet` schedule-friendly mode
- Family-drain shared lockfile (cross-skill race protection)
- Sunset criterion + telemetry-driven decommission gate
- Domain inference at promotion (defaults to `uncategorized`)
- Resuming a re-worded bug description against an existing draft (verbatim
  re-invocation resumes; re-wording creates a new draft)
- Garbage-collecting stale `.inbox/` drafts

## Routing

Read [pipeline.md](pipeline.md) and follow the step-by-step orchestration. The
pipeline file owns: arg parsing, bug-report scaffolding, the `/investigate`
dispatch prompt, the sentinel parser, the halt-taxonomy entries, draft
promotion, artifact writes, the chain dispatch, and telemetry.

## Error Handling

| Error | Message | Recovery |
|-------|---------|----------|
| Not a git repo | "Error: /CJ_goal_defect requires a git repository." | Run inside a repo |
| Skill assets not found | "Error: CJ_goal_defect skill assets not found." | Run `skills-deploy install` |
| No argument | "Error: a bug description is required." | Pass a quoted bug description |
| Worktree phase failed | `[worktree] ERROR: ...` | Inspect `cj-goal-common.sh` output; pass `--no-worktree` on a clean checkout |
| Checkout not clean+isolated (or helper unreachable) | `[investigate-not-isolated]` (Step 5.0 pre-dispatch halt) | Commit/stash changes, run from a fresh worktree / clean feature branch, or pass `--no-worktree` on a clean checkout; re-run via `resume_cmd` |
| Promotion lock timeout | `[promote-lock-timeout]` | Check for a stale `.scaffold.lock.d`; rmdir it if no other invocation is live; re-run the same description |
| /investigate output missing sentinel | Journal entry `[investigate-no-sentinel]` with `next_action=` / `resume_cmd=` / `raw_output_path=` | Inspect raw output; manual investigate; resume via `resume_cmd` |
| /investigate JSON malformed | `[investigate-parse-error]` | Same |
| Empty root cause / placeholder | `[investigate-no-root-cause]` | Re-run /investigate manually; the draft is retained, no D-ID minted |
| /investigate returned BLOCKED | `[investigate-blocked]` | Inspect DEBUG_REPORT for the blocker; resolve; re-run the same description |
| DONE_WITH_CONCERNS | `[investigate-unverified]` | Manual verification + manual /ship if appropriate; draft retained |
| Blast radius >5 files | `[investigate-blast-radius]` (pre-write halt) | Decompose into multiple bugs; manual /investigate per chunk |
| /CJ_qa-work-item red | `[qa-red]` (re-use existing CJ_qa-work-item marker) | Inspect QA output; fix; re-run |
| /ship Gate #2 declined | `[ship-declined]` | Address operator feedback; re-run when ready |
| /land-and-deploy red | `[land-and-deploy-red]` (CI / merge / canary) | Inspect run output; fix + re-invoke |

## Halt-on-Red Taxonomy (inherited from investigate v1.1, unchanged)

All halts write a structured journal entry to the active tracker (the draft's
`DRAFT.md` pre-promotion, or the canonical `*_TRACKER.md` post-promotion) with
the following fields:

- `[<halt-id>]` — bracket-tagged marker for grep
- `next_action=<one-line description>` — what the operator should do
- `resume_cmd=<copy-paste shell command>` — how to resume after fixing
- `pr_url=<url or N/A>` — set when a PR exists (post-/ship halts)
- `raw_output_path=<path or N/A>` — pointer to raw subagent output where applicable

`CJ_goal_defect` always starts from a draft, so the canonical-resolve halts
(`halted_at_resolve_ambiguous`, the retired `halted_at_resolve_zero`) and the
fix-in-tree anomaly row do not apply — every run is fresh by construction. The
substantive end-states it inherits unchanged:

| End-state | Halt marker | When |
|-----------|-------------|------|
| `halted_at_no_arg` | (no journal — usage halt; output on stderr) | No bug description passed |
| `halted_at_investigate_blast_radius` | `[investigate-blast-radius]` | FIX_PLAN reports >5 files; pre-write halt |
| `halted_at_investigate_no_sentinel` | `[investigate-no-sentinel]` | /investigate stdout missing DEBUG_REPORT_BEGIN_JSON block |
| `halted_at_investigate_parse_error` | `[investigate-parse-error]` | Sentinel block found but JSON invalid |
| `halted_at_investigate_no_root_cause` | `[investigate-no-root-cause]` | JSON.root_cause empty or matches `/^\[.*\]$/` placeholder |
| `halted_at_investigate_blocked` | `[investigate-blocked]` | JSON.status == "BLOCKED" |
| `halted_at_investigate_unverified` | `[investigate-unverified]` | JSON.status == "DONE_WITH_CONCERNS" |
| `halted_at_investigate_not_isolated` | `[investigate-not-isolated]` | Step 5.0 isolation gate: checkout not clean+isolated OR worktree helper unreachable; pre-dispatch halt, source-writing subagent provably not dispatched |
| `halted_at_promote_lock_timeout` | `[promote-lock-timeout]` | Step 7.4 D-ID allocation mkdir-lock held >10s; promotion aborted, draft retained, no D-ID consumed |
| `halted_at_qa` | `[qa-red]` | /CJ_qa-work-item red |
| `halted_at_ship` | `[ship-declined]` | /ship Gate #2 declined or pre-landing review red |
| `halted_at_deploy` | `[land-and-deploy-red]` | /land-and-deploy red (CI / merge / canary) |

Success end-states: `green`, `dry_run_preview`.

## Idempotency

`CJ_goal_defect` is idempotent across re-invocation of the SAME bug description:

- **Pre-promotion:** the slug is derived deterministically from the description
  (no timestamp in the dir name), so a verbatim re-run resumes the existing
  `.inbox/<slug>/DRAFT.md` rather than creating a duplicate. The draft itself
  is fresh by construction (no RCA, no D-ID, no PR possible).
- **Post-promotion:** once `/investigate` passes the Iron-Law gate and the
  draft is promoted to a canonical `D000NNN_<slug>/` dir, a re-run of the same
  phrase resolves the canonical tracker (the written `name:` field matches the
  description), so no second D-ID is minted. The 5-row R/F/P/M resume ladder
  from investigate v1.1 then applies to the canonical defect.
- **Halts** write `next_action=` / `resume_cmd=` and preserve state (draft or
  canonical tracker); re-running resumes from the first incomplete step.

## Notes

- **Sentinel-wrapped JSON** is the load-bearing convention. The dispatch
  prompt explicitly instructs `/investigate` to emit
  `DEBUG_REPORT_BEGIN_JSON\n{...}\nDEBUG_REPORT_END_JSON` (and optionally
  `FIX_PLAN_BEGIN_JSON ... FIX_PLAN_END_JSON` pre-Phase-4). It is a
  prompt-convention, not an upstream feature; the parser falls back to
  `[investigate-no-sentinel]` halt if the block is absent rather than
  attempting fragile free-text regex parsing.
- **`/investigate` Phase 4 writes the fix directly** — there is no separate
  implementation step in this chain. RCA + test-plan are post-investigate
  audit artifacts, not inputs.
- **Iron-Law gate** is preserved: `DONE_WITH_CONCERNS` halts at
  `[investigate-unverified]` and does NOT auto-advance to `/ship`. The draft
  is retained (no D-ID consumed); the operator can verify + ship manually.
- **`/ship` Gate #2 always fires** — the autonomy ceiling is intact. This
  skill does NOT bypass operator diff review. This is the genuine difference
  from `/cj_goal_auto`'s opt-in auto-merge: a bug fix deploys only after the
  human approves the diff at Gate #2.
- **`/land-and-deploy --suppress-readiness-gate`** — mirrors the family pattern
  so the chain doesn't AUQ a second time at deploy.
- **Telemetry path** is `~/.gstack/analytics/CJ_goal_defect.jsonl` (one JSONL
  line per run), matching the family convention (`CJ_goal_investigate.jsonl`,
  `CJ_goal_auto.jsonl`). The shared `cj-goal-common.sh` is consumed for the
  deterministic worktree + pr-check phases; the canonical end-state telemetry
  line is written inline by Step 11 (same shape as investigate v1.1's Step 11)
  so the documented per-verb stream is authoritative.
- **Depth ≤ 2.** Orchestrator → leaf subagent (`/investigate`,
  `/CJ_qa-work-item`). No subagent-spawns-subagent path; `/ship` +
  `/land-and-deploy` run inline at the top level.
