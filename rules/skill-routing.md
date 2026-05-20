# Skill Routing

When the user's request matches an available skill, invoke it:

Only top-level pipelines and standalone utilities are listed below. Internal pipeline
steps (scaffold/implement/qa work-item, personal-workflow/company-workflow validators)
are invoked transitively by the orchestrators — do not route to them directly.

- "check installed skills", "skill system health", "skills status" -> /CJ_system-health
- "ship feature", "ship the whole feature", "design doc to production", "end-to-end ship", "full pipeline from design", "ship the whole pipeline", "run personal pipeline", "scaffold + implement + qa from a design doc", "auto pipeline", "fire and forget pipeline" -> /CJ_goal_run <design-doc-path>
- "resume work-item", "continue work-item", "what's left on this work-item", "finish this work-item" -> /CJ_goal_run <work-item-dir> (NOTE: Branch(f) phase-detection placeholder until S000039 lands; prints next-step guidance and exits)
- "resume current branch", "what's next on this branch", "auto resume", "pick up where I left off" -> /CJ_goal_run (no args; Branch(g) scans for in-progress user-stories and hands off to Branch(f) — see note above)
- "what's next", "what should I work on", "suggest next work item", "top 5 work items" -> /CJ_suggest
- "fix this TODO", "auto-resolve TODOs", "clear the TODO backlog", "ship the next TODO", "close TODOs from TODOS.md", "auto-ship TODOs", "resolve a TODO end-to-end" -> /CJ_goal_todo_fix [<T-ID> | "<fragment>"]
- "fix TODO backlog continuously", "loop through TODOs", "auto-clear TODOs" -> /loop /CJ_goal_todo_fix
- "evaluate this URL", "is this a good Claude pattern", "should we adopt this", "check this Anthropic article", "add this pattern to TODOS" -> /CJ_improve-queue evaluate <url>
- "investigate this defect", "debug this defect", "ship a fix for D000NNN", "root-cause and ship", "fix this bug end-to-end", "investigate to ship", "RCA and deploy" -> /CJ_goal_investigate <D-id|fragment>
- "fire and forget small change", "one-liner to deployed", "auto-ship this small idea", "handoff this small change", "ship this small idea end-to-end" -> /CJ_goal_auto "<idea>"  (default human-gated at GATE #2; add --auto-merge-small-diffs for opt-in auto-merge; --dry-run for zero-write preview; --audit for read-only receipt history)
