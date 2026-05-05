---
type: architecture
parent: S000009_always_on_instructions
feature: F000004_work_copilot
title: "Always-On Copilot Instructions — Architecture"
version: 1
status: Draft
date: 2026-04-22
author: chjiang
prd: PRD.md
reviewers: []
---

## Overview

A single markdown file (`copilot-instructions.md`) sits in
`work-copilot/instructions/` as the source of truth and is installed to
`<target>/.github/copilot-instructions.md` by S000008's installer. Content is
a compact index of conventions — not a duplicate of the manifest or the
validate prompt — and ends with a pointer to `/validate` for enforcement.

## Architecture

```
work-copilot/instructions/copilot-instructions.md    (source of truth)
         |
         | installed verbatim by copilot-deploy install
         v
<target>/.github/copilot-instructions.md             (always-on in Copilot chat)
         |
         | Copilot loads implicitly at every request
         v
all Copilot chats in target repo see it
```

Structure of the file (planned) — 5 sections as H2 headers in the
installed `copilot-instructions.md`:

1. `Working on this repo (ambient context)` — intro, one paragraph
2. `How work is tracked` — hierarchy (feature > user-story > task, depth 3),
   IDs (F/S/T/D + 6 digits), placement rules, 3-phase lifecycle (Track,
   Implement, Ship)
3. `How to add a work item` — pointer to `.github/work-copilot/templates/`
   and minimum required artifacts per type from the manifest
4. `How to check compliance` — "run `/validate <path>`"
5. `Sources` — links to manifest path, templates dir, and upstream
   `skills/personal-workflow/WORKFLOW.md`

### Components Affected

| Component | Repo | Change Type | Description |
|-----------|------|------------|-------------|
| `work-copilot/instructions/copilot-instructions.md` | claude-skills-templates | New | The always-on source file |
| `work-copilot/install-manifest.json` | claude-skills-templates | Modified | Include the new instructions file and its install target |

### Data Flow

1. Engineer opens target repo in VS Code
2. Copilot Chat loads `.github/copilot-instructions.md` into every request
3. When user asks a workflow question, Copilot has ambient context to
   answer correctly and pointers to load more if needed
4. For any actual compliance check, it invokes `/validate`

## API Changes

### New APIs

| API | Signature | Description |
|-----|-----------|-------------|
| `.github/copilot-instructions.md` | File | Always-on context for Copilot Chat |

### Modified APIs

| API | Before | After | Reason |
|-----|--------|-------|--------|
| `install-manifest.json` | 3 file categories (prompts, templates, reference) | 4 categories (+ instructions) | New install target path |

## Dependencies

| Dependency | Type | Status | Notes |
|-----------|------|--------|-------|
| S000008 installer | Feature | Pending | Needed to actually deliver the file to the target repo |
| Copilot `.github/copilot-instructions.md` support | Tool | Available | Standard Copilot Chat feature |

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Instructions drift from WORKFLOW.md | Med | Med | Add a Tier 1 smoke test that greps for known invariants (ID regex, phase names, filenames) |
| Byte budget exceeded as spec grows | Low | Low | Tier 1 size check; trim or link out if over |
| Copilot ignores instructions in some contexts (e.g., inline suggestions vs chat) | Med | Low | Document scope: this only influences Chat, not inline completion |
| Conflicting instructions in user's pre-existing `copilot-instructions.md` | Med | High | S000008 installer refuses to overwrite a non-bundle file without `--overwrite` (drift detection) |

## Design Decisions

| Decision | Chosen | Rejected Alternative | Why |
|----------|--------|---------------------|-----|
| Single file | One `copilot-instructions.md` | Split across multiple files + `.copilot/` dir | Copilot only loads the canonical path; splitting loses always-on guarantee |
| Content shape | Index + pointers | Full spec inline | Budget + single-source-of-truth; manifest and templates stay authoritative |
| Validator mention | Explicit `/validate` pointer | Let Copilot improvise | Forces the compliance path; no invention |
| Source of truth | Maintained in `work-copilot/instructions/` and copied on install | Generated on install from WORKFLOW.md | Simpler and reviewable; can be generated later if worth it |
