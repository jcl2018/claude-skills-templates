---
type: architecture
parent: S000003_company_workflow_implementation
feature: F000003_company_workflow
title: "Company Workflow Implementation — Architecture"
version: 2
status: Draft
date: 2026-04-11
author: chjiang
prd: S000003_PRD.md
reviewers: []
---

## Overview

A standalone Claude Code skill that packages an entire company work item specification.
One unified validate command with two modes: file mode (structural rules) and directory
mode (artifact completeness). Zero external dependencies. No gstack, no /docs check,
no analytics. Read-only: validates but never modifies files.

## Architecture

```
company-workflow skill (standalone, read-only)
    |
    +-- [DATA LAYER]
    |   +-- templates/company-workflow/              13 templates (5 trackers + 8 docs)
    |   +-- skills/company-workflow/contract.json    structural rules (file mode)
    |   +-- skills/company-workflow/company-artifact-manifests.json
    |   |                                            type->artifact mapping (dir mode)
    |   +-- template-registry.json                   template set metadata (repo root)
    |
    +-- [COMMAND LAYER]
    |   +-- validate <file>     contract rules -> exit 0/1
    |   +-- validate <dir>      artifact completeness -> [PASS]/[MISSING]/[DRIFT]
    |
    +-- [EXAMPLE LAYER]
    |   +-- examples/    13 filled-in examples (1 per template, AI reads during generation)
    |
    +-- [REFERENCE LAYER]
        +-- reference/   7 human reference guides
        +-- philosophy/  3 lifecycle rationale docs
        +-- fixtures/    3 file-mode + 2 dir-mode test fixtures
```

### Path Resolution

2-level fallback chain. Works in the workbench repo and on deployed machines:

```
Level 1: $REPO_ROOT/skills/company-workflow/     (workbench)
Level 2: ~/.claude/skills/company-workflow/       (deployed via skills-deploy)
```

Templates resolve the same way: `$REPO_ROOT/templates/company-workflow/` then
`~/.claude/templates/company-workflow/`.

### Components

| Component | Type | Description |
|-----------|------|-------------|
| skills/company-workflow/SKILL.md | Skill | Unified validate command (file + dir modes) |
| skills/company-workflow/contract.json | Data | Structural validation rules |
| skills/company-workflow/company-artifact-manifests.json | Data | Type->artifact mapping (5 types) |
| skills/company-workflow/examples/ | Examples | 13 filled-in examples (1 per template) |
| skills/company-workflow/reference/ | Docs | 7 human reference guides |
| skills/company-workflow/philosophy/ | Docs | 3 lifecycle rationale docs |
| skills/company-workflow/fixtures/ | Test | 3 file-mode + 2 dir-mode fixtures |
| templates/company-workflow/ | Templates | 13 company spec templates |
| template-registry.json | Data | Declares template sets |
| skills-catalog.json | Config | Skill catalog entry |

### Data Flow

**validate (file mode):**
1. Read contract.json (expected fields, sections, order)
2. Parse target file's YAML frontmatter + ## headings
3. Compare actual vs expected
4. Exit 0 (valid) or exit 1 (violations to stderr)

**validate (directory mode):**
1. Find *_TRACKER.md in directory (first alphabetically if multiple)
2. Parse type from frontmatter, normalize spelling (userstory/user-story)
3. Read company-artifact-manifests.json (type -> required artifacts)
4. For each required artifact: match files (strip ^[A-Z]\d+_ prefix), compare frontmatter keys against template (presence only), check for unresolved {PLACEHOLDER} patterns
5. Check lifecycle (4 phases, min 4 checkboxes total)
6. Report [PASS], [MISSING], or [DRIFT] per artifact

### Artifact Manifest Schema

```json
{
  "types": {
    "feature":   { "required": [{"artifact":"tracker","template":"tracker-feature.md","filename":"TRACKER.md"}, ...] },
    "defect":    { "required": [...] },
    "task":      { "required": [...] },
    "userstory": { "required": [...] },
    "review":    { "required": [...] }
  }
}
```

Artifact counts: feature=5, defect=3, task=2, userstory=5, review=2.

## Design Decisions

| Decision | Chosen | Rejected | Why |
|----------|--------|----------|-----|
| Standalone | Zero gstack deps | Extend /docs check | Portable to any repo |
| Namespacing | Subfolder (templates/company-workflow/) | Top-level dir | Matches existing patterns |
| Validation | Skill with unified validate | Shared scripts | /docs check pattern, CI-callable |
| userstory spelling | Preserve spec exact | Normalize to user-story | Company spec is truth |
| Import method | One-time copy | Git submodule | Repo is source after commit |
| Enforcement | Own manifest | Extend artifact-manifests.json | Two independent systems |
| Unified command | File + dir modes | Separate subcommands | Simpler, one entry point |
| Artifacts | All unconditionally required | Optional tier | Wrong type = wrong artifacts |

## Delivery

The skill is designed for deployment to any machine via `skills-deploy install`.

### What Gets Deployed

```
~/.claude/skills/company-workflow/
    SKILL.md                          # skill entry point
    contract.json                     # structural validation rules
    company-artifact-manifests.json   # type->artifact mapping
    examples/                         # 13 filled-in examples (AI reads these)
    reference/guide-*.md              # 7 human reference guides
    philosophy/rationale-*.md         # 3 lifecycle rationale docs
    fixtures/                         # test fixtures

~/.claude/templates/company-workflow/
    tracker-*.md                      # 5 tracker templates
    doc-*.md                          # 8 doc templates
```

### Install on Another Machine

```bash
# Via skills-deploy (recommended):
./scripts/skills-deploy.sh install

# Manual:
cp -r skills/company-workflow/ ~/.claude/skills/company-workflow/
cp -r templates/company-workflow/ ~/.claude/templates/company-workflow/
```

After install, the 2-level fallback chain resolves templates from `~/.claude/`
when no repo-local copy exists. Examples deploy alongside the skill so AI
has reference material for doc generation on any machine.

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| skills-deploy subfolder issue | Low | Med | Shipped in v0.4.0 |
| userstory spelling confusion | Med | Med | Documented intentional divergence |
| Template changes break check | Med | Med | check reads templates dynamically |
| Deployed skill out of sync | Med | Med | skills-deploy doctor detects drift |
