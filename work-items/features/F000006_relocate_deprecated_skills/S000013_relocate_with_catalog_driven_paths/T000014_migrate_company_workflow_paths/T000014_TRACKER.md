---
name: "migrate-company-workflow-paths"
type: task
id: "T000014_migrate_company_workflow_paths"
status: active
created: "2026-05-02"
updated: "2026-05-02"
parent: "S000013_relocate_with_catalog_driven_paths"
repo: "claude-skills-templates"
branch: "feat/relocate-deprecated-skills"
blocked_by: ""
---

## Lifecycle

### Phase 1: Track

1. Read parent tracker to understand scope and acceptance criteria
2. Create working branch: `git checkout -b feat/relocate-deprecated-skills`
   (uses parent's branch — same PR; no separate branch warranted)
3. Scaffold required docs:
   - `test-plan.md` (test scenarios for this task) — from `templates/doc-test-plan.md`
4. Populate Files section with expected changed files
5. Write initial Todos from parent's acceptance criteria

**Gates:**
- [x] Parent scope read (parent tracker reviewed)
- [ ] Working branch created (`branch` field populated)
- [x] Required docs scaffolded (test-plan)
- [x] Files section populated

### Phase 2: Implement

1. Work from `/office-hours` design doc + parent's acceptance criteria + your Todos
   → design doc at `~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-main-design-20260502-015311.md`
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

- [ ] Run all 6 regression cases in `T000014_test-plan.md` end-to-end on a fresh `SKILLS_DEPLOY_TARGET`
- [ ] Verify `validate.sh` Error check 10 reports PASS for all 7 mirror entries (byte-identity)
- [ ] Verify `test.sh` exits 0 with no behavioral changes (only path-replacement diffs)
- [ ] Confirm `scripts/skills-deploy doctor` reports `company-workflow` under INFO at the new path
- [ ] Capture before/after manifest contents to confirm path field reflects `deprecated/company-workflow/SKILL.md`
- [ ] Update test-plan Status column to Pass/Fail per case; record commit SHA in Log

## Log

<!-- Chronological entries with dates and commit SHAs. Each entry records
     what happened, not what should happen. -->

- 2026-05-02: Created. Verification gate for F000006 — runs the full clean-target install matrix (default + --include-deprecated + doctor) plus the mirror invariant byte-check, confirms behavior is unchanged from F000005's lifecycle except for the source path on disk.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. Populated during Track phase, updated during Implement. -->

<!-- This task does not directly modify code — it verifies the changes made by S000013.
     "Affected" here means files inspected/exercised by the verification matrix. -->

- skills-catalog.json                            # inspected (catalog files[] / templates[] paths)
- scripts/skills-deploy                          # exercised (install + install --include-deprecated + doctor)
- scripts/validate.sh                            # exercised (full run, esp. Error check 10)
- scripts/test.sh                                # exercised (full run)
- deprecated/company-workflow/                   # source root inspected
- ~/.claude/skills/company-workflow/             # destination dir inspected (in test target)
- $SKILLS_DEPLOY_TARGET/manifest.json            # manifest path field inspected

## Insights

<!-- Non-obvious findings worth remembering. Things that surprised you,
     patterns discovered, or context that future readers will need. -->

- The verification gate is purely *observational* — no code changes. If a regression case fails, the fix lands in S000013, not here. Test cases re-run after S000013 fixes.
- The manifest path field is the most useful single signal: it reflects the actual source location resolved by skills-deploy. Pre-feature: `skills/company-workflow/SKILL.md`. Post-feature: `deprecated/company-workflow/SKILL.md`.

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->
