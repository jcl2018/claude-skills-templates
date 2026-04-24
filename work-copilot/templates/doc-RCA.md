---
type: rca
parent: {DEFECT_ID}
title: "{Defect Name} — Root Cause Analysis"
date: {YYYY-MM-DD}
author: {author}
severity: P1/P2/P3
status: Draft
---

## Symptom

<!-- What was observed? Be concrete: error message, incorrect behavior, crash,
     data corruption. Include reproduction frequency (always, intermittent, specific conditions). -->

## Reproduction Steps

<!-- Minimal steps to reproduce the issue. -->

1. {step}
2. {step}
3. **Observe:** {what goes wrong}

**Environment:** {OS, build version, configuration that matters}

## Investigation Trail

<!-- Timestamped log of investigation steps. This is the reasoning chain,
     not just the conclusion. Each entry: what was tried, what was found. -->

| Time | Action | Finding |
|------|--------|---------|
| {HH:MM} | {what was investigated} | {what was learned} |

## Root Cause

<!-- One clear statement of WHY the bug happens. Not what the fix is, but what
     is wrong in the existing code/logic/data. -->

**Root cause:** {statement}

**Location:** {file:line or component}

## Affected Components

<!-- What parts of the system are impacted by this root cause? -->

| Component | File/Module | Impact |
|-----------|------------|--------|
| {component} | {path} | {how it is affected} |

## Fix Description

<!-- What was changed to fix the root cause. Not a diff, but a human-readable
     explanation of the approach. -->

## Regression Risk

<!-- What could break as a result of the fix? What areas need extra testing? -->

| Area | Risk Level | Why | Mitigation |
|------|-----------|-----|------------|
| {area} | Low/Med/High | {reason} | {how to verify} |
