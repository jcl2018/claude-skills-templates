---
type: design
parent: F000029
title: "Marker-pickup AUQ in cj_goal preambles (closes F000028 doc-sync loop) — Feature Design"
version: 1
status: Approved
date: 2026-05-30
author: chjiang
reviewers: []
---

<!-- A feature's cross-story design doc. Captures the PROBLEM, the SHAPE of
     the solution, the BIG DECISIONS with rationale, the RISKS, the
     DEFINITION OF DONE, and out-of-scope boundaries. Story-scope detail
     (SPEC/TEST-SPEC) lives on the nested user-stories — do
     not duplicate it here. For a filled-in example, see
     `work-items/features/F000004_work_copilot/F000004_DESIGN.md`. -->

## Problem

PR #177 (F000028) shipped the post-merge / post-rewrite git hooks that DROP a doc-sync marker at `~/.gstack/doc-sync-pending/<slug>.json` whenever `main` moves non-trivially. The hook works (verified live in the PR #177 dogfood pull — marker dropped with all 5 SPEC fields, idempotency confirmed). But **nothing reads the marker**. It accumulates silently until the operator manually runs `/document-release`. PR #177's deferred follow-up #1 explicitly identified this gap.

This feature closes the loop: the three `cj_goal` orchestrator skill preambles check for the marker, and on a hit, surface an AUQ asking the operator whether to invoke `/document-release` inline now, snooze for 24h, or skip this marker. The operator decides in one keystroke; the marker stops accumulating; docs stay synced; no separate "do I need to run /document-release?" question for the operator to remember.

## Shape of the solution

A single child user-story carries the full implementation: a new script `scripts/skills-doc-sync-check` (mirroring `scripts/skills-update-check`), identical 3-line preamble bash additions in each of the 3 cj_goal SKILL.md files, the AUQ-instruction prose block (also identical across all three), a flat-convention test file, and a CLAUDE.md sibling subsection. The pattern is exactly F000009's `skills-update-check` with one novel twist: the script's output drives an orchestrator AUQ (the script can't AUQ itself), so the SKILL.md instruction block must be explicit with a copy-paste AUQ template.

| Concern | User-story | Artifact |
|---------|-----------|----------|
| Script + preamble edits + tests + doc | S000062 | [S000062_marker_pickup_auq_impl/S000062_TRACKER.md](S000062_marker_pickup_auq_impl/S000062_TRACKER.md) |

## Big decisions

<!-- Choices that shape the feature, with rationale. Future readers need
     to know why this path over the rejected alternatives. -->

| # | Decision | Why |
|---|----------|-----|
| 1 | Approach C (new `scripts/skills-doc-sync-check` + per-preamble call) | Single evolution surface for detection logic; mirrors proven F000009 pattern; each preamble grows by 2–3 lines, not 20+; no new skill in catalog. Rejected Approach A (triplicate 10-line block in 3 SKILL.md files — 3 places to edit on logic change). Rejected Approach B (new `/CJ_doc_sync` skill — adds skill to catalog forever + extra invocation hop). **SUPERSEDED BY F000036 (v6.0.1):** the rejected "new skill in catalog" shape (Approach B variant) is reopened as `skills/CJ_document-release/` because it earns the catalog cost with a strict capability-superset the F000029 detection-only script can't expose: `--docs <subset>` parameterization (per-invocation doc filtering, best-effort via project-context block), halt-on-red contract (`[doc-sync-red]` / `[doc-sync-non-doc-write]` halt classes that propagate as orchestrator HALTs), and auto-commit of doc-only changes gated by a conservative whitelist. F000029's marker-AUQ stays as fallback for non-orchestrator paths (raw `git push`, manual `/ship` outside the cj_goal pipeline); F000036 fires inline in orchestrator paths (cj_goal_feature/defect/todo_fix Step 5.5). The two mechanisms layer; they do not fight. |
| 2 | No `prompted_session` field in cache (no PID dedup) | `$$` is not stable across SKILL.md bash fences — each fence is a fresh bash subprocess with a fresh PID (reviewer-flagged P0). Dedup achieved naturally via `--resolved` (deletes marker), `--snooze` (clock-based), `--skip` (head_sha-based). |
| 3 | Marker check fires BEFORE worktree creation (at operator cwd on main), then auto-commits doc-only changes | Prevents Step 1.9 isolation-gate `[feature-not-isolated]` HALT on dirty checkout. `/document-release` writes uncommitted README/ARCHITECTURE/CLAUDE.md changes; they must be folded into a commit before yielding to the worktree phase. |
| 4 | Branch-aware AUQ option ordering lives in SKILL.md prose, NOT in the script | Keeps script's single job ("is there a marker?") clean. Orchestrator detects branch via `git symbolic-ref --short HEAD`; on main, recommend "Run /document-release now"; on a feature branch / worktree, recommend "Snooze 1h" (Y on non-main would pollute the branch with wrong doc state). |
| 5 | Global snooze, not per-marker | Simpler. Operator who hits Snooze means "stop bugging me for a while," not "stop bugging me about this specific head_sha." Revisit if operator wants per-marker snooze. |

## Risks & open questions

<!-- What could go wrong, and what's still undecided. Each row should
     have a "Next check" naming who/when resolves it — otherwise it
     will rot. -->

| Risk / Question | Next check |
|-----------------|-----------|
| Should `/CJ_goal_todo_fix` also get the preamble call? | Deferred — out of scope; revisit after F000029 ships and dogfoods. |
| Should `/CJ_suggest` / `/CJ_system-health` also surface the marker? | Probably not (informational utilities, not work-starters); deferred. |
| Should snooze be per-marker (`<head_sha>`-keyed) or global? | Current design: global. Revisit if operator hits the case where Snooze silences a NEW marker they wanted to see. |
| Multiple repos with same basename collide on `~/.gstack/doc-sync-pending/<basename>.json` | Known limitation inherited from F000028's hook. Same edge case, not new. Deferred to a future cross-cutting fix. |
| Novel-pattern (script output → orchestrator AUQ) discoverability | The SKILL.md instruction block must be explicit and verbose enough that the orchestrator never improvises. QA covers AUQ surfaces correctly in real invocation. |

## Definition of done

<!-- Objective, measurable criteria for "shipped." Not aspirations. A
     reviewer should be able to verify each item without asking the
     author. -->

- [ ] `scripts/skills-doc-sync-check` exists, is executable, passes shellcheck.
- [ ] All 3 cj_goal SKILL.md preambles contain the bash block + the AUQ-instruction prose (identical across all three modulo skill-name comment).
- [ ] `tests/skills-doc-sync-check.test.sh` covers 8 cases (a-h from design's Success Criteria).
- [ ] `./scripts/validate.sh` passes (0 errors, 0 warnings).
- [ ] `./scripts/test.sh` passes.
- [ ] CLAUDE.md "Doc-sync check mechanism (F000028 follow-up)" sibling subsection added below "Update-check mechanism (F000009)".
- [ ] CHANGELOG entry added for F000029.
- [ ] Live dogfood: a `/cj_goal_feature` invocation against a repo with a planted marker surfaces the AUQ with all 3 marker fields populated.

## Not in scope

<!-- Explicit non-goals. Prevents scope creep and gives reviewers an
     unambiguous boundary. -->

- `/CJ_goal_todo_fix` preamble — same drift-cleanup logic applies but excluded from this PR to keep scope minimal.
- `/CJ_suggest` / `/CJ_system-health` preamble — informational utilities, not work-starters; doesn't fit the trigger surface.
- Per-marker snooze (head_sha-keyed) — current design is global snooze; revisit if operator wants finer control.
- Cross-repo basename collision fix — inherited limitation from F000028's hook; not introduced by this PR.
- Changes to F000028's hook or marker shape — strictly downstream consumer.

## Pointers

<!-- Cross-links to related artifacts: parent tracker, roadmap,
     upstream sources, related features/defects. Use relative paths
     from the feature directory. -->

- Parent tracker: [F000029_TRACKER.md](F000029_TRACKER.md)
- Roadmap: [F000029_ROADMAP.md](F000029_ROADMAP.md)
- Child story: [S000062_marker_pickup_auq_impl/S000062_TRACKER.md](S000062_marker_pickup_auq_impl/S000062_TRACKER.md)
- Upstream design: `~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-cj-feat-20260530-222955-29095-design-20260530-223418.md`
- Predecessor feature: [../F000028_doc_sync_post_merge_hook/F000028_TRACKER.md](../F000028_doc_sync_post_merge_hook/F000028_TRACKER.md) (hook that drops the markers)
- Architectural precedent: `scripts/skills-update-check` (F000009 — `skills-update-check` mechanism)
