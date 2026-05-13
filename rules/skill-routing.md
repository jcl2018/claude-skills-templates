# Skill Routing

When the user's request matches an available skill, invoke it:

Only top-level pipelines and standalone utilities are listed below. Internal pipeline
steps (scaffold/implement/qa work-item, personal-workflow/company-workflow validators)
are invoked transitively by the orchestrators — do not route to them directly.

- "check installed skills", "skill system health", "skills status" -> /CJ_system-health
- "ship feature", "ship the whole feature", "design doc to production", "end-to-end ship", "full pipeline from design" -> /CJ_ship-feature
- "ship the whole pipeline", "run personal pipeline", "scaffold + implement + qa from a design doc", "auto pipeline", "fire and forget pipeline" -> /CJ_personal-pipeline (v1.16.0+: auto-decision is the only mode; legacy `--auto` flag accepted as silent no-op for backwards compat)
- "what's next", "what should I work on", "suggest next work item", "top 5 work items" -> /CJ_suggest
