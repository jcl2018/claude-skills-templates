---
type: design
parent: {FEATURE_ID}
title: "{FEATURE_NAME} — Feature Design"
version: 1
status: Draft
date: {YYYY-MM-DD}
author: {author}
reviewers: []
---

<!-- A feature's cross-story design doc. Captures the PROBLEM, the SHAPE of
     the solution, the BIG DECISIONS with rationale, the RISKS, the
     DEFINITION OF DONE, and out-of-scope boundaries. Story-scope detail
     (PRD/ARCHITECTURE/TEST-SPEC) lives on the nested user-stories — do
     not duplicate it here. For a filled-in example, see
     `work-items/features/F000004_work_copilot/F000004_DESIGN.md`. -->

## Problem

<!-- 1-2 paragraphs: what gap or pain does this feature close? Give a
     reader who hasn't seen the tracker enough context to understand why
     the feature exists. -->

## Shape of the solution

<!-- The feature at a glance — what gets built, how the pieces fit
     together, how it decomposes into user-stories. A small table mapping
     concerns to user-stories makes cross-story boundaries legible. -->

| Concern | User-story | Artifact |
|---------|-----------|----------|
| {concern} | {STORY_ID} | {path to STORY_ID_TRACKER.md} |

## Big decisions

<!-- Choices that shape the feature, with rationale. Future readers need
     to know why this path over the rejected alternatives. -->

| # | Decision | Why |
|---|----------|-----|
| 1 | {decision} | {rationale over rejected alternative} |

## Risks & open questions

<!-- What could go wrong, and what's still undecided. Each row should
     have a "Next check" naming who/when resolves it — otherwise it
     will rot. -->

| Risk / Question | Next check |
|-----------------|-----------|
| {risk or open question} | {how/when it resolves} |

## Definition of done

<!-- Objective, measurable criteria for "shipped." Not aspirations. A
     reviewer should be able to verify each item without asking the
     author. -->

- [ ] {criterion}

## Not in scope

<!-- Explicit non-goals. Prevents scope creep and gives reviewers an
     unambiguous boundary. -->

- {non-goal} — {why excluded}

## Pointers

<!-- Cross-links to related artifacts: parent tracker, milestones,
     upstream sources, related features/defects. Use relative paths
     from the feature directory. -->

- Parent tracker: [{FEATURE_ID}_TRACKER.md]({FEATURE_ID}_TRACKER.md)
- Milestones: [{FEATURE_ID}_milestones.md]({FEATURE_ID}_milestones.md)
