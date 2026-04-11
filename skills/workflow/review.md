# review — Phase 3: Code Review

Subcommand of /workflow. Runs a doc contract quality gate, then delegates to
gstack /review for the actual code review.

Shared context (branch, work item, phase) is already resolved by SKILL.md.

## Step 1: Load context

1. Read tracker: name, type, status, current phase
2. Read doc triplet if it exists (for scoped review context)
3. Get diff scope:
   ```bash
   BASE=$(git merge-base main HEAD 2>/dev/null || git merge-base master HEAD 2>/dev/null)
   git diff --stat "$BASE"..HEAD 2>/dev/null
   ```

## Step 2: Contract Quality Gate

Before code review, check doc contracts via the /contracts skill.

### Check if contracts skill exists
```bash
SKILL_DIR=$(git rev-parse --show-toplevel 2>/dev/null)/skills/contracts
[ -f "$SKILL_DIR/SKILL.md" ] && echo "CONTRACTS_AVAILABLE" || echo "CONTRACTS_MISSING"
```

### Failure mode A: Contracts skill missing
- Log: "WARN: /contracts skill not found. Skipping contract quality gate."
- Write journal: `### {date} -- review-gate\nContract gate skipped: skill not installed.`
- Proceed to Step 3.

### Failure mode B: Contract check finds failures
- Invoke /contracts check on the work item directory using the Skill tool:
  ```
  Skill: contracts, args: "check {work_item_dir}"
  ```
- If check returns FAIL findings:
  - Display failures to user
  - Ask via AskUserQuestion: "Contract check found {N} failures. Override and continue review? [y/N]"
  - If override: log to journal `### {date} -- review-gate\nContract gate: {N} failures overridden by user.`
  - If not override: log `### {date} -- review-gate\nContract gate: blocked. {N} failures.` and stop.
- If check passes: log `### {date} -- review-gate\nContract gate passed.`

## Step 3: Journal entry

Write to tracker Journal:
```
### {date} -- review
Entering review phase. Diff scope: {N files changed, +X/-Y lines}.
```

## Step 4: Write handoff

Update handoff block:
```
<!-- HANDOFF: phase=review status=in-progress next=/workflow ship -->
```

## Step 5: Delegate to gstack /review

Invoke gstack /review using the Skill tool:
```
Skill: review
```

The upstream skill handles diff analysis, SQL safety, trust boundary violations,
and structural issue detection.

## Step 6: Capture outcome

After /review completes, read the review outcome.

### If blocked
- Journal: `### {date} -- review-blocked\nReview found blocking issues: {summary}`
- Handoff: `<!-- HANDOFF: phase=review status=blocked next=/workflow implement -->`
- Tell user: "Review blocked. Fix issues, then re-run `/workflow review`."

### If passed
- Journal: `### {date} -- review-passed\nReview passed. {summary}`
- Mark Phase 3 sub-gates as complete in Lifecycle
- Handoff: `<!-- HANDOFF: phase=review status=complete next=/workflow ship -->`
- Tell user: "Review passed. Run `/workflow ship` when ready."

## Rules

- **Contract gate runs first.** Before any code review, check contracts.
- **Two failure modes.** Missing skill = warn + skip. Check failures = warn + prompt override.
- **No code modification.** This subcommand reads code, does not change it.
- **Always delegate to /review.** The review logic lives upstream in gstack.
- **Journal every review.** Pass or fail, the outcome goes in the tracker.
