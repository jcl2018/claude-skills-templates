---
name: "migrate-company-workflow"
type: task
id: "T000013_migrate_company_workflow"
status: active
created: "2026-05-02"
updated: "2026-05-02"
parent: "S000012_deprecated_status_semantics"
repo: "claude-skills-templates"
branch: "feat/deprecated-skill-status"
blocked_by: "S000012"
---

## Lifecycle

### Phase 1: Track

1. Read parent tracker to understand scope and acceptance criteria
2. Create working branch: `git checkout -b feat/deprecated-skill-status`
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
- [x] Core changes committed (>=1 commit SHA in Log) — pending commit; see Log
- [x] Todos section reflects remaining work (no stale items)
- [x] Files section updated with changed files

### Phase 3: Ship

1. Run `/personal-workflow check` — verify no regressions
2. Verify test-plan: all test scenarios passing
3. Run `/ship` — creates PR, bumps version, updates changelog (includes pre-landing code review)
4. Run `/land-and-deploy` — merges PR and verifies deployment

❌ If tests fail: fix, re-run
❌ If CI fails: fix, push, re-run `/ship`

**Gates:**
- [x] `/personal-workflow check` — validation passed
- [x] Test-plan verified (all 10 regression cases Pass)
- [ ] `/ship` — PR created
- [ ] `/land-and-deploy` — merged and deployed

## Todos

<!-- Actionable items for this task. Not lifecycle duplicates — these are
     the actual things to build, fix, or investigate. -->

- [x] Edit `skills-catalog.json` — change `company-workflow` entry's `status` from `"active"` to `"deprecated"`
- [x] Run `scripts/validate.sh` — clean, RESULT: PASS, 0 errors / 0 warnings
- [x] Run `scripts/generate-readme.sh` — regenerated README; `company-workflow` row now under `### Deprecated` section (line 19), absent from main active table
- [x] Verify install on a clean target: `SKILLS_DEPLOY_TARGET=/tmp/skills-deploy-test-* ./scripts/skills-deploy install` → company-workflow/ NOT created, one `WARN: skipping deprecated skill: company-workflow (use --include-deprecated to install)` line, summary shows `Deprecated-skipped: 1`
- [x] Verify `--include-deprecated`: same target after re-run with `--include-deprecated` → company-workflow/ + all 17 templates installed, no WARN, summary shows `Installed: 4`
- [x] Verify doctor: both states emit INFO not WARN, exit 0; not-installed → `INFO: company-workflow — deprecated, not installed by default`; installed → `INFO: company-workflow — deprecated, installed (--include-deprecated)`
- [x] Verify `work-copilot/` byte-mirror still passes: `scripts/validate.sh` Error check 10 (`MIRROR_SPECS`, 7 entries) all PASS
- [x] Run `./scripts/test.sh` — `Failures: 0  RESULT: PASS`
- [ ] Update `F000005_TRACKER.md` and `S000012_TRACKER.md` Files / Log sections with actual SHAs (pending commit)

## Log

<!-- Chronological entries with dates and commit SHAs. Each entry records
     what happened, not what should happen. -->

- 2026-05-02: Created. Verification gate for F000005 — flip `company-workflow` to `status: deprecated` and verify the new install/doctor/README behavior end-to-end on a clean target.
- 2026-05-02: Executed. company-workflow flipped to `deprecated` in catalog (skills-catalog.json:105). README regenerated with new `### Deprecated` section. All 10 regression test-plan cases Pass on macOS (zsh, bash 3.2.57). work-copilot byte-mirror invariant intact. `./scripts/test.sh` PASS.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. Populated during Track phase, updated during Implement. -->

- skills-catalog.json   # only the company-workflow entry's status field changes
- README.md             # regenerated with new "Deprecated" section

## Insights

<!-- Non-obvious findings worth remembering. Things that surprised you,
     patterns discovered, or context that future readers will need. -->

- The `skills/company-workflow/` source files MUST stay in the repo even after deprecation — `work-copilot/` byte-mirrors them and `validate.sh` Error check 10 enforces it. Deprecation here is purely a *visibility / install* signal.
- Idempotency check matters: a user with a pre-existing `~/.claude/skills/company-workflow/` should NOT have it removed by the new install — install only adds, never deletes, even when filtering. The deprecation just stops *new* installs.

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

### 2026-05-02 — decision

Scoped as a task (not a sub-story) because the surface area is one catalog field flip + a fixed verification checklist. There's no PRD-shaped requirement set distinct from S000012's; the migration is the *gate* that proves S000012 actually works on the canonical target.
