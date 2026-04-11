---
name: docs
type: skill-design
date: 2026-04-11
---

# Design: /docs — Doc Intelligence Skill

## Problem

No tool generates the "why" documentation. `/document-release` updates post-ship.
But neither it nor CLAUDE.md validation rules can look at a repo with zero philosophy
docs and produce a narrative that captures design intent, tradeoffs, and rationale.

Primary audience: future-self. Coming back to a repo in 6 months and needing to remember
why decisions were made.

## Approach

Two subcommands:
- `init` — reads codebase, git history, existing docs, synthesizes PHILOSOPHY.md or OVERVIEW.md
- `check` — reads `.docs/claims.json` sidecar, detects staleness via `git diff`, runs mechanical coherence checks

The claims sidecar maps each doc section to evidence files with commit SHAs.
Staleness is `git diff <stored-sha>..HEAD -- <evidence-path>`. Precise. No timestamps.

## Key Decisions

1. **init+check only, no enforce/sync** — /docs focuses on narrative generation. Format enforcement moved to CLAUDE.md validation rules (formerly /contracts).
2. **File-level evidence, not line-level** — Line-level is too brittle. Any edit triggers false positives.
3. **Flag-only staleness** — No auto-regeneration. Philosophy docs need the user's voice.
4. **claims.json in repo root** — `.docs/claims.json` committed to git. Only option for portability.
5. **Re-run skips content generation** — When doc already exists, only update claims.json. Avoids LLM nondeterminism overwriting human edits.

## Design Doc

Full design at: `~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-worktree-new-skill-design-20260411-000803.md`
