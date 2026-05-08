---
type: design
parent: S000019
title: "qa-work-item skill — Design"
version: 1
status: Draft
date: 2026-05-08
author: chjiang
reviewers: []
---

<!-- Atomic story scaffold; the parent feature's DESIGN.md is the primary
     context. This DESIGN.md is a brief stub. -->

## Problem

`/qa-work-item` is the third pipeline skill the user invokes per user-story (after `/scaffold-work-item` and `/implement-from-spec`). The May 5 design said "E2E walked once before ship" was a deliberate human checkpoint. The today's office-hours session changed that premise: an LLM subagent acting as a QA engineer can run E2E autonomously with autoplan-style prompts only on red/ambiguous results. This generalizes E2E beyond pre-scripted bash harnesses.

See parent: [F000010_DESIGN.md](../F000010_DESIGN.md) for the full feature shape.

## Shape of the solution

| Concern | User-story | Artifact |
|---------|-----------|----------|
| Read TEST-SPEC + implementation context | S000019 | this story |
| Run smoke tests (script-driven) | S000019 | this story |
| Delegate E2E to QA engineer subagent | S000019 | this story |
| Write structured findings to tracker; gate phase transition | S000019 | this story |

## Big decisions

| # | Decision | Why |
|---|----------|-----|
| 1 | QA engineer subagent (always invoked for E2E) | User's invention from /office-hours. Generalizes E2E beyond pre-scripted harnesses. The subagent reads TEST-SPEC and figures out HOW to verify each criterion |
| 2 | Smoke runs first (script-driven), E2E second (subagent) | Cheap test first; if smoke red, short-circuit before spending subagent tokens on a broken implementation |
| 3 | Subagent prompt: stable preamble first, variable data after | Prompt cache friendliness; ~2x cost reduction over runs |
| 4 | Subagent return: 1-2 sentences + file pointers | Premise 1: short reports keep orchestrator context small. Detailed findings written to tracker by subagent, not returned to parent |
| 5 | Decision gate: AskUserQuestion only on red/ambiguous, silent on green | Autoplan-style; user only intervenes when something needs intervention |
| 6 | Subagent timeout: hard 5-minute cap | Bounded latency; on timeout, write entry + AskUserQuestion (no automatic retry) |

## Risks & open questions

| Risk / Question | Next check |
|-----------------|-----------|
| Where does the QA engineer prompt template live? (Open Q1 of source design) | Implementation; recommendation: hardcoded in SKILL.md for v1; extract to `prompts/qa-engineer.md` if reuse demands |
| TEST-SPEC drift — what if implementation skipped a TEST-SPEC criterion? | Subagent reports as red; AskUserQuestion to add the test or strike the criterion |
| Subagent calling Claude Code tools — does it have full tool access? | Implementation: verify Agent tool grants Bash + Read + Edit (yes per docs); no Write to source code (read-only) |
| Subagent prompt injection from TEST-SPEC | Low risk for personal-use workbench; flag if scaling to multi-user consumers |
| Subagent reads files outside the work-item dir (e.g., implementation files anywhere in repo) | Expected behavior; the QA engineer needs to read implementation to verify it. Document this in SKILL.md |

## Definition of done

- [ ] Skill file written, validated by `validate.sh`, deployed by `skills-deploy install`
- [ ] Acceptance criteria in [TRACKER.md](S000019_TRACKER.md) all green
- [ ] Golden fixture authored: small TEST-SPEC + small implementation + expected findings
- [ ] Subagent prompt verified cache-friendly (inspect token cost on second run)

## Not in scope

- Adversarial QA subagent ("try to break this") — deferred; v1 has one QA engineer subagent
- Auto-rerun on flaky tests — out; if smoke flakes, user re-runs the skill
- Cross-machine non-script E2E generalization — v2

## Pointers

- Parent: [S000019_TRACKER.md](S000019_TRACKER.md)
- Spec: [S000019_SPEC.md](S000019_SPEC.md)
- Test spec: [S000019_TEST-SPEC.md](S000019_TEST-SPEC.md)
- Feature design: [F000010_DESIGN.md](../F000010_DESIGN.md)
