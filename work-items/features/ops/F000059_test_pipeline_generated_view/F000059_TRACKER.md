---
name: "test-pipeline — a generated, check-level human view of the verification surface"
type: feature
id: "F000059"
status: active
created: "2026-06-10"
updated: "2026-06-10"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "claude/hardcore-napier-1efc3f"
blocked_by: ""
---

<!-- Prerequisite: Before scaffolding this work item, run /office-hours to
     produce a design plan in ~/.gstack/projects/. Distill that plan into
     DESIGN.md during Phase 1 below. -->

## Lifecycle

### Phase 1: Track

1. Create working branch: `git checkout -b feat/test_pipeline_generated_view`
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

- [ ] `./scripts/validate.sh` and `./scripts/test.sh` fully green, including: extended Check 23 covering the third generated view (`docs/test-pipeline.md`); new Check 24 (coverage cross-check) HARD with a clean baseline — the `tests/cj-goal-feature-smoke.test.sh` silent-skip triage resolved (registered or retired); config-test 13 seed byte-identity passing with the grown 11-doc seed.
- [ ] `docs/test-pipeline.md` is fully GENERATED (`scripts/test-pipeline.sh --render` via `scripts/generate-doc-views.sh`), idempotent under re-render, opens with the per-family summary table before the first `## ` heading, contains ZERO work-item IDs, and enumerates at land time: all 25 live numbered validate.sh check IDs across BOTH namespaces (including the new Check 24 itself; Check 15 as one row) + the 2 warning checks, every registered test sub-suite + the 15 inline test.sh families, the 3 standalone suites (test-deploy, eval, windows-smoke), the 3 CI workflows, the 2 git hooks, and the 3 ratchets — each with disposition + trigger.
- [ ] The four drift drills pass in `tests/test-pipeline-spec.test.sh` (temp-dir isolated, never mutating the tree): (a) fake `=== Check 99` banner → reverse-flagged; (b) broken registry anchor → forward-flagged; (c) hand-edited generated view → Check 23-extension diff fails; (d) removed test.sh runner block → forward-flags the orphaned test row (the silent-skip catch).
- [ ] The doc-spec registry declares BOTH new docs (`docs/test-pipeline.md` common/human-doc/front_table-required; `spec/test-pipeline.md` custom/operational); doc views regenerate (doc-general gains the common row, doc-custom gains the spec row); the Common seed carries eleven general docs in lockstep copies (templates/doc-spec-common.md + the scripts/doc-spec.sh heredoc byte-identical, spec/doc-spec.md marker block in sync) with a mechanism-neutral seed requirement string.
- [ ] A first-time reader can answer "what protects this repo, where, and when" from docs/test-pipeline.md's summary table alone in under a minute.

## Todos

<!-- Actionable items for this feature. Break into child tasks for
     large features. -->

- [ ] S000101: full build — stray-test triage (Step 0), spec/test-pipeline.md registry (~65 rows from the inventory appendix), scripts/test-pipeline.sh parser (--validate / --list-units / --render + rendered-field ID-lint), generate-doc-views.sh third output, validate.sh Check 23 extension + new hard Check 24, doc-spec registry entries + 3-copy seed lockstep (10 → 11) + view regen, tests/test-pipeline-spec.test.sh + test.sh registration + drift drills, self-inclusion loop-back rows, CLAUDE.md / architecture.md secondary-doc sweep
- [ ] Coordinate: single-commit atomicity — doc + registry entries + seed copies + heredoc + regenerated views land together (Checks 15a + 23 fail half-states at the pre-commit hook)
- [ ] Coordinate: no tree mutations while `scripts/test.sh` runs (its EXIT restore-trap clobbers concurrent edits)
- [ ] Coordinate: new scripts/test-pipeline.sh passes the stricter apt shellcheck in CI (SC2015/SC2016 class), not just local 0.11

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-06-10: Created. docs/test-pipeline.md — a generated, check-level human view of the repo's verification surface (validate checks, test families, standalone suites, CI workflows, hooks, ratchets), built from a 4th spec-registry member (spec/test-pipeline.md) with a hard view-sync (Check 23 extension) and a hard coverage cross-check (new Check 24).

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. Populated during Track phase, updated during Implement. -->

- spec/test-pipeline.md (new — 4th spec-registry member: prose + fenced yaml registry of verification units)
- scripts/test-pipeline.sh (new — parser: --validate / --list-units / --render, gate-spec.sh idiom)
- docs/test-pipeline.md (new — fully generated human view)
- scripts/generate-doc-views.sh (modified — third output, skip-when-absent)
- scripts/validate.sh (modified — Check 23 extension + new Check 24)
- spec/doc-spec.md (modified — two registry entries + Common-block prose counts)
- templates/doc-spec-common.md (modified — seed lockstep, 10 → 11)
- scripts/doc-spec.sh (modified — heredoc lockstep + header-comment count)
- docs/doc-general.md, docs/doc-custom.md (regenerated)
- tests/test-pipeline-spec.test.sh (new — parser round-trip + drift drills)
- scripts/test.sh (modified — register new sub-suite + Check-23-extension mirror)
- tests/cj-goal-feature-smoke.test.sh (triaged — register or retire)
- CLAUDE.md, docs/architecture.md (modified — secondary-doc sweep)

## Insights

<!-- Non-obvious findings worth remembering. Design decisions,
     trade-offs, patterns discovered. -->

- The repo's map of its own defenses becomes a defense itself: the doc is GENERATED from a machine registry with a HARD view-sync check and a HARD coverage cross-check, so "validate.sh gained a check the doc doesn't list" and "the doc lists a check that no longer exists" are mechanical pre-commit/CI failures, not reviewer judgment calls.
- Live silent-skip instance found at design time: tests/*.test.sh files are hand-registered in test.sh (not glob-discovered), and tests/cj-goal-feature-smoke.test.sh exists on disk with ZERO runner references — it silently never runs. The new coverage cross-check turns that comment-discipline into a check; this stray file is its first catch.
- Check 24 ships HARD from day one (no advisory soak): the advisory-soak convention existed for checks inheriting baselines they didn't control; here the same PR authors the full registry, so the baseline is clean by construction and any finding is new by definition.
- Inventory irregularities every implementation must honor: "Error check 11" and "Check 11" are two DISTINCT live checks sharing a numeral (namespace prefixes preserved); sub-IDs 15a/15b exist only as bare comments (Check 15 is ONE registry row); Check 17 is echo-anchored only; Check 12 is retired and must not be resurrected by naive extraction; extraction regexes are written `[0-9]+[a-z]?` with the namespace prefix kept.
- We buy structural sync, not meaning sync: SEMANTIC drift (a check's behavior changes under a stable banner while its one-line purpose rots) deliberately stays with the advisory agent-judged registered-doc audit.

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->
- 2026-06-10T18:25:58Z [feature-pr-opened] F000059 v6.0.64 PR #259
  pr_url=https://github.com/jcl2018/claude-skills-templates/pull/259
