---
name: "refine spec/test-spec-custom.md: replace the inline check/unit lists in the verification-surface-grouped-by-layer section with per-group tables briefly explaining each check/unit"
type: task
id: "T000049"
status: active
created: "2026-06-13"
updated: "2026-06-13"
parent: ""
repo: "/Users/chjiang/Documents/projects/claude-skills-templates/.claude/worktrees/cool-lichterman-cbb4b0"
branch: "claude/cool-lichterman-cbb4b0"
blocked_by: ""
---

<!-- Prerequisite (optional): If this task came from /office-hours, distill the
     design context into the ## Insights section below. Otherwise (per the
     skip-design-for-small-todos convention in WORKFLOW.md), proceed without
     a separate DESIGN.md — the parent user-story's DESIGN already covers it. -->

## Lifecycle

### Phase 1: Track

1. Read parent tracker to understand scope and acceptance criteria
2. Create working branch: `git checkout -b feat/refine_spec_test_spec_custom_md_replace`
   (use parent's branch if the task ships in the same PR; create a new branch if it warrants its own PR)
3. Scaffold required docs:
   - `test-plan.md` (test scenarios for this task) — from `templates/doc-test-plan.md`
4. Populate Files section with expected changed files
5. Write initial Todos from parent's acceptance criteria

**Gates:**
- [x] Parent scope read (parent tracker reviewed)
- [x] Working branch created (`branch` field populated)
- [x] Required docs scaffolded (test-plan)
- [x] Files section populated

### Phase 2: Implement

1. Work from `/office-hours` design doc + parent's acceptance criteria + your Todos
   → design doc at `~/.gstack/projects/refine_spec_test_spec_custom_md_replace/`
2. Commit changes incrementally with descriptive messages
3. Update Todos section — check off completed items, add discoveries
4. Update Files section with actual changed files

**Gates:**
- [ ] Core changes committed (>=1 commit SHA in Log)
- [x] Todos section reflects remaining work (no stale items)
- [x] Files section updated with changed files

### Phase 3: Ship

1. Run `/CJ_personal-workflow check` — verify no regressions
2. Verify test-plan: all test scenarios passing
3. Run `/ship` — creates PR, bumps version, updates changelog (includes pre-landing code review)
4. Run `/land-and-deploy` — merges PR and verifies deployment

❌ If tests fail: fix, re-run
❌ If CI fails: fix, push, re-run `/ship`

**Gates:**
- [ ] `/CJ_personal-workflow check` — validation passed
- [ ] Test-plan verified (all scenarios passing)
- [ ] `/ship` — PR created
- [ ] `/land-and-deploy` — merged and deployed

## Todos

<!-- Actionable items for this task. Not lifecycle duplicates — these are
     the actual things to build, fix, or investigate. -->

- [x] Implement: refine spec/test-spec-custom.md: replace the inline check/unit lists in the verification-surface-grouped-by-layer section with per-group tables briefly explaining each check/unit

## Log

<!-- Chronological entries with dates and commit SHAs. Each entry records
     what happened, not what should happen. -->

- 2026-06-13: Created. Auto-scaffolded by /CJ_goal_task from topic: refine spec/test-spec-custom.md: replace the inline check/unit lists in the verification-surface-grouped-by-layer section with per-group tables briefly explaining each check/unit
- 2026-06-13: Rendered the verification-surface section as per-group tables; QA green (smoke; Step 8.6 doc+test audits 0 findings, faithfulness cross-walk clean). Squashed to one `v6.0.74` commit; STOPPED at the PR.

## PRs

<!-- PR links with status (open/merged/closed). -->

- [#272](https://github.com/jcl2018/claude-skills-templates/pull/272) — open (v6.0.74) — render the verification-surface section as per-group tables.

## Files

<!-- Affected file paths. Populated during Track phase, updated during Implement. -->

- `spec/test-spec-custom.md` (modified) — replaced the inline comma-separated check/unit lists in the `## The verification surface, grouped by layer` section (the `ci`, `local-hook`, and `Ratchets` subsections) with per-group `Check / Unit` ⇄ `What it asserts` markdown tables rendered from the `units:`/`ratchet:` registry rows. The `pipeline-gate` gates table and the `units:`/`gates:` registry fence are untouched.

## Insights

<!-- Auto-injected from the /CJ_goal_task topic -->

Scope (from /CJ_goal_task topic): refine spec/test-spec-custom.md: replace the inline check/unit lists in the verification-surface-grouped-by-layer section with per-group tables briefly explaining each check/unit


<!-- Non-obvious findings worth remembering. Things that surprised you,
     patterns discovered, or context that future readers will need. -->

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

<!-- Source: /CJ_goal_task: refine spec/test-spec-custom.md: replace the inline check/unit lists in the verification-surface-grouped-by-layer section with per-group tables briefly explaining each check/unit -->

- 2026-06-13 [impl-decision] Rendered each group's table from the `units:` registry rows (label → `Check / Unit`; ≤12-word condensation of `purpose` → `What it asserts`) rather than inventing copy, per the task's data-source constraint. Left the `### Handled by pipeline-gate` gates table exactly as-is and added no second yaml fence.
- 2026-06-13 [impl-finding] Cross-checked completeness against `scripts/test-spec.sh --list-units` (66 rows): validate=25 (error 12 + warning 2 + numbered 10 + portability-audit 1), test=33 (registered 17 + inline 16), test-deploy/eval/windows-smoke=3, ci=3, hook=2. Every unit row appears exactly once across the group tables; none dropped or duplicated. Ratchets table = the four `ratchet: true` rows (Error check 8, Check 14, Check 18, portability-audit engine).
- 2026-06-13 [impl] Modified 1 file (spec/test-spec-custom.md): replaced the inline lists in the ci / local-hook / Ratchets subsections with per-group tables.
- 2026-06-13 [impl-auto] Auto-mode run; --auto allowed (1 file touched, non-sensitive surface, trivial).
- 2026-06-13 [impl-pass] T000049: implementation complete. Phase 2 implementer-owned gates transitioned. Verified: --validate OK, --check-coverage findings=0, validate.sh RESULT: PASS (Check 24 green), exactly 1 yaml fence.
- 2026-06-13 [qa-smoke] S1 (acceptance-bar): green — `test-spec.sh --validate` → `OK schema_version=1` (exit 0).
- 2026-06-13 [qa-smoke] S2 (acceptance-bar): green — `test-spec.sh --check-coverage` → `OK coverage rows=66 findings=0` (exit 0).
- 2026-06-13 [qa-smoke] S3 (acceptance-bar): green — `validate.sh` → `RESULT: PASS` (0 errors, 0 warnings; Check 24 green).
- 2026-06-13 [qa-smoke] S4 (acceptance-bar): green — `grep -c '^\`\`\`yaml' spec/test-spec-custom.md` → 1 (exactly one yaml fence retained).
- 2026-06-13 [qa-smoke] S5 (acceptance-bar): green — completeness: `--list-units` = 66 rows; family split validate=25, test=33, ci=3, hook=2, standalone(test-deploy/eval/windows-smoke)=3 — matches the expected 66, every family unit appears once across the group tables.
- 2026-06-13 [qa-smoke-summary] green: 5/5 non-manual rows green (0 manual rows pending). Test-plan row #1 (free-form prose) superseded by the 5 concrete acceptance-bar smoke checks.
- 2026-06-13 [qa-audit] AUDITS=doc:ok,test:ok,spec_updates:test-spec-custom:none,doc-spec-custom:none (Step 8.6a-d; findings ride the green RESULT — checkpoint decision belongs to the orchestrator). Faithfulness cross-walk: all 66 registry units appear once across the group tables (4 ratchet rows deliberately echoed in the Ratchets table = 70 table rows); every "What it asserts" cell is a faithful condensation of its registry `purpose` (no invention, no contradiction).
- 2026-06-13 [qa-pass] T000049 (task): green smoke from acceptance-bar rows (5 rows). No qa-owned Phase 2 gates per template; Phase 3 `Test-plan verified` gate awaits /ship-time inference.
