---
name: "jq CRLF output breaks the spec engines on Windows Git Bash: workbench scripts consume $(jq -r ...) without stripping CR, so with a Windows jq build that emits CRLF, workflow-spec.sh registry-completeness reads CJ_goal_todo_fix\r and false-halts [workflow-spec-no-config], cascading into test-spec.sh --validate / --list-units and validate.sh Checks 24/26/27/28 — validate red blocks every commit via the pre-commit hook"
type: defect
id: "D000038"
status: active
created: "2026-07-02"
updated: "2026-07-02"
repo: "E:/projects/claude-skills-templates"
branch: "cj-def-20260701-173850-2847"
blocked_by: ""
auto_scaffolded: true
promoted_from_draft: .inbox/jq_crlf_output_breaks_the_spec_engines_on_windows
---

## Lifecycle

### Phase 1: Track

1. Reproduction documented (see Reproduction Steps + the bug report)
2. Working branch created: cj-def-20260701-173850-2847
3. Required docs scaffolded (D000038 RCA + test-plan — written at Step 7.5)
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

On Windows Git Bash with a CRLF-emitting jq build (jq 1.7.1 at ~/bin/jq, first in PATH):
1. `bash scripts/workflow-spec.sh --list-orchestrators` → `[workflow-spec-no-config] registry-completeness (no-vanish): routable CJ_goal_* skill 'CJ_goal_todo_fix' has NO entry` (rc=1) even though the section exists at spec/workflow-spec.md:386.
2. CRLF proof: `jq -r '.[].name' skills-catalog.json | od -c` shows \r\n line endings.
3. Cascade: `bash scripts/test-spec.sh --validate` → [test-spec-no-config]; `bash scripts/validate.sh` → Checks 24/26/27/28 red → pre-commit hook blocks every commit.

## Todos

- [ ] Ship via /ship (Gate #2 human diff review)
- [ ] Land via /land-and-deploy

## Log

- 2026-07-02: Promoted from draft .inbox/jq_crlf_output_breaks_the_spec_engines_on_windows after /investigate populated the root cause. Domain defaulted to 'uncategorized'; relocate to a more specific subdir if needed.

## PRs

<!-- PR links populated at /ship. -->

## Files

<!-- Affected files are listed in the RCA Affected Components table. -->

## Insights

<!-- Root cause + patterns discovered; see the D000038 RCA. -->

## Journal
- 2026-07-02T01:15:37Z [auto-scaffolded] /CJ_goal_defect captured the bug as draft .inbox/jq_crlf_output_breaks_the_spec_engines_on_windows, then promoted to D000038 after /investigate populated the root cause. Domain defaulted to 'uncategorized'.
- 2026-07-01 [qa-smoke] R1 (T7 CRLF drill): green — `bash tests/workflow-spec-render.test.sh` RESULT: PASS incl. both T7 OK lines (--list-orchestrators CR-free rc=0, no [workflow-spec-no-config]; --validate rc=0)
- 2026-07-01 [qa-smoke] R2 (live engine): green — `bash scripts/workflow-spec.sh --list-orchestrators` printed the 4 CJ_goal_* orchestrator names, rc=0 on the affected Windows machine (real CRLF jq first in PATH)
- 2026-07-01 [qa-smoke] R3 (cascade repaired): green — `bash scripts/test-spec.sh --validate` OK schema_version=1; `bash scripts/validate.sh` Checks 24 (coverage rows=82 findings=0) / 26 / 27 / 28 all PASS, Errors: 0, Warnings: 0, RESULT: PASS, rc=0
- 2026-07-01 [qa-smoke-summary] green: 3/3 non-manual rows green (0 manual rows pending) — test-plan rows run as smoke-equivalent (defect type dispatch) at commit 7a58439
- 2026-07-01 [qa-audit] AUDITS=deferred,spec_updates:test-spec-custom:none,doc-spec-custom:none (Step 8.6a/8.6b ran inline — T7 extends the already-registered suite tests/workflow-spec-render.test.sh (units row test-workflow-spec-render unchanged); no new docs; 8.6c/8.6d DEFERRED via DEFER_AUDIT — orchestrator runs the post-sync audit)
- 2026-07-01 [qa-pass] D000038 (defect): green smoke from test-plan rows (3 rows). No qa-owned Phase 2 gates per template; Phase 3 `Test-plan verified` gate awaits /ship-time inference.
