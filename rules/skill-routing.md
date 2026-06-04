# Skill Routing

When the user's request matches an available skill, invoke it:

Only top-level pipelines and standalone utilities are listed below. Internal pipeline
steps (scaffold/implement/qa work-item, personal-workflow/company-workflow validators)
are invoked transitively by the orchestrators — do not route to them directly.

- "check installed skills", "skill system health", "skills status" -> /CJ_system-health
- "build a feature", "build this feature end-to-end", "ship a feature end-to-end", "one-line idea to a reviewable PR", "topic to PR", "scaffold + implement + qa from a topic and stop at the PR" -> /CJ_goal_feature "<topic>"
- "fix this bug", "fix this bug end-to-end from a description", "bug report to deployed fix", "root-cause and ship a fix", "RCA and deploy" (with or without a pre-existing defect dir) -> /CJ_goal_defect "<bug description>"
- "resume", "pick up where I left off", "what's next on this branch", "continue the in-progress run" -> re-invoke the same verb (`/CJ_goal_feature` or `/CJ_goal_defect`); each resumes its own in-progress run from its per-branch state file (validate-before-skip)
- "what's next", "what should I work on", "suggest next work item", "top 5 work items" -> /CJ_suggest
- "fix this TODO", "auto-resolve TODOs", "clear the TODO backlog", "ship the next TODO", "close TODOs from TODOS.md", "auto-ship TODOs", "resolve a TODO end-to-end" -> /CJ_goal_todo_fix [<T-ID> | "<fragment>"]
- "fix TODO backlog continuously", "loop through TODOs", "auto-clear TODOs" -> /loop /CJ_goal_todo_fix
- "evaluate this URL", "is this a good Claude pattern", "should we adopt this", "check this Anthropic article", "add this pattern to TODOS" -> /CJ_improve-queue evaluate <url>
- "set up this repo for the CJ skills", "init repo prerequisites", "make this repo ready for CJ_", "bootstrap repo config", "verify repo prerequisites" -> /CJ_repo-init
