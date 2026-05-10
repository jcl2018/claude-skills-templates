# Review Notes Generation Guide

How to pre-populate review notes from the template.

## When to generate

When a standalone review work item is created via `the work-track create command --type review`.

**Note:** This is for standalone code reviews (reviewing someone else's PR or branch).
For phase reviews (reviewing your own work item's changes), use `/work-review` which
wraps `/review` and writes to the existing work item's journal.

## Sources

1. **Git diff** — the primary input. Read the diff for the specified PR, branch,
   or commit range. Run structured analysis.
2. **PR description** — if a PR URL is provided, extract the PR title and description
   for context on what the change intends.
3. **User input** — the reviewer may specify focus areas ("look at security",
   "check performance", "review the API changes only").

## Steps

### 1. Fill frontmatter

- `parent`: from the work item's `id` field
- `title`: from the PR title or branch name + " — Code Review Notes"
- `pr`: PR URL or number (if provided)
- `branch`: branch name (if provided)
- `commit`: commit hash or range
- `date`: today
- `reviewer`: current user
- `verdict`: "Pending" (updated after review)

### 2. Review Metadata

Compute from the diff:
```bash
git diff --stat {base}..{head}
```
Extract file count and line counts.

### 3. Findings

Analyze the diff systematically by category:
- **Correctness:** logic errors, null handling, off-by-one, race conditions
- **Performance:** N+1 patterns, unnecessary allocations, missing caching
- **Security:** input validation, injection risks, auth gaps
- **Style:** naming, formatting, dead code, unclear intent
- **Maintainability:** DRY violations, missing tests, unclear abstractions

For each finding:
- Specify the exact file:line
- Describe the problem concretely
- Recommend a specific fix (not "consider improving")

Assign severity:
- **Critical:** blocks merge, would cause bugs or security issues in production
- **Major:** should fix before merge, significant quality concern
- **Minor:** optional fix, code is correct but could be better
- **Note:** informational, no action required

### 4. Sections to leave blank for human input

- **Follow-Up Actions** — assigned during or after review discussion
- **Verdict** — set after the reviewer evaluates all findings

## Offline requirement

All generation uses local git repos. No network access required for diff analysis.
PR descriptions require network only if the PR is on a remote system.
