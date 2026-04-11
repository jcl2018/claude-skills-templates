---
type: architecture
parent: ""
feature: F000001_workflow_alpha
title: "workflow-alpha — Architecture"
version: 1
status: Draft
date: 2026-04-11
author: chjiang
prd: F000001_PRD.md
reviewers: []
---

## Overview

The workflow skill is a single-entry-point router for the 4-phase dev lifecycle. It detects the current branch, resolves the matching work item from `work-items/`, determines which phase is active, and dispatches to the appropriate subcommand. The design consolidates what were originally 5 separate skills into one multi-file skill with shared context resolution.

## Architecture

```
                    ┌──────────────────────────┐
                    │    /workflow ROUTER       │
                    │    (SKILL.md)             │
                    │                          │
                    │  1. Branch detection      │
                    │  2. Work item resolution  │
                    │  3. Phase detection       │
                    │  4. Status menu (default) │
                    └──────────┬───────────────┘
                               │
           ┌──────────┬────────┼────────┬──────────┐
           ▼          ▼        ▼        ▼          ▼
       track.md  implement.md review.md ship.md  (status)
           │          │        │        │
           ▼          ▼        ▼        ▼
    work-items/   code edits  /contracts /contracts
    {slug}/                   + /review  + /ship
    ├── TRACKER.md
    ├── PRD.md
    ├── ARCHITECTURE.md
    ├── TEST-SPEC.md
    └── milestones.md
```

### Components Affected

| Component | Path | Description |
|-----------|------|-------------|
| Router | skills/workflow/SKILL.md | Branch detection, work item resolution, phase detection, status menu |
| Track | skills/workflow/track.md | Work item CRUD: create, journal, milestones, list, close, scrum, child-items |
| Implement | skills/workflow/implement.md | Build-forward (features) or debug-backward (defects) |
| Review | skills/workflow/review.md | Contract quality gate → delegates to gstack /review |
| Ship | skills/workflow/ship.md | TEST-SPEC validation + contract gate → delegates to gstack /ship |

### Data Flow

1. User runs `/workflow [subcommand]`
2. SKILL.md detects branch pattern (feat/*, fix/*, task/*, story/*, review/*)
3. Derives type (feature/defect/task/user-story/review) and slug from branch name
4. Searches `work-items/` for a TRACKER.md matching the slug
5. Reads TRACKER.md frontmatter and lifecycle checkboxes to determine current phase
6. Dispatches to the appropriate subcommand .md file with resolved context

### Branch Pattern Matching

| Pattern | Type | Example |
|---------|------|---------|
| `feature-*`, `feat-*`, `feat/*` | feature | feat/workflow-alpha |
| `defect-*`, `fix-*`, `fix/*`, `bugfix-*` | defect | fix/null-pointer |
| `task-*`, `chore-*`, `chore/*` | task | task/cleanup-templates |
| `story-*` | user-story | story/user-onboarding |
| `review-*` | review | review/q2-audit |

### Template Resolution

Templates resolve via 3-level fallback:

```
1. $REPO_ROOT/templates/        (repo-local, highest priority)
2. ~/.claude/spec/templates/    (user spec system)
3. ~/.claude/templates/         (skills-deploy fallback)
```

### Track Subcommands

| Subcommand | What it does |
|-----------|-------------|
| create | Scaffold work item + artifacts per artifact-manifests.json |
| (default) | Evidence synthesis — propose journal entries from git history |
| journal | Manual journal entry (decision / finding / blocker) |
| milestones | CRUD operations on milestones.md |
| list | List all work items with risk badges (overdue/urgent/at-risk) |
| close | Set status: done, add close date |
| scrum | Generate scrum notes from milestones + git + journal |
| child-items | Create sub-items (max depth 3: feature → story → task) |

### Implement Modes

| Mode | Triggered by | Behavior |
|------|-------------|----------|
| Build-forward | feature, task, user-story | Read doc triplet → draft plan → execute with approval |
| Debug-backward | defect | Collect symptoms → 3 hypotheses → test systematically → root-cause gate → fix |

## Dependencies

| Dependency | Type | Status | Notes |
|-----------|------|--------|-------|
| /contracts | Skill | Available | Invoked as quality gate at review and ship phases |
| gstack /review | Skill | Available | Code review delegation at Phase 3 |
| gstack /ship | Skill | Available | Ship delegation at Phase 4 |
| artifact-manifests.json | Config | Available | Declares required artifacts per work item type |
| Template fallback chain | Infra | Available | 3-level resolution for doc/tracker templates |

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Branch naming doesn't match patterns | Med | Med | Clear error message listing patterns, suggest `/workflow track create` |
| Templates missing after clone | Med | High | 3-level fallback + loud failure with install instructions |
| Contract gate too strict | Low | Med | Override prompt at every gate |

## Design Decisions

| Decision | Chosen | Rejected Alternative | Why |
|----------|--------|---------------------|-----|
| Single router with subcommands | Multi-file skill (SKILL.md + track/implement/review/ship.md) | 5 separate skills | Context resolved once; lower cognitive load |
| Branch as primary key | Branch name determines work item | Explicit --item flag | Zero-config: just be on the right branch |
| Manifest-driven scaffolding | artifact-manifests.json | Hardcoded per-type logic in track.md | Extensible: add types without code changes |
| Handoff blocks in TRACKER.md | `<!-- HANDOFF: phase=... -->` HTML comments | Separate state file | Inline, no extra files, grep-friendly |
| Dual implement modes | Build-forward vs debug-backward based on type | Single mode for all types | Features and defects have fundamentally different workflows |
