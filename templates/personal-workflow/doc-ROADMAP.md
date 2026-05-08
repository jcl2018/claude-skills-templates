---
type: roadmap
parent: {FEATURE_ID}
title: "{FEATURE_NAME} — Roadmap"
date: {YYYY-MM-DD}
author: {author}
status: Draft
---

<!-- A feature's roll-up roadmap — merges what was previously in feature-summary
     + milestones. Captures scope/non-goals (the feature's identity), decomposition
     (which user-stories carry the work), and delivery timeline (when each piece
     ships). The /personal-workflow templates step produces this. -->

## Scope

<!-- One paragraph: what this feature delivers, in plain English. The high-level
     intent, not the per-story implementation. SPEC + TEST-SPEC live at the
     user-story level and own the story-scope detail. This doc is the feature's
     identity. -->

## Non-Goals

<!-- Explicit non-goals. Things this feature deliberately does NOT do, and why.
     Prevents scope creep during Implement and gives reviewers an unambiguous
     boundary. -->

- {non-goal} — {why it's excluded}

## Success Criteria

<!-- Bulleted, measurable outcomes. Each criterion should be observable from
     the outside (a user, an SLO, a stakeholder report) — not internal code
     state. If you can't measure it, it's not a success criterion; it's
     an aspiration. -->

- [ ] {measurable outcome}

## Decomposition

<!-- The user-stories that decompose this feature, with current status. The
     validator does not enforce this list, but it's the canonical map for human
     readers. Status values: Open, In Progress, Closed. -->

| User-Story | Title | Status |
|-----------|-------|--------|
| [{STORY_ID}]({STORY_ID}-{slug}/{STORY_ID}_TRACKER.md) | {Story Name} | Open |

## Delivery Timeline

<!-- Forward-looking milestones for this feature. Owner = primary person responsible.
     Status: Done, In Progress, Not Started, At Risk, Deferred.
     Blocked By = milestone number(s) that must complete first, or "—" if none.
     Forward roadmap entries go here; historical entries (PR links, merge dates
     after ship) move to the ### Delivery History sub-section below. -->

| # | Milestone | Target Date | Status | Owner | Notes | Blocked By |
|---|-----------|-------------|--------|-------|-------|------------|
| {n} | {milestone name} | {YYYY-MM-DD or —} | {status} | {person} | {context} | {#n or —} |

### Delivery History

<!-- Backward-looking record: PR links, merge dates, version bumps after ship.
     Append-only. Don't edit historical entries — they're the durable record
     of what shipped when. Use this section to absorb any pre-existing
     milestones content during a feature-summary+milestones → ROADMAP migration. -->

- {YYYY-MM-DD}: {PR# or version} — {brief description}

## Dependency Graph

<!-- Visual representation of milestone ordering. Format: #N description --> #M
     description (arrow = "blocks"). Keep in sync with the Blocked By column. -->

```
{ASCII dependency graph}
```

## Open Questions

<!-- Questions still being decided. -->

| Question | Next check |
|----------|-----------|
| {question} | {who/when} |
