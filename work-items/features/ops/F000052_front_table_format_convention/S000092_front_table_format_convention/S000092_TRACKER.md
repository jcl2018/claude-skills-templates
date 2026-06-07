---
name: "Front-table format convention (registry field + subcommand + Check 20 + tables + tests + doc-touches)"
type: user-story
id: "S000092"
status: active
created: "2026-06-06"
updated: "2026-06-06"
parent: "F000052"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "cj-feat-20260606-154639-66395"
blocked_by: ""
---

<!-- Prerequisite: Before scaffolding this work item, run /office-hours to
     produce a design plan in ~/.gstack/projects/. Distill that plan into
     DESIGN.md during Phase 1 below. (For atomic stories that derive directly
     from the parent feature's /office-hours session, the parent's design is
     sufficient context — DESIGN.md may be a brief stub linking to the parent.) -->

## Lifecycle

### Phase 1: Track

1. Read parent tracker to understand scope
2. Create working branch: `git checkout -b feat/front_table_format_convention` (or use parent's branch if shipping in same PR)
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
- [x] Tasks broken down (N/A — atomic story)

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

- [x] `doc-spec.md` carries `front_table: required` on the `docs/philosophy.md` and `docs/workflow.md` registry entries, with extended requirement strings and a Custom-prose note; the `DOC-SPEC-COMMON` block is unchanged.
- [x] `scripts/doc-spec.sh --list-front-table-docs` prints exactly `docs/philosophy.md` and `docs/workflow.md` (separate awk path; `_parse_registry` 3-column TSV and `_emit_seed` untouched); `--validate` still returns `OK schema_version=1`.
- [x] `scripts/validate.sh` Check 20 passes on the repo and fails with a `  ERROR:` Check-20 line (inline, not `fail()`) when a flagged doc's leading table is removed.
- [x] `docs/philosophy.md` and `docs/workflow.md` each open with a leading summary table (before the first `^## `), with no work-item IDs; both still pass Check 15/15a/15b and Check 19.
- [x] `scripts/test.sh` is green end-to-end, including the plant-and-restore Check-20 negative test and the `--list-front-table-docs` unit assertions in `tests/cj-document-release-config.test.sh`.
- [x] Doc-touches updated in the same PR: CLAUDE.md (check list + doc-spec.sh subcommand row), architecture.md (Check 20 + subcommand list), CJ_document-release SKILL.md subcommand list, and USAGE.md `last-updated` bumped.

## Todos

<!-- Actionable items for this story. -->

- [ ] `doc-spec.md`: add `front_table: required` + extend the two requirement strings + Custom prose note.
- [ ] `scripts/doc-spec.sh`: separate-awk `--list-front-table-docs` (+ gates + help); leave `_parse_registry` and `_emit_seed` untouched.
- [ ] `docs/philosophy.md` and `docs/workflow.md`: add the leading front tables.
- [ ] `scripts/validate.sh`: Check 20 (awk, stop-at-first-`##`, `  ERROR:` inline).
- [ ] Tests: plant-and-restore Check-20 negative test in `scripts/test.sh`; `--list-front-table-docs` unit assertions in `tests/cj-document-release-config.test.sh`.
- [ ] Doc-touches: CLAUDE.md (check list + subcommand row), architecture.md (Check 20 + subcommand list), SKILL.md subcommand list + USAGE.md `last-updated` bump.
- [ ] Run `./scripts/validate.sh` and `./scripts/test.sh` green.

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-06-06: Created. Atomic story implementing the front-table format convention end-to-end.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. -->

- `doc-spec.md`
- `scripts/doc-spec.sh`
- `scripts/validate.sh`
- `scripts/test.sh`
- `tests/cj-document-release-config.test.sh`
- `docs/philosophy.md`
- `docs/workflow.md`
- `CLAUDE.md` (doc-touch)
- `docs/architecture.md` (doc-touch)
- `skills/CJ_document-release/SKILL.md` (doc-touch)
- `skills/CJ_document-release/USAGE.md` (doc-touch — `last-updated` bump)

## Insights

<!-- Non-obvious findings worth remembering. -->

- Check 20's awk MUST stop at the first `^## ` heading — both docs already contain tables LATER (philosophy.md:136, workflow.md:581), so a whole-file grep yields a false PASS.
- `_parse_registry`'s 3-column TSV must NOT be widened to a 4th column — its consumer `_run_registry_gates` reads with a 3-var `read`, so a 4th column would append `front_table` onto `audit_class` and break the closed-enum gate for every entry. Use a separate awk path.
- Check 20 emits `  ERROR:` inline (Check 15-19 style), NOT the `fail()` helper (which prints `FAIL:`) — the negative test greps a literal `  ERROR:` prefix.
- The `zzz-test-scaffold` fixture runs validate.sh against the REAL repo, so once the two real docs get front tables it passes Check 20 unchanged; the real test edit needed is an explicit plant-and-restore negative test in the Check 17 / Check 19 style.

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

- [decision] Use a SEPARATE awk path for `--list-front-table-docs` rather than widening `_parse_registry`'s shared TSV. Summary: the 3-var `read` consumer would mis-bind a 4th column onto `audit_class` and break the closed-enum gate for every entry.
- [decision] Check 20 stops at the first `^## ` and emits `  ERROR:` inline. Summary: later tables in both docs would false-PASS a whole-file grep; the negative test matches a literal `  ERROR:` prefix so `fail()`'s `FAIL:` output is wrong.
- 2026-06-06 [qa-smoke] S1 (AC-2): green — `scripts/doc-spec.sh --list-front-table-docs` prints exactly `docs/philosophy.md` + `docs/workflow.md` (exit 0); nothing else emitted.
- 2026-06-06 [qa-smoke] S2 (AC-1): green — `scripts/doc-spec.sh --validate` prints `OK schema_version=1` (exit 0); new `front_table` field + extended requirement strings do not break the schema.
- 2026-06-06 [qa-smoke] S3 (AC-3,AC-4): green — `scripts/validate.sh` RESULT: PASS (Errors: 0, Warnings: 0); Check 20 ran and both `docs/philosophy.md` + `docs/workflow.md` PASS alongside Check 15/15a/15b + 19.
- 2026-06-06 [qa-smoke] S4 (AC-3,AC-5): green — `scripts/test.sh` RESULT: PASS (Failures: 0); the Check-20 plant-and-restore negative test passes both legs (strip philosophy.md table → front-table ERROR + non-zero exit; restore → exit 0).
- 2026-06-06 [qa-smoke] S5 (AC-5): green — `tests/cj-document-release-config.test.sh` PASS; asserts `--list-front-table-docs` emits only `front_table: required` paths (entry WITH the flag emitted, entry WITHOUT it not).
- 2026-06-06 [qa-smoke-summary] green: 5/5 non-manual rows green (0 manual rows pending)
- 2026-06-06 [qa-e2e-run-start] RUN_ID=20260606-164251-55264 commit=97c703c
- 2026-06-06 [qa-e2e] E1 (AC-4): green — both docs open with a leading summary table before their first `## ` (philosophy.md table at L8 < first `## ` at L15; workflow.md table at L49 < first `## ` at L58); no `[FSTD]NNNNNN` in either doc.
- 2026-06-06 [qa-e2e] E2 (AC-6): green — all four doc-touches carry the new subcommand/check: CLAUDE.md (Scripts row lists `--list-front-table-docs`; check list has Check 20; doc-spec.sh row reads "Checks 15/16/17/19/20"), architecture.md (Check 20 + `--list-front-table-docs`), CJ_document-release SKILL.md (`--list-front-table-docs`), USAGE.md `last-updated` bumped to 2026-06-06T23:27:20Z; validate.sh Check 14 reports CJ_document-release USAGE.md current (no drift flag).
- 2026-06-06 [qa-e2e] E3 (AC-3): green — registry-driven scoping holds: `docs/architecture.md` (a declared human-doc) is ABSENT from `--list-front-table-docs`, has no leading table, yet validate.sh PASSes (Check 20 lists only philosophy+workflow) — architecture.md is exempt.
- 2026-06-06 [qa-e2e-summary] green (0s subagent [leaf-inline, read-only partition]; 0 rows parent-inline; 0 deferred): all 3 E2E criteria (E1, E2, E3) green. Tracker journal updated.
- 2026-06-06 [qa-pass] S000092 (user-story): green smoke (5/5) + green E2E (3/3). Phase 2 gates transitioned. Convention is workbench-local — DOC-SPEC-COMMON block + `_emit_seed` byte-identical to origin/main.
