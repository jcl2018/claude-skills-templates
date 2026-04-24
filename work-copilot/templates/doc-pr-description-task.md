---
type: pr-description
parent: {TASK_ID}
title: "{Task Name} — PR Description"
date: {YYYY-MM-DD}
author: {author}
status: Draft
---

<!--
PR Description Template — TASK
TFS limit: 4,000 chars. Self-contained — TFS reviewers cannot click links to
local files (RCA.md, test-plan.md, etc.). Inline-summarize whatever they need.

To paste:
  1. Strip this comment block and the YAML frontmatter above.
  2. Fill in {placeholders}. Keep prose tight — every sentence costs ~80 chars.
  3. Paste the body below into the TFS PR description field.
  4. Verify length under 4,000 chars before submitting.
-->

[{TASK_ID}] {Task Name}

## Summary

{One sentence: what the change does and the mechanism. Not just the symptom.}

## Motivation

{1-2 sentences pulled from the parent work item or task scope. Why this change
is needed — the underlying requirement, constraint, or technical context
(concurrency, lifecycle, ownership, perf) reviewers need to evaluate the "why".}

## Changes

- {Structural change 1 — self-contained, verifiable against the diff}
- {Structural change 2}
- {Structural change 3}

## Affected Workflows

**{Workflow}:** {One sentence: old behavior (if relevant) → new behavior.}
**{Workflow}:** {One sentence.}

## Test Plan

{One line: coverage strategy — unit / integration / manual / mix, and why.}

| # | Scenario | Verified By | Result |
|---|----------|-------------|--------|
| 1 | {scenario} | {test path or manual steps} | Pass |
| 2 | {scenario} | {test path or manual steps} | Pass |
| 3 | {scenario} | {test path or manual steps} | Pass |
