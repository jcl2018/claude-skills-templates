---
type: design
parent: F000010
title: "Personal-workflow pipeline skills — Feature Design"
version: 1
status: Draft
date: 2026-05-08
author: chjiang
reviewers: []
---

<!-- Source: ~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-main-design-20260508-102829.md
     (refined by /plan-eng-review 2026-05-08). This DESIGN.md is the condensed
     local distillation; the full transcript stays in ~/.gstack/projects/. -->

## Problem

The May 5 personal-workflow tracker re-cut defined a 6-step workflow: `/office-hours` → scaffold → implement → smoke + E2E → `/ship` → `/land-and-deploy`. Steps 1, 5, 6 are skill-automated. Steps 2, 3, 4 are not — `WORKFLOW.md` describes the rules in prose and tells the AI to read them and follow them inline. Today the user directs Claude conversationally: "scaffold a feature for this design," "now implement per SPEC," "now run the tests." Three things suffer:

1. **No structural enforcement at scaffold time.** `/personal-workflow check` validates *after* the AI scaffolds; cannot prevent malformed scaffolds.
2. **No isolation across phases.** Scaffolding context (templates, manifests, design doc) bleeds into implementation context (codebase, prior commits, test infra) bleeds into QA context. Token cost grows monotonically; the AI's attention is always split across phases.
3. **No standard handoff shape.** Scaffold→implement→test handoff is conversational, not reproducible.

This feature closes that gap with three new LLM-driven skills, each handling exactly one workflow step, communicating only via filesystem handoff docs.

## Shape of the solution

| Concern | User-story | Artifact |
|---------|-----------|----------|
| Design doc → work-item directory tree | S000017 | [S000017_TRACKER.md](S000017_scaffold_work_item/S000017_TRACKER.md) |
| User-story SPEC → code + tracker journal | S000018 | [S000018_TRACKER.md](S000018_implement_from_spec/S000018_TRACKER.md) |
| TEST-SPEC → smoke + E2E results in tracker | S000019 | [S000019_TRACKER.md](S000019_qa_work_item/S000019_TRACKER.md) |

```
~/.gstack/projects/{slug}/...-design-*.md
              │
              ▼
     /personal-workflow scaffold (or /scaffold-work-item)        [S000017]
              │
              ▼
   work-items/{type}s/{slug}/{ID}_{slug}/                  (feature)
     ├── {ID}_TRACKER.md
     ├── {ID}_DESIGN.md
     ├── {ID}_ROADMAP.md
     └── {child-slug}/{S_ID}_{slug}/                       (user-story child)
         ├── {S_ID}_TRACKER.md
         ├── {S_ID}_DESIGN.md
         ├── {S_ID}_SPEC.md
         └── {S_ID}_TEST-SPEC.md
              │
              ▼  (per user-story)
     /personal-workflow implement (or /implement-from-spec)      [S000018]
              │
              ▼
        code changes + tracker journal entries
              │
              ▼  (per user-story)
     /personal-workflow qa (or /qa-work-item)                    [S000019]
        ├── smoke (script-driven via scripts/test.sh)
        └── E2E (QA engineer subagent)
              │
              ▼
        tracker Phase 2 gates green
              │
              ▼
        [user takes over]  /ship  →  /land-and-deploy
```

## Big decisions

| # | Decision | Why |
|---|----------|-----|
| 1 | Three independent skills, no orchestrator (Approach A) | Office-hours offered four shapes; user picked A over B (single orchestrator) to validate the handoff-doc thesis cheap. Orchestrator captured as P3/M follow-up in TODOS.md after 2+ weeks of real use. |
| 2 | QA engineer subagent (Premise 2 supersedes May 5) | May 5 said "E2E walked once before ship" was deliberate. v3 (this feature) says a subagent prompted "you are a QA engineer, read TEST-SPEC, verify acceptance criteria" runs E2E autonomously. Generalizes beyond pre-scripted harnesses. |
| 3 | Idempotency contract (Premise 1.1, /plan-eng-review 1.1A) | Every skill is idempotent. Re-run on same input → NO-OP if already done. On abort: no rollback; tracker journal records what was written. Next run re-derives state from filesystem. Idempotency over `.in-progress` markers — fewer files, same recovery semantics. |
| 4 | Boundary validation (Premise 1.3, /plan-eng-review 1.3A) | Every skill calls `/personal-workflow check <work-item-dir>` at start AND end. Drift detection at runtime; runtime safety net for v1's manual-tests-only choice. |
| 5 | Granularity: scaffold full tree; implement/QA at user-story level (1.2A) | SPEC and TEST-SPEC are user-story-level. Multi-story feature pipeline = 1 scaffold + N implements + N QAs invocations. Explicit beats implicit auto-iteration. |
| 6 | Step 0A — manual tests only in v1 | Behavioral eval harness (TODOS.md P1) deferred. Test coverage is fixture-based + manual (one golden fixture per skill, 3.1A). Automated regression lands in a future PR after the eval harness ships. |

## Risks & open questions

| Risk / Question | Next check |
|-----------------|-----------|
| QA engineer subagent prompt design — where does the template live? (Open Q1 of source design) | Decide during S000019 implementation; recommendation: hardcoded in `skills/qa-work-item/SKILL.md` for v1, extract to `prompts/` if reuse demands it |
| `/implement-from-spec` propose-vs-write default behavior — heuristic for "small change" vs "needs confirmation" (Open Q2) | Decide during S000018 implementation; recommendation: propose-and-confirm by default, toggle "just do it" via skill argument |
| Scaffold updating parent design doc footer (Open Q3) | Decide during S000017 implementation; recommendation: yes, append a small "Status: SCAFFOLDED → work-items/.../F000010" footer for traceability |
| Multi-story decomposition logic in /scaffold-work-item — how does it decide N user-story children? | S000017 implementation; recommendation: AskUserQuestion to confirm N + slugs, do NOT auto-decompose silently |
| Subagent failure semantics within skills (timeout, empty response, error) | S000019 (most subagent-heavy) implementation; baseline: idempotency from 1.1A handles abort, AskUserQuestion handles ambiguous |
| Bootstrap chicken-and-egg | F000010 hand-scaffolded; re-scaffold via /scaffold-work-item after S000017 ships, diff against this baseline as first fixture |

## Definition of done

- [ ] All three user-stories shipped (S000017, S000018, S000019)
- [ ] Each skill ships with a golden fixture; manual snapshot-diff workflow documented
- [ ] Each skill's SKILL.md ≤ 500 lines (per source design Success Criterion); 3 skills together ≤ 1500 lines
- [ ] Bootstrap: re-scaffold F000010 via /scaffold-work-item, output matches hand-scaffolded baseline (modulo timestamps)
- [ ] Pipeline runs end-to-end on at least one new real work item; user manually validates output before declaring v1 ready
- [ ] TODOS.md `/personal-pipeline` orchestrator entry remains valid (revisit gate at 2+ weeks of real use)

## Not in scope

- `/personal-pipeline` orchestrator (Approach B from office-hours) — captured as TODOS.md P3 follow-up
- Behavioral eval harness automation — TODOS.md P1, deferred per Step 0A
- Multi-machine consumer support (non-script E2E) — Premise 2 covers script-or-agent E2E for this workbench; cross-machine generalization is v2
- Subagent in /scaffold-work-item (validator subagent) — already optional in source design; covered by 1.3A boundary check
- Subagent in /implement-from-spec (code reviewer for taste decisions) — per-decision optional invocation, not always-on
- /ship and /land-and-deploy integration — premise 3: stay outside the pipeline, invoked separately
- /office-hours integration (auto-trigger scaffold from /office-hours) — out per premise 3

## Pointers

- Parent tracker: [F000010_TRACKER.md](F000010_TRACKER.md)
- Roadmap: [F000010_ROADMAP.md](F000010_ROADMAP.md)
- Source office-hours design (full): `~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-main-design-20260508-102829.md`
- Eng-review test plan: `~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-main-eng-review-test-plan-20260508-102829.md`
- Foundational predecessor (workflow shape): `~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-main-design-20260505-140754.md` (May 5 tracker re-cut)
- Existing infrastructure reused: [skills/personal-workflow/](../../../skills/personal-workflow/), [WORKFLOW.md](../../../skills/personal-workflow/WORKFLOW.md), [personal-artifact-manifests.json](../../../skills/personal-workflow/personal-artifact-manifests.json), [templates/personal-workflow/](../../../templates/personal-workflow/)
