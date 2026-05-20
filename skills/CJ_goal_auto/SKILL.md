---
name: CJ_goal_auto
description: "Full-handoff one-liner-to-deployed orchestrator (v1.0, experimental). Takes a single one-line idea, runs Stage 0 (worktree + version-queue + --handoff capability sentinel grep) -> Stage 0.5 (small-unambiguous classifier; halts non-small) -> Stage 1 (workbench-owned design-doc generator) -> Stage 1.5 (fail-closed post-condition doc gate) -> Stage 2 (/CJ_goal_run <doc> --handoff --no-drain). GATE #1 (autoplan final-approval AUQ) is always human; GATE #2 (post-/ship merge gate) is delegated to scripts/cj-handoff-gate.sh -- frozen merge-base, denylist (rename/symlink-safe + test-surface), <=120 added lines, <=5 files, Phase-2 markers all-green -- exit 0 proceeds to /land-and-deploy --suppress-readiness-gate; non-zero halts for human review of the created PR. Three explicit shapes: '<idea>' (human-gated default), --auto-merge-small-diffs '<idea>' (opt-in auto-merge), --dry-run '<idea>' (zero-write preview). --handoff is a deprecated alias for --auto-merge-small-diffs. Stage 3 writes per-run audit receipt to ~/.gstack/analytics/CJ_goal_auto.jsonl with classifier verdict, pinned BASE SHA, denylist result, Phase-2 markers, gate result, resume_cmd; --audit/--list-handoffs prints the last 10. Every-run retro AUQ for first 5 auto-merges, then every-5th. Halt-on-red default with structured stop block + next_action= + resume_cmd= + pr_url=. Workbench-only (macOS, claude-skills-templates repo). v1.0 single user-story; multi-story/headless-office-hours/Approach C/Copilot bundle all deferred. Use when: 'fire and forget small change', 'one-liner to deployed', 'auto-ship small idea', 'handoff small change'."
version: 1.0.0
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

Check for collection updates (silent if none, banner if a newer version is available):

```bash
_S=$(jq -r '.source // empty' "$HOME/.claude/.skills-templates.json" 2>/dev/null)
[ -n "$_S" ] && [ -x "$_S/scripts/skills-update-check" ] && "$_S/scripts/skills-update-check" 2>/dev/null || true
```

Verify this is a git repository:

```bash
git rev-parse --show-toplevel 2>/dev/null || echo "NOT_A_GIT_REPO"
```

If `NOT_A_GIT_REPO`: tell the user "Error: /CJ_goal_auto requires a git repository." and stop.

## Update Nudge Handling (skip silently if preamble printed nothing about updates)

Same as /CJ_goal_run: if preamble output contains `SKILLS_UPGRADE_AVAILABLE <old> <new>`, follow the upgrade flow defined in `~/.claude/skills/CJ_personal-workflow/SKILL.md`. If `SKILLS_JUST_UPGRADED <from> <to>`, print "claude-skills-templates upgraded to v\<to\> (was v\<from\>)" and continue.

## Default-worktree (BEFORE Path Resolution — variables get re-resolved post-cd)

Per F000025/S000054 (mirroring `/CJ_goal_run` + `/CJ_goal_investigate`): when invoked
with a positional one-liner on `main`, auto-create
`.claude/worktrees/cj-auto-{YYYYMMDD-HHMMSS}-{PID}/` and `cd` into it. Conductor-
managed sessions (already inside a worktree) detect + no-op. `--no-worktree` opts out;
`--quiet` gates the `[worktree]` echo and skips on a dirty checkout. The positional-
arg guard means a flag-only invocation (e.g. bare `--audit` with no idea) skips the
helper and falls through to the read-only `--audit` handler in `auto.md`.

```bash
# Default-worktree (BEFORE path resolution — variables get re-resolved post-cd).
# Detect a positional idea: at least one non-flag arg present.
_HAS_POSITIONAL=0
for _ARG in "$@"; do
  case "$_ARG" in
    --*|-*) ;;
    *) _HAS_POSITIONAL=1; break ;;
  esac
done

if [ "$_HAS_POSITIONAL" = "1" ]; then  # only when an idea is present
  _S=$(jq -r '.source // empty' "$HOME/.claude/.skills-templates.json" 2>/dev/null)
  if [ -n "$_S" ] && [ -x "$_S/scripts/cj-worktree-init.sh" ]; then
    _WT_JSON=$("$_S/scripts/cj-worktree-init.sh" --caller auto "$@" 2>/dev/null)
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
      [ "${QUIET:-0}" != "1" ] && [ -n "$_WT_NOTE" ] && echo "[worktree] $_WT_NOTE"
    fi
  else
    [ "${QUIET:-0}" != "1" ] && echo "[worktree] WARN: helper unreachable; running on current branch"
  fi
fi
```

Note: `cj-worktree-init.sh` is the F000025 helper; it accepts `--caller auto` as
a branch-prefix discriminator. If the helper predates the `auto` caller, it falls
through to its default branch prefix and behavior is functionally identical for
this skill (worktree gets a generic name; everything else still works).

## Path Resolution

Resolve skill assets using a 2-level fallback chain. This skill depends on
`/CJ_goal_run` (Stage 2 inline Skill invocation; required for `--handoff` /
`--no-drain` plumbing + sentinel) and the gate helper `scripts/cj-handoff-gate.sh`
(orchestrator-owned; invoked from within `/CJ_goal_run/run.md` at the post-`/ship`
/ pre-`/land-and-deploy` seam).

```bash
_REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
_SKILL_DIR=""

if [ -n "$_REPO_ROOT" ] && [ -f "$_REPO_ROOT/skills/CJ_goal_auto/auto.md" ]; then
  _SKILL_DIR="$_REPO_ROOT/skills/CJ_goal_auto"
fi
if [ -z "$_SKILL_DIR" ] && [ -f "$HOME/.claude/skills/CJ_goal_auto/auto.md" ]; then
  _SKILL_DIR="$HOME/.claude/skills/CJ_goal_auto"
fi

# Verify upstream skill exists (/CJ_goal_run is invoked inline at Stage 2)
if [ ! -f "$HOME/.claude/skills/CJ_goal_run/SKILL.md" ] && [ ! -f "$_REPO_ROOT/skills/CJ_goal_run/SKILL.md" ]; then
  echo "ERROR: required upstream skill 'CJ_goal_run' not found."
  echo "Run: ./scripts/skills-deploy install"
  echo "MISSING_UPSTREAM"
  exit 1
fi

# Verify the gate helper exists + is executable (Stage 0 capability self-check uses
# the resolved CJ_goal_run/run.md; the helper itself is called from inside run.md).
_GATE_HELPER="$_REPO_ROOT/scripts/cj-handoff-gate.sh"
[ -x "$_GATE_HELPER" ] || _GATE_HELPER="$HOME/.claude/scripts/cj-handoff-gate.sh"
if [ ! -x "$_GATE_HELPER" ]; then
  echo "ERROR: scripts/cj-handoff-gate.sh not found or not executable."
  echo "Run: ./scripts/skills-deploy install (workbench)"
  echo "MISSING_GATE_HELPER"
  exit 1
fi

if [ -z "$_SKILL_DIR" ]; then
  echo "ERROR: CJ_goal_auto skill assets not found."
  echo "Run: ./scripts/skills-deploy install (workbench) or check repo structure."
  echo "NOT_FOUND"
else
  echo "SKILL_DIR: $_SKILL_DIR"
  echo "GATE_HELPER: $_GATE_HELPER"
fi
```

If `NOT_FOUND` / `MISSING_UPSTREAM` / `MISSING_GATE_HELPER`: tell the user the matching error and stop.

## Overview

`/CJ_goal_auto "<one-liner>"` is the single-keystroke path from a one-line idea to a deployed change. The chain:

```
Stage 0 (worktree + version-queue + capability-sentinel)
   |
   v   Stage 0.5 (classifier: small-unambiguous | needs-human-taste | too-big)
   |
   v   Stage 1 (workbench-owned design-doc generator -> ~/.gstack/projects/<slug>/...)
   |
   v   Stage 1.5 (fail-closed post-condition: file exists + Status: APPROVED + all required sections non-empty)
   |
   v   Stage 2 (/CJ_goal_run <doc> --handoff --no-drain)
   |     |
   |     v   autoplan -> GATE #1 final-approval AUQ (always human)
   |     |
   |     v   scaffold / impl / qa  (reversible -- a branch)
   |     |
   |     v   Phase 3: /ship  (creates PR; runs pre-landing review)
   |     |
   |     v   GATE #2: scripts/cj-handoff-gate.sh
   |     |     - git fetch origin main; BASE=merge-base origin/main HEAD
   |     |     - git diff --no-renames --raw -z $BASE HEAD: denylist + symlink-safe
   |     |     - files <= 5, lines <= 120
   |     |     - PIPELINE_END_STATE=green + SMOKE=pass + E2E=pass + all PHASE2_GATES checked
   |     |     |
   |     |     +--- exit 0: proceed to /land-and-deploy --suppress-readiness-gate
   |     |     |
   |     |     +--- exit != 0: halt for human (structured stop block + named tripped condition)
   |     |
   |     v   Phase 4: /land-and-deploy --suppress-readiness-gate
   |
   v   Stage 3 (audit receipt -> ~/.gstack/analytics/CJ_goal_auto.jsonl + PR body line + retro AUQ)
```

`--handoff` is a deprecated alias for `--auto-merge-small-diffs`; both are
per-invocation opt-ins for the auto-merge path. The default shape
`/CJ_goal_auto "<idea>"` always halts at GATE #2 for human PR review (it never
auto-merges; `/ship` still runs but `/land-and-deploy` is never invoked from
the auto orchestrator without the opt-in flag).

Every gate is fail-closed:
- Stage 0 capability self-check missing the sentinel halts the run.
- Stage 0.5 non-`small-unambiguous` halts with manual route.
- Stage 1.5 missing required section halts AND Stage 2 is NEVER invoked.
- GATE #2 non-zero exit halts AND `/land-and-deploy` is NEVER invoked.

## Usage

```
/CJ_goal_auto "<idea>"                              # human-gated default (no auto-merge)
/CJ_goal_auto --auto-merge-small-diffs "<idea>"     # opt-in auto-merge (GATE #2 must pass)
/CJ_goal_auto --handoff "<idea>"                    # deprecated alias for --auto-merge-small-diffs
/CJ_goal_auto --dry-run "<idea>"                    # preview Stage 0 + 0.5 only; ZERO writes
/CJ_goal_auto --audit                               # print last 10 receipts
/CJ_goal_auto --list-handoffs                       # alias for --audit
```

**Flags:**

- `--auto-merge-small-diffs` — Per-invocation opt-in for the auto-merge path. Passed
  through to `/CJ_goal_run` as `--handoff`. GATE #2 (`scripts/cj-handoff-gate.sh`)
  must pass for the merge to proceed.
- `--handoff` — Deprecated alias for `--auto-merge-small-diffs`. Accepted; emits a
  one-line deprecation banner on stderr; otherwise identical.
- `--dry-run` — Preview-only. Runs Stage 0 + Stage 0.5; prints classifier verdict +
  reason, would-create paths, sentinel presence, and GATE #2 caps. ZERO writes to
  the filesystem. Stage 1 is NEVER invoked.
- `--audit` / `--list-handoffs` — Read-only. Prints the last 10 entries from
  `~/.gstack/analytics/CJ_goal_auto.jsonl` in human-readable form (classifier
  verdict, doc path, PR URL, pinned BASE SHA, gate result). Skips all other stages.
- `--no-worktree` — Opt out of the F000025 auto-worktree (default-worktree block above).
- `--quiet` — Suppresses the `[worktree]` echo. Mirrors the other CJ_goal_* skills.

**Default mode resolution:**

```
                  no flag     +--auto-merge-small-diffs    +--handoff (alias)
                  ---------   ------------------------     ------------------
mode=             human-gated   auto-merge-small             auto-merge-small
                  (Stage 2      (Stage 2 invoked with        (same; deprecation
                  invoked       --handoff; GATE #2           banner printed)
                  with /ship    must pass for merge)
                  but NOT
                  /land-and-
                  deploy)
```

The skill **always** echoes the resolved mode to stderr at Stage 0 start (mirroring
`/CJ_goal_todo_fix`'s `todo_fix.sh`):

```
mode=human-gated handoff=0 max_files=5 max_lines=120
mode=auto-merge-small handoff=1 max_files=5 max_lines=120
```

This is the load-bearing "operator confirms Claude understood my intent" signal.

## Routing

Read [auto.md](auto.md) and follow its instructions. The full orchestration logic
lives there: arg parsing + mode resolution, Stage 0 (worktree + version-queue +
sentinel), Stage 0.5 (classifier), Stage 1 (generator), Stage 1.5 (post-condition
gate), Stage 2 (`/CJ_goal_run --handoff --no-drain`), Stage 3 (audit receipt + retro
AUQ), structured halt contract, and the `--audit` / `--list-handoffs` read-only path.

## Error Handling

| Error | Message | Recovery |
|---|---|---|
| Not a git repo | "Error: /CJ_goal_auto requires a git repository." | Run inside a repo |
| Skill assets not found | "Error: CJ_goal_auto skill assets not found." | Run `skills-deploy install` |
| CJ_goal_run missing | "Error: required upstream skill 'CJ_goal_run' not found." | Run `skills-deploy install` |
| Gate helper missing | "Error: scripts/cj-handoff-gate.sh not found or not executable." | Run `skills-deploy install` |
| No idea arg in non-`--audit` mode | "Error: idea required. Use `/CJ_goal_auto \"<one-liner>\"` or `--audit` for read-only mode." | Pass an idea string |
| Stage 0 sentinel missing | `[capability-missing]` halt: "`--handoff` sentinel not found in resolved `CJ_goal_run/run.md`. The deployed `/CJ_goal_run` predates this skill. Run `./scripts/skills-deploy install` from the workbench, then re-invoke." | Update the deployed `/CJ_goal_run` |
| Stage 0 version-queue collision | `[version-queue-collision]` halt: prints next free slot from `scripts/check-version-queue.sh` | Wait for the colliding PR to merge, OR rebase the colliding branch |
| Stage 0.5 classifier non-small-unambiguous | `[classifier-halted]`: prints verdict + one-line reason + manual route (`/office-hours` -> `/CJ_goal_run <doc>`) | Run `/office-hours` for taste-needing or larger changes |
| Stage 1.5 doc missing required section | `[doc-gate-fail]`: prints missing section name(s); Stage 2 NEVER invoked | Inspect the generated doc at `~/.gstack/projects/<slug>/...`; fix the generator template if recurring |
| Stage 2 /CJ_goal_run halt | `[stage2-halt]`: pass-through of `/CJ_goal_run`'s halt; structured stop block + `next_action=` + `resume_cmd=` + `pr_url=` (if PR was created) | Resume per `resume_cmd` |
| GATE #2 denylist hit | `[gate2-denylist]`: prints the matched denylisted path + `pr_url=` + `resume_cmd=gh pr diff <N>` | Inspect PR; merge manually if good |
| GATE #2 size cap exceeded | `[gate2-size-cap]`: prints `files=N max=5` or `lines=N max=120` + `pr_url=` + `resume_cmd=gh pr diff <N>` | Inspect PR; merge manually if good |
| GATE #2 Phase-2 marker failed | `[gate2-qa-marker]`: prints which marker failed + `pr_url=` + `resume_cmd=gh pr diff <N>` | Inspect Phase-2 logs; fix; re-invoke if needed |
| GATE #2 symlink detected | `[gate2-symlink]`: prints the path of the new/changed symlink + `pr_url=` + `resume_cmd=gh pr diff <N>` | Manual review |
| GATE #2 rename of denylisted file | `[gate2-rename-denylist]`: prints both old + new paths + `pr_url=` + `resume_cmd=gh pr diff <N>` | Manual review |
| /land-and-deploy red | `[deploy-red]`: pass-through; `pr_url=` (already merged?) + `resume_cmd` | Manual: rollback OR fix-forward |

## Halt-on-Red Taxonomy

All halts write a structured journal entry (in the orchestrator's stderr summary AND the audit receipt) with:

- `[<halt-id>]` — bracket-tagged marker for grep
- `next_action=<one-line description>`
- `resume_cmd=<copy-paste shell command>`
- `pr_url=<URL>` — when a PR was created (Stage 2 reached `/ship`)
- `work_item_dir=<path>` — when scaffolding reached the work-item-dir stage

The end-states (audit-receipt `gate_result` field):

| End-state | Halt marker | When |
|-----------|-------------|------|
| `auto-approved` | none | GATE #2 exit 0; `/land-and-deploy` proceeded |
| `human-gated` | none | Default mode (no `--auto-merge-small-diffs`); GATE #2 not invoked; PR ready for manual merge |
| `dry_run_preview` | none | `--dry-run` completed |
| `audit_view` | none | `--audit` / `--list-handoffs` |
| `halted_at_capability` | `[capability-missing]` | Stage 0 sentinel missing |
| `halted_at_version_queue` | `[version-queue-collision]` | Stage 0 preflight |
| `halted_at_classifier` | `[classifier-halted]` | Stage 0.5 non-small-unambiguous |
| `halted_at_doc_gate` | `[doc-gate-fail]` | Stage 1.5 missing required section |
| `halted_at_stage2` | `[stage2-halt]` | `/CJ_goal_run` halted before GATE #2 |
| `halted_at_gate2` | `[gate2-*]` | GATE #2 non-zero exit (auto-merge mode only) |
| `halted_at_deploy` | `[deploy-red]` | `/land-and-deploy` red |

## Sunset Criterion

Mirrors `/CJ_goal_run`'s pattern. v1.0 ships without a fixed trip-wire because there
is no historical data yet; revisit on invocation 6 once the audit receipt log has
populated. The every-run retro AUQ for the first 5 auto-merges (then every-5th) is
the primary signal for "is the classifier wrong" — that's a separate-but-related
checkpoint surfaced by `auto.md` Stage 3. A formal `halt_count >= 3 of 5` trip-wire
can be added once `~/.gstack/analytics/CJ_goal_auto.jsonl` accumulates enough rows
to be meaningful.

To delete: remove `skills/CJ_goal_auto/`, strike the catalog entry, run
`skills-deploy install`. Also strip the `--handoff` / `--no-drain` / sentinel wiring
from `skills/CJ_goal_run/run.md` (post-Step 4, pre-Step 5 seam) and remove
`scripts/cj-handoff-gate.sh`. Tests 1–11 in `scripts/test.sh` should be removed in
the same change.
