---
type: test-plan
parent: D000009
title: "personal-workflow: feature type does not require DESIGN.md — Test Plan"
date: 2026-04-22
author: chjiang
status: Draft
---

## Scope

Files changed in this PR:
- `skills/personal-workflow/personal-artifact-manifests.json` — add design artifact to `feature.required`
- `skills/company-workflow/company-artifact-manifests.json` — add design artifact to `feature.required`
- `templates/personal-workflow/doc-DESIGN.md` — new template
- `templates/company-workflow/doc-DESIGN.md` — new template
- `skills-catalog.json` — add doc-DESIGN.md entries for both workflows
- `work-items/features/F000001_*/F000001_DESIGN.md` through `F000004_*/F000004_DESIGN.md` — backfill (4 files)
- `work-items/features/F000005_work_copilot/F000005_DESIGN.md` — aligned to template
- `scripts/test.sh` — D000009 regression block

## Regression Test Cases

| # | Test Case | Steps | Expected Result | Status |
|---|-----------|-------|-----------------|--------|
| 1 | Missing DESIGN.md flagged (personal) | Scaffold a personal-workflow feature directory with only TRACKER.md + milestones.md; run `/personal-workflow check <dir>` | Validator reports VIOLATION: missing required artifact `DESIGN.md` | Pending |
| 2 | Fully scaffolded personal feature passes | Scaffold a feature with TRACKER + DESIGN + milestones; run `/personal-workflow check <dir>` | Validation passes (0 violations) | Pending |
| 3 | Missing DESIGN.md flagged (company) | Scaffold a company-workflow feature with TRACKER + feature-summary + milestones but no DESIGN; run `/company-workflow validate <dir>` | Validator reports VIOLATION: missing required artifact `DESIGN.md` | Pending |
| 4 | Existing features all pass | Run `/personal-workflow check work-items/` after backfill | All 5 features (F000001–F000005) pass validation; no missing-DESIGN violations | Pending |
| 5 | DESIGN.md frontmatter enforced | Create DESIGN.md with no YAML frontmatter; run validator | Validator reports VIOLATION: missing/invalid frontmatter | Pending |
| 6 | test.sh D000009 regression block | Run `./scripts/test.sh` | New D000009 block passes (greps for design entry in both manifests; greps for doc-DESIGN.md presence) | Pending |

## Verification Steps

- [ ] `scripts/validate.sh` — catalog ↔ filesystem consistency passes
- [ ] `scripts/test.sh` — full suite passes including the new D000009 regression block
- [ ] `/personal-workflow check work-items/` — all features pass (backfill worked)
- [ ] Manual scaffold: new feature without DESIGN.md fails validation (regression case 1)
- [ ] Manual scaffold: new feature with DESIGN.md passes validation (regression case 2)

## Environments Tested

| Environment | Build | Result |
|------------|-------|--------|
| macOS Darwin 25.3.0 | fix/feature-requires-design-doc @ {commit} | Pending |
