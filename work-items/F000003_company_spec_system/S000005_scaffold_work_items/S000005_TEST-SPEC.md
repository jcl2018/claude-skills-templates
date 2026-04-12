---
type: test-spec
parent: S000005_scaffold_work_items
feature: F000003_company_spec_system
title: "Scaffold Company Work Items — Test Specification"
version: 1
status: Draft
date: 2026-04-12
author: chjiang
prd: S000005_PRD.md
architecture: S000005_ARCHITECTURE.md
reviewers: []
---

## Test Matrix

| # | Tag | Test Case | AC | Precondition | Steps | Expected Result | Priority | Type |
|---|-----|-----------|-----|-------------|-------|-----------------|----------|------|
| 1 | core | Scaffold feature creates 5 artifacts | AC-1 | Templates exist | Run create --type feature | Directory with tracker + PRD + ARCH + TEST-SPEC + milestones | P0 | E2E |
| 2 | core | Scaffold defect creates 3 artifacts | AC-1 | Templates exist | Run create --type defect | Directory with tracker + RCA + test-plan | P0 | E2E |
| 3 | core | Scaffold task creates 2 artifacts | AC-1 | Templates exist | Run create --type task --parent ID | Directory with tracker + test-plan | P0 | E2E |
| 4 | core | Scaffold userstory creates 5 artifacts | AC-1 | Templates exist | Run create --type userstory | Directory with tracker + PRD + ARCH + TEST-SPEC + milestones | P0 | E2E |
| 5 | core | Scaffold review creates 2 artifacts | AC-1 | Templates exist | Run create --type review | Directory with tracker + review-notes | P0 | E2E |
| 6 | core | Placeholders filled correctly | AC-6 | Feature scaffolded | Read tracker frontmatter | name, id, date, branch, repo all filled | P0 | E2E |
| 7 | resilience | Scaffolded tracker passes validation | AC-7 | Feature scaffolded | Run company-workflow validate | Exit 0 | P0 | E2E |
| 8 | resilience | Existing templates untouched after scaffold | — | SHA256 recorded | Scaffold, recompute checksums | Identical | P0 | E2E |

## Test Tiers

### Tier 1: Smoke Tests (automated, no live execution)

| # | Tag | Check | What It Validates | Script/Command |
|---|-----|-------|-------------------|---------------|
| S1 | core | SKILL.md has create subcommand | Subcommand documented | `grep -q 'create' skills/company-workflow/SKILL.md` |
| S2 | core | Artifact mapping covers 5 types | All types have entries | Grep for feature, defect, task, userstory, review in artifact mapping section |

### Tier 2: E2E Tests (real end-to-end execution)

Each test scaffolds a complete work item with realistic input, then validates output.
(Moved from S000003 TEST-SPEC — these tests require scaffolding capability.)

| # | Tag | Scenario | Steps (as a real user would) | Expected Outcome | Rubric |
|---|-----|----------|----------------------------|-----------------|--------|
| E1 | core | Scaffold a feature: "Design a Google Search clone" | Invoke company skill with `--type feature --name "google-search-clone"`. Skill reads templates/company-workflow/tracker-feature.md, scaffolds tracker + PRD + ARCHITECTURE + TEST-SPEC + milestones. | work-items/F{next}_google_search_clone/ contains: TRACKER.md (11 frontmatter fields, 4-phase lifecycle with sub-gates), PRD (problem statement filled, user stories table), ARCHITECTURE (overview filled), TEST-SPEC (test matrix), milestones (dependency graph). | Pass: `company-workflow validate` exit 0 on tracker. All 5 artifacts exist. Frontmatter `workflow_type: feature` and `url:` present. Lifecycle has "Feature scoped", "Doc triplet created", "Linux branch build passes" checkboxes. Fail: missing artifact, missing field, wrong lifecycle. |
| E2 | core | Scaffold a defect: "Login page returns 500 on expired session token" | Invoke company skill with `--type defect --name "login-500-expired-token"`. Skill reads tracker-defect.md, scaffolds tracker + RCA + test-plan. | work-items/D{next}_login_500_expired_token/ contains: TRACKER.md (11 fields, defect lifecycle), RCA (symptom section filled), test-plan (regression case). | Pass: `company-workflow validate` exit 0. Tracker has "Root cause identified", "Hypothesis tested with evidence", "Regression test added" in Phase 2. RCA has Symptom, Reproduction Steps, Root Cause sections. Fail: missing RCA, missing defect-specific checkboxes. |
| E3 | core | Scaffold a task: "Migrate user table to new schema" | Invoke company skill with `--type task --name "migrate-user-table" --parent S000003`. Skill reads tracker-task.md, scaffolds tracker + test-plan. | work-items/.../T{next}_migrate_user_table/ contains: TRACKER.md (12 fields including parent=S000003), test-plan. | Pass: `company-workflow validate` exit 0. Tracker has `parent: "S000003"` in frontmatter. Phase 1 has "Scope understood from parent work item". Fail: missing parent, missing test-plan. |
| E4 | core | Scaffold a user story: "As a seller, I want to list products with images" | Invoke company skill with `--type userstory --name "seller-product-listing"`. Skill reads tracker-user-story.md, scaffolds tracker + PRD + ARCHITECTURE + TEST-SPEC + milestones. | work-items/.../S{next}_seller_product_listing/ contains: TRACKER.md (11 fields, `type: userstory`), PRD, ARCHITECTURE, TEST-SPEC, milestones. | Pass: `company-workflow validate` exit 0. Tracker has `type: userstory` (no hyphen), `workflow_type: userstory`. Fail: type spelled `user-story`, missing doc triplet. |
| E5 | core | Scaffold a review: "Q2 security audit code review" | Invoke company skill with `--type review --name "q2-security-audit"`. Skill reads tracker-review.md, scaffolds tracker + review-notes. | work-items/.../R{next}_q2_security_audit/ contains: TRACKER.md (12 fields including `deadline`), review-notes (10 fields including `reviewer`, `verdict`). | Pass: `company-workflow validate` exit 0. Tracker has `deadline:` field, Meetings section, Handoff section (9 sections total). Fail: missing deadline, missing Meetings/Handoff, missing review-notes. |
| E6 | resilience | Scaffold feature, then verify no existing files touched | Before: record SHA256 of all templates/*.md. Scaffold "Design a YouTube recommendation engine" as feature. After: recompute SHA256. | SHA256 checksums identical before and after. validate.sh exits 0. | Pass: every checksum matches. Fail: any checksum differs. |
| E7 | core | Validate a deliberately invalid work item | Create a tracker missing `workflow_type` and `url`, with sections out of order. Run `company-workflow validate`. | Exit code 1. stderr lists: missing `workflow_type`, missing `url`, section order violation. | Pass: exit 1, all 3 violations named. Fail: exit 0, or missing violation in output. |
| E8 | core | Scaffold all 5 types in sequence, validate all | Scaffold feature "Build a Spotify playlist engine", defect "Playback stutters on low bandwidth", task "Add retry logic to streaming endpoint", userstory "As a listener I want offline mode", review "Streaming reliability code review". Validate each. | 5 work items created, each with correct artifacts per type. All 5 pass validation. | Pass: 5x exit 0. Correct artifact counts: feature=5, defect=3, task=2, userstory=5, review=2. Fail: any validation failure or missing artifact. |

## Coverage Gaps

| Gap | Why Not Tested | Risk Accepted |
|-----|---------------|---------------|
| Concurrent scaffolding | Single-user repo | Low: no shared state |
| ID collision across types | Prefixes are unique (F/D/T/S/R) | Low: scan is type-prefixed |
| Scaffolding in foreign repo | Blocked on T000003 (skills-deploy subfolder patch) | Med: test when T000003 lands |
