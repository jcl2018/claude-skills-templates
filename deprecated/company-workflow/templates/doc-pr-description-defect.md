---
type: pr-description
parent: {DEFECT_ID}
title: "{Defect Name} — PR Description"
date: {YYYY-MM-DD}
author: {author}
severity: P1/P2/P3
status: Draft
---

<!--
PR Description Template — DEFECT
TFS limit: 4,000 chars. Self-contained — TFS reviewers cannot click links to
local files (RCA.md, test-plan.md, etc.). Inline-summarize the headline facts
from RCA.md and test-plan.md so the reviewer can approve without leaving TFS.

To paste:
  1. Strip this comment block and the YAML frontmatter above.
  2. Fill in {placeholders}. Keep prose tight — every sentence costs ~80 chars.
  3. Paste the body below into the TFS PR description field.
  4. Verify length under 4,000 chars before submitting.
-->

[{DEFECT_ID}] {Defect Name} (P{N})

## Summary

{One sentence: "Fix {symptom} caused by {root cause}, by {mechanism}."}

## Symptom

{2-3 sentences pulled from RCA.md: what users observed, frequency
(always / intermittent / specific conditions), and user impact (data loss,
blocked workflow, visible glitch, perf degradation).}

## Root Cause

{1-2 sentences pulled from RCA.md: WHY the bug happens — the failure
mechanism (concurrency / lifecycle / ownership / state machine / off-by-one).
Not the fix, the cause.}

**Location:** {file:line or component}

## Fix

{2-3 sentences: what changed and why this breaks the failure mechanism above.
The reviewer should be able to map fix-to-cause from this paragraph alone.}

## Changes

- {Structural change 1 — self-contained, verifiable against the diff}
- {Structural change 2}
- {Structural change 3}

## Test Coverage

{One line summarizing test strategy — what proves the bug is fixed and what
prevents the failure mode from recurring elsewhere.}

| # | Scenario | Verified By | Result |
|---|----------|-------------|--------|
| 1 | {original bug — fails before fix, passes after} | {test path or manual steps} | Pass |
| 2 | {related failure-mode scenario} | {test path or manual steps} | Pass |
| 3 | {regression risk scenario} | {test path or manual steps} | Pass |
