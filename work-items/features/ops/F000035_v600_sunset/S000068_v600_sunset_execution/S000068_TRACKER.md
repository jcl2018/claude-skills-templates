---
name: "v6.0.0 sunset execution (atomic full-nuke commit)"
type: user-story
id: "S000068"
status: active
created: "2026-06-02"
updated: "2026-06-02"
parent: "F000035"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "cj-feat-20260602-010655-sunset"
blocked_by: ""
# pr: ""  # optional; populate with PR URL for explicit PR-state lookups.
---

<!-- Prerequisite: Before scaffolding this work item, run /office-hours to
     produce a design plan in ~/.gstack/projects/. Distill that plan into
     DESIGN.md during Phase 1 below. -->

## Lifecycle

### Phase 1: Track

1. Read parent tracker to understand scope
2. Create working branch: `git checkout -b feat/v600_sunset_execution` (or use parent's branch `cj-feat-20260602-010655-sunset` — shipping in same PR)
3. Scaffold work item directory and TRACKER.md
4. Distill `DESIGN.md` from the /office-hours output — from `templates/doc-DESIGN.md`
5. Scaffold `SPEC.md` (requirements, acceptance criteria, architecture, tradeoffs) — from `templates/doc-SPEC.md`
6. Scaffold `TEST-SPEC.md` (smoke + E2E test scenarios) — from `templates/doc-TEST-SPEC.md`
7. Break into child tasks if scope warrants decomposition (N/A — atomic story)

**Gates:**
- [x] /office-hours design referenced (parent F000035 design)
- [x] Working branch created (`branch` field populated — uses parent's feature branch)
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
- [ ] Acceptance criteria verified met
- [ ] Smoke tests pass
- [ ] Todos section reflects remaining work (no stale items)
- [ ] Files section updated with changed files

### Phase 3: Ship

1. Run `/CJ_personal-workflow check` — verify all validation passes
2. Verify smoke tests pass in CI (automated regression)
3. Walk E2E manually — drive the feature as a user would
4. Ensure all child tasks (if any) have shipped — N/A
5. Run `/ship` — creates PR, bumps version, updates changelog (includes pre-landing code review)
6. Run `/land-and-deploy` — merges PR and verifies deployment

❌ If `/CJ_personal-workflow check` finds issues: fix findings, re-run until clean
❌ If smoke or E2E fails: fix, re-run

**Gates:**
- [ ] `/CJ_personal-workflow check` — validation passed
- [ ] Smoke tests pass in CI
- [ ] E2E walked manually
- [ ] All children shipped (if any) — N/A
- [ ] `/ship` — PR created (with pre-landing review)
- [ ] `/land-and-deploy` — merged and deployed (deferred to operator per workbench auto-deploy safety)

## Acceptance Criteria

- [ ] 5 deprecated skill directories deleted: `skills/CJ_goal_run/`, `skills/CJ_goal_auto/`, `deprecated/CJ_goal_investigate/`, `deprecated/cj_goal_feature/`, `deprecated/cj_goal_defect/`
- [ ] `deprecated/` directory deleted entirely (including its `README.md` and `work-items/` subtree)
- [ ] 5 deprecated entries filtered out of `skills-catalog.json`; post-edit status values are only `active` + `experimental`
- [ ] `scripts/validate.sh` Check 9b closed-enum updated to `{active, experimental}`; fail messages + comment updated
- [ ] `scripts/skills-deploy`: all 6 `--include-deprecated` handling sites removed (arg parse + gate `if` block + post-install INFO labels + help text); `grep -c 'deprecat' scripts/skills-deploy` returns 0
- [ ] `scripts/generate-readme.sh`: `DEPRECATED_COUNT` line + `if DEPRECATED_COUNT > 0` block removed
- [ ] CLAUDE.md surgeries: `## Skill routing` "Deprecated front doors" paragraphs deleted; `### Deprecated skills convention` subsection deleted; `### Retired-skill drift check` subsection deleted; auto-worktree `~~CJ_goal_investigate~~` bullet deleted
- [ ] `doc/PHILOSOPHY.md ## Retired skills` section deleted; cross-references updated
- [ ] `doc/ARCHITECTURE.md ## Deprecation tombstones` section deleted; inline deprecation mentions rewritten
- [ ] `rules/skill-routing.md ## Deprecated front doors` section deleted
- [ ] Tests: `tests/cj-goal-investigate-shim.test.sh` deleted; `tests/cj-goal-investigate-did-allocator.test.sh` deleted; `tests/eval/CJ_goal_run/` deleted; `tests/cj-worktree-init.test.sh` inspected + updated if needed; `tests/cj-goal-doc-sync-auq-recommendation.test.sh` inspected + updated if needed
- [ ] TODOS.md sweep: v6.0.0 sunset-related rows marked strikethrough + completion-annotated
- [ ] Memory cleanup: `project_investigate_retire_candidate.md` deleted; `MEMORY.md` index line removed
- [ ] `VERSION` → `6.0.0`; `CHANGELOG.md` has `## [6.0.0] - 2026-06-02` entry with `### Removed` body
- [ ] `./scripts/generate-readme.sh` regen produces a README with no `### Deprecated` table
- [ ] `./scripts/validate.sh` passes with 0 errors; `./scripts/test.sh` passes
- [ ] PR title: `v6.0.0 feat: F000035 sunset deprecated shims + deprecation infrastructure (full nuke)`

## Todos

- [ ] Step 1: Delete 5 deprecated skill dirs
- [ ] Step 2: `rm -rf deprecated/`
- [ ] Step 3: Filter `skills-catalog.json` (jq + atomic mv)
- [ ] Step 4: Edit `scripts/validate.sh` Check 9b closed-enum (3 sites: case statement, 2 fail messages, comment)
- [ ] Step 5: Edit `scripts/skills-deploy` — remove 6 `--include-deprecated` sites
- [ ] Step 6: Simplify `scripts/generate-readme.sh` — drop DEPRECATED_COUNT block
- [ ] Step 7: CLAUDE.md — 4 distinct surgeries
- [ ] Step 8: `doc/PHILOSOPHY.md` — delete `## Retired skills` + cross-refs
- [ ] Step 9: `doc/ARCHITECTURE.md` — delete `## Deprecation tombstones` + inline deprecation rewrites
- [ ] Step 10: `rules/skill-routing.md` — delete `## Deprecated front doors`
- [ ] Step 11: Tests — delete 2 + delete `tests/eval/CJ_goal_run/` + inspect/update 2
- [ ] Step 12: TODOS.md hygiene sweep
- [ ] Step 13: Memory cleanup
- [ ] Step 14: VERSION + CHANGELOG
- [ ] Step 15: README regen
- [ ] Step 16: Atomic single-commit stage (per DESIGN — Check 9b enum staged with catalog filter)
- [ ] `/CJ_personal-workflow check` clean on F000035 tree
- [ ] `/ship` — open PR, no auto-merge

## Log

- 2026-06-02: Created. Atomic single-story execution of F000035 v6.0.0 sunset.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. -->

- VERSION, CHANGELOG.md, README.md, CLAUDE.md, TODOS.md
- skills-catalog.json
- rules/skill-routing.md
- doc/PHILOSOPHY.md, doc/ARCHITECTURE.md
- scripts/validate.sh, scripts/skills-deploy, scripts/generate-readme.sh
- skills/CJ_goal_run/* (deleted), skills/CJ_goal_auto/* (deleted)
- deprecated/* (deleted, entire tree)
- tests/cj-goal-investigate-shim.test.sh (deleted)
- tests/cj-goal-investigate-did-allocator.test.sh (deleted)
- tests/eval/CJ_goal_run/* (deleted)
- tests/cj-worktree-init.test.sh (potentially updated)
- tests/cj-goal-doc-sync-auq-recommendation.test.sh (potentially updated)
- ~/.claude/projects/.../memory/project_investigate_retire_candidate.md (deleted)
- ~/.claude/projects/.../memory/MEMORY.md (index line removed)

## Insights

- Single-commit atomicity is non-negotiable: Check 9b enum change MUST stage with catalog filter so the staged enum matches the staged catalog. Pre-commit validate.sh runs against the staged tree.
- Step 16 of the design is really an ordering constraint, not a separate step: all 15 prior steps converge into one `git add -A` + one commit.
- The 5-skill deletion + `deprecated/` deletion + catalog filter could in principle ship as 3 commits, but the closed-enum validate.sh edit can't ship before the catalog filter (validate would fail) or after (un-rebased validate would fail). Bundling is the only safe order.

## Journal

- [decision] 2026-06-02: Atomic single-story (no decomposition). Summary: Check 9b enum edit + catalog filter must stage together; splitting into multiple stories risks transient validate.sh red. One commit, all 15 surgical edits + 1 ordering constraint.
- [decision] 2026-06-02: Leave validate.sh Check 13/14/15 predicates as-is (`status != "deprecated"`). Summary: Robust to future re-introduction of the enum value; filters nothing today.
- [finding] 2026-06-02: `tests/cj-worktree-init.test.sh` may have investigate-specific case rows per T000035 retirement; needs surgical update during Phase 2, not delete.
- [gates-update] 2026-06-02: Phase 2 Implement complete. Summary: All 16 design steps executed atomically in the worktree. Deletions: 5 shim dirs (skills/CJ_goal_{run,auto}/, deprecated/{CJ_goal_investigate,cj_goal_feature,cj_goal_defect}/), entire deprecated/ tree, 5 catalog entries (17 → 12), `tests/cj-goal-investigate-{shim,did-allocator}.test.sh`, `tests/eval/CJ_goal_run/`, memory file `project_investigate_retire_candidate.md`. Surgical edits to scripts/validate.sh Check 9b enum (active|experimental), scripts/skills-deploy (--include-deprecated removed end-to-end), scripts/generate-readme.sh (DEPRECATED_COUNT block removed), CLAUDE.md (4 subsections + 1 strikethrough bullet removed), doc/PHILOSOPHY.md (## Retired skills + drift-rule prose removed), doc/ARCHITECTURE.md (## Deprecation tombstones + 4 inline mentions cleaned), rules/skill-routing.md (## Deprecated front doors removed), tests/cj-worktree-init.test.sh (case h5 + pipeline.md grep guards removed; investigate→defect caller swap on cases a-g), tests/cj-goal-doc-sync-auq-recommendation.test.sh (deprecated-narrative comment cleaned). TODOS rows 5 + 48 marked DONE. MEMORY.md index line removed. VERSION 5.0.19 → 6.0.0. CHANGELOG entry prepended. README.md regenerated. Awaiting QA + /ship.
- [qa] 2026-06-02: QA verification by /CJ_qa-work-item. RESULT=red. Summary: TEST-SPEC smoke S5 (`./scripts/test.sh` passes) FAILS — 7 test failures from stale rows in scripts/test.sh itself that the implementation phase forgot to update. Stale rows still grep for skills/CJ_goal_run/SKILL.md, deprecated/CJ_goal_investigate/SKILL.md, skills/CJ_goal_run/run.md, skills/CJ_goal_auto/auto.md, and invoke deleted tests/cj-goal-investigate-{shim,did-allocator}.test.sh. validate.sh PASSES; all 13 structural verification checks PASS (catalog 12 entries, status enum closed to {active,experimental}, deprecated/ + shim dirs absent, all 5 convention/tombstone headings removed, VERSION=6.0.0, CHANGELOG 6.0.0 present, README clean, generate-readme idempotent + clean, skills-deploy --help clean, skills-deploy bash -n clean). Also flagged 3 residual mentions in active prose: README.md L15 + skills-catalog.json L138 (CJ_personal-pipeline description still mentions /CJ_goal_run) + CLAUDE.md L438 (Edge case 2 subsection retained). Phase 2 QA gates NOT transitioned to green; AC-15 in SPEC explicitly requires test.sh to pass. Remediation: prune stale rows from scripts/test.sh at the line ranges identified in the F000035 tracker [qa] entry, regenerate README from updated catalog, drop the CLAUDE.md Edge case 2 subsection, then re-run validate.sh + test.sh.

- 2026-06-02T08:44:17Z [qa-reverify] QA RED caught 7 test.sh failures + 4 residual mentions; orchestrator applied 7 fixes: (1) trimmed 2 stale shim assertions from F000025 Regression test in scripts/test.sh (CJ_goal_run + CJ_goal_investigate shim greps); (2) replaced did-allocator test runner block with a tombstone comment; (3) replaced investigate-shim test runner block with a tombstone comment; (4) deleted F000026 Tests 8-11 (the auto.md/run.md sentinel/classifier assertions; Tests 1-7 of cj-handoff-gate.sh helper kept — still in use by /CJ_goal_feature + /CJ_goal_defect; Tests 12-13 kept numerically); (5) skills-catalog.json CJ_personal-pipeline description updated to reference /CJ_goal_todo_fix + /CJ_goal_feature (was '/CJ_goal_run'); (6) deleted CLAUDE.md `### Edge case 2: multi-PR bundles via /CJ_goal_run` subsection; (7) doc/SKILL-CATALOG.md CJ_personal-pipeline status line dropped 'historically by /CJ_goal_run' suffix; bonus (8) skills-catalog.json CJ_goal_defect description dropped historical '~80% reshape of /CJ_goal_investigate v1.1' lineage; README.md regenerated. ./scripts/validate.sh → PASS (0 errors); ./scripts/test.sh → PASS (0 failures, Test 13 SKIP-with-presence-check). All residual-prose grep findings now in TODOS.md DONE/archived rows only (historical record preserved per CLAUDE.md TODOS.md hygiene). Phase 2 QA gates green; ready for /ship.
