---
name: "CJ_portability-audit SKILL.md advisory rationale is stale: it says the audit is advisory because the workbench has real declared-vs-actual mismatches, but the catalog is clean (FINDINGS=0) and F000051 made it a hard gate on the cj_goal path"
type: defect
id: "D000033"
status: active
created: "2026-06-07"
updated: "2026-06-07"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "cj-def-20260606-200132-51066"
blocked_by: ""
auto_scaffolded: true
promoted_from_draft: .inbox/cj_portability_audit_skill_md_advisory_rationale_i
---

## Lifecycle

### Phase 1: Track

1. Reproduction documented (see Reproduction Steps + the bug report)
2. Working branch created: cj-def-20260606-200132-51066
3. Required docs scaffolded (D000033 RCA + test-plan)
4. /investigate populated the root cause (Iron-Law gate passed)

**Gates:**
- [x] Reproduction steps documented
- [x] Working branch created (branch field populated)
- [x] Required docs scaffolded (RCA + test-plan)
- [x] Root cause identified (or best hypothesis logged)

### Phase 2: Implement

1. /investigate Phase 4 wrote the fix directly to source
2. Regression guard: validate.sh Check 14 + Check 18 + cj-portability-audit.sh
3. Fix + work-item artifacts committed (Step 7.6, before QA)
4. RCA updated with the final root cause

**Gates:**
- [x] Fix committed
- [x] RCA doc updated
- [x] Todos section reflects remaining work (no stale items)

### Phase 3: Ship

1. /CJ_qa-work-item — verify the test-plan rows (Step 8)
2. /CJ_document-release — doc-sync (Step 5.5)
3. /ship — open the fix PR (Step 9)
4. /land-and-deploy — merge + verify (Step 10)

**Gates:**
- [ ] /CJ_personal-workflow check — validation passed
- [ ] Test-plan verified (regression scenarios passing)
- [ ] /ship — PR created
- [ ] /land-and-deploy — merged and deployed

## Reproduction Steps

CJ_portability-audit SKILL.md advisory rationale is stale: it says the audit is advisory because the workbench has real declared-vs-actual mismatches, but the catalog is clean (FINDINGS=0) and F000051 made it a hard gate on the cj_goal path

## Todos

- [ ] Ship via /ship (Gate #2 human diff review)
- [ ] Land via /land-and-deploy

## Log

- 2026-06-07: Promoted from draft .inbox/cj_portability_audit_skill_md_advisory_rationale_i after /investigate populated the root cause. Domain defaulted to 'uncategorized'.

## PRs

<!-- PR links populated at /ship. -->

## Files

<!-- Affected files are listed in the RCA Affected Components table. -->

## Insights

<!-- Root cause + patterns discovered; see the D000033 RCA. -->

## Journal
- 2026-06-07T03:08:55Z [auto-scaffolded] /CJ_goal_defect captured the bug as draft .inbox/cj_portability_audit_skill_md_advisory_rationale_i, then promoted to D000033 after /investigate populated the root cause.
- 2026-06-06 [qa-smoke] 1 (stale-phrase-removed): green — `grep "HAS real declared-vs-actual" skills/CJ_portability-audit/SKILL.md` no match (exit 1).
- 2026-06-06 [qa-smoke] 2 (catalog-clean): green — `scripts/cj-portability-audit.sh` → FINDINGS=0, SKILLS_AUDITED=12, RESULT: OK (advisory), exit 0.
- 2026-06-06 [qa-smoke] 3 (usage-drift-check14): green — `scripts/validate.sh` Check 14 PASS (CJ_portability-audit USAGE.md current); 0 errors.
- 2026-06-06 [qa-smoke] 4 (portability-check18): green — `scripts/validate.sh` Check 18 PASS (portability audit clean, 0 findings; advisory posture intact, exit 0).
- 2026-06-06 [qa-smoke-summary] green: 4/4 non-manual rows green (0 manual rows pending).
- 2026-06-06 [qa-pass] D000033 (defect): green smoke from test-plan rows (4 rows). No qa-owned Phase 2 gates per template; Phase 3 `Test-plan verified` gate awaits /ship-time inference.
