---
skill-name: "workflow"
version: 0.1.0
status: DRAFT
created: "2026-04-10"
last-updated: "2026-04-10"
---

# Skill Design: workflow

## Purpose

Consolidates 5 work-pipeline skills (work, work-track, work-implement, work-review, work-ship) into a single skill with subcommands: track, implement, review, ship. Provides a standardized dev workflow pipeline for any repo.

The original 5-skill approach caused routing confusion, duplicated context resolution logic across every skill, and made the system harder to learn. A single entry point with subcommands solves all three.

## Behavior

1. **Routing (SKILL.md):** Detects branch pattern (feature-*, fix-*, task-*, story-*), resolves the active work item from work-items/, and dispatches to the appropriate subcommand. If no subcommand given, shows a status menu with phase progress.

2. **track (track.md):** Handles work item scaffolding (create), evidence synthesis (default), journal entries, milestones CRUD, list, close, and child-items. Manifest-driven scaffolding reads artifact-manifests.json. Template validation checks templates/ then ~/.claude/spec/templates/ then ~/.claude/templates/ as fallback.

3. **implement (implement.md):** Dual-mode execution. Build-forward for features/tasks: read plan from doc triplet, draft implementation plan, execute, verify. Debug-backward for defects: collect symptoms, form 3 hypotheses, test systematically with 3-strike rule, root-cause-before-fix gate.

4. **review (review.md):** Loads work item context, writes journal entry. Quality gate reads skills/contracts/SKILL.md and runs check before code review. Two failure modes: (a) contracts skill missing = warn + skip, (b) check failures = warn + prompt override + journal log. Delegates to gstack /review via Skill tool. Captures outcome (blocked or passed), writes journal, updates handoff.

5. **ship (ship.md):** Validates TEST-SPEC P0 acceptance criteria (blocks on failure). Quality gate runs /contracts check + test. Same two failure modes as review. Advisory sub-gate warnings for unchecked lifecycle items. Delegates to gstack /ship via Skill tool. Captures outcome, writes journal, updates handoff.

## Design Decisions

- **Multi-file split over monolithic SKILL.md.** SKILL.md handles routing and shared context. Each subcommand lives in its own .md file for independent maintenance and manageable file sizes.
- **Shared context resolution eliminates 5-way duplication.** Branch detection, work item resolution, and phase detection are defined once in SKILL.md and referenced by all subcommands.
- **Approach B (Pipeline + Contracts) chosen.** Workflow owns the pipeline; /contracts is a separate skill for doc enforcement. This keeps concerns clean and allows /contracts to be invoked independently.
- **Soft gates v1.** Contract check failures warn and allow override rather than hard-blocking. This lets teams adopt incrementally without breaking existing workflows.

## Dependencies

- `/contracts` skill (local) — invoked as quality gate in review and ship phases
- gstack `/review` (external) — actual code review mechanics
- gstack `/ship` (external) — PR creation, VERSION bump, CHANGELOG update
- `jq` — for reading artifact-manifests.json

## Security Boundaries

allowed-tools: Bash, Read, Write, Edit, Glob, Grep, AskUserQuestion, Agent, Skill

Write and Edit are needed for tracker mutations (journal, handoff blocks, scaffolding). Skill is needed for delegating to /contracts, /review, and /ship. Agent is needed for parallel sub-tasks during implementation.

## Test Criteria

- `/workflow` on a feature branch shows the phase menu with correct progress
- `/workflow track create` scaffolds work item with correct artifacts per manifest
- `/workflow implement` on a feature loads doc triplet and presents implementation plan
- `/workflow implement` on a defect enters debug-backward mode with hypothesis formation
- `/workflow review` triggers contract quality gate before delegating to /review
- `/workflow ship` blocks on P0 TEST-SPEC failures
- `/workflow ship` runs contract check + test gate before delegating to /ship
- Shared context resolution works for all branch patterns (feature-*, fix-*, task-*, story-*)
