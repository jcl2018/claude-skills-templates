---
name: work-review
description: "Phase 3: code review wrapper. Loads work item context, writes journal entry, delegates to gstack /review."
allowed-tools:
  - Bash
  - Read
  - Edit
  - Glob
  - Grep
  - Skill
  - AskUserQuestion
---

# /work-review — Phase 3: Code Review

Thin wrapper around gstack `/review`. Adds work item context, journal tracking,
and spec validation gates.

## Step 1: Load context

1. Resolve work item from branch (same as /work router)
2. Read the tracker: name, type, status, current phase
3. Read the doc triplet if it exists (for scoped review context)
4. Get the diff scope:
   ```bash
   BASE=$(git merge-base main HEAD 2>/dev/null || git merge-base master HEAD 2>/dev/null)
   git diff --stat "$BASE"..HEAD 2>/dev/null
   ```

## Step 2: Journal entry

Write to the tracker's Journal section:
```
### {date} — review
Entering review phase. Diff scope: {N files changed, +X/-Y lines}.
```

## Step 3: Handoff block

Write (or update) the handoff block in the tracker:
```
<!-- HANDOFF: phase=review status=in-progress next=/work-ship -->
```

## Step 4: Delegate to /review

Invoke gstack `/review` using the Skill tool:
```
Skill: review
```

The upstream skill handles the actual code review mechanics (diff analysis,
SQL safety, trust boundary violations, structural issues).

## Step 5: Capture outcome

After /review completes, read the review outcome from the conversation.

If /review reports **blocking issues**:
- Write to tracker Journal:
  ```
  ### {date} — review-blocked
  Review found blocking issues: {summary of blockers}
  ```
- Update handoff: `<!-- HANDOFF: phase=review status=blocked next=/work-implement -->`
- Tell user: "Review blocked. Fix the issues, then re-run /work-review."

If /review passes:
- Write to tracker Journal:
  ```
  ### {date} — review-passed
  Review passed. {summary}
  ```
- Mark Phase 3 sub-gates as complete in the Lifecycle section
- Update handoff: `<!-- HANDOFF: phase=review status=complete next=/work-ship -->`
- Tell user: "Review passed. Run /work-ship when ready to land."

## Rules

- **No code modification.** This skill reads code, doesn't change it.
- **Always delegate to /review.** The review logic lives upstream.
- **Journal every review.** Pass or fail, the outcome goes in the tracker.
