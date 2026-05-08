---
type: test-spec
parent: S000017
feature: F000010
title: "scaffold-work-item skill — Test Specification"
version: 1
status: Draft
date: 2026-05-08
author: chjiang
spec: SPEC.md
reviewers: []
---

<!-- v1 test plan: manual fixture-based testing per Step 0A choice and Issue 3.1A.
     One golden fixture in skills/scaffold-work-item/fixtures/. Manual snapshot
     diff workflow. Automated regression deferred to TODOS.md P1 eval harness. -->

## Smoke Tests

| # | Tag | AC | Check | What It Validates | Script/Command |
|---|-----|-----|-------|-------------------|----------------|
| S1 | core | AC-1, AC-2, AC-3 | Skill exists in catalog and has valid frontmatter | Catalog wiring is correct; skill is discoverable | `./scripts/validate.sh` |
| S2 | core | AC-3 | Boundary check at end produces PASS on the golden fixture | Output structurally compliant | `./scripts/test.sh` (extends test runner to scaffold from fixture and `/personal-workflow check` the result) |
| S3 | resilience | AC-4 | Idempotency: scaffold twice on the fixture; second invocation is NO-OP | Idempotent contract holds | manual: re-run skill on same input, observe NO-OP message |
| S4 | resilience | AC-5 | Boundary check at start refuses on a stale work-item dir | Drift detection works | manual: introduce drift in fixtures/expected-output, re-run skill, observe refusal |

## E2E Tests

| # | Tag | AC | Scenario | Steps (as a real user would) | Expected Outcome | Rubric |
|---|-----|-----|----------|------------------------------|------------------|--------|
| E1 | core | AC-1 | Bootstrap proof: re-scaffold F000010 via the new skill | 1. Move/backup current `work-items/features/personal-workflow/F000010_pipeline_skills/`. 2. Run `/scaffold-work-item ~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-main-design-20260508-102829.md`. 3. Diff produced output against backup baseline. | Diff shows only timestamp + journal-entry differences; structure matches | PASS if structural/content match (modulo timestamps + auto-generated journal); FAIL on any artifact missing or section drift |
| E2 | core | AC-2 | User-story-level scaffold | 1. Pick a user-story-level design doc (or write a fresh one). 2. Run `/scaffold-work-item <doc-path>`. 3. Verify a single user-story dir is created with 4 artifacts. | Single user-story dir; 4 artifacts; no feature dir | PASS if shape matches manifest; FAIL on extra/missing artifacts |
| E3 | usability | AC-6 | Branch fallback (on `main`) | 1. Checkout `main`. 2. Run `/scaffold-work-item <feature-design-doc>`. 3. Confirm AskUserQuestion fires asking for type. 4. Pick "feature". | AskUserQuestion fires; feature scaffold proceeds with chosen type | PASS if AUQ fires and type used; FAIL on silent default |
| E4 | usability | AC-7 | Multi-story confirmation | 1. Pick a feature design doc with 3 alternatives. 2. Run `/scaffold-work-item <doc>`. 3. Verify AskUserQuestion proposes 3 user-story children with slugs. 4. Modify slug for one of them. | AUQ fires with proposed slugs; user can override; chosen slugs used | PASS if user can override; FAIL if scaffold ignores user input |
| E5 | usability | AC-9 | Output path printed | 1. Run any successful scaffold. 2. Inspect skill output. | Last line is the path to the new work-item dir | PASS if path is the last line and copy-paste-friendly |

## Coverage Gaps

| Gap | Why Not Tested | Risk Accepted |
|-----|----------------|---------------|
| Concurrency: two simultaneous /scaffold-work-item runs on same input | Personal use, single user, single machine | Low: edge case shouldn't occur in practice |
| Cross-machine path resolution (workbench vs deployed `~/.claude/`) | Tested manually post-deploy; existing 2-level fallback chain is well-trod | Low: existing infrastructure |
| Source design doc footer append (AC-8, P1) | Optional in v1; verify manually after first real use | Low: cosmetic regression at worst |
| Pre-existing-scaffold detection (P2 AC-10) | Nice-to-have; can be added post-v1 | Low: user can grep the SCAFFOLDED footer manually |
| Performance / token cost on large design docs | Unbounded design doc sizes uncommon; cap tested via the F000010 design (which is moderately large at ~10K tokens) | Low: latency, not correctness |
| Behavioral regression on template changes | Step 0A defers automated harness; manual fixture diff catches major drift | Medium: small drift might slip past manual diff; mitigated by 1.3A boundary check |
