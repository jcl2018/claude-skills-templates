---
type: test-spec
parent: S000018
feature: F000010
title: "implement-from-spec skill — Test Specification"
version: 1
status: Draft
date: 2026-05-08
author: chjiang
spec: SPEC.md
reviewers: []
---

<!-- v1 test plan: manual fixture-based testing per Step 0A choice. One golden
     fixture in skills/implement-from-spec/fixtures/. Note: LLM non-determinism
     means "code matches expected" is unrealistic; "code passes the SPEC's AC"
     is the realistic test. -->

## Smoke Tests

| # | Tag | AC | Check | What It Validates | Script/Command |
|---|-----|-----|-------|-------------------|----------------|
| S1 | core | AC-1 | Skill exists in catalog and has valid frontmatter | Catalog wiring correct | `./scripts/validate.sh` |
| S2 | core | AC-1, AC-2, AC-3 | Tracker updates: journal entries appear, Phase 2 gates transition | Skill mutates tracker correctly | manual: scaffold a small fixture user-story, run skill, inspect tracker |
| S3 | resilience | AC-4 | Idempotency: re-run on completed user-story is a NO-OP | Idempotent contract holds | manual: re-run, observe NO-OP message |
| S4 | resilience | AC-5, AC-6 | Boundary check refuses on broken handoff (e.g., missing SPEC) | Drift detection works on entry/exit | manual: delete SPEC.md from fixture, run skill, observe refusal |

## E2E Tests

| # | Tag | AC | Scenario | Steps (as a real user would) | Expected Outcome | Rubric |
|---|-----|-----|----------|------------------------------|------------------|--------|
| E1 | core | AC-1 | Implement S000017 (scaffold-work-item skill itself) using this skill, after S000017 ships | 1. Run `/implement-from-spec work-items/features/personal-workflow/F000010_pipeline_skills/S000017_scaffold_work_item/`. 2. Approve proposed changes. 3. Verify skill file written, catalog updated, fixture authored, tracker journal populated. 4. Run `/personal-workflow check` on the dir. | Phase 2 gates green; skill SKILL.md exists and matches SPEC's architecture; /personal-workflow check PASS | PASS if SPEC's AC are verifiable in the produced code; FAIL on missing core requirement |
| E2 | usability | AC-7 | Feature dir mistake | 1. Run `/implement-from-spec work-items/features/personal-workflow/F000010_pipeline_skills/`. 2. Confirm AUQ lists 3 user-story children. | AUQ fires with S000017/S000018/S000019 listed; user picks one | PASS if AUQ fires with correct children; FAIL on silent default |
| E3 | usability | AC-9 | Propose-and-confirm default | 1. Run skill on a non-trivial user-story without --auto. 2. Inspect proposed diff before approving. | Diff preview shown; AUQ asks "Apply / Modify / Cancel" | PASS if preview is readable and AUQ fires; FAIL on silent write |
| E4 | usability | AC-10 | --auto on trivial change | 1. Pick a user-story whose SPEC touches 1 file. 2. Run with `--auto`. | Skill writes directly; tracker entry says "auto-mode" | PASS if no AUQ fired and tracker records auto-mode; FAIL otherwise |
| E5 | usability | AC-8 | Sensitive surface protection | 1. Pick a user-story whose SPEC touches `skills-catalog.json`. 2. Run skill. | AUQ fires before commit; user must approve | PASS if AUQ fires; FAIL on silent commit |

## Coverage Gaps

| Gap | Why Not Tested | Risk Accepted |
|-----|----------------|---------------|
| LLM determinism — same SPEC produces different code | Inherent LLM behavior; goal is "code passes SPEC's AC" not "code identical to fixture" | Medium: test fixture asserts AC met, not byte-equality |
| Multi-language code generation correctness | Same skill handles all; LLM picks based on existing repo language | Medium: covered by SPEC's Components Affected |
| Sensitive surface coverage | AC-8 only tests catalog-touching SPECs; manifest + validator surfaces equally protected by code | Low: one path tests the contract |
| Behavioral regression on prior-implemented stories | Step 0A defers automated harness; manual fixture diff catches major drift | Medium: small drift might slip past manual diff |
| Concurrency: two simultaneous skill runs on same user-story | Personal use, single user, single machine | Low: shouldn't occur in practice |
| --auto config-level default (P2 NOT in v1) | Deferred to v2 per Open Q | Low: v1 ships --auto as per-invocation only |
