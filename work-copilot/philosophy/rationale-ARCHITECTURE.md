---
type: architecture
parent: universal-4phase-lifecycle
feature: universal-4phase-lifecycle
title: "Universal 4-Phase Work Lifecycle — Architecture"
version: 2
status: Active
date: 2026-04-10
author: ""
prd: PRD.md
reviewers: []
---

## Overview

The work pipeline uses a universal 4-phase lifecycle (Track → Implement → Review → Ship) enforced through templates and executed by one command per phase. `work-implement` operates in dual mode: build-forward for features/tasks, debug-backward for defects. `work-audit` is a companion command callable at any lifecycle stage for quality checks. Not every type uses every phase — review items skip Implement entirely.

Commands are vendor-neutral pipeline stages. `workpipe` (CLI) handles Layer 1 (structural validation). AI wrappers — Claude Code skills today, Copilot agents tomorrow — handle Layer 2 (rich sub-gates, evidence synthesis). Migrating to a new AI host means writing wrapper commands, not changing the pipeline. See PRD.md for per-type workflows and requirements.

## Architecture

```
                    ┌─────────────┐
                    │    work     │  (router: reads lifecycle, suggests next command)
                    └──────┬──────┘
                           │
      ┌───────────┬────────┴────────┬───────────┐
      ▼           ▼                 ▼           ▼
┌──────────┐ ┌──────────┐    ┌──────────┐ ┌──────────┐
│  work-   │ │  work-   │    │  work-   │ │  work-   │
│  track   │ │ implement│    │  review  │ │  ship    │
│          │ │          │    │          │ │          │
└────┬─────┘ └────┬─────┘    └────┬─────┘ └────┬─────┘
     │            │                │            │
     │     ┌──────┴──────┐        │            │
     │     │  mode       │        │            │       ┌──────────┐
     │     │  detect     │        │            │       │  work-   │
     │     ├─────────────┤        │            │       │  audit   │
     │     │build-forward│        │            │       │(companion│
     │     │(feature/task)        │            │       └────┬─────┘
     │     ├─────────────┤        │            │            │
     │     │debug-backward        │            │     ┌──────┴──────┐
     │     │(defect)     │        │            │     │ 3 checks:  │
     │     └─────────────┘        │            │     │ tracking   │
     │                            │            │     │ alignment  │
     │                            │            │     │ quality    │
     ▼           ▼               ▼            ▼     └─────────────┘
┌──────────────────────────────────────────────┐  callable at any
│  Work Item Tracker (.md)                     │  lifecycle stage
│  ## Lifecycle                                │
│  - [x] Track    - [ ] Implement              │
│  - [ ] Review   - [ ] Ship                   │
│  ## Journal, ## Log, ## Handoff, ...         │
└──────────────────────────────────────────────┘

Layer 1 (CLI):  workpipe create/audit/status  ← vendor-neutral, deterministic
Layer 2 (AI):   wrapper commands (Claude skills, Copilot agents, …)  ← host-specific, swappable
```

### Components

| Component | Repo | Description |
|-----------|------|-------------|
| spec/templates/tracker- | ai-content | Per-type tracker templates (feature, defect, user-story, task, review) |
| spec/templates/doc- | ai-content | Doc scaffolding templates (PRD, ARCHITECTURE, TEST-SPEC, RCA, etc.) |
| spec/reference/guide- | ai-content | Generation instructions for AI when creating docs |
| spec/contract.json | ai-content | Structural validation rules (`workpipe audit` reads this) |
| spec/philosophy/rationale- | ai-content | Design docs explaining the lifecycle philosophy (this triplet) |
| artifact-manifests.json | ai-content | Maps item types to their required artifacts (PRD, RCA, etc.) |

### Data Flow

**Build-forward mode (feature/task):**

1. User invokes `work-implement` on a feature work item
2. Command reads work item type from frontmatter → `feature` → build-forward mode
3. Command reads handoff block from `work-track` phase
4. Command reads doc triplet (PRD.md, ARCHITECTURE.md, TEST-SPEC.md) if present
5. Command drafts implementation plan from doc triplet (or from tracker if no triplet)
6. User approves plan
7. Command executes: write code → run tests → log to journal → iterate
8. On completion: mark `- [x] Implement`, write handoff block

**Debug-backward mode (defect):**

1. User invokes `work-implement` on a defect work item
2. Command reads work item type → `defect` → debug-backward mode
3. Command reads handoff block from `work-track` phase
4. Command collects symptoms (error messages, reproduction steps)
5. Command forms hypotheses H1, H2, H3 with predicted evidence
6. Command tests each hypothesis, logging verdict to journal
7. If 3 consecutive failures → 3-strike escalation (stop, ask user)
8. Root cause found → implement fix → verify with regression test
9. On completion: mark `- [x] Implement`, write handoff block

**Companion: work-audit (callable at any stage):**

1. User invokes `work-audit` at any point in the lifecycle
2. Resolve work item path from slug or branch name
3. **Tracking validation** — verify required frontmatter, sections, and lifecycle checkboxes against `spec/contract.json`
4. **Template alignment** — check doc triplet structure against `spec/templates/doc-` templates, verify cross-references between PRD↔ARCHITECTURE↔TEST-SPEC
5. **Inline quality checks** — readability, consistency, template usage, cross-refs, traceability
6. Findings written to journal as structured table (FAIL/WARN only, or "All checks passed")
7. Suggests next action based on findings (fix issues, proceed to review, etc.)
8. Never modifies lifecycle checkboxes — reports only

**Review item (minimal path):**

1. User invokes `work-track` on a review item — scaffolds with goals only
2. Implement phase is skipped (checkbox stays unchecked)
3. Router detects review type → suggests `work-review` directly after Track
4. `work-review` captures feedback, `work-ship` merges

## Commands

| Command | Signature | Description |
|---------|-----------|-------------|
| work | `work [slug]` | Router: reads lifecycle, suggests next command per item type |
| work-track | `work-track [create\|slug]` | Scaffolds tracker + artifacts, evidence synthesis, CRUD |
| work-implement | `work-implement [slug]` | Dual-mode: build-forward (feature/task) or debug-backward (defect) |
| work-review | `work-review [slug]` | Context loading + delegation to upstream review command |
| work-ship | `work-ship [slug]` | Spec validation + delegation to upstream ship command |
| work-audit | `work-audit [slug]` | Companion: tracking + alignment + quality checks (any stage) |

## Dependencies

- **ai-content repo**: Templates, contract, and rationale live in separate repo, deployed independently
- **upstream review/ship commands**: `work-review` and `work-ship` delegate to host-provided review and ship commands

## Required Capabilities

Any host (Claude Code, Copilot, etc.) implementing the command pipeline must provide:

| Capability | Used By | Description |
|-----------|---------|-------------|
| Item resolution | all commands | Resolve a work item slug or branch name to a tracker file path |
| Contract validation | work-audit, workpipe audit | Validate tracker against `spec/contract.json` (required frontmatter, sections, lifecycle) |
| Template alignment | work-audit | Compare doc triplet structure against `spec/templates/doc-` templates |
| Traceability check | work-audit | Verify cross-references between PRD↔ARCHITECTURE↔TEST-SPEC |
| Inline quality checks | work-audit | Assess readability, consistency, template usage, cross-refs |
| Scaffolding | work-track | Copy tracker + ALL required artifact templates per `artifact-manifests.json` |
| Artifact completeness | work-audit | Verify all required artifacts exist per manifest (PRD, RCA, etc.) |
| Code review delegation | work-review | Invoke host-provided code review tooling |
| Ship delegation | work-ship | Invoke host-provided PR/merge tooling |
| Journal write | all commands | Append structured entries to the tracker's Journal section |
| Lifecycle checkpoint | phase commands | Mark `- [x]` on the appropriate lifecycle checkbox after phase completion |

`workpipe` CLI (Layer 1) already provides contract validation and item resolution. Layer 2 capabilities are implemented by the host's wrapper commands.

## Design Decisions

### DD-1: Dual-mode command over separate commands

**Chosen:** One `work-implement` command with mode detection (build-forward / debug-backward).
**Why:** Features and defects share the same lifecycle position (Phase 2). Separate commands would require the router to know which to suggest based on type — duplicating type-awareness that belongs in the command itself.
**Rejected:** Separate `work-build` and `work-debug` commands (splits a single phase into two commands).

### DD-2: 4 phases over 5

**Chosen:** Track → Implement → Review → Ship (4 core phases).
**Why:** Analysis and implement are the same motion — understanding the problem and building the solution happen together. Splitting them creates an artificial checkpoint.
**Rejected:** Track → Analysis → Implement → Review → Ship (5-phase model proposed initially).

### DD-3: Template-enforced phases

**Chosen:** Lifecycle checkboxes with exit criteria baked into template labels.
**Why:** Codex challenged "all phases always present" as checkbox theater. Templates with exit criteria in labels resolve this: each phase has concrete criteria, and enforcement is structural.
**Rejected:** Minimum artifact rule (adds complexity without matching template enforcement).

### DD-4: 3-strike rule in debug-backward

**Chosen:** Keep the 3-strike escalation in debug-backward mode.
**Why:** Proven mechanism that prevents rabbit holes. Simplification deferred to follow-up.

### DD-6: work-audit as companion, not a lifecycle phase

**Chosen:** `work-audit` is a companion command callable at any lifecycle stage. It writes findings to the journal but never modifies lifecycle checkboxes.
**Why:** Quality checks are useful at every stage — after Track to verify scaffolding, after Implement to check alignment, after Ship to confirm final state. Locking audit to a fixed position (e.g., between Implement and Review) would prevent these use cases and add artificial ceremony to simple items.
**Rejected:** Audit as a fixed gate between Implement and Review (restricts when it can be called). Audit as a 5th phase with its own checkbox (over-constrains the lifecycle).

### DD-7: Vendor-neutral command pipeline

**Chosen:** Frame the lifecycle as a command pipeline (`work-track`, `work-implement`, etc.) rather than tying it to a specific AI host's plugin system.
**Why:** The pipeline is migrating to Copilot. If commands are defined as vendor-neutral stages, Copilot just adds wrapper agents on top — no lifecycle redesign needed. `workpipe` CLI (Layer 1) is already host-independent.
**Rejected:** Defining phases as Claude Code skills specifically (creates migration friction).

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Cross-repo template drift | Low | Medium | `workpipe audit` validates against contract.json; `work-audit` checks alignment |
| Router suggests wrong command for type | Low | Medium | Type-aware routing with per-type workflow definitions |
| work-audit false positives | Low | Low | Companion only — findings are advisory, never block progression |
