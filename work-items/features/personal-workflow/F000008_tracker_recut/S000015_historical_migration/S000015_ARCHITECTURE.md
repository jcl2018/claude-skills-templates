---
type: architecture
parent: S000015
feature: F000008
title: "Historical migration — Architecture"
version: 1
status: Draft
date: 2026-05-05
author: chjiang
prd: PRD.md
reviewers: []
---

## Overview

Mechanical but content-aware migration of 14 work items (13 historicals + F000008 self) from the OLD artifact shape to the NEW shape. This story has no code changes — it's pure file operations + content merging. Every operation is a Write (new file) or Delete or Edit (existing file). The migration runs in a single sequence to avoid touching the same files twice.

Per the `validators-may-be-llm-not-bash` learning (Apr 16, 10/10 confidence), the migration cannot be a bash script that "calls the validator" — `/personal-workflow check` is an LLM skill, not an executable. The migration is therefore done either by Claude reading per-file content and merging interactively, OR by a one-shot bash script that does straight content concatenation + frontmatter edits without invoking the validator. Validator runs separately as a verification step.

## Architecture

```
                   S000014 ships first (templates + manifest exist)
                                      |
                                      v
+-----------------------------------------------------------------+
| Migration sequence (per work item, processed in dependency order)|
|                                                                  |
| For each feature {F000001, F000002, F000004, F000005, F000006}:  |
|   1. Read feature-summary.md content                             |
|   2. Read milestones.md content                                  |
|   3. Write {ID}_ROADMAP.md = merged content                      |
|   4. Edit {ID}_DESIGN.md: Milestones link → Roadmap link         |
|   5. Delete feature-summary.md and milestones.md                 |
|                                                                  |
| For each user-story {S000001, S000006-S000010, S000012, S000013}:|
|   1. Read PRD.md content                                         |
|   2. Read ARCHITECTURE.md content                                |
|   3. Write {ID}_SPEC.md = PRD merged with ARCHITECTURE,          |
|      preserving ### P0/P1/P2 sub-sections                        |
|   4. Write {ID}_DESIGN.md (stub or distilled)                    |
|   5. Edit {ID}_TEST-SPEC.md frontmatter: prd+architecture → spec |
|   6. Delete PRD.md and ARCHITECTURE.md                           |
|                                                                  |
| F000008 self-migration (parent + 3 children): same recipe        |
+-----------------------------------------------------------------+
                                      |
                                      v
                /personal-workflow check work-items/  (verify 0 findings)
```

### Components Affected

| Component | Repo | Change Type | Description |
|-----------|------|------------|-------------|
| `work-items/features/personal-workflow/F000001_personal_workflow/` | claude-skills-templates | Modified | feature-summary + milestones → ROADMAP; DESIGN edit |
| `work-items/features/system-health/F000002_system_health/` | claude-skills-templates | Modified | Same pattern |
| `work-items/features/work-copilot/F000004_work_copilot/` | claude-skills-templates | Modified | Same pattern |
| `work-items/features/ops/deprecation/F000005_deprecated_skill_status/` | claude-skills-templates | Modified | Same pattern |
| `work-items/features/ops/deprecation/F000006_relocate_deprecated_skills/` | claude-skills-templates | Modified | Same pattern |
| `S000001`, `S000006`-`S000010`, `S000012`, `S000013` user-story dirs | claude-skills-templates | Modified | PRD + ARCHITECTURE → SPEC; add DESIGN; TEST-SPEC frontmatter |
| `F000008_tracker_recut/` (this feature) | claude-skills-templates | Modified | Self-migration: feature artifacts + 3 children |

### Data Flow

1. **For a feature migration:**
   - Source files: `{ID}_feature-summary.md` + `{ID}_milestones.md` (raw markdown)
   - Concatenate Scope, Success Criteria, Constituent User-Stories, Out-of-Scope from feature-summary into ROADMAP's `## Scope`, `## Non-Goals`, `## Success Criteria`, `## Decomposition`
   - Concatenate milestones table + dependency graph into ROADMAP's `## Delivery Timeline` (with `### Delivery History` for historical entries)
   - Output: `{ID}_ROADMAP.md`; delete the two source files
2. **For a user-story migration:**
   - Source files: `{ID}_PRD.md` + `{ID}_ARCHITECTURE.md`
   - Concatenate PRD's User Stories tables (P0/P1/P2 sub-sections) into SPEC's `## Requirements` (preserving the sub-section structure for Step 18 parser)
   - Concatenate PRD's Acceptance Criteria into SPEC's `## Acceptance Criteria`
   - Concatenate ARCHITECTURE's Architecture, Components, Data Flow, API Changes, Dependencies, Risk Assessment, Design Decisions into SPEC's `## Architecture` and `## Tradeoffs`
   - Output: `{ID}_SPEC.md`; delete the two source files
   - Add: `{ID}_DESIGN.md` (5-line stub per Open Question 1)
   - Edit: `{ID}_TEST-SPEC.md` frontmatter (lines 10-11)
3. **F000008 self-migration:** F000008 + each of its 3 children get the same treatment as historical features + user-stories.

## API Changes

No API changes. Pure file operations.

## Dependencies

| Dependency | Type | Status | Notes |
|-----------|------|--------|-------|
| S000014 shipped | Feature | Pending | Must land before S000015 Phase 2 begins (new templates + manifest required) |
| Pre-migration `/personal-workflow check` baseline report | Artifact | Pending | Save before Phase 2 starts so Step 18 regression diff is possible |

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Content loss during merge (e.g., edge-case formatting in PRD's User Stories table broken on concat) | Med | Med | Manual diff each merged SPEC against the pair of source files for at least 2 of the 8 user-stories before declaring done |
| Step 18 regression on a previously-passing user-story | Low | High (validator output noise) | Pre-migration baseline + post-migration diff; investigate any new [UNTESTED] |
| F000008 self-migration race — running it before S000014 lands breaks check.md | Med | High (blocks PR) | Hard sequence: S000014 PR section merged into branch first; then S000015 includes F000008 in its sweep |
| Migration script (if used) doesn't handle frontmatter cleanly (sed regex on YAML is fragile) | Med | Med | Either do TEST-SPEC frontmatter edits via Edit tool individually, or use yq instead of sed |
| Historical milestone content (PR links, merge dates) lost during ROADMAP merge | Low | Low | Explicitly preserve as `### Delivery History` sub-section per design |

## Design Decisions

| Decision | Chosen | Rejected Alternative | Why |
|----------|--------|---------------------|-----|
| Migration approach | Per-file Read + Write + Delete operations (Claude-driven) | One-shot bash script | Bash struggles with markdown content merge; Claude reads each pair and produces a coherent SPEC; faster end-to-end given 14 items |
| DESIGN.md backfill | 5-line stub for all 8 user-stories by default | Hand-distill from PRD content for each | PRD is being deleted in same PR — circular dependency; stub is honest about the absence of a `/office-hours` record |
| Pre-migration baseline | Save `/personal-workflow check` output to /tmp before Phase 2 | Skip; trust the validator post-migration | Step 18 regression diff requires baseline; cheap to save |
| F000008 migration order | Last item processed in S000015's sweep | First item processed | Migrating F000008's children would break check on this feature mid-flight; do all historicals first, then self at end |
