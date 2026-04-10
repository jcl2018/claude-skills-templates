---
type: architecture
feature: work-pipeline
title: "Work Pipeline — Architecture"
version: 1
status: Active
date: 2026-04-09
author: chjiang
prd: PRD.md
---

## Overview

The work pipeline implements a 4-phase lifecycle through five skills: a router (`/work`) and four phase skills (`/work-track`, `/work-implement`, `/work-review`, `/work-ship`). Quality gates are provided by `/system-health --scope`. Each skill reads a manifest file to understand current state and appends journal entries to maintain a decision trail.

## Architecture

```
/work (router)
  |
  +-- detect branch + manifest --> suggest phase
  |
  v
/work-track -----> /work-implement -----> /work-review -----> /work-ship
  |                    |                      |                    |
  | scaffold from      | load PRD+ARCH        | load diff+context  | validate AC
  | templates/         | dual-mode:           | delegate to        | write journal
  | create manifest    | build or debug       | gstack /review     | delegate to
  | write journal      | write journal        | write journal      | gstack /ship
  |                    |                      |                    |
  v                    v                      v                    v
docs/{family}/     source code            PR review            PR created
PRD + ARCH + TEST  changes                findings             + shipped
```

### Components Affected

| Component | Path | Change Type | Description |
|-----------|------|------------|-------------|
| Router | .claude/skills/work/SKILL.md | Core | Detects phase, shows menu, suggests next skill |
| Track | .claude/skills/work-track/SKILL.md | Core | CRUD + manifest-driven scaffolding from templates |
| Implement | .claude/skills/work-implement/SKILL.md | Core | Build-forward or debug-backward with context loading |
| Review | .claude/skills/work-review/SKILL.md | Core | Loads work context, delegates to gstack /review |
| Ship | .claude/skills/work-ship/SKILL.md | Core | Validates TEST-SPEC AC, delegates to gstack /ship |
| Templates | templates/*.md | Reference | PRD, ARCH, TEST-SPEC templates used by scaffolding |
| Quality gate | .claude/skills/system-health/SKILL.md | External | /system-health --scope provides work item quality checks |

### Data Flow

1. `/work` reads git branch name and scans for manifest file
2. `/work-track` creates docs/{family}/ with triplet files from templates
3. `/work-implement` loads PRD.md and ARCHITECTURE.md as context for implementation
4. `/work-review` loads work item context and delegates diff review to gstack
5. `/work-ship` checks TEST-SPEC acceptance criteria, then delegates to gstack /ship

## Design Decisions

| Decision | Chosen | Rejected Alternative | Why |
|----------|--------|---------------------|-----|
| Separate skill per phase | Six discrete SKILL.md files | Single monolithic work skill | Each phase has distinct inputs/outputs; separation enables independent evolution |
| Manifest-driven scaffolding | Templates in templates/ with variable substitution | Hardcoded file content in skill | Templates are editable without changing skill logic; P1 compliance |

## API Changes

No formal APIs. Skills are invoked by name (/work, /work-track, etc.). The artifact-manifests.json schema defines work item structure.

## Dependencies

| Dependency | Type | Description |
|-----------|------|-------------|
| Templates | Internal | PRD-TEMPLATE.md, ARCHITECTURE-TEMPLATE.md, TEST-SPEC-TEMPLATE.md for scaffolding |
| artifact-manifests.json | Internal | Defines artifact types and their required files |
| /review (gstack) | Skill | Delegated to by /work-review |
| /ship (gstack) | Skill | Delegated to by /work-ship |
| /system-health | Skill | Quality gates via --scope flag |

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Manifest schema changes break existing work items | Low | High | Versioned manifests; backward-compatible changes only |
| gstack /review or /ship API changes | Medium | Medium | work-review and work-ship are thin wrappers; easy to update |
| Journal entries grow large | Low | Low | Journal is append-only text; can be summarized if needed |
