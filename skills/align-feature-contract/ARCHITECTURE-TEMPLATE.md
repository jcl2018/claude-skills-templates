---
type: architecture
parent: {FEATURE_ID}
title: "{Feature Name} — Architecture"
version: 1
status: Draft
date: {YYYY-MM-DD}
author: {author}
prd: PRD.md
reviewers: []
---

## Overview

<!-- One paragraph: what this design achieves and why this approach was chosen.
     Link back to the PRD for requirements context. -->

## Architecture

<!-- High-level system design. Which components are affected? How do they interact?
     Include an ASCII diagram for any non-trivial data flow. -->

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

## API Changes

<!-- New or modified APIs, function signatures, message formats.
     Skip this section if no API changes. -->

### New APIs

| API | Signature | Description |
|-----|-----------|-------------|
| {function/method} | {params -> return} | {what it does} |

### Modified APIs

| API | Before | After | Reason |
|-----|--------|-------|--------|
| {function/method} | {old signature} | {new signature} | {why} |

## Dependencies

<!-- Technical dependencies: libraries, frameworks, other features, build requirements.
     This is the single place for all dependency tracking. -->

| Dependency | Type | Status | Notes |
|-----------|------|--------|-------|
| {dependency} | Code/Infra/Feature | Available/Pending | {notes} |

## Risk Assessment

<!-- What could go wrong? What are the unknowns? -->

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| {risk} | Low/Med/High | Low/Med/High | {mitigation strategy} |

## Design Decisions

<!-- Choices made and alternatives rejected. Future readers need to know why. -->

| Decision | Chosen | Rejected Alternative | Why |
|----------|--------|---------------------|-----|
| {decision} | {chosen approach} | {alternative considered} | {rationale} |
