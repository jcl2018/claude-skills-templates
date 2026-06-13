---
name: "Required reference.md — a general-tier curated external-references doc governed by the doc contract"
type: feature
id: "F000062"
status: active
created: "2026-06-12"
updated: "2026-06-12"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates/.claude/worktrees/unruffled-kalam-e25974"
branch: "claude/unruffled-kalam-e25974"
blocked_by: ""
---

<!-- Prerequisite: Before scaffolding this work item, run /office-hours to
     produce a design plan in ~/.gstack/projects/. Distill that plan into
     DESIGN.md during Phase 1 below. -->

## Lifecycle

### Phase 1: Track

1. Create working branch: `git checkout -b feat/required_reference_doc`
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

- [ ] **`docs/reference.md` exists, declared general:** the file is on disk, is a curated external-references doc (grouped categories, real entries each with a one-line why), declared in the registry as `section: common` + `audit_class: human-doc` with NO `front_table`, and carries no work-item IDs (Check 19 stays green because it is a human-doc).
- [ ] **Registry row in all 3 seed copies, byte-identical:** the `docs/reference.md` registry entry (the shape-not-links `requirement` string) is added after `docs/architecture.md` in `scripts/doc-spec.sh`'s heredoc, `templates/doc-spec-common.md`, and `spec/doc-spec.md` — identically.
- [ ] **Human-docs prose-table row in all 3 seed copies:** the `| docs/reference.md | ... |` row is added under the seed's "Human docs" table in all three copies.
- [ ] **Count edit swept everywhere:** `eleven` → `twelve` in the seed prose of all 3 copies and in `spec/doc-spec-custom.md`; CLAUDE.md's human-docs parenthetical (~L539) gains `docs/reference.md`.
- [ ] **3-way seed byte-identity holds:** `bash scripts/doc-spec.sh --seed | cmp - spec/doc-spec.md` AND `cmp spec/doc-spec.md templates/doc-spec-common.md` both pass after the edits.
- [ ] **Views regenerated, Check 23 green:** `scripts/generate-doc-views.sh` regenerates `docs/doc-general.md` to list 12 docs; the regen-to-temp + diff (Check 23, HARD) is clean.
- [ ] **Contract + tests green:** `doc-spec.sh --validate` parses; `--list-declared` shows `docs/reference.md`; `--check-on-disk` PASS; `scripts/validate.sh` PASS 0/0 (no validate.sh edit needed); `scripts/test.sh` PASS — config test 8b tolerates 12 (inclusion-based) and gains a `docs/reference.md` include-assertion.
- [ ] **QA dogfood:** this build's own QA runs the three-stage `/CJ_doc_audit` (F000061) — Stage 2 judges `docs/reference.md` `satisfies` against its requirement, Stage 3 reports `no-drift`. reference.md is the first doc born under the hardened audit.

## Todos

<!-- Actionable items for this feature. Break into child tasks for
     large features. -->

- [ ] S000104: full build — the `docs/reference.md` curated content + the 3-way-byte-identical registry row + Human-docs prose-table row + the `eleven`→`twelve` count sweep (3 seed copies + `spec/doc-spec-custom.md` + CLAUDE.md parenthetical) + regenerate `docs/doc-general.md` + config-test-8b growth-safe verification (tolerate 12, add reference.md to expected-includes)
- [ ] Coordinate: single-commit atomicity — the 3 seed copies + `spec/doc-spec.md` registry + the regenerated `docs/doc-general.md` view must land together (Checks 15a/16/23 fail half-states at the pre-commit hook)
- [ ] Coordinate: no tree mutations while `scripts/test.sh` runs (its EXIT restore-trap clobbers concurrent edits — never regen views / scaffold during a test run)
- [ ] Coordinate: `validate.sh` is NOT edited — its registry-reading checks (15/15a/17/19/20) auto-pick-up the new declared doc; an unnecessary validate.sh edit is out of scope
- [ ] Content honesty: every `docs/reference.md` entry grounded in a demonstrable repo reference (grep `CLAUDE.md` / `scripts/` / `CHANGELOG.md` / `docs/` / `.github/` for the URL / tool / standard before listing it); no invented influences; no work-item IDs
- [ ] Post-land assignment: open `docs/reference.md` and prune/extend the curated list to match what the operator actually rates as formative (the build seeds from repo-evidence; the editorial call is the operator's)

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-06-12: Created. A new REQUIRED general-tier doc, `docs/reference.md`: a curated shelf of external references (repos / links / blogs / articles) relevant to building this workbench, grouped by category, each with a one-line why. Governed by the doc contract like every other registered doc — added to all 3 byte-identical seed copies (`scripts/doc-spec.sh` heredoc + `templates/doc-spec-common.md` + `spec/doc-spec.md`) as `section: common` / `audit_class: human-doc` / no `front_table`, with the count edit (`eleven`→`twelve`) swept across the seed copies + `spec/doc-spec-custom.md` + CLAUDE.md, the generated `docs/doc-general.md` view regenerated, and the build's own QA dogfooding the three-stage `/CJ_doc_audit`. Reuses the F000058 general-docs-required row+count+view mechanics. Single-story scope.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. Populated during Track phase, updated during Implement. -->

- docs/reference.md (new — curated external references, grouped categories, no work-item IDs)
- scripts/doc-spec.sh (modified — `--seed` heredoc gains the `docs/reference.md` registry row + Human-docs prose-table row + `eleven`→`twelve`; byte-identical to the other 2 seed copies)
- templates/doc-spec-common.md (modified — seed lockstep: same row + table row + count edit)
- spec/doc-spec.md (modified — seed lockstep: same row + table row + count edit)
- spec/doc-spec-custom.md (modified — `eleven`→`twelve` count prose)
- docs/doc-general.md (regenerated — now lists 12 common docs incl. `docs/reference.md`)
- CLAUDE.md (modified — human-docs parenthetical ~L539 gains `docs/reference.md`)
- tests/cj-document-release-config.test.sh (modified — config test 8b gains a `docs/reference.md` include-assertion; remains growth-safe / inclusion-based)

## Insights

<!-- Non-obvious findings worth remembering. Design decisions,
     trade-offs, patterns discovered. -->

- "It should be in doc-spec.md" — the operator reaches for the contract first: a reference doc that isn't governed by the registry would drift into staleness, so it is put under the same audit as everything else from the start.
- The `requirement` string asserts SHAPE + PURPOSE, never specific links — links churn; the doc must not self-stale when one entry is added or removed (the same reason Check 14 / the audit judge requirements, not contents).
- `validate.sh` needs NO edit: Checks 15/15a/17/19/20 read the merged registry, so a new declared doc is picked up automatically — the contract is registry-driven by construction, which is exactly what F000050/F000056 bought.
- Config test 8b is inclusion-based (asserts the seed INCLUDES core docs, tolerates growth) — adding a 12th doc breaks nothing; the only edits are the human-readable count words, never an exact-count assertion.
- This is the first doc to be born under F000061's three-stage `/CJ_doc_audit` — the build dogfoods its own freshly-hardened audit (Stage 2 requirement-compliance + Stage 3 implementation-drift) on the doc it just declared.

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

- 2026-06-12 [decision] D15.1 — general-seed tier (not a custom-overlay row): the operator chose "required everywhere," paying the consumer-ripple cost so the rule means the same thing in every adopting repo.
- 2026-06-12 [decision] D15.2 — curated v1 (real entries grounded only in sources the repo demonstrably uses, verified by grep), not an empty stub; the operator prunes/extends at the PR.
- 2026-06-12 [decision] No `front_table` — reference.md is a categorized link shelf, not a principle/workflow index; only philosophy.md + workflow.md require a leading summary table, so Check 20 deliberately does not apply.
- 2026-06-12 [decision] `validate.sh` untouched — registry-reading checks auto-cover the new declared doc; an extra validate.sh edit would be redundant and out of scope.
