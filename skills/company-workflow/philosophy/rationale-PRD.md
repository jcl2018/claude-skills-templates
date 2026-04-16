---
type: prd
parent: universal-4phase-lifecycle
feature: universal-4phase-lifecycle
title: "Universal 4-Phase Work Lifecycle — Product Requirements"
version: 2
status: Active
date: 2026-04-10
author: ""
reviewers: []
---

## Problem Statement

A software engineer uses the work pipeline daily for defect fixes and feature development. Before the universal lifecycle, the pipeline had inconsistent lifecycles across item types: features, tasks, and defects each had different phase names and different numbers of checkboxes. Switching between a defect and a feature on the same day required remembering two different lifecycle models. The router couldn't reliably suggest "next phase" because phases differed by type.

## Mental Model

One lifecycle, three layers:

```
Templates enforce it ──→ Commands execute it ──→ Router navigates it

  Track → Implement → Review → Ship        (4 phases, universal)
    │         │          │        │
  work-    work-      work-    work-
  track    implement   review    ship        (1 command per phase)

  work-audit                                (companion: callable anytime)
```

Every work item type gets the same 4-phase skeleton. Not every type uses every phase equally — review items have a minimal path, features have the richest. Commands mark their checkpoint when they complete. The router reads checkpoints to suggest the next phase.

`work-audit` is a **companion command**, not a lifecycle phase. It can be invoked at any point — after Track to verify scaffolding, after Implement to check doc alignment, or after Ship to confirm final state. It never blocks progression.

Commands are vendor-neutral: `workpipe` (CLI) handles Layer 1, AI wrappers (Claude Code skills, Copilot agents, etc.) handle Layer 2. Migrating to a different AI host means adding wrapper commands on top of the same pipeline — no lifecycle changes.

## Required Artifacts — Not Just Tracking

A work item is not just a tracker with lifecycle checkboxes. Each type has **required companion documents** defined by the artifact manifest (`artifact-manifests.json`). The tracker is the skeleton; the artifacts are the substance.

| Type | Required artifacts (besides tracker) |
|------|--------------------------------------|
| Feature (user-story scope) | PRD, ARCHITECTURE, TEST-SPEC, milestones |
| Defect | RCA (Root Cause Analysis), test-plan (Regression Test Plan) |
| Review | review-notes |
| Task | test-plan (Test Plan) |

**Why this matters:** Without required artifacts, work items become glorified checklists. A feature tracker with all checkboxes checked but no PRD is a feature nobody can understand six months later. A defect tracker with "fix committed" but no RCA is a fix nobody can learn from.

The artifact manifest enforces this: `work-track create` scaffolds the tracker AND all required artifacts. `work-audit` checks that required artifacts exist and are non-empty. Alignment checks (`doc alignment check`) verify cross-references between the doc triplet (PRD → ARCHITECTURE → TEST-SPEC).

**Optional artifacts** (scrum notes, test plans) are scaffolded on demand, not by default.

## Work Item Types and Workflows

Not all types follow the same path through the 4 phases. The lifecycle checkboxes are universal, but the depth and artifacts differ by type.

### Feature (roll-up path)

```
Track ──→ Implement ──→ Review ──→ Ship
  │           │
  ├─ scope acceptance criteria
  ├─ create branch
  ├─ produce feature-summary.md (scope, success criteria, constituent stories, non-goals)
  ├─ produce milestones.md (delivery roadmap)
  └─ break down into child user-stories/tasks (story-scope detail lives there)
              │
              ├─ child user-stories carry the doc triplet (PRD + ARCHITECTURE + TEST-SPEC)
              ├─ feature tracker rolls up child progress
              ├─ commit infrastructure shared across child stories
              └─ update Files section
```

Features carry only roll-up artifacts (`tracker + feature-summary + milestones`). The detailed PRD/ARCHITECTURE/TEST-SPEC content lives at the user-story level, not duplicated at feature scope. See D000003 in `work-items/defects/` for the rationale and the migration policy for legacy feature-scope doc-triplet files.

### Defect (debug-backward path)

```
Track ──→ Implement ──→ Review ──→ Ship
  │           │
  ├─ document reproduction steps
  ├─ create branch
  └─ log initial symptom
              │
              ├─ debug-backward mode (symptoms → hypotheses → root cause)
              ├─ 3-strike escalation if 3 hypotheses fail
              ├─ commit fix + regression test
              └─ write RCA to Insights
```

Defects enter `work-implement` in debug-backward mode with structured hypothesis testing. RCA (Root Cause Analysis) is a **required artifact** — the investigation trail, root cause, and regression risk must be documented, not just the fix.

### User Story (medium path)

```
Track ──→ Implement ──→ Review ──→ Ship
  │           │
  ├─ define acceptance criteria
  ├─ create branch
  ├─ produce doc triplet (PRD + ARCHITECTURE + TEST-SPEC)
  ├─ create milestones
  └─ break down tasks if needed
              │
              ├─ build-forward mode (from doc triplet + acceptance criteria)
              ├─ commit implementation
              └─ verify acceptance criteria met
```

User stories under features require the full doc triplet (PRD + ARCHITECTURE + TEST-SPEC) plus milestones. The doc triplet lives alongside the user story tracker in its directory. This is where the real design work happens — the feature-level tracker is just an umbrella.

### Task (child path)

```
Track ──→ Implement ──→ Review ──→ Ship
  │           │
  ├─ read parent scope
  ├─ create branch
  └─ populate Files
              │
              ├─ commit core changes
              ├─ keep Todos current
              └─ update Files with changed files
```

Tasks are children of features or user-stories. Lightest implementation — scope comes from parent.

### Review (minimal path)

```
Track ──→ Review ──→ Ship
  │          │
  └─ goals   └─ review feedback
```

Review items skip Implement entirely. They track code review goals, capture feedback, and ship. The Implement checkbox stays unchecked — the router recognizes this and suggests Review directly after Track.

## User Stories

### P0 (Must-Have)

| # | What it asks | As a... | I want to... | So that... |
|---|-------------|---------|-------------|------------|
| 1 | Can I implement a feature by reading its plan and writing code? | engineer | invoke `work-implement` on a feature and have it read my doc triplet, draft an implementation plan, and execute it | I don't have to manually translate requirements into code tasks |
| 2 | Can I debug a defect with structured hypothesis testing? | engineer | invoke `work-implement` on a defect and have it enter debug-backward mode (symptoms → hypotheses → root cause → fix) | I get structured debugging with the same command I use for features |
| 3 | Do all item types have the same lifecycle structure? | engineer | see Track → Implement → Review → Ship checkboxes on every tracker | I never have to remember which type has which phases, even if some phases are skipped |
| 4 | Does the router suggest the right next command? | engineer | run `work` and have it suggest the correct next command based on item type and checked phases | the router guides me through the correct command sequence |
| 5 | Can I check doc quality at any point? | engineer | run `work-audit` at any time (after Track, after Implement, or after Ship) and get a quality report | I catch issues whenever I want, not only at a fixed point in the lifecycle |

### P1 (Important)

| # | What it asks | As a... | I want to... | So that... |
|---|-------------|---------|-------------|------------|
| 6 | Can I resume a build-forward session? | engineer | restart `work-implement` after interruption and have it detect where I left off | I don't re-do completed work |
| 7 | Do contracts and docs match the lifecycle? | engineer | run the project-level audit and get zero FAILs related to lifecycle | the doc triplets stay consistent |

### P2 (Nice-to-Have)

| # | What it asks | As a... | I want to... | So that... |
|---|-------------|---------|-------------|------------|
| 8 | Can I see build progress during implementation? | engineer | see a journal log of files created/modified with commit SHAs during build-forward mode | I have an audit trail of what was built |

## Acceptance Criteria

### Story #1: Build-forward mode for features

**AC-1:** Given a feature work item with a populated `feature-summary.md` plus child user-stories carrying the doc triplet (PRD + ARCHITECTURE + TEST-SPEC), when I invoke `work-implement`, then the command reads the feature-summary for scope and the constituent user-stories' doc triplets for detail, presents an implementation plan, and after approval executes it (write code, run tests, iterate).

**AC-2:** Given a feature work item WITHOUT a feature-summary or with no constituent user-stories, when I invoke `work-implement`, then the command reads the tracker description and acceptance criteria and drafts its own plan.

### Story #2: Debug-backward mode for defects

**AC-3:** Given a defect work item, when I invoke `work-implement`, then the command enters debug-backward mode: collects symptoms, forms hypotheses (H1, H2, H3), tests them systematically.

**AC-4:** Given 3 consecutive failed hypotheses in debug-backward mode, when the 3rd hypothesis fails, then the command stops and asks the user to escalate or re-approach (3-strike rule).

### Story #3: Universal lifecycle structure

**AC-5:** Given a newly scaffolded feature, defect, task, user-story, or review tracker, when I read the Lifecycle section, then it contains the 4 checkboxes: Track, Implement, Review, Ship. Review items may leave Implement unchecked by design.

### Story #4: Router integration

**AC-6a:** Given a feature/defect/task with Track checked and Implement unchecked, when I run `work`, then the router suggests `work-implement`.

**AC-6b:** Given a review item with Track checked, when I run `work`, then the router suggests `work-review` (skipping Implement).

### Story #5: Companion audit

**AC-7:** Given any work item at any lifecycle stage, when I invoke `work-audit`, then the command runs tracking validation, template alignment, and inline quality checks, writing findings to the journal.

**AC-8:** `work-audit` never modifies lifecycle checkboxes. It reports findings only.

### Story #6: Session resume

**AC-9:** Given an interrupted `work-implement` session in build-forward mode, when I re-invoke `work-implement`, then the command detects incomplete journal entries and resumes from the last completed plan item.

### Story #7: Doc/contract consistency

**AC-10:** Given all lifecycle changes are deployed, when I run the project-level audit, then zero FAILs are produced related to lifecycle naming or phase references.

## Assumptions

- The home-setup repo and ai-content repo are both accessible from the same machine
- Templates in ai-content can be updated independently of commands in home-setup
- Commands are vendor-neutral: `workpipe` CLI handles Layer 1, AI wrappers (Claude Code skills, Copilot agents) handle Layer 2
- Review items legitimately skip Implement — the router must handle this without treating it as incomplete

## Out of Scope

- Linux branch CI integration in `work-review` (deferred to separate work item)

## Success Metrics

- All 5 tracker templates (feature, defect, user-story, task, review) have the same 4-checkbox lifecycle structure
- `work-implement` handles build-forward and debug-backward modes without regression
- `work-audit` works as a companion at any lifecycle stage
- Router correctly handles per-type workflow differences (e.g., review skips Implement)
- Project-level audit produces zero new FAILs after deployment
- Zero manual phase-name confusion during daily use (self-reported)
