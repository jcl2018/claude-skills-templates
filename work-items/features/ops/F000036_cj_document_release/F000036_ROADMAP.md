---
type: roadmap
parent: F000036
title: "CJ_document-release skill + cj_goal orchestrator inline wiring — Roadmap"
date: 2026-06-02
author: chjiang
status: Draft
---

<!-- A feature's roll-up roadmap — merges what was previously in feature-summary
     + milestones. Captures scope/non-goals (the feature's identity), decomposition
     (which user-stories carry the work), and delivery timeline (when each piece
     ships). -->

## Scope

Build a new workbench skill `CJ_document-release` that wraps upstream `/document-release` with a `--docs <subset>` flag for per-invocation doc subset, a halt-on-red contract, and auto-commit of doc-only changes. Wire all 3 cj_goal orchestrators (`/CJ_goal_feature`, `/CJ_goal_defect`, `/CJ_goal_todo_fix`) to auto-invoke it inline between QA pass and `/ship` so doc updates fold into the same code PR. Add tests for both the skill and the orchestrator wiring. Annotate F000029 BD#1 with SUPERSEDED BY F000036 in-place (F000029's marker-AUQ stays as fallback for non-orchestrator paths). Workbench-internal — no upstream skill changes; no deployment surface beyond `skills-deploy install`.

## Non-Goals

- Upstream `/document-release` modification — not ours to edit. Integration via Skill tool with project-context priming (memory `project_workbench_auto_deploy_unsafe`).
- `--skip-docs` negation flag — v1 only positive `--docs` subset; deferred.
- F000029 deprecation — coexistence with marker-AUQ for non-orchestrator paths. F000029 stays installable and functional.
- `/land-and-deploy` step in this PR — /CJ_goal_feature stops at PR by design.
- README.md per-skill workflow-chart column — F000034 deferred this.
- work-copilot/ analog skill — workbench-only scope.
- Behavior change for non-cj_goal callers of `/document-release` — they continue to call upstream directly.
- Per-marker snooze of CJ_document-release outputs — single global halt-on-red is sufficient.
- Auto-generated catalog entry — hand-written per F000034 precedent.

## Success Criteria

- [ ] `skills/CJ_document-release/SKILL.md` exists with valid YAML frontmatter (name, description, version, allowed-tools: Bash, Read, Glob, Grep, Skill).
- [ ] `skills/CJ_document-release/USAGE.md` exists with all 5 required H2 sections.
- [ ] `skills-catalog.json` has the CJ_document-release entry with `status: experimental`, `portability: workbench`.
- [ ] `doc/SKILL-CATALOG.md` has the `### CJ_document-release` section with `(phase-step in /CJ_goal_feature chain)` tag.
- [ ] All 3 cj_goal `pipeline.md` files contain a "Step 5.5: Doc-sync" subsection inserted between QA pass and `/ship`.
- [ ] All 3 cj_goal `SKILL.md` halt-taxonomy tables contain both new rows (`[doc-sync-red]` + `[doc-sync-non-doc-write]`).
- [ ] `tests/cj-document-release.test.sh` covers: skill files exist, frontmatter parses, USAGE.md 5 sections, halt markers grep, branch refusal, clean-tree refusal, `--docs` parsing.
- [ ] `tests/cj-goal-doc-sync-wiring.test.sh` covers: all 3 pipeline.md files have Step 5.5, all 3 SKILL.md halt-taxonomy tables have both new rows, row ordering correct.
- [ ] `scripts/test.sh` wires both test files; full suite passes.
- [ ] `./scripts/validate.sh` exits 0 / 0 errors / 0 warnings (audit set grows from 11 to 12 skills, includes CJ_document-release).
- [ ] `./scripts/test.sh` exits 0.
- [ ] `work-items/features/ops/F000029_marker_pickup_auq/F000029_DESIGN.md` BD#1 has the "SUPERSEDED BY F000036 (v6.0.1)" annotation.
- [ ] CHANGELOG entry in user-forward voice naming F000036; VERSION PATCH-bumped to 6.0.1 via `./scripts/check-version-queue.sh`.
- [ ] PR opened against main via `/ship`. PR body notes F000028+F000029+F000034 lineage + F000029 BD#1 supersession.
- [ ] Manual smoke A (post-merge): invoke `/CJ_document-release --docs README` from a feature branch with a stale README; skill runs, README updates auto-commit, success summary printed.
- [ ] Manual smoke B (post-merge): invoke `/CJ_goal_defect "synthetic doc-drift bug"` against a fixture that modifies a code file mentioned in README; verify Step 5.5 fires after QA, README drift auto-commits, PR diff includes BOTH code fix AND README update.

## Decomposition

| User-Story | Title | Status |
|-----------|-------|--------|
| [S000069](S000069_cj_document_release_skill_impl/S000069_TRACKER.md) | CJ_document-release skill + cj_goal orchestrator inline wiring — implementation (SKILL.md + USAGE.md + catalog entry + doc/SKILL-CATALOG.md section + 3 pipeline.md edits + 3 SKILL.md halt-taxonomy edits + 2 tests + scripts/test.sh wiring + F000029 BD#1 annotation + VERSION + CHANGELOG) | Open |

## Delivery Timeline

| # | Milestone | Target Date | Status | Owner | Notes | Blocked By |
|---|-----------|-------------|--------|-------|-------|------------|
| 1 | Ship S000069 (skill + wiring + tests + supersession + VERSION + CHANGELOG) | 2026-06-02 | Not Started | chjiang | One atomic PR via /ship against main; /CJ_goal_feature stops at PR | — |
| 2 | After merge: live dogfood A — `/CJ_document-release --docs README` from a stale-README feature branch | 2026-06+ | Not Started | chjiang | Skill respects `--docs` best-effort; auto-commits doc-only changes; success summary printed | #1 |
| 3 | After merge: live dogfood B — `/CJ_goal_defect "synthetic doc-drift bug"` end-to-end | 2026-06+ | Not Started | chjiang | Step 5.5 fires after QA; doc drift auto-commits; PR diff includes BOTH code + doc updates | #1 |
| 4 | Observation: pay attention to Step 5.5 friction (does it feel necessary or like overhead?) | 2026-06+ | Not Started | chjiang | If friction surfaces, consider follow-up: workbench-side helper pre-scanning for `file_path:line_no` references in source vs docs | #2, #3 |

### Delivery History

<!-- Backward-looking record: PR links, merge dates, version bumps after ship.
     Append-only. -->

- 2026-06-02: Created — F000036 scaffolded from /office-hours design doc (`chjiang-cj-feat-20260602-011228-doc-release-design-20260602-012718.md`).

## Dependency Graph

<!-- Visual representation of milestone ordering. Format: #N description --> #M
     description (arrow = "blocks"). Keep in sync with the Blocked By column. -->

```
(no upstream stacking — independent F-ID after F000034 merged at origin/main HEAD 006ffe3)
                                  |
                                  v
#1 Ship S000069 (skill + 3-way orchestrator wiring + tests + BD#1 supersession + VERSION + CHANGELOG)
                                  |
                                  v
                            (PR review = architecture gate; human merge)
                                  |
                  +---------------+---------------+
                  v                               v
#2 Live dogfood A: /CJ_document-release      #3 Live dogfood B: /CJ_goal_defect
   --docs README from feature branch           "synthetic doc-drift bug" end-to-end
                  |                               |
                  +---------------+---------------+
                                  v
#4 Observation: Step 5.5 friction signal (necessary vs overhead?)
```

## Open Questions

<!-- Questions still being decided. -->

| Question | Next check |
|----------|-----------|
| Should `/CJ_goal_todo_fix --quiet` (cron) suppress `[doc-sync-red]` halt marker? | No — `--quiet` only suppresses summary banners + AUQs, not halt-on-red contracts. Cron operator reads halt journal at convenience. |
| Should v1 accept `--skip-docs` negation flag? | No — v1 only positive `--docs` subset; deferred to v2 if operator demand surfaces. |
| Should doc-only whitelist also include `*.md` files anywhere in repo? | No — v1 whitelist is `README\|CHANGELOG\|CLAUDE\|ARCHITECTURE.md` + `doc/.+\.md` + `templates/doc-.*\.md`. Conservative > permissive (avoid false-positive halt). Extend if operator hits the false-positive in dogfood. |
| Should F000029_DESIGN.md BD#1 supersession be in-place edit or appended "## Supersessions" section? | In-place edit — readers scanning the BD#1 row see the supersession immediately. Audit trail preserved via git blame. |
| Should `--docs` parsing be case-sensitive? | No — operator typos are common; case-insensitive parsing. |
| What about `/document-release`'s existing `--pr-body` output when running BEFORE /ship? | v1 best-effort: rely on `/document-release`'s existing behavior; `/ship` picks up at PR-construction time. If integration breaks, fix in follow-up (would surface in live dogfood). |
