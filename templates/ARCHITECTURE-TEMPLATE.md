---
type: architecture
parent: {PARENT_ID}
feature: {FEATURE_ID}
title: "{Feature Name} — Architecture"
version: 1
status: Draft
date: {YYYY-MM-DD}
author: {author}
prd: PRD.md
---

## Overview

<!-- One paragraph: what this design achieves and why this approach was chosen.
     Link back to the PRD for requirements context.
     If there are multiple related components (e.g., a main skill and its test harness),
     introduce all of them here so readers see the full picture upfront. -->

## Architecture

<!-- High-level system design. Which components are affected? How do they interact?
     Include an ASCII diagram for any non-trivial data flow. -->

```
{ASCII architecture diagram}
```

### Components Affected

| Component | Path | Change Type | Description |
|-----------|------|------------|-------------|
| {component} | {file or directory path} | New / Modified | {what changes} |

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

<!-- Technical dependencies: libraries, frameworks, other features, build requirements. -->

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
