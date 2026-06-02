---
type: design
parent: F000036
title: "CJ_document-release skill + cj_goal orchestrator inline wiring — Feature Design"
version: 1
status: Draft
date: 2026-06-02
author: chjiang
reviewers: []
---

<!-- A feature's cross-story design doc. Captures the PROBLEM, the SHAPE of
     the solution, the BIG DECISIONS with rationale, the RISKS, the
     DEFINITION OF DONE, and out-of-scope boundaries. Story-scope detail
     (SPEC/TEST-SPEC) lives on the nested user-stories — do
     not duplicate it here. -->

## Problem

F000028 (PR #177, v5.0.8) + F000029 (PR #178, v5.0.9) wired the doc-sync loop. F000028's post-merge git hook drops a marker at `~/.gstack/doc-sync-pending/<slug>.json` when main moves non-trivially; F000029's `skills-doc-sync-check` script + 3 cj_goal preamble snippets surface a `DOC_SYNC_PENDING` AUQ on next session asking whether to run `/document-release`, snooze, or skip. D000026 (v5.0.14) made the AUQ recommendation branch-aware.

That loop works, but it has two gaps for the cj_goal orchestrator family (`/CJ_goal_feature`, `/CJ_goal_defect`, `/CJ_goal_todo_fix`):

1. **Drift window.** F000029's AUQ only fires on the NEXT `/CJ_goal_*` session. If the operator's next cj_goal invocation is hours or days away, doc drift sits on main until then. The marker lifetime decouples doc-sync from the shipping cycle that produced it.
2. **No per-doc parameterization.** F000029's marker-AUQ runs `/document-release` with no args — the operator can't say "this PR only touched README; skip the ARCHITECTURE audit." It's all-or-nothing. For small surgical PRs (TODO drains, single-doc edits), this means either the full audit runs (overhead) or the operator declines/snoozes and drift accumulates.

This feature builds a better-fit shape for the cj_goal pipeline specifically: a new workbench skill `CJ_document-release` that wraps upstream `/document-release` with a `--docs <subset>` flag, halt-on-red contract, and auto-commit of doc-only changes. The orchestrators auto-invoke it BEFORE `/ship` on the feature branch, after QA passes — doc updates fold into the same code PR. Drift closes to ~minutes (atomic with the code PR, no second auto-deploy cycle). F000029's marker-AUQ stays as a fallback for paths that bypass the orchestrator (raw `git push`, manual `/ship`).

## Shape of the solution

One atomic PR. Sixteen files touched:

1. `skills/CJ_document-release/SKILL.md` (NEW) — wrapper skill with arg parsing (`--docs`), branch + clean-tree gate, project-context block, Skill(`/document-release`) invocation, halt-on-red, auto-commit doc-only.
2. `skills/CJ_document-release/USAGE.md` (NEW) — 5 required H2 sections per F000032 convention (When to use / When NOT to use / Mental model / Common pitfalls / Related skills).
3. `skills-catalog.json` (MODIFIED) — new entry with `status: experimental`, `portability: workbench`, `depends.skills: ["document-release"]`.
4. `doc/SKILL-CATALOG.md` (MODIFIED) — new `### CJ_document-release` section with `(phase-step in /CJ_goal_feature chain)` tag.
5. `skills/CJ_goal_feature/pipeline.md` (MODIFIED) — new Step 5.5: Doc-sync between QA and /ship.
6. `skills/CJ_goal_feature/SKILL.md` (MODIFIED) — halt-taxonomy table: 2 new rows for doc-sync-red + doc-sync-non-doc-write.
7. `skills/CJ_goal_defect/pipeline.md` (MODIFIED) — same Step 5.5: Doc-sync.
8. `skills/CJ_goal_defect/SKILL.md` (MODIFIED) — same halt-taxonomy rows.
9. `skills/CJ_goal_todo_fix/pipeline.md` (MODIFIED) — same Step 5.5: Doc-sync.
10. `skills/CJ_goal_todo_fix/SKILL.md` (MODIFIED) — same halt-taxonomy rows.
11. `tests/cj-document-release.test.sh` (NEW) — unit-shape tests for the skill itself.
12. `tests/cj-goal-doc-sync-wiring.test.sh` (NEW) — integration-shape tests for the orchestrator wiring.
13. `scripts/test.sh` (MODIFIED) — wire both new test files in.
14. `work-items/features/ops/F000029_marker_pickup_auq/F000029_DESIGN.md` (MODIFIED) — BD#1 supersession annotation appended in-place.
15. `VERSION` (MODIFIED) — PATCH bump 5.0.19 → 6.0.1.
16. `CHANGELOG.md` (MODIFIED) — new [6.0.1] entry in user-forward voice.

| Concern | User-story | Artifact |
|---------|-----------|----------|
| CJ_document-release skill + all 3 cj_goal orchestrator wiring + tests + F000029 BD#1 supersession (atomic implementation) | S000069 | `S000069_cj_document_release_skill_impl/S000069_TRACKER.md` |

## Big decisions

| # | Decision | Why |
|---|----------|-----|
| 1 | Approach A (new SKILL.md skill) over B (hybrid skill + script helper) over C (inline triplicate in 3 pipeline.md files) | A reuses the just-shipped F000032+F000033+F000034 pattern (per-skill USAGE.md + doc/SKILL-CATALOG.md section + validate.sh-compliant). `--docs` flag + halt-on-red + auto-commit-doc-only live in one skill folder; future per-verb extensions are single-file changes. Approach C is the exact anti-pattern F000029 BD#1 itself flagged when rejecting its own internal "Approach A". |
| 2 | F000029 BD#1 explicitly superseded; annotation appended in-place to F000029_DESIGN.md | F000029 rejected the new-skill shape three weeks ago citing two reasons (adds to catalog forever; extra invocation hop). This PR reopens with strictly-more-capability shape (`--docs` parameterization + halt-on-red + auto-commit-doc-only) that earns the catalog cost. In-place annotation keeps the audit trail navigable. |
| 3 | F000029 marker-AUQ STAYS as fallback (not deprecated) | Non-orchestrator paths (raw `git push`, manual `/ship` from outside cj_goal pipeline) still need a way to surface doc drift. F000029's mechanism is the fallback. The two mechanisms layer — F000036 fires inline in cj_goal pipelines; F000029 fires on next-session for non-orchestrator paths. |
| 4 | All 3 cj_goal orchestrators get the wiring (uniform across the family) | `/CJ_goal_feature` + `/CJ_goal_defect` + `/CJ_goal_todo_fix` all auto-invoke CJ_document-release between QA and `/ship`. Uniform behavior. The Step 5.5 block is identical across all 3 modulo the `<verb>` in the resume_cmd. |
| 5 | Halt-on-red is a hard halt, not a warning | Per memory `feedback_skill_contracts_strict` + F000030/F000032/F000033/F000034 precedent: WARN gets ignored; ERROR-with-cheap-override is the load-bearing pattern. CJ_document-release returning non-green produces a `[doc-sync-red]` halt marker the orchestrator treats as build failure. |
| 6 | Doc-only auto-commit whitelist: `^(README\|CHANGELOG\|CLAUDE\|ARCHITECTURE)\.md$` + `^doc/.+\.md$` + `^templates/doc-.*\.md$` | Conservative whitelist prevents stealth code edits via the doc-sync surface. If `/document-release` writes outside the whitelist, CJ_document-release refuses to auto-commit and HALTs with `[doc-sync-non-doc-write]`. The `templates/doc-*` extension covers F000032/F000033/F000034 template-doc convention. |
| 7 | No upstream `/document-release` modification (workbench-only scope) | Per memory `feedback_workbench_scope` + `project_workbench_auto_deploy_unsafe`. Upstream `/document-release` invoked via Skill tool with project-context priming; filter/halt/auto-commit logic lives in the workbench skill, not upstream. Mirrors F000034's "no upstream modification" precedent. |
| 8 | Single user-story decomposition (atomic implementation) | All 16 files ship atomically under the pre-commit hook. Same shape as F000032 (S000065), F000033 (S000066), F000034 (S000067). Splitting adds bookkeeping without splitting risk; Check 13 (USAGE.md presence) + Check 15 (catalog section completeness) would block intermediate-state commits anyway. |
| 9 | `portability: workbench` for the catalog entry | This skill depends on workbench-specific conventions (CLAUDE.md tracked-doc/ manifest, cj_goal orchestrators) and isn't useful in a standalone target repo. Explicit signal. |
| 10 | PR-stop at /ship; no /land-and-deploy in this PR | /CJ_goal_feature stops at PR by design — the PR is the architecture gate (human review). Per memory `project_workbench_auto_deploy_unsafe`, auto-deploy is unsafe in this workbench. The Step 5.5 wiring works with PR-stop semantics precisely because the same-PR shape doesn't depend on /land-and-deploy. |

## Risks & open questions

| Risk / Question | Next check |
|-----------------|-----------|
| `--quiet` mode interaction: should `/CJ_goal_todo_fix --quiet` (cron) suppress `[doc-sync-red]` halt marker? | Resolution: no, let it halt as usual. `--quiet` only suppresses summary banners + AUQs, not halt-on-red contracts. Cron operator reads halt journal at convenience; silently swallowing doc-sync failures defeats the purpose. |
| `--docs` negation flag (`--skip-docs README`) for v1? | Resolution: v1 only positive subset; negation deferred to v2 if operator demand surfaces. Keeps parser surface small. |
| Doc-only whitelist scope: should `*.md` files anywhere in repo count? | Resolution: v1 whitelist = `^(README\|CHANGELOG\|CLAUDE\|ARCHITECTURE)\.md$` + `^doc/.+\.md$` + `^templates/doc-.*\.md$`. Conservative > permissive (avoid `[doc-sync-non-doc-write]` false-positive halt). Extend whitelist if operator hits the false-positive. |
| `--docs` case sensitivity | Resolution: case-insensitive — operator typos are common. |
| `/document-release`'s `--pr-body` output integration when running BEFORE /ship | Resolution: v1 best-effort. `/document-release` writes PR body to a file path it tracks; `/ship` picks up at PR-construction time. If integration breaks, fix in follow-up (would surface in live dogfood). |
| Atomic commit ordering with pre-commit hook + Check 13 + Check 15 | Same constraint as F000032+F000033+F000034: stage all 16 files once. Intermediate states would fire Check 13 (USAGE.md presence) or Check 15b (catalog section completeness). |
| 16 files in one PR is a wide diff | Mitigation: the surface is largely template + 3-way symmetric edits (3 pipeline.md identical-modulo-verb; 3 SKILL.md identical halt-taxonomy rows). Diff review is largely "did the 3-way edits stay symmetric." Tests/cj-goal-doc-sync-wiring.test.sh asserts the symmetry. |
| F000029 BD#1 supersession is a legitimate reopen, but the audit trail must be navigable | Mitigation: in-place "SUPERSEDED BY F000036 (v6.0.1)" annotation in F000029_DESIGN.md BD#1 row. Future readers see the rationale immediately; git blame preserves the original. |
| Future per-verb behavior divergence | Mitigation: SKILL.md is the single evolution surface for the wrapper logic. The Step 5.5 block in each pipeline.md is a thin invocation — divergence would mean adding orchestrator-specific args. Current design has identical invocations across all 3 verbs. |
| Backwards-compat with existing F000029 marker-AUQ paths | F000029 stays installed and functional; its preamble snippet continues to fire on next-session for non-orchestrator paths. CJ_document-release's Step 5.5 fires inline in orchestrator paths. The two paths are mutually exclusive at run-time (orchestrator session vs non-orchestrator session). |

## Definition of done

- [ ] `skills/CJ_document-release/SKILL.md` + `USAGE.md` exist with valid YAML frontmatter + 5 required H2 sections.
- [ ] `skills-catalog.json` has the new CJ_document-release entry.
- [ ] `doc/SKILL-CATALOG.md` has the new `### CJ_document-release` section.
- [ ] All 3 cj_goal `pipeline.md` files contain Step 5.5: Doc-sync.
- [ ] All 3 cj_goal `SKILL.md` halt-taxonomy tables contain both new rows.
- [ ] `tests/cj-document-release.test.sh` + `tests/cj-goal-doc-sync-wiring.test.sh` exist and pass.
- [ ] `scripts/test.sh` wires both test files in.
- [ ] `./scripts/validate.sh` exits 0 / 0 errors / 0 warnings.
- [ ] `./scripts/test.sh` exits 0.
- [ ] F000029_DESIGN.md BD#1 has the SUPERSEDED BY annotation.
- [ ] VERSION = 6.0.1; CHANGELOG entry in user-forward voice.
- [ ] PR opened against main via /ship.

## Not in scope

- Upstream `/document-release` modification — not ours to edit. Wrap via Skill tool with project-context priming (memory `project_workbench_auto_deploy_unsafe`).
- `--skip-docs` negation flag — v1 positive subset only; deferred to v2 if demand surfaces.
- Per-marker snooze of CJ_document-release outputs — single global halt-on-red is sufficient.
- `/land-and-deploy` step in this PR — /CJ_goal_feature stops at PR by design; deploy is a separate human step.
- README.md per-skill workflow-chart column — out of scope; F000034 deferred this.
- work-copilot/ analog skill — workbench-only scope.
- F000029 deprecation — coexistence with marker-AUQ for non-orchestrator paths.
- Deprecation of any existing CJ_* skill — additive only.
- Auto-generated catalog entry — hand-written per F000034 precedent.
- Behavior change for non-cj_goal callers of `/document-release` — they continue to call upstream directly.

## Pointers

- Parent tracker: [F000036_TRACKER.md](F000036_TRACKER.md)
- Roadmap: [F000036_ROADMAP.md](F000036_ROADMAP.md)
- Child story: [S000069_cj_document_release_skill_impl/S000069_TRACKER.md](S000069_cj_document_release_skill_impl/S000069_TRACKER.md)
- Source design: `~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-cj-feat-20260602-011228-doc-release-design-20260602-012718.md`
- F000028 (PR #177, v5.0.8) — post-merge git hook + doc-sync-pending marker shape. CJ_document-release doesn't read the marker; coexists with F000028's hook for non-orchestrator paths.
- F000029 (PR #178, v5.0.9) — `scripts/skills-doc-sync-check` + 3 cj_goal preamble AUQ. F000029 BD#1 explicitly superseded by this PR; F000029 marker-AUQ stays as fallback for non-orchestrator paths.
- D000026 (v5.0.14) — branch-aware AUQ recommendation fix (B-snooze on main). Unaffected; F000029's preamble continues to fire as fallback with the branch-aware recommendation.
- F000032 (PR #186, v5.0.17) — per-skill USAGE.md convention. CJ_document-release follows it.
- F000033 (PR #188, v5.0.18) — USAGE.md drift detection (Check 14). CJ_document-release subject to it.
- F000034 (PR #189, v5.0.19) — doc/SKILL-CATALOG.md + tracked-doc/ manifest. CJ_document-release gets a section with the phase-step tag.
