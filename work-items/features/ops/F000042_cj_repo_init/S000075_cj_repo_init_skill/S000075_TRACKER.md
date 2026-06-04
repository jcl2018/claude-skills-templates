---
name: "cj-repo-init detection engine + skill + tests + wiring"
type: user-story
id: "S000075"
status: active
created: "2026-06-03"
updated: "2026-06-03"
parent: "F000042"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "cj-feat-20260603-174453-41356"
blocked_by: ""
---

<!-- Prerequisite: parent feature F000042's /office-hours session is the design source. -->

## Lifecycle

### Phase 1: Track

1. Read parent tracker to understand scope
2. Create working branch: `git checkout -b feat/cj_repo_init` (or use parent's branch if shipping in same PR)
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
- [x] Todos section reflects remaining work (no stale items)
- [x] Files section updated with changed files

### Phase 3: Ship

1. Run `/CJ_personal-workflow check` — verify all validation passes
2. Verify smoke tests pass in CI (automated regression)
3. Walk E2E manually — drive the feature as a user would (TEST-SPEC `## E2E Tests` table)
4. Ensure all child tasks (if any) have shipped
5. Run `/ship` — creates PR, bumps version, updates changelog (includes pre-landing code review)
6. Run `/land-and-deploy` — merges PR and verifies deployment

❌ If `/CJ_personal-workflow check` finds issues: fix findings, re-run until clean
❌ If smoke or E2E fails: fix, re-run

**Gates:**
- [ ] `/CJ_personal-workflow check` — validation passed
- [ ] Smoke tests pass in CI
- [ ] E2E walked manually
- [ ] All children shipped (N/A — no child tasks)
- [ ] `/ship` — PR created (with pre-landing review)
- [ ] `/land-and-deploy` — merged and deployed

## Acceptance Criteria

<!-- What "done" looks like for this story. -->

- [x] `scripts/cj-repo-init.sh` default run detects deployed CJ_ skills, builds the required-prereq set, verifies each, prints a health table, and emits machine-readable `GAPS=<n>` + per-gap lines.
- [x] `--fix` scaffolds the missing repo-level prereqs (`TODOS.md`, `cj-document-release.json`, `work-items/` dirs) from generic seeds; never touches install-level gaps.
- [x] `--dry-run` performs detection + table only and writes nothing.
- [x] Exit 0 when no repo-level gaps; exit 1 when repo-level gaps remain.
- [x] Scaffolded `cj-document-release.json` is parseable JSON with `schema_version: 1` (passes `validate.sh` Check 16).
- [x] Invalid/unparseable existing `cj-document-release.json` is reported as a gap.
- [x] `skills/CJ_repo-init/SKILL.md` runs detection, prints the table, surfaces ONE confirm AUQ on gaps, calls `--fix` on confirm, re-runs detection, prints post-fix table.
- [x] `tests/cj-repo-init.test.sh` exists, covers the cases above, and is wired into `scripts/test.sh`.

## Todos

<!-- Actionable items for this story. -->

- [x] Implement `scripts/cj-repo-init.sh` (detect / `--dry-run` / `--fix`) with inline generic seed heredocs.
- [x] Write `skills/CJ_repo-init/SKILL.md` (frontmatter incl. `allowed-tools`, detection wrapper, single confirm AUQ).
- [x] Write `skills/CJ_repo-init/USAGE.md` with all 5 required H2 sections.
- [x] Add `tests/cj-repo-init.test.sh`; wire into `scripts/test.sh` (explicit `Running tests/cj-repo-init.test.sh` invocation block added after the cj-goal-doc-sync-wiring block — tests are NOT auto-globbed in this repo).
- [x] Add skills-catalog.json entry (status: experimental); doc/SKILL-CATALOG.md section + `(single-step utility)` tag; rules/skill-routing.md trigger.

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-06-03: Created. Detection engine + skill wrapper + tests + catalog/doc/routing wiring for CJ_repo-init.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. -->

- `scripts/cj-repo-init.sh` (new)
- `skills/CJ_repo-init/SKILL.md` (new)
- `skills/CJ_repo-init/USAGE.md` (new)
- `tests/cj-repo-init.test.sh` (new)
- `scripts/test.sh` (modified)
- `skills-catalog.json` (modified)
- `doc/SKILL-CATALOG.md` (modified)
- `rules/skill-routing.md` (modified)

## Insights

<!-- Non-obvious findings worth remembering. -->

- Every new `validate.sh`/`test.sh` surface in this repo needs a parallel edit to `scripts/test.sh`'s zzz-test-scaffold integration fixture; the implement step has systematically forgotten this on prior features (F000032/F000034/F000035). Flag it during implementation.

## Journal

<!-- Structured entries from the work-track journal command. -->

- [decision] 2026-06-03: Single atomic user-story carries the whole feature. Summary: the engine + skill + tests + wiring are one cohesive change with no parallel sub-units, so no task children are scaffolded (Phase 1 gate marked N/A — atomic story per WORKFLOW.md line 120).
- 2026-06-03 [impl-finding] `--auto` demoted to propose-equivalent: 8 files touched + sensitive surfaces (skills-catalog.json, doc/SKILL-CATALOG.md, rules/skill-routing.md). Sensitive-surface AUQ would normally fire — these three edits are PRE-AUTHORIZED by the operator-approved /CJ_goal_feature design gate (creating a new skill mandates them per CLAUDE.md "Creating a new skill"). Proceeded without AUQ as a silent orchestrator runner.
- 2026-06-03 [impl-decision] Detection fallback chain implemented as manifest (.skills object keys, grep ^CJ_) → `find ~/.claude/skills -name CJ_*` → repo-local `skills/CJ_*` (DESIGN #3). Added a `CJ_REPO_INIT_CLAUDE_HOME` env override so the test harness can point detection at a synthetic ~/.claude without touching the operator's real one.
- 2026-06-03 [impl-decision] When detection finds NO deployed skills (detect source "none"), the engine conservatively requires all repo-level prereqs so a fresh-machine operator still gets a useful health table + scaffold path, rather than emitting an empty table.
- 2026-06-03 [impl-decision] Generated `cj-document-release.json` seed uses a PORTABLE whitelist (README/CHANGELOG/CLAUDE.md/CONTRIBUTING.md + `doc/**/*.md`) + 5 generic categories — deliberately NOT this workbench's own richer config (which carries workbench-specific paths). Verified the seed passes all five validate.sh Check 16 sub-assertions (schema_version=1, non-empty whitelist array, non-empty categories object, each category a non-empty array).
- 2026-06-03 [impl-decision] `--fix` does NOT overwrite a present-but-invalid `cj-document-release.json` — it reports a `NOTE:` to stderr and leaves the file. Clobbering an intentional-but-broken config would lose operator data; safer to surface and let them fix by hand.
- 2026-06-03 [impl-finding] KNOWN BLIND SPOT addressed: this repo's `scripts/test.sh` does NOT auto-glob `tests/*.test.sh` — each test is invoked by an explicit `bash "$REPO_ROOT/tests/X.test.sh"` block. Added the `Running tests/cj-repo-init.test.sh` block after the cj-goal-doc-sync-wiring block (F000032/F000034/F000035 each forgot this parallel edit).
- 2026-06-03 [impl] Wrote 4 files (scripts/cj-repo-init.sh, skills/CJ_repo-init/SKILL.md, skills/CJ_repo-init/USAGE.md, tests/cj-repo-init.test.sh); modified 4 (scripts/test.sh, skills-catalog.json, doc/SKILL-CATALOG.md, rules/skill-routing.md). Both .sh files chmod +x. validate.sh PASS (0 errors/0 warnings); cj-repo-init.test.sh all assertions pass.
- 2026-06-03 [impl-pass] S000075: implementation complete. Phase 2 implementer-owned gates transitioned (Todos + Files). QA-owned gates (Acceptance criteria verified met, Smoke tests pass) left for /CJ_qa-work-item.
- 2026-06-03 [qa-smoke] S1 (AC-1, AC-2): green — detect_emits_gaps: default run prints table + GAPS=3 + per-gap REPO_GAP lines; exit 1 with gaps present.
- 2026-06-03 [qa-smoke] S2 (AC-3, AC-5): green — fix_then_noop: --fix scaffolds 3 prereqs, exit 0, post-fix GAPS=0; idempotent re-run reports no-op, exit 0.
- 2026-06-03 [qa-smoke] S3 (AC-6): green — config_valid_and_invalid_detected: generated config passes all 4 Check-16 sub-assertions; unparseable + schema_version=2 flagged as invalid gap; --fix does not clobber present-but-invalid config.
- 2026-06-03 [qa-smoke] S4 (AC-4): green — dry_run_no_write: --dry-run mutates no files, exit 1, still reports GAPS=3.
- 2026-06-03 [qa-smoke] S5 (AC-9): green — degrades_cleanly: not-a-git-repo exits 2 with clear message; missing manifest + no skill dirs degrades to detect source 'none' with a GAPS= line, no crash.
- 2026-06-03 [qa-smoke-summary] green: 5/5 non-manual rows green (0 manual rows pending) — bash tests/cj-repo-init.test.sh all assertions passed, exit 0.
- 2026-06-03 [qa-e2e-run-start] RUN_ID=20260603-181404-44196 commit=ff22704
- 2026-06-03 [qa-e2e] E1 (AC-7): green — fresh-repo init: detection prints a 3-row gap table (GAPS=3, 3 REPO_GAP lines); skill Step 3 fires exactly ONE confirm AUQ; 'Scaffold now' runs --fix, creates TODOS.md + cj-document-release.json + work-items/{features,defects,tasks}/, post-fix table GAPS=0, exit 0. Verified in isolated temp repo. [parent-inline]
- 2026-06-03 [qa-e2e] E2 (AC-5): green — idempotent re-run on the now-healthy repo: GAPS=0, no AUQ path (skill Step 3 no-op branch), 4 table rows green, no writes (tree unchanged), exit 0. [parent-inline]
- 2026-06-03 [qa-e2e] E3 (AC-8): green — suite green: ./scripts/validate.sh exit 0 (0 errors/0 warnings, incl. CJ_repo-init SKILL-CATALOG section + Check 16 schema + Check 17 allowlist); ./scripts/test.sh exit 0 (Failures: 0); cj-repo-init.test.sh wired + green at test.sh line 929. [parent-inline]
- 2026-06-03 [qa-e2e-summary] green (0s subagent; 3 rows parent-inline; 0 deferred): all 3 E2E criteria green (E1 fresh-init+single-AUQ+scaffold, E2 idempotent no-op, E3 validate.sh+test.sh suite green).
- 2026-06-03 [qa-pass] S000075 (user-story): green smoke + green E2E. Phase 2 gates transitioned (Acceptance criteria verified met + Smoke tests pass).
