---
type: test-plan
parent: D888000
title: "Greeting suffix fix fixture — Test Plan"
date: 2026-05-08
author: chjiang
status: Draft
---

<!-- Synthetic test plan for /CJ_implement-from-spec defect-path fixture.
     Acts as the de-facto SPEC: defines post-fix behavior the implementation
     must produce. Parallels example-user-story/S888000_TEST-SPEC.md but in
     test-plan format (the defect/task input artifact shape). -->

## Scope

The fix produces a single file: `output/fixed.txt` (relative to the fixture dir) with exact content `Hello from defect fix\n`.

Modified files: 1 (the new file under output/).

## Regression Test Cases

| # | Test Case | Steps | Expected Result | Status |
|---|-----------|-------|-----------------|--------|
| 1 | File exists post-fix | After `/CJ_implement-from-spec` runs on this fixture, check that `skills/CJ_implement-from-spec/fixtures/example-defect/output/fixed.txt` exists | File exists | Pending |
| 2 | Content is exact | Read the file's content with `cat` (or equivalent) | Output is exactly `Hello from defect fix\n` (one line, trailing newline; no extra whitespace, no surrounding quotes, no different capitalization) | Pending |
| 3 | Tracker journal recorded | After dogfood, grep `D888000_TRACKER.md` for `[impl-pass]` | At least one `[impl-pass]` line dated today | Pending |

## Verification Steps

- [ ] Local build succeeds (no language-specific build needed; markdown + filesystem ops only)
- [ ] L1 regression suite passes (N/A for fixture; the dogfood IS the regression test)
- [ ] Manual reproduction of original bug confirms fix: file existed before? `rm` first, then re-run skill, observe file appears
- [ ] After dogfood, run `/CJ_personal-workflow check skills/CJ_implement-from-spec/fixtures/example-defect/` — should be PASS (or warn-only)

## Environments Tested

| Environment | Build | Result |
|------------|-------|--------|
| macOS (darwin) — workbench dev | feat/pipeline-parity | Pending |
