---
name: "WORKFLOW.md type-to-artifact tables drift from manifest + D000012 drift block misses deployed-extra"
type: defect
id: "D000014"
status: active
created: "2026-05-01"
updated: "2026-05-01"
repo: "jcl2018/claude-skills-templates"
branch: "fix/workflow-doc-drift-and-extra-detection"
blocked_by: ""
---

## Lifecycle

### Phase 1: Track

1. Document reproduction steps in the Log section
2. Create working branch: `git checkout -b fix/workflow-doc-drift-and-extra-detection`
3. Scaffold required docs:
   - `D000014_RCA.md` (root cause analysis) — from `templates/personal-workflow/doc-RCA.md`
   - `D000014_test-plan.md` (regression test plan) — from `templates/personal-workflow/doc-test-plan.md`
4. Run `/investigate` to diagnose root cause
   → produces investigation findings in Log + Insights
5. Log initial symptoms and hypotheses

**Gates:**
- [x] Reproduction steps documented
- [x] Working branch created (`branch` field populated)
- [x] Required docs scaffolded (RCA + test-plan)
- [x] Root cause identified (manifest changes shipped without updating WORKFLOW.md tables and prose; D000012 drift detection only iterates one direction)

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

**Drift A — WORKFLOW.md type-to-artifact tables (4 entries across 2 files):**

1. `jq -r '.types | to_entries[] | .key + ": " + ([.value.required[].filename] | join(", "))' skills/personal-workflow/personal-artifact-manifests.json`
2. **Observe:** `feature: TRACKER.md, feature-summary.md, DESIGN.md, milestones.md` (4 artifacts).
3. Read `skills/personal-workflow/WORKFLOW.md` lines 21 and 64.
4. **Observe:** lines say `Feature: tracker + milestones (2 artifacts)` and `| feature | TRACKER, milestones | 2 |` — wrong on both count (2 vs 4) and content (missing feature-summary, DESIGN).
5. Same check for `skills/company-workflow/`:
   - feature: WORKFLOW.md says 3, manifest says 4 (missing DESIGN)
   - defect: WORKFLOW.md says 3, manifest says 4 (missing PR-DESCRIPTION)
   - task: WORKFLOW.md says 2, manifest says 3 (missing PR-DESCRIPTION)
6. **Result:** the doc that the AI reads when scaffolding work items understates the required artifact count for 4 type-workflow combinations. AI-generated work items would only scaffold the listed subset and pass scaffolding-time prose checks while failing the validator's manifest reconciliation.

**Drift B — D000012 block misses deployed-extra:**

1. Manually create a stale template in `~/.claude/templates/personal-workflow/orphan.md` (simulates a workbench template removed in a later PR).
2. Run `./scripts/test.sh`.
3. **Observe:** D000012 block reports `OK: deployed templates/personal-workflow/ matches workbench source` even though `orphan.md` is in the deployed dir but not in workbench.
4. **Result:** the D000012 forward-only loop catches missing/stale workbench-declared templates but not deployed templates that were removed from workbench. Stale data lingers undetected on the user's machine.

**Environment:** workbench at v1.1.2 (commit `da3daa5`), D000012 + D000013 already shipped.

## Todos

**In scope (this PR — narrow):**

- [x] Fix `skills/personal-workflow/WORKFLOW.md` lines 21 + 64 (feature: 2 → 4, add feature-summary + DESIGN)
- [x] Fix `skills/company-workflow/WORKFLOW.md` lines 25 + 81 (feature: 3 → 4, add DESIGN)
- [x] Fix `skills/company-workflow/WORKFLOW.md` lines 28 + 84 (defect: 3 → 4, add PR-DESCRIPTION)
- [x] Fix `skills/company-workflow/WORKFLOW.md` lines 27 + 83 (task: 2 → 3, add PR-DESCRIPTION)
- [x] Extend D000012 drift block in `scripts/test.sh` with a reverse loop: every deployed template must exist in workbench (catches deployed-extras)
- [x] Add new D000014 regression block in `scripts/test.sh`: WORKFLOW.md type-to-artifact counts must match manifest counts (prevents future doc drift the same way D000012 prevents template drift)
- [x] Update D000012 TRACKER's "out of scope" — both deferred items are now resolved (cross-link D000014)
- [x] **Adjacent hygiene:** prune the retired-`skill-check.sh` reference from `scripts/setup-hooks.sh`'s pre-commit hook content (TODOS.md confirms `skill-check.sh` was removed; the hook still tried to run it, breaking commits that touched `skills/`). Re-ran setup-hooks.sh on this machine to install the fixed hook.

**Out of scope (follow-up if still needed):**

- [ ] **`skills-deploy install --prune`** — extras get reported by the new test.sh check but cleanup is manual. A `--prune` flag (or making `--overwrite` imply pruning) would close the loop. Risky for hand-edited files; defer until extras become a real problem.
- [ ] **Post-checkout hook** (carryover from D000013) — branch switches that bring template changes don't trigger post-merge auto-sync.

## Log

- 2026-05-01: Created. Two doc/coverage gaps from the D000009 + v0.14.2 manifest changes that D000012 + D000013 didn't close. (a) WORKFLOW.md tables and prose understate required artifact counts in 4 places (personal feature, company feature, company defect, company task). (b) D000012's drift block iterates over workbench templates only, so deployed-extras (stale templates left after a future workbench removal) slip through. Fixing both in one PR since they share the same root cause: changes to the manifest didn't update co-located docs/coverage.

## PRs

## Files

- `skills/personal-workflow/WORKFLOW.md` — feature row + prose updated to 4 artifacts (TRACKER + feature-summary + DESIGN + milestones)
- `skills/company-workflow/WORKFLOW.md` — feature, defect, task rows + prose updated; review unchanged
- `scripts/test.sh` — D000012 block extended with reverse-direction loop (deployed-extras); new D000014 block added (WORKFLOW.md count match)
- `work-items/defects/D000012_personal_workflow_template_deploy_drift/D000012_TRACKER.md` — out-of-scope items checked off

## Insights

<!-- Initial observation: every time the manifest changed (v0.13.1 = DESIGN, v0.14.2 = feature-summary, earlier = PR-DESCRIPTION for company defect/task), the in-repo docs that quote the manifest contents drifted. WORKFLOW.md is the most impactful drift because it's what scaffolding AIs read. The new regression check forces WORKFLOW.md and the manifest into source-of-truth alignment in CI. The deployed-extra detection closes the symmetry gap in D000012's drift block: deploy state must match workbench state in BOTH directions, not just "workbench ⊆ deployed". -->

## Journal
