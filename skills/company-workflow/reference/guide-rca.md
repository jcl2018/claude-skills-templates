# RCA Generation Guide

How to pre-populate a Root Cause Analysis from the template.

## When to generate

When a new defect work item is created via `the work-track create command --type defect`.
Also useful mid-investigation: run generation again to synthesize findings so far.

## Sources (in priority order)

1. **Work item journal** — `finding` entries contain investigation hypotheses
   and evidence. `decision` entries contain fix choices. Map these to the
   Investigation Trail table.
2. **Git log** — commits on the defect branch tell the investigation story.
   Extract commit messages as investigation trail entries.
3. **Git diff** — the actual code changes reveal what was fixed. Summarize
   into Fix Description and Affected Components.
4. **User-provided description** — from the create command or defect ticket.

## Steps

### 1. Fill frontmatter

- `parent`: from the work item's `id` field
- `title`: from the work item's `name` field + " — Root Cause Analysis"
- `date`: today
- `author`: current user
- `severity`: from the work item's lifecycle (if set)

### 2. Symptom

Extract from:
- Defect ticket description (if URL provided and accessible)
- User's natural language input during create
- Work item's `## Insights` section

### 3. Investigation Trail

Build from git log + journal entries:

```bash
# Get commits on the defect branch since creation
git log --oneline --since={created_date} {branch}
```

Map each commit to an investigation trail entry:
- Timestamp from commit date
- Action from commit message
- Finding from the diff summary

Add journal `finding` entries as additional trail rows.

### 4. Root Cause + Fix + Affected Components

If the investigation is complete (journal has a confirmed finding):
- Extract root cause from the confirmed hypothesis
- Extract fix from the git diff summary
- Extract affected components from changed file paths

If investigation is still in progress:
- Leave Root Cause as "Under investigation"
- Leave Fix Description empty
- Populate Affected Components from files already touched

### 5. Sections to leave blank for human input

- **Reproduction Steps** — often requires domain-specific setup
- **Regression Risk** — requires judgment about blast radius

## Offline requirement

All generation uses local git repos and work item files. No network access required.
