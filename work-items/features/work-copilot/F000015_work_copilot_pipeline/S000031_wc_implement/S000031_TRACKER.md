---
name: "/wc-implement — implement from spec (per-type dispatch)"
type: user-story
id: "S000031"
status: active
created: "2026-05-11"
updated: "2026-05-11"
parent: "F000015"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "claude/zealous-antonelli-5f8036"
blocked_by: "S000030"
---

<!-- Prerequisite: Before scaffolding this work item, run /office-hours to
     produce a design plan in ~/.gstack/projects/. Distill that plan into
     DESIGN.md during Phase 1 below. (For atomic stories that derive directly
     from the parent feature's /office-hours session, the parent's design is
     sufficient context — DESIGN.md may be a brief stub linking to the parent.) -->

## Lifecycle

### Phase 1: Track

1. Read parent tracker to understand scope
2. Create working branch: `git checkout -b feat/wc_implement` (or use parent's branch if shipping in same PR)
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
- [x] Tasks broken down (or N/A — atomic story)

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

- [ ] `work-copilot/prompts/implement.prompt.md` exists with `tools: [codebase, search, searchResults, findTestFiles, editFiles]`.
- [ ] Prompt does per-type dispatch over 5 work-item types: feature (delegate to child), user-story (PRD + ARCHITECTURE + TEST-SPEC), defect (RCA + test-plan), task (TRACKER + test-plan), review (review-notes — degenerate receipt).
- [ ] Walkthrough mode only: propose plan → user confirms in chat → edit code → re-confirm. No `--auto` flag.
- [ ] Captures `latest_sha_at_implement` and `commits_since_scaffold` via user-paste pattern.
- [ ] Working-Tree Rule paste pattern hard-stops on dirty `files_touched`.
- [ ] Writes `receipts.implement` block with all required fields per the schema locked by S000030.
- [ ] Review-type receipt is degenerate (`files_touched: []`, `commits_since_scaffold: []`, `ac_ids_targeted: []`, `open_risks: ["<one-line: what was reviewed and what action was taken>"]`) and `/wc-pipeline` (S000035) tolerates this shape.
- [ ] Manual smoke pass: invoke `/wc-implement` against a user-story fixture; observe walkthrough; verify receipt block.

## Todos

<!-- Actionable items for this story. -->

- [ ] Author `work-copilot/prompts/implement.prompt.md` with frontmatter + 6 main steps.
- [ ] Per-type input dispatch block (read different artifacts per `type:` in tracker frontmatter).
- [ ] Walkthrough-mode instructions (propose, confirm, edit, re-confirm).
- [ ] User-paste pattern for `git rev-parse HEAD` and `git log --oneline <scaffold_sha>..HEAD`.
- [ ] Working-Tree Rule paste pattern (hard-stop).
- [ ] Read-whole-tracker, parse-merge-write pattern for `receipts.implement`.
- [ ] Review-type degenerate path documented and tested.
- [ ] Smoke + fixture exercise.

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-05-11: Created. Build #2 of Approach C. Blocked by S000030 (locks receipt schema).

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. -->

- `work-copilot/prompts/implement.prompt.md` (new)

## Insights

<!-- Non-obvious findings worth remembering. -->

- The "review" type is the only one with a degenerate receipt (empty arrays + a 1-line open_risks summary). The schema must explicitly allow empty arrays as valid completion state; otherwise `/wc-pipeline` flags every review work-item as drifted.

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

- [decision] 2026-05-11: Walkthrough mode is the only mode. No `--auto` flag. Reasoning: the parent /CJ_personal-pipeline has --auto for trivial changes, but Copilot has no AUQ and no shell — walkthrough chat is the safest UX for V1.
