---
name: "port-skill-and-workflow"
type: task
id: "T000007"
status: deferred
created: "2026-04-20"
updated: "2026-04-20"
parent: "S000006"
repo: "claude-skills-templates"
branch: "claude/heuristic-almeida-2f246d"
blocked_by: "S000006 deferred — see parent tracker Log 2026-04-20 autoplan review"
---

## Lifecycle

### Phase 1: Track

1. Read parent tracker to understand scope and acceptance criteria
2. Create working branch: `git checkout -b feat/{slug}`
   (use parent's branch if the task ships in the same PR; create a new branch if it warrants its own PR)
3. Scaffold required docs:
   - `test-plan.md` (test scenarios for this task) — from `templates/doc-test-plan.md`
4. Populate Files section with expected changed files
5. Write initial Todos from parent's acceptance criteria

**Gates:**
- [x] Parent scope read (parent tracker reviewed)
- [x] Working branch created (`branch` field populated)
- [x] Required docs scaffolded (test-plan)
- [x] Files section populated

### Phase 2: Implement

1. Work from `/office-hours` design doc + parent's acceptance criteria + your Todos
   → design doc at `~/.gstack/projects/{slug}/`
2. Commit changes incrementally with descriptive messages
3. Update Todos section — check off completed items, add discoveries
4. Update Files section with actual changed files

**Gates:**
- [ ] Core changes committed (>=1 commit SHA in Log)
- [ ] Todos section reflects remaining work (no stale items)
- [ ] Files section updated with changed files

### Phase 3: Ship

1. Run `/personal-workflow check` — verify no regressions
2. Verify test-plan: all test scenarios passing
3. Run `/ship` — creates PR, bumps version, updates changelog (includes pre-landing code review)
4. Run `/land-and-deploy` — merges PR and verifies deployment

❌ If tests fail: fix, re-run
❌ If CI fails: fix, push, re-run `/ship`

**Gates:**
- [ ] `/personal-workflow check` — validation passed
- [ ] Test-plan verified (all scenarios passing)
- [ ] `/ship` — PR created
- [ ] `/land-and-deploy` — merged and deployed

## Todos

<!-- Actionable items for this task. Not lifecycle duplicates — these are
     the actual things to build, fix, or investigate. -->

- [ ] Confirm S000005 landed on `main` (PR merged, `./scripts/test.sh` passes on main); if not, stop and wait
- [ ] Checkout the final shipped SHAs of `skills/company-workflow/SKILL.md` and `skills/company-workflow/WORKFLOW.md` as the source of truth for the copy
- [ ] Copy the `## Knowledge Resolution` block from company-workflow/SKILL.md into personal-workflow/SKILL.md, positioned after `## Stale Rules Detection` and before `## Overview`
- [ ] Copy the `## Knowledge Loading` block from company-workflow/SKILL.md into personal-workflow/SKILL.md, immediately after the Knowledge Resolution block
- [ ] Scan the pasted blocks for `/company-workflow` references in comments/docstrings/warning text; replace with `/personal-workflow` where the reference is skill-scoped. Leave references that name the *feature* (F000004) alone
- [ ] Copy the `## Knowledge Configuration` section from company-workflow/WORKFLOW.md into personal-workflow/WORKFLOW.md, positioned at the end of the file (after the existing `## Installation` section), matching company-workflow's placement
- [ ] Adapt the WORKFLOW.md prose: every command reference becomes `/personal-workflow`; the F000004 backlink path is identical
- [ ] Add a T000007 test block in `scripts/test.sh` immediately after the T000003 block. Copy T000003's structure wholesale, then flip the `_SKILL=` path variable to `skills/personal-workflow/SKILL.md`
- [ ] Ensure the T000007 block also covers the Loading assertions (S7–S12 from the TEST-SPEC Tier 1 table) — if S000005's T000006 added loading assertions to company-workflow's block, mirror them in T000007
- [ ] Run `./scripts/test.sh` end-to-end; fix any failures before committing
- [ ] Run `/personal-workflow check work-items/features/F000004_knowledge_integration/` to confirm the whole F000004 tree still validates after this task's edits
- [ ] Capture a `before.txt` baseline of `/personal-workflow check` output (unset env var) BEFORE the port, then diff after — the only allowed delta is the new stderr warning line
- [ ] Update the F000004_TRACKER Files section with the three touched files (skills/personal-workflow/SKILL.md, skills/personal-workflow/WORKFLOW.md, scripts/test.sh)

## Log

<!-- Chronological entries with dates and commit SHAs. Each entry records
     what happened, not what should happen. -->

- 2026-04-20: Created. Single implementation task for S000006's parity port. Scope: three copy-and-adapt moves (SKILL.md Resolution + Loading, WORKFLOW.md Knowledge Configuration) plus a mirrored T000007 test block in `scripts/test.sh`. Blocked by S000005 landing on `main`.
- 2026-04-20: **DEFERRED** alongside parent S000006. /autoplan dual voices (CEO phase) converged 5/6 CONFIRMED-NO on the parent story's premises. User chose evidence-gated deferral at premise gate. See `S000006_TRACKER.md` Log for full rationale. Task artifacts retained; resumable once S000006 is unblocked.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. Populated during Track phase, updated during Implement. -->

- skills/personal-workflow/SKILL.md (to be modified — add `## Knowledge Resolution` + `## Knowledge Loading` sections mirrored from company-workflow)
- skills/personal-workflow/WORKFLOW.md (to be modified — add `## Knowledge Configuration` section mirrored from company-workflow)
- scripts/test.sh (to be modified — add T000007 parallel assertion block pointed at personal-workflow/SKILL.md; source shared `scripts/test-helpers/knowledge.sh`)

## Insights

<!-- Non-obvious findings worth remembering. Things that surprised you,
     patterns discovered, or context that future readers will need. -->

- The T000003 test block landed as "Regression test (T000004)" in `scripts/test.sh` after the 2026-04-19 task consolidation. When mirroring, follow that naming: the header comment in the new block should read "Regression test (T000007 — personal-workflow parity port)" so grep continues to find both blocks by task ID.
- Be deliberate about where the section name is vs. skill name: `## Knowledge Resolution` is the **section** name (must match across skills for the test assertions and WORKFLOW.md backlinks to work). `/company-workflow` vs `/personal-workflow` is the **skill** name (must diverge). Code review needs to keep the two straight.

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->
