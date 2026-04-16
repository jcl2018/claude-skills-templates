---
type: test-plan
parent: D000003
title: "company-workflow feature ↔ user-story artifact duplication — Regression Test Plan"
date: 2026-04-16
author: chjiang
status: Draft
---

## Scope

Validates the Issue 2 fix in `skills/company-workflow/`:
- `company-artifact-manifests.json` (feature artifact set narrows from 5 to 3)
- `WORKFLOW.md` (summary table updated)
- `templates/company-workflow/doc-feature-summary.md` (new template)
- `skills-catalog.json` (new template entry)
- `CHANGELOG.md` (migration note)

Issues 1 and 3 are out of scope — they ship under D000004 with the round-trip runner architecture decision.

## Regression Test Cases

| # | Test Case | Steps | Expected Result | Status |
|---|-----------|-------|-----------------|--------|
| 1 | Manifest declares 3 feature artifacts | `jq '.types.feature.required \| length' skills/company-workflow/company-artifact-manifests.json` | 3 | Pending |
| 2 | Manifest declares 5 user-story artifacts (unchanged) | `jq '.types["user-story"].required \| length' skills/company-workflow/company-artifact-manifests.json` | 5 | Pending |
| 3 | feature-summary.md template exists | `[ -f templates/company-workflow/doc-feature-summary.md ]` | Exit 0 | Pending |
| 4 | feature-summary.md template has expected sections | `grep -q '## Scope\|## Success Criteria\|## Constituent User-Stories\|## Out-of-Scope' templates/company-workflow/doc-feature-summary.md` | All four sections present | Pending |
| 5 | skills-catalog.json registers feature-summary.md | `jq '.[] \| select(.name == "company-workflow") \| .templates[]' skills-catalog.json \| grep feature-summary` | Match | Pending |
| 6 | WORKFLOW.md summary table updated | `grep -A2 "feature " skills/company-workflow/WORKFLOW.md \| grep -E "tracker.*feature-summary.*milestones"` | Match | Pending |
| 7 | `./scripts/validate.sh` exits 0 | run script | Exit 0 | Pending |
| 8 | `./scripts/test.sh` exits 0 | run script | Exit 0 | Pending |
| 9 | `skills-deploy doctor` reports new template healthy | `scripts/skills-deploy doctor` | feature-summary.md listed under company-workflow templates, no missing/drifted/orphaned | Pending |
| 10 | `skills-deploy install --overwrite` ships new template | `scripts/skills-deploy install --overwrite && [ -f ~/.claude/templates/company-workflow/doc-feature-summary.md ]` | Template present at deploy location | Pending |
| 11 | **Post-deploy:** legacy ai-content tracker tolerated | After fix deployed: `/company-workflow validate ai-content/work-items/F973012/` | No false-positive violations on legacy `PRD.md`/`ARCHITECTURE.md`/`TEST-SPEC.md` | Pending |
| 12 | **Post-deploy:** new feature scaffold rejects missing feature-summary.md | Scaffold a fresh feature (no feature-summary.md), run `/company-workflow validate <dir>` | Validator reports `feature-summary` artifact missing | Pending |
| 13 | **Cross-skill regression:** personal-workflow unchanged | `/personal-workflow check work-items/` | Same pass/fail count as before fix | Pending |
| 14 | CHANGELOG entry exists with migration note | `grep -A5 "feature-summary\|feature artifact set" CHANGELOG.md` | Match | Pending |

## Verification Steps

- [ ] `./scripts/validate.sh` exits 0
- [ ] `./scripts/test.sh` exits 0
- [ ] `/personal-workflow check work-items/` shows no new violations (sibling skill regression)
- [ ] `skills-deploy doctor` reports the new template healthy
- [ ] Manual: scaffold a fresh feature dir, confirm validator demands `feature-summary.md`
- [ ] Manual: `/company-workflow validate` against legacy `ai-content/F973012/` produces no false positives
- [ ] CHANGELOG entry written with migration note
- [ ] Skill version bumped per `scripts/collection-version.sh`

## Environments Tested

| Environment | Build | Result |
|-------------|-------|--------|
| macOS Darwin 25.3.0 — workbench repo | branch `claude/nostalgic-volhard` | Pending |
| macOS Darwin 25.3.0 — ai-content consumer repo (post-deploy) | master @ post-fix | Pending |
