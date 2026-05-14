---
name: "Add --work-item-dir flag to CJ_personal-pipeline"
type: user-story
id: "S000036"
status: active
created: "2026-05-13"
updated: "2026-05-13"
parent: "F000016"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates/.claude/worktrees/awesome-pasteur-36565c"
branch: "claude/awesome-pasteur-36565c"
blocked_by: ""
---

<!-- Prerequisite: Before scaffolding this work item, run /office-hours to
     produce a design plan in ~/.gstack/projects/. Distill that plan into
     DESIGN.md during Phase 1 below. (For atomic stories that derive directly
     from the parent feature's /office-hours session, the parent's design is
     sufficient context — DESIGN.md may be a brief stub linking to the parent.) -->

## Lifecycle

### Phase 1: Track

1. Read parent tracker to understand scope
2. Create working branch: `git checkout -b feat/{slug}` (or use parent's branch if shipping in same PR)
3. Scaffold work item directory and TRACKER.md
4. Distill `DESIGN.md` from the /office-hours output (own session or parent's) — from `templates/doc-DESIGN.md`
5. Scaffold `SPEC.md` (requirements, acceptance criteria, architecture, tradeoffs) — from `templates/doc-SPEC.md`
6. Scaffold `TEST-SPEC.md` (smoke + E2E test scenarios) — from `templates/doc-TEST-SPEC.md`
7. Break into child tasks if scope warrants decomposition (per WORKFLOW.md, tasks are optional for atomic stories)

**Gates:**
- [x] /office-hours design referenced (own or parent's, captured in DESIGN.md)
- [x] Working branch created (`branch` field populated)
- [x] DESIGN + SPEC + TEST-SPEC scaffolded
- [x] Acceptance criteria defined
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

- [ ] `pipeline.md` Step 1 parses `--work-item-dir <path>` flag; DESIGN_DOC validation block is gated on override being absent
- [ ] `pipeline.md` Step 2 gains Branch (e): when `WORK_ITEM_DIR_OVERRIDE` is set, skips footer search and Phase 1, journal-writes `[orchestrator] --work-item-dir mode`, continues directly to Step 4
- [ ] Step 4 sub-step 1 (footer write-back check) is skipped in `--work-item-dir` mode; sub-steps 2–4 run normally
- [ ] Step 9.3 summary prints `Design: (work-item-dir mode — no design doc)` when DESIGN_DOC is empty
- [ ] Telemetry Step 9.1 adds `"work_item_dir_mode": true` field when flag is set
- [ ] `SKILL.md` Usage section updated with `--work-item-dir` mode documentation
- [ ] `CJ_personal-pipeline 0.1.0` → `0.2.0` in SKILL.md and skills-catalog.json
- [ ] `--suppress-final-gate` still works when combined with `--work-item-dir`
- [ ] Standalone test: invoke `CJ_personal-pipeline --work-item-dir <existing-user-story-dir>`, verify it skips scaffold and reaches impl (Step 5) without error

## Todos

- [ ] Edit `skills/CJ_personal-pipeline/pipeline.md` Step 1: add `--work-item-dir` to arg parser (look-ahead variable pattern from design doc)
- [ ] Edit `skills/CJ_personal-pipeline/pipeline.md` Step 1: gate DESIGN_DOC validation block on `WORK_ITEM_DIR_OVERRIDE` being absent; add `--work-item-dir` validation block for when override is set
- [ ] Edit `skills/CJ_personal-pipeline/pipeline.md` Step 2: add Branch (e) at top before footer search
- [ ] Edit `skills/CJ_personal-pipeline/pipeline.md` Step 4: carve out sub-step 1 skip in `--work-item-dir` mode
- [ ] Edit `skills/CJ_personal-pipeline/pipeline.md` Step 9.1: add `work_item_dir_mode` telemetry field
- [ ] Edit `skills/CJ_personal-pipeline/pipeline.md` Step 9.3: handle empty DESIGN_DOC in summary
- [ ] Edit `skills/CJ_personal-pipeline/SKILL.md`: update Usage section, bump version to 0.2.0
- [ ] Edit `skills-catalog.json`: bump CJ_personal-pipeline version to 0.2.0
- [ ] Run `./scripts/validate.sh` to verify

## Log

- 2026-05-13: Created. Extends CJ_personal-pipeline with --work-item-dir flag — first-class input mode for pre-scaffolded work item dirs, reusable beyond ship-feature. Derived from F000016 /office-hours design, Approach B.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

- `skills/CJ_personal-pipeline/pipeline.md`
- `skills/CJ_personal-pipeline/SKILL.md`
- `skills-catalog.json`

## Insights

<!-- Non-obvious findings worth remembering. -->

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->
