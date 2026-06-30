Run `/CJ_goal_feature --dry-run "add a per-repo cache for tracker frontmatter reads"` inside the fixture working directory. `--dry-run` previews the planned chain (worktree → /office-hours → scaffold → implement → qa → doc-sync → audit → portability → /ship) and exits BEFORE any mutation — it writes nothing, spawns no subagents, and never reaches the gstack `/office-hours` or `/ship` skills (the clean gstack-independent path).

Drive the workflow through its preamble + the `--dry-run` chain-plan preview. Determine the end_state it emits and report it as a JSON object with this exact shape:

```json
{
  "end_state": "<end_state>",
  "chain_plan_contains": "<short substring expected to appear in the printed chain plan>"
}
```

The `--dry-run` path emits `dry_run_preview` and prints `DRY RUN:` lines naming the planned worktree + the office-hours/scaffold/implement/qa/ship chain. No writes happen.

**Output only the JSON object.** First non-whitespace character `{`, last `}`. No prose.
