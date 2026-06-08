---
type: test-plan
parent: T000045
title: "Add a CI/CD topic to docs/philosophy.md — Test Plan"
date: 2026-06-07
author: Charlie
status: Draft
---

<!-- Scope: ONE task. Cases must be concrete and reproducible. -->

## Scope

Add a new **`## Topic: CI/CD`** topic to `docs/philosophy.md` that lifts the
verification-layer model now formalized in `gate-spec.md` (the four layers —
local-hook / CI / pipeline-gate / ratchet — and the one-owning-layer-per-guarantee
division of labor) into the philosophy as a named topic, with a principle-style
section under it. The front summary table is updated to include the new topic, the
existing `## Decision tree: which CJ_ skill do I call?` heading stays LAST, and the
doc remains a clean human-doc (no work-item IDs). Only `docs/philosophy.md` changes.

## Regression Test Cases

| # | Test Case | Steps | Expected Result | Status |
|---|-----------|-------|-----------------|--------|
| 1 | New topic present | `grep -n '^## Topic: CI/CD' docs/philosophy.md` | exactly one match | Pending |
| 2 | Four layers named | grep the new topic for the layer ids | local-hook, ci, pipeline-gate, ratchet all named | Pending |
| 3 | Points at gate-spec.md | `grep -n 'gate-spec.md' docs/philosophy.md` | the new topic references gate-spec.md as the concrete map | Pending |
| 4 | Front table updated | inspect the summary table before the first `## ` heading | a CI/CD row is present (Check 20 stays green) | Pending |
| 5 | Decision tree still last | `grep -n '^## ' docs/philosophy.md \| tail -1` | last `## ` heading is `## Decision tree: which CJ_ skill do I call?` | Pending |
| 6 | No work-item IDs (human-doc) | `grep -nE '[FSTD][0-9]{6}' docs/philosophy.md` | zero matches (Check 19 hard lint) | Pending |
| 7 | validate.sh green | `./scripts/validate.sh` | exit 0, 0 errors (Checks 15/15a/15b/16/17/19/20 + New-skills) | Pending |

## Verification Steps

- [ ] `./scripts/validate.sh` passes (0 errors) — the philosophy.md human-doc lints (Check 19 no work-item IDs, Check 20 front-table) and the doc-spec checks all green.
- [ ] `docs/philosophy.md` reads coherently: the new CI/CD topic complements rather than duplicates the existing "Verification is a continuous gate" principle (the principle is the *why*; the CI/CD topic is the *concrete layered model*), with a cross-reference between them.
- [ ] Only `docs/philosophy.md` is changed by the implement step (plus the work-item tracker).

## Environments Tested

| Environment | Build | Result |
|------------|-------|--------|
| local macOS | current branch (off main 65df18e) | Pending |
