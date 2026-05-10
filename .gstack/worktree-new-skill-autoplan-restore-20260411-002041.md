# /autoplan Restore Point
Captured: 2026-04-11T00:20:41Z | Branch: worktree-new-skill | Commit: 949ed38

## Re-run Instructions
1. Copy "Original Plan State" below back to your plan file
2. Invoke /autoplan

## Original Plan State
# Plan: Build /docs — Full Doc Intelligence Skill

## Context

Building a new Claude Code skill (`/docs`) for the claude-skills-templates repo. This skill generates narrative documentation (PHILOSOPHY.md, OVERVIEW.md), detects doc staleness via a claims sidecar, absorbs `/contracts` template enforcement, and composes with gstack's `/document-release` for post-ship updates.

Design doc: `~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-worktree-new-skill-design-20260411-000803.md` (APPROVED)

## Skill Structure

```
skills/docs/
  SKILL.md           # Router + preamble + subcommand dispatch
  init.md            # Generate docs from scratch (PHILOSOPHY.md, OVERVIEW.md)
  check.md           # Coherence checking + staleness detection
  enforce.md         # Absorbed contracts logic (template enforcement)
  sync.md            # Compose with /document-release for post-ship updates
  CHANGELOG.md       # Version history
```

## Subcommands

### `/docs init [type]` — Generate docs from scratch
- Reads codebase structure, CLAUDE.md, README.md, git log, existing docs, design docs in `~/.gstack/projects/`
- Generates PHILOSOPHY.md (default) or OVERVIEW.md
- Outputs doc file + `.docs/claims.json` sidecar mapping sections to evidence
- Re-run: if doc exists, generate claims.json without overwriting, present diff, ask user

### `/docs check` — Coherence + staleness
- Staleness: `git diff <stored-sha>..HEAD -- <evidence-path>` per claims.json section
- Coherence v1: mechanical checks (broken links, duplicate headers, conflicting versions, missing files)
- Output: report grouped by severity

### `/docs enforce [path]` — Template enforcement (absorbed from /contracts)
- Doc triplet validation (PRD + ARCHITECTURE + TEST-SPEC) against templates
- Template resolution fallback chain: $REPO_ROOT/templates/ -> ~/.claude/spec/templates/ -> ~/.claude/templates/
- Report first, fix only on explicit request

### `/docs sync` — Post-ship doc updates
- Compose with gstack's `/document-release`
- Run `/docs check` after to verify coherence

## Claims Sidecar (`.docs/claims.json`)
- File-level evidence tracking (not line-level)
- Commit SHA stored per section for exact diff comparison
- Directory evidence used sparingly (only when directory structure IS the claim)

## Migration Plan
1. v0.1.0: Ship `/docs` alongside `/contracts` (both work independently)
2. v0.2.0: Update `/workflow` to prefer `/docs enforce`, fall back to `/contracts`
3. v0.3.0: Remove `skills/contracts/`

## Key Files to Modify/Create
- `skills/docs/SKILL.md` (new)
- `skills/docs/init.md` (new)
- `skills/docs/check.md` (new)
- `skills/docs/enforce.md` (new)
- `skills/docs/sync.md` (new)
- `skills/docs/CHANGELOG.md` (new)
- `skills-catalog.json` (add docs entry)

## Key Files to Read (existing patterns)
- `skills/contracts/SKILL.md` — enforce logic to absorb
- `skills/workflow/SKILL.md` — multi-file skill pattern to follow
- `skills/skill-author/SKILL.md` — catalog entry pattern
- `templates/contract-*.md` — template enforcement patterns

## Success Criteria
- `/docs init` produces useful PHILOSOPHY.md for this repo
- `/docs check` flags stale sections after code changes
- `/docs enforce` passes existing `/contracts` test cases
- Passes `./scripts/validate.sh` and `./scripts/test.sh`

## Verification
1. Run `/docs init` on this repo, inspect PHILOSOPHY.md quality
2. Change a SKILL.md, run `/docs check`, verify staleness flagged
3. Run `/docs enforce` on existing doc triplets, compare output with `/contracts`
4. Run `./scripts/validate.sh` and `./scripts/test.sh`
