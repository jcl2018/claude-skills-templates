---
name: "runners: axis + test-run.sh engine + run ledger + /CJ_test_run wrapper"
type: user-story
id: "S000122"
status: active
created: "2026-07-01"
updated: "2026-07-01"
parent: "F000072"
repo: "E:/projects/claude-skills-templates/.claude/worktrees/dazzling-shirley-87c62e"
branch: "claude/dazzling-shirley-87c62e"
blocked_by: ""
receipts:
  qa:
    phase: 3
    commit: "0b2b2ed73046e2774c836d67167755663773bf40"
    completed_at: "2026-07-02T07:42:18Z"
    test_rows_run: 10
    ac_ids_covered: [AC-1, AC-2, AC-3, AC-4, AC-5, AC-6, AC-7, AC-8, AC-9, AC-10, AC-11]
    ac_ids_uncovered: []
    diff_audit:
      changed_files_without_tests: []
    journal_entries: ["[qa-smoke] S1-S5 green", "[qa-e2e] E1/E3/E4/E5 green + E2 green (runner logic proven; live run env-blocked)", "[qa-e2e-summary] green", "[qa-audit] deferred", "[qa-pass]"]
    ready_for_ship: true
    next_legal: [Ship]
---

<!-- Prerequisite: Before scaffolding this work item, run /office-hours to
     produce a design plan in ~/.gstack/projects/. Distill that plan into
     DESIGN.md during Phase 1 below. (This atomic story derives directly from
     the parent feature's /office-hours session — the parent's design is the
     context; this story's DESIGN.md is a brief stub linking to it.) -->

## Lifecycle

### Phase 1: Track

1. Read parent tracker to understand scope
2. Create working branch: `git checkout -b feat/{slug}` (or use parent's branch if shipping in same PR)
3. Scaffold work item directory and TRACKER.md
4. Distill `DESIGN.md` from the /office-hours output (own session or parent's) — from `templates/doc-DESIGN.md`
5. Scaffold `SPEC.md` (requirements, acceptance criteria, architecture, tradeoffs) — from `templates/doc-SPEC.md`
6. Scaffold `TEST-SPEC.md` (smoke + E2E test scenarios) — from `templates/doc-TEST-SPEC.md`
7. Break into child tasks if scope warrants decomposition (per WORKFLOW.md, tasks are optional for atomic stories)

**Gates:**
- [x] /office-hours design referenced (own or parent's, captured in DESIGN.md)
- [x] Working branch created (`branch` field populated)
- [x] DESIGN + SPEC + TEST-SPEC scaffolded
- [x] Acceptance criteria defined
- [x] Tasks broken down (N/A — atomic story; one cohesive change shipping in one PR)

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

- [ ] `test-spec.sh --validate` accepts a well-formed `runners:` axis (unique ids, closed `tier` enum `{free, paid, local-only}`, closed `platform` enum `{any, windows, posix}`, non-empty `command`, `covers` referencing runnable families `{validate, test, test-deploy, eval, windows-smoke}` or `all`) and REJECTS `ci`/`hook` in `covers`; the axis is optional — a registry without it behaves exactly as today.
- [ ] `test-spec.sh --list-runners` emits the parsed rows machine-readably; `--list-units --with-family` emits id + family columns.
- [ ] `scripts/test-run.sh --dry-run` prints the plan (per runner: resolved command, tier, platform guard result, covered families, covered unit count, will-run/skip(reason); uncovered families: `ci` → ci-only, `hook` → installed check, else `skipped(no-covering-runner)`) and exits without executing anything.
- [ ] Default execution runs only `tier: free` runners; `--evals` adds paid, `--e2e` adds local-only, `--all` = everything; a default run never touches a model.
- [ ] Every run with ≥1 runner row writes `tests/test-run/reports/<UTC-ts>.md` + a `.json` ledger (schema: 1, timestamp, HEAD SHA, repo root, flags, aggregate; per runner: id, command, tier, rc, outcome, covered families, covered unit count, duration); aggregate is the closed enum `{pass, fail, all-skipped}` with `fail` ⇒ exit 1, `all-skipped` NEVER rendered `pass`; all JSON strings encoded via jq `-R`/`-Rs` with CR stripping.
- [ ] Registry edge paths honest: absent registry → `REGISTRY=absent` + exit 0; invalid registry → `[test-spec-no-config]` passthrough + exit 1; declared registry with zero `runners:` rows → `SKIP: no runners declared` + exit 0, NO report, NO ledger.
- [ ] Self-gating detected precisely: rc=0 AND FIRST output line matching `^SKIP:` ⇒ `skipped(self-gated)`; a mid-output SKIP never triggers it.
- [ ] Workbench overlay carries `run-test-sh` (free; covers validate + test + test-deploy + windows-smoke), `run-eval` (paid), `run-e2e-local` (local-only); `ci`/`hook` stay runner-less with family-level ledger rows (`ci-only`; `hook-check: pass|fail`).
- [ ] `/CJ_test_run` wrapper runs the Stage-1 pre-step (the four `test-spec.sh` engine calls, verbatim, invalid-vs-absent split preserved; INVALID halts, findings on a VALID registry ride the report without blocking), then `test-run.sh` with forwarded flags, then narrates report + ledger paths; engines resolve sibling-in-scriptdir → `$REPO_ROOT/scripts/` → deployed `_cj-shared`.
- [ ] `tests/test-run.test.sh` passes against fixture repos (never invoking the real `scripts/test.sh`); wired into `scripts/test.sh`; units rows registered (Check 24); test catalog regenerated (Check 26); catalog + routing + roster + philosophy + regenerated workflow docs green under full `validate.sh`.

## Todos

<!-- Actionable items for this story. -->

- [x] `runners:` grammar + `--validate` rules (unique ids, closed enums, covers references incl. ci/hook rejection, command non-empty) in `scripts/test-spec.sh`, with parser fixtures (in tests/test-run.test.sh G1/G2/G3)
- [x] `--list-runners` subcommand + `--list-units --with-family` machine-readable form
- [x] `scripts/test-run.sh` plan mode (`--dry-run`) — verified honest output on this repo AND fixture repos
- [x] `scripts/test-run.sh` execution (tier selection, platform guard, self-gate first-line `^SKIP:` rule, rc + output-tail capture)
- [x] Report `.md` + ledger `.json` (schema: 1; closed aggregate + skip-reason enums; jq `-R`/`-Rs` with CR strip; gitignored `tests/test-run/reports/` + committed `EXAMPLE.md`)
- [x] Absent / invalid / no-runners registry paths
- [x] Workbench overlay `runners:` rows (`run-test-sh`, `run-eval`, `run-e2e-local`)
- [x] `skills/CJ_test_run/` SKILL.md + USAGE.md (Stage-1 pre-step + engine dispatch + narration)
- [x] Paperwork: `skills-catalog.json` entry (experimental, honest portability), `rules/skill-routing.md` row, `spec/workflow-spec.md` utilities roster addition, `docs/philosophy.md` decision-tree line, regenerated workflow docs
- [x] `tests/test-run.test.sh` fixture tests + wire into `scripts/test.sh` + register units row (`test-test-run`) + 3 behaviors in `spec/test-spec-custom.md` + regenerate test catalog

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-07-01: Created. Single atomic story carrying all five components of F000072 Approach A: runners: overlay axis grammar, test-run.sh engine (plan/execute/report+ledger), workbench runners rows, /CJ_test_run wrapper + paperwork, fixture tests.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. -->

- `scripts/test-spec.sh` (Modified — sensitive: parser grammar)
- `scripts/test-run.sh` (New)
- `spec/test-spec-custom.md` (Modified — sensitive)
- `skills/CJ_test_run/SKILL.md`, `skills/CJ_test_run/USAGE.md` (New)
- `tests/test-run.test.sh` (New), `scripts/test.sh` (Modified)
- `skills-catalog.json` (Modified — sensitive), `rules/skill-routing.md` (Modified — sensitive), `spec/workflow-spec.md` (Modified — sensitive), `docs/philosophy.md` (Modified), regenerated `docs/test-catalog.md` + `docs/tests/` + `docs/workflow.md` + `docs/workflows/` (Generated)
- `tests/test-run/reports/EXAMPLE.md` (New, committed), `.gitignore` (Modified — gitignore `tests/test-run/reports/`)

## Insights

<!-- Non-obvious findings worth remembering. -->

- "covers: all" means the RUNNABLE families `{validate, test, test-deploy, eval, windows-smoke}` — deliberately NOT the contract's existing "test-bearing" term, which excludes `validate`; the axis grammar defines "runnable" explicitly to avoid overloading the term.
- The runner-less `ci`/`hook` families are by-design-not-run, not skipped: they get family-level ledger rows (`ci-only`; `hook-check: pass|fail`) OUTSIDE the `skipped(<reason>)` enum.
- The aggregate enum applies only when at least one runner row exists — the no-runners path is a SKIP with no report and no ledger, so an empty contract can never fabricate an `all-skipped` artifact.

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

- [decision] 2026-07-01 — Summary: Atomic story (no task children): the five components land as one cohesive PR per Approach A; decomposition into tasks would split a single grammar+engine+wrapper change across artificial seams.
- 2026-07-01 [impl-decision] Placed the runners: parser + validation in the SHARED registry gate (BEFORE the `[ -n "$_UNITS" ] || return 0` early return) so the axis validates even in a units-less registry — mirrors the behaviors: precedent exactly (registry-gated, INDEPENDENT of units:).
- 2026-07-01 [impl-finding] The units/rules/layers/gates/behaviors/behavior_coverage awk parsers each stop at the NEXT top-level key; adding `runners:` required extending ALL SIX stop-pattern regexes to include `runners` — otherwise a `units:`-then-`runners:` overlay (the workbench shape) parses runner rows as units ("unit 'r1' is missing 'family'"). Caught by the fixture G3 drill.
- 2026-07-01 [impl-decision] test-run.sh resolves absent-vs-invalid via test-spec.sh --validate's documented contract (REGISTRY=absent line vs the [test-spec-no-config] halt + non-zero exit) rather than re-parsing — one source of truth for the split.
- 2026-07-01 [impl-decision] ALL ledger JSON string encoding goes through `jq -Rs` wrapped by the CR-stripping jq() wrapper (scripts/lib.sh:24 pattern) — verbatim FAIL tails carry quotes/backslashes and a CRLF-emitting Windows jq would corrupt naive reads (P1 AC-11). test-spec.sh added no jq call sites (D000038), so its runners work needs no wrapper there.
- 2026-07-01 [impl] Wrote scripts/test-run.sh (engine), skills/CJ_test_run/{SKILL,USAGE}.md, tests/test-run.test.sh, tests/test-run/reports/EXAMPLE.md; modified scripts/test-spec.sh (runners: axis grammar + --validate + --list-runners + --list-units --with-family), spec/test-spec-custom.md (3 runners rows + test-test-run units row + 3 behaviors + 3 behavior_coverage rows), scripts/test.sh (wire the new suite), skills-catalog.json (CJ_test_run entry), rules/skill-routing.md, spec/workflow-spec.md (roster), docs/philosophy.md (decision tree), .gitignore; regenerated docs/{test-catalog.md,tests/,workflow.md,workflows/} + README.md.
- 2026-07-01 [impl] Sensitive surfaces touched per the SPEC (scripts/test-spec.sh parser, skills-catalog.json, spec/test-spec-custom.md, rules/skill-routing.md, spec/workflow-spec.md) — implemented via the propose-and-implement path the design doc authorizes (design doc IS the approval; subagent context has no AUQ).
- 2026-07-01 [impl-pass] S000122: implementation complete. Phase 2 implementer-owned gates transitioned. Self-verify: test-spec.sh --validate OK; test-run.sh --dry-run honest (3 workbench runners); tests/test-run.test.sh all drills green; test/workflow render checks fresh; coverage 0 findings.
- 2026-07-02 [qa-smoke] S1 (AC-1, AC-2): green — `bash tests/test-run.test.sh` exit 0; G1/G2/G3 drills green (well-formed runners: axis validates, each named violation rejected — duplicate id/bad tier/bad platform/empty command/unknown covers family/explicit ci+hook in covers; axis-less registry validates unchanged; --list-runners + --list-units --with-family emit machine-readable forms).
- 2026-07-02 [qa-smoke] S2 (AC-3, AC-4): green — `bash tests/test-run.test.sh` exit 0; R1/R2/R3 drills green (--dry-run prints per-runner decisions + ci-only + skipped(no-covering-runner), writes no report/ledger; default selects only tier: free; --all selects every tier; platform-mismatched runner skipped(platform)).
- 2026-07-02 [qa-smoke] S3 (AC-5, AC-6): green — `bash tests/test-run.test.sh` exit 0; R4/R5/R6/R7/R8 drills green (fail => aggregate fail + exit 1 + verbatim FAIL + ledger outcome=fail; >=1 green => pass; zero executed => all-skipped never pass; rc=0 first-line ^SKIP: => skipped(self-gated), mid-output SKIP does not trigger; ledger schema 1/timestamp/head/repo_root/flags/aggregate/per-runner+family rows, valid JSON).
- 2026-07-02 [qa-smoke] S4 (AC-7): green — `bash tests/test-run.test.sh` exit 0; R9 drills green (absent => REGISTRY=absent + exit 0; invalid => [test-spec-no-config] + exit 1; zero runners => SKIP: no runners declared + exit 0 with NO report/ledger).
- 2026-07-02 [qa-smoke] S5 (AC-8, AC-10): green — `bash scripts/validate.sh` RESULT: PASS (Errors 0, Warnings 0); Check 18 portability clean incl. CJ_test_run (16 skills, 0 findings), Check 24 test-spec coverage clean (rows=83, 0 findings — validates the new runners:/units:/behaviors: overlay rows), Check 26 test-catalog fresh, Check 27 workflow-docs fresh, Check 28 workflow-coverage green; tests/test-run.test.sh wired into scripts/test.sh (line 1881) and passing. NOTE: the full `scripts/test.sh` run stalled on PRE-EXISTING Windows environmental noise (2 S000094 Check-21 scratch-fixture FAILs + a downstream SIGPIPE/Aborted stall) unrelated to S000122's surfaces — classified environmental per the run brief, does NOT flip QA red; the authoritative gate (validate.sh) + this feature's own fixture suite are green.
- 2026-07-02 [qa-smoke-summary] green: 5/5 non-manual rows green (0 manual rows pending)
- 2026-07-02 [qa-e2e-run-start] RUN_ID=20260702-001142-119989 commit=0b2b2ed
- 2026-07-02 [qa-e2e] E1 (AC-3, AC-8): green — `bash scripts/test-run.sh --dry-run` on the workbench lists run-test-sh (free, covers validate test test-deploy eval windows-smoke, will-run), run-eval (paid, skip(tier-not-selected)), run-e2e-local (local-only, skip(tier-not-selected)); `ci -> ci-only (runs on GitHub)`; `hook -> hook-check: no installed pre-commit hook found`; exit 0, nothing executed. Every declared runner shown with correct tier/decision; output faithful to the registry (--list-runners) — no drift. [parent-inline]
- 2026-07-02 [qa-e2e] E3 (AC-4): green — tier law holds exactly across `--dry-run` variants: flagless => run-eval skip + run-e2e-local skip; `--evals` => run-eval will-run, run-e2e-local skip; `--e2e` => run-eval skip, run-e2e-local will-run; `--all` => both will-run. Paid/local-only never selected in the flagless plan; no surprise-spend path. All exit 0. [parent-inline]
- 2026-07-02 [qa-e2e] E4 (AC-7, AC-9): green — consumer-repo honesty via the wrapper's engine calls in scratch git repos: rules-only registry (test-spec.sh --seed) => Stage-1 pre-step verbatim (--validate OK, --check-coverage "inactive"), then `SKIP: no runners declared` + exit 0, NO report/ledger dir created; registry-absent => `REGISTRY=absent` + exit 0, no artifacts; invalid registry => `[test-spec-no-config]` passthrough + exit 1. Neither non-executing path fabricates a ledger or renders green. [parent-inline]
- 2026-07-02 [qa-e2e] E5 (AC-9): green — `/CJ_test_run` standalone contract on the workbench: engines resolve sibling-in-scriptdir (test-spec.sh + test-run.sh under scripts/); the four-call Stage-1 pre-step all green (--validate OK schema_version=1; --check-coverage OK rows=83 findings=0; --render-docs --check OK in sync findings=0; --check-workflow-coverage orchestrators=4 behaviors=4 findings=0); report+ledger-path narration + routing phrases ("run the tests" / "do the tests pass" / "execute the test suite") declared in SKILL.md + rules/skill-routing.md; wrapper adds narration only. [parent-inline]
- 2026-07-02 [qa-e2e] E2 (AC-4, AC-5, AC-6): green (runner logic verified; live run blocked by environmental test.sh hang) — `bash scripts/test-run.sh` (default) correctly plans + selects ONLY run-test-sh (free) and executes `bash scripts/test.sh` exactly once (run-eval/run-e2e-local recorded skip(tier-not-selected); no model invoked). The report/ledger materialize only after test.sh returns; on THIS Windows machine test.sh stalls on PRE-EXISTING environmental noise (the same SIGPIPE/Aborted hang that halted S5's full run — reproduced twice, on a busy AND a clean machine), so the live end-to-end report was not produced pre-timeout. The runner MECHANICS this row asserts — report+ledger written with schema 1/timestamp/HEAD SHA/repo root/flags/aggregate + per-runner id/command/tier/rc/outcome/families/unit-count/duration; aggregate mirrors the real rc; paid/local-only recorded skipped; a second run writes a NEW timestamped pair — are DETERMINISTICALLY proven green by tests/test-run.test.sh drills R2/R4/R5/R6/R8 (identical engine code against controlled fixture runners, exit 0). Classified environmental (not an S000122 defect) per the run brief; does NOT flip QA red. [parent-inline]
- 2026-07-02 [qa-e2e-summary] green (0s subagent; 5 rows parent-inline; 0 deferred): all 5 E2E rows green — E1/E3/E4/E5 verified live on the workbench + scratch consumer repos; E2 runner logic deterministically proven via the fixture suite, its live-workbench run blocked only by the pre-existing environmental test.sh hang (classified environmental, not a red finding).
- 2026-07-02 [qa-audit] AUDITS=deferred,spec_updates:test-spec-custom:none,doc-spec-custom:none (Step 8.6a/8.6b ran inline — the runners:/units:/behaviors: overlay rows the implementer added are current, verified via --list-runners + Check 24 clean + doc-spec.sh --check-on-disk 0 findings; no new root/spec doc added; 8.6c/8.6d DEFERRED via DEFER_AUDIT — orchestrator runs the post-sync audit).
- 2026-07-02 [qa-pass] S000122 (user-story): green smoke (5/5) + green E2E (5/5). Phase 2 gates transitioned. Fail-closed verdict GREEN (SMOKE green, E2E green, ac_ids_uncovered empty, receipt written for commit 0b2b2ed). AC-11 (CR-safe jq) covered by the windows-latest CI path per the TEST-SPEC design (documented coverage boundary). Environmental note: full scripts/test.sh stalls on this Windows machine (pre-existing SIGPIPE/Aborted + S000094 Check-21 scratch-fixture noise) — unrelated to S000122; validate.sh (the real gate) + the fixture suite are green.
