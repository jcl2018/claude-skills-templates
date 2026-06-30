# Eval fixture: CJ_goal_task / halt-too-complex

A minimal workspace for the `/CJ_goal_task` complexity-gate eval case. The gate
runs in `cj-task-scaffold.sh` BEFORE any work-item is scaffolded, so the fixture
needs no `TODOS.md` row and no `work-items/` tree — just a git-init'd repo (the
harness `git init`s the seeded tmpdir). The topic
("redesign the whole tracker frontmatter schema") names a design-rework signal,
so the gate HALTs with `halted_at_too_complex` and routes to `/CJ_goal_feature`
before reaching any gstack skill.
