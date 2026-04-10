---
type: prd
feature: infrastructure
title: "Infrastructure — Product Requirements"
version: 1
status: Active
date: 2026-04-09
author: chjiang
---

## Problem Statement

Claude Code sessions load configuration from `~/.claude/`, but that directory has no version control, no audit trail, and no way to reproduce its state. When skills or settings are edited directly in `~/.claude/`, changes are invisible and irreproducible. A repo owner needs a single source of truth that deploys deterministically to the runtime directory.

## Mental Model

The repo is the authority (P1). `~/.claude/` is a deployment target. A deploy script copies repo content to the runtime directory. A post-commit hook (P11) ensures every commit auto-deploys. Five principles (P1, P2, P3, P5, P11) govern what goes where.

## User Stories

### P0 (Must-Have)

| # | Tag | What it asks | As a... | I want to... | So that... |
|---|-----|-------------|---------|-------------|------------|
| 1 | core | R-001: Does deploy.sh copy all deployable files to ~/.claude/? | repo owner | run `bash scripts/deploy.sh` and have skills, settings land in ~/.claude/ | my runtime config matches the repo |
| 2 | core | R-002: Do principles P1-P11 have enforceable directives? | repo owner | have each principle translate to a Claude directive and a path-scoped rule | principles are enforced by construction, not memory |
| 3 | resilience | R-003: Does the post-commit hook auto-deploy? | repo owner | have changes deploy automatically after every commit | committed-but-not-deployed is impossible (P11) |
| 4 | observability | R-004: Can I detect repo-vs-home drift? | repo owner | run an audit that diffs repo state against ~/.claude/ | I know immediately when drift exists |

### P1 (Important)

None for v1.

### P2 (Nice-to-Have)

None for v1.

## Acceptance Criteria

### Story #1: Deploy pipeline [core]

```
GIVEN the repo contains skills/, settings/, and .claude/skills/
WHEN  I run bash scripts/deploy.sh
THEN  every file is copied to its ~/.claude/ counterpart and exit code is 0
```

### Story #3: Auto-deploy [resilience]

```
GIVEN the post-commit hook is installed in .claude/hooks/
WHEN  I commit a change to any deployable file
THEN  deploy.sh runs automatically and ~/.claude/ reflects the commit
```

### Story #2: Principles enforcement [core]

```
GIVEN principles P1, P2, P3, P5, and P11 are defined in CLAUDE.md
WHEN  a user edits a file in skills/, settings/, or .claude/skills/
THEN  the corresponding path-scoped rule activates and enforces the governing principle
```

### Story #4: Drift detection [observability]

```
GIVEN the repo has been deployed to ~/.claude/
WHEN  I run deploy.sh --dry-run
THEN  it reports any files that differ between the repo and ~/.claude/ without modifying the target
```

## Success Metrics

| Metric | Target | How Measured |
|--------|--------|-------------|
| Deploy drift | Zero drift after every commit | Post-commit hook auto-deploys; `deploy.sh --dry-run` confirms |
| Rule coverage | Every deployable path has a governing rule | Path-scoped rules exist for skills/, settings/, templates/ |

## Out of Scope

- Multi-machine sync (each machine runs its own deploy)
- Remote deployment or CI/CD pipelines

## Assumptions

- The repo is the only source that writes to `~/.claude/` (no manual edits to deployment target)
- Git hooks are not bypassed (--no-verify is not used)
- The deploy.sh script has access to the target directory
