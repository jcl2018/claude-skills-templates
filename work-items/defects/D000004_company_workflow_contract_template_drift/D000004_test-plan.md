---
type: test-plan
parent: D000004
title: "company-workflow contract/template drift (workflow_type, section order) — Regression Test Plan"
date: 2026-04-16
author: chjiang
status: Draft
---

## Scope

Validates the Issue 1 and Issue 3 fixes in `skills/company-workflow/`, plus whatever drift-detection mechanism is chosen in Phase 1 of the fix.

Files in scope:
- `skills/company-workflow/contract.json` (frontmatter required/recommended; sections optional + expected_order + order_skip_absent + type_specific_optional)
- `skills/company-workflow/SKILL.md` line 126 (validator field list reference)
- `templates/company-workflow/tracker-{feature,user-story,defect}.md` (no edits expected; the contract is what changes)
- `templates/company-workflow/tracker-{task,review}.md` (must remain unaffected)
- Per Phase 1 choice: one or more of `scripts/test-roundtrip.sh`, `scripts/lib-validate.sh`, pre-rendered fixtures, pre-commit hook, or `--self-test` skill subcommand

Out of scope:
- Issue 2 fix (manifest split + feature-summary.md template) — ships under D000003.

## Regression Test Cases

### Pre-fix baseline (current state — should be RED)

| # | Test Case | Steps | Expected Result | Status |
|---|-----------|-------|-----------------|--------|
| 1 | **Pre-fix:** scaffolded company feature/story tracker FAILS section-order check | Scaffold feature tracker from current template; run `/company-workflow validate <file>` | Violation: section order — `Acceptance Criteria` not in expected order | Pending |
| 2 | **Pre-fix:** scaffolded company defect tracker section-order behavior is undefined | Scaffold defect tracker from current template; run `/company-workflow validate <file>` | Either passes (accidental) or fails (depending on validator's strictness for unknown sections) | Pending |

### Post-fix expected behavior

| # | Test Case | Steps | Expected Result | Status |
|---|-----------|-------|-----------------|--------|
| 3 | **Issue 1:** scaffolded feature passes frontmatter validation | Scaffold a feature tracker; run `/company-workflow validate <file>` | Validator reports OK; `workflow_type` and `url` recognized | Pending |
| 4 | **Issue 1:** tracker missing `workflow_type` (if required by pre-step) is rejected | Remove `workflow_type:` line from a scaffolded tracker; re-run validator | Violation, naming `workflow_type` | Pending |
| 5 | **Issue 1:** tracker missing `url` is accepted (recommended-only) | Remove `url:` line from a scaffolded tracker; re-run validator | OK — `url` is recommended, not required | Pending |
| 6 | **Issue 1:** validator field list comes from contract | Grep `SKILL.md` for hardcoded company-specific field names | No hardcoded list; reads from `contract.json` | Pending |
| 7 | **Issue 3:** scaffolded feature tracker passes section-order check | Scaffold a feature tracker; run `/company-workflow validate <file>` | OK — `Acceptance Criteria` between `Lifecycle` and `Todos` is accepted | Pending |
| 8 | **Issue 3:** scaffolded user-story tracker passes section-order check | Scaffold a user-story tracker; run `/company-workflow validate <file>` | OK | Pending |
| 9 | **Issue 3:** scaffolded defect tracker passes section-order check | Scaffold a defect tracker; run `/company-workflow validate <file>` | OK — `Reproduction Steps` between `Lifecycle` and `Todos` is accepted | Pending |
| 10 | **Issue 3:** trackers without the optional section still pass | Remove the optional section from a scaffolded tracker; re-run validator | OK — section is optional | Pending |
| 11 | **Issue 3:** misordered sections still rejected | Move `Lifecycle` to the bottom of a scaffolded tracker; re-run validator | Violation: section-order rule still enforces canonical order | Pending |
| 12 | **Unaffected templates:** `tracker-task.md` round-trip clean | Scaffold task; run validator | OK (no Acceptance Criteria, no Reproduction Steps emitted; type_specific_optional has empty array for task) | Pending |
| 13 | **Unaffected templates:** `tracker-review.md` round-trip clean | Scaffold review; run validator | OK (same as task) | Pending |

### Per-Phase-1-choice tests (depends on architectural decision)

These vary by which mechanism is chosen. The test plan will be re-finalized once Phase 1 lands.

| # | If Phase 1 chooses... | Tests required |
|---|----------------------|----------------|
| 14a | A (subset-validator-in-bash) | Self-tests S1 (DRIFT detection via fixture skill) + S2 (TEMPLATE_BUG via malformed template fixture) per the original /plan-eng-review test plan. Plus regressions R1 (personal-workflow CLEAN) + R2 (company-workflow CLEAN after this defect's fix). |
| 14b | B (pre-rendered fixtures + git-diff) | Commit one fixture per (skill, type). Test: re-scaffold from template, diff against committed fixture, expect zero diff. Test: edit a template, expect non-zero diff. |
| 14c | C (drop the runner; lint only) | Test: lint catches `Acceptance Criteria` in template when contract doesn't allow it. Test: lint catches `workflow_type` in template when contract doesn't list it. |
| 14d | D (self-test inside SKILL) | Manual: invoke `/personal-workflow check --self-test`, expect zero violations. Same for company-workflow. No CI gate. |
| 14e | E (shared bash library) | All of A's tests, plus: confirm SKILL.md actually consumes the lib (smoke test by editing the lib and seeing both validators behave consistently). |

### Cross-skill regression (always required)

| # | Test Case | Steps | Expected Result | Status |
|---|-----------|-------|-----------------|--------|
| 15 | personal-workflow unaffected | `/personal-workflow check work-items/` | Same pass/fail count as before fix | Pending |
| 16 | `./scripts/validate.sh` exits 0 | run script | Exit 0 | Pending |
| 17 | `./scripts/test.sh` exits 0 | run script | Exit 0 (with whatever new tests Phase 1 adds) | Pending |

### Post-deploy verification

| # | Test Case | Steps | Expected Result | Status |
|---|-----------|-------|-----------------|--------|
| 18 | Legacy ai-content trackers tolerated | After fix deployed: `/company-workflow validate ai-content/work-items/F973012/` | No false-positive violations on `workflow_type` or `url` (per grandfather policy) | Pending |
| 19 | Fresh ai-content tracker scaffolded post-deploy passes | Scaffold a new tracker in ai-content; run validator | OK | Pending |

## Verification Steps

- [ ] Phase 1 architectural choice decided (A/B/C/D/E)
- [ ] `./scripts/validate.sh` exits 0
- [ ] `./scripts/test.sh` exits 0 (with whatever Phase 1 adds)
- [ ] `/personal-workflow check work-items/` shows no new violations
- [ ] All Phase 2 contract edits land per RCA's Fix Description
- [ ] Manual reproduction of Issues 1 and 3 confirms each is gone
- [ ] CHANGELOG entry written
- [ ] Skill version bumped per `scripts/collection-version.sh`
- [ ] Verified `~/.claude/skills/company-workflow/` post-deploy matches repo state
- [ ] Post-deploy: `/company-workflow validate ai-content/work-items/F973012/` produces no false positives

## Environments Tested

| Environment | Build | Result |
|-------------|-------|--------|
| macOS Darwin 25.3.0 — workbench repo | branch `claude/nostalgic-volhard` | Pending |
| macOS Darwin 25.3.0 — ai-content consumer repo | master @ post-fix deploy | Pending |
