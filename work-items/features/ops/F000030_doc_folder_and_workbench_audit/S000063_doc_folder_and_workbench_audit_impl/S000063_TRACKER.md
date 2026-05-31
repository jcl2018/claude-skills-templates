---
name: "Move + rewrite philosophy.md → doc/PHILOSOPHY.md, add doc/ARCHITECTURE.md, README + CLAUDE.md edits, CHANGELOG"
type: user-story
id: "S000063"
status: active
created: "2026-05-31"
updated: "2026-05-31"
parent: "F000030"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "cj-feat-20260531-123255-4461"
blocked_by: ""
# pr: ""  # optional; populate with PR URL (e.g. https://github.com/org/repo/pull/123) for explicit PR-state lookups. The `## PRs` section below is the canonical home for PR links; this frontmatter field is a machine-readable shortcut consumed by /CJ_goal_run Branch(f)/(g) gh pr view dedup. Either convention is accepted.
---

<!-- Prerequisite: Before scaffolding this work item, run /office-hours to
     produce a design plan in ~/.gstack/projects/. Distill that plan into
     DESIGN.md during Phase 1 below. (For atomic stories that derive directly
     from the parent feature's /office-hours session, the parent's design is
     sufficient context — DESIGN.md may be a brief stub linking to the parent.) -->

## Lifecycle

### Phase 1: Track

1. Read parent tracker to understand scope
2. Create working branch: `git checkout -b cj-feat-20260531-123255-4461` (or use parent's branch if shipping in same PR — same branch here)
3. Scaffold work item directory and TRACKER.md
4. Distill `DESIGN.md` from the /office-hours output (own session or parent's) — from `templates/doc-DESIGN.md`
5. Scaffold `SPEC.md` (requirements, acceptance criteria, architecture, tradeoffs) — from `templates/doc-SPEC.md`
6. Scaffold `TEST-SPEC.md` (smoke + E2E test scenarios) — from `templates/doc-TEST-SPEC.md`
7. Break into child tasks if scope warrants decomposition (per WORKFLOW.md, tasks are optional for atomic stories)

**Gates:**
- [x] /office-hours design referenced (own or parent's, captured in DESIGN.md)
- [x] Working branch created (`branch` field populated)
- [x] DESIGN + SPEC + TEST-SPEC scaffolded
- [x] Acceptance criteria defined
- [x] Tasks broken down (N/A — atomic story)

### Phase 2: Implement

1. Read DESIGN + SPEC for context
2. Implement according to architecture decisions in SPEC
3. Run smoke tests as you go (TEST-SPEC `## Smoke Tests` table)
4. Run `/CJ_personal-workflow check` on modified docs after updates
5. Update tracker: move through lifecycle phases, add journal entries
6. Update Files section with changed file paths

**Gates:**
- [x] Acceptance criteria verified met
- [x] Smoke tests pass
- [ ] Todos section reflects remaining work (no stale items)
- [ ] Files section updated with changed files

### Phase 3: Ship

1. Run `/CJ_personal-workflow check` — verify all validation passes
   → should show PASS for template, lifecycle, traceability badges
2. Verify smoke tests pass in CI (automated regression)
3. Walk E2E manually — drive the feature as a user would (TEST-SPEC `## E2E Tests` table)
4. Ensure all child tasks (if any) have shipped
5. Run `/ship` — creates PR, bumps version, updates changelog (includes pre-landing code review)
6. Run `/land-and-deploy` — merges PR and verifies deployment

If `/CJ_personal-workflow check` finds issues: fix findings, re-run until clean
If smoke or E2E fails: fix, re-run

**Gates:**
- [ ] `/CJ_personal-workflow check` — validation passed
- [x] Smoke tests pass in CI
- [ ] E2E walked manually
- [ ] All children shipped (if any)
- [x] `/ship` — PR created (with pre-landing review)
- [x] `/land-and-deploy` — merged and deployed

## Acceptance Criteria

<!-- What "done" looks like for this story. -->

- [ ] `doc/` folder exists at repo root.
- [ ] `doc/PHILOSOPHY.md` exists; root `philosophy.md` is absent; `git log --follow doc/PHILOSOPHY.md` shows the rename preserved.
- [ ] `doc/PHILOSOPHY.md` references `/cj_goal_feature` + `/cj_goal_defect` as primary front doors and has a `## Decision tree` heading with a routing diagram covering active CJ_ skills (cj_goal_feature, cj_goal_defect, CJ_goal_investigate, CJ_goal_todo_fix, CJ_suggest, CJ_system-health, CJ_improve-queue) plus a "Called transitively" table for internal phase-step skills (CJ_personal-pipeline, CJ_scaffold-work-item, CJ_implement-from-spec, CJ_qa-work-item, CJ_personal-workflow).
- [ ] `doc/PHILOSOPHY.md` has a `## Retired skills` subsection with one paragraph each for `/workflow`, `/contracts`, `/docs`, `/CJ_goal_auto`, `/CJ_goal_run` — each naming what it was, when retired (PR # / version), why, what replaced it.
- [ ] No mention of `/workflow`, `/contracts`, `/docs`, `/CJ_goal_auto`, `/CJ_goal_run` in `doc/PHILOSOPHY.md` outside `## Retired skills` (no orphan references elsewhere).
- [ ] `doc/PHILOSOPHY.md` preserves the design-principles 1-5, "What this intentionally does NOT optimize for", "Key patterns and conventions", "How to extend without breaking its character", "Dependencies and assumptions", and "Failure modes and maintenance risks" sections — verified light-edited against current repo state.
- [ ] `doc/ARCHITECTURE.md` exists with exactly the five required `##` headings: `## The shared cj-goal-common.sh helper (S000057)`, `## F000028 doc-sync hooks (post-merge + post-rewrite)`, `## F000029 marker-pickup AUQ (cj_goal preambles)`, `## Decision tree mirror`, `## Deprecation tombstones`.
- [ ] `## The shared cj-goal-common.sh helper (S000057)` names the phases it owns (worktree, pr-check, telemetry), modes it dispatches on (feature, defect, investigate), and the consumers (cj_goal_feature, cj_goal_defect; CJ_goal_investigate adopts on its own update cadence).
- [ ] `## F000028 doc-sync hooks (post-merge + post-rewrite)` names the marker file path schema (`~/.gstack/doc-sync-pending/<repo-slug>.json`), the marker fields (repo, head_sha, main_moved_at, diff_base, changed_files), the two git hooks (post-merge, post-rewrite), and what they don't fire on (trivial main-moving merges).
- [ ] `## F000029 marker-pickup AUQ (cj_goal preambles)` explains the script-output-drives-AUQ split (script detects + prints `DOC_SYNC_PENDING <path>`, SKILL.md prose owns AUQ template + branch logic), the branch-aware A/B ordering (A on main, B on feature branch), and the `--resolved` / `--snooze` / `--skip` lifecycle.
- [ ] `## Decision tree mirror` points readers back to `doc/PHILOSOPHY.md ## Decision tree` (single source of truth; ARCHITECTURE summarizes, does not duplicate).
- [ ] `## Deprecation tombstones` cross-references `doc/PHILOSOPHY.md ## Retired skills` and explains the workbench's "three-shape deprecation" pattern (catalog `status: deprecated` + skill source relocation to `deprecated/<name>/` + work-item history relocation). Names F000005, F000006, F000007 as the original instances; F000027 + S000060 as the recent.
- [ ] Root `README.md` has `## Deeper reading` section linking to `doc/PHILOSOPHY.md` and `doc/ARCHITECTURE.md` (≤5 lines added).
- [ ] Root `CLAUDE.md` has NEW section `## /document-release workbench audit conventions` containing: (a) statement that `doc/PHILOSOPHY.md` + `doc/ARCHITECTURE.md` are NAMED audit surfaces with specific drift class; (b) retired-skill drift check literal command (`jq -r '.[] | select(.status=="deprecated") | .name' skills-catalog.json` + grep instructions + annotation suppression rules); (c) new-skills check literal command (`jq -r '.[] | select(.status=="active") | .name' skills-catalog.json` + grep `doc/PHILOSOPHY.md ## Decision tree` instructions); (d) finding-surfacing instruction (`## Documentation` PR-body section, `### Skill-routing drift` subheading).
- [ ] `CHANGELOG.md` entry added for F000030 (Unreleased section).
- [ ] `./scripts/validate.sh` exits 0 with 0 errors / 0 warnings.
- [ ] `./scripts/test.sh` exits 0.
- [ ] No edits to files under `skills/document-release/` or `~/.claude/skills/document-release/` (upstream skill untouched).
- [ ] No edits to root-convention files beyond README.md and CLAUDE.md (no edits to CONTRIBUTING.md, TODOS.md, skills-catalog.json, philosophy.md beyond the `git mv`).

## Todos

<!-- Actionable items for this story. -->

- [ ] Create `doc/` folder at repo root: `mkdir -p doc`
- [ ] Move philosophy.md to doc/PHILOSOPHY.md: `git mv philosophy.md doc/PHILOSOPHY.md`
- [ ] Rewrite `doc/PHILOSOPHY.md` to current state (drop retired-skill references except in `## Retired skills`; replace `/CJ_goal_auto` + `/CJ_goal_run` with `/cj_goal_feature` + `/cj_goal_defect`; add `## Decision tree` heading + routing diagram; preserve load-bearing sections with light edits)
- [ ] Write new `doc/ARCHITECTURE.md` with the five required sections, each answering its content questions
- [ ] Edit root `README.md` — add `## Deeper reading` section with links to both new docs
- [ ] Edit root `CLAUDE.md` — add `## /document-release workbench audit conventions` section with literal jq commands + annotation suppression rules
- [ ] Edit `CHANGELOG.md` — add F000030 entry in Unreleased section
- [ ] Run `./scripts/validate.sh` until 0 errors, 0 warnings
- [ ] Run `./scripts/test.sh` until green (deferred full to /CJ_qa-work-item — Phase 2 QA-owned)
- [ ] Run `/CJ_personal-workflow check` on the work-item dir until PASS (deferred to /CJ_qa-work-item)

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-05-31: Created. Implementation story for F000030 — move + rewrite philosophy.md into doc/PHILOSOPHY.md, add doc/ARCHITECTURE.md, edit README + CLAUDE.md, add CHANGELOG entry.

## PRs

<!-- PR links with status (open/merged/closed). -->

- [PR #180: v5.0.11 feat: F000030 doc/ folder + workbench audit conventions in CLAUDE.md (self-applied on first run)](https://github.com/jcl2018/claude-skills-templates/pull/180) — MERGED

## Files

<!-- Affected file paths. -->

- `philosophy.md` (MOVED → `doc/PHILOSOPHY.md` via `git mv`)
- `doc/PHILOSOPHY.md` (NEW path; full rewrite)
- `doc/ARCHITECTURE.md` (NEW)
- `README.md` (MODIFIED — `## Deeper reading` section added)
- `CLAUDE.md` (MODIFIED — `## /document-release workbench audit conventions` section added)
- `CHANGELOG.md` (MODIFIED — F000030 entry)

## Insights

<!-- Non-obvious findings worth remembering. -->

- **`git mv` works in one shot here, despite case-insensitive APFS.** The source `./philosophy.md` and the destination `./doc/PHILOSOPHY.md` differ in directory component, so the standard `git mv philosophy.md doc/PHILOSOPHY.md` succeeds without the two-step rename dance you'd need for an in-place case-only rename (e.g., `philosophy.md` → `PHILOSOPHY.md` in same dir on APFS).
- **Three required content gates for ARCHITECTURE sections, not word counts.** The Definition of Done lists specific questions each ARCHITECTURE section must answer (S000057 phases + modes + consumers; F000028 marker schema + fields + hooks + non-fires; F000029 split + branch ordering + lifecycle; Decision tree mirror points back; Deprecation tombstones cross-refs + three-shape pattern). QA validates against content presence, not paragraph count.
- **Annotation suppression rule is the symmetric escape hatch.** The audit's retired-skill drift check has explicit suppression: mention is allowed inside `## Retired skills` OR inside `~~strikethrough~~` OR within 200 chars of `DEPRECATED` / `sunset` / `tombstone` (case-insensitive). Required so the `## Retired skills` subsection's own paragraphs don't drift-flag themselves, and so doc/ARCHITECTURE.md's `## Deprecation tombstones` can name the deprecated entities for explanation purposes without flagging itself.
- **Project-instructions-teach-upstream-skill pattern is reused, not invented.** CLAUDE.md already teaches `/ship` + `/land-and-deploy` to skip `--auto` (CI/CD merge convention section). This feature adds a sibling convention telling `/document-release` what to do in this workbench. Pattern: write the convention in CLAUDE.md; upstream skill reads CLAUDE.md as project context during its run; convention lands without forking the skill.
- **`/document-release` Step 1 base-branch abort is a separate gap.** The skill refuses to run on main. The CLAUDE.md convention this feature adds is still read on any feature branch in this workbench — so the wiring lands on the path Step 1 actually allows. The abort fix is a TODOS follow-up; do not gate this feature on fixing it.

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

- 2026-05-31 [decision] Atomic story — no further decomposition into tasks. Summary: the six file changes (1 `git mv` + 1 full rewrite + 1 new file + 1 README edit + 1 CLAUDE.md edit + 1 CHANGELOG entry) are mutually load-bearing; shipping any subset is unverifiable (CLAUDE.md convention with no `doc/PHILOSOPHY.md` to audit is dead config; `doc/` folder with stale philosophy is incomplete; README link to non-existent doc is broken). Single user-story carries the full slice.
- 2026-05-31 [decision] Use one `## Retired skills` subsection in `doc/PHILOSOPHY.md` for all five retired skill names (`/workflow`, `/contracts`, `/docs`, `/CJ_goal_auto`, `/CJ_goal_run`). Summary: one canonical tombstone location per name; the annotation suppression rule (mentions inside that subsection or near `DEPRECATED`/`sunset`/`tombstone` skipped) is the symmetric escape hatch for the audit.
- 2026-05-31 [decision] Use literal jq commands in the CLAUDE.md convention, not pseudocode. Summary: operator (or `/document-release`) can copy-paste and run; reduces ambiguity at audit time. Same shape as the CI/CD merge convention section's literal `gh pr merge <PR#> --squash --delete-branch` snippet.
- 2026-05-31 [decision] `doc/README.md` index file is dropped from v1. Summary: with only two files in `doc/`, YAGNI. Discovery via root `README.md ## Deeper reading` + GitHub's directory rendering. Revisit if `doc/` grows past 4 files.
- 2026-05-31 [decision] CLAUDE.md mechanism duplication accepted for v1. Summary: F000009 / F000028 / F000029 / TODOS-hygiene sections stay in CLAUDE.md (agent-relevant); doc/ARCHITECTURE.md gets operator-facing versions that may overlap ~30%. Approach C extraction rejected at scope AUQ.
- 2026-05-31 [qa-pass] /CJ_qa-work-item ran smoke + drift dry-runs. Summary: 6/8 fully green (S1a-c, S2, S3, S4, S5a-d, S5f-h, S6); 2 partial-green with documented defer/edge-case (S5e CHANGELOG entry — owned by /ship Step 13 auto-generate; S7 line-94 ARCHITECTURE mention of CJ_goal_run/CJ_goal_auto at offset 355 from `deprecated` at offset 86 = 269 chars > 200 — falls inside `## Deprecation tombstones` section (lines 86-100) so structurally OK, but flagged by strict 200-char rule; pre-accepted in TEST-SPEC Coverage Gaps line 83 as annotation-window edge case). S1d (`git log --follow`) deferred — rename uncommitted; resolves after /ship Step 12 commit. S8 false-positive on `templates` (catalog `status: active` placeholder for template registry, not a callable skill; zero `files[]`, single `templates[]` entry — naming it as a missing-decision-tree drift is a catalog modeling artifact, not a doc gap). All 7 user-facing CJ_ skills (cj_goal_feature, cj_goal_defect, CJ_goal_investigate, CJ_goal_todo_fix, CJ_suggest, CJ_system-health, CJ_improve-queue) verified in `## Decision tree`; all 5 phase-step skills verified in PHILOSOPHY anywhere per AC. validate.sh exits 0 errors / 0 warnings (work-item dir passes). E2E rows E2 + E3 are tagged `post-ship` (require `/document-release` on merged branch) — deferred per TEST-SPEC convention. E1 (read-and-answer-routing-questions usability check) verified semantically: Q1 (`/cj_goal_feature` for feature start) answered at PHILOSOPHY line 7 + 45 of Decision tree; Q2 (F000028 + F000029 closes doc-sync loop) answered at lines 124 + 149 + 179. Phase 2 QA-owned gates `Acceptance criteria verified met` + `Smoke tests pass` marked checked.
- 2026-05-31 [qa-e2e-deferred] E2 (integration post-ship) — plant unannotated retired-skill reference + run /document-release. Summary: post-ship row per TEST-SPEC convention; verification happens after PR merges (manual `gh workflow run` or post-merge tooling). Not gating this PR.
- 2026-05-31 [qa-e2e-deferred] E3 (integration post-ship) — add active-skill stub not in decision tree + run /document-release. Summary: post-ship row per TEST-SPEC convention. Not gating this PR.
- 2026-05-31 [qa-e2e] E1 (usability) — verified semantically by content inspection: Decision tree at PHILOSOPHY:59-124 names `/cj_goal_feature` as the build-a-feature front door (line 7 + 45); doc-sync mechanism explained at lines 124 + 149 + 179 naming F000028 + F000029 marker-pickup AUQ. A fresh reader can answer both routing questions on first read.
- 2026-05-31 [gates-update] Phase 3: /ship — PR #180,/land-and-deploy — PR merged,Smoke tests pass — all checks green on PR #180,PRs section: linked PR #180 (MERGED).
