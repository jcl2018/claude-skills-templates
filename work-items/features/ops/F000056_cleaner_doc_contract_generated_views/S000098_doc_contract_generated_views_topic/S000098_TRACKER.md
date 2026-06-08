---
name: "Generated general/custom doc views + philosophy Doc-contract topic"
type: user-story
id: "S000098"
status: active
created: "2026-06-08"
updated: "2026-06-08"
parent: "F000056"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "claude/sleepy-cerf-e8f24b"
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
2. Create working branch: `git checkout -b feat/cleaner_doc_contract_generated_views` (or use parent's branch if shipping in same PR)
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
- [x] Tasks broken down (or N/A — atomic story)

### Phase 2: Implement

1. Read DESIGN + SPEC for context
2. Implement according to architecture decisions in SPEC
3. Run smoke tests as you go (TEST-SPEC `## Smoke Tests` table)
4. Run `/CJ_personal-workflow check` on modified docs after updates
5. Update tracker: move through lifecycle phases, add journal entries
6. Update Files section with changed file paths

**Gates:**
- [ ] Acceptance criteria verified met
- [ ] Smoke tests pass
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

- [ ] `doc-spec.sh --render general` emits the 4 `section: common` rows as a Markdown table (Doc · Purpose · Requirement); `--render custom` emits the 9 `section: custom` rows; cells quote-stripped + pipe-escaped; deterministic (no timestamps); awk-only (bash 3.2 portable); added to `--help` + the tail `case`.
- [ ] `scripts/generate-doc-views.sh` (new, mirrors `generate-readme.sh`) supports `--output-dir <dir>` (default `docs/`), writes `doc-general.md` + `doc-custom.md` with an AUTO-GENERATED header, idempotently.
- [ ] `docs/doc-general.md` + `docs/doc-custom.md` exist (generated), carry no work-item IDs, are not `front_table: required`, and land in the SAME commit as their two registry entries.
- [ ] Two `section: custom`, `audit_class: human-doc` registry entries added to the `doc-spec.md` Custom section for the two views (with `purpose:` + an in-sync `requirement:`).
- [ ] `doc-spec.md` Custom prose slimmed: the hand-written root-operational-docs table replaced by a pointer; the "Repo notes" rationale nuggets (why root docs stay at root; singular `workflow.md`; no-separate-whitelist; the `front_table` field explanation) preserved; Common section byte-identical to the seed.
- [ ] `docs/philosophy.md` has `## Topic: Doc contract` (the two moved principles + a registry→views lead-in) before `## Decision tree`; front-summary-table topic labels updated; Check 19/20 green.
- [ ] `validate.sh` Check 23 (new, from scratch): regenerate into a temp dir via the generator, diff both views against `docs/`; any diff ⇒ ERROR; skip cleanly if the generator is absent.
- [ ] `scripts/test.sh` mirrors Check 23 stdout/temp-only (generate into a temp dir twice, compare temp outputs; never writes `docs/`).
- [ ] `generate-readme.sh:23` docs/ blurb updated to include the two new views; `README.md` regenerated to match; `CLAUDE.md` Scripts table documents `generate-doc-views.sh`.

## Todos

<!-- Actionable items for this story. -->

- [x] Delta 1: `doc-spec.sh --render <general|custom>` (separate awk pass; quote-strip + pipe-escape; --help + case).
- [x] Delta 2: `scripts/generate-doc-views.sh` (--output-dir; AUTO-GENERATED header; idempotent).
- [x] Delta 3: generate `docs/doc-general.md` + `docs/doc-custom.md`.
- [x] Delta 4: two `section: custom` / `audit_class: human-doc` registry entries in `doc-spec.md`.
- [x] Delta 5: slim `doc-spec.md` Custom prose to a pointer; KEEP the "Repo notes" rationale; Common section untouched.
- [x] Delta 6: `docs/philosophy.md` `## Topic: Doc contract` (move 2 principles, before Decision tree); update front-table labels.
- [x] Delta 7: `validate.sh` Check 23 (in-sync) + `test.sh` stdout-only mirror.
- [x] Delta 8: `generate-readme.sh:23` docs/ blurb + README regen (+ CLAUDE.md Scripts row for generate-doc-views.sh per SPEC AC-7).

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-06-08: Created. Single child story carrying the 8-delta implementation of the cleaner doc-contract feature (generated views + philosophy Doc-contract topic).

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. -->

- `scripts/doc-spec.sh` (modified — `--render general|custom` separate awk pass + --help + case)
- `scripts/generate-doc-views.sh` (NEW — generator mirroring generate-readme.sh; `--output-dir`; AUTO-GENERATED header; idempotent)
- `scripts/validate.sh` (modified — Check 23: regen-to-temp + diff drift gate)
- `scripts/test.sh` (modified — stdout/temp-only Check 23 mirror; never writes docs/)
- `scripts/generate-readme.sh` (modified — :23 docs/ blurb includes the two views)
- `docs/doc-general.md` (NEW — generated view of the section:common docs)
- `docs/doc-custom.md` (NEW — generated view of the section:custom docs)
- `docs/philosophy.md` (modified — new `## Topic: Doc contract`; 2 principles moved; front-table labels relabeled to Doc contract)
- `doc-spec.md` (modified — 2 new custom human-doc registry entries; Custom prose slimmed to a pointer, rationale preserved; Common seed untouched)
- `README.md` (modified — regenerated to match the new generate-readme.sh blurb)
- `CLAUDE.md` (modified — Scripts row for generate-doc-views.sh; doc-spec.sh row notes --render + Check 23)

## Insights

<!-- Non-obvious findings worth remembering. -->

- `--render` must NOT extend `_parse_registry` (its 3-col TSV mis-binds a 4th field onto `audit_class` and breaks the closed-enum gate); copy the separate-awk-pass pattern of `_list_front_table_docs` instead. `purpose:`/`requirement:` are quoted multi-word free-form values.
- `test.sh` cannot write into `docs/`: the EXIT trap restores README/catalog/VERSION/CHANGELOG but NOT `docs/doc-*.md`. Mirror the README idempotency test — generate into a temp dir twice and compare the two temp outputs.

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

- [decision] Render row sets are pinned: general = 4 rows (incl. `README.md`, which is a root path not under `docs/`); custom = 9 rows = 7 root operational docs + the 2 self-referencing views.
- [decision] Registry entries + generated files land in ONE commit, else `validate.sh` Check 15a fails declared-but-missing/orphan mid-build.
- [finding] (advisory, non-halt) the registered-doc audit will emit 2 new verdict lines for the views — expected.
- 2026-06-08 [impl-decision] `--render` implemented as a SEPARATE awk pass (`_render_section`, mirroring `_list_front_table_docs`), NOT an extension of `_parse_registry` — a 4th TSV field would mis-bind onto audit_class. purpose/requirement extracted via a `strip()` helper (drop `key: "` prefix + trailing `"`, then `gsub(/\|/,"\\|")` to pipe-escape). The `front_table: required` field between audit_class and purpose for philosophy/workflow is inert (awk only matches section/purpose/requirement).
- 2026-06-08 [impl-decision] Added the `CLAUDE.md` Scripts row for `generate-doc-views.sh` (+ noted `--render`/Check 23 on the existing `doc-spec.sh` row) even though the task's Delta 8 named only generate-readme.sh:23 + README — SPEC requirement #7 + TEST-SPEC E5 require it, and the skill-contract is the source of truth. Honest one-line additions, no scope creep.
- 2026-06-08 [impl-finding] Check 23 written from scratch (no regenerate-and-diff idiom existed — README is only idempotency-tested in test.sh, not drift-checked in validate.sh). Generator-based (header-safe). test.sh mirror is temp-twice-compare (the EXIT trap restores README/catalog/VERSION/CHANGELOG but NOT docs/doc-*.md) — verified the block runs clean under `bash set -e` and never writes docs/.
- 2026-06-08 [impl] Implemented all 8 deltas. Wrote 1 new script (generate-doc-views.sh) + 2 generated views (docs/doc-general.md, docs/doc-custom.md); modified doc-spec.sh, validate.sh, test.sh, generate-readme.sh, doc-spec.md, docs/philosophy.md, README.md, CLAUDE.md. Common seed byte-identical (test #13 green); registry validates schema_version=1.
- 2026-06-08 [impl-pass] S000098: implementation complete. Phase 2 implementer-owned gates transitioned. validate.sh PASS 0/0 (incl. Check 23 PASS, Check 19 6 human-docs clean); generator idempotent; seed-diff empty; Check-23 drift caught + cleared on regen.
