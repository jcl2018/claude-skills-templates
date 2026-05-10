# Scrum Doc Generation Guide

How to pre-populate a new scrum doc from the template.
This guide is the reference document; the work scrum command integrates these steps
into the skill command.

## When to generate

Before each scheduled meeting. Check `next_meeting` in the most recent scrum doc
inside `{feature-dir}/scrums/`.

## Steps

### 1. Find the previous scrum doc and feature item

Look in `{feature-dir}/scrums/` for the most recent file by date.
Read the feature work item (`{feature-dir}/{FEATURE_ID}-*.md`) to get `repos:`,
`branches:`, `children:`, and `contributors:` fields.

**Cold start (first meeting):** If no previous scrum doc exists, set `prev_scrum`
to empty. Skip action item carry-forward.

**Additional edge cases:**
- If milestones.md doesn't exist yet, show "Milestones: Not yet created" and skip
  the milestones snapshot.
- If milestones table has zero rows, leave the milestones section empty with a note.
- If prev_scrum points to a deleted/renamed file, warn and proceed without carry-forward.

### 2. Review milestone status

- Read milestones.md to understand current state
- Note which milestones changed since last meeting (for Progress table)

### 3. Pull git activity

Resolve repos from the feature work item's `repos:` field and `branches:` field.
For each repo, prefer branch-specific log over `--all` (faster, less noise):

```bash
# Primary: scan tracked branches (from feature's branches: field)
git log --oneline --since={prev_meeting_date} {branch_name}

# Fallback: scan by work item ID in commit messages (catches untracked branches)
git log --oneline --since={prev_meeting_date} --extended-regexp \
  --grep="{FEATURE_ID}|{CHILD_ID_1}|{CHILD_ID_2}"
```

**Note:** This depends on commit messages containing work item IDs. Commits without
IDs and not on tracked branches will not appear in the Progress table. Recommended
commit message convention: `{ID}: description` (e.g., `T12345: refactor data layer`).

Group by milestone/task. Summarize into Progress table rows.

### 3.5. Pull journal entries

Read the `## Journal` section of each work item (feature item and children).
If no `## Journal` section exists, skip this step silently.

Extract entries since the previous meeting date. For each entry:
- Auto-generate a scrum-ready one-liner from the **Summary** field
- `decision` entries → add to the **Decisions** table
- `finding` entries → add to the **Discussion** section
- `blocker` entries → add to **Risk Flags**
- All entries → add the auto-generated bullet to the **Progress** table

If a journal entry is malformed (missing type header or Summary), skip it and warn.

### 4. Pull PR status

Read the feature item's `## PRs` section for manually-registered PRs.
Check branches listed in the feature's `branches:` field for recent activity.

PR status is read from the feature item's manually-maintained section —
no external tooling (gh CLI) is required. Contributors update this section
when PRs are created or merged.

### 5. Carry forward action items

Read previous scrum's Action Items table. Any item with Status != Done gets copied
to the new doc with `(carried since {original_date})` tag, where `original_date` is
the date the action was first created. If first meeting (no prev_scrum), skip this step.

Items carried 3+ times should auto-generate a MEDIUM risk flag:
`MEDIUM: Action item '{action}' has been carried since {date} (N meetings).`

### 6. Detect risks

- Milestone past target date → **HIGH** risk
- Branch with no commits in 7+ days → **MEDIUM** risk
- Milestone #N not started but dependent milestones done → **MEDIUM** risk
- Action item carried 3+ meetings → **MEDIUM** risk
- Milestone has no target date → **LOW** risk

### 7. Create the doc

Copy `scrum-TEMPLATE.md` to `{feature-dir}/scrums/scrum-{YYYY-MM-DD}.md`.
Fill in all fields. Leave Discussion and Decisions sections empty (filled during meeting).

### 7.5 Validate the generated doc

After generation, verify:

- [ ] Milestone count in scrum matches milestone count in milestones.md
- [ ] All child IDs from the feature item appear in Progress or Milestones table
- [ ] prev_scrum file exists and is readable (if specified)
- [ ] No empty tables (at minimum, milestones table should have rows)

If validation fails, flag the issue before the meeting rather than presenting
a broken document.

### 8. Post-meeting sync (run after the meeting)

Compare the scrum doc's milestones table to milestones.md. Sync these fields ONLY:
- **Status** (the most common change during meetings)
- **Target Date** (may be revised during discussion)
- **Owner** (may be reassigned)

**Direction:** scrum doc → milestones.md (never the reverse). The scrum doc reflects
the meeting's decisions, so it is the source of truth during this step.

**Date conversion:** Convert scrum's MM/DD format back to milestones.md's YYYY-MM-DD.
For cross-year milestones (e.g., 01/15 in a December meeting), use the next calendar year.

**New/deleted milestones:** Do NOT sync. Adding or removing milestones requires
manual editing of milestones.md (including updating the dependency graph).

**Conflict handling:** If milestones.md was updated directly between meetings and
conflicts with the scrum snapshot, show the diff to the user and ask which version
to keep. Default: the more recent update wins.

Also update the feature work item's `updated:` timestamp.
