---
type: design
parent: S000069
title: "CJ_document-release skill + cj_goal orchestrator inline wiring — implementation design"
version: 1
status: Draft
date: 2026-06-02
author: chjiang
reviewers: []
---

<!-- A user-story design doc. (For an atomic user-story, this is a
     brief link-to-parent stub — the parent F000036_DESIGN.md owns the full
     problem-framing + alternative analysis.) -->

## Problem

F000028+F000029 wired the doc-sync loop via post-merge marker + next-session AUQ. That loop works but has two gaps for the cj_goal orchestrator family: (1) drift window (AUQ fires on next session, not in the shipping cycle that caused the drift); (2) no per-doc parameterization (the marker-AUQ runs `/document-release` with no args; all-or-nothing). This story implements the better-fit shape: a new workbench skill `CJ_document-release` that wraps upstream `/document-release` with a `--docs` flag, halt-on-red contract, and auto-commit-doc-only behavior. All 3 cj_goal orchestrators auto-invoke it inline between QA pass and `/ship` — doc updates fold into the same code PR. See parent `F000036_DESIGN.md` for the full Approach A/B/C analysis + F000029 BD#1 supersession rationale.

## Shape of the solution

Atomic implementation across 16 files in one PR (one commit, staged together for the pre-commit hook):

1. `skills/CJ_document-release/SKILL.md` (NEW) — wrapper skill, ~80-120 lines.
2. `skills/CJ_document-release/USAGE.md` (NEW) — 5 required H2 sections per F000032.
3. `skills-catalog.json` (MODIFIED) — new entry; `portability: workbench`; `depends.skills: ["document-release"]`.
4. `doc/SKILL-CATALOG.md` (MODIFIED) — new `### CJ_document-release` section with `(phase-step in /CJ_goal_feature chain)` tag.
5–10. 3 cj_goal pipeline.md edits (Step 5.5 insertion) + 3 cj_goal SKILL.md edits (halt-taxonomy 2 new rows).
11–12. 2 new test files (cj-document-release.test.sh + cj-goal-doc-sync-wiring.test.sh).
13. `scripts/test.sh` (MODIFIED) — wire both test files in.
14. `work-items/features/ops/F000029_marker_pickup_auq/F000029_DESIGN.md` (MODIFIED) — BD#1 "SUPERSEDED BY F000036" annotation in-place.
15–16. `VERSION` + `CHANGELOG.md` — PATCH bump (5.0.19 → 6.0.1) + user-forward entry.

## Big decisions

| # | Decision | Why |
|---|----------|-----|
| 1 | Single user-story (no sub-tasks) | Atomic under pre-commit hook. Same shape as F000032 (S000065), F000033 (S000066), F000034 (S000067). Splitting adds bookkeeping without splitting risk. Check 13 (USAGE.md presence) + Check 15b (per-skill catalog completeness) would block intermediate-state commits anyway. |
| 2 | `[doc-sync-red]` vs `[doc-sync-non-doc-write]` are separate halt classes | Different diagnostic surfaces. `[doc-sync-red]` = `/document-release` itself failed (audit error, mid-write). `[doc-sync-non-doc-write]` = upstream succeeded but wrote outside whitelist (upstream-misbehaved). Separation gives halt-journal clarity. |
| 3 | Project-context block to `/document-release` is documentation-only, not programmatic | We don't modify upstream `/document-release`. The block tells the skill prose to filter; if upstream honors it, filtering works; if upstream audits everything anyway, CJ_document-release auto-commits whatever's produced. Best-effort filter, not enforced. |
| 4 | Doc-only auto-commit whitelist: `^(README\|CHANGELOG\|CLAUDE\|ARCHITECTURE)\.md$` + `^doc/.+\.md$` + `^templates/doc-.*\.md$` | Conservative. Prevents stealth code edits via doc-sync surface. Anything outside → HALT. The `templates/doc-*` extension covers F000032/F000033/F000034 template-doc convention. |
| 5 | Identical Step 5.5 across all 3 cj_goal orchestrators (modulo `<verb>` in resume_cmd) | Uniform behavior across the family. Future per-verb divergence would mean adding args to the skill invocation, not duplicating skill logic. |
| 6 | F000029 BD#1 annotation appended in-place, not in separate "## Supersessions" section | Readers scanning the BD#1 row see "SUPERSEDED BY F000036" immediately. Audit trail via git blame. |
| 7 | Hand-written catalog section under Phase-step skills grouping with explicit tag | Per F000034 precedent. Phase-step skills get tag (not chart) per F000034 Open Question #1 resolution. |
| 8 | No new validate.sh checks | Existing Check 13/14/15 auto-cover CJ_document-release once it's in skills-catalog.json with `status != "deprecated"` + `files: [...SKILL.md]`. Audit set grows 11 → 12. |
| 9 | `portability: workbench` (not `standalone`) | This skill depends on workbench-specific conventions (CLAUDE.md tracked-doc/ manifest, cj_goal orchestrators) and isn't useful in a standalone target repo. |

## Risks & open questions

| Risk / Question | Next check |
|-----------------|-----------|
| 16 files in one PR is a wide diff | Mitigation: largely template + 3-way symmetric edits. Diff review focuses on "did the 3-way edits stay symmetric." tests/cj-goal-doc-sync-wiring.test.sh asserts the symmetry mechanically. |
| Atomic-commit ordering with pre-commit hook | Same constraint as F000032+F000033+F000034: stage all 16 files once. Intermediate state would fire Check 13 (USAGE.md presence) or Check 15b (catalog section completeness). |
| `--docs` parsing edge cases (unknown values, case sensitivity, comma-list with whitespace) | Resolution: case-insensitive; unknown values warn + skip (don't halt); whitespace trimmed. Loud warn is enough for operator typos. |
| Project-context block to `/document-release` doesn't enforce filter | Best-effort by design; if upstream audits everything, CJ_document-release still auto-commits whatever's produced. Filter is operator intent, not gate. |
| `/document-release`'s `--pr-body` output integration when running BEFORE /ship | v1 best-effort. Rely on `/document-release`'s existing behavior; `/ship` picks up at PR-construction time. Fix in follow-up if integration breaks. |
| Test file assertion shape | Per parent design Step 8: cj-document-release.test.sh ≥10 assertions; cj-goal-doc-sync-wiring.test.sh ≥5 assertions. Smoke-shape (file content grep) is sufficient; integration shape (actually running the skill) is post-merge dogfood. |
| Halt-marker ordering in halt-taxonomy tables | Resolution: after qa-red row, before ship-declined row. The doc-sync phase sits between QA and ship; the table order should mirror the pipeline order. tests/cj-goal-doc-sync-wiring.test.sh asserts the ordering. |
| F000029 BD#1 annotation triggers F000030 retired-skill drift check | No — F000029 isn't deprecated, just superseded on one decision. Check 15 audits SKILL-CATALOG.md completeness; the F000030 retired-skill check only fires for `status: deprecated` entries. F000029 stays `active`. |

## Definition of done

- [ ] All acceptance criteria from S000069_TRACKER.md verified.
- [ ] `./scripts/validate.sh` + `./scripts/test.sh` both exit 0.
- [ ] PR opened against main via /ship; /CJ_goal_feature stops at PR per design.

## Not in scope

- Upstream `/document-release` modification.
- `--skip-docs` negation flag (v2).
- F000029 deprecation (coexistence).
- /land-and-deploy in this PR (separate human step).
- README.md per-skill chart column (F000034 deferred).
- work-copilot/ analog skill.
- Per-marker snooze of CJ_document-release outputs.
- Auto-generated catalog entry.
- Distinguishing real vs cosmetic doc edits (operator owns content; Check 15 owns structure).

## Pointers

- Parent feature design: [../F000036_DESIGN.md](../F000036_DESIGN.md)
- Parent feature tracker: [../F000036_TRACKER.md](../F000036_TRACKER.md)
- Parent feature roadmap: [../F000036_ROADMAP.md](../F000036_ROADMAP.md)
- SPEC: [S000069_SPEC.md](S000069_SPEC.md)
- TEST-SPEC: [S000069_TEST-SPEC.md](S000069_TEST-SPEC.md)
- Source design doc: `~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-cj-feat-20260602-011228-doc-release-design-20260602-012718.md`
- F000028 (PR #177, v5.0.8) — post-merge hook + doc-sync-pending marker.
- F000029 (PR #178, v5.0.9) — `scripts/skills-doc-sync-check` + preamble AUQ; BD#1 SUPERSEDED by this PR; marker-AUQ stays as fallback.
- F000032 (PR #186, v5.0.17) — USAGE.md + Check 13; same audit predicate reused.
- F000033 (PR #188, v5.0.18) — Check 14 (USAGE.md freshness); same predicate.
- F000034 (PR #189, v5.0.19) — doc/SKILL-CATALOG.md + tracked-doc/ manifest; CJ_document-release gets a section here.
