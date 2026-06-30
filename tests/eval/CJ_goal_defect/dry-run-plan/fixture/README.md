# Eval fixture: CJ_goal_defect / dry-run-plan

A minimal workspace for the `/CJ_goal_defect --dry-run` eval case. `--dry-run`
prints the planned chain + the write paths and exits before any mutation — no
DRAFT or defect dir is written, no subagents are dispatched, and the gstack
`/investigate` + `/ship` skills are never reached. The harness `git init`s the
seeded tmpdir; nothing else is needed because the dry-run path writes nothing.
