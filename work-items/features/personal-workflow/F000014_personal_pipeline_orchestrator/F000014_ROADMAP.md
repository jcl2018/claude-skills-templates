---
type: roadmap
parent: F000014
title: "Personal-pipeline orchestrator — Roadmap"
date: 2026-05-09
author: chjiang
status: Draft
---

<!-- Roll-up roadmap for F000014. Two user-stories (S000026 spike, S000027 skill).
     Sunset checkpoint at run 5 is built into the skill (mechanical telemetry + AUQ). -->

## Scope

Single `/personal-pipeline <design-doc-path>` skill that orchestrates the 3
existing pipeline skills (scaffold-work-item, implement-from-spec, qa-work-item)
via fresh-context Agent subagents per phase, with file-only handoff and
independent inter-step quality gates (pre-scaffold idempotency, post-scaffold
check + footer confirm, post-implement validate.sh, post-QA tracker parse).
Single keystroke for the user; halt-on-red default; AskUserQuestion only at
decision points (scaffold approval, implement taste forks / sensitive surfaces,
red QA, sunset on 6th invocation).

## Non-Goals

- Multi-story feature looping — orchestrator halts after scaffold for features with ≥1 child; user invokes implement+qa per child manually
- `scripts/test.sh` in the post-implement gate — v1 runs `validate.sh` only
- Process-level isolation via `claude -p` — explicitly rejected as Approach C
- Custom `subagent_type` per phase — `general-purpose` everywhere in v1
- TODOS.md:26 fix (scaffold Step 5 idempotency hole) — defense-in-depth, separate item
- Concurrent-invocation locking on `work-items/` — documented accepted risk

## Success Criteria

- [ ] One real TODOS.md entry shipped end-to-end via single `/personal-pipeline` invocation
- [ ] Subagent prompts under 500 tokens each; subagent returns under 200 tokens each (verified by inspection)
- [ ] Pre-scaffold idempotency regression test passes on F000010's design doc (footer detected, Phase 1 skipped)
- [ ] Post-implement gate catches a deliberately broken `validate.sh`
- [ ] Post-QA gate halts with AskUserQuestion on red smoke
- [ ] Sunset trip-wire (≥3 of 5 `halted_at_gate`) verifiable on 6th invocation from `~/.gstack/analytics/personal-pipeline.jsonl`
- [ ] Skill markdown total under 800 lines

## Decomposition

| User-Story | Title | Status |
|-----------|-------|--------|
| [S000026](S000026_subagent_spike/S000026_TRACKER.md) | Subagent capabilities spike (AUQ bubble + RESULT-line reliability) | Open |
| [S000027](S000027_pipeline_skill/S000027_TRACKER.md) | Personal-pipeline skill implementation (SKILL.md + pipeline.md + fixtures) | Open |

## Delivery Timeline

| # | Milestone | Target Date | Status | Owner | Notes | Blocked By |
|---|-----------|-------------|--------|-------|-------|------------|
| 0 | Pre-authoring tool-identifier check (`Agent` vs `Task` in settings.json) | 2026-05-09 | Not Started | chjiang | 60-second `grep`; trivial | — |
| 1 | Ship S000026 (spike) | 2026-05-10 | Not Started | chjiang | ~1 hour total (two ~30-min legs) | #0 |
| 2 | Ship S000027 (skill) | 2026-05-24 | Not Started | chjiang | ~2 weekends per design estimate | #1 |
| 3 | First real run on a TODOS.md entry (e.g., Fork-aware update detection P3) | 2026-05-26 | Not Started | chjiang | Bootstrap validation | #2 |
| 4 | 5-run usage period | 2026-06-15 | Not Started | chjiang | Telemetry accumulates | #3 |
| 5 | Sunset checkpoint AUQ on 6th invocation | 2026-06-16 | Not Started | chjiang | Mechanical trip-wire (≥3 of 5 `halted_at_gate`); user keep/delete | #4 |

### Delivery History

<!-- PR links, merge dates, version bumps. Append-only after ship. -->

- 2026-05-09: Scaffolded F000014 from `chjiang-main-design-20260509-135305.md` via /scaffold-work-item.

## Dependency Graph

```
#0 tool-identifier check
        |
        v
#1 S000026 spike  (BLOCKING for pipeline.md authoring)
        |
        v
#2 S000027 skill
        |
        v
#3 first real run
        |
        v
#4 5-run usage
        |
        v
#5 sunset checkpoint
```

## Open Questions

| Question | Next check |
|----------|-----------|
| Will AUQ bubble through Agent subagents to the human? | S000026 leg (a); ~30 min |
| Will subagents reliably emit a parseable `RESULT: <key>=<value>` final line across 5+ trials? | S000026 leg (b); ~30 min |
| Does Multi-story feature halt-after-scaffold pattern actually feel right when we hit a real multi-story feature? | Defer until first multi-story feature post-v1 |
| Should `subagent_type` be custom per phase (e.g., `scaffold-runner`)? | Defer until tool-access lockdown becomes load-bearing |
