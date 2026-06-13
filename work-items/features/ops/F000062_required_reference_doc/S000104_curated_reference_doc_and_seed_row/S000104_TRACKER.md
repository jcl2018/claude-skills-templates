---
name: "Curated reference.md + 3-way seed row/table/count + view regen + config-test-8b verify + QA dogfood"
type: user-story
id: "S000104"
status: active
created: "2026-06-12"
updated: "2026-06-12"
parent: "F000062"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates/.claude/worktrees/unruffled-kalam-e25974"
branch: "claude/unruffled-kalam-e25974"
blocked_by: ""
receipts:
  qa:
    phase: 3
    commit: "292fbb7f4bdba4cc343abc370a7898a5a2a7bde2"
    completed_at: "2026-06-12T19:45:00Z"
    test_rows_run: 7
    ac_ids_covered: [AC-1, AC-2, AC-3, AC-4, AC-5, AC-6, AC-7, AC-8]
    ac_ids_uncovered: []
    diff_audit:
      changed_files_without_tests: []
    journal_entries: ["[qa-smoke] S1-S5 green", "[qa-e2e] E1 green", "[qa-e2e] E2 green", "[qa-audit] doc:ok test:ok", "[qa-pass]"]
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
2. Create working branch: `git checkout -b feat/required_reference_doc` (or use parent's branch if shipping in same PR)
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

- [ ] `docs/reference.md` exists: a curated external-references doc with a short intro line + grouped categories (e.g. Claude Code & agents, gstack, Conventions & standards, Tooling), each entry `- [Name](url) — one-line why it matters here`, every entry grep-grounded in the repo, no work-item IDs.
- [ ] The `docs/reference.md` registry row (section: common, audit_class: human-doc, NO front_table, shape-not-links requirement) is added after `docs/architecture.md` byte-identically in all 3 seed copies.
- [ ] The Human-docs prose-table row is added in all 3 seed copies.
- [ ] `eleven`→`twelve` is swept in all 3 seed copies + `spec/doc-spec-custom.md`; CLAUDE.md's human-docs parenthetical (~L539) gains `docs/reference.md`.
- [ ] 3-way byte-identity holds (`--seed | cmp - spec/doc-spec.md` AND `cmp spec/doc-spec.md templates/doc-spec-common.md`).
- [ ] `docs/doc-general.md` regenerated (now 12 docs); Check 23 green.
- [ ] `doc-spec.sh --validate` OK; `--list-declared` shows `docs/reference.md`; `--check-on-disk` PASS; `scripts/validate.sh` PASS 0/0; `scripts/test.sh` PASS (config test 8b tolerates 12 + lists reference.md).
- [ ] QA's `/CJ_doc_audit` reports reference.md `satisfies` (Stage 2) + `no-drift` (Stage 3).

## Todos

<!-- Actionable items for this story. -->

- [x] Grep the tree (`CLAUDE.md`, `scripts/`, `CHANGELOG.md`, `docs/`, `.github/`) for referenced URLs / tool names / cited standards; assemble the curated entry set from real hits only.
- [x] Write `docs/reference.md` (intro + grouped categories + one-line whys; no work-item IDs).
- [x] Add the registry row after `docs/architecture.md` in `scripts/doc-spec.sh` heredoc, `templates/doc-spec-common.md`, `spec/doc-spec.md` (byte-identical).
- [x] Add the Human-docs prose-table row in all 3 seed copies.
- [x] Sweep `eleven`→`twelve` in the 3 seed copies + `spec/doc-spec-custom.md`; add `docs/reference.md` to CLAUDE.md's parenthetical (~L539).
- [x] `bash scripts/generate-doc-views.sh` to regenerate `docs/doc-general.md`.
- [x] Verify: 3-way `cmp`, `doc-spec.sh --validate`/`--list-declared`/`--check-on-disk`, Check 23, `validate.sh` 0/0.
- [x] Update config test 8b: confirm growth-safe / tolerates 12; add a `docs/reference.md` include-assertion.
- [ ] Run `scripts/test.sh` (only when the tree is otherwise quiescent — its EXIT restore-trap clobbers concurrent edits).

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-06-12: Created. Single-story build of the required general-tier `docs/reference.md`: curated content + 3-way-byte-identical registry row + Human-docs prose-table row + `eleven`→`twelve` count sweep + `docs/doc-general.md` regeneration + config-test-8b growth-safe verification + the QA dogfood of the three-stage `/CJ_doc_audit`.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. -->

- docs/reference.md (new)
- scripts/doc-spec.sh (modified — `--seed` heredoc: registry row + Human-docs table row + count edit)
- templates/doc-spec-common.md (modified — seed lockstep)
- spec/doc-spec.md (modified — seed lockstep)
- spec/doc-spec-custom.md (modified — `eleven`→`twelve`)
- docs/doc-general.md (regenerated — 12 docs)
- CLAUDE.md (modified — human-docs parenthetical gains `docs/reference.md`)
- tests/cj-document-release-config.test.sh (modified — config test 8b reference.md include-assertion)
- tests/doc-spec-overlay.test.sh (modified — mk_cod_fixture creates the newly-declared docs/reference.md so the clean-fixture + one-finding-isolation drills stay green)

## Insights

<!-- Non-obvious findings worth remembering. -->

- The three seed copies are byte-identical by invariant: edit one, mirror the other two, then verify with `--seed | cmp -` against both — never hand-diff.
- `validate.sh` needs no edit; the registry-reading checks (15/15a/17/19/20) pick up the new declared doc — a redundant validate.sh change would be out of scope.
- Config test 8b is inclusion-based, so it already tolerates a 12th doc; the only change is adding an include-assertion for the new doc (and the human-readable count word edits live in the seed prose, not in any test).

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

- 2026-06-12 [decision] Single-story scope — the six mechanical pieces are tightly coupled (the file, the 3 seed copies, the count sweep, the view, the verify) and ship in one PR; decomposing into tasks would only fragment an atomic change.
- 2026-06-12 [decision] Seed edits + regenerated view land in ONE commit — Checks 15a/16/23 fail any half-state at the pre-commit hook, so the registry row, the 3 byte-identical copies, and the `docs/doc-general.md` regeneration are atomic.
- 2026-06-12 [impl-decision] Curated reference.md entries are grep-grounded only (D15.2): each URL/tool/standard was confirmed referenced in-repo before listing — Keep a Changelog (collection-version.sh + CHANGELOG.md), semver (skills-update-check is_semver), gh (README cli.github.com + the merge convention), shellcheck (CI + philosophy.md), jq/python3/Git-for-Windows/Copilot (README prerequisites + work-copilot), GitHub Actions (.github/workflows/), gstack (wrapped throughout). Claude Code + Anthropic docs grounded by the repo being a Claude Code skills collection.
- 2026-06-12 [impl-decision] Config test 8b left inclusion-based (not weakened): added `docs/reference.md` to its existing `grep -qx` include-chain rather than asserting an exact count, so future seed growth still breaks nothing while the new doc is now covered.
- 2026-06-12 [impl-finding] No "four human docs" / numeric count phrase existed in this repo's CLAUDE.md — the only general-doc enumeration was the human-docs parenthetical list, which gained `docs/reference.md`. The "eleven"→"twelve" word lives only in the seed prose + the custom overlay; all swept (zero "eleven" left).
- 2026-06-12 [impl] Created docs/reference.md (new); modified scripts/doc-spec.sh (--seed heredoc: registry row + Human-docs table row + count), templates/doc-spec-common.md + spec/doc-spec.md (seed lockstep), spec/doc-spec-custom.md (count), CLAUDE.md (parenthetical), tests/cj-document-release-config.test.sh (8b include-assertion), tests/doc-spec-overlay.test.sh (mk_cod_fixture), docs/doc-general.md (regenerated). 3-way seed cmp clean; doc-spec --validate OK; --list-declared=17 (12 common + 5 custom) incl. docs/reference.md; --check-on-disk FINDINGS=0; validate.sh PASS 0/0 (Check 19 7 human-docs, Check 23 in sync); smoke S1-S5 PASS.
- 2026-06-12 [impl-finding] test.sh surfaced a 2nd test that enumerates the seed's declared docs on disk: tests/doc-spec-overlay.test.sh's mk_cod_fixture creates each declared general doc, so adding docs/reference.md to the registry made the clean-fixture --check-on-disk drill (and the 7 one-finding-isolation drills built on it) fail with `declared doc missing: docs/reference.md`. Fixed by adding a docs/reference.md creation line to mk_cod_fixture (mirrors the registry order; not a test weakening — the fixture's contract is 'every declared doc present'). This is the known new-declared-doc / test-fixture parallel-edit pattern.
- 2026-06-12 [impl-pass] S000104: implementation complete. Phase 2 implementer-owned gates transitioned.
- 2026-06-12 [qa-smoke] S1 (AC-1): green — docs/reference.md exists and carries no work-item IDs (test -f + ! grep -E '[FSTD][0-9]{6}' exit 0).
- 2026-06-12 [qa-smoke] S2 (AC-2,AC-3,AC-4): green — merged registry declares docs/reference.md; no 'eleven' in spec/doc-spec.md; CLAUDE.md parenthetical includes docs/reference.md (exit 0).
- 2026-06-12 [qa-smoke] S3 (AC-6): green — 3-way seed byte-identity holds (--seed | cmp - spec/doc-spec.md && cmp spec/doc-spec.md templates/doc-spec-common.md, exit 0).
- 2026-06-12 [qa-smoke] S4 (AC-5): green — doc-spec.sh --validate OK schema_version=1; validate.sh PASS 0 errors / 0 warnings (Check 23 view-sync incl. docs/doc-general.md green).
- 2026-06-12 [qa-smoke] S5 (AC-7): green — config test 8b growth-safe + lists docs/reference.md (tests/cj-document-release-config.test.sh PASS, exit 0).
- 2026-06-12 [qa-smoke-summary] green: 5/5 non-manual rows green (0 manual rows pending).
- 2026-06-12 [qa-e2e-run-start] RUN_ID=20260612-194500-qa commit=292fbb7
- 2026-06-12 [qa-e2e] E2 (AC-1,AC-3): green — reference.md is a usable reference shelf: 4 grouped categories (Claude Code & agents / gstack / Conventions & standards / Tooling), 12 entries each with a one-line why, intro present, zero work-item IDs; spot-checks grounded (Keep-a-Changelog in collection-version.sh + CHANGELOG.md; shellcheck in validate.yml + windows-smoke.sh; gh pr merge/view/api in CLAUDE.md; is_semver x4 in skills-update-check; jq + skills-catalog.json in validate.sh; the 3 named workflows exist on disk); Human-docs table row present in seed at spec/doc-spec.md:31. [parent-inline]
- 2026-06-12 [qa-e2e] E1 (AC-8): green — the build dogfoods the three-stage doc audit; Step 8.6c /CJ_doc_audit verdicts docs/reference.md `satisfies` (Stage 2) + `no-drift` (Stage 3); no FINDING on reference.md (see [qa-audit] entry + AUDIT_FINDINGS block). [parent-inline]
- 2026-06-12 [qa-e2e-summary] green (0s subagent; 2 rows parent-inline; 0 deferred): both E2E rows green — E2 reference-shelf groundedness + E1 the audit dogfood verdict.
- 2026-06-12 [qa-audit] AUDITS=doc:ok,test:ok,spec_updates:test-spec-custom:none,doc-spec-custom:none (Step 8.6a-d; findings ride the green RESULT — checkpoint decision belongs to the orchestrator). doc audit: Stage1 6/6 PASS findings=0, Stage2 reference.md `satisfies` (all 5 requirement clauses met), Stage3 reference.md `no-drift` (12 entries grounded; eleven→twelve fully swept). test audit: Stage1 --validate OK + --check-coverage rows=69 findings=0, Stage2 5 rules satisfy + 2 touched units (config 8b, doc-spec-overlay) purpose truthful, Stage3 no-drift / no new surface class.
- 2026-06-12 [qa-pass] S000104 (user-story): green smoke + green E2E. Phase 2 gates transitioned.
- 2026-06-13T02:47:27Z [qa-audit-continue] operator checkpoint: doc:ok test:ok, all six stage counts 0, reference.md satisfies+no-drift (the hardened-audit dogfood); continued to doc-sync. No waiver.
