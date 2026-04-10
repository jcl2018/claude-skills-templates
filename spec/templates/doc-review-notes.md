---
type: review-notes
parent: {REVIEW_ID}
title: "{Review Subject} — Code Review Notes"
date: {YYYY-MM-DD}
reviewer: {reviewer}
status: Draft
pr: "{PR URL or number}"
branch: "{branch name}"
commit: "{commit hash or range}"
verdict: Pending
---

## Review Metadata

| Field | Value |
|-------|-------|
| PR / Branch | {PR URL or branch name} |
| Commit range | {base..head or specific commit} |
| Reviewer | {name} |
| Date | {YYYY-MM-DD} |
| Files changed | {count} |
| Lines changed | +{added} / -{removed} |

## Findings

<!-- Severity: Critical (blocks merge), Major (should fix), Minor (optional), Note (informational).
     Category: correctness, performance, security, style, maintainability.
     Each finding = one row. Be specific: file:line, what's wrong, what to do. -->

| # | Severity | Category | Location | Description | Recommendation |
|---|----------|----------|----------|-------------|---------------|
| 1 | {Critical/Major/Minor/Note} | {category} | {file:line} | {what's wrong} | {what to do} |

## Summary

**Verdict:** {Approve / Request Changes / Reject}

**Key concerns:**
- {1-line summary of most important finding}

**Positive observations:**
- {what was done well}

## Follow-Up Actions

| Action | Owner | Status |
|--------|-------|--------|
| {action from findings} | {person} | Open/Done |
