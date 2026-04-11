# implement — Phase 2: Implementation

Subcommand of /workflow. Dual-mode: build-forward for features/tasks,
debug-backward for defects. Auto-detects mode from work item type.

Shared context (branch, work item, phase) is already resolved by SKILL.md.

## Context Loading

1. Read tracker frontmatter: type, name, status
2. Read Acceptance Criteria section from tracker
3. Check for doc triplet (PRD.md, ARCHITECTURE.md, TEST-SPEC.md) in work item directory
4. Check for additional artifacts: milestones.md, test-plan.md, review-notes.md, RCA.md

## Mode Detection

From tracker `type` frontmatter:
- `feature`, `task`, `user-story` -> **Build-forward mode**
- `defect` -> **Debug-backward mode**

## Build-Forward Mode

### Step 1: Read the plan

If doc triplet exists:
- Read PRD, ARCHITECTURE, TEST-SPEC
- Extract: user stories (PRD), component list (ARCHITECTURE), test cases (TEST-SPEC)
- Summarize implementation scope

If no triplet but tracker has Acceptance Criteria:
- Use AC as implementation guide

If neither:
- Ask: "No doc triplet or acceptance criteria found. Describe what to build."

### Step 2: Draft implementation plan

Present via AskUserQuestion:
```
Implementation Plan for: {name}

Files to create/modify:
1. {file} -- {what changes}
2. {file} -- {what changes}

Approach: {one paragraph summary}
Estimated scope: {S/M/L}
```
Options: A) Approve and start  B) Revise  C) Cancel

### Step 3: Execute

For each planned change:
1. Write or edit the file
2. Run relevant tests if they exist
3. Log to Journal: `### {date} -- implementation\nImplemented: {what}. Commit: {SHA}`

### Step 4: Verify

After implementation:
- Run TEST-SPEC Tier 1 smoke test commands if specified
- Check Acceptance Criteria against current state
- Mark Phase 2 sub-gates as complete in Lifecycle
- Write handoff: `<!-- HANDOFF: phase=implement status=complete next=/workflow review -->`

## Debug-Backward Mode

### Step 1: Collect symptoms

Read RCA.md Symptom section if it exists. Otherwise ask:
- "What error or incorrect behavior are you seeing?"
- "How do you reproduce it?"
- "When did it start (commit, date, or event)?"

Write symptoms to RCA.md.

### Step 2: Form hypotheses

Form 3 hypotheses:
```
H1: {hypothesis} -- Predicted evidence: {what you'd find if true}
H2: {hypothesis} -- Predicted evidence: {what you'd find if true}
H3: {hypothesis} -- Predicted evidence: {what you'd find if true}
```

Present via AskUserQuestion: "Here are my hypotheses. Investigate H1 first?"

### Step 3: Test systematically

For each hypothesis:
1. Search for predicted evidence (grep, read, run commands)
2. Log to RCA.md Investigation Trail: `| {time} | Tested H{n}: {desc} | {found} |`
3. Verdict: CONFIRMED or DISPROVED (must cite specific evidence)

**3-strike rule:** After 3 DISPROVED hypotheses with contradicting evidence, stop:
"Three hypotheses disproved. Escalate or form new hypotheses with different approach?"

### Step 4: Root cause and fix

Once confirmed:
1. Write Root Cause section in RCA.md
2. Propose fix via AskUserQuestion:
   ```
   Root cause: {statement}
   Location: {file:line}
   Proposed fix: {description}
   ```
3. **Root-cause-before-fix gate:** Fix must address the stated root cause. If mismatch, stop and explain.
4. Implement with user approval
5. Mark Phase 2 sub-gates complete
6. Write handoff: `<!-- HANDOFF: phase=implement status=complete next=/workflow review -->`

## Rules

- **No code modification without approval.** Always present plan or fix first.
- **Root cause before fix (defects).** Never fix without identifying root cause.
- **3-strike escalation.** Stop after 3 disproved hypotheses.
- **Journal everything.** Every action gets a journal entry.
- **Evidence-based verdicts.** Cite specific evidence, not "it seemed like."
