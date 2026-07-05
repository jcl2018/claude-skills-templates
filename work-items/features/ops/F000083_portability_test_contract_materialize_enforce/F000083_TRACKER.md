---
name: "Materialize + enforce the portability test contract (dream doc + topic subdir + detailed per-test docs + CI-push parity gate)"
type: feature
id: "F000083"
status: active
created: "2026-07-05"
updated: "2026-07-05"
repo: "E:/projects/claude-skills-templates/.claude/worktrees/peaceful-benz-04bccc"
branch: "claude/peaceful-benz-04bccc"
blocked_by: ""
---

<!-- Single-deliverable feature: the implementation is folded into the feature
     tracker (no child user-stories). The manifest requires only TRACKER +
     DESIGN + ROADMAP for a feature; the change is one coherent PR. -->

## Lifecycle

### Phase 1: Track

1. Working branch: `claude/peaceful-benz-04bccc` (Conductor worktree)
2. Scaffold work item directory and TRACKER.md
3. Distill `DESIGN.md` (problem, big decisions, risks) — from `templates/doc-DESIGN.md`
4. Scaffold `ROADMAP.md` (scope, non-goals, delivery) — from `templates/doc-ROADMAP.md`
5. Define acceptance criteria
6. Single-deliverable feature — implementation folded in (no child stories)

**Gates:**
- [x] Design captured in DESIGN.md (from the in-session design gate, in lieu of a `~/.gstack/projects/` office-hours doc)
- [x] Working branch created (`branch` field populated)
- [x] DESIGN + ROADMAP scaffolded
- [x] Acceptance criteria scoped
- [x] Single-deliverable feature (implementation folded in)

### Phase 2: Implement

1. Dream doc `docs/goals/portability.md` (WHAT — end goal + 3 properties)
2. Topic subdir `docs/tests/topics/portability/` (HOW — index + per-layer pages)
3. Enrich the 5 per-test front-door docs with assertion→property tables
4. Enforcement: `test-spec.sh --check-topic-docs` + `validate.sh` Check 31 + `test.sh` negative test
5. CI-push parity gate: `windows-smoke.sh` S5 (completeness) + S6 (fidelity)
6. Confirm Check 18 strict + tidy stale "advisory" wording
7. Declare all new docs in `spec/doc-spec-custom.md`; update registries + CLAUDE.md

**Gates:**
- [x] All deliverables implemented
- [x] Feature-level Todos reflect remaining coordination work

### Phase 3: Ship

1. Run `/CJ_personal-workflow check`
2. Verify targeted engines green (doc-spec, test-spec structure/topic-docs, negative test, scoped validate)
3. Run `/ship` — creates feature PR
4. STOP at PR (human review + merge)

**Gates:**
- [ ] `/CJ_personal-workflow check` passes
- [ ] Targeted engines green
- [ ] `/ship` — PR created
- [ ] STOP at PR (merge is a separate human step)

## Acceptance Criteria

- [ ] A maintainer can open ONE doc (`docs/goals/portability.md`) and learn the end goal ("another machine gets the same cj_skills as in this repo") + the three properties (completeness, fidelity, cross-platform parity).
- [ ] A topic subdir `docs/tests/topics/portability/` presents the tests grouped by layer (CI-push / CI-nightly / local-hook), each page listing "how to achieve" the dream + referencing the dream doc.
- [ ] Each of the 5 per-test docs carries a detailed `## What it proves` table (test case → assertion → property), not a one-line stub.
- [ ] `test-spec.sh --check-topic-docs` HARD-fails when an enrolled topic is missing its dream doc or a per-layer topic page; wired into `validate.sh` (Check 31) + a `test.sh` negative test.
- [ ] Completeness + fidelity gate on CI-push via fast `windows-smoke.sh` S5/S6 (no slow suite moved).
- [ ] Check 18 hard-fails on a portability finding (confirmed); engine header wording no longer says "advisory by default".
- [ ] `validate.sh` + `test.sh` (targeted) green; all new `docs/**` declared (no orphans).

## Todos

- [x] Dream doc + topic subdir + enriched per-test docs
- [x] `--check-topic-docs` engine + Check 31 + negative test
- [x] windows-smoke S5/S6
- [x] doc-spec-custom declarations + CLAUDE.md + index.md
- [ ] `/ship`

## Log

- 2026-07-05: Created. Materialize + enforce the portability topic's three test properties (end-goal dream doc, topic-by-layer subdir, detailed per-test tables, structural enforcement check, CI-push parity gate).

## PRs

## Files

- `docs/goals/portability.md` (new)
- `docs/tests/topics/portability/{index,CI-push,CI-nightly,local-hook}.md` (new)
- `docs/tests/infra/{CI-push,CI-nightly,local-hook}/portability-*.md` (enriched)
- `scripts/test-spec.sh` (`--check-topic-docs`)
- `scripts/validate.sh` (Check 31; Check 18 wording)
- `scripts/test.sh` (negative test)
- `scripts/windows-smoke.sh` (S5/S6)
- `scripts/cj-portability-audit.sh` (header wording)
- `spec/doc-spec-custom.md`, `spec/test-spec-custom.md`, `docs/tests/index.md`, `CLAUDE.md`

## Insights

- `docs/workflows/` is GENERATED (`workflow-spec.sh --render-docs`) + orphan-swept, so the hand-authored "dream doc" cannot live there — it lives at `docs/goals/portability.md`.
- Every `docs/**/*.md` must be declared in `spec/doc-spec-custom.md` (recursive orphan sweep, Check 15a) — 5 new docs → 5 new declaring rows.
- Check 18 was ALREADY strict-by-default at the validate gate (T000054, `PORTABILITY_STRICT:-1`); only the engine's header comment lagged.

## Journal
