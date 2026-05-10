---
type: test-plan
parent: T000018
title: "Rename user-authored skills to CJ_ prefix — Test Plan"
date: 2026-05-09
author: chjiang
status: Draft
---

<!-- Scope: ONE fix (defect) or ONE task. Cases must be concrete and reproducible.
     For broader coverage of a user story, use TEST-SPEC.md instead.
     For defects, the test cases are regression cases for the specific bug. -->

## Scope

This task renames all 8 user-authored skills (active, experimental, deprecated) to use the `CJ_` prefix. Files/components modified:

- 8 × `SKILL.md` files (`name:` field)
- 8 × skill directories (renamed in place)
- `skills-catalog.json` (8 entries: `name`, `files`, `templates`, `templates_source`, `depends.skills[]`)
- 2 × template directories renamed (`templates/personal-workflow/`, `deprecated/company-workflow/templates/`)
- `work-copilot/` byte-mirror entries
- `CLAUDE.md` (skill-routing block)
- `README.md` (regenerated)
- Scripts referencing skill names (validate.sh MIRROR_SPECS, skills-deploy, test.sh, test-deploy.sh, copilot-deploy.py, generate-readme.sh, sync-upstream.sh, skills-update-check)
- `work-items/**` cross-references (grep-and-replace)
- VERSION files (per-skill + collection)

The change is purely organizational/namespacing — no functional behavior changes. The contract for QA: all repo-health scripts that gate normal development must still exit 0 after the rename, AND there must be no remaining bare references to the old skill names.

## Regression Test Cases

| # | Test Case | Steps | Expected Result | Status |
|---|-----------|-------|-----------------|--------|
| 1 | `validate.sh` exits 0 | `cd $REPO && ./scripts/validate.sh; echo "exit=$?"` | `exit=0`. All 10+ error checks pass. MIRROR_SPECS check 10 (byte-identity between `deprecated/CJ_company-workflow/` and `work-copilot/`) is green. | Pending |
| 2 | `test.sh` full suite exits 0 | `cd $REPO && ./scripts/test.sh; echo "exit=$?"` | `exit=0`. Includes `test-deploy.sh` against renamed skills. | Pending |
| 3 | `generate-readme.sh` regenerates README.md cleanly | `cd $REPO && ./scripts/generate-readme.sh && git diff README.md` | README.md regenerates without error. Diff shows new `CJ_*` names; no leftover unprefixed references. | Pending |
| 4 | `skills-deploy install` succeeds end-to-end | `cd $REPO && ./scripts/skills-deploy install` | All 8 renamed skills install to `~/.claude/skills/CJ_*/`. Templates deploy to `~/.claude/templates/CJ_personal-workflow/`. Manifest at `~/.claude/.skills-templates.json` lists all 8 with new names. | Pending |
| 5 | `skills-deploy doctor` reports zero orphans / zero drift | `cd $REPO && ./scripts/skills-deploy doctor` | Zero orphans (no leftover unprefixed dirs from prior install). Zero drift between source and deployed copies. | Pending |
| 6 | Catalog cross-references resolve | `cd $REPO && jq '.[].depends.skills[]' skills-catalog.json \| sort -u` then check each value matches a `name:` field in the catalog | Every `depends.skills[]` entry matches exactly one catalog `name`. No dangling references to old unprefixed names. | Pending |
| 7 | No bare references to old skill names in repo source | `grep -rE '\b(system-health\|personal-workflow\|scaffold-work-item\|implement-from-spec\|qa-work-item\|personal-pipeline\|suggest\|company-workflow)\b' --include='*.md' --include='*.json' --include='*.sh' --include='*.py' CLAUDE.md README.md scripts/ skills/ deprecated/ templates/ work-copilot/ \| grep -v 'CJ_' \| grep -vE '(CHANGELOG\|work-items/\|\.gstack/)' \| wc -l` | `0`. Allowed exceptions: CHANGELOG entries documenting the rename, history under `work-items/`, and `.gstack/` design docs. | Pending |
| 8 | Slash-command names work post-deploy | After `skills-deploy install`, in a fresh Claude Code session: invoke `/CJ_personal-workflow check`. | Skill loads and runs `check` successfully. Old slash-command form (`/personal-workflow`) is no longer registered. | Pending |
| 9 | Per-skill version bumps applied | `git diff main -- skills-catalog.json` shows `version` bumped for all 8 entries (major bump per breaking-change convention). | Each of the 8 catalog entries shows a major version increment. Collection VERSION also bumped per convention (e.g., 1.15.x → 1.16.0 minor or 2.0.0 major depending on policy). | Pending |
| 10 | Self-rename of `personal-workflow` doesn't break Phase 3 boundary check | After rename + redeploy, run `/CJ_personal-workflow check work-items/tasks/skills/T000018_rename_user-authored_skills_to_cj_prefix/` | Exit 0. Validates the renamed skill can validate its own work-item. | Pending |

## Verification Steps

<!-- How was the fix verified beyond the test cases above? -->

- [ ] Local `./scripts/validate.sh` succeeds (exit 0)
- [ ] Local `./scripts/test.sh` succeeds (exit 0, full suite including test-deploy.sh)
- [ ] `./scripts/skills-deploy install` followed by `./scripts/skills-deploy doctor` reports clean
- [ ] `./scripts/generate-readme.sh` regenerates README.md with no leftover unprefixed names (verified via grep)
- [ ] CI run on PR is green (full GitHub Actions matrix)
- [ ] Manual: invoke `/CJ_personal-workflow check` against the scaffold T000018 dir; confirms self-validation works post-rename
- [ ] Manual: confirm `/CJ_personal-pipeline` slash command appears in the available-skills list after redeploy

## Environments Tested

| Environment | Build | Result |
|------------|-------|--------|
| macOS Darwin 25.3.0 (local dev) | claude/naughty-antonelli-5f2565 | Pending |
| GitHub Actions CI (Ubuntu) | PR build | Pending |
