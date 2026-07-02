Run `/CJ_goal_defect --dry-run "the login form throws a 500 on an empty password"` inside the fixture working directory. `--dry-run` previews the planned chain (draft → /investigate → promote → RCA + test-plan → qa → doc-sync → audit → /ship → /land-and-deploy) plus the write paths, and exits BEFORE any mutation — it writes no DRAFT or defect content and never reaches the gstack `/investigate` or `/ship` skills (the clean gstack-independent path).

Drive the workflow through its preamble + the `--dry-run` chain-plan preview. Determine the end_state it emits and report it as a JSON object with this exact shape:

```json
{
  "end_state": "<end_state>",
  "chain_plan_contains": "<short substring expected to appear in the printed chain plan>"
}
```

The `--dry-run` path emits `dry_run_preview` and prints `DRY RUN:` lines naming the draft path + the investigate/promote/RCA/qa/ship chain. No writes happen.

**Output only the JSON object.** First non-whitespace character `{`, last `}`. No prose.
