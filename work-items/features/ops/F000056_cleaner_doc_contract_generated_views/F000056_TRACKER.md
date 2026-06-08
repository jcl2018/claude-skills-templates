---
name: "Cleaner doc-contract: generated general/custom views + philosophy Doc-contract topic"
type: feature
id: "F000056"
status: active
created: "2026-06-08"
updated: "2026-06-08"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "claude/sleepy-cerf-e8f24b"
blocked_by: ""
---

<!-- Prerequisite: Before scaffolding this work item, run /office-hours to
     produce a design plan in ~/.gstack/projects/. Distill that plan into
     DESIGN.md during Phase 1 below. -->

## Lifecycle

### Phase 1: Track

1. Create working branch: `git checkout -b feat/cleaner_doc_contract_generated_views`
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

- [ ] `doc-spec.sh --render general` emits exactly the 4 `section: common` rows (`README.md`, `docs/philosophy.md`, `docs/workflow.md`, `docs/architecture.md`) as a Markdown table (Doc · Purpose · Requirement), quote-stripped and pipe-escaped.
- [ ] `doc-spec.sh --render custom` emits exactly the 9 `section: custom` rows (7 root operational docs + the 2 new self-referencing views) as a Markdown table.
- [ ] `scripts/generate-doc-views.sh` (with `--output-dir`) writes `docs/doc-general.md` + `docs/doc-custom.md` idempotently (twice into a temp dir → identical output).
- [ ] `docs/doc-general.md` + `docs/doc-custom.md` exist, are declared in the `doc-spec.md` Custom registry, and land in the SAME commit as their two registry entries (Check 15a green mid-build).
- [ ] `validate.sh` Check 23 fails when the generated views drift from the registry and passes when in sync; it skips cleanly if the generator is absent.
- [ ] `scripts/test.sh` mirrors Check 23 stdout/temp-only (generate into a temp dir twice, compare temp outputs; never writes `docs/`).
- [ ] `docs/philosophy.md` has a new `## Topic: Doc contract` carrying the two doc-contract principles + the registry→views model; front-summary-table topic labels updated; `## Decision tree` stays last.
- [ ] `doc-spec.md` Custom prose is slimmed to a pointer (table replaced) while preserving the "Repo notes" rationale nuggets; the Common section stays byte-identical to the seed (test #13 green); registry stays `doc-spec.sh --validate` clean.
- [ ] `CLAUDE.md` Scripts reference table documents `generate-doc-views.sh`.
- [ ] `generate-readme.sh:23` docs/ layout blurb updated to include the two new views and `README.md` regenerated to match.
- [ ] `validate.sh` + `test.sh` green; Check 19/20 green; portability gate green; PR opens and STOPS.

## Todos

<!-- Actionable items for this feature. Break into child tasks for
     large features. -->

- [ ] Implement the 8 deltas via child story S000098 (render subcommand → generator → views → registry entries → slim Custom prose → philosophy topic → Check 23 + test.sh mirror → generate-readme blurb + README regen).
- [ ] QA: render row sets exact (general=4, custom=9); views in sync (Check 23); validate.sh + test.sh green; seed test #13 green; Check 19/20 green; portability green.

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-06-08: Created. Cleaner doc-contract — keep one root registry, generate readable general/custom views into `docs/`, add a validate.sh in-sync check, and lift the doc-contract logic into a `philosophy.md` "Doc contract" topic.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. Populated during Track phase, updated during Implement. -->

- `scripts/doc-spec.sh` (new `--render general|custom` subcommand)
- `scripts/generate-doc-views.sh` (new generator)
- `docs/doc-general.md`, `docs/doc-custom.md` (new generated views)
- `doc-spec.md` (two new Custom registry entries + slimmed Custom prose)
- `docs/philosophy.md` (new `## Topic: Doc contract`)
- `scripts/validate.sh` (Check 23), `scripts/test.sh` (stdout-only mirror)
- `scripts/generate-readme.sh` (docs/ blurb), `README.md` (regenerated)
- `CLAUDE.md` (Scripts reference row)

## Insights

<!-- Non-obvious findings worth remembering. Design decisions,
     trade-offs, patterns discovered. -->

- The literal "relocate doc-spec.md into docs/ + two hand-maintained files" proposal was reframed: `doc-spec.md` is config (carries `schema_version` + a machine schema, read by ~13 hardcoded `./`-relative call sites), not a doc. Generating the views from the one root registry preserves single-source-of-truth — there is no second list to keep in sync, exactly like README is generated from `skills-catalog.json`.
- The operator optimizes for the invariant, not the literal file move: accepting "config stays at root, generate the views" once the single-source-of-truth cost was named.

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

- [decision] Keep one root registry; generate `docs/doc-general.md` + `docs/doc-custom.md` as views (Approach A). Rejected Approach B (literal relocation + hand-maintained files) — breaks ~13 pinned paths + every consumer repo and reintroduces a second list. Rejected Approach C (philosophy topic only) — leaves the hand-maintained duplicate table and skips the readable split.
- [decision] The Common/portable seed section of `doc-spec.md` is OUT OF SCOPE (untouched) — it is byte-identical to `templates/doc-spec-common.md`, enforced by `tests/cj-document-release-config.test.sh` test #13. Only the repo-local Custom section is slimmed.
- [decision] `--render` is implemented as a separate awk pass (NOT `_parse_registry`, whose 3-col TSV would mis-bind a 4th field), with quote-strip + pipe-escape, mirroring `_list_front_table_docs`.
- [decision] Check 23 is written from scratch (no existing regenerate-and-diff idiom to mirror); it is generator-based (header-safe). The `test.sh` mirror is stdout/temp-only because the EXIT trap does not restore `docs/`.
