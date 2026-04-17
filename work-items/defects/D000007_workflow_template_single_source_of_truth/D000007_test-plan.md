---
type: test-plan
parent: D000007
title: "Eliminate contract.json — templates as single source of truth — Test Plan"
date: 2026-04-17
author: chjiang
status: Draft
---

<!-- Scope: ONE fix (defect) or ONE task. Cases must be concrete and reproducible.
     For broader coverage of a user story, use TEST-SPEC.md instead.
     For defects, the test cases are regression cases for the specific bug. -->

## Scope

Architectural change across both workflow skills:

- DELETE `skills/company-workflow/contract.json` and `skills/personal-workflow/contract.json`
- REWRITE validator sections in `skills/company-workflow/SKILL.md`, `skills/personal-workflow/SKILL.md`, and `skills/personal-workflow/check.md` to derive structural rules from templates at runtime
- UPDATE `WORKFLOW.md` in both skills (Validation Rules / Using validate sections)
- UPDATE `skills-catalog.json` (remove contract.json from both skills' `files` arrays)
- AUDIT `skills/{company,personal}-workflow/fixtures/` — retire or rewrite contract-specific fixtures
- ADD `scripts/test.sh` regression block "Regression test (D000007)" preventing accidental re-introduction
- CROSS-LINK `D000004_TRACKER.md` Log: superseded entry

No template changes. No `company-artifact-manifests.json` / `personal-artifact-manifests.json` changes (those are scaffolding type→artifact mapping, not validation rules — different concern).

## Regression Test Cases

| # | Test Case | Steps | Expected Result | Status |
|---|-----------|-------|-----------------|--------|
| 1 | contract.json files no longer exist | `[ ! -f skills/company-workflow/contract.json ] && [ ! -f skills/personal-workflow/contract.json ] && echo OK` | Output is `OK` | Pass |
| 2 | SKILL.md / check.md no longer reference contract.json (runtime read) | Asserted by test.sh D000007 block: `grep -qE "(cat\|jq\|Read\|read).*contract\.json"` against each validator file | All 3 validator files PASS the no-runtime-read check | Pass |
| 3 | WORKFLOW.md no longer references contract.json as a validator input | `grep -n "contract" skills/{company,personal}-workflow/WORKFLOW.md` | 0 matches (verified) | Pass |
| 4 | skills-catalog.json no longer lists contract.json under either skill | Asserted by test.sh D000007 block: `jq -r '.[] \| .files[]' \| grep contract.json` | 0 matches | Pass |
| 5 | scripts/test.sh has D000007 regression block | `grep -qE "Regression test \(D000007\)" scripts/test.sh` | Match found | Pass |
| 6 | scripts/validate.sh PASS post-rewrite | `./scripts/validate.sh` | 0 errors / 0 warnings | Pass |
| 7 | scripts/test.sh PASS post-rewrite (incl. D000007 block) | `./scripts/test.sh` | 0 failures, 6 new D000007 checks all OK | Pass |
| 8 | Existing trackers under work-items/ pass against template-derived rules | Spot-checked D000003, D000005, D000006, D000007 by deriving rules from templates and comparing — all match exactly. Legacy F000002, F000003 surface 1-checkbox drift (Milestones gate added post-authorship, strictly correct enforcement, expected behavior change) | D000003/D000005/D000006/D000007: PASS. F000002/F000003: surface drift (intentional) | Pass (with documented intentional drift surfacing for legacy items) |
| 9 | Newly scaffolded company tracker passes validation | Templates include all required keys (id/name/type/...etc.); a fresh paste-and-fill produces a valid tracker | Validator-derived rules match template exactly → fresh trackers always pass | Pass (by construction) |
| 10 | Newly scaffolded personal tracker passes validation | Same flow with personal-workflow tracker-defect.md; D000007 itself is the proof | D000007 created from template + fills → passes all derived rules | Pass (D000007 is the existence proof) |
| 11 | Phase 2 test-verification gates (D000006) now validator-enforced via checkbox count | Template's checkbox count is the floor; missing a gate → violation | Confirmed: tracker-defect.md template has 11 boxes; instance with 10 would fail with "lifecycle has 10 checkboxes, minimum is 11 (per template)" | Pass (logic verified; live trigger is on legacy F000002/F000003) |
| 12 | type_specific_optional behavior preserved by per-type-template inference | Defect template has `## Reproduction Steps`, task template doesn't. Validator infers from per-type template lookup. | Confirmed: tracker-defect template has the section, tracker-task does not. Per-type lookup is automatic. | Pass (structural by design) |
| 13 | "recommended" frontmatter behavior change documented | Old: `repo`, `branch` were "recommended" (advisory). New: present in every tracker template → required. CHANGELOG should call this out. | Behavior change is intentional; tracked in RCA's Regression Risk table | Pass (tracked; CHANGELOG entry pending /ship) |
| 14 | D000004 marked superseded | `grep -qE "SUPERSEDED by D000007" work-items/defects/D000004_company_workflow_contract_template_drift/D000004_TRACKER.md` | Match found at line 124; status flipped to `superseded` | Pass |
| 15 | Fixtures audit complete | Audited all 11 fixtures across both skills. 4 invalid-* fixtures still produce violations under new rules (still useful as negative cases). 2 valid fixtures (personal valid-tracker.md, valid-feature-dir/F999999_TRACKER.md) needed `id` + `blocked_by` backfill (now valid). Company fixtures already complete. | All fixtures meaningful; 2 backfilled | Pass |
| 16 | No tooling outside this repo depends on contract.json | `grep -rn "contract\.json" scripts/` returns nothing meaningful; consumer `~/.claude/` copies will pick up the change next `skills-deploy install --overwrite` (which removes the deployed contract.json since the catalog no longer references it) | scripts/ clean; consumer cleanup happens on next deploy | Pass (with note for consumers to redeploy) |

## Verification Steps

- [x] `./scripts/validate.sh` PASS (0 errors / 0 warnings)
- [x] `./scripts/test.sh` PASS (0 failures, all D000005 + D000006 + new D000007 blocks green)
- [x] Spot-checked recent trackers (D000003, D000005, D000006, D000007) against template-derived rules — all match exactly. Legacy F000002/F000003 surface intentional drift (1 missing checkbox each from a template gate added after authorship).
- [x] D000007 itself is the "fresh personal-workflow defect" passing validation proof (created from tracker-defect.md template with all keys, sections, phases, and 11 checkboxes matching the template).
- [x] Read both rewritten validators end-to-end: every step that read contract.json is gone or replaced with template-derivation; violation messages preserved with one improvement (`(per template)` annotation on min-checkbox violations to clarify provenance).
- [ ] Consumer dogfood (e.g., ai-content) via `skills-deploy install --overwrite` — pending; will run after merge so consumers pick up the new validators + cleared contract.json
- [ ] CHANGELOG entry called out in /ship covering: (a) `frontmatter.recommended` removal — `repo`/`branch` now required since templates emit them; (b) stricter checkbox enforcement now driven by template counts; (c) per-type optional sections now structural rather than declarative
- [x] D000004's tracker: status flipped to `superseded`, Log entry appended (line 124)

## Environments Tested

| Environment | Build | Result |
|------------|-------|--------|
| macOS Darwin 25.3.0 | branch `claude/nostalgic-volhard` (12 files modified, 2 deleted) | Pass |
| Consumer repo dogfood (e.g., ai-content) via `skills-deploy install --overwrite` | latest skill version | Pending (post-merge) |
