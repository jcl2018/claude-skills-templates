---
name: "personal-workflow scaffold and check skip subdir-prefix and hierarchy.min"
type: defect
id: "D000007"
status: active
created: "2026-04-16"
updated: "2026-04-16"
repo: "jcl2018/claude-skills-templates"
branch: "fix/scaffold-prefix-hierarchy"
blocked_by: ""
---

## Lifecycle

### Phase 1: Track

1. Document reproduction steps in the Log section
2. Create working branch: `git checkout -b fix/scaffold-prefix-hierarchy`
3. Scaffold required docs:
   - `D000007_RCA.md` (root cause analysis) — from `templates/doc-RCA.md`
   - `D000007_test-plan.md` (regression test plan) — from `templates/doc-test-plan.md`
4. Diagnose root cause (covered in RCA — spec gap + missing validator coverage)
5. Log initial symptoms and hypotheses

**Gates:**
- [x] Reproduction steps documented
- [x] Working branch created (`branch` field populated)
- [x] Required docs scaffolded (RCA + test-plan)
- [x] Root cause identified (WORKFLOW.md spec gap; Tier 2 validator does not enforce subdir name or `hierarchy.min`)

### Phase 2: Implement

1. Update `skills/personal-workflow/WORKFLOW.md` Directory Layout to require `{ID}_{slug}/` for every work-item directory (not just files)
2. Extend `skills/personal-workflow/check.md` Tier 2 Step 19 to:
   - Validate each work-item subdir matches `^{ID_PREFIX}\d+_{slug}$`
   - Verify the embedded ID matches the directory's TRACKER.md frontmatter `id`
   - Enforce `hierarchy.{type}.min` when counting `required_child` (currently the `min` is read but not enforced for "0 children" — already partial in 19b; verify and harden)
3. Add fixtures under `skills/personal-workflow/fixtures/`:
   - `invalid-unprefixed-subdir/` — feature with bare-slug user-story child
   - `invalid-missing-required-child/` — user-story with zero task children
4. Update `WORKFLOW.md` Directory Layout example to show prefixed subdirs
5. Run `scripts/test.sh` and `/personal-workflow check` against fixtures
6. Commit changes

**Gates:**
- [ ] WORKFLOW.md updated
- [ ] check.md updated
- [ ] Fixtures added (positive + 2 negative)
- [ ] All existing tests pass
- [ ] New negative fixtures produce expected violations
- [ ] RCA updated with final root cause and fix description
- [ ] Todos section reflects remaining work (no stale items)

### Phase 3: Ship

1. Run `/personal-workflow check work-items/defects/D000007_scaffold_subdir_prefix_and_hierarchy/` — should pass
2. Run `scripts/validate.sh` — repo health check
3. Verify test-plan: all regression scenarios passing
4. `/ship` — creates fix PR targeting `claude/nostalgic-volhard`
5. After merge: backfill `portfolio/work-items/features/discord-v1/*` (cross-repo task — see related portfolio defect D000001)
6. `/land-and-deploy` if applicable

❌ If regression test fails: investigate further
❌ If CI fails: fix, push, re-run `/ship`

**Gates:**
- [ ] `/personal-workflow check` — validation passed on this work item
- [ ] `scripts/validate.sh` — repo validation passed
- [ ] Test-plan verified (all scenarios passing)
- [ ] `/ship` — PR created
- [ ] Cross-repo backfill tracked (portfolio D000001)

## Reproduction Steps

**Bug 1 — Subdirectories missing ID prefix:**

1. Use `/personal-workflow` to scaffold a feature with user-story children
2. Inspect `work-items/features/{slug}/`
3. **Observe:** child user-story directories are named `{child-slug}/`, not `{ID}_{child-slug}/`
4. Files inside the child do use the `{ID}_` prefix (e.g., `S000001_TRACKER.md`), so the convention is inconsistent at the directory boundary
5. **Observe:** `/personal-workflow check` does not flag the missing directory prefix

**Bug 2 — Missing required hierarchy levels:**

1. `personal-artifact-manifests.json` declares `hierarchy.user-story = {required_child: task, min: 1}`
2. Scaffold a feature with user-story children
3. **Observe:** no `task/` subdirectories are generated under any user-story
4. **Observe:** `/personal-workflow check` does not robustly flag "0 children of required type" against `hierarchy.min` (review Step 19b — the rule is documented, verify enforcement)

**Discovery context:** Found while reviewing `portfolio/work-items/features/discord-v1/` — 5 user-story dirs all unprefixed and childless. See cross-referenced defect: `portfolio/work-items/defects/D000001_scaffold-prefix-hierarchy/`.

## Todos

- [ ] Read current `check.md` Step 19 carefully — confirm whether the `min` enforcement bug is "missing entirely" or "documented but not implemented in practice"
- [ ] Decide: directory-name validation lives in Step 19 (structural) or a new step
- [ ] Update `WORKFLOW.md` Directory Layout — show `{ID}_{slug}/` for all work-item dirs, with corrected example
- [ ] Update `WORKFLOW.md` Placeholder Replacement table if a new placeholder is needed (e.g., `{SLUG_DIR}`)
- [ ] Extend `check.md` Step 19 with `[STRAY]`-adjacent rule for unprefixed work-item dirs (`[MISFORMATTED]` or similar)
- [ ] Verify `check.md` Step 19b actually emits `[INCOMPLETE]` when count is zero (re-read existing logic)
- [ ] Add fixture: feature with unprefixed user-story child
- [ ] Add fixture: user-story with no task subdirs
- [ ] Add positive counter-fixture: properly nested feature → S00X_user-story → T00X_task
- [ ] Run scripts/test.sh — verify no regressions
- [ ] Run /personal-workflow check on portfolio/discord-v1 — should now report violations

## Log

- 2026-04-16: Created. Companion to portfolio D000001 (`scaffold-prefix-hierarchy`). Implementing fix in source-of-truth repo. Forked from `claude/nostalgic-volhard` to keep work isolated from in-flight D000006.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

- `skills/personal-workflow/WORKFLOW.md` — Directory Layout + Placeholder Replacement
- `skills/personal-workflow/check.md` — Tier 2 Step 19 (Structural Completeness)
- `skills/personal-workflow/fixtures/invalid-unprefixed-subdir/` — new
- `skills/personal-workflow/fixtures/invalid-missing-required-child/` — new
- `skills/personal-workflow/fixtures/valid-nested-feature/` — new (positive case)
- `skills/personal-workflow/personal-artifact-manifests.json` — possibly extend if new fields needed (likely not)

## Insights

<!-- To be filled after implementation. -->

## Journal

<!-- Structured entries from the work-track journal command. -->
