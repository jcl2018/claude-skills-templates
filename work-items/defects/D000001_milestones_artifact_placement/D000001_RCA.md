---
type: rca
parent: D000001
title: "Milestones artifact mapped to wrong work item type — Root Cause Analysis"
date: 2026-04-13
author: chjiang
severity: P3
status: Complete
---

## Symptom

`artifact-manifests.json` lists `doc-milestones.md` as a required artifact for the `user-story` type. Milestones track the delivery timeline of an entire feature (which spans multiple stories and tasks), not individual user stories. This means scaffolding a user-story creates a milestones doc at the wrong level, and scaffolding a feature does not create one at all.

Reproduction frequency: always (deterministic, configuration-level defect).

## Reproduction Steps

1. Read `artifact-manifests.json`, inspect `types.user-story.required`
2. Find `{"artifact": "milestones", "template": "doc-milestones.md", "filename": "milestones.md"}` in the array
3. **Observe:** milestones is required for user-story but absent from feature

**Environment:** any (configuration file, no runtime dependency)

## Investigation Trail

| Time | Action | Finding |
|------|--------|---------|
| 19:00 | Read artifact-manifests.json | milestones entry at types.user-story.required[4] |
| 19:01 | Read rules/work-items.md | user-story line includes doc-milestones.md, feature line does not |
| 19:02 | Search work-items/ for existing milestones files | S000001_milestones.md found at story level, needs migration to feature level |
| 19:03 | Review git history for when milestones was added | Part of v2.0.0 manifest, grouped with user-story doc set |

## Root Cause

**Root cause:** During the v2.0.0 artifact manifest design, `doc-milestones.md` was grouped with the user-story document set (PRD, ARCHITECTURE, TEST-SPEC) because all four were new doc artifacts added at the same time. The grouping was by "when added" rather than "what level of the hierarchy they serve." PRD/ARCHITECTURE/TEST-SPEC correctly belong at user-story level. Milestones does not.

**Location:** `artifact-manifests.json:35` (types.user-story.required array) and `rules/work-items.md:10` (user-story artifact list)

## Affected Components

| Component | File/Module | Impact |
|-----------|------------|--------|
| Artifact manifest | artifact-manifests.json | Wrong type mapping for milestones |
| Work item rules | rules/work-items.md | Rules doc inconsistent with intended hierarchy |
| /docs check | skills/docs/check.md | Would validate milestones at wrong level |

## Fix Description

Move the milestones entry from `types.user-story.required` to `types.feature.required` in `artifact-manifests.json`. Update `rules/work-items.md` to list `doc-milestones.md` under feature instead of user-story. The template file `doc-milestones.md` itself is unchanged.

## Regression Risk

| Area | Risk Level | Why | Mitigation |
|------|-----------|-----|------------|
| /docs check | Low | Will now expect milestones.md at feature level | Existing features (F000001, F000002) will be flagged as missing milestones — this is correct behavior |
| Scaffolding | Low | New user-stories will no longer get milestones.md | Correct — milestones belong at feature level |
| validate.sh | Low | Checks catalog/manifest consistency | Run validate.sh to confirm no regressions |
