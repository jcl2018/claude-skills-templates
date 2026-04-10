---
type: architecture
feature: infrastructure
title: "Infrastructure — Architecture"
version: 1
status: Active
date: 2026-04-09
author: chjiang
prd: PRD.md
---

## Overview

The infrastructure layer implements P1 (single source of truth) and P11 (deploy or it didn't happen) through a deploy script, a post-commit hook, and path-scoped rules that enforce principles at edit time. The repo owns all shared configuration; `~/.claude/` is a read-only deployment target.

## Architecture

```
home-setup repo                          ~/.claude/ (runtime)
+-----------------------+                +------------------------+
| skills/        (P2)   | --deploy.sh--> | skills/gstack/          |
| .claude/skills/ (P3)  | --deploy.sh--> | skills/{custom}/        |
| settings/             | --deploy.sh--> | settings.json           |
+-----------------------+                +------------------------+
        |
  post-commit hook (P11)
  triggers deploy.sh automatically
```

### Components Affected

| Component | Path | Change Type | Description |
|-----------|------|------------|-------------|
| Deploy script | scripts/deploy.sh | Core | Copies repo files to ~/.claude/, merges settings |
| Post-commit hook | .claude/hooks/post-commit-deploy.sh | Core | Triggers deploy.sh after every git commit |
| Path-scoped rules | .claude/rules/*.md | Core | Enforce P1-P11 at edit time per file context |
| Principles | CLAUDE.md (## Principles) | Reference | Defines P1, P2, P3, P5, P11 with directives |

### Data Flow

1. User edits a deployable file (skills, settings, templates)
2. Path-scoped rule activates and reminds Claude of the governing principle
3. User commits; post-commit hook fires deploy.sh
4. deploy.sh copies files to ~/.claude/, skipping upstream .git dirs
5. Audit checks (AG1) verify repo-home sync on demand

## Design Decisions

| Decision | Chosen | Rejected Alternative | Why |
|----------|--------|---------------------|-----|
| Post-commit hook for auto-deploy | Git hook in .claude/hooks/ | Manual deploy reminder | P11: removes human step; deployed by construction |
| Path-scoped rules over global rules | One .md per principle-path pair | Single large rules file | Granular activation; rule only loads when editing relevant files |

## API Changes

No API changes. The deploy script and path-scoped rules are internal to the repo.

## Dependencies

| Dependency | Type | Description |
|-----------|------|-------------|
| Git hooks | Infra | Post-commit hook triggers deploy.sh |
| rsync/cp | Infra | File copy for deployment |
| jq | External | Used by validation scripts |

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Manual ~/.claude/ edits overwritten | Medium | Low | P1 principle: repo is source of truth; deploy overwrites |
| Hook bypassed with --no-verify | Low | Medium | CLAUDE.md rules prohibit --no-verify usage |
| New deployable paths miss rules | Medium | Medium | Audit checks for uncovered paths |
