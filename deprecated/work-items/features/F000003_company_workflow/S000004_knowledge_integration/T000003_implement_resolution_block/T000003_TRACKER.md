---
name: "implement-resolution-block"
type: task
id: "T000003"
status: shipped
created: "2026-04-16"
updated: "2026-04-21"
parent: "S000004"
repo: "claude-skills-templates"
branch: "claude/heuristic-almeida-2f246d"
blocked_by: ""
---

## Lifecycle

### Phase 1: Track

1. Read parent tracker to understand scope and acceptance criteria
2. Create working branch: `git checkout -b feat/{slug}`
   (use parent's branch if the task ships in the same PR; create a new branch if it warrants its own PR)
3. Scaffold required docs:
   - `test-plan.md` (test scenarios for this task) — from `templates/doc-test-plan.md`
4. Populate Files section with expected changed files
5. Write initial Todos from parent's acceptance criteria

**Gates:**
- [x] Parent scope read (parent tracker reviewed)
- [x] Working branch created (`branch` field populated)
- [x] Required docs scaffolded (test-plan)
- [x] Files section populated

### Phase 2: Implement

1. Work from `/office-hours` design doc + parent's acceptance criteria + your Todos
   → design doc at `~/.gstack/projects/{slug}/`
2. Commit changes incrementally with descriptive messages
3. Update Todos section — check off completed items, add discoveries
4. Update Files section with actual changed files

**Gates:**
- [x] Core changes committed (>=1 commit SHA in Log)
- [x] Todos section reflects remaining work (no stale items)
- [x] Files section updated with changed files

### Phase 3: Ship

1. Run `/personal-workflow check` — verify no regressions
2. Verify test-plan: all test scenarios passing
3. Run `/ship` — creates PR, bumps version, updates changelog (includes pre-landing code review)
4. Run `/land-and-deploy` — merges PR and verifies deployment

❌ If tests fail: fix, re-run
❌ If CI fails: fix, push, re-run `/ship`

**Gates:**
- [x] `/personal-workflow check` — validation passed
- [x] Test-plan verified (all scriptable scenarios passing; case 9 deferred to manual per test-plan scope note)
- [x] `/ship` — PR created (PR #38)
- [x] `/land-and-deploy` — merged and deployed (commit aca2674, v0.11.0)

## Todos

<!-- Actionable items for this task. Implementation + tests, shipped together. -->

- [x] Draft the exact warning text (3 variants: unset/empty, path-not-found, path-is-file)
- [x] Add `## Knowledge Resolution` section to SKILL.md right after `## Path Resolution`
- [x] Implement bash block: read env, validate `-d`, expose `$_KNOWLEDGE_DIR`, emit warning on failure paths
- [x] Handle three failure modes distinctly: unset/empty, path-not-found, path-is-file (see S000004 PRD AC-2/3)
- [x] Add `## Knowledge Configuration` section to WORKFLOW.md with `AI_KNOWLEDGE_DIR` setup example + layout + `.knowledge.yml` schema
- [x] Verify warning lands on stderr (`>&2`), exit code remains 0 (no `exit 1`)
- [x] Implement S000004 TEST-SPEC Tier 1 checks as shell assertions in `scripts/test.sh` (cases 1, 2, 3, 11; case 4 piggybacks on validate.sh assertion)
- [x] Implement S000004 TEST-SPEC Tier 2 scenarios via extract-and-exec (cases 5 E1, 6 E2, 7 E3, 8 E4, 10 E1b, 12 E5, 13 E6 hostile input)
- [x] Wire new tests into `./scripts/test.sh` so CI runs them
- [ ] Regression diff (TEST-SPEC case 9): DEFERRED to manual verification per test-plan scope note. `/company-workflow validate` is an LLM-driven SKILL.md, not scriptable from bash CI (see D000004 RCA).
- [ ] Capture warning text in a variable so impl and tests share one source — deferred; revisit if warning text changes often.
- [ ] Document how to run the E2E tests locally — deferred; tests run as part of `./scripts/test.sh` with no special setup.

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-04-16: Created. Implements resolution bash block in SKILL.md + docs in WORKFLOW.md + scripted tests for S000004 AC-1/2/3/4.
- 2026-04-17: Implemented impl side. Added `## Knowledge Resolution` section to SKILL.md (bash block + behavior contract + cross-link) and `## Knowledge Configuration` section to WORKFLOW.md (setup + layout + `.knowledge.yml` schema + current status). Three distinct warning lines per failure mode (unset/empty, not-found, not-a-directory). Committed as 6265249 (feat: T000003 AI_KNOWLEDGE_DIR resolution + WORKFLOW.md configuration docs).
- 2026-04-17: Converted to personal-workflow structure (3-phase lifecycle; simplified frontmatter; PR-DESCRIPTION.md dropped).
- 2026-04-18: /plan-eng-review expanded test coverage: added 3 cases (empty-string parity, stdout-empty assertion, set -e safety). Codex outside-voice caught 3 gaps: (a) rewrote Tier 2 E1–E5+E1b as extract-and-exec of the SKILL.md bash block (end-to-end skill invocation not scriptable per D000004 RCA); (b) added case 13 (hostile input) pinning the SKILL.md sanitization patch; (c) clarified scope note at top of test-plan. Applied SKILL.md sanitization commit a46efa9.
- 2026-04-18: Tests landed. Added "Regression test (T000004)" section to `scripts/test.sh` with 11 assertions covering all scriptable cases (1, 2, 3, 5, 6, 7, 8, 10, 11, 12, 13). Case 4 piggybacks on validate.sh; case 9 remains manual-only. Full `./scripts/test.sh` suite passes. S000004 Phase 2 complete.
- 2026-04-19: Absorbed former T000004_tests task into this task. Convention change per F000001/F000003 precedent (impl + tests ship as one unit; separate "tests" task was bookkeeping overhead). T000003 + T000004 originally shipped in the same squash PR #38; the split was never a real PR boundary.

## PRs

<!-- PR links with status (open/merged/closed). -->

- [#38](https://github.com/jcl2018/claude-skills-templates/pull/38) — merged 2026-04-19 (v0.11.0, commit aca2674). Knowledge-integration scaffolding + env-var resolution.

## Files

<!-- Affected file paths. -->

- skills/company-workflow/SKILL.md (modified — `## Knowledge Resolution` section; sanitization patch in a46efa9)
- skills/company-workflow/WORKFLOW.md (modified — `## Knowledge Configuration` section)
- scripts/test.sh (modified — "Regression test (T000004)" section, 11 scripted assertions covering all branches of the Knowledge Resolution block)

## Insights

<!-- Non-obvious findings worth remembering. -->

- `/company-workflow validate` is an LLM-driven SKILL.md, not an executable. Bash CI cannot run the skill end-to-end. The testable unit is the bash block extracted from SKILL.md via `awk '/^## Knowledge Resolution/,/^## Template Registry/'` then `awk '/^\`\`\`bash/,/^\`\`\`$/'`. This pattern should be reused for S000005/S000006 test coverage.
- Sanitization (control-char strip + 200-char truncation) on `$AI_KNOWLEDGE_DIR` display is load-bearing: preserves the "exactly one warning line" contract under hostile input. Case 13 (E6) pins it.

## Journal
