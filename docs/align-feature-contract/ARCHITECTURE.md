---
type: architecture
feature: align-feature-contract
title: "Align Feature Contract — Architecture"
version: 1
status: Active
date: 2026-04-09
author: chjiang
prd: PRD.md
---

## Overview

The align-feature-contract skill implements three-level doc triplet enforcement. It reads template files to derive required sections (L1), parses frontmatter to verify cross-doc references (L2), and checks the filesystem for referenced file existence (L3). A companion test harness (`/test-align-contract`) validates the enforcement logic itself using fixture triplets.

## Architecture

```
/align-feature-contract
  |
  +-- L1: Template Alignment
  |     read templates/*.md -> extract ## headings
  |     read docs/{family}/*.md -> extract ## headings
  |     diff required vs present -> report missing
  |
  +-- L2: Cross-Doc Traceability
  |     parse ARCHITECTURE.md frontmatter -> prd: field
  |     parse TEST-SPEC.md frontmatter -> prd: + architecture: fields
  |     verify references point to sibling files
  |
  +-- L3: Reference Verification
  |     resolve prd: and architecture: paths relative to doc dir
  |     check file existence on disk
  |
  +-- Fix Mode (optional)
        add missing sections from templates
        correct broken frontmatter references

/test-align-contract (test harness)
  |
  +-- Tier 1: smoke tests (section existence, frontmatter parsing)
  +-- Tier 2: E2E (invoke skill on fixture triplets, verify output)
```

### Components Affected

| Component | Path | Change Type | Description |
|-----------|------|------------|-------------|
| Contract skill | .claude/skills/align-feature-contract/SKILL.md | Core | Three-level enforcement logic |
| Test harness | .claude/skills/test-align-contract/SKILL.md | Core | Validates enforcement with fixtures |
| Templates | templates/{PRD,ARCHITECTURE,TEST-SPEC}-TEMPLATE.md | Reference | Source of truth for required sections |
| Doc triplets | docs/{family}/{PRD,ARCHITECTURE,TEST-SPEC}.md | Target | Files being validated |

### Data Flow

1. Skill receives a family name or scans all docs/{family}/ directories
2. L1: Reads template, extracts `## ` headings as required set; reads target doc, diffs
3. L2: Parses YAML frontmatter for `prd:` and `architecture:` fields
4. L3: Resolves relative paths, checks `test -f` on each
5. Reports findings per level; fix mode writes corrections back to files

## Design Decisions

| Decision | Chosen | Rejected Alternative | Why |
|----------|--------|---------------------|-----|
| Three discrete levels | L1/L2/L3 with independent pass/fail | Single combined check | Granular reporting; users can fix L1 issues before worrying about L2 |
| Templates as section source of truth | Extract headings from template files | Hardcoded section list in skill | Templates evolve independently; skill stays in sync automatically |

## API Changes

No formal APIs. The skill is invoked as `/align-feature-contract` with an optional family path argument.

## Dependencies

| Dependency | Type | Description |
|-----------|------|-------------|
| Templates | Internal | PRD-TEMPLATE.md, ARCHITECTURE-TEMPLATE.md, TEST-SPEC-TEMPLATE.md define required sections |
| /test-align-contract | Skill | Test harness that exercises this skill's checks |

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Template section additions break existing families | Medium | Medium | Adding sections is additive; existing sections still pass |
| False positives on optional sections | Low | Low | Template marks optional sections explicitly |
| Frontmatter format changes | Low | Medium | YAML parsing is standard; field names are stable |
