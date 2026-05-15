---
name: "/CJ_implement-from-spec should chmod +x shell scripts it creates"
type: task
id: "T000022"
status: active
created: "2026-05-14"
updated: "2026-05-14"
parent: ""
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "fix/implement-chmod-x-T000022"
blocked_by: ""
---

<!-- Skip-design per feedback_skip_design_for_small_todos. Source: TODOS.md row.
     This task also serves as the "first real run" end-to-end validation of
     v3.4.1's pipeline substrate fix (type-aware Step 7 + sensitive-surface
     regex). Recommended by D000019 design doc as the sympathetic first run. -->

## Lifecycle

### Phase 1: Track

**Gates:**
- [x] Parent scope read (no parent; TODOS.md source)
- [x] Working branch created (`fix/implement-chmod-x-T000022`)
- [x] Required docs scaffolded (test-plan)
- [x] Files section populated

### Phase 2: Implement

**Gates:**
- [ ] Core changes committed (>=1 commit SHA in Log)
- [x] Todos section reflects remaining work (no stale items)
- [x] Files section updated with changed files

### Phase 3: Ship

**Gates:**
- [ ] `/CJ_personal-workflow check` — validation passed
- [ ] Test-plan verified (all scenarios passing)
- [ ] `/ship` — PR created
- [ ] `/land-and-deploy` — merged and deployed

## Todos

- [x] Add post-write `chmod +x` step to `skills/CJ_implement-from-spec/implement.md` Step 9 for files matching `*.sh`, `*.bash`, or no-extension files starting with a `#!` shebang
- [x] Belt-and-suspenders: also verify executable bit in Step 11 boundary block (or note as advisory if structurally hard) — recorded as advisory in v1 per the implement.md insertion; no Step 11 enforcement added
- [ ] Mark TODOS.md:97 as DONE in same PR via /document-release

## Log

- 2026-05-14: Created. Scope from TODOS.md:97. Closes the autoplan-recommended "first real run" for v3.4.1's substrate fix — validates the type-aware Step 7 + Step 5.1 work end-to-end for a task-type tracker.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

- `skills/CJ_implement-from-spec/implement.md` (modified) — Step 9 + possibly Step 11

## Insights

**Source: TODOS.md:97** (P4, S — `/CJ_implement-from-spec` should `chmod +x` shell scripts it creates).

**Body (verbatim from TODOS.md):**

When `/CJ_implement-from-spec` writes a new `.sh` file (e.g. D000017's `skills/CJ_suggest/scripts/suggest.sh`), the file lands at mode 644 (non-executable). Test-plan rows that assert "executable bit set" and downstream `skills-deploy install` smoke checks both flag it as a discrepancy. On D000017 (PR #84), /ship Step 9 pre-landing review caught it as a [LOW] AUTO-FIX and `chmod +x`d the file before commit; the implement subagent should have done that itself.

**Fix:** add a post-write `chmod +x` step to `skills/CJ_implement-from-spec/implement.md` (find the per-type write loop) for any file matching `*.sh`, `*.bash`, or no-extension files starting with a `#!` shebang. Belt-and-suspenders: also fix in the verification block (re-check executable bit after the write).

**Reference:** D000017 ship (PR #84) — implement subagent shipped the new script at mode 644; /ship Step 9 chmod'd it pre-merge.

**Implementation detail (post-design audit):** Step 9 of implement.md is the per-type write loop. The cleanest insertion point is a new sub-step after Step 9's "Atomicity within Step 9" block — a small bash snippet that loops over staged-for-write paths matching the heuristic and runs `chmod +x` on each. Step 11's boundary check could optionally re-verify the executable bit; v1 keeps it advisory (any failure would surface at /ship Step 9 pre-landing review, which is what catches it today).

**Substrate validation hook:** because this is a task-type work-item, the dispatch via `/CJ_personal-pipeline --work-item-dir` exercises the v3.4.1 type-aware Step 7 (defect/task green-on-ambiguous) and Step 5.1 (task scans TRACKER + test-plan, not SPEC) for the first time end-to-end against real conditions. If the pipeline reaches `end_state=green` without taste-override, the substrate fix is validated.

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

- 2026-05-14: [orchestrator] --work-item-dir mode: using pre-staged dir at /Users/chjiang/Documents/projects/claude-skills-templates/work-items/tasks/skills/T000022_implement_from_spec_chmod_x; scaffold skipped.
- 2026-05-14: [impl-decision] Inserted chmod +x sub-step at implement.md Step 9 immediately after the "Atomicity within Step 9" block per task TRACKER Insights → Implementation detail. Heuristic targets `*.sh`, `*.bash`, and no-extension files whose first line is `#!`. Belt-and-suspenders Step 11 enforcement deferred to advisory v1 (any miss surfaces at /ship Step 9 pre-landing review per D000017 precedent).
- 2026-05-14: [impl] Modified 1 file (skills/CJ_implement-from-spec/implement.md), +54 lines, 0 deletions; Step 9 region only.
- 2026-05-14: [impl-auto] Auto-mode run dispatched via /CJ_personal-pipeline --work-item-dir + --suppress-final-gate (first real run of v3.4.1 type-aware substrate fix end-to-end for a task-type tracker).
- 2026-05-14: [qa-smoke-summary] green — 5/5 test-plan grep rows pass (chmod +x present, .bash mentioned, shebang/#! covered, TODOS:97/D000017/T000022 rationale inline, no regression in other Step headers).
- 2026-05-14: [qa-pass] T000022: implementation verified per test-plan; defect/task smoke-based gate (E2E n/a for task type per qa.md line 179).
- 2026-05-14: [impl-pass] T000022: implementation complete. Phase 2 implementer-owned gates transitioned.
- 2026-05-14: [auto-pipeline-clean] /CJ_personal-pipeline run 20260514-211806-7063 ended green with 1 mechanical decision (Step 4 scaffold-shape-confirm), 0 taste, 0 user-challenge-approved. --suppress-final-gate set → Step 8.5 AUQ skipped.

<!-- Source: TODOS.md ### /CJ_implement-from-spec should chmod +x shell scripts it creates (P4, S) -->
