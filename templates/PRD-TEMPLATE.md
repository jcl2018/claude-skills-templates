---
type: prd
parent: {PARENT_ID}
feature: {FEATURE_ID}
title: "{Feature Name} — Product Requirements"
version: 1
status: Draft
date: {YYYY-MM-DD}
author: {author}
---

## Problem Statement
<!-- What problem does this feature solve? Who has this problem?
     Be specific: name the user, their role, and the pain they experience today. -->

## Mental Model
<!-- If the feature has layers, phases, or modes, add a diagram or short
     explanation here so readers understand the structure before reading
     individual stories. For simple features, a one-sentence summary suffices. -->

## User Stories

<!-- P0 = must-have for first release. P1 = important, ship soon after. P2 = nice-to-have.
     "What it asks" = one plain-English question per story. No codes or abbreviations.
     "Tag" = domain keyword(s) so reviewers can quickly classify each story.
       Standard vocabulary: core, resilience, observability, usability, security, integration.
       Use the same tag in the AC heading: ### Story #N: Title [tag].
     The test: can a reader understand what this story checks without consulting another doc? -->

### P0 (Must-Have)

| # | Tag | What it asks | As a... | I want to... | So that... |
|---|-----|-------------|---------|-------------|------------|
| 1 | {tag} | {plain-English question this story answers} | {role} | {action} | {outcome} |

### P1 (Important)

| # | Tag | What it asks | As a... | I want to... | So that... |
|---|-----|-------------|---------|-------------|------------|
| | | | | | |

### P2 (Nice-to-Have)

| # | Tag | What it asks | As a... | I want to... | So that... |
|---|-----|-------------|---------|-------------|------------|
| | | | | | |

## Acceptance Criteria

<!-- Given/When/Then format. One block per user story or logical group. -->

### Story #{n}: {title} [{tag}]

```
GIVEN {precondition}
WHEN  {action}
THEN  {expected result}
```

## Success Metrics

<!-- How do you measure whether this feature succeeded? Concrete, measurable. -->

| Metric | Target | How Measured |
|--------|--------|-------------|
| {metric} | {target value} | {measurement method} |

## Out of Scope

<!-- Explicitly list what this feature does NOT do. Prevents scope creep. -->

- {item that is explicitly deferred or excluded}

## Assumptions

<!-- What this PRD takes for granted. If an assumption is wrong, revisit the PRD. -->

- {assumption about the environment, users, or system}
