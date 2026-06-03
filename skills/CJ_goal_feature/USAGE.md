---
skill-name: "CJ_goal_feature"
version: 0.1.0
status: experimental
created: "2026-06-01"
last-updated: "2026-06-03T07:19:32Z"
---

# Skill Usage: CJ_goal_feature

## When to use

- "build a feature", "build this feature end-to-end", "ship a feature end-to-end",
  "one-line idea to a reviewable PR", "topic to PR"
- You have a plain feature topic (one-line) and want a reviewable PR at the end
- Resume: re-invoking the same verb on the same branch picks up where you left off
  (state file records `last_completed_phase` + per-phase HEAD SHA + PR number;
  validates-before-skipping)
- `--dry-run` previews the chain plan without mutation

## When NOT to use

- The work is a bug, not a feature — use `/CJ_goal_defect`
- The work is already tracked as a TODOS.md row — use `/CJ_goal_todo_fix`
- You want auto-merge after PR — not supported by design; the handoff-gate
  denylist makes auto-merge unsafe-by-construction; PR-stop is correct here
- You want plan review or eng/CEO/design review — those are separate gstack
  skills; this orchestrator is build-end-to-end-to-PR, not plan-review

## Mental model

One interactive phase (`/office-hours` inline, emits APPROVED design doc) then
silent leaf subagents (scaffold → implement → QA), then `/CJ_document-release`
(Step 5.5 doc-sync) inline, then `/ship` inline (with
diff-review AUQ suppressed) → STOPS at the open PR. The PR is the architecture
gate (human review). Worktree-on-main creates `cj-feat-*` worktree
automatically. Halt taxonomy: `green_pr_opened`, `halted_at_*`,
`already_shipped` with `next_action=` / `resume_cmd=` / `pr_url=` journal
entries.

## Common pitfalls

- Expecting the PR to merge automatically — it won't; `/ship` Gate #2 is human,
  and `/land-and-deploy` is a separate manual step here
- Abandoning the /office-hours phase (not APPROVED) and expecting the chain to
  proceed — it HALTs by design
- Re-invoking on a branch with a force-pushed history — resume validates-before-
  skipping; if the recorded SHA isn't ancestor-of current HEAD, the affected
  phase restarts
- Running it on a non-macOS host — workbench-only

## Related skills

- `/office-hours` (upstream gstack) — the one interactive phase
- `/CJ_scaffold-work-item` — silent leaf subagent (Phase 3.1)
- `/CJ_implement-from-spec` — silent leaf subagent (Phase 3.2)
- `/CJ_qa-work-item` — silent leaf subagent (Phase 3.3)
- `/ship` (upstream gstack) — inline final step; opens PR with diff-review AUQ
- `/CJ_goal_defect` — sibling top-level verb for bug-from-description
- `/CJ_goal_todo_fix` — sibling top-level verb for TODOS.md drains
