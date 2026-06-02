---
name: "CJ_document-release skill + cj_goal orchestrator inline wiring"
type: feature
id: "F000036"
status: active
created: "2026-06-02"
updated: "2026-06-02"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "cj-feat-20260602-011228-64202"
blocked_by: ""
---

<!-- Prerequisite: Before scaffolding this work item, run /office-hours to
     produce a design plan in ~/.gstack/projects/. Distill that plan into
     DESIGN.md during Phase 1 below. -->

## Lifecycle

### Phase 1: Track

1. Create working branch: `cj-feat-20260602-011228-64202` (auto-created by /CJ_goal_feature worktree phase from origin/main HEAD `006ffe3`; no upstream stacking)
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
5. Run `/land-and-deploy` — merges and verifies deployment (deferred — /CJ_goal_feature stops at PR)
6. Run `/document-release` — post-ship doc audit; fix drifts inline or spawn D-tickets (deferred)

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

- [ ] `skills/CJ_document-release/SKILL.md` exists with valid YAML frontmatter (name, description, version, allowed-tools: Bash, Read, Glob, Grep, Skill).
- [ ] `skills/CJ_document-release/USAGE.md` exists with all 5 required H2 sections (When to use / When NOT to use / Mental model / Common pitfalls / Related skills).
- [ ] `skills-catalog.json` has a new CJ_document-release entry with `status: experimental`, `portability: workbench`, `depends.skills: ["document-release"]`.
- [ ] `doc/SKILL-CATALOG.md` has a new `### CJ_document-release` section with `(phase-step in /CJ_goal_feature chain)` tag.
- [ ] All 3 cj_goal `pipeline.md` files (`skills/CJ_goal_feature/pipeline.md`, `skills/CJ_goal_defect/pipeline.md`, `skills/CJ_goal_todo_fix/pipeline.md`) contain a new "Step 5.5: Doc-sync" subsection inserted between QA pass and `/ship`.
- [ ] All 3 cj_goal `SKILL.md` halt-taxonomy tables contain two new rows: `[doc-sync-red]` (halt class `halted_at_doc_sync`) and `[doc-sync-non-doc-write]` (halt class `halted_at_doc_sync_non_doc_write`), inserted after the qa-red row and before the ship-declined row.
- [ ] `tests/cj-document-release.test.sh` exists and covers: skill files exist, SKILL.md frontmatter parses (name/description/version/allowed-tools), USAGE.md has 5 required H2 sections, catalog entry exists, doc/SKILL-CATALOG.md section exists, `[doc-sync-red]` halt marker grep, branch refusal prose grep, clean-tree refusal prose grep, `--docs all` parsing path documented, `--docs README,CHANGELOG` parsing path documented.
- [ ] `tests/cj-goal-doc-sync-wiring.test.sh` exists and covers: all 3 pipeline.md files contain "Step 5.5: Doc-sync", all 3 SKILL.md halt-taxonomy tables contain both new rows, halt-taxonomy row ordering is correct (after qa-red, before ship-declined).
- [ ] `scripts/test.sh` wires both new test files in.
- [ ] `./scripts/validate.sh` exits 0 with 0 errors / 0 warnings on this PR's HEAD (all 15 checks pass; catalog audit set grows from 11 to 12 skills, includes CJ_document-release).
- [ ] `./scripts/test.sh` exits 0 on this PR's HEAD (full superset suite passes).
- [ ] `work-items/features/ops/F000029_marker_pickup_auq/F000029_DESIGN.md` Big Decision #1 row has the "SUPERSEDED BY F000036 (v6.0.1)" annotation appended in-place; rationale captured (`--docs` parameterization + halt-on-red + auto-commit earns the catalog cost the F000029 detection-only script can't expose).
- [ ] `VERSION` reads `6.0.1` (PATCH bump from 5.0.19); queue-collision preflight via `./scripts/check-version-queue.sh` confirmed the slot is free before /ship.
- [ ] `CHANGELOG.md` has a new `[6.0.1] — 2026-06-02` entry in user-forward voice, naming F000036 + the F000029 BD#1 supersession + the orchestrator wiring across all 3 cj_goal verbs.
- [ ] PR opened against main via `/ship`. PR body notes the F000028+F000029+F000034 lineage + the F000029 BD#1 supersession callout. /CJ_goal_feature stops at PR per design (no auto-merge, no /land-and-deploy).
- [ ] No upstream `/document-release` modification. No changes to `~/.claude/` or `deprecated/` or `work-copilot/`.

## Todos

<!-- Actionable items for this feature. Break into child tasks for
     large features. -->

- [ ] Ship S000069 (`cj_document_release_skill_impl`) — single atomic user-story carrying the SKILL.md + USAGE.md + catalog entry + doc/SKILL-CATALOG.md section + all 3 cj_goal pipeline.md edits + all 3 cj_goal SKILL.md halt-taxonomy edits + tests/cj-document-release.test.sh + tests/cj-goal-doc-sync-wiring.test.sh + scripts/test.sh wiring + F000029_DESIGN.md BD#1 supersession annotation + VERSION + CHANGELOG.
- [ ] End-to-end pipeline run — `/ship` opens PR against main; `./scripts/validate.sh` PASS; `./scripts/test.sh` PASS; manual smoke A = invoke `/CJ_document-release --docs README` from a feature branch with a stale README and verify auto-commit; manual smoke B = `/CJ_goal_defect "synthetic doc-drift bug"` against a fixture that modifies a code file mentioned in README and verify Step 5.5 fires, README drift auto-commits, PR diff includes BOTH code + doc updates.

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-06-02: Created. Cut from origin/main HEAD `006ffe3` (post-F000034 merged + WIP commit). Closes the F000029 marker-AUQ drift window for orchestrator-driven shipping by wrapping upstream `/document-release` in a new workbench skill `CJ_document-release` with a `--docs <subset>` flag for per-invocation parameterization, halt-on-red contract, and auto-commit of doc-only changes. All 3 cj_goal orchestrators (`/CJ_goal_feature`, `/CJ_goal_defect`, `/CJ_goal_todo_fix`) auto-invoke it inline between QA pass and `/ship` — doc updates fold into the same code PR. F000029 BD#1 (rejected new-skill-in-catalog) explicitly superseded; the `--docs` + halt-on-red + auto-commit capability earns the catalog cost the F000029 detection-only script can't expose. F000029's marker-AUQ stays as fallback for non-orchestrator paths (raw `git push`, manual `/ship`). No upstream gstack modification — wraps `/document-release` via Skill tool with project-context priming.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. Populated during Track phase, updated during Implement. -->

- `skills/CJ_document-release/SKILL.md` (NEW — wrapper skill with `--docs` flag, halt-on-red, auto-commit-doc-only)
- `skills/CJ_document-release/USAGE.md` (NEW — 5 required H2 sections per F000032 convention)
- `skills-catalog.json` (MODIFIED — new CJ_document-release entry with `status: experimental`, `portability: workbench`)
- `doc/SKILL-CATALOG.md` (MODIFIED — new `### CJ_document-release` section with `(phase-step in /CJ_goal_feature chain)` tag)
- `skills/CJ_goal_feature/pipeline.md` (MODIFIED — new Step 5.5: Doc-sync between QA and /ship)
- `skills/CJ_goal_feature/SKILL.md` (MODIFIED — halt-taxonomy table: 2 new rows for doc-sync-red + doc-sync-non-doc-write)
- `skills/CJ_goal_defect/pipeline.md` (MODIFIED — same Step 5.5: Doc-sync)
- `skills/CJ_goal_defect/SKILL.md` (MODIFIED — same halt-taxonomy rows)
- `skills/CJ_goal_todo_fix/pipeline.md` (MODIFIED — same Step 5.5: Doc-sync)
- `skills/CJ_goal_todo_fix/SKILL.md` (MODIFIED — same halt-taxonomy rows)
- `tests/cj-document-release.test.sh` (NEW — unit-shape tests for the skill itself)
- `tests/cj-goal-doc-sync-wiring.test.sh` (NEW — integration-shape tests for the orchestrator wiring)
- `scripts/test.sh` (MODIFIED — wire both new test files in)
- `work-items/features/ops/F000029_marker_pickup_auq/F000029_DESIGN.md` (MODIFIED — BD#1 supersession annotation appended in-place)
- `VERSION` (MODIFIED — PATCH bump 5.0.19 → 6.0.1)
- `CHANGELOG.md` (MODIFIED — new [6.0.1] entry in user-forward voice)

## Insights

<!-- Non-obvious findings worth remembering. Design decisions,
     trade-offs, patterns discovered. -->

- **Closes the doc-sync loop into the shipping cycle that originated it.** F000028+F000029's marker-AUQ shape decouples doc-sync from the PR that caused the drift — the operator's next session AUQ might fire hours/days later. F000036 inlines `/document-release` in the same shipping cycle that produced the drift, folding doc updates into the same code PR. Code + docs ship together because they were CHANGED together. The two-PR follow-up pattern was an artifact of the marker mechanism, not a desired property of the workflow.
- **First workbench skill with the explicit shape "thin wrapper around an upstream gstack skill."** `/CJ_document-release` calls `/document-release` via the Skill tool, adding workbench-specific concerns (per-doc filtering, halt taxonomy, auto-commit doc-only) without touching upstream. If we later want similar wrappers for other upstream skills (`/CJ_ship`? `/CJ_review`?), this is the template.
- **F000029 BD#1 supersession is a legitimate-reopen pattern.** Three weeks after F000029 explicitly rejected "new /CJ_doc_sync skill in catalog" for two reasons (adds to catalog forever; extra invocation hop), this PR reopens that decision because the new skill earns the catalog cost with capabilities the F000029 detection-only script can't expose: `--docs` parameterization, halt-on-red, auto-commit-doc-only. The right move is to annotate F000029 BD#1 in-place with "SUPERSEDED BY F000036" — audit trail navigable, future readers see the rationale without hunting through commit history.
- **Atomic-commit ordering through the pre-commit hook.** Same constraint as F000032 + F000033 + F000034: stage everything once. Validate.sh Check 13 (USAGE.md presence) would BLOCK any intermediate commit between SKILL.md and USAGE.md landing; Check 15b (SKILL-CATALOG.md per-skill completeness) would BLOCK any intermediate commit between catalog entry and doc/SKILL-CATALOG.md section landing. One commit, one push, one PR.
- **`portability: workbench`** is an explicit choice that signals workbench-only dependencies (CLAUDE.md tracked-doc/ manifest, cj_goal orchestrators). Other CJ_* skills could be retroactively normalized to this value in a follow-up; deferred. The catalog entry's `depends.skills: ["document-release"]` makes the upstream coupling explicit.
- **Halt-on-red is a hard halt, not a warning.** `[doc-sync-red]` propagates as a build failure to the calling orchestrator — `/CJ_goal_*` HALTs with a journal entry naming the resume_cmd. The cron-mode `/CJ_goal_todo_fix --quiet` flag suppresses summary banners + AUQs but NOT halt-on-red contracts (cron operator inspects the halt journal at their convenience; silently swallowing doc-sync failures would defeat the purpose).
- **`[doc-sync-non-doc-write]` is a new halt class for the upstream-misbehaved case.** If `/document-release` writes files outside the doc-only whitelist (`README|CHANGELOG|CLAUDE|ARCHITECTURE`.md or `doc/.+\.md` or `templates/doc-.*\.md`), CJ_document-release refuses to auto-commit and HALTs. Conservative whitelist prevents stealth code edits via the doc-sync surface.
- **Coexistence with F000029, not replacement.** F000029's marker-AUQ stays in place as fallback for non-orchestrator paths — raw `git push`, manual `/ship` from outside the cj_goal pipeline, etc. The two mechanisms layer; they don't fight. F000029 fires only when F000036's in-pipeline path didn't run.

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

- 2026-06-02 [decision] Approach A (new SKILL.md skill) over B (hybrid skill + script helper) over C (inline triplicate in 3 pipeline.md files). Summary: A reuses the just-shipped F000032+F000033+F000034 pattern (per-skill USAGE.md + doc/SKILL-CATALOG.md section + validate.sh-compliant). Per-doc `--docs` flag + halt-on-red + auto-commit live in one skill folder; future per-verb extensions are single-file changes. Approach B fragments discoverability (script `--help` vs SKILL.md). Approach C is the exact anti-pattern F000029 BD#1 itself flagged when rejecting its own internal "Approach A" (triplicate 10-line block in 3 SKILL.md preambles, same reason).
- 2026-06-02 [decision] Single user-story decomposition (atomic implementation). Summary: SKILL.md + USAGE.md + catalog entry + doc/SKILL-CATALOG.md section + 3 pipeline.md edits + 3 SKILL.md halt-taxonomy edits + 2 tests + scripts/test.sh wiring + F000029_DESIGN.md BD#1 annotation + VERSION + CHANGELOG all ship atomically under the pre-commit hook. Same shape as F000032 (S000065), F000033 (S000066), F000034 (S000067). Splitting adds bookkeeping without splitting risk.
- 2026-06-02 [decision] F000029 BD#1 explicitly superseded; annotation appended in-place to F000029_DESIGN.md. Summary: F000029 BD#1 rejected the new-skill shape three weeks ago citing two reasons (adds to catalog forever; extra invocation hop). This PR reopens with strictly-more-capability shape — `--docs` parameterization + halt-on-red + auto-commit-doc-only — that earns the catalog cost. The in-place "SUPERSEDED BY F000036 (v6.0.1)" annotation keeps the audit trail navigable; future readers see the rationale immediately.
- 2026-06-02 [decision] F000029 marker-AUQ STAYS as fallback (not deprecated). Summary: Non-orchestrator paths (raw `git push`, manual `/ship` from outside cj_goal pipeline, third-party scripts) still need a way to surface doc drift. F000029's marker mechanism is the fallback for those paths. The two mechanisms layer — F000036 fires inline in cj_goal pipelines; F000029 fires on next-session for non-orchestrator paths. No deprecation; coexistence.
- 2026-06-02 [decision] All 3 cj_goal orchestrators get the wiring (uniform across the family). Summary: `/CJ_goal_feature` + `/CJ_goal_defect` + `/CJ_goal_todo_fix` all auto-invoke CJ_document-release between QA and `/ship`. Uniform behavior across the family. The Step 5.5 block is identical across all 3 modulo the `<verb>` in the resume_cmd. The wiring doesn't depend on /land-and-deploy running, which means it works with /CJ_goal_feature's PR-stop semantics (no auto-deploy expansion needed).
- 2026-06-02 [decision] Halt-on-red is a hard halt, not a warning. Summary: `[doc-sync-red]` propagates as a build failure; the orchestrator HALTs with a journal entry naming the resume_cmd. Per memory `feedback_skill_contracts_strict` + F000030/F000032/F000033/F000034 precedent: WARN gets ignored; ERROR-with-cheap-override is the load-bearing pattern. CJ_document-release returning non-green produces a `[doc-sync-red]` halt marker the orchestrator treats as build failure.
- 2026-06-02 [decision] Doc-only auto-commit whitelist: `^(README|CHANGELOG|CLAUDE|ARCHITECTURE)\.md$` + `^doc/.+\.md$` + `^templates/doc-.*\.md$`. Summary: Conservative whitelist prevents stealth code edits via the doc-sync surface. If `/document-release` writes a file outside the whitelist, CJ_document-release refuses to auto-commit and HALTs with `[doc-sync-non-doc-write]`. The `templates/doc-*` extension covers the F000032/F000033/F000034 template-doc convention.
- 2026-06-02 [decision] No upstream `/document-release` modification (workbench-only scope). Summary: Per memory `feedback_workbench_scope` + `project_workbench_auto_deploy_unsafe`. Upstream `/document-release` invoked via Skill tool with project-context priming; the filter/halt/auto-commit logic lives in the workbench skill, not upstream. Mirrors F000034's "no upstream modification" precedent.
- 2026-06-02 [decision] `portability: workbench` for the catalog entry. Summary: This skill depends on workbench-specific conventions (CLAUDE.md tracked-doc/ manifest, cj_goal orchestrators) and isn't useful in a standalone target repo. Explicit signal in the catalog. Other CJ_* skills could be retroactively normalized to this value in a follow-up; deferred.
- 2026-06-02 [decision] PR-stop at /ship per /CJ_goal_feature semantics; no /land-and-deploy in this PR. Summary: /CJ_goal_feature stops at PR by design — the PR is the architecture gate (human review). Per memory `project_workbench_auto_deploy_unsafe`, auto-deploy is unsafe in this workbench (cj-handoff-gate denylist blocks the skill surfaces every feature touches). The Step 5.5 wiring works with PR-stop semantics precisely because the same-PR shape doesn't depend on /land-and-deploy.
