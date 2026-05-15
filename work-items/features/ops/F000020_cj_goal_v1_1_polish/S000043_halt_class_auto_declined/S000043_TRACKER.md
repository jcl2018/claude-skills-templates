---
name: "Halt-class semantic rename `_user_declined` → `_auto_declined` + add to continue set (WI-B)"
type: user-story
id: "S000043"
status: active
created: "2026-05-15"
updated: "2026-05-15"
parent: "F000020"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "main"
blocked_by: ""
# pr: ""  # populate post-/ship
---

<!-- Prerequisite: parent F000020 /office-hours design captures full context;
     this story is an atomic semantic rename + halt-class table update. -->

## Lifecycle

### Phase 1: Track

1. Read parent tracker to understand scope
2. Create working branch: `git checkout -b feat/halt_class_auto_declined` (or use parent's branch if shipping in same PR)
3. Scaffold work item directory and TRACKER.md
4. Distill `DESIGN.md` from the parent's /office-hours output — from `templates/doc-DESIGN.md`
5. Scaffold `SPEC.md` (requirements, acceptance criteria, architecture, tradeoffs) — from `templates/doc-SPEC.md`
6. Scaffold `TEST-SPEC.md` (smoke + E2E test scenarios) — from `templates/doc-TEST-SPEC.md`
7. Break into child tasks if scope warrants decomposition

**Gates:**
- [x] /office-hours design referenced (own or parent's, captured in DESIGN.md)
- [x] Working branch created (`branch` field populated)
- [x] DESIGN + SPEC + TEST-SPEC scaffolded
- [x] Acceptance criteria defined
- [x] Tasks broken down (N/A — atomic story)

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
2. Verify smoke tests pass in CI (automated regression)
3. Walk E2E manually — drive the feature as a user would (TEST-SPEC `## E2E Tests` table)
4. Ensure all child tasks (if any) have shipped
5. Run `/ship` — creates PR, bumps version, updates changelog (includes pre-landing code review)
6. Run `/land-and-deploy` — merges PR and verifies deployment

**Gates:**
- [ ] `/CJ_personal-workflow check` — validation passed
- [ ] Smoke tests pass in CI
- [ ] E2E walked manually
- [ ] All children shipped (if any)
- [ ] `/ship` — PR created (with pre-landing review)
- [ ] `/land-and-deploy` — merged and deployed

## Acceptance Criteria

- [ ] `goal.sh:296` (current sensitive-surface auto-default site) emits end_state `halted_at_sensitive_surface_auto_declined` (not `_user_declined`).
- [ ] /CJ_goal SKILL.md halt-class table lists `halted_at_sensitive_surface_auto_declined` in the **continue** column (mirror `halted_at_preflight`).
- [ ] /loop /CJ_goal hitting a sensitive-surface row continues to the next iteration (does not STOP).
- [ ] No regression for interactive /CJ_goal: when a real human is at the AUQ in the future interactive path, `halted_at_sensitive_surface_user_declined` (the explicit-decline semantic) remains reserved (not actively emitted in v1.1; surfaces only when interactive AUQ at orchestrator layer ships).

## Todos

- [ ] Rename the case in `goal.sh:296` from `halted_at_sensitive_surface_user_declined` to `halted_at_sensitive_surface_auto_declined`
- [ ] Update halt-class lookup table in `goal.sh` (continue vs STOP) so the new end_state is in the continue set
- [ ] Update `skills/CJ_goal/SKILL.md` halt-class documentation table
- [ ] Verify smoke test exercising sensitive-surface gate now emits the new end_state
- [ ] Verify /loop /CJ_goal continues past the gate

## Log

- 2026-05-15: Created. WI-B from F000020 design. One-line semantic alignment: `_user_declined → _auto_declined` (defense-in-depth complement to WI-A's pre-filter).

## PRs

## Files

- skills/CJ_goal/scripts/goal.sh
- skills/CJ_goal/SKILL.md

## Insights

- Disposition (`auto_default vs user_declined`) is the right discriminator for halt-class semantics, not caller-detection (`/loop` env). Same outcome today; future-proof for non-/loop unattended contexts (cron, daemon).
- `_user_declined` end state stays reserved for the future interactive AUQ at orchestrator layer; in v1.1 the bash script never has a human at the AUQ, so it never emits `_user_declined` directly.

## Journal

- [decision] 2026-05-15: Just rename the existing end_state (don't introduce both `_auto_declined` AND `_user_declined` upfront). The user-declined variant lands when interactive AUQ ships; no concrete consumer today.
- [decision] 2026-05-15: Use disposition (was-a-human-present) not caller-detection (was-it-/loop). Smaller blast radius; no /loop env contract introduced.
