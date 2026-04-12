---
name: docs
description: "Doc intelligence: generate narrative docs (PHILOSOPHY.md, OVERVIEW.md) with a claims sidecar for diff-based staleness detection. Work item validation against templates."
version: 0.3.0
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - AskUserQuestion
---

## Preamble

Log skill usage so `/system-health` can track which skills are actually used:

```bash
mkdir -p ~/.gstack/analytics
echo '{"skill":"docs","ts":"'"$(date -u +%Y-%m-%dT%H:%M:%SZ)"'","repo":"'"$(basename "$(git rev-parse --show-toplevel 2>/dev/null)" 2>/dev/null || echo unknown)"'"}' >> ~/.gstack/analytics/skill-usage.jsonl 2>/dev/null || true
```

Verify this is a git repository:

```bash
git rev-parse --show-toplevel 2>/dev/null || echo "NOT_A_GIT_REPO"
```

If `NOT_A_GIT_REPO`: tell the user "Error: /docs requires a git repository. Run this inside a repo." and stop.

# /docs — Doc Intelligence

Generate narrative documentation with a claims sidecar for diff-based staleness detection.
Three subcommands: init (default), check, and tree.

## Quick Start

```
/docs init                    # Generate PHILOSOPHY.md + .docs/claims.json
# ... make changes to code ...
/docs check                   # Staleness + work item validation + structural completeness
/docs tree                    # Quick hierarchy view with structural badges
/docs init overview           # Generate OVERVIEW.md
```

## What This Is

A "repo memory compiler." Reads the codebase, git history, and existing docs, then
synthesizes a narrative that captures design intent, tradeoffs, and philosophy. The
claims sidecar (`.docs/claims.json`) maps each doc section to its code evidence, so
`/docs check` can tell you exactly which sections went stale after code changes.

This is NOT a post-ship doc updater (that's `/document-release`). This generates the
"why" docs that post-ship updates don't produce.

## Subcommand Routing

Detect the subcommand from the user's input:

- `/docs` or `/docs init [type]` — generate documentation (read init.md and follow it)
- `/docs check` — staleness + coherence + work item validation + structural completeness (read check.md and follow it)
- `/docs tree` — quick hierarchy view with structural badges (read tree.md and follow it)

For each subcommand, read the corresponding .md file in this skill directory
and follow its instructions.
