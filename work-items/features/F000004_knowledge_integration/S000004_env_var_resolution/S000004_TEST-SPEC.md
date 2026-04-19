---
type: test-spec
parent: S000004
feature: F000004
title: "env-var-resolution — Test Specification"
version: 1
status: Draft
date: 2026-04-16
author: chjiang
prd: PRD.md
architecture: ARCHITECTURE.md
reviewers: []
---

<!-- Scope: ENTIRE user story. Test Matrix must cover every PRD acceptance criterion
     across happy/edge/error paths. For a single fix or task, use test-plan.md instead. -->

## Test Matrix

<!-- Each row maps to a PRD acceptance criterion via the AC column.
     Every P0 criterion needs at least one test case.
     "Tag" = domain keyword matching the PRD story this test traces to
       (core, resilience, observability, usability, security, integration). -->

| # | Tag | Test Case | AC | Precondition | Steps | Expected Result | Priority | Type |
|---|-----|-----------|-----|-------------|-------|-----------------|----------|------|
| 1 | core | Resolution succeeds with valid dir | AC-1 | Temp dir exists; `AI_KNOWLEDGE_DIR` exported to it | Invoke any `validate` command | `$_KNOWLEDGE_DIR` equals the exported path; no warning on stderr | P0 | Integration |
| 2 | usability | Warning emitted when var unset | AC-2 | `AI_KNOWLEDGE_DIR` unset | Invoke `validate <any file>` | Exactly one warning line on stderr naming `AI_KNOWLEDGE_DIR`; exit code 0 | P0 | E2E |
| 3 | usability | Warning emitted when var empty string | AC-2 | `AI_KNOWLEDGE_DIR=""` exported | Invoke `validate` | Same warning as #2; exit code 0 | P0 | E2E |
| 4 | resilience | Warning when path does not exist | AC-3 | `AI_KNOWLEDGE_DIR=/nonexistent/path/xyz` | Invoke `validate` | Warning naming the path and "not found"; exit code 0 | P0 | E2E |
| 5 | resilience | Warning when path is a file not a dir | AC-3 | `AI_KNOWLEDGE_DIR` points at an existing file | Invoke `validate` | Warning naming the path and "not a directory"; exit code 0 | P0 | E2E |
| 6 | core | Happy path: no warning | AC-4 | Valid dir exported | Invoke `validate` | Zero warnings on stderr; command output identical to baseline | P0 | Integration |
| 7 | core | Zero regression — output byte-identical | AC-6 | Existing `fixtures/valid-feature-dir/` | Run `validate` on fixture twice: once with env unset, once with env=valid dir; diff stdout | Diff is empty | P0 | Integration |
| 8 | observability | Diagnostic shows resolved path | AC (P1) | Env set to valid dir | Invoke diagnostic (TBD — may defer to a follow-up) | Resolved path appears in output | P1 | Integration |

## Test Tiers

<!-- Every feature has two test tiers. Both are needed:
     - Tier 1 (smoke): Fast, deterministic, catches structural regressions without invoking AI
     - Tier 2 (E2E): Real execution, catches behavioral regressions in prompts and output
     Tier 1 alone can't test AI behavior. Tier 2 alone is slow and non-deterministic.
     Together they form a fast-then-thorough pipeline. -->

### Tier 1: Smoke Tests (automated, no live execution)

<!-- Static/structural checks: file existence, schema validation, section headers,
     frontmatter fields. Can run in CI or via a shell script. Fast, deterministic. -->

| # | Tag | Check | What It Validates | Script/Command |
|---|-----|-------|-------------------|---------------|
| S1 | core | SKILL.md contains a Knowledge Resolution section | The implementation section exists at the documented location | `grep -q "^## Knowledge Resolution" skills/company-workflow/SKILL.md` |
| S2 | core | Resolution block references `AI_KNOWLEDGE_DIR` | Variable name is exactly as specified | `grep -q "AI_KNOWLEDGE_DIR" skills/company-workflow/SKILL.md` |
| S3 | core | Resolution block exposes `_KNOWLEDGE_DIR` | Downstream stories can depend on the name | `grep -q "_KNOWLEDGE_DIR=" skills/company-workflow/SKILL.md` |
| S4 | usability | Warning text named correctly | Regression guard on the exact warning string | `grep -q "AI_KNOWLEDGE_DIR.*unset\|AI_KNOWLEDGE_DIR.*not set" skills/company-workflow/SKILL.md` |
| S5 | core | WORKFLOW.md documents the env var | Docs stay in sync with implementation | `grep -q "AI_KNOWLEDGE_DIR" skills/company-workflow/WORKFLOW.md` |
| S6 | core | Catalog + manifest unchanged structurally | No accidental schema drift | `./scripts/validate.sh` passes |

### Tier 2: E2E Tests (real end-to-end execution)

<!-- Full end-to-end execution: invoke the actual feature, observe output, verify behavior
     matches AC. Requires AI execution. Can be manual (rubric-scored by human) or automated
     via an E2E test skill that creates fixtures and invokes the skill under test. -->

| # | Tag | Scenario | Steps (as a real user would) | Expected Outcome | Rubric |
|---|-----|----------|----------------------------|-----------------|--------|
| E1 | usability | First-run engineer has no `AI_KNOWLEDGE_DIR` | In a fresh shell, `unset AI_KNOWLEDGE_DIR`; invoke `/company-workflow validate <fixture>` | Output includes the validate result AND a single stderr warning line naming the variable | Pass iff: exactly one warning, exit 0, validate output unchanged vs. baseline |
| E2 | core | Engineer sets a valid path | `export AI_KNOWLEDGE_DIR=$(mktemp -d)`; invoke validate | Validate runs; no warning on stderr | Pass iff: zero warnings, exit 0 |
| E3 | resilience | Engineer sets a bad path | `export AI_KNOWLEDGE_DIR=/definitely/not/a/real/path/abc123`; invoke validate | Warning names the exact path and says not-found; exit 0 | Pass iff: warning contains the path; exit 0 |
| E4 | resilience | Engineer sets a path to a file | `touch /tmp/k && export AI_KNOWLEDGE_DIR=/tmp/k`; invoke validate | Warning names the path and indicates not-a-directory | Pass iff: warning mentions directory issue; exit 0 |

<!-- If an E2E test skill exists for this feature, reference it here:
     E2E test skill: the test skill for the feature
     Run with: `/test-{skill-name}-e2e` -->

## Coverage Gaps

<!-- What is explicitly NOT tested and why. Honesty beats false confidence. -->

| Gap | Why Not Tested | Risk Accepted |
|-----|---------------|---------------|
| Symlink to a valid directory | Treated identically to a real dir by `[ -d ... ]`; no special handling needed | If symlinks ever need special treatment, add a case later |
| Unicode / spaces in path | Bash properly quotes `"$AI_KNOWLEDGE_DIR"` so this works; not worth separate test | Manual spot-check during review |
| Concurrent invocations reading different env values | Skill is stateless per invocation; each reads its own env | None — no shared state to corrupt |
| Windows (non-POSIX) shell behavior | Company-workflow target platform is Linux/macOS; skills-deploy has a separate Windows jq CRLF defect | Not a regression from today |
| Warning suppression | P2 feature, explicitly out of scope for this story | If users demand it, spin a follow-up story |
