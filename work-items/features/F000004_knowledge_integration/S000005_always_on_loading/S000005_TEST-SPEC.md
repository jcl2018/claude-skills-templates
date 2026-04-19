---
type: test-spec
parent: S000005
feature: F000004
title: "always-on-loading — Test Specification"
version: 1
status: Draft
date: 2026-04-16
author: chjiang
prd: PRD.md
architecture: ARCHITECTURE.md
reviewers: []
---

## Test Matrix

| # | Tag | Test Case | AC | Precondition | Steps | Expected Result | Priority | Type |
|---|-----|-----------|-----|-------------|-------|-----------------|----------|------|
| 1 | core | Single always-on category loads | AC-1,2 | Fixture with `coding/` + valid yml + 2 md files (one nested) | Invoke validate | `## Always-On Knowledge` section lists both absolute paths, lex-sorted | P0 | Integration |
| 2 | core | On-demand category NOT loaded | AC-4 | Fixture category with `surface: on-demand` | Invoke validate | No paths from that category in Always-On Knowledge section | P0 | Integration |
| 3 | core | Missing yml = not loaded, no warning | AC-4 | Fixture category with no `.knowledge.yml` | Invoke validate | Zero paths from category; zero warnings | P0 | Integration |
| 4 | resilience | Malformed yml warns + continues | AC-3,5 | Two categories: one valid always-on, one yml with invalid syntax | Invoke validate | Valid category paths listed; single warning names the malformed yml; exit 0 | P0 | Integration |
| 5 | core | Load order is deterministic | AC | Fixture with 3 files unsorted on disk | Invoke validate twice | Path list identical across runs, lex-sorted | P0 | Integration |
| 6 | core | Empty `$_KNOWLEDGE_DIR` → no loading | AC-6 | `AI_KNOWLEDGE_DIR` unset | Invoke validate | No Always-On Knowledge section emitted; S000004 warning still present | P0 | E2E |
| 7 | core | Claude actually reads the listed paths | AC-1 | Fixture file contains unique canary string `CANARY_ZXQJ_7391` | User asks Claude a question; assert Claude can quote the canary | Claude produces the canary in its reply | P0 | E2E |
| 8 | resilience | Zero regression on existing fixtures | AC-7 | `fixtures/valid-feature-dir/` with env unset AND env set to empty dir | Diff validate output across the two runs | Byte-identical | P0 | Integration |
| 9 | observability | Loaded path list visible in diagnostic | AC (P1) | Several always-on categories | Run a diagnostic command | All loaded paths visible | P1 | Integration |
| 10 | resilience | Soft warning above size threshold | AC (P1) | Always-on fixture with >50KB total | Invoke validate | One warning noting total size; content still loaded | P1 | Integration |

## Test Tiers

### Tier 1: Smoke Tests (automated, no live execution)

| # | Tag | Check | What It Validates | Script/Command |
|---|-----|-------|-------------------|---------------|
| S1 | core | SKILL.md has a Knowledge Loading section | Implementation block exists | `grep -q "^## Knowledge Loading" skills/company-workflow/SKILL.md` |
| S2 | core | SKILL.md has `## Always-On Knowledge` emit | Output contract is stable | `grep -q "## Always-On Knowledge" skills/company-workflow/SKILL.md` |
| S3 | core | SKILL.md instructs Claude to Read listed paths | Contract between skill and Claude | `grep -qi "read.*always-on knowledge" skills/company-workflow/SKILL.md` |
| S4 | core | Fixture `valid-knowledge-dir/` exists w/ mixed categories | Test infra present | `test -d skills/company-workflow/fixtures/valid-knowledge-dir/coding` |
| S5 | resilience | Fixture has a malformed yml variant | Error-path testable | `test -f skills/company-workflow/fixtures/valid-knowledge-dir/malformed/.knowledge.yml` |
| S6 | core | WORKFLOW.md documents `.knowledge.yml` schema | Docs current | `grep -qE "surface:.*always.*on-demand\|always.*on-demand" skills/company-workflow/WORKFLOW.md` |
| S7 | core | Repo validate passes | No catalog/manifest drift | `./scripts/validate.sh` |

### Tier 2: E2E Tests (real end-to-end execution)

| # | Tag | Scenario | Steps (as a real user would) | Expected Outcome | Rubric |
|---|-----|----------|----------------------------|-----------------|--------|
| E1 | core | Happy path: always-on content reaches Claude | Set AI_KNOWLEDGE_DIR to a dir with `coding/.knowledge.yml { surface: always }` and a md file containing `CANARY_ALPHA_9283`. Ask Claude: "what canary strings have you seen?" | Claude quotes `CANARY_ALPHA_9283` | Pass iff: Claude's reply contains the canary verbatim |
| E2 | core | Mixed categories: only always-on is loaded | Fixture has `alwayson/` (surface: always, contains `A_CANARY`) and `demand/` (surface: on-demand, contains `D_CANARY`). User asks about canaries without mentioning on-demand triggers | Claude cites `A_CANARY` but not `D_CANARY` | Pass iff: only the always-on canary appears |
| E3 | resilience | Malformed yml in one category doesn't break others | Fixture has one valid always-on (`GOOD_CANARY`) and one with invalid yml | Claude sees GOOD_CANARY; stderr has one warning | Pass iff: canary visible, warning text matches documented format |
| E4 | resilience | Empty `AI_KNOWLEDGE_DIR` → no loading | `unset AI_KNOWLEDGE_DIR`; ask Claude about canaries | Claude reports it hasn't seen any | Pass iff: zero canary content in reply |

## Coverage Gaps

| Gap | Why Not Tested | Risk Accepted |
|-----|---------------|---------------|
| Hot reload when files change mid-session | Out of scope per PRD Assumptions | Engineer can restart session |
| Circular symlinks inside a category | Very unusual; `find` handles in default invocation | Would appear as duplicate paths; user would notice |
| Binary / non-markdown files in a category | Only `*.md` is enumerated; other files silently ignored | Documented behavior |
| Categories nested 3+ deep | `find` is recursive; no depth limit specified | If users hit performance issues, add a max-depth option |
| Line ending variants (CRLF) in `.knowledge.yml` | `grep` tolerant; minor parse risk | If users hit it on Windows-origin files, add a normalization step |
| Concurrent skill invocations reading the same knowledge | Read-only; no shared state | None |
