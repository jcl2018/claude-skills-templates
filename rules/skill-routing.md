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

## Deprecated front doors (sunset v6.0.0)

`/CJ_goal_run`, `/CJ_goal_auto`, `/cj_goal_feature`, `/cj_goal_defect`, and
`/CJ_goal_investigate` are thin **DEPRECATED** alias shims (F000027 two-verb
refactor + F000031 casing-fix follow-up + F000027 closure for investigate):
each prints a one-line deprecation banner then routes to a canonical uppercase
verb. `/CJ_goal_run` + `/CJ_goal_auto` route to `/CJ_goal_feature`;
`/cj_goal_feature` + `/cj_goal_defect` (the original F000027 lowercase verbs)
route to `/CJ_goal_feature` + `/CJ_goal_defect` respectively for casing
consistency with the rest of the CJ_* family. `/CJ_goal_investigate` routes to
`/CJ_goal_defect` for non-D-id args; **bare D-id args (`^D[0-9]{6}$`) are
rejected** (forwarding would slug the D-id as a description and mint a new
D-id). To ship a fix for an existing D-id, run the deprecated skill directly
after `skills-deploy install --include-deprecated`.

Do NOT route here for new work — prefer `/CJ_goal_feature` (build a feature) and
`/CJ_goal_defect` (fix a bug). They stay installable via
`skills-deploy install --include-deprecated` so in-flight pipelines can finish;
removal lands at v6.0.0. `/CJ_goal_todo_fix` + `/CJ_personal-pipeline` are NOT
deprecated and are unchanged (`/schedule` + `/loop` integrations unaffected).
