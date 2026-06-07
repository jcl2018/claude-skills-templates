---
name: "Front-table format convention for philosophy.md & workflow.md (registry-driven, enforced)"
type: feature
id: "F000052"
status: active
created: "2026-06-06"
updated: "2026-06-06"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "cj-feat-20260606-154639-66395"
blocked_by: ""
---

<!-- Prerequisite: Before scaffolding this work item, run /office-hours to
     produce a design plan in ~/.gstack/projects/. Distill that plan into
     DESIGN.md during Phase 1 below. -->

## Lifecycle

### Phase 1: Track

1. Create working branch: `git checkout -b feat/front_table_format_convention`
2. Scaffold work item directory and TRACKER.md
3. Distill `DESIGN.md` from the /office-hours output (problem shape, big decisions, risks) — from `templates/doc-DESIGN.md`
4. Scaffold `ROADMAP.md` (scope, non-goals, decomposition, delivery timeline) — from `templates/doc-ROADMAP.md`
5. Define acceptance criteria (what "done" looks like for the whole feature)
6. Decompose into child user-stories
   → detail (DESIGN, SPEC, TEST-SPEC) lives in child stories

**Gates:**
- [x] /office-hours design produced (in `~/.gstack/projects/`)
- [x] Working branch created (`branch` field populated)
- [x] DESIGN + ROADMAP scaffolded
- [x] Acceptance criteria scoped
- [x] Broken down into child stories

### Phase 2: Implement

1. Child user-stories drive implementation (feature tracker coordinates)
2. Monitor child progress — update this tracker when children complete phases
3. Update Todos section — check off completed children, add discoveries
4. Update Files section with top-level changed files

**Gates:**
- [ ] All child stories have entered Phase 2+
- [ ] Feature-level Todos reflect remaining coordination work

### Phase 3: Ship

1. Run `/CJ_personal-workflow check` — verify all children pass validation
2. Verify smoke tests pass in CI (automated regression)
3. Walk E2E manually — run user-scenario verification before ship
4. Run `/ship` — creates feature PR (includes pre-landing code review)
5. Run `/land-and-deploy` — merges and verifies deployment
6. Run `/document-release` — post-ship doc audit; fix drifts inline or spawn D-tickets

**Gates:**
- [ ] `/CJ_personal-workflow check` — all children pass validation
- [ ] Smoke tests pass in CI
- [ ] E2E walked manually
- [ ] `/ship` — PR created (with pre-landing review)
- [ ] `/land-and-deploy` — merged and deployed
- [ ] `/document-release` — post-ship doc audit done; drifts fixed inline or spawned as D-tickets

## Acceptance Criteria

<!-- What "done" looks like for this feature. Each criterion should be
     testable and specific. -->

- [ ] `scripts/doc-spec.sh --list-front-table-docs` prints exactly `docs/philosophy.md` and `docs/workflow.md`.
- [ ] `scripts/doc-spec.sh --validate` still returns `OK schema_version=1`.
- [ ] `scripts/validate.sh` passes on the repo (both docs now have front tables) and fails with a `  ERROR:` Check-20 line when a flagged doc's leading table is removed.
- [ ] `scripts/test.sh` is green end-to-end, including the new plant-and-restore Check-20 integration test and the `--list-front-table-docs` unit assertions in `tests/cj-document-release-config.test.sh`.
- [ ] `docs/philosophy.md` and `docs/workflow.md` each open with a summary table; both still pass Check 15/15a/15b and Check 19.
- [ ] The Step 6.7 registered-doc audit reads the updated requirement strings (advisory; no new halt). No `doc-spec.sh` subcommand enumeration left stale.

## Todos

<!-- Actionable items for this feature. Break into child tasks for
     large features. -->

- [ ] Ship S000092 — front-table format convention (registry field + subcommand + Check 20 + tables + tests + doc-touches)

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-06-06: Created. Front-table format convention for philosophy.md & workflow.md — registry-driven, hard validate.sh gate.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. Populated during Track phase, updated during Implement. -->

- `doc-spec.md` — add `front_table: required` to philosophy.md/workflow.md entries; extend their requirement strings; Custom prose note.
- `scripts/doc-spec.sh` — new `--list-front-table-docs` subcommand (separate awk path; `_parse_registry` + `_emit_seed` untouched).
- `scripts/validate.sh` — hard Check 20 (front-table-required docs open with a summary table).
- `scripts/test.sh` — plant-and-restore Check-20 negative test.
- `tests/cj-document-release-config.test.sh` — `--list-front-table-docs` positive/negative unit assertions.
- `docs/philosophy.md` — leading summary table (every principle).
- `docs/workflow.md` — leading summary table (every workflow / entry point).
- Doc-touches: `CLAUDE.md`, `docs/architecture.md`, `skills/CJ_document-release/SKILL.md` + `skills/CJ_document-release/USAGE.md`.

## Insights

<!-- Non-obvious findings worth remembering. Design decisions,
     trade-offs, patterns discovered. -->

- The registry-driven gate (a `front_table` field read by `validate.sh`) honors the workbench's own Principle 3 ("the registry is the source of truth; tooling parses it, never a second hardcoded list") — flagging a third doc later is a one-line registry edit, no validator change.
- The new field is a workbench-LOCAL registry extension: it lives outside the `DOC-SPEC-COMMON:BEGIN/END` prose markers, so `doc-spec.md` still satisfies its "Common section verbatim from the seed" requirement and `_emit_seed` stays byte-identical.
- Two gate-breaking traps the adversarial review surfaced: (1) Check 20's awk must stop at the FIRST `^## ` heading — both docs already contain tables LATER (philosophy.md:136, workflow.md:581), so a whole-file grep yields a false PASS; (2) `_parse_registry`'s 3-column TSV must NOT be widened to a 4th column — its consumer reads with a 3-var `read`, so a 4th column would append `front_table` onto `audit_class` and break the closed-enum gate for every entry. Use a SEPARATE awk path.
- Check 20 must emit `  ERROR:` inline (Check 15-19 style), NOT the `fail()` helper (which prints `FAIL:`) — the negative test greps a literal `  ERROR:` prefix.

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

- [decision] Enforced, registry-driven (Approach C) chosen over advisory-only (A) and portable-seed (B). Summary: operator escalated from advisory to a hard CI gate AND chose the registry-driven gate source over hardcoding filenames in validate.sh.
- [decision] Workbench-local registry extension (C2) chosen over propagating via the `doc-spec.sh` seed heredoc. Summary: keep the COMMON prose block + `_emit_seed` byte-identical so `doc-spec.md` still satisfies its own "verbatim seed" requirement; the new field lives in the machine registry outside the COMMON markers and is documented in the Custom prose section.
- [decision] `architecture.md` deliberately NOT flagged with a front table. Summary: only philosophy.md + workflow.md are flagged; leaving architecture.md unflagged demonstrates the registry-driven scoping (adding it later is a one-line registry edit) — deferred as out of scope.
