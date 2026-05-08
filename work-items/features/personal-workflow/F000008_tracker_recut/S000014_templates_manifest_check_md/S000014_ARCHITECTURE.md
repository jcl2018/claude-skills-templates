---
type: architecture
parent: S000014
feature: F000008
title: "Templates + manifest + check.md — Architecture"
version: 1
status: Draft
date: 2026-05-05
author: chjiang
prd: PRD.md
reviewers: []
---

## Overview

This story introduces the new artifact-set shape across three coupled layers: templates (source of truth for structural rules), manifest (type-to-artifact mapping), and validator (cross-reference traceability). Templates and the manifest can change in parallel; check.md depends on both. Per `personal-workflow-restructure` learning (Apr 16, 10/10 confidence), the validator derives expectations from the templates at runtime — there's no separate `contract.json` to keep in sync.

## Architecture

```
                  +--------------------+
                  |   templates/       |
                  |   personal-workflow/|
                  | doc-SPEC.md (new)  |---+
                  | doc-ROADMAP.md (new)|  |
                  | doc-DESIGN.md (edit)|  |
                  | doc-TEST-SPEC.md   |  |
                  | tracker-*.md       |  |
                  +--------------------+  |
                            |             |
                            | (read by)   | (read by)
                            v             v
              +---------------------+  +-----------------+
              | check.md (validator)|  | personal-       |
              | Steps 11, 16, 18    |  | artifact-       |
              | derive rules from   |  | manifests.json  |
              | templates + manifest|<-| types.feature   |
              +---------------------+  | types.user-story|
                                       +-----------------+
                                              |
                                              | (read by Step 11)
                                              v
                                       (work-items/ walk in
                                        check.md Step 14)
```

### Components Affected

| Component | Repo | Change Type | Description |
|-----------|------|------------|-------------|
| `templates/personal-workflow/doc-SPEC.md` | claude-skills-templates | New | Merged PRD + ARCHITECTURE structure with preserved P0/P1/P2 sub-sections |
| `templates/personal-workflow/doc-ROADMAP.md` | claude-skills-templates | New | Merged feature-summary + milestones with Delivery History sub-section |
| `templates/personal-workflow/doc-PRD.md` | claude-skills-templates | Delete | Replaced by SPEC |
| `templates/personal-workflow/doc-ARCHITECTURE.md` | claude-skills-templates | Delete | Replaced by SPEC |
| `templates/personal-workflow/doc-feature-summary.md` | claude-skills-templates | Delete | Replaced by ROADMAP |
| `templates/personal-workflow/doc-milestones.md` | claude-skills-templates | Delete | Replaced by ROADMAP |
| `templates/personal-workflow/doc-DESIGN.md` | claude-skills-templates | Modified | Lines 15 prose, 71 comment, 76 Milestones→Roadmap link |
| `templates/personal-workflow/doc-TEST-SPEC.md` | claude-skills-templates | Modified | Frontmatter cross-refs (prd + architecture → spec) |
| `templates/personal-workflow/tracker-feature.md` | claude-skills-templates | Modified | Full rewrite: Prerequisite line, Phase 1 reorder, Phase 3 4-gate |
| `templates/personal-workflow/tracker-user-story.md` | claude-skills-templates | Modified | Full rewrite parallel to feature |
| `templates/personal-workflow/tracker-task.md` | claude-skills-templates | Modified | Add optional /office-hours Prerequisite line |
| `skills/personal-workflow/personal-artifact-manifests.json` | claude-skills-templates | Modified | v3.0.0; types.feature + types.user-story rewritten |
| `skills/personal-workflow/check.md` | claude-skills-templates | Modified | Step 18 (5 line edits) + 4 incidentals (84, 218, 220, 365) |
| `skills/personal-workflow/WORKFLOW.md` | claude-skills-templates | Modified | 7 lines (21, 22, 38, 41, 49, 64-65, 190) |
| `skills/personal-workflow/SKILL.md` | claude-skills-templates | Modified | Version bump to 3.0.0 |

### Data Flow

1. Engineer scaffolds a new work item using `templates/personal-workflow/{doc,tracker}-*.md` as source.
2. `/personal-workflow check {dir}` runs:
   - **Step 11** reads `personal-artifact-manifests.json`, looks up `types.{type}.required`, and asserts each artifact filename is present in the directory.
   - **Step 16** resolves each artifact's template, parses required fields/sections, and compares to the actual file's content.
   - **Step 18** opens SPEC.md, parses `### P0/P1/P2` sub-sections inside `## Requirements`, opens TEST-SPEC.md, parses `## Smoke Tests` and `## E2E Tests` tables for `AC-{n}` values, and asserts every P0 story number has a matching AC.
3. Steps 11 and 16 auto-follow the manifest + template changes (no code edit needed). Step 18 needs explicit code edits because it hardcodes the source filename and parent section name.

## API Changes

No external API changes. All changes are to template files and validator instructions (read by Claude Code as natural language, not parsed as code).

## Dependencies

| Dependency | Type | Status | Notes |
|-----------|------|--------|-------|
| v1.4.0 TEST-SPEC restructure shipped | Feature | Available | Verified: commit abe411c, PR #57 |
| `/personal-workflow check` walk root is `work-items/` | Code | Available | check.md Step 14 |
| Engineer's `/tmp` directory writable for synthetic smoke tests | Infra | Available | Standard |

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Step 18 incidental misses (line 220, etc.) silently leave stale text | Med | Low (cosmetic) | TEST-SPEC includes grep-based smoke check covering all 4 incidental lines |
| New SPEC template's `### P0/P1/P2` shape diverges from PRD's, breaking parser | Low | High (breaks Step 18) | Preserve PRD's sub-section structure verbatim per design Big Decision #6 |
| Template author forgets to add a section that check.md derives | Med | Med (DRIFT findings on next check) | Manual smoke test with `/personal-workflow check` on synthetic work item before declaring done |

## Design Decisions

| Decision | Chosen | Rejected Alternative | Why |
|----------|--------|---------------------|-----|
| SPEC.md sub-section structure | Preserve PRD's `### P0/P1/P2` inside `## Requirements` | Single flat `## Requirements` table with Priority column | Keeps check.md Step 18 parser at filename-only change; row-filter rewrite would need additional pseudocode change |
| ROADMAP.md timeline section | `## Delivery Timeline` with `### Delivery History` sub-section | Two separate `## Plan` and `## History` sections | Single section keeps reading flow chronological; sub-section absorbs historical merge-date entries |
| tracker-defect.md changes | None — leave as-is | Add /investigate Prerequisite line | Defects start from /investigate naturally; tracker shape already fits; no value in adding redundant prose |
| Smoke test approach | Synthetic /tmp work item + `/personal-workflow check` | In-place test on a real work item | Avoids polluting work-items/ tree with throwaway directory; teardown trivial (`rm -rf`) |
