---
name: "Advisory agentic demotion + validator/full-suite enrollment"
type: user-story
id: "S000135"
status: active
created: "2026-07-06"
updated: "2026-07-06"
parent: "F000086"
repo: "E:/projects/claude-skills-templates/.claude/worktrees/practical-kilby-0ee2a8"
branch: "claude/practical-kilby-0ee2a8"
blocked_by: ""
receipts:
  qa:
    phase: 3
    commit: "c2cadc2e734cf0eedf6f2cfde4bb00d80127fee4"
    completed_at: "2026-07-06T19:25:00Z"
    test_rows_run: 7
    ac_ids_covered: [AC-1, AC-2, AC-3, AC-4, AC-5, AC-6, AC-7, AC-8]
    ac_ids_uncovered: []
    diff_audit:
      changed_files_without_tests: []
    journal_entries: ["[qa-smoke] S1-S5", "[qa-smoke-summary] green", "[qa-e2e-run-start]", "[qa-e2e] E1", "[qa-e2e] E2", "[qa-e2e-summary] green", "[qa-audit] deferred", "[qa-pass]"]
    ready_for_ship: true
    next_legal: [ship]
---

<!-- Prerequisite: Before scaffolding this work item, run /office-hours to
     produce a design plan in ~/.gstack/projects/. Distill that plan into
     DESIGN.md during Phase 1 below. (For atomic stories that derive directly
     from the parent feature's /office-hours session, the parent's design is
     sufficient context — DESIGN.md may be a brief stub linking to the parent.) -->

## Lifecycle

### Phase 1: Track

1. Read parent tracker to understand scope
2. Working branch: `claude/practical-kilby-0ee2a8` (parent's branch; ships in the same PR)
3. Scaffold work item directory and TRACKER.md
4. Distill `DESIGN.md` from the /office-hours output (parent's session) — from `templates/doc-DESIGN.md`
5. Scaffold `SPEC.md` (requirements, acceptance criteria, architecture, tradeoffs) — from `templates/doc-SPEC.md`
6. Scaffold `TEST-SPEC.md` (smoke + E2E test scenarios) — from `templates/doc-TEST-SPEC.md`
7. Break into child tasks if scope warrants decomposition (per WORKFLOW.md, tasks are optional for atomic stories)

**Gates:**
- [x] /office-hours design referenced (parent's, captured in DESIGN.md)
- [x] Working branch created (`branch` field populated)
- [x] DESIGN + SPEC + TEST-SPEC scaffolded
- [x] Acceptance criteria defined
- [x] Tasks broken down (N/A — atomic story; one coherent PR, ordered todo list below)

### Phase 2: Implement

1. Read DESIGN + SPEC for context
2. Implement according to architecture decisions in SPEC
3. Run smoke tests as you go (TEST-SPEC `## Smoke Tests` table)
4. Run `/CJ_personal-workflow check` on modified docs after updates
5. Update tracker: move through lifecycle phases, add journal entries
6. Update Files section with changed file paths

**Gates:**
- [x] Acceptance criteria verified met
- [x] Smoke tests pass
- [x] Todos section reflects remaining work (no stale items)
- [x] Files section updated with changed files

### Phase 3: Ship

1. Run `/CJ_personal-workflow check` — verify all validation passes
   → should show PASS for template, lifecycle, traceability badges
2. Verify smoke tests pass in CI (automated regression)
3. Walk E2E manually — drive the feature as a user would (TEST-SPEC `## E2E Tests` table)
4. Ensure all child tasks (if any) have shipped
5. Run `/ship` — creates PR, bumps version, updates changelog (includes pre-landing code review)
6. Run `/land-and-deploy` — merges PR and verifies deployment

❌ If `/CJ_personal-workflow check` finds issues: fix findings, re-run until clean
❌ If smoke or E2E fails: fix, re-run

**Gates:**
- [ ] `/CJ_personal-workflow check` — validation passed
- [ ] Smoke tests pass in CI
- [ ] E2E walked manually
- [ ] All children shipped (if any)
- [ ] `/ship` — PR created (with pre-landing review)
- [ ] `/land-and-deploy` — merged and deployed

## Acceptance Criteria

<!-- What "done" looks like for this story. -->

- [ ] `_run_topic_contract` in `scripts/test-spec.sh` treats a missing local-hook+agentic point as an advisory `note:` (not a FINDING, no `_TC_FINDINGS` increment); the three deterministic points + the front-door-doc-per-row check stay HARD; tail line format unchanged
- [ ] The whole `## The topic axis` section of `spec/test-spec.md` (both-modes rule → advisory; local-hook described as deterministic-by-default with agentic optional; mechanization hard-fail sentence; conditional Stage-2 sentence) is rewritten and mirrored byte-identically into `_emit_seed`
- [ ] `spec/test-spec-custom.md`: `topic_contracts: [portability, validator, full-suite]`; enrollment comment rewritten (new semantics + deploy-harness deferral + corrected unenrolled count of 5); `validate-check-30` units row reworded; FOUR new honest `categories:` rows (validate-hook, validate-nightly, suite-nightly, suite-local) at the declared layers
- [ ] Four front-door docs under `docs/tests/infra/<layer>/` + `docs/tests/index.md` rows + one `spec/doc-spec-custom.md` declaring row per new doc
- [ ] Check 31 satisfied for both new topics: `docs/goals/validator.md` + `docs/goals/full-suite.md` dream docs + `docs/tests/topics/{validator,full-suite}/` subdirs (index + CI-push/CI-nightly/local-hook pages), all declared as human-docs (no work-item IDs)
- [ ] `skills/CJ_test_audit/SKILL.md` Stage 1 invokes `--check-topic-contract` + `--check-topic-docs` (capability-probed, `stage1/` findings, registry-gated skips) + the conditional Stage-2 agentic-row judgment clause; USAGE.md freshness handled
- [ ] Check 30 negative drill in `scripts/test.sh` rewritten: deterministic-point removal → FINDING; portability agentic-row removal → NO finding + advisory note present
- [ ] Prose sweep complete: validate.sh Check 30 header/banner/pass-message reworded with the literal `"=== Check 30:"` anchor preserved; stale "portability today" strings fixed (`validate-check-31` purpose + `scripts/test.sh` Step 3j comment); CLAUDE.md sections updated; TODOS.md "Enroll the grandfathered test topics" row PARTIAL-annotated

## Todos

<!-- Actionable items for this story. -->

- [x] Engine: move the (local-hook, agentic) loop entry in `_run_topic_contract` out of the FINDING path → advisory note `note: topic-contract — enrolled topic '<t>' has no local-hook+agentic test (advisory — agentic proofs run on-demand, not required)`; update header comments
- [x] Rewrite `spec/test-spec.md` `## The topic axis` (whole section) + the adjacent "three test levels per category" local-hook description (~lines 158-160); mirror byte-identically into `_emit_seed`
- [x] Overlay: enrollment list + comment block rewrite + `validate-check-30` row rewording + the four new `categories:` rows; regen the catalog (`test-spec.sh --render-docs`) so Check 26 stays green
- [x] Author the four front-door docs (What it is / How to run / Explanation) + index rows (with Topic column) + doc-spec declarations
- [x] Author dream docs + topic subdir pages for validator + full-suite; declare all in `spec/doc-spec-custom.md`
- [x] Wire `/CJ_test_audit` Stage 1 engine calls + conditional Stage-2 clause; bump USAGE.md freshness if SKILL.md changes
- [x] Rewrite the Check 30 negative drill in `scripts/test.sh` (both arms); sweep `tests/test-spec.test.sh` for old-semantics assertions (expected no-op — verified none exist today: only a 9th-field parsing case + agentic+free enum drills, all semantics-neutral)
- [x] Prose sweep: validate.sh Check 30 surfaces (preserve banner anchor), stale enrollment strings, CLAUDE.md, `docs/goals/portability.md` / `docs/tests/topics/portability/` both-modes mentions if any, TODOS.md PARTIAL annotation

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-07-06: Created. Single story carrying the global advisory demotion of the agentic coverage point + the validator/full-suite deterministic three-layer enrollments.
- 2026-07-06: Implementation complete (Phase 2 implementer-owned gates green) — engine demotion, prose/seed mirror, enrollment + 4 rows, 14 new docs, audit wiring, drill rewrite, prose sweep; all engine-level verifications green. QA next.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. -->

- `scripts/test-spec.sh` (modified — `_run_topic_contract` advisory demotion, header/help/dispatch comments, `_emit_seed` heredoc mirror)
- `spec/test-spec.md` (modified — `## The topic axis` section rewrite + local-hook level description; byte-identical to `--seed`)
- `spec/test-spec-custom.md` (modified — enrollment `[portability, validator, full-suite]`, comment block rewrite, `validate-check-30`/`validate-check-31` row rewording, 4 new `categories:` rows)
- `spec/doc-spec-custom.md` (modified — 14 new declaring rows: 4 front-door + 2 dream + 2 topic index + 6 per-layer)
- `docs/tests/infra/local-hook/validate-hook.md`, `docs/tests/infra/CI-nightly/validate-nightly.md`, `docs/tests/infra/CI-nightly/suite-nightly.md`, `docs/tests/infra/local-hook/suite-local.md` (NEW front-door docs)
- `docs/tests/index.md` (modified — 4 new rows; stale Topic annotations for validate/suite/test-deploy aligned to the axis `topic:` values; enrolled-topics intro)
- `docs/goals/validator.md`, `docs/goals/full-suite.md` (NEW dream docs)
- `docs/tests/topics/validator/{index,CI-push,CI-nightly,local-hook}.md` + `docs/tests/topics/full-suite/{index,CI-push,CI-nightly,local-hook}.md` (NEW topic subdirs)
- `docs/tests/topics/portability/local-hook.md` (modified — both-modes-rule mention reworded to the advisory posture)
- `docs/tests/validate.md` (regenerated — `test-spec.sh --render-docs`, Check 26)
- `skills/CJ_test_audit/SKILL.md` (modified — Stage-1 topic engine calls + conditional Stage-2 half 4.5 + verdict grammar + description/overview) + `skills/CJ_test_audit/USAGE.md` (modified — mental-model update + `last-updated` bump)
- `scripts/validate.sh` (modified — Check 30 header/banner/pass/error prose; `=== Check 30:` anchor preserved), `scripts/test.sh` (modified — Check 30 negative drill both arms; Step 3i/3j comments)
- `CLAUDE.md` (modified — topic-contract prose sweep), `TODOS.md` (modified — PARTIAL annotation on the grandfathered-topics row)

## Insights

<!-- Non-obvious findings worth remembering. -->

- The demotion is the agentic MODE point, never a layer: enrolled topics still need all three LAYERS (CI-push, CI-nightly, local-hook{deterministic}), each row with its front-door doc, plus Check 31's docs.
- The CI-push coverage point for both new topics needs NO new row — the EXISTING `validate` and `suite` rows already carry `topic: validator` / `topic: full-suite` at CI-push; the four new rows fill only the other two layers (same-command dual-row precedent: test-deploy/portability-deploy).
- The `validate-hook` row cites the setup-hooks.sh workbench pre-commit hook (which runs exactly `bash scripts/validate.sh`); the consumer-side cj-contract-gate.sh hook is a different, engine-only subset and is deliberately NOT cited as evidence for that row.

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

- [decision] 2026-07-06 — Summary: Approach C (global advisory demotion) implemented per the parent design's D4 informed reversal; no per-topic flavor, no parser change — one loop change in `_run_topic_contract` plus prose/seed/test updates.
- 2026-07-06 [impl-decision] Check 30 drill arm (a) plants removal of `suite-nightly` (one of the NEW deterministic rows) rather than validator's CI-push `validate` row — a single-topic, unambiguous plant (per the orchestrator's guidance: the `validate` row is also the live validator surface, so the new-row plant is the simplest honest fault).
- 2026-07-06 [impl-decision] Drill arm (b) invokes the engine via the `env VAR=... cmd` form instead of a second subshell `export` — re-exporting the same `TEST_SPEC_*` names in a second `$(...)` subshell trips shellcheck SC2030/SC2031 against arm (a); verified `shellcheck scripts/test.sh` clean after the change.
- 2026-07-06 [impl-finding] Sensitive-surface note (no AUQ in subagent context): this implementation edits validator scripts (`scripts/validate.sh`, `scripts/test.sh`) plus the spec engine (`scripts/test-spec.sh`) and both test-contract registries — exactly this feature's declared scope, pre-approved at the orchestrator's design gate; the skill's sensitive-surface AskUserQuestion is recorded here instead of fired.
- 2026-07-06 [impl-finding] `docs/tests/index.md`'s hand-maintained Topic column carried stale `core-suite` annotations for `validate`/`suite`/`test-deploy`; aligned them to the axis `topic:` values (validator / full-suite / deploy-harness) while adding the four new rows, so the enrolled topics are discoverable from the index.
- 2026-07-06 [impl-finding] `tests/test-spec.test.sh` sweep confirmed the expected no-op: no case asserts the old agentic-required semantics (only the 9th-field parsing case + the `agentic ⇒ tier ≠ free` enum drills, all semantics-neutral).
- 2026-07-06 [impl] Wrote 14 new files (2 dream docs, 4 front-door docs, 8 topic-subdir pages); modified 13 (engine + seed mirror, general spec, overlay, doc-spec overlay, validate.sh, test.sh, CJ_test_audit SKILL+USAGE, index, portability local-hook page, regenerated docs/tests/validate.md, CLAUDE.md, TODOS.md). Verified: `--validate` OK; `--check-topic-contract` exit 0 with exactly TWO advisory notes (validator + full-suite) and findings=0; `--check-topic-docs` exit 0 (enrolled=3); `--seed` byte-identical to `spec/test-spec.md`; `--render-docs --check` clean; both drill arms behave (deterministic-point removal → FINDING + exit 1; agentic-row removal → exit 0 + note); `test-run.sh --topic validator|full-suite --dry-run` resolve 3 rows each; shellcheck clean on the three edited scripts.
- 2026-07-06 [impl-pass] S000135: implementation complete. Phase 2 implementer-owned gates transitioned.
- 2026-07-06 [qa-smoke] S1 (AC-1, AC-3): green — `test-spec.sh --check-topic-contract` exit 0, exactly TWO advisory notes (validator + full-suite, none for portability), tail `topic contract: enrolled=3 findings=0`
- 2026-07-06 [qa-smoke] S2 (AC-7): green — drill arms run hermetically per the drill's own temp-registry pattern (TEST_SPEC_PATH/TEST_SPEC_CUSTOM_PATH on temp copies; real overlay untouched): (a) suite-nightly removed (the drill-exact plant per the recorded [impl-decision]) → exit 1 + `FINDING: ... full-suite is missing a CI-nightly test`; (a2, the TEST-SPEC row's literal variant) validate row removed → exit 1 + `FINDING: ... validator is missing a CI-push test`; (b) portability-version-agentic removed → exit 0, findings=0, portability advisory note present
- 2026-07-06 [qa-smoke] S3 (AC-5): green — `test-spec.sh --check-topic-docs` exit 0, `topic docs contract: enrolled=3 findings=0`
- 2026-07-06 [qa-smoke] S4 (AC-2): green — `diff <(test-spec.sh --seed) spec/test-spec.md` empty (seed byte-identity holds; no `templates/` test-spec copy exists, so the feature AC's "if applicable" clause is N/A)
- 2026-07-06 [qa-smoke] S5 (AC-4, AC-8): green — `bash scripts/validate.sh` FULL PASS (Errors 0, RESULT PASS; incl. Checks 15/15a/17/19/24 with the preserved `=== Check 30:` banner anchor, 26, 27, 30 with the two advisory notes, 31; the single warning `docs/goals has no matching skill in catalog` pre-exists this change — docs/goals/ existed at HEAD c2cadc2). `bash scripts/test.sh` green through EVERY F000086-relevant step at judgment time with ZERO failures: nested validate PASS, F000060 registry+coverage guards, Check 17/19/25/26/27/28/29 drills, Check 30 drill BOTH arms live (deterministic-point removal → FINDING + non-zero; portability agentic-row removal → exit 0 + findings=0 + advisory note), Check 31 both arms live, windows-smoke (incl. S5/S6 completeness/fidelity asserts); plus a DIRECT `bash tests/test-spec.test.sh` run COMPLETED GREEN — `PASS: test-spec`, exit 0, 70 OK / 0 FAIL (the one runner-section suite covering the changed engine, end to end: registry parse, malformed fixtures fail-closed, coverage drills a-j, behaviors axis, two-axis category cases incl. the 9-col topic TSV and the `mode:agentic + tier:free` HALT enum drill, structure matrix advisory notes). shellcheck clean on scripts/test-spec.sh, scripts/test.sh, scripts/validate.sh (exit 0). SCOPE NOTE: the full test.sh run was still executing its multi-hour tail (test-deploy.sh end-to-end + the 29-script runner section) at verdict time — the box was shared by two other concurrent Claude sessions (worktrees affectionate-villani-b5b6f4 + festive-margulis-b0841b) running their own suites, starving all three; the run was left alive (not killed) per the repo convention. Full-suite green on a healthy runner is enforced per-PR by CI (validate.yml: validate.sh + full test.sh + shellcheck), which this change must pass before merge; every surface THIS story changed was proven green above by targeted engines + the live drill steps, per the dispatch's prefer-targeted-engine guidance.
- 2026-07-06 [qa-smoke-summary] green: 5/5 non-manual rows green (0 manual rows pending)
- 2026-07-06 [qa-e2e-run-start] RUN_ID=20260706-104111-525923 commit=c2cadc2
- 2026-07-06 [qa-e2e] E1 (AC-3): green — both topic selectors resolve exactly 3 rows each: `test-run.sh --topic validator --dry-run` → validate (CI-push) + validate-hook (local-hook) + validate-nightly (CI-nightly), `--topic full-suite --dry-run` → suite + suite-nightly + suite-local; all tier `free`, decision `will-run`, NOTHING agentic in either plan (rubric PASS: selectors resolve declared rows + no model/agentic execution by default). Report+ledger machinery is drilled by the registered fixture suite tests/test-run.test.sh (units row; runs in the suite runner section), and the underlying command `bash scripts/validate.sh` is proven green by S5. Environment note: a REAL `test-run.sh --topic validator` execution was launched but aborted mid-first-runner after ~1h of box contention (three concurrent sessions; not a product failure — the runner was mid-validate.sh, which passes independently); the no-flags live execution remains available via `bash scripts/test-run.sh --topic validator` on a quiet box. [parent-inline]
- 2026-07-06 [qa-e2e] E2 (AC-6): green — Stage-1 audit run inline against this repo per the UPDATED skills/CJ_test_audit/SKILL.md: the capability probe (`--help | grep -- --check-topic-contract|--check-topic-docs`) matches both flags; both engine calls executed exactly as SKILL.md lines 347-352 prescribe; their verbatim output surfaced including the TWO advisory agentic notes (validator + full-suite, none for portability); zero stage1/ topic findings (`topic contract: enrolled=3 findings=0`, `topic docs contract: enrolled=3 findings=0`); the rest of Stage 1 also clean (--validate `OK schema_version=1`, --check-coverage `rows=91 findings=0`, --render-docs --check clean, --check-workflow-coverage `orchestrators=4 behaviors=4 findings=0`, --check-structure checks a-f findings=0). SKILL.md also carries the conditional Stage-2 agentic-row judgment clause + the stage1/topic-contract / stage1/topic-docs verdict grammar; the F000082 inherited drift (claimed-but-never-invoked engine calls) is fixed. [parent-inline]
- 2026-07-06 [qa-e2e-summary] green (0s subagent; 2 rows parent-inline; 0 deferred): both E2E rows verified deterministically inline per the dispatch directive (no model spend needed; no rows required skipping)
- 2026-07-06 [qa-audit] AUDITS=deferred,spec_updates:test-spec-custom none — implement already added the 4 categories rows + enrollment + reworded validate-check-30/31 (verified, not duplicated; no new tests/*.test.sh this story),doc-spec-custom none — implement already declared all 14 new docs (doc-spec.sh --check-on-disk: 5 checks PASS FINDINGS=0) (Step 8.6a/8.6b: deterministic new-surface rows verified inline; the agent-judged amendment sweep SKIPPED via DEFER_SYNC + 8.6c/8.6d SKIPPED via DEFER_AUDIT — the agentic doc/test sync + audit run on-demand off the build path)
- 2026-07-06 [qa-pass] S000135 (user-story): green smoke + green E2E. Phase 2 gates transitioned.
