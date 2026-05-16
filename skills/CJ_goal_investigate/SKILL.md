---
name: CJ_goal_investigate
description: "Defect-to-shipped-fix orchestrator. Takes a scaffolded defect work-item (legacy `work-items/defects/<domain>/D000NNN_<slug>/` layout in v1.0) and ships a deployed fix end-to-end via /investigate (Agent subagent, sentinel-wrapped JSON output) → RCA + test-plan artifact writes → /CJ_qa-work-item → /ship → /land-and-deploy. Iron-Law gate enforced for free: no fixes ship without a populated root cause. 9-state halt-on-red taxonomy with `next_action=` / `resume_cmd=` / `raw_output_path=` journal entries. 5-row idempotency resume table. `--dry-run` previews chain plan + write paths without mutation. Workbench-only (v1.0); drain mode / family-drain lock / sunset criterion / freestanding defect convention all deferred to v1.1."
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

Check for collection updates (silent if none, banner if newer):

```bash
_S=$(jq -r '.source // empty' "$HOME/.claude/.skills-templates.json" 2>/dev/null)
[ -n "$_S" ] && [ -x "$_S/scripts/skills-update-check" ] && "$_S/scripts/skills-update-check" 2>/dev/null || true
```

Verify this is a git repository:

```bash
git rev-parse --show-toplevel 2>/dev/null || echo "NOT_A_GIT_REPO"
```

If `NOT_A_GIT_REPO`: print `Error: /CJ_goal_investigate requires a git repository.` and stop.

## Path Resolution

Resolve skill assets using a 2-level fallback chain:

```bash
_REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
_SKILL_DIR=""

if [ -n "$_REPO_ROOT" ] && [ -f "$_REPO_ROOT/skills/CJ_goal_investigate/pipeline.md" ]; then
  _SKILL_DIR="$_REPO_ROOT/skills/CJ_goal_investigate"
fi
if [ -z "$_SKILL_DIR" ] && [ -f "$HOME/.claude/skills/CJ_goal_investigate/pipeline.md" ]; then
  _SKILL_DIR="$HOME/.claude/skills/CJ_goal_investigate"
fi

if [ -z "$_SKILL_DIR" ]; then
  echo "ERROR: CJ_goal_investigate skill assets not found."
  echo "Run: ./scripts/skills-deploy install"
  echo "NOT_FOUND"
else
  echo "SKILL_DIR: $_SKILL_DIR"
fi
```

If `NOT_FOUND`: surface the error and stop.

## Overview

`/CJ_goal_investigate <D-id|fragment>` is the one-keystroke path from a scaffolded
defect work-item to a deployed fix. The chain:

```
resolve defect dir (D-ID exact OR fragment fuzzy; halt on ambiguity)
   │
   ▼  preflight: 5-row idempotency table → pick resume row
   │
   ▼  Agent: /investigate dispatch (sentinel-wrapped JSON instruction)
   │        FIX_PLAN_BEGIN_JSON / DEBUG_REPORT_BEGIN_JSON output blocks
   │
   ▼  parse FIX_PLAN → halt if >5 files ([investigate-blast-radius] pre-write halt)
   │
   ▼  parse DEBUG_REPORT → 9-state halt-on-red taxonomy
   │        ([investigate-no-sentinel], [investigate-parse-error],
   │         [investigate-no-root-cause], [investigate-blocked],
   │         [investigate-unverified], [investigate-three-strike], etc.)
   │
   ▼  write RCA.md (template-heading-mapped) + test-plan.md (row append)
   │
   ▼  /CJ_qa-work-item <defect-dir>           (Skill invocation)
   │
   ▼  /ship                                    (Gate #2 fires; halt on [ship-declined])
   │
   ▼  /land-and-deploy --suppress-readiness-gate   (Skill invocation)
   │
   ▼  tracker journal: [investigate-shipped] D000NNN vX.Y.Z PR #NNN
   │
   ▼  telemetry append
```

Iron-Law gate is enforced by design: `/investigate` Phase 4 writes the fix
DIRECTLY to source — there is NO separate `/CJ_implement-from-spec` step. RCA
+ test-plan are post-investigate audit artifacts. `DONE_WITH_CONCERNS`
(`[investigate-unverified]`) halts pre-ship: a "fix written but unverified"
never auto-advances.

## Usage

```
/CJ_goal_investigate D000019                  # exact D-ID resolve
/CJ_goal_investigate "step5"                  # fragment fuzzy resolve (unique match required)
/CJ_goal_investigate --dry-run D000019        # preview chain plan + idempotency state; no writes
/CJ_goal_investigate --dry-run "step5"
```

**Flags:**
- `--dry-run` — preview only; print resolved defect path, current idempotency
  resume row, expected `/investigate` dispatch plan, and expected RCA / test-plan
  write paths. NO files written, NO subagent dispatched. Output includes a
  copy-paste suggested resume command (drop the `--dry-run`).
- `--verbose` *(P2, optional)* — emit the raw `/investigate` transcript to
  `~/.gstack/analytics/CJ_goal_investigate-runs/<RUN_ID>/investigate-raw.txt`
  in addition to the structured halt journal entries' `raw_output_path=`.

**Out of scope for v1.0** (deferred to v1.1+ per SPEC Tradeoffs row 6 and
parent F000023 design):
- Drain mode (`--max-drain N`)
- `--quiet` schedule-friendly mode
- Family-drain shared lockfile (cross-skill race protection)
- Sunset criterion + telemetry-driven decommission gate
- Freestanding defect convention (`D<NNN>_bug-report.md` without dir)
- Ad-hoc bugs without scaffolded defect dir (v2.0)

## Routing

Read [pipeline.md](pipeline.md) and follow the step-by-step orchestration. The
pipeline file owns: arg parsing, defect resolver, idempotency table, dispatch
prompt construction, sentinel parser, halt-taxonomy entries, artifact writes,
chain dispatch, and telemetry.

## Error Handling

| Error | Message | Recovery |
|-------|---------|----------|
| Not a git repo | "Error: /CJ_goal_investigate requires a git repository." | Run inside a repo |
| Skill assets not found | "Error: CJ_goal_investigate skill assets not found." | Run `skills-deploy install` |
| No argument | "Error: D-ID or fragment required." | Pass `D000NNN` or a fragment string |
| Defect not resolved (zero matches) | "Halt: no defect matches '<arg>'." | Verify `work-items/defects/<domain>/D000NNN_*/` exists; check spelling |
| Defect ambiguous (2+ matches) | "Halt: '<arg>' matches N defects:\n  D000NNN at <path>\n  ...\nRe-run with full D-ID." | Re-run with `D000NNN` |
| Anomaly: RCA empty but fix in tree | "Halt: [anomaly-rca-missing-with-fix] — fix on branch but no RCA. Manual review required." | Inspect tracker journal; either revert the partial fix or hand-author RCA |
| /investigate output missing sentinel | Journal entry `[investigate-no-sentinel]` with `next_action=` / `resume_cmd=` / `raw_output_path=` | Inspect raw output; manual investigate; resume via `resume_cmd` |
| /investigate JSON malformed | `[investigate-parse-error]` | Same |
| Empty root cause / placeholder | `[investigate-no-root-cause]` | Re-run /investigate manually; populate RCA by hand if needed |
| DONE_WITH_CONCERNS | `[investigate-unverified]` | Manual verification + manual /ship if appropriate |
| Blast radius >5 files | `[investigate-blast-radius]` (pre-write halt) | Decompose fix into multiple defects; manual /investigate per chunk |
| /ship Gate #2 declined | `[ship-declined]` | Address operator feedback; re-run when ready |
| /land-and-deploy red | `[land-and-deploy-red]` (CI / merge / canary) | Inspect run output; fix + re-invoke |

## Halt-on-Red Taxonomy (9 end-states)

All halts write a structured journal entry with the following fields:

- `[<halt-id>]` — bracket-tagged marker for grep
- `next_action=<one-line description>` — what the operator should do
- `resume_cmd=<copy-paste shell command>` — how to resume after fixing
- `raw_output_path=<path or N/A>` — pointer to raw subagent output where applicable

The 9 end-states:

| End-state | Halt marker | When |
|-----------|-------------|------|
| `halted_at_resolve_ambiguous` | (no journal — resolver halt; output on stderr) | Fragment matched 2+ defects |
| `halted_at_resolve_zero` | (no journal — resolver halt; output on stderr) | Fragment matched zero defects |
| `halted_at_anomaly_rca_missing` | `[anomaly-rca-missing-with-fix]` | Fix in tree but RCA empty (idempotency anomaly row) |
| `halted_at_investigate_blast_radius` | `[investigate-blast-radius]` | FIX_PLAN reports >5 files; pre-write halt |
| `halted_at_investigate_no_sentinel` | `[investigate-no-sentinel]` | /investigate stdout missing DEBUG_REPORT_BEGIN_JSON block |
| `halted_at_investigate_parse_error` | `[investigate-parse-error]` | Sentinel block found but JSON invalid |
| `halted_at_investigate_no_root_cause` | `[investigate-no-root-cause]` | JSON.root_cause empty or matches `/^\[.*\]$/` placeholder |
| `halted_at_investigate_unverified` | `[investigate-unverified]` | JSON.status == "DONE_WITH_CONCERNS" |
| `halted_at_ship` | `[ship-declined]` | /ship Gate #2 declined or pre-landing review red |
| `halted_at_deploy` | `[land-and-deploy-red]` | /land-and-deploy red (CI / merge / canary) |

(End-state count is 9 substantive halts + the 2 resolver halts that exit
before any journal write. The taxonomy table above lists all of them for
completeness.)

## Idempotency Resume Table (5 rows)

State signals: RCA-populated (R), fix-in-tree (F), PR-open (P), PR-merged (M).
Re-running on a partially-completed defect picks the right resume point:

| Row | R | F | P | M | Action |
|-----|---|---|---|---|--------|
| 1   | 0 | 0 | 0 | 0 | Fresh: dispatch /investigate, write artifacts, chain QA→ship→deploy |
| 2   | 1 | 1 | 0 | 0 | Skip /investigate + writes; chain QA→ship→deploy |
| 3   | 1 | 1 | 1 | 0 | Skip everything through /ship; chain /land-and-deploy |
| 4   | 1 | 1 | 0 | 1 | No-op: print one-line summary `[investigate-shipped]` already in journal |
| 5   | 0 | 1 | * | * | Anomaly: halt with `[anomaly-rca-missing-with-fix]` |

Signals are detected from:
- RCA-populated: `D000NNN_RCA.md` exists AND `## Root Cause` section has prose
  (more than the placeholder `<!-- TODO -->`).
- Fix-in-tree: `git log --all --oneline` matches the defect's D-ID, OR
  `git diff origin/main..HEAD` shows source changes paired with this defect's
  tracker journal entries.
- PR-open / PR-merged: `gh pr list --search "D000NNN in:title"` returns
  state OPEN / MERGED.

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
  `[investigate-unverified]` and does NOT auto-advance to `/ship`. The
  operator can ship manually after verification if appropriate.
- **`/ship` Gate #2 always fires** — the autonomy ceiling is intact. v1.0
  does NOT bypass operator diff review.
- **`/land-and-deploy --suppress-readiness-gate`** — mirrors `/CJ_goal_run`'s
  family-pattern so the chain doesn't AUQ a second time at deploy.
- **Legacy defect dir only in v1.0.** `resolve_defect_dir()` searches
  `work-items/defects/<domain>/D000NNN_<slug>/`. Freestanding
  `D<NNN>_bug-report.md` convention is a v1.1 helper swap.
