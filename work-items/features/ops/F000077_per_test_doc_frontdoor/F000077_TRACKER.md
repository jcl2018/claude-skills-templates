---
name: "Per-test category docs as the authoritative What/How/Why front door, enforced generally"
type: feature
id: "F000077"
status: active
created: "2026-07-03"
updated: "2026-07-03"
repo: "E:/projects/claude-skills-templates/.claude/worktrees/eloquent-cohen-54b476"
branch: "claude/eloquent-cohen-54b476"
blocked_by: ""
---

<!-- Prerequisite: Before scaffolding this work item, run /office-hours to
     produce a design plan in ~/.gstack/projects/. Distill that plan into
     DESIGN.md during Phase 1 below. -->

## Lifecycle

### Phase 1: Track

1. Create working branch: `git checkout -b feat/per_test_doc_frontdoor`
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

- [ ] A GENERAL what/how/why rule for per-test docs lives in the portable `spec/test-spec.md`, added by EDITING the existing category-axis section (NOT a duplicate rule) and byte-identical to the `--seed` heredoc in `scripts/test-spec.sh` (`tests/test-spec.test.sh` `cmp -s` green).
- [ ] The `--seed-docs` stub template in `scripts/test-spec.sh` renders the three-section shape (What it is / How to run / Explanation + family-doc cross-link); idempotent present-⇒-skip preserved.
- [ ] All 7 existing category docs (`validate`, `suite`, `test-deploy`, `windows`, `windows-deploy`, `goal-task-eval`, `e2e-local`) carry filled What it is / How to run / Explanation sections, each cross-linking its family doc(s).
- [ ] `test-spec.sh --check-structure` gains a content check (gated on the `categories:` axis) that each per-test doc contains the three sections; findings-are-the-product, inactive when no categories axis.
- [ ] `/CJ_test_audit` runs the structure content check in Stage 1 and judges the docs' what/how/why truthfulness against the test in Stage 2.
- [ ] `/CJ_test_run <name>` surfaces/links the per-test doc's How-to-run so run + doc agree.
- [ ] `spec/doc-spec-custom.md` category-doc rows (72-78) `Requirement` cells updated to include the what/how/why sections; family-doc rows (63-70) unchanged; `docs/tests/index.md` row unchanged.
- [ ] `CJ_test_audit` + `CJ_test_run` SKILL.md/USAGE.md + catalog descriptions describe the enforced per-test-doc-content model; `CLAUDE.md` synced via doc-sync.
- [ ] `validate.sh` green (Checks 15/15a, 24, 26 unaffected), full `test.sh` green (ubuntu CI authoritative), shellcheck clean.

## Todos

<!-- Actionable items for this feature. Break into child tasks for
     large features. -->

- [ ] Edit the portable seed category-axis section in BOTH `spec/test-spec.md` and the `scripts/test-spec.sh --seed` heredoc in lockstep (keep `cmp -s`).
- [ ] Enrich the `--seed-docs` stub template to the three-section shape.
- [ ] Fill What/How/Why into the 7 existing category docs with family-doc cross-links.
- [ ] Add the `--check-structure` content check (extend check (d) or add (f)); wire into `/CJ_test_audit` Stage 1 + Stage 2.
- [ ] Surface the per-test doc How-to-run in `/CJ_test_run <name>`.
- [ ] Update `spec/doc-spec-custom.md` category-doc row requirements.
- [ ] Update both cj_test skills' SKILL.md/USAGE.md + catalog descriptions.
- [ ] Add `tests/test-spec.test.sh` cases for the content check + enriched `--seed-docs`; keep `--seed` byte-identity + family `--render-docs`/Check-26 cases green.

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-07-03: Created. Make `docs/tests/<category>/<name>.md` the authoritative What/How/Why front door per test, enforced by a GENERAL rule in the portable `spec/test-spec.md` and checked by the cj_test skills; family docs kept as linked units-detail.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. Populated during Track phase, updated during Implement. -->

- `spec/test-spec.md` (edit the category-axis section — general rule)
- `scripts/test-spec.sh` (`--seed` heredoc lockstep edit; `--seed-docs` stub template; `--check-structure` content check)
- `docs/tests/CI-push/validate.md`, `docs/tests/CI-push/suite.md`, `docs/tests/CI-push/test-deploy.md`, `docs/tests/CI-push/windows.md`, `docs/tests/CI-nightly/windows-deploy.md`, `docs/tests/workflow/goal-task-eval.md`, `docs/tests/workflow/e2e-local.md` (the 7 category docs — exact category subdirs confirmed during implement)
- `spec/doc-spec-custom.md` (category-doc row requirement updates)
- `skills/CJ_test_audit/SKILL.md`, `skills/CJ_test_audit/USAGE.md`, `skills/CJ_test_run/SKILL.md`, `skills/CJ_test_run/USAGE.md`, `skills-catalog.json`
- `tests/test-spec.test.sh`
- `CLAUDE.md` (via doc-sync)

## Insights

<!-- Non-obvious findings worth remembering. Design decisions,
     trade-offs, patterns discovered. -->

- The "retire family docs" draft scored 5/10 with a dealbreaker (no categories→units join key; orphaned ci/hook units; a 2-feature schema change). Re-scoping to KEEP the family render removes those dealbreakers by construction — this ships the authoritative/enforced/portable per-test docs without the risky re-org.
- The general rule is added by EDITING the existing category-axis prose that ALREADY exists in both `spec/test-spec.md` and the `--seed` heredoc — appending a duplicate rule would break the `cmp -s` byte-identity assertion in `tests/test-spec.test.sh`.
- `--seed-docs` is idempotent (present ⇒ skip), so the 7 already-seeded stubs will NOT auto-upgrade; their content must be filled by a one-time authored pass while the template is updated for future tests.
- No schema change, no join key, no Check 26 rewrite — the family render (`--render-docs`) and its freshness gate stay untouched, keeping doc-spec Checks 15/15a green with no row churn (family rows unchanged, category rows get requirement-cell updates only).

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

- [decision] Approach B (category docs are the enforced front door; keep family render) chosen over A (retire family render — review dealbreaker) and C (rule + check only, no stub enrichment — leaves stubs thin). Summary: enforce a what/how/why content template on the category-test docs as a GENERAL portable rule; keep the family docs as the linked units-detail drill-down.
- [decision] The requirement is a GENERAL rule in `spec/test-spec.md` (propagates to consumers on their next contract seed), not a repo-custom overlay rule. Summary: designing for every adopting repo, not just this one.
- [decision] Section headings proposed as `## What it is` / `## How to run` / `## Explanation` (the content check keys off these). Summary: confirm exact wording during implement; the check is heading-anchored.
- [decision] Nothing is re-categorized: `eval`'s front door stays `docs/tests/workflow/goal-task-eval.md` (its declared category per F000075), cross-linking `docs/tests/eval.md` — no test scripts move under Approach B.
