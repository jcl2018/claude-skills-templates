---
name: "test-spec.sh reverse-sweep per-namespace floors misfire in non-workbench consumer repos"
type: defect
id: "D000035"
status: active
created: "2026-06-15"
updated: "2026-06-15"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "claude/dazzling-jemison-feb6e8"
blocked_by: ""
auto_scaffolded: true
promoted_from_draft: .inbox/test_spec_sh_reverse_sweep_per_namespace_floors_mi
---

## Lifecycle

### Phase 1: Track

1. Reproduction documented (see Reproduction Steps + the bug report)
2. Working branch created: claude/dazzling-jemison-feb6e8
3. Required docs scaffolded (D000035 RCA + test-plan)
4. /investigate populated the root cause (Iron-Law gate passed)

**Gates:**
- [x] Reproduction steps documented
- [x] Working branch created (branch field populated)
- [x] Required docs scaffolded (RCA + test-plan)
- [x] Root cause identified (or best hypothesis logged)

### Phase 2: Implement

1. /investigate Phase 4 wrote the fix directly to source
2. Regression test added covering the defect scenario
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

test-spec.sh reverse-sweep per-namespace floors misfire in non-workbench consumer repos

## Todos

- [ ] Ship via /ship (Gate #2 human diff review)
- [ ] Land via /land-and-deploy

## Log

- 2026-06-15: Promoted from draft .inbox/test_spec_sh_reverse_sweep_per_namespace_floors_mi after /investigate populated the root cause. Domain defaulted to 'uncategorized'.

## PRs

<!-- PR links populated at /ship. -->

## Files

<!-- Affected files are listed in the RCA Affected Components table. -->

## Insights

<!-- Root cause + patterns discovered; see the D000035 RCA. -->

## Journal
- 2026-06-15T16:54:49Z [auto-scaffolded] /CJ_goal_defect captured the bug as draft .inbox/test_spec_sh_reverse_sweep_per_namespace_floors_mi, then promoted to D000035 after /investigate populated the root cause.
- 2026-06-15 [qa-smoke] 1 (regression cases a/b/c): green — `bash tests/test-spec.test.sh` printed "PASS: test-spec", exit 0; covers test-plan rows 1-3 (consumer-surface no-misfire, present-but-zero-token namespace still-fires, rules-only unchanged).
- 2026-06-15 [qa-smoke] 4 (workbench coverage): green — `bash scripts/test-spec.sh --check-coverage` printed "OK coverage rows=69 reverse_tokens=49 findings=0", exit 0; no workbench regression.
- 2026-06-15 [qa-smoke-summary] green: 2/2 non-manual rows green (0 manual rows pending)
- 2026-06-15 [qa-audit] AUDITS=deferred,spec_updates:test-spec-custom:none,doc-spec-custom:none (Step 8.6a/8.6b ran inline; 8.6c/8.6d DEFERRED via DEFER_AUDIT — orchestrator runs the post-sync audit)
- 2026-06-15 [qa-pass] D000035 (defect): green smoke from test-plan rows (2 rows). No qa-owned Phase 2 gates per template; Phase 3 `Test-plan verified` gate awaits /ship-time inference.
- 2026-06-15 [gate-strengthen] At the Gate #2 review, an adversarial verification (4 lenses) confirmed the fix solid on 3 lenses but found a MEDIUM residual: path-existence gating alone still false-fires for a consumer with a reserved-path file in non-workbench grammar (husky scripts/setup-hooks.sh / own scripts/validate.sh) — the defect's own title scope. Operator chose "strengthen now". Composed path-presence with family-row-presence (a namespace counts as present only when the registry declares rows in its family). Closes the residual without weakening the workbench. Added regression case (d). Re-verifying QA + post-sync audit on the strengthened fix.
