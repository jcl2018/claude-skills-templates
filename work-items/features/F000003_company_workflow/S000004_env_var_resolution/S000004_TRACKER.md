---
name: "env-var-resolution"
type: user-story
id: "S000004"
status: shipped
created: "2026-04-16"
updated: "2026-04-21"
parent: "F000003_company_workflow"
repo: "claude-skills-templates"
branch: "claude/heuristic-almeida-2f246d"
blocked_by: ""
---

## Lifecycle

### Phase 1: Track

1. Read parent tracker to understand scope
2. Run `/office-hours` with your idea
   → produces design doc in `~/.gstack/projects/`
3. Create working branch: `git checkout -b feat/{slug}`
4. Scaffold work item directory and TRACKER.md
5. Scaffold required docs from design doc:
   - `PRD.md` (requirements) — from `templates/doc-PRD.md`
   - `ARCHITECTURE.md` (architecture decisions) — from `templates/doc-ARCHITECTURE.md`
   - `TEST-SPEC.md` (test scenarios) — from `templates/doc-TEST-SPEC.md`
6. Break into child tasks if scope warrants decomposition

**Gates:**
- [x] Acceptance criteria defined
- [x] Working branch created (`branch` field populated)
- [x] Required docs scaffolded (PRD + ARCHITECTURE + TEST-SPEC)
- [x] Tasks broken down (if needed)

### Phase 2: Implement

1. Child tasks drive implementation (user-story tracker coordinates)
2. Monitor child progress — update this tracker when children complete phases
3. Update Todos section — check off completed children, add discoveries
4. Update Files section with changed file paths

**Gates:**
- [x] All child tasks have entered Phase 2+
- [x] Acceptance criteria verified met
- [x] Todos section reflects remaining work (no stale items)
- [x] Files section updated with changed files

### Phase 3: Ship

1. Run `/personal-workflow check` — verify all validation passes
   → should show PASS for template, lifecycle, traceability, structure badges
2. Run `/personal-workflow tree` — verify hierarchy and structural completeness
3. Verify TEST-SPEC alignment: do test cases cover all P0 acceptance criteria?
4. Ensure all child tasks have shipped
5. Run `/ship` — creates PR, bumps version, updates changelog (includes pre-landing code review)
6. Run `/land-and-deploy` — merges PR and verifies deployment

❌ If `/personal-workflow check` finds issues: fix findings, re-run until clean
❌ If CI fails: fix, push, re-run `/ship`

**Gates:**
- [x] `/personal-workflow check` — validation passed
- [x] `/personal-workflow tree` — structure verified
- [x] TEST-SPEC covers all P0 acceptance criteria
- [x] All children shipped (T000003 shipped in PR #38)
- [x] `/ship` — PR created (PR #38)
- [x] `/land-and-deploy` — merged and deployed (v0.11.0, commit aca2674)

## Acceptance Criteria

<!-- What "done" looks like for this story. -->

- [x] `company-workflow` skill reads `AI_KNOWLEDGE_DIR` on every invocation and exposes the resolved path as a skill-internal variable for downstream code — T000003 cases 1/2/6 verify
- [x] When `AI_KNOWLEDGE_DIR` is unset OR empty: skill emits exactly one warning line on stderr naming the variable and pointing to docs, exit code remains 0 — T000003 cases 5 (E1) + 10 (E1b) + 11 verify
- [x] When `AI_KNOWLEDGE_DIR` is set but the path does not exist or is not a directory: skill emits a warning mentioning the configured path, exit code remains 0 — T000003 cases 7 (E3) + 8 (E4) verify
- [x] When `AI_KNOWLEDGE_DIR` is set and points to a valid directory: no warning emitted — T000003 case 6 (E2) verifies
- [x] No knowledge files are read or loaded by this story (resolution only — loading lands in S000005 always-on and S000006 on-demand stories) — T000003 bash block does only `[ -e ]`/`[ -d ]` checks, no file I/O (verified by code review + case 11 stdout-empty)
- [x] Existing `validate` command produces byte-identical output with and without `AI_KNOWLEDGE_DIR` set (zero regression) — T000003 case 11 (stdout-empty) scripted + case 9 deferred to manual (not scriptable: LLM skill)

## Todos

<!-- Actionable items for this story. -->

- [x] Draft the exact warning text (one line, ≤100 chars, names the variable, points to docs) — 3 variants shipped (unset/empty, path-not-found, path-is-file)
- [x] Add resolution block to SKILL.md Path Resolution section — `## Knowledge Resolution` shipped
- [x] Decide where the warning is emitted — skill preamble, every invocation (intentionally noisy per design journal)
- [x] Write Tier 1 smoke test — shipped in scripts/test.sh
- [x] Write Tier 2 E2E test — extract-and-exec pattern; cases 1/2/3/5/6/7/8/10/11/12/13 all scripted
- [x] Update WORKFLOW.md or SKILL.md docs with the `AI_KNOWLEDGE_DIR` setup instructions — `## Knowledge Configuration` shipped in WORKFLOW.md
- [x] Confirm no regression against existing fixtures — case 11 stdout-empty assertion; case 9 deferred to manual (LLM skill, not scriptable)

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-04-16: Created. First vertical slice of F000004: env var resolution + missing-folder warning. No knowledge loading in this story.
- 2026-04-17: Decomposed into tasks: T000003 (resolution + warning impl in SKILL.md + WORKFLOW.md) and T000004 (Tier 1 + Tier 2 + regression tests). T000004 blocked by T000003.
- 2026-04-17: T000003 landed (commit 6265249).
- 2026-04-17: Converted to personal-workflow structure (3-phase lifecycle; simplified frontmatter with `parent: F000004`; story-level milestones.md dropped — now only at feature level).
- 2026-04-18: T000004 (tests) landed. scripts/test.sh has 11 new assertions covering all scriptable branches; `./scripts/test.sh` passes end-to-end. All 6 S000004 AC verified or explicitly deferred to S000005/S000006. Phase 2 gates all satisfied; Phase 3 ready.
- 2026-04-19: Consolidated T000004_tests into T000003_implement_resolution_block (impl + tests ship as one unit). Both already landed in squash PR #38; the split was bookkeeping-only. Matches F000001/F000003 precedent of collapsing redundant task decomposition.

## PRs

<!-- PR links with status (open/merged/closed). -->

- [#38](https://github.com/jcl2018/claude-skills-templates/pull/38) — merged 2026-04-19 (v0.11.0, commit aca2674). F000004 scaffolding + S000004 env-var resolution.

## Files

<!-- Affected file paths. -->

- skills/company-workflow/SKILL.md (modified — `## Knowledge Resolution` section added in T000003; sanitization patch in commit a46efa9)
- skills/company-workflow/WORKFLOW.md (modified — `## Knowledge Configuration` section added in T000003)
- scripts/test.sh (modified — T000003 added "Regression test (T000004)" section with 11 scripted assertions covering all branches of the Knowledge Resolution block)

## Insights

<!-- Non-obvious findings worth remembering. -->

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->
