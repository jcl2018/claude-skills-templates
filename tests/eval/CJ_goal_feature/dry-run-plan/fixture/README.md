# Eval fixture: CJ_goal_feature / dry-run-plan

A minimal workspace for the `/CJ_goal_feature --dry-run` eval case. `--dry-run`
prints the planned chain and exits before any mutation — no worktree is created,
no subagents are dispatched, and the gstack `/office-hours` + `/ship` skills are
never reached. The harness `git init`s the seeded tmpdir; nothing else is needed
because the dry-run path writes nothing.
