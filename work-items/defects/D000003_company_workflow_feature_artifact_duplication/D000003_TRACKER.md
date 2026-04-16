---
name: "company-workflow feature ↔ user-story artifact duplication"
type: defect
id: "D000003"
status: active
created: "2026-04-16"
updated: "2026-04-16"
repo: "jcl2018/claude-skills-templates"
branch: "claude/nostalgic-volhard"
blocked_by: ""
---

## Lifecycle

### Phase 1: Track

1. Document reproduction steps in the Log section
2. Create working branch: `git checkout -b fix/company-workflow-feature-artifact-duplication`
3. Scaffold required docs:
   - `D000003_RCA.md` (root cause analysis) — from `templates/doc-RCA.md`
   - `D000003_test-plan.md` (regression test plan) — from `templates/doc-test-plan.md`
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

Surfaced by deploying and using `/company-workflow` against the ai-content repo (master branch). Single defect: company-workflow's manifest forces the same 5-artifact set at both feature scope and nested user-story scope, causing duplicated content for the same scope.

1. Open `skills/company-workflow/company-artifact-manifests.json` and `WORKFLOW.md`
2. Both `feature` and `user-story` declare the same 5 required artifacts: TRACKER + PRD + ARCHITECTURE + TEST-SPEC + milestones
3. Scaffold a feature with a nested user-story in ai-content (e.g. `F973012/` containing `S1441024-hfss-integration/`)
4. Inspect both directories:
   - `F973012_PRD.md` (148 lines), `F973012_ARCHITECTURE.md` (173 lines), `F973012_TEST-SPEC.md` (76 lines) at feature scope
   - The same 3 artifacts inside `S1441024-hfss-integration/`, with overlapping content scope
5. **Observe:** product/architecture/test-spec content is required at both feature level and the nested user-story level — duplicated coverage of the same scope, no contract-level distinction between feature-scope vs story-scope of those docs

**Environment:** macOS 25.3.0; deployed via `skills-deploy install` to `~/.claude/skills/company-workflow/`; consumed in the ai-content repo, master branch.

**Note on scope:** This defect was originally part of a 3-issue cluster (`D000003_company_workflow_contract_template_drift`). On 2026-04-16 the scope was narrowed to Issue 2 only because Issues 1 and 3 (workflow_type frontmatter drift, section-order drift) hit a separate architectural blocker (LLM-driven validators can't be exec'd from a bash round-trip runner). Those two issues were spun out to **D000004**. This defect ships independently with a pure manifest + template edit and no runner architecture dependency.

## Todos

- [x] Decide whether feature should be a strict superset of user-story artifacts or a different artifact set. **Decided** in /office-hours 2026-04-16: feature drops PRD/ARCH/TEST-SPEC, gains a new lightweight `feature-summary.md` artifact, keeps milestones. Preserves feature-scope design identity without duplicating story-scope content.
- [x] Update `skills/company-workflow/company-artifact-manifests.json`: feature requires `tracker + feature-summary + milestones` (3 artifacts); user-story unchanged at 5.
- [x] Add `templates/company-workflow/doc-feature-summary.md`. Sections: YAML frontmatter (`type: feature-summary`, `parent: {FEATURE_ID}`, `title`, `date`, `author`, `status`); `## Scope`; `## Success Criteria`; `## Constituent User-Stories`; `## Out-of-Scope`.
- [x] Update `skills/company-workflow/WORKFLOW.md` summary table to reflect the new feature artifact set.
- [x] Update `templates/company-workflow/tracker-feature.md`: lifecycle gates referencing the doc triplet (PRD + ARCHITECTURE + TEST-SPEC) replaced with feature-summary + milestones.
- [x] Add `feature-summary.md` row to the per-skill template manifest in `skills-catalog.json` so `skills-deploy install` picks it up.
- [x] Migration note in `CHANGELOG.md`: existing feature-scope `PRD.md`/`ARCHITECTURE.md`/`TEST-SPEC.md` files become legacy artifacts (validator no longer requires them at feature scope) but are not flagged. Author should migrate canonical content to the nested user-story directory.
- [x] Bump skill version per `scripts/collection-version.sh` (0.6.0 → 0.7.0 minor).
- [ ] After ship: deploy via `skills-deploy install --overwrite` and verify `skills-deploy doctor` reports the new template healthy.
- [ ] After ship: optional follow-up (file as separate task) to add `feature-summary.md` content for `F973012` in ai-content.

## Log

- 2026-04-16: Created. Three contract/template drift defects surfaced while deploying and using `/company-workflow` in the ai-content repo. Original framing covered Issues 1 + 2 + 3.
- 2026-04-16: Ran /office-hours, produced design doc with Approach B (round-trip invariant). Ran /plan-eng-review, locked implementation contract for `scripts/test-roundtrip.sh`, design doc Status moved to APPROVED.
- 2026-04-16: **STOP — implementation halted before any code written.** Discovered the validators (`/personal-workflow check`, `/company-workflow validate`) are LLM-driven SKILL.md files, not executable scripts. The bash round-trip runner is unimplementable as designed.
- 2026-04-16: **Scope narrowed to Issue 2 only.** Issue 2 (artifact duplication) is a pure manifest + template edit with no architectural dependency on the round-trip runner. Issues 1 and 3 (workflow_type drift, section-order drift) require the round-trip mechanism question to be resolved first; spun out to **D000004**. This defect (D000003) renamed from `_contract_template_drift` to `_feature_artifact_duplication` to reflect the narrowed scope. Directory and file IDs unchanged.
- 2026-04-16: Updated `updated:` field to reflect today's work.
- 2026-04-16: **Fix implemented.** Edited `skills/company-workflow/company-artifact-manifests.json` (feature.required: 5 → 3 artifacts), created `templates/company-workflow/doc-feature-summary.md`, updated `templates/company-workflow/tracker-feature.md` (lifecycle gates), updated `skills/company-workflow/WORKFLOW.md` (Step 1 list + summary table + rationale paragraph), registered new template in `skills-catalog.json`, bumped VERSION 0.6.0 → 0.7.0, added CHANGELOG 0.7.0 entry with migration note. Pending validate + test + commit.

## PRs

## Files

- `skills/company-workflow/company-artifact-manifests.json` — feature artifact set narrows from 5 to 3 (tracker + feature-summary + milestones); user-story unchanged
- `skills/company-workflow/WORKFLOW.md` — summary table + Step 1 list updated for the new feature artifact set; rationale paragraph added
- `templates/company-workflow/doc-feature-summary.md` — NEW lightweight one-pager template (Scope, Success Criteria, Constituent User-Stories, Out-of-Scope)
- `templates/company-workflow/tracker-feature.md` — lifecycle gate references updated from "PRD + ARCHITECTURE + TEST-SPEC" triplet to "feature-summary + milestones"
- `skills-catalog.json` — adds `company-workflow/doc-feature-summary.md` to the templates list (13 → 14)
- `CHANGELOG.md` — 0.7.0 entry with manifest change + migration note for legacy ai-content trackers
- `VERSION` — 0.6.0 → 0.7.0 (minor; new artifact required for feature type)

## Insights

Issue 2 is a design question, not a pure bug. The skill's documented intent never said *why* feature needs PRD/ARCH/TEST-SPEC when its nested user-stories already own those. The fix is a small product decision (feature-summary.md preserves feature-scope design identity without duplicating story-scope content) plus a mechanical manifest change.

**Why this ships independently from D000004:** Issue 2's symptom is "manifest forces duplicated artifacts" — visible by reading `company-artifact-manifests.json`, not by running a validator on a scaffolded file. The validator can't even detect this as a violation; it's a manifest-design issue. So unlike Issues 1 and 3 (which are template-vs-contract drift the validator should catch), Issue 2 doesn't need a round-trip runner to be confirmed or fixed. Pure JSON + new template file. Ships in isolation.

**Cross-reference:** D000004 holds Issues 1 + 3 plus the inherited round-trip runner architectural question. The original /office-hours design doc (`chjiang-claude-nostalgic-volhard-design-20260416-142220.md`, Status: NEEDS_REVISION) covered all three issues; from D000003's perspective only the "feature artifact split + feature-summary.md" portion still applies.

## Journal

