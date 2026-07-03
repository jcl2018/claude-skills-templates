---
skill-name: "CJ_goal_task"
version: 0.1.0
status: experimental
created: "2026-06-07"
last-updated: "2026-07-03T20:06:32Z"
---

# Skill Usage: CJ_goal_task

## When to use

- "do this small task end-to-end", "refine a doc / add a file / clean up files to
  a PR", "fix this small thing and stop at the PR"
- You have a small, well-scoped, **mechanical** ad-hoc change that does NOT need
  design or root-cause investigation, and it is NOT already a `TODOS.md` row
- Recurring small cleanups: a one-row `TODOS.md` edit, a stale doc/badge sync, a
  single-file fix, clearing a stray tracked file, sweeping leftover scratch
- Resume: re-invoking the same verb on the same branch picks up where you left off
  (state file records `last_completed_phase` + per-phase HEAD SHA + work-item dir +
  PR number; validates-before-skipping)
- `--dry-run` previews the chain plan (including the complexity-gate verdict)
  without mutation; `--no-worktree` runs in place on a clean checkout; `--no-sync`
  skips the pre-build skills-sync

## When NOT to use

- The work needs design / an `/office-hours` pass — use `/CJ_goal_feature` (the
  complexity gate will refuse design-rework topics and route you there)
- The work is a bug needing root-cause investigation — use `/CJ_goal_defect` (the
  gate refuses bug/investigation topics and routes you there)
- The work is large / multi-skill / an epic — use `/CJ_goal_feature` (the gate
  refuses explicit-large-scope topics)
- The work is already a `TODOS.md` row — use `/CJ_goal_todo_fix` (it drains
  existing rows; `cj_goal_task` is for *ad-hoc* topics with no row)
- You want auto-merge after the PR — not supported by design; PR-stop only (the
  handoff-gate denylist makes auto-merge unsafe-by-construction here)

## Mental model

`cj_goal_task` is `/CJ_goal_feature` with the design phase swapped for an
automatic gate, and `/CJ_goal_todo_fix` minus the TODOS-row requirement. It is the
**most autonomous** verb up to the PR-stop: **no AskUserQuestion** on the happy
path (the former inline audit checkpoint is gone — see below). The flow is:
pre-build skills-sync → `cj-task-*` worktree (with
base-freshness) → isolation gate → a **hard complexity gate** (in
`scripts/cj-task-scaffold.sh`) that REFUSES design/bug/large topics and otherwise
silently bash-scaffolds a `type: task` work-item (T-ID) from the topic → silent
`/CJ_implement-from-spec` → `/CJ_qa-work-item` leaf subagents (with the inline
audits SKIPPED — the orchestrator passes a literal `DEFER_AUDIT: true` directive
so QA skips its Step 8.6c/8.6d doc/test audits and returns `AUDITS=deferred`, while
still running the 8.6a/8.6b spec-overlay writes) → an idempotent pre-doc-sync
commit → `/CJ_document-release` (Step 5.5 doc-sync) → `/ship` (with the
diff-review AUQ suppressed) → STOP at the open PR. The agent-judged doc/test audit
(`/CJ_doc_audit` + `/CJ_test_audit`) no longer runs on the build path or gates the
ship; it runs NIGHTLY in CI (`.github/workflows/audit-nightly.yml`), filing
findings to a GitHub issue. The deterministic per-PR gate (`validate.sh` /
pre-commit) is unchanged. The PR is the human review;
`/land-and-deploy` is a separate manual step. The deterministic worktree / sync /
pr-check / cleanup phases come from `cj-goal-common.sh --mode task`.

## Common pitfalls

- Using it for work that really needs design or investigation — the complexity
  gate HALTs (`[task-too-complex]`) and names the verb to use instead; do not
  fight the gate, switch verbs
- Expecting the PR to merge automatically — it won't; `/ship` Gate #2 is the
  human review and `/land-and-deploy` is a separate manual step
- A task that touches a sensitive surface (catalog, validators, skill dirs) — the
  silent `/CJ_implement-from-spec` subagent halts conservatively (`[impl-red]`)
  rather than mutating in place; scaffold it manually or use `/CJ_goal_feature`
- Re-invoking on a branch with a force-pushed history — resume validates-before-
  skipping; a non-ancestor recorded SHA restarts the affected phase
- Expecting `--no-sync` to also skip the base fast-forward — it does not; only the
  heavy `skills-deploy install` is skipped, Fork-1's local-main ff still runs
- Running it on a non-macOS host — workbench-only

## Related skills

- `/CJ_goal_feature` — sibling verb for feature-sized work (runs `/office-hours`);
  the complexity gate routes design topics here
- `/CJ_goal_defect` — sibling verb for bugs (runs `/investigate`); the gate routes
  bug topics here
- `/CJ_goal_todo_fix` — sibling verb for draining existing `TODOS.md` rows
- `/CJ_implement-from-spec` — silent leaf subagent (Step 3)
- `/CJ_qa-work-item` — silent leaf subagent (Step 4); when orchestrator-driven it
  SKIPS its Step 8.6c/8.6d inline audits (`DEFER_AUDIT: true`) — the agent-judged
  `/CJ_doc_audit` + `/CJ_test_audit` run nightly in CI, not on the build path
  (standalone `/CJ_qa-work-item` still runs them inline)
- `/CJ_document-release` — inline Step 5.5 doc-sync wrapper
- `/ship` (upstream gstack) — inline final step; opens the PR with diff-review AUQ
  suppressed
