---
name: "personal-workflow: deployed templates drift from workbench after D000009/v0.14.2"
type: defect
id: "D000012"
status: active
created: "2026-05-01"
updated: "2026-05-01"
repo: "jcl2018/claude-skills-templates"
branch: "fix/personal-workflow-template-deploy-drift"
blocked_by: ""
---

## Lifecycle

### Phase 1: Track

1. Document reproduction steps in the Log section
2. Create working branch: `git checkout -b fix/personal-workflow-template-deploy-drift`
3. Scaffold required docs:
   - `D000012_RCA.md` (root cause analysis) — from `templates/personal-workflow/doc-RCA.md`
   - `D000012_test-plan.md` (regression test plan) — from `templates/personal-workflow/doc-test-plan.md`
4. Run `/investigate` to diagnose root cause
   → produces investigation findings in Log + Insights
5. Log initial symptoms and hypotheses

**Gates:**
- [x] Reproduction steps documented
- [x] Working branch created (`branch` field populated)
- [x] Required docs scaffolded (RCA + test-plan)
- [x] Root cause identified (or best hypothesis logged)

### Phase 2: Implement

1. Work from `/office-hours` design doc (if applicable) + root cause analysis
   → design doc at `~/.gstack/projects/{slug}/`
2. Implement fix based on root cause analysis
3. Write regression test covering the defect scenario
4. Commit fix and test together
5. Update RCA doc with final root cause

**Gates:**
- [x] Fix committed
- [x] RCA doc updated
- [x] Todos section reflects remaining work (no stale items)

### Phase 3: Ship

1. Run `/personal-workflow check` — verify no regressions
2. Verify test-plan: regression test scenarios passing
3. Run `/ship` — creates fix PR (includes pre-landing code review)
4. Run `/land-and-deploy` — merges and verifies fix in production

❌ If regression test fails: investigate further
❌ If CI fails: fix, push, re-run `/ship`

**Gates:**
- [ ] `/personal-workflow check` — validation passed
- [ ] Test-plan verified (regression scenarios passing)
- [ ] `/ship` — PR created
- [ ] `/land-and-deploy` — merged and deployed

## Reproduction Steps

1. From a non-workbench repo using personal-workflow (e.g., `/Users/chjiang/Documents/projects/portfolio`), invoke `/personal-workflow check work-items/features/discord-v1`
2. Path resolution falls to Level 2: `_TMPL_DIR=~/.claude/templates/personal-workflow/`
3. `ls ~/.claude/templates/personal-workflow/` — observe missing `doc-DESIGN.md` and `doc-feature-summary.md`. `tracker-feature.md` is dated Apr 16 (workbench source: Apr 25; smaller bytecount).
4. The manifest at `~/.claude/skills/personal-workflow/personal-artifact-manifests.json` (symlinked to workbench) declares `feature.required` = `[tracker, feature-summary, design, milestones]`.
5. **Observe:** validator reports `[MISSING] feature-summary` and `[MISSING] design` for `discord-v1`. For a directory that has feature-summary.md (e.g., `cold-start`), frontmatter validation is skipped because the template can't be resolved (only the existence check fires).

**Environment:** workbench at v1.1.0 / D000009 closed in v0.13.1. `~/.claude/templates/personal-workflow/` last updated Apr 16. Portfolio repo has no local `templates/` so it always resolves to the deployed copy.

## Todos

**In scope (this PR — narrow):**

- [x] Re-run `scripts/skills-deploy install --overwrite` — refreshed 7 templates across personal-workflow + company-workflow (3 newly installed, 4 overwritten due to checksum drift)
- [x] Add D000012 regression block to `scripts/test.sh` covering both workflows: (a) catalog declares both new templates and (b) deployed dir byte-matches workbench when `~/.claude/templates/{workflow}/` exists (skip with INFO when not deployed, e.g. CI)
- [x] Verify drift block actually catches drift (ran test.sh pre-deploy: 7 FAILs surfacing the same 7 deltas the deploy then fixed) — proves the regression test would have caught the original D000009/v0.14.2 drift before it shipped

**Out of scope (follow-up defects if still needed):**

- [x] **Option C design call** (see RCA Fix Description) — decided **C2** (post-merge hook). Shipped in D000013 / v1.1.2. C1 (symlink templates dir) remains unimplemented; revisit only if the workbench-must-exist trade-off becomes a real constraint.
- [ ] **Portfolio backfill** — `discord-v1` now correctly reports `[MISSING] feature-summary` and `[MISSING] design`. `cold-start` is missing DESIGN.md. These were previously silently skipped due to template-not-found. The validator surfacing them now is the intended behavior change; backfill is a portfolio-side task.
- [ ] **WORKFLOW.md type-to-artifact tables** — `skills/personal-workflow/WORKFLOW.md` lines 19-25 and 62-67 still say "Feature: tracker + milestones (2 artifacts)" (doc drift, not validator-breaking; same drift item D000009 deferred)
- [ ] **Deployed-extra detection** — current drift check iterates over workbench templates only; an old template that was removed from workbench would linger in `~/.claude/templates/` undetected. Low priority because removed templates are rare, but worth a follow-up.

## Log

- 2026-05-01: Created. While scaffolding `cold-start` in portfolio and validating against the existing `discord-v1`, observed that the deployed templates at `~/.claude/templates/personal-workflow/` are missing `doc-DESIGN.md` (added to the workbench in D000009 / v0.13.1) and `doc-feature-summary.md` (added separately in v0.14.2 / PR #45). The workbench manifest already requires both for `feature` type, so any non-workbench repo using personal-workflow sees the new manifest requirement but cannot resolve the templates. `tracker-feature.md` in the deployed copy is also stale (Apr 16 vs Apr 25 in workbench). Filing this defect to track the deploy drift mechanism, separate from any per-repo backfill.
- 2026-05-01: Phase 2 implemented on `fix/personal-workflow-template-deploy-drift`. Added a generic D000012 regression block to `scripts/test.sh` covering both personal-workflow and company-workflow templates. Block verifies (a) `skills-catalog.json` declares both new templates and (b) when `~/.claude/templates/{workflow}/` exists on the host, every workbench template is byte-identical in the deployed copy. Pre-fix run surfaced 7 FAILs (more than the originally-noted 2): personal-workflow missing `doc-DESIGN.md` and `doc-feature-summary.md` plus drifted `tracker-feature.md` and `tracker-user-story.md`; company-workflow missing `doc-DESIGN.md` plus drifted `doc-milestones.md` and `tracker-feature.md`. Ran `scripts/skills-deploy install --overwrite` (Option A) — installed 7 templates (3 new + 4 overwritten). Re-ran `./scripts/test.sh` — 0 failures. The drift check generalizes the systemic deploy-sync gap; D000009's doc-DESIGN.md and v0.14.2's doc-feature-summary.md were just two instances of a broader pattern that also affected company-workflow.

## PRs

## Files

- `scripts/test.sh` — added D000012 regression block (~50 lines) after the existing D000009 block. Generic over both workflows; gracefully skips when deployed dir is absent (e.g. CI).
- `~/.claude/templates/{personal,company}-workflow/` — refreshed via `scripts/skills-deploy install --overwrite` (runtime action, not a committed file change)
- `work-items/defects/D000012_personal_workflow_template_deploy_drift/` — TRACKER + RCA + test-plan

## Insights

<!-- Initial observation: D000009 closed claiming workbench was fixed and F000001-F000004 backfilled, but the deploy step (re-running skills-deploy install) is implicit and was missed. The validator's 2-level path resolution is correct; the templates at Level 2 simply weren't refreshed. The downstream consequence is that any other repo using personal-workflow inherits the manifest requirement without the templates needed to satisfy it.

Phase 2 finding: the drift was broader than initially scoped. The original observation was 2 missing personal-workflow templates. The generic drift block surfaced 7 deltas across both personal-workflow and company-workflow — including company-workflow's `doc-DESIGN.md` MISSING (the same D000009 pattern) and 4 templates that had been edited in workbench post-deploy without a refresh. The regression block now catches all of them and forces a re-deploy whenever the workbench source moves ahead of `~/.claude/templates/`. Generalizing to company-workflow was the right call — it's the same deploy-sync mechanism, not a per-skill quirk. -->

## Journal
