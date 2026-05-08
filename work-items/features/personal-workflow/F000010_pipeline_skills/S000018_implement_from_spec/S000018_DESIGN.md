---
type: design
parent: S000018
title: "implement-from-spec skill — Design"
version: 1
status: Draft
date: 2026-05-08
author: chjiang
reviewers: []
---

<!-- Atomic story scaffold; the parent feature's DESIGN.md is the primary
     context. This DESIGN.md is a brief stub. -->

## Problem

`/implement-from-spec` is the second skill the user invokes per user-story (after `/scaffold-work-item` produces the directory tree, before `/qa-work-item` validates). Today the user manually directs Claude to read SPEC + DESIGN and write code. This skill codifies that read-and-implement loop with explicit lifecycle gate transitions and tracker journal entries.

See parent: [F000010_DESIGN.md](../F000010_DESIGN.md) for the full feature shape.

## Shape of the solution

| Concern | User-story | Artifact |
|---------|-----------|----------|
| Read user-story handoff docs (SPEC + DESIGN + ROADMAP) | S000018 | this story |
| Implement per SPEC architecture decisions | S000018 | this story |
| Update tracker journal + transition lifecycle gates | S000018 | this story |

## Big decisions

| # | Decision | Why |
|---|----------|-----|
| 1 | Skill takes user-story-level dir only (Issue 1.2A) | SPEC and TEST-SPEC are user-story-level artifacts; feature dirs aren't actionable |
| 2 | Propose-and-confirm default; opt-in `--auto` | Default safety; user can override for trivial cases. Heuristic for "small change" pinned during implementation |
| 3 | No code reviewer subagent in v1 | Source design says "for taste decisions"; defer until /qa misses things in practice |
| 4 | Tracker journal with category grouping (decision/finding/implementation) | Matches existing /personal-workflow pattern; commit SHAs added after staged changes commit |
| 5 | Sensitive surface protection: AskUserQuestion before committing changes to catalog/manifest/validator | High-blast-radius surfaces deserve human-in-loop before write |

## Risks & open questions

| Risk / Question | Next check |
|-----------------|-----------|
| Propose-vs-write heuristic — when does default flip to "just do it"? | Implementation; recommendation: propose if >2 files touched OR sensitive surface |
| LLM non-determinism on code writes — same SPEC produces different code on different runs | Idempotency (Premise 1.1) protects against duplicate runs; goal is "produces correct code per SPEC each time" not "produces identical code" |
| SPEC gaps — what if SPEC's Architecture section is incomplete? | AskUserQuestion to fill before proceeding |
| Subagent disagreement (if a code reviewer is added later) — how does the parent reconcile? | Defer; if and when subagent added, define disagreement resolution |

## Definition of done

- [ ] Skill file written, validated by `validate.sh`, deployed by `skills-deploy install`
- [ ] Acceptance criteria in [TRACKER.md](S000018_TRACKER.md) all green
- [ ] Golden fixture authored (small SPEC + expected file changes)

## Not in scope

- Code reviewer subagent (deferred per source design)
- Auto-commit integration with `/ship` (kept separate — user runs /ship explicitly)
- Multi-language code generation differences (same skill handles all; LLM picks)

## Pointers

- Parent: [S000018_TRACKER.md](S000018_TRACKER.md)
- Spec: [S000018_SPEC.md](S000018_SPEC.md)
- Test spec: [S000018_TEST-SPEC.md](S000018_TEST-SPEC.md)
- Feature design: [F000010_DESIGN.md](../F000010_DESIGN.md)
