---
skill-name: "CJ_implement-from-spec"
version: 1.0.0
status: experimental
created: "2026-06-01"
last-updated: "2026-06-06T03:46:08Z"
---

# Skill Usage: CJ_implement-from-spec

## When to use

- "implement this work-item", "write the code for this spec"
- A scaffolded work-item exists with the per-type spec already on disk
  (SPEC+DESIGN for user-stories, RCA+test-plan for defects, TRACKER+test-plan
  for tasks)
- An orchestrator (`/CJ_goal_feature`, `/CJ_goal_todo_fix`) is delegating
  the implementation phase as a leaf subagent
- Trivial 1-2 file changes: pass `--auto` to skip the propose-and-confirm AUQ

## When NOT to use

- Phase 1 is incomplete or the work-item dir isn't scaffolded yet — run
  `/CJ_scaffold-work-item` first
- The work-item is a feature (parent-only) — features delegate to a child
  user-story via AUQ; route to the child instead
- The change touches sensitive surfaces (catalog, manifest, validator) and you
  want it to skip the gate — the sensitive-surface AUQ fires regardless of
  `--auto`; that gate is intentional
- You want tests run after the code lands — that's `/CJ_qa-work-item`

## Mental model

Read the per-type input artifacts; plan against the SPEC's "Components Affected"
+ "Data Flow" sections; write code via Read/Edit/Write; commit nothing (the
commit happens at `/ship`). Propose-and-confirm by default (per-file AUQ);
`--auto` collapses the AUQ for trivial ≤2-file changes. Idempotent — re-running
on an already-implemented work-item is NO-OP-shaped.

## Common pitfalls

- Skipping the Components Affected / Data Flow read — the skill plans against
  them; thin SPECs produce thin implementations
- Calling `--auto` on a multi-file or sensitive-surface change — the AUQ still
  fires for sensitive surfaces; the flag is for trivial edits only
- Forgetting that the skill does not commit — Phase 2 ends with uncommitted
  diff; `/ship` is the next step (this is the cause of the task-type QA halt
  pattern documented in memory)
- Calling it as a top-level skill when the operator just had a topic — route
  via `/CJ_goal_feature` so scaffold runs first

## Related skills

- `/CJ_scaffold-work-item` — upstream phase: produces the work-item tree
- `/CJ_qa-work-item` — downstream phase: tests what this skill writes
- `/CJ_goal_feature` + `/CJ_goal_todo_fix` — top-level orchestrators that call
  this skill as a leaf subagent (impl→qa flatten)
- `/CJ_personal-workflow` — runs at boundaries to confirm structural shape
