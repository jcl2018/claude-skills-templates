---
name: work-implement
description: "Structured implementation with root-cause debugging. Dual-mode: build-forward (features/tasks) or debug-backward (defects)."
version: 0.1.0
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - AskUserQuestion
  - Agent
---

# /work-implement — Phase 2: Implementation

Dual-mode implementation skill. Auto-detects mode from the work item's type field.

## Context Loading

1. Resolve the work item from the current branch (same pattern as /work router)
2. Read the tracker's frontmatter to get: type, name, status
3. Read the tracker's Acceptance Criteria section
4. Check for doc triplet (PRD.md, ARCHITECTURE.md, TEST-SPEC.md) in the work item directory
5. Check for additional artifacts: milestones.md (features/user-stories), test-plan.md (defects/tasks), review-notes.md (reviews)

## Mode Detection

Based on the tracker's `type` frontmatter:
- `feature`, `task`, `user-story` → **Build-forward mode**
- `defect` → **Debug-backward mode**

## Build-Forward Mode (features, tasks, user-stories)

### Step 1: Read the plan

If a doc triplet exists (PRD + ARCHITECTURE + TEST-SPEC):
- Read all three docs
- Extract: user stories (from PRD), component list (from ARCHITECTURE), test cases (from TEST-SPEC)
- Summarize the implementation scope

If no triplet exists but the tracker has Acceptance Criteria:
- Use the AC as the implementation guide

If neither exists:
- Ask the user: "No doc triplet or acceptance criteria found. Describe what you want to build."

### Step 2: Draft implementation plan

Present a plan via AskUserQuestion:
```
Implementation Plan for: {name}

Files to create/modify:
1. {file} — {what changes}
2. {file} — {what changes}

Approach: {one paragraph summary}

Estimated scope: {S/M/L}
```

Options: A) Approve and start  B) Revise the plan  C) Cancel

### Step 3: Execute

For each planned change:
1. Write or edit the file
2. Run relevant tests if they exist
3. Log progress to the tracker's Journal section:
   ```
   ### {date} — implementation
   Implemented: {what was done}. Commit: {SHA if committed}
   ```

### Step 4: Verify

After implementation is complete:
- Run any test commands from TEST-SPEC Tier 1 (smoke tests)
- Check the Acceptance Criteria against the current state
- Update the tracker: mark Phase 2 sub-gates as complete
- Write handoff block:
  ```
  <!-- HANDOFF: phase=implement status=complete next=/work-review -->
  ```

## Debug-Backward Mode (defects)

### Step 1: Collect symptoms

Read the RCA.md in the work item directory. If it has a Symptom section, use it.
If not, ask the user:
- "What's the error or incorrect behavior you're seeing?"
- "How do you reproduce it?"
- "When did it start (commit, date, or event)?"

Write symptoms to RCA.md Symptom section.

### Step 2: Form hypotheses

Based on symptoms, form 3 hypotheses:
```
H1: {hypothesis} — Predicted evidence: {what you'd find if true}
H2: {hypothesis} — Predicted evidence: {what you'd find if true}
H3: {hypothesis} — Predicted evidence: {what you'd find if true}
```

Present via AskUserQuestion: "Here are my hypotheses. Should I investigate H1 first?"

### Step 3: Test hypotheses systematically

For each hypothesis:
1. Search for predicted evidence (grep, read files, run commands)
2. Log the investigation to RCA.md Investigation Trail:
   ```
   | {time} | Tested H{n}: {description} | {what was found} |
   ```
3. Verdict: CONFIRMED (evidence matches prediction) or DISPROVED (evidence contradicts)

**3-strike rule:** After 3 DISPROVED hypotheses (with contradicting evidence, not mere
user disagreement), stop and ask: "Three hypotheses disproved. Want to escalate, or
should I form new hypotheses with a different approach?"

### Step 4: Root cause and fix

Once a hypothesis is confirmed:
1. Write the Root Cause section in RCA.md
2. Propose a fix via AskUserQuestion:
   ```
   Root cause: {statement}
   Location: {file:line}
   
   Proposed fix: {description}
   ```
3. **Root-cause-before-fix gate:** The fix must address the stated root cause.
   If it doesn't, stop and explain the mismatch.
4. Implement the fix with user approval
5. Update the tracker: mark Phase 2 sub-gates as complete
6. Write handoff block:
   ```
   <!-- HANDOFF: phase=implement status=complete next=/work-review -->
   ```

## Rules

- **No code modification without approval.** Always present the plan or fix before executing.
- **Root cause before fix (defects).** Never fix without identifying root cause first.
- **3-strike escalation.** After 3 disproved hypotheses, stop and ask.
- **Journal everything.** Every significant action gets a journal entry in the tracker.
- **Evidence-based verdicts.** Hypothesis verdicts must cite specific evidence, not "it seemed like."
