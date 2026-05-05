---
name: "personal-workflow: feature type does not require a DESIGN.md artifact"
type: defect
id: "D000009"
status: closed
created: "2026-04-22"
updated: "2026-04-25"
repo: "jcl2018/claude-skills-templates"
branch: "fix/feature-requires-design-doc"
blocked_by: ""
---

## Lifecycle

### Phase 1: Track

1. Document reproduction steps in the Log section
2. Create working branch: `git checkout -b fix/feature-requires-design-doc`
3. Scaffold required docs:
   - `D000009_RCA.md` (root cause analysis) — from `templates/personal-workflow/doc-RCA.md`
   - `D000009_test-plan.md` (regression test plan) — from `templates/personal-workflow/doc-test-plan.md`
4. Run `/investigate` to diagnose root cause
   → produces investigation findings in Log + Insights
5. Log initial symptoms and hypotheses

**Gates:**
- [x] Reproduction steps documented
- [x] Working branch created (`branch` field populated)
- [x] Required docs scaffolded (RCA + test-plan)
- [x] Root cause identified (manifest omits design artifact; no doc-DESIGN.md template exists)

### Phase 2: Implement

1. Work from `/office-hours` design doc (if applicable) + root cause analysis
   → design doc at `~/.gstack/projects/{slug}/`
2. Implement fix based on root cause analysis
3. Write regression test covering the defect scenario
4. Commit fix and test together
5. Update RCA doc with final root cause

**Gates:**
- [x] Fix implemented (working tree clean; commit pending `/ship`)
- [x] RCA doc updated (Fix Description reflects the narrow-scope implementation)
- [x] Todos section reflects remaining work (in-scope items checked; out-of-scope items clearly labeled)

### Phase 3: Ship

1. Run `/personal-workflow check` — verify no regressions
2. Verify test-plan: regression test scenarios passing
3. Run `/ship` — creates fix PR (includes pre-landing code review)
4. Run `/land-and-deploy` — merges and verifies fix in production

❌ If regression test fails: investigate further
❌ If CI fails: fix, push, re-run `/ship`

**Gates:**
- [x] `/personal-workflow check` — validation passed
- [x] Test-plan verified — `jq '.types.feature.required' skills/personal-workflow/personal-artifact-manifests.json` now lists `design`/`DESIGN.md`; `templates/personal-workflow/doc-DESIGN.md` exists; F000001-F000004 have backfilled DESIGN.md
- [x] `/ship` — PR created
- [x] `/land-and-deploy` — merged and deployed (v0.13.1, then v0.14.2 backfilled feature-summary.md across personal-workflow)

## Reproduction Steps

1. `jq '.types.feature.required' skills/personal-workflow/personal-artifact-manifests.json`
2. **Observe:** 2 entries — `tracker` (TRACKER.md) and `milestones` (milestones.md). No `design`/`DESIGN.md` artifact.
3. Scaffold a new feature directory with just those 2 files.
4. Run `/personal-workflow check <dir>`.
5. **Observe:** validation PASSES (0 violations). Feature carries no design document and nothing flags it.

**Environment:** workbench repo at v0.13.0 (fix/feature-requires-design-doc from feat/work-copilot); personal-workflow manifest version 2.0.0.

## Todos

**In scope (this PR — narrow):**

- [x] Author `templates/personal-workflow/doc-DESIGN.md` (7 sections) and `templates/company-workflow/doc-DESIGN.md` (6 sections — drops "Not in scope" since feature-summary.md owns Out-of-Scope)
- [x] Add `{"artifact": "design", "template": "doc-DESIGN.md", "filename": "DESIGN.md"}` to feature.required in both manifests
- [x] Add template entries to `skills-catalog.json`
- [x] Backfill minimal `DESIGN.md` for F000001–F000004 (closed features, `status: Backfill`)
- [ ] Align F000005's DESIGN.md to the new template — deferred to the `feat/work-copilot` branch where F000005 lives (rename "Big decisions (already made)" → "Big decisions"; remove Sequencing section)
- [x] Add D000009 regression block to `scripts/test.sh` (4 checks: design entry in each manifest + template file present for each workflow). Also bumped the `pw_count` hardcoded count from 10 → 11 to match the new template count

**Out of scope (follow-up defects if still needed):**

- [ ] WORKFLOW.md type-to-artifact tables (personal + company) — doc drift, not validator-breaking
- [ ] Tracker-feature.md template Phase 1 step text — doc drift, not validator-breaking
- [ ] Company fixtures/examples/SKILL.md/philosophy text — doc drift
- [ ] work-copilot bundle sync — wait for F000005 to ship first (F000005 owns the bundle)

## Log

- 2026-04-22: Created. Personal-workflow (and company-workflow) feature scaffolding currently enforces only TRACKER + milestones (and feature-summary for company). No canonical home for cross-story design decisions — they scatter across TRACKER journal entries and per-user-story ARCHITECTURE.md files. Filing this defect to require `DESIGN.md` as a feature artifact. Scope deliberately narrow: manifest + template + catalog + backfill + regression test only; doc-drift items (WORKFLOW tables, fixtures, examples, philosophy) are out of scope and can be swept in a follow-up.
- 2026-04-22: First attempt was stashed and reset after scope drift — the AI touched fixtures, examples, SKILL.md, philosophy, and WORKFLOW.md tables in addition to the core fix. Restarted with a tighter scope (see the Todos split above).
- 2026-04-22: Fix implemented on fix/feature-requires-design-doc. Files: 2 new templates + 2 manifest edits + 1 catalog edit + 4 backfilled DESIGN.md + 1 aligned F000005_DESIGN.md + 1 regression block + 1 test count bump. `./scripts/validate.sh` PASS (0 errors); `./scripts/test.sh` PASS (0 failures; D000009 regression block green).
- 2026-04-25: Closed. Fix shipped in v0.13.1 (PR #42), with v0.14.2 (PR #45) extending the same pattern to feature-summary.md across personal-workflow. Manifest verification: `jq '.types.feature.required'` returns the full 4-artifact set (tracker + feature-summary + design + milestones). Tracker drift fixed during F000003 v1.0.0 cut.

## PRs

## Files

- `skills/personal-workflow/personal-artifact-manifests.json` — adds design entry to feature.required
- `skills/company-workflow/company-artifact-manifests.json` — adds design entry to feature.required
- `templates/personal-workflow/doc-DESIGN.md` — new template
- `templates/company-workflow/doc-DESIGN.md` — new template
- `skills-catalog.json` — adds doc-DESIGN.md to personal + company template lists
- `work-items/features/F000001_workflow_alpha/F000001_DESIGN.md` — backfill
- `work-items/features/F000002_system_health_v1/F000002_DESIGN.md` — backfill
- `work-items/features/F000003_company_spec_system/F000003_DESIGN.md` — backfill
- `work-items/features/F000004_knowledge_integration/F000004_DESIGN.md` — backfill
- `scripts/test.sh` — new D000009 regression block

Note: F000005_work_copilot lives on a parallel branch (`feat/work-copilot`, not yet merged). When that feature ships, its existing DESIGN.md will need to align to the new template (rename "Big decisions (already made)" → "Big decisions"; remove Sequencing section that duplicates milestones.md). Tracked as a follow-up in `feat/work-copilot`.

## Insights

<!-- Filled during /investigate. Initial observation: this is a manifest-and-template gap, not a validator bug. The validator correctly enforces whatever the manifest declares; the manifest simply never declared design as required for features. -->

## Journal
