---
type: architecture
parent: S000006
feature: F000004
title: "personal-workflow-port — Architecture"
version: 1
status: Draft
date: 2026-04-20
author: chjiang
prd: PRD.md
reviewers: []
---

## Overview

Mechanical parity port. Copy the two shipped bash blocks (`## Knowledge Resolution` from S000004; `## Knowledge Loading` from S000005) from `skills/company-workflow/SKILL.md` into `skills/personal-workflow/SKILL.md`, adapt only skill-name references, mirror the WORKFLOW.md `## Knowledge Configuration` section the same way, and add a T000007 test block to `scripts/test.sh` that mirrors T000003's assertions pointed at the new file.

No new design decisions. No new dependencies. No new env vars, schemas, or markers. The point of this story is to eliminate the asymmetry where `/company-workflow` reads the user's knowledge folder and `/personal-workflow` ignores it, without re-opening any decision F000004 already made.

## Architecture

```
Before:
  skills/company-workflow/SKILL.md
    ## Path Resolution
    ## Knowledge Resolution       (S000004 — shipped)
    ## Knowledge Loading          (S000005 — in flight)
    ## Template Registry
    ...

  skills/personal-workflow/SKILL.md
    ## Preamble
    ## Path Resolution
    ## Stale Rules Detection
    ## Overview                   ← no knowledge blocks
    ...

After:
  skills/company-workflow/SKILL.md   (unchanged)

  skills/personal-workflow/SKILL.md
    ## Preamble
    ## Path Resolution
    ## Stale Rules Detection
    ## Knowledge Resolution       ← MIRRORED from company-workflow
    ## Knowledge Loading          ← MIRRORED from company-workflow
    ## Overview
    ...

  scripts/test.sh
    # T000003 block — 11 cases against company-workflow/SKILL.md
    # T000007 block — 11 parallel cases against personal-workflow/SKILL.md  ← NEW
```

The block placement inside `personal-workflow/SKILL.md` is **after Stale Rules Detection, before Overview**. Same reasoning as company-workflow: resolution must run after the skill has verified its own assets exist (Path Resolution) but before any documentation-style sections the user might read to understand the skill. Stale Rules Detection is personal-workflow-specific (flags the old `~/.claude/rules/work-items.md`) and belongs to Path Resolution's prelude, so Knowledge Resolution slots in right after it.

### Components Affected

| Component | Repo | Change Type | Description |
|-----------|------|------------|-------------|
| `skills/personal-workflow/SKILL.md` | claude-skills-templates | Modified | Add `## Knowledge Resolution` and `## Knowledge Loading` sections mirrored from company-workflow |
| `skills/personal-workflow/WORKFLOW.md` | claude-skills-templates | Modified | Add `## Knowledge Configuration` section mirrored from company-workflow |
| `scripts/test.sh` | claude-skills-templates | Modified | Add T000007 test block (parallel to T000003) asserting the mirrored blocks against personal-workflow/SKILL.md |
| `scripts/test-helpers/knowledge.sh` | claude-skills-templates | Reused (unchanged) | Shared fixture builder from S000005 — both skills' tests source it |
| `skills/company-workflow/*` | claude-skills-templates | Unchanged | The port is additive; company-workflow source is not touched |

### Data Flow

1. User exports `AI_KNOWLEDGE_DIR=/path/to/knowledge` in their shell profile.
2. User drops `.claude/knowledge-enabled` in the current repo root (per-repo opt-in).
3. User invokes `/personal-workflow check` (or any personal-workflow command).
4. SKILL.md's Path Resolution runs → sets `$_SKILL_DIR` + `$_TMPL_DIR`.
5. Stale Rules Detection runs → emits legacy warning if applicable.
6. **Knowledge Resolution runs** → sets `$_KNOWLEDGE_DIR` or emits an unset/invalid warning to stderr.
7. **Knowledge Loading runs** → if marker present, enumerates categories, parses `.knowledge.yml`, emits `## Always-On Knowledge` + `## On-Demand Knowledge Candidates` blocks.
8. Overview + Usage + other sections follow (user reads and executes the command as before).

Step 6 mirrors the company-workflow behavior shipped in S000004. Step 7 mirrors what S000005 will ship. Both are copied verbatim (modulo skill-name strings).

## API Changes

No API changes. All changes are internal to personal-workflow's SKILL.md and its test harness. The only user-visible change is that `AI_KNOWLEDGE_DIR` is now honored by `/personal-workflow` in addition to `/company-workflow` — an additive behavior change documented in WORKFLOW.md.

### New APIs

_None._

### Modified APIs

_None._

## Dependencies

| Dependency | Type | Status | Notes |
|-----------|------|--------|-------|
| S000004 Resolution block | Feature | Shipped (PR #38) | Source to copy for the Resolution port |
| S000005 Loading block | Feature | In flight (Phase 2 pending) | Source to copy for the Loading port — HARD BLOCKER for this story |
| `scripts/test-helpers/knowledge.sh` | Code | Built in S000005 | Shared fixture builder — T000007 sources it |
| `.claude/knowledge-enabled` marker convention | Contract | Decided in S000005 | Both skills honor the same marker name |

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Copying company-workflow bash verbatim misses a skill-name reference and /personal-workflow claims to be /company-workflow in a warning | Med | Low | T000007's test block greps for the correct skill name in every emitted string |
| The Loading block evolves between S000005 landing and this port starting, so the copy is stale on day one | Med | Med | Diff-before-copy step explicitly listed in the Todos; S000006 stays in Phase 1 until S000005 lands on `main` |
| Duplicated bash drifts between skills over time (bug fixed in one but not the other) | Med | Med (deferred) | P2 Story #9 tracks the extraction-to-helper option; accept the drift risk for v1 in exchange for simpler lift-and-shift |
| personal-workflow's `## Stale Rules Detection` interacts unexpectedly with the new Knowledge Resolution (section order assumption) | Low | Low | Block placement pinned: after Stale Rules, before Overview. T000007 asserts the section order |
| A user who opted into company-workflow knowledge is surprised when personal-workflow also starts loading in the same repo | Low | Med | WORKFLOW.md documents that the per-repo opt-in marker activates knowledge for BOTH skills; this is explicit, not incidental |
| T000007 test block duplicates T000003 drift — one gets updated, the other doesn't | Med | Low | T000007 is structurally identical; adjust a single `_SKILL=` variable at the top of the block. Code review checklist item. |

## Design Decisions

| Decision | Chosen | Rejected Alternative | Why |
|----------|--------|---------------------|-----|
| Scope | Single story, both blocks ported together | Two stories (resolution now, loading later) | See S000006_TRACKER journal — avoids half-ported cutover |
| Duplication vs shared helper | Lift-and-shift (accept bash duplication for v1) | Extract Resolution + Loading to `skills/_shared/knowledge.sh`, source from both | Lift-and-shift is the minimum-viable port. Extraction is a broader refactor; S000006 tracks it as P2 Story #9, not a requirement |
| Block position in SKILL.md | After Stale Rules Detection, before Overview | Anywhere else (after Overview, after Usage, etc.) | Matches company-workflow's "resolve infra before explaining yourself" order; Stale Rules is personal-workflow-specific setup that must run first |
| Opt-in marker | Reuse `.claude/knowledge-enabled` (same as company-workflow) | Separate marker per skill (`.claude/knowledge-enabled-personal`) | The marker answers "does THIS repo want knowledge?"; it's a repo-level concern, not a skill-level one. Splitting would double the setup burden for no gain |
| Env var | Reuse `AI_KNOWLEDGE_DIR` (same as company-workflow) | Separate env var per skill | Same reasoning as the marker — the knowledge store is a user-level resource, not skill-scoped. Splitting forces dual config |
| Test harness | Add a parallel T000007 block in `scripts/test.sh` that mirrors T000003's 11 cases against personal-workflow/SKILL.md | Extract T000003 into a parameterized helper that both skills invoke | Parameterization is the right end-state but out of scope for v1; mirror-then-maybe-dedupe is the safer sequence (T000003 has landed and been reviewed; reopening it for parameterization risks regressing company-workflow) |
| WORKFLOW.md docs | Mirror the entire `## Knowledge Configuration` section, rename commands in prose only | Write a personal-workflow-specific section from scratch | Same content, same schema, same setup — writing from scratch invites subtle drift |
| Docs backlink | Same `work-items/features/F000004_knowledge_integration/` reference | Separate backlink per skill | Both skills share the same feature; one backlink is correct |
