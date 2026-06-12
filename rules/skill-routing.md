# Skill Routing

When the user's request matches an available skill, invoke it:

Only top-level pipelines and standalone utilities are listed below. Internal pipeline
steps (scaffold/implement/qa work-item, personal-workflow/company-workflow validators)
are invoked transitively by the orchestrators — do not route to them directly.

- "check installed skills", "skill system health", "skills status" -> /CJ_system-health
- "build a feature", "build this feature end-to-end", "ship a feature end-to-end", "one-line idea to a reviewable PR", "topic to PR", "scaffold + implement + qa from a topic and stop at the PR" -> /CJ_goal_feature "<topic>"
- "do this small task end-to-end", "small ad-hoc cleanup to a PR", "refine a doc / add a file / clean up files / a one-line fix end-to-end", "fix this small thing and stop at the PR" (small + mechanical; NOT a TODOS row, NOT needing design or investigation) -> /CJ_goal_task "<small task>"
- "fix this bug", "fix this bug end-to-end from a description", "bug report to deployed fix", "root-cause and ship a fix", "RCA and deploy" (with or without a pre-existing defect dir) -> /CJ_goal_defect "<bug description>"
- "resume", "pick up where I left off", "what's next on this branch", "continue the in-progress run" -> re-invoke the same verb (`/CJ_goal_feature`, `/CJ_goal_task`, or `/CJ_goal_defect`); each resumes its own in-progress run from its per-branch state file (validate-before-skip)
- "what's next", "what should I work on", "suggest next work item", "top 5 work items" -> /CJ_suggest
- "fix this TODO", "auto-resolve TODOs", "clear the TODO backlog", "ship the next TODO", "close TODOs from TODOS.md", "auto-ship TODOs", "resolve a TODO end-to-end" -> /CJ_goal_todo_fix [<T-ID> | "<fragment>"]
- "fix TODO backlog continuously", "loop through TODOs", "auto-clear TODOs" -> /loop /CJ_goal_todo_fix
- "evaluate this URL", "is this a good Claude pattern", "should we adopt this", "check this Anthropic article", "add this pattern to TODOS" -> /CJ_improve-queue evaluate <url>
- "audit this repo's docs", "check doc hygiene", "does this repo follow its doc contract", "check doc-spec alignment" -> /CJ_doc_audit
- "audit this repo's tests", "are tests aligned with the test spec", "check the test coverage contract", "check test-spec alignment" -> /CJ_test_audit
