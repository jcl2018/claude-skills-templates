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

<!-- A feature's cross-story design doc. Complements feature-summary.md
     (which owns scope, success criteria, constituent stories, and
     out-of-scope boundaries). DESIGN owns the engineering plan: problem
     framing, solution shape, cross-story decisions, risks, and
     objective ship criteria. Story-scope detail
     (PRD/ARCHITECTURE/TEST-SPEC) lives on the nested user-stories. -->

## Problem

<!-- 1-2 paragraphs: what gap or pain does this feature close? Give a
     reader who hasn't seen feature-summary enough context to understand
     why the feature exists. -->

## Shape of the solution

<!-- The feature at a glance — what gets built, how the pieces fit
     together, how it decomposes into user-stories. A small table
     mapping concerns to user-stories makes cross-story boundaries
     legible. feature-summary.md's Constituent User-Stories section
     lists the stories; this table explains what each one owns. -->

| Concern | User-story | Artifact |
|---------|-----------|----------|
| {concern} | {STORY_ID} | {path to STORY_ID_TRACKER.md} |

## Big decisions

<!-- Engineering choices that shape the feature, with rationale. Future
     readers need to know why this path over the rejected alternatives. -->

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

<!-- Objective, technical ship criteria. Complements feature-summary's
     Success Criteria (which owns user-facing outcomes) with
     engineering gates: CI green, deploy verified, regression suite
     extended, docs updated. Reviewers should be able to verify each
     item without asking the author. -->

- [ ] {technical/ship criterion}

## Pointers

<!-- Cross-links to related artifacts: parent tracker, feature-summary,
     milestones, upstream sources, related features/defects. Use
     relative paths from the feature directory. -->

- Parent tracker: [{FEATURE_ID}_TRACKER.md]({FEATURE_ID}_TRACKER.md)
- Feature summary: [{FEATURE_ID}_feature-summary.md]({FEATURE_ID}_feature-summary.md)
- Milestones: [{FEATURE_ID}_milestones.md]({FEATURE_ID}_milestones.md)
