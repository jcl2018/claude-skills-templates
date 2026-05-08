---
type: spec
parent: {USER_STORY_ID}
feature: {FEATURE_ID}
title: "{User Story Name} — Specification"
version: 1
status: Draft
date: {YYYY-MM-DD}
author: {author}
reviewers: []
---

<!-- The user-story spec — merges what was previously in PRD + ARCHITECTURE.
     Captures the requirements (what to build) AND the architecture decisions
     (how to build it) in one cohesive doc. The /personal-workflow templates
     step produces this; the engineer locks it before implementing. -->

## Problem Statement

<!-- What problem does this user-story solve? Who has this problem?
     Be specific: name the user, their role, and the pain they experience today. -->

## Mental Model

<!-- If the story has layers, phases, or modes, add a diagram or short
     explanation here so readers understand the structure before reading
     individual requirements. For simple stories, a one-sentence summary suffices. -->

## Requirements

<!-- P0 = must-have for first release. P1 = important, ship soon after. P2 = nice-to-have.
     "What it asks" = one plain-English question per row. No codes or abbreviations.
     "Tag" = domain keyword(s). Standard vocabulary: core, resilience, observability,
     usability, security, integration. Use the same tag in the AC heading.
     The validator's Step 18 (cross-reference traceability) parses these P0/P1/P2
     sub-sections and matches story numbers against TEST-SPEC's AC column. Preserve
     the sub-section structure even if a tier is empty. -->

### P0 (Must-Have)

| # | Tag | What it asks | As a... | I want to... | So that... |
|---|-----|-------------|---------|-------------|------------|
| 1 | {tag} | {plain-English question this row answers} | {role} | {action} | {outcome} |

### P1 (Important)

| # | Tag | What it asks | As a... | I want to... | So that... |
|---|-----|-------------|---------|-------------|------------|
| | | | | |

### P2 (Nice-to-Have)

| # | Tag | What it asks | As a... | I want to... | So that... |
|---|-----|-------------|---------|-------------|------------|
| | | | | |

## Acceptance Criteria

<!-- Given/When/Then format. One block per requirement or logical group.
     Each #n header should match the # column in the Requirements tables. -->

### Story #{n}: {title} [{tag}]

```
GIVEN {precondition}
WHEN  {action}
THEN  {expected result}
```

## Architecture

<!-- High-level system design for this story. Which components are affected?
     How do they interact? Include an ASCII diagram for any non-trivial data flow.
     This is the "how" — paired with Requirements above (the "what"). -->

```
{ASCII architecture diagram}
```

### Components Affected

| Component | Repo | Change Type | Description |
|-----------|------|------------|-------------|
| {component} | {repo path} | New / Modified | {what changes} |

### Data Flow

<!-- How does data move through the system for the primary use case?
     Step-by-step, component to component. -->

1. {step}

## Tradeoffs

<!-- Design decisions made in this spec, with rejected alternatives and rationale.
     Future readers need to know why this path over the others. -->

| Decision | Chosen | Rejected Alternative | Why |
|----------|--------|---------------------|-----|
| {decision} | {chosen approach} | {alternative considered} | {rationale} |

## Open Questions

<!-- Questions still being decided. Each row should name "Next check" — who/when
     resolves it. Otherwise it rots. -->

| Question | Next check |
|----------|-----------|
| {question} | {who/when} |
