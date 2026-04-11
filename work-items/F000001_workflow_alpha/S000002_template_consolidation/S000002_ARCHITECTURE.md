---
type: architecture
parent: S000002_template_consolidation
feature: F000001_workflow_alpha
title: "Work Item Template Consolidation — Architecture"
version: 1
status: Draft
date: 2026-04-11
author: chjiang
prd: S000002_PRD.md
reviewers: []
---

## Overview

This is a template-only change — no skill logic modifications. The 5 tracker templates in `templates/tracker-*.md` get updated gates, cleaned frontmatter, and consistent structure. The key constraint is that SKILL.md phase detection counts checkboxes, not gate text, so gate rewording is safe.

## Architecture

```
templates/
  tracker-feature.md      ← update Phase 3+4 gates, clean frontmatter
  tracker-defect.md       ← update Phase 3+4 gates, clean frontmatter
  tracker-task.md         ← update Phase 3+4 gates, simplify lifecycle, clean frontmatter
  tracker-user-story.md   ← update Phase 3+4 gates, clean frontmatter
  tracker-review.md       ← rewrite to sub-gate style, clean frontmatter

skills/workflow/SKILL.md  ← verify phase detection (no changes expected)
```

No data flow changes. No new components. No API changes.

### Changes Per Template

#### tracker-feature.md

**Frontmatter:**
- Remove `url: "{JIRA_OR_TFS_URL}"`
- Remove `workflow_type` (redundant with `type`)

**Phase 3: Review** (before → after):
```
BEFORE:
- [ ] Code review requested (reviewer noted)
- [ ] Review feedback captured (suggestions + resolutions in Journal)
- [ ] All review suggestions resolved or marked won't-fix
- [ ] Doc triplet passes doc alignment check (if applicable)

AFTER:
- [ ] Self-review completed (diff reviewed)
- [ ] Doc triplet passes contract check (if applicable)
- [ ] Tests pass
```

**Phase 4: Ship** (before → after):
```
BEFORE:
- [ ] Linux branch build passes
- [ ] Regression tests pass
- [ ] Code review completed (reviewer noted in Journal)
- [ ] PR description generated
- [ ] PR created (PR link in PRs section)
- [ ] Merged to target branch

AFTER:
- [ ] Tests pass
- [ ] PR created (link in PRs section)
- [ ] Merged to target branch
```

#### tracker-defect.md

Same Phase 3+4 changes as feature. Defect-specific Phase 1+2 gates unchanged (reproduction steps, RCA, hypothesis testing are still relevant for solo-dev).

#### tracker-user-story.md

Same Phase 3+4 changes as feature.

#### tracker-task.md

Same Phase 3+4 changes as feature, plus:

**Phase 1: Track** — simplify:
```
AFTER:
- [ ] Scope understood from parent work item
- [ ] Working branch created
```

**Phase 2: Implement** — simplify:
```
AFTER:
- [ ] Changes committed (>=1 commit SHA in Log)
- [ ] Files section updated
```

#### tracker-review.md

Rewrite from single-line style to sub-gate style matching other templates. Adopt the same Phase 3+4 gates.

### Frontmatter Changes (all templates)

| Field | Action | Reason |
|-------|--------|--------|
| `url` | Remove | Enterprise tracker integration, not used in solo-dev |
| `workflow_type` | Remove | Always matches `type`, redundant |
| `blocked_by` | Keep | Useful for solo-dev dependency tracking |
| `repo` | Keep | Useful for multi-repo context |

## Dependencies

| Dependency | Type | Status | Notes |
|-----------|------|--------|-------|
| Phase detection (SKILL.md) | Code | Available | Uses checkbox counting, not text matching — safe |
| /contracts check | Skill | Available | Contract templates unchanged — no impact |
| artifact-manifests.json | Config | Available | References template filenames, not content — no impact |

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Existing work items have old gate text | Med | Low | Phase detection counts checkboxes, not text — old items still work |
| skills-deploy copies stale templates | Low | Low | Run `skills-deploy install --overwrite` after update |

## Design Decisions

| Decision | Chosen | Rejected Alternative | Why |
|----------|--------|---------------------|-----|
| Keep 4 phases for tasks | Lighter gates within 4 phases | 2-phase lifecycle (Implement → Ship) | Consistent model; fewer gates achieves "lighter" without a structural change |
| Remove "PR description generated" gate | Fold into PR creation | Keep as separate gate | Solo dev generates description as part of creating the PR, not a separate step |
| "Self-review" instead of removing Review | Rename the gate | Drop Phase 3 entirely | Self-review is still valuable; contract check still runs here |
