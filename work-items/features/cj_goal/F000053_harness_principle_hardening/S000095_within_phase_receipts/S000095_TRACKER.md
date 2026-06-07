---
name: "Within-phase receipts — continue from receipts, not transcript"
type: user-story
id: "S000095"
status: active
created: "2026-06-06"
updated: "2026-06-06"
parent: "F000053"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates/.claude/worktrees/tender-elion-267bd0"
branch: "claude/tender-elion-267bd0"
blocked_by: ""
# pr: ""  # optional; populate with PR URL (e.g. https://github.com/org/repo/pull/123) for explicit PR-state lookups. The `## PRs` section below is the canonical home for PR links; this frontmatter field is a machine-readable shortcut consumed by /CJ_goal_run Branch(f)/(g) gh pr view dedup. Either convention is accepted.
---

<!-- Prerequisite: Before scaffolding this work item, run /office-hours to
     produce a design plan in ~/.gstack/projects/. Distill that plan into
     DESIGN.md during Phase 1 below. (For atomic stories that derive directly
     from the parent feature's /office-hours session, the parent's design is
     sufficient context — DESIGN.md may be a brief stub linking to the parent.) -->

## Lifecycle

### Phase 1: Track

1. Read parent tracker to understand scope
2. Create working branch: `git checkout -b feat/within_phase_receipts` (or use parent's branch if shipping in same PR)
3. Scaffold work item directory and TRACKER.md
4. Distill `DESIGN.md` from the /office-hours output (own session or parent's) — from `templates/doc-DESIGN.md`
5. Scaffold `SPEC.md` (requirements, acceptance criteria, architecture, tradeoffs) — from `templates/doc-SPEC.md`
6. Scaffold `TEST-SPEC.md` (smoke + E2E test scenarios) — from `templates/doc-TEST-SPEC.md`
7. Break into child tasks if scope warrants decomposition (per WORKFLOW.md, tasks are optional for atomic stories)

**Gates:**
- [ ] /office-hours design referenced (own or parent's, captured in DESIGN.md)
- [ ] Working branch created (`branch` field populated)
- [ ] DESIGN + SPEC + TEST-SPEC scaffolded
- [ ] Acceptance criteria defined
- [ ] Tasks broken down (or N/A — atomic story)

### Phase 2: Implement

1. Read DESIGN + SPEC for context
2. Implement according to architecture decisions in SPEC
3. Run smoke tests as you go (TEST-SPEC `## Smoke Tests` table)
4. Run `/CJ_personal-workflow check` on modified docs after updates
5. Update tracker: move through lifecycle phases, add journal entries
6. Update Files section with changed file paths

**Gates:**
- [ ] Acceptance criteria verified met
- [ ] Smoke tests pass
- [ ] Todos section reflects remaining work (no stale items)
- [ ] Files section updated with changed files

### Phase 3: Ship

1. Run `/CJ_personal-workflow check` — verify all validation passes
   → should show PASS for template, lifecycle, traceability badges
2. Verify smoke tests pass in CI (automated regression)
3. Walk E2E manually — drive the feature as a user would (TEST-SPEC `## E2E Tests` table)
4. Ensure all child tasks (if any) have shipped
5. Run `/ship` — creates PR, bumps version, updates changelog (includes pre-landing code review)
6. Run `/land-and-deploy` — merges PR and verifies deployment

❌ If `/CJ_personal-workflow check` finds issues: fix findings, re-run until clean
❌ If smoke or E2E fails: fix, re-run

**Gates:**
- [ ] `/CJ_personal-workflow check` — validation passed
- [ ] Smoke tests pass in CI
- [ ] E2E walked manually
- [ ] All children shipped (if any)
- [ ] `/ship` — PR created (with pre-landing review)
- [ ] `/land-and-deploy` — merged and deployed

## Acceptance Criteria

<!-- What "done" looks like for this story. -->

- [ ] AC1: after the office-hours inline phase, a compact phase receipt is written to `.cj-goal-feature/` via the existing atomic mktemp+mv path.
- [ ] AC2: the post-office-hours steps READ `$RECEIPT_PATH`, and the design-summary digest is sourced from the receipt file rather than regenerated from conversation context.
- [ ] AC3: scoped to the known long inline phases (office-hours); no generic compaction framework is introduced.
- [ ] AC4: the receipt reuses Story S000093's receipt schema (shared format, set by whichever ships first).

## Todos

<!-- Actionable items for this story. -->

- [ ] Write a compact phase receipt to `.cj-goal-feature/` at the office-hours boundary in `skills/CJ_goal_feature/pipeline.md`, via the existing atomic mktemp+mv path.
- [ ] Repoint the post-office-hours steps (design-summary digest) to READ `$RECEIPT_PATH` rather than regenerate from context.
- [ ] Generalize the resume state file (`.cj-goal-feature/${branch}.state`) into a per-phase receipt chain, preserving the atomic-write + ancestor-SHA validate-before-skip contract.
- [ ] Reuse S000093's receipt schema (one schema, not two); if S000093 ships first, consume that schema.
- [ ] Keep scope to office-hours only — no generic "compact everything" framework.

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-06-06: Created. Within-phase receipts — write a compact phase receipt at the office-hours inline boundary and have the orchestrator continue from `$RECEIPT_PATH` rather than the raw transcript (GAP C / P1, sequenced last in F000053).

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. -->

- `skills/CJ_goal_feature/pipeline.md` (office-hours boundary writes a receipt; design-summary digest reads it)
- The resume state-file schema (`.cj-goal-feature/${branch}.state`)
- `scripts/cj-goal-common.sh` (possibly)

## Insights

<!-- Non-obvious findings worth remembering. -->

- The design-summary digest at the office-hours boundary is already a proto-receipt — generalize it rather than inventing a new surface.
- This story overlaps most with Claude Code's built-in auto-compaction, so it is sequenced last: lowest marginal value, highest over-build risk. The guardrail is "scoped to known long inline phases only," not a generic framework.
- The receipt schema is SHARED with S000093 (Trajectory QA); whichever ships first sets it. If S000093 lands first, this story consumes that schema with no second schema introduced.

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->
