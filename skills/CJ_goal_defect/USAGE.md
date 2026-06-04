---
skill-name: "CJ_goal_defect"
version: 0.1.0
status: experimental
created: "2026-06-01"
last-updated: "2026-06-03T22:15:00Z"
---

# Skill Usage: CJ_goal_defect

## When to use

- "fix this bug", "fix this bug end-to-end from a description", "bug report to
  deployed fix", "root-cause and ship a fix", "RCA and deploy"
- You have a plain bug description (no pre-existing defect dir required)
- Resume: re-invoking the same verb on the same branch picks up where you left off
- `--dry-run` previews the chain plan + write paths without mutation

## When NOT to use

- The work is a feature, not a bug — use `/CJ_goal_feature`
- You only want to root-cause without shipping — call `/investigate` directly
  (this orchestrator ships the fix after RCA passes)
- The Iron-Law `/investigate` gate returns no root cause — the orchestrator
  HALTs (nothing promoted, nothing shipped); fix the investigation first
- You're a non-macOS host — workbench-only

## Mental model

A 4-step chain: throwaway `.inbox/<slug>/DRAFT.md` scratchpad → `/investigate`
as Agent subagent (Iron-Law: no RCA ⇒ HALT) → on populated RCA, write
RCA+test-plan and promote draft to a canonical
`work-items/defects/uncategorized/D000NNN_<slug>/` dir (D-ID minted ONLY after
the Iron-Law gate passes) → `/CJ_qa-work-item` leaf subagent →
`/CJ_document-release` (Step 5.5 doc-sync) → `/ship` (Gate
#2 always human) → `/land-and-deploy --suppress-readiness-gate`. A ~80%
reshape of the retired `/CJ_goal_investigate` v1.1 pipeline; depth ≤ 2 (no
subagent-spawns-subagent).

## Common pitfalls

- Trying to resume an existing D-id work-item — this orchestrator is
  start-from-scratch; the retired `/CJ_goal_investigate` was the resume-by-D-id
  path and is now a rejection-on-D-id shim
- Expecting D-ID to be minted before RCA — by design, the D-ID is minted ONLY
  after Iron-Law passes; failed investigations leave nothing behind
- Running it inside a subagent — depth-≤2 ceiling; the orchestrator must be
  top-level
- Skipping the bug-description and just running the skill — needs a description
  arg to seed the `.inbox/<slug>/DRAFT.md`

## Related skills

- `/investigate` (upstream gstack) — Iron-Law root-cause analysis subagent
- `/CJ_qa-work-item` — leaf subagent that runs the test-plan rows
- `/ship` (upstream gstack) — opens PR with Gate #2
- `/land-and-deploy` (upstream gstack) — merges and verifies deploy
- `/CJ_goal_feature` — sibling top-level verb for feature-from-topic
- `/CJ_goal_todo_fix` — sibling top-level verb for TODOS.md drains
