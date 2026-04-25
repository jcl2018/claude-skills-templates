---
type: architecture
parent: S000004
feature: F000003_company_workflow
title: "env-var-resolution — Architecture"
version: 1
status: Draft
date: 2026-04-16
author: chjiang
prd: PRD.md
reviewers: []
---

## Overview

<!-- One paragraph: what this design achieves and why this approach was chosen.
     Link back to the PRD for requirements context.
     If there are multiple related components (e.g., a main skill and its test harness),
     introduce all of them here so readers see the full picture upfront. -->

Extend the `company-workflow` skill's existing Path Resolution section (see SKILL.md) with a knowledge-directory resolution block. The block reads `AI_KNOWLEDGE_DIR`, validates that the path exists and is a directory, exposes the result as a skill-local variable (`$_KNOWLEDGE_DIR`), and emits a one-line warning on stderr when resolution fails. This design reuses the skill's existing "bash preamble" pattern — no new infrastructure, no new files, no external dependencies.

## Architecture

<!-- High-level system design. Which components are affected? How do they interact?
     Include an ASCII diagram for any non-trivial data flow. -->

```
┌──────────────────────────────────────────────────────────────────┐
│  company-workflow skill invocation                               │
│                                                                  │
│  ┌─────────────────────┐   ┌───────────────────────┐             │
│  │ Preamble            │──▶│ Path Resolution       │             │
│  │ (git check)         │   │ (skill dir, tmpl dir) │             │
│  └─────────────────────┘   └───────────┬───────────┘             │
│                                        │                         │
│                                        ▼                         │
│                            ┌───────────────────────┐             │
│                            │ Knowledge Resolution  │◀── NEW      │
│                            │ (read AI_KNOWLEDGE_DIR│             │
│                            │  → $_KNOWLEDGE_DIR    │             │
│                            │  or warn)             │             │
│                            └───────────┬───────────┘             │
│                                        │                         │
│                                        ▼                         │
│                            ┌───────────────────────┐             │
│                            │ Command: validate     │             │
│                            │ (unchanged)           │             │
│                            └───────────────────────┘             │
└──────────────────────────────────────────────────────────────────┘
```

### Components Affected

| Component | Repo | Change Type | Description |
|-----------|------|------------|-------------|
| skills/company-workflow/SKILL.md | claude-skills-templates | Modified | Add Knowledge Resolution section after Path Resolution |
| skills/company-workflow/WORKFLOW.md | claude-skills-templates | Modified | Document `AI_KNOWLEDGE_DIR` under Installation / Configuration |
| scripts/test.sh | claude-skills-templates | Modified | Tier 1 smoke checks + Tier 2 extract-and-exec scenarios (shipped as T000003) |

### Data Flow

<!-- How does data move through the system for the primary use case?
     Step-by-step, component to component. -->

1. User invokes a `company-workflow` command (e.g. `validate`)
2. Skill preamble runs: verify git repo
3. Skill Path Resolution runs: locate `$_SKILL_DIR` and `$_TMPL_DIR` via 2-level fallback
4. **NEW: Knowledge Resolution runs**:
   - Read `$AI_KNOWLEDGE_DIR`
   - If unset or empty → emit warning, set `$_KNOWLEDGE_DIR=""`
   - If set but `! -d "$AI_KNOWLEDGE_DIR"` → emit warning with the path, set `$_KNOWLEDGE_DIR=""`
   - If set and valid → set `$_KNOWLEDGE_DIR="$AI_KNOWLEDGE_DIR"`, no warning
5. Skill command executes (unchanged); `$_KNOWLEDGE_DIR` is available for later stories to consume

## API Changes

<!-- New or modified APIs, function signatures, message formats.
     Skip this section if no API changes. -->

### New APIs

| API | Signature | Description |
|-----|-----------|-------------|
| `$_KNOWLEDGE_DIR` (skill-local var) | string (absolute path or empty) | Populated by Knowledge Resolution; consumed by S00000X always-on and S00000X on-demand |

### Modified APIs

| API | Before | After | Reason |
|-----|--------|-------|--------|
| (none) | — | — | No user-facing command signatures change in this story |

## Dependencies

<!-- Technical dependencies: libraries, frameworks, other features, build requirements.
     This is the single place for all dependency tracking. -->

| Dependency | Type | Status | Notes |
|-----------|------|--------|-------|
| company-workflow Path Resolution block | Code | Available | Must run first; Knowledge Resolution appends to the same bash preamble |
| Bash 3.2+ | Infra | Available | `[ -d ... ]` test + parameter expansion; macOS default shell compatible |

## Risk Assessment

<!-- What could go wrong? What are the unknowns? -->

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Warning becomes noisy after engineers configure knowledge elsewhere (e.g. project-level override in later feature) | Med | Low | Revisit warning cadence when multi-source support lands (deferred per feature Journal); for v1 accept the noise |
| Engineer sets `AI_KNOWLEDGE_DIR` to a file by mistake instead of a dir | Low | Low | `[ -d "$AI_KNOWLEDGE_DIR" ]` explicitly checks directory, emits distinct warning |
| Warning suppression becomes P2 scope creep | Med | Low | Explicitly deferred to Out of Scope; reopen as its own story if users ask |
| `$_KNOWLEDGE_DIR` name collides with future skill changes | Low | Low | Underscore prefix follows existing convention (`$_SKILL_DIR`, `$_TMPL_DIR`); document in SKILL.md |

## Design Decisions

<!-- Choices made and alternatives rejected. Future readers need to know why. -->

| Decision | Chosen | Rejected Alternative | Why |
|----------|--------|---------------------|-----|
| Expose resolved path as skill-local variable | `$_KNOWLEDGE_DIR` (underscore prefix) | Global `$KNOWLEDGE_DIR` | Matches existing `$_SKILL_DIR` / `$_TMPL_DIR` convention; avoids polluting the engineer's shell namespace |
| Value when resolution fails | Empty string `""` | Unset / the literal path anyway | Empty is trivially testable with `[ -z "$_KNOWLEDGE_DIR" ]` in downstream stories; literal-path would fool Layer 2/3 into trying to load from a bad dir |
| Where the warning is emitted | Skill preamble (once per invocation) | Per-command, or lazily when first accessed | Preamble = always visible, deterministic; per-command would duplicate; lazy means engineers miss the setup nudge |
| Warning text form | One line, names the var, points to docs | Multi-line with install instructions | One line stays in scroll-back; full instructions live in WORKFLOW.md; link via a short `See: ...` pointer |
| Skip validation of directory readability | Only check `-d` | Check `-d && -r` | macOS + Linux default perms make the extra check rarely useful; keep the bash block minimal; revisit if a user hits the edge |
