---
name: "Rename /CJ_ship-feature → /CJ_run + Branch(g) no-arg branch scan"
type: user-story
id: "S000038"
status: active
created: "2026-05-13"
updated: "2026-05-13"
parent: "F000017"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "claude/awesome-pasteur-36565c"
blocked_by: ""
---

<!-- Atomic story under F000017. Design context: parent F000017_DESIGN.md and
     source design at
     ~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-claude-awesome-pasteur-36565c-design-20260513-154622.md -->

## Lifecycle

### Phase 1: Track

1. Read parent tracker to understand scope
2. Create working branch: `git checkout -b feat/cj_run_rename` (or use parent's branch if shipping in same PR)
3. Scaffold work item directory and TRACKER.md
4. Distill `DESIGN.md` from the parent F000017_DESIGN.md
5. Scaffold `SPEC.md` (requirements, acceptance criteria, architecture, tradeoffs)
6. Scaffold `TEST-SPEC.md` (smoke + E2E test scenarios)
7. Break into child tasks if scope warrants decomposition — N/A (atomic story)

**Gates:**
- [x] /office-hours design referenced (parent's F000017_DESIGN.md and source design)
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
- [x] Todos section reflects remaining work (no stale items)
- [x] Files section updated with changed files

### Phase 3: Ship

1. Run `/CJ_personal-workflow check` — verify all validation passes
2. Verify smoke tests pass in CI (automated regression)
3. Walk E2E manually — drive the feature as a user would (TEST-SPEC `## E2E Tests` table)
4. Ensure all child tasks (if any) have shipped — N/A
5. Run `/ship` — creates PR, bumps version, updates changelog (includes pre-landing code review)
6. Run `/land-and-deploy` — merges PR and verifies deployment

**Gates:**
- [ ] `/CJ_personal-workflow check` — validation passed
- [ ] Smoke tests pass in CI
- [ ] E2E walked manually
- [ ] All children shipped (N/A — atomic)
- [ ] `/ship` — PR created (with pre-landing review)
- [ ] `/land-and-deploy` — merged and deployed

## Acceptance Criteria

- [ ] `skills/CJ_ship-feature/` renamed to `skills/CJ_run/` via `git mv`
- [ ] `skills/CJ_run/SKILL.md` `name:` updated to `CJ_run`, version bumped to 0.2.0, description rewritten to reflect new input modes
- [ ] `skills/CJ_run/ship-feature.md` renamed to `skills/CJ_run/run.md`
- [ ] `skills/CJ_run/run.md` Step 1 contains new Branch(g) logic (no-arg branch scan)
- [ ] `skills-catalog.json` entry renamed `CJ_ship-feature` → `CJ_run`
- [ ] `rules/skill-routing.md` routing entries updated: `/CJ_run` replaces `/CJ_ship-feature`; `/CJ_personal-pipeline` removed
- [ ] `skills/CJ_personal-pipeline/SKILL.md` description prefixed with "INTERNAL — invoked by /CJ_run. Do not call directly."
- [ ] `skills-catalog.json` `CJ_personal-pipeline` description matches the SKILL.md update
- [ ] `validate.sh` passes
- [ ] Telemetry log path updated to `CJ_run.jsonl` (fresh counter)
- [ ] `/CJ_run` (no args) on the current branch with 1 in-progress work-item → auto-resumes correctly
- [ ] `/CJ_run` (no args) with no `work-items/` dir → prints "No work-items/ found." and exits 0

## Todos

- [x] `git mv skills/CJ_ship-feature skills/CJ_run`
- [x] Update `skills/CJ_run/SKILL.md` frontmatter (`name:`, `version:`, `description:`)
- [x] Rename `ship-feature.md` → `run.md` (and update references in SKILL.md)
- [x] Add Branch(g) logic at Step 1 of `run.md` (bash 3.2 compatible while-read loop)
- [x] Update branch summary table in `run.md` to include Branch(g)
- [x] Update `skills-catalog.json`: rename `CJ_ship-feature` entry, update file paths, update description
- [x] Update `rules/skill-routing.md`: replace `/CJ_ship-feature` and `/CJ_personal-pipeline` routes with `/CJ_run`
- [x] Update `skills/CJ_personal-pipeline/SKILL.md` description and catalog entry
- [x] Update telemetry log path constant in `run.md`
- [x] Run `./scripts/validate.sh` and fix any drift (passed: 0 errors, 0 warnings)
- [ ] Manual smoke: `/CJ_run` (no args) on this branch with F000017 partially in progress (QA-owned)

## Log

- 2026-05-13: Created. Atomic story for the mechanical rename + new Branch(g) no-arg scan.
- 2026-05-13: Implementation complete. 6 files changed (1 dir rename + 1 file rename + 4 modifications). validate.sh PASS (0 errors, 0 warnings). Phase 2 implementer-owned gates transitioned.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

- `skills/CJ_ship-feature/` → `skills/CJ_run/` (renamed via git mv)
- `skills/CJ_run/SKILL.md` (modified: name → CJ_run, version → 0.2.0, description rewritten, all internal refs updated)
- `skills/CJ_run/run.md` (renamed from ship-feature.md; new Branch summary table + Branch(g) implementation + Branch(f) placeholder at Step 1; telemetry log path → CJ_run.jsonl; state file path → /tmp/cj-run-*.env)
- `skills/CJ_personal-pipeline/SKILL.md` (modified: description prefixed with "INTERNAL — invoked by /CJ_run. Do not call directly.")
- `skills-catalog.json` (modified: CJ_ship-feature entry renamed to CJ_run, version → 0.2.0, description rewritten, files paths updated; CJ_personal-pipeline description prefixed with INTERNAL)
- `rules/skill-routing.md` (modified: lines 10-11 → /CJ_run routing for design-doc, work-item-dir, and no-arg invocations; /CJ_ship-feature and /CJ_personal-pipeline routes removed)

## Insights

- Branch(g) is `bash 3.2` compatible: uses `while IFS= read -r` (not `mapfile -t` which requires bash 4+). macOS ships with bash 3.2 by default.
- The Phase 1 gate-string detection in Branch(g) is user-story-specific. Defect/task TRACKERs use different phrasing. Document the limitation in SPEC.
- This story is independent of F000016 — can ship in parallel or before. No /CJ_personal-pipeline `--work-item-dir` flag is needed for Branch(g); that's S000039's concern.

## Journal

- 2026-05-13 [decision] Bundle rename and Branch(g) into one story rather than splitting. Rationale: Branch(g) lives inside the file being renamed (`run.md`); separate stories would touch the same file twice with merge-conflict risk.
- 2026-05-13 [decision] No backward-compat shim for `/CJ_ship-feature`. Direct callers (scripts, memory files, custom commands) must update.
- 2026-05-13 [impl-decision] Used `sed -i.bak` for bulk rename of 22 references in run.md after the surgical Edit of Step 1. Rationale: bulk-replace is mechanical (single token mapping), keeps the diff reviewable, faster than per-occurrence Edit.
- 2026-05-13 [impl-decision] Branch(f) Step 1.1 left as a placeholder ("not yet implemented") that prints a clear message and exits. Rationale: full Branch(f) is S000039's scope; placeholder makes the dispatch path observable without breaking on missing logic.
- 2026-05-13 [impl-decision] Branch(g) multi-candidate case prints the list and exits 0 with a "re-invoke with explicit path" message rather than blocking with AskUserQuestion. Rationale: SKILL-level bash blocks cannot invoke AUQ; AUQ is orchestrator-mediated (model-side). The bash output is the protocol for the model to render the AUQ.
- 2026-05-13 [impl-finding] CJ_personal-pipeline description prefix updated in BOTH skills-catalog.json AND skills/CJ_personal-pipeline/SKILL.md frontmatter. Catalog description and SKILL frontmatter must stay in sync.
- 2026-05-13 [impl] Renamed skills/CJ_ship-feature/ → skills/CJ_run/ via git mv; renamed ship-feature.md → run.md; updated 19 refs in SKILL.md, 22 refs in run.md, 2 routing entries in rules/skill-routing.md, 2 catalog entries (CJ_run + CJ_personal-pipeline), 1 SKILL.md description prefix. Added Branch(g) implementation (~60 lines of bash 3.2 compatible code) + Branch(f) placeholder in run.md Step 1. validate.sh PASS (0 errors, 0 warnings).
- 2026-05-13 [impl-pass] S000038: implementation complete. Phase 2 implementer-owned gates transitioned. validate.sh PASS.
- 2026-05-13 [qa-smoke] S1 (AC-1): green — validate.sh exit 0
- 2026-05-13 [qa-smoke] S2 (AC-1): green — 3 CJ_run refs in rules/skill-routing.md, no stale CJ_ship-feature or CJ_personal-pipeline entries
- 2026-05-13 [qa-smoke-manual] S3 (AC-3): pending human verification — Branch(g) on /tmp/empty-repo mock requires deployed /CJ_run skill; defer to post-deploy E2E
- 2026-05-13 [qa-smoke] S4 (AC-8): red — `grep -q 'mapfile' skills/CJ_run/run.md` matches a comment ("uses `while IFS= read -r` (not `mapfile -t`)" at run.md:113). Test pattern is over-broad; intent is "no mapfile usage" not "no mapfile token"
- 2026-05-13 [qa-smoke] S5 (AC-6): green — 5 CJ_run.jsonl references in run.md
- 2026-05-13 [qa-smoke-summary] red: 3/4 non-manual rows green (1 manual row pending) — S4 false positive caused by over-broad grep pattern matching a documentation counter-example
- 2026-05-13 [qa-decision] S4 test pattern refined: now extracts only ```bash code blocks (excluding comments) and checks for `mapfile -` / `readarray -` command usage. Rationale: the original `grep -q 'mapfile'` matched a documentation counter-example in a prose comment. Intent of AC-8 (bash 3.2 compat) preserved; new pattern is more precise.
- 2026-05-13 [qa-smoke] S4 (AC-8): green — bash-block scan finds 0 `mapfile -`/`readarray -` command uses and 1 `while IFS= read` use in Branch(g)
- 2026-05-13 [qa-smoke-summary] green (re-run after S4 pattern fix): 4/4 non-manual rows green (1 manual row pending: S3 requires deployed /CJ_run skill)
- 2026-05-13 [qa-e2e-run-start] RUN_ID=20260513-163204-28020 commit=cd8de4a
- 2026-05-13 [qa-e2e] E1 (AC-2): ambiguous — needs skills-deploy install to run live; structural verification suggests pass. Branch(g) single-candidate path at skills/CJ_run/run.md:158-163 sets INPUT_MODE="work-item-dir" and falls through to Branch(f) at run.md:189-194 (placeholder prints "Branch(f) phase-detection + dispatch is implemented in S000039" and exits 0). Dispatch wiring is in place; pipeline-resume body is S000039's scope per design.
- 2026-05-13 [qa-e2e] E2 (AC-3): ambiguous — needs skills-deploy install to run live; structural verification suggests pass. run.md:122-125 prints exact expected message ("No work-items/ found. Run /office-hours or /CJ_scaffold-work-item first.") and `exit 0` before any candidate scan or trace.
- 2026-05-13 [qa-e2e] E3 (AC-4): ambiguous — needs skills-deploy install to run live; structural verification suggests pass with a contract-shape note. Multi-candidate path at run.md:164-176 prints candidate list and exits 0; AUQ enumeration is orchestrator-mediated per [impl-decision] at journal entry above (SKILL-level bash cannot invoke AUQ directly). User-observable outcome (AUQ enumerates both, user picks one) is achieved by the model rendering AUQ on the printed list and re-invoking with explicit path. The non-picked story is untouched since each invocation operates on one explicit path.
- 2026-05-13 [qa-e2e] E4 (AC-5): green — rules/skill-routing.md has 3 /CJ_run routing entries (lines 10-12) covering design-doc, work-item-dir, and no-arg invocations; zero CJ_ship-feature or CJ_personal-pipeline mentions. Routing matches the design.
- 2026-05-13 [qa-e2e-summary] ambiguous (46s subagent; 0 rows parent-inline; 0 deferred): 1 green (E4), 3 ambiguous-structural-pass (E1, E2, E3). All ambiguity stems from /CJ_run not yet being deployed to ~/.claude/skills/; structural inspection of skills/CJ_run/run.md confirms each branch's expected behavior is wired correctly. Recommend post-deploy live re-verification before closing AC checkboxes on E1-E3.
- 2026-05-13 [qa-decision] User adjudicated E2E ambiguous → treat as green. Rationale: structural inspection passes for E1/E2/E3; full live verification requires post-deploy (`skills-deploy install`) which happens after /ship + /land-and-deploy. Manual smoke todo captures the post-deploy re-verification. Phase 2 gates transition; the live re-verify is the user's responsibility post-deploy.
- 2026-05-13 [qa-pass] S000038 (user-story): green smoke + green E2E (after user adjudication of structural-pass ambiguity). Phase 2 gates transitioned.
