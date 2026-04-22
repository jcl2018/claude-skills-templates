---
type: architecture
parent: S000007_copilot_prompt_packaging
feature: F000005_work_copilot
title: "Copilot Prompt Packaging — Architecture"
version: 1
status: Draft
date: 2026-04-22
author: chjiang
prd: PRD.md
reviewers: []
---

## Overview

Port the company-workflow validator into a Copilot-native prompt file. The
validator is already expressed as prose + checklists in
`skills/company-workflow/SKILL.md`; we translate it into a `.prompt.md` that
Copilot loads when the user types `/validate`. The manifest
(`copilot-artifact-manifests.json`) and the templates directory are
delivered alongside the prompt and are read by Copilot at prompt time via
the workspace file API.

## Architecture

```
.github/                              (inside the target repo)
  copilot-instructions.md             always-on context (S000009)
  prompts/
    validate.prompt.md                THIS STORY — the slash command
  work-copilot/
    copilot-artifact-manifests.json   same schema as company manifest
    templates/                        mirrored from templates/company-workflow/
    reference/                        optional guides for the model

Copilot chat flow:
  user types /validate <path>
    -> Copilot loads validate.prompt.md
    -> prompt instructs model: "read manifest, read templates, read <path>"
    -> model uses Copilot's file tool to read workspace files
    -> model emits [PASS]/[MISSING]/[DRIFT] lines + summary footer
```

### Components Affected

| Component | Repo | Change Type | Description |
|-----------|------|------------|-------------|
| `work-copilot/prompts/validate.prompt.md` | claude-skills-templates | New | The slash-command prompt |
| `work-copilot/copilot-artifact-manifests.json` | claude-skills-templates | New | Copy of company manifest, renamed for namespace clarity |
| `work-copilot/templates/` | claude-skills-templates | New | Mirror of `templates/company-workflow/` |

### Data Flow

1. User invokes `/validate <path>` in Copilot chat
2. Copilot injects `validate.prompt.md` as the system/user prompt
3. The prompt tells the model to read `copilot-artifact-manifests.json`
4. Model resolves work-item type from the tracker's `type:` frontmatter
5. Model reads each required artifact's template to derive structural rules
6. Model reads each required artifact in the target directory
7. Model emits one status line per artifact + a summary footer

## API Changes

### New APIs

| API | Signature | Description |
|-----|-----------|-------------|
| `/validate <path>` | Copilot slash prompt | Invokes validate.prompt.md on the given path |
| `/validate` (no args) | Copilot slash prompt | Prints usage cheat sheet |

### Modified APIs

| API | Before | After | Reason |
|-----|--------|-------|--------|
| — | — | — | No existing APIs modified |

## Dependencies

| Dependency | Type | Status | Notes |
|-----------|------|--------|-------|
| GitHub Copilot `.prompt.md` support | Tool | Available | Ships with Copilot Chat in VS Code |
| company-workflow manifest schema | Code | Available | Reused verbatim; version-pin the copy |
| templates/company-workflow/ files | Code | Available | Copied into the bundle |

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Copilot model hallucinates manifest contents instead of reading the file | Med | High | Prompt explicitly instructs "read the file, do not recall" and names the path |
| `.prompt.md` format changes in a future Copilot release | Low | Med | Pin documentation link, add a smoke test in S000008's installer |
| Output drift between Claude Code and Copilot runtimes | Med | Med | Ship fixtures in the bundle; manually diff outputs before declaring parity |
| Prompt too long for Copilot context window | Low | Med | Keep prompt body under 2 KB; link to reference guides instead of embedding |

## Design Decisions

| Decision | Chosen | Rejected Alternative | Why |
|----------|--------|---------------------|-----|
| Runtime surface | `.prompt.md` in `.github/prompts/` | `.chatmode.md` | Prompts are slash-invokable per-message, matching Claude slash-command UX |
| Manifest schema | Reuse company schema 1:1 | Invent a Copilot-specific schema | One spec, two runtimes — drift is the enemy |
| Output format | Identical `[PASS]`/`[MISSING]`/`[DRIFT]` | Copilot-native rich cards | Grep-ability + diff parity with company-workflow |
| Shell execution | None (pure prompt) | Node.js helper in `.github/scripts/` | Copilot prompts can't shell out; adding a script doubles the install surface |
| File reads | Model uses Copilot's file tool | Embed templates inline in the prompt | Inline would bloat context and couple the prompt to template versions |
