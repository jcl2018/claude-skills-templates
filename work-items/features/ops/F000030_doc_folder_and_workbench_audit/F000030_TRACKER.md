---
name: "doc/ folder with rewritten PHILOSOPHY + new ARCHITECTURE; /document-release named-doc audit"
type: feature
id: "F000030"
status: active
created: "2026-05-31"
updated: "2026-05-31"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "cj-feat-20260531-123255-4461"
blocked_by: ""
---

<!-- Prerequisite: Before scaffolding this work item, run /office-hours to
     produce a design plan in ~/.gstack/projects/. Distill that plan into
     DESIGN.md during Phase 1 below. -->

## Lifecycle

### Phase 1: Track

1. Create working branch: `git checkout -b cj-feat-20260531-123255-4461`
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

- [ ] `doc/` folder exists at repo root with exactly two files: `doc/PHILOSOPHY.md` + `doc/ARCHITECTURE.md`.
- [ ] Root `philosophy.md` is gone (moved via `git mv`); `git log --follow doc/PHILOSOPHY.md` shows the rename history preserved.
- [ ] `doc/PHILOSOPHY.md` references `/cj_goal_feature` + `/cj_goal_defect` as primary front doors.
- [ ] Every mention of `/CJ_goal_auto`, `/CJ_goal_run`, `/workflow`, `/contracts`, `/docs` in `doc/PHILOSOPHY.md` is either inside the `## Retired skills` subsection OR dropped (no orphan mentions elsewhere).
- [ ] `doc/PHILOSOPHY.md` has a `## Decision tree` heading containing the routing diagram for active CJ_ skills.
- [ ] `doc/ARCHITECTURE.md` has these five exact headings: `## The shared cj-goal-common.sh helper (S000057)`, `## F000028 doc-sync hooks (post-merge + post-rewrite)`, `## F000029 marker-pickup AUQ (cj_goal preambles)`, `## Decision tree mirror`, `## Deprecation tombstones`.
- [ ] Each ARCHITECTURE section answers the content questions enumerated in DESIGN.md (not a word-count gate).
- [ ] Root `README.md` has a `## Deeper reading` section linking to `doc/PHILOSOPHY.md` and `doc/ARCHITECTURE.md`.
- [ ] Root `CLAUDE.md` has a NEW section `## /document-release workbench audit conventions` containing the literal jq commands (retired-skill drift + new-skills check) and annotation suppression rules.
- [ ] `./scripts/validate.sh` exits 0 with 0 errors / 0 warnings.
- [ ] `./scripts/test.sh` exits 0.
- [ ] Smoke test: a leaf reader of `doc/PHILOSOPHY.md` can answer "which CJ_ skill do I call to start a feature?" → `/cj_goal_feature`, and "what closes the doc-sync loop?" → F000028 hooks + F000029 marker-pickup AUQ.
- [ ] No upstream skill files modified (`/document-release`, `cj_goal_feature`, etc. untouched).

## Todos

<!-- Actionable items for this feature. Break into child tasks for
     large features. -->

- [ ] Ship S000063 (`doc_folder_and_workbench_audit_impl`) — implementation user-story (move + rewrite philosophy.md → doc/PHILOSOPHY.md; new doc/ARCHITECTURE.md; README + CLAUDE.md edits)
- [ ] End-to-end pipeline run — `/ship` opens PR; `/CJ_personal-workflow check` PASS; manual smoke test confirms philosophy legibility

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-05-31: Created. Rewrite philosophy.md as doc/PHILOSOPHY.md, add doc/ARCHITECTURE.md, wire /document-release named-doc audit via CLAUDE.md convention. Closes the F000028+F000029 doc-sync loop on the content side.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. Populated during Track phase, updated during Implement. -->

- `philosophy.md` (MOVED → `doc/PHILOSOPHY.md` via `git mv`; rewritten in same PR)
- `doc/PHILOSOPHY.md` (NEW path; full rewrite)
- `doc/ARCHITECTURE.md` (NEW — five required sections: cj-goal-common.sh, F000028 hooks, F000029 AUQ, Decision tree mirror, Deprecation tombstones)
- `README.md` (MODIFIED — add `## Deeper reading` section)
- `CLAUDE.md` (MODIFIED — add `## /document-release workbench audit conventions` section)
- `CHANGELOG.md` (MODIFIED — F000030 entry)

## Insights

<!-- Non-obvious findings worth remembering. Design decisions,
     trade-offs, patterns discovered. -->

- **Closes a real feedback loop.** F000028 + F000029 (v5.0.8 + v5.0.9, shipped 2026-05-30) wired the doc-sync mechanism — hooks drop markers, preambles surface AUQs. But the actual content `/document-release` audits had no specific named-doc treatment for the workbench's signature "why this exists + which skill does what" surface. This feature gives that surface its own named-doc audit so the loop becomes: routing change → hook fires → AUQ surfaces → `/document-release` runs → named-doc check catches skill-routing drift → operator sees and fixes.
- **Project-instructions-teach-upstream-skill is a proven pattern.** The CLAUDE.md `## /document-release workbench audit conventions` section rides the same convention as the existing CI/CD merge convention section that teaches `/ship` + `/land-and-deploy` to skip `--auto` in this repo. `/document-release` reads CLAUDE.md as project context during its Step 2 audit pass, so the workbench-specific drift checks land without touching the upstream skill.
- **Case-insensitive APFS lets `git mv philosophy.md doc/PHILOSOPHY.md` work in one shot.** The two paths differ in directory component, so the rename does not need the two-step `git mv` dance required for in-place case-only renames. Confirmed at design time (premise #3); no surprise during implementation.
- **`/document-release` Step 1 base-branch abort is a separate F000029 contract gap (out of scope here).** The skill refuses to run on main. The CLAUDE.md convention is still useful — it's read on any feature branch in this workbench. File the abort gap as a TODOS follow-up; do not gate this feature on fixing it.
- **CLAUDE.md mechanism duplication accepted for v1.** F000009 / F000028 / F000029 / TODOS-hygiene sections in CLAUDE.md overlap ~30% with doc/ARCHITECTURE.md content; rejected Approach C (extract → ARCHITECTURE) at scope AUQ. Revisit if CLAUDE.md grows past ~500 lines.

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

- 2026-05-31 [decision] Chose Approach B (create `doc/` folder, `git mv` philosophy.md → doc/PHILOSOPHY.md, rewrite, add doc/ARCHITECTURE.md, wire via CLAUDE.md convention) over Approach A (rewrite philosophy.md in place + add to /document-release Step 2 named docs) or Approach C (Approach B + extract CLAUDE.md mechanism prose into ARCHITECTURE). Summary: B captures the operator's reframe ("consolidate into doc/") at the right granularity, closes the F000028+F000029 loop on the content side, and keeps blast radius small enough that QA verifies with smoke tests + a Diataxis coverage check.
- 2026-05-31 [decision] Add NO new manifest layer (skills-manifest.yaml or similar). Summary: skill routing already lives in `rules/skill-routing.md`; prose narrative in `doc/PHILOSOPHY.md` + `doc/ARCHITECTURE.md` is enough. The rejected Option C from the scope AUQ — declarative manifest driving generated docs — is YAGNI at this scale (~7 active skills).
- 2026-05-31 [decision] Drop-vs-tombstone rule: retired skill names (`/workflow`, `/contracts`, `/docs`, `/CJ_goal_auto`, `/CJ_goal_run`) get a single `## Retired skills` paragraph each in `doc/PHILOSOPHY.md`; all OTHER mentions throughout PHILOSOPHY/ARCHITECTURE are dropped. Summary: one canonical tombstone location per name; everything else clean. Annotation suppression rule in the audit convention (Retired-skill mentions inside that subsection or near `DEPRECATED`/`sunset`/`tombstone` are skipped) is the symmetric escape hatch.
- 2026-05-31 [decision] `doc/README.md` index file is dropped from v1. Summary: with only two files in `doc/` (PHILOSOPHY.md + ARCHITECTURE.md), an index file is YAGNI cost. Discovery via root `README.md ## Deeper reading` + GitHub's directory rendering is sufficient. Revisit if `doc/` grows past 4 files.
- 2026-05-31 [decision] CLAUDE.md mechanism duplication acceptable for v1. Summary: F000009 / F000028 / F000029 / TODOS-hygiene sections stay in CLAUDE.md (agent-relevant); doc/ARCHITECTURE.md gets its own operator-facing versions that may overlap by ~30%. Rejected the bigger Approach C refactor (extract mechanism prose to ARCHITECTURE) at scope AUQ. Soft duplication is the cost of declining the bigger refactor.
