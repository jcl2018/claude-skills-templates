---
type: test-plan
parent: D000007
title: "personal-workflow scaffold and check skip subdir-prefix and hierarchy.min — Regression Test Plan"
date: 2026-04-16
author: chjiang
status: Draft
---

## Scope

Changes touch the personal-workflow skill assets:

- `skills/personal-workflow/WORKFLOW.md` — Directory Layout section + example
- `skills/personal-workflow/check.md` — Tier 2 Step 19 (new subdir-name rule, possibly hardening 19b)
- `skills/personal-workflow/fixtures/` — 3 new fixtures (1 positive, 2 negative)

No production code change. No template change. No manifest change.

## Regression Test Cases

| # | Test Case | Steps | Expected Result | Status |
|---|-----------|-------|-----------------|--------|
| 1 | Unprefixed subdir → `[MISFORMATTED]` | Run `/personal-workflow check fixtures/invalid-unprefixed-subdir/` | Reports `[MISFORMATTED]` for the bare-slug child directory | Pending |
| 2 | Subdir with mismatched ID → `[MISFORMATTED]` | Construct dir `S000099_foo/` containing TRACKER with `id: S000007`; run check | Reports `[MISFORMATTED]` — embedded ID does not match TRACKER frontmatter | Pending |
| 3 | User-story with no tasks → `[INCOMPLETE]` | Run `/personal-workflow check fixtures/invalid-missing-required-child/` | Reports `[INCOMPLETE]` — 0 task children, min 1 | Pending |
| 4 | Conformant nested feature → all PASS | Run `/personal-workflow check fixtures/valid-nested-feature/` | No violations; feature → user-story → task all pass template + structure checks | Pending |
| 5 | Existing fixtures still pass | Run `/personal-workflow check fixtures/valid-feature-dir/` and `fixtures/valid-tracker.md` | Same results as before this change (no regression) | Pending |
| 6 | Existing negative fixtures still fail correctly | Run check on `invalid-bad-frontmatter.md`, `invalid-missing-artifact-dir/`, `invalid-missing-lifecycle.md`, `invalid-missing-section.md`, `invalid-wrong-order.md` | Each still emits its expected violation; no false-positives from new rules | Pending |
| 7 | discord-v1 (cross-repo) → both violations | Run `/personal-workflow check` in `portfolio/` against `work-items/features/discord-v1/` | Reports `[MISFORMATTED]` for all 5 user-story subdirs and `[INCOMPLETE]` (or equivalent) for missing task children | Pending |
| 8 | `scripts/test.sh` passes | Run `bash scripts/test.sh` from repo root | All existing tests still pass (no regression in company-workflow, system-health, or general validation) | Pending |
| 9 | `tree.md` still renders | Run `/personal-workflow tree` against `valid-nested-feature/` fixture | Tree displays prefixed subdir names cleanly | Pending |

## Verification Steps

- [ ] `/personal-workflow check work-items/defects/D000007_scaffold_subdir_prefix_and_hierarchy/` passes (the work item itself uses the new convention)
- [ ] `bash scripts/test.sh` exits 0
- [ ] `bash scripts/validate.sh` exits 0
- [ ] All 3 new fixtures produce the documented expected output when fed to `check`
- [ ] WORKFLOW.md Directory Layout example uses the new convention and matches what fixtures show
- [ ] CHANGELOG entry drafted noting the convention change and migration guidance
- [ ] Cross-repo: portfolio D000001 backfill checklist updated with the rename pattern

## Environments Tested

| Environment | Build | Result |
|------------|-------|--------|
| macOS Darwin 25.3.0, worktree `fix-scaffold-prefix` | branch `fix/scaffold-prefix-hierarchy` | Pending |
| Cross-repo: portfolio against deployed skill (after merge to `nostalgic-volhard`) | branch `claude/vigorous-nobel-777de1` | Pending |
