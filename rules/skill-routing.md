# Skill Routing

When the user's request matches an available skill, invoke it:

Only top-level pipelines and standalone utilities are listed below. Internal pipeline
steps (scaffold/implement/qa work-item, personal-workflow/company-workflow validators)
are invoked transitively by the orchestrators — do not route to them directly.

- "check installed skills", "skill system health", "skills status" -> /CJ_system-health
- "build a feature", "build this feature end-to-end", "ship a feature end-to-end", "one-line idea to a reviewable PR", "topic to PR", "scaffold + implement + qa from a topic and stop at the PR" -> /cj_goal_feature "<topic>"
- "fix this bug", "fix this bug end-to-end from a description", "bug report to deployed fix", "root-cause and ship a fix", "RCA and deploy" (no pre-existing defect dir) -> /cj_goal_defect "<bug description>"
- "ship a fix for D000NNN", "investigate to ship an existing/scaffolded defect" -> /CJ_goal_investigate <D-id|fragment>
- "resume", "pick up where I left off", "what's next on this branch", "continue the in-progress run" -> re-invoke the same verb (`/cj_goal_feature` or `/cj_goal_defect`); each resumes its own in-progress run from its per-branch state file (validate-before-skip)
- "what's next", "what should I work on", "suggest next work item", "top 5 work items" -> /CJ_suggest
- "fix this TODO", "auto-resolve TODOs", "clear the TODO backlog", "ship the next TODO", "close TODOs from TODOS.md", "auto-ship TODOs", "resolve a TODO end-to-end" -> /CJ_goal_todo_fix [<T-ID> | "<fragment>"]
- "fix TODO backlog continuously", "loop through TODOs", "auto-clear TODOs" -> /loop /CJ_goal_todo_fix
- "evaluate this URL", "is this a good Claude pattern", "should we adopt this", "check this Anthropic article", "add this pattern to TODOS" -> /CJ_improve-queue evaluate <url>

## Deprecated front doors (sunset v6.0.0)

`/CJ_goal_run` and `/CJ_goal_auto` are thin **DEPRECATED** alias shims (F000027 two-verb
refactor): each prints a one-line deprecation banner then routes to `/cj_goal_feature`.
Do NOT route here for new work — prefer `/cj_goal_feature` (build a feature) and
`/cj_goal_defect` (fix a bug). They stay installable via
`skills-deploy install --include-deprecated` so in-flight pipelines can finish; removal
lands at v6.0.0. `/CJ_goal_todo_fix` + `/CJ_personal-pipeline` are NOT deprecated and are
unchanged (`/schedule` + `/loop` integrations unaffected).
