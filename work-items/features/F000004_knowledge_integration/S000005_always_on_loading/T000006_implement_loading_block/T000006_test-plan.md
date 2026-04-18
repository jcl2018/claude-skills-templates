---
type: test-plan
parent: T000006
title: "implement-loading-block — Test Plan"
date: 2026-04-16
author: chjiang
status: Draft
---

<!-- Scope: ONE fix (defect) or ONE task. Cases must be concrete and reproducible. -->

## Scope

Adds Knowledge Loading bash block to SKILL.md and the schema doc to WORKFLOW.md. Developed against T000005 fixtures. Automated tests land in T000007; this task's test plan is the dev-loop checklist.

## Regression Test Cases

| # | Test Case | Steps | Expected Result | Status |
|---|-----------|-------|-----------------|--------|
| 1 | Always-on category loaded | Point env at `fixtures/valid-knowledge-dir`; invoke skill; inspect emitted output | `## Always-On Knowledge` block lists `coding/style.md` and `coding/cpp/errors.md` (lex-sorted) | Pending |
| 2 | On-demand category NOT in always-on block | Same fixture | `runbooks/` paths not listed | Pending |
| 3 | Missing-yml category skipped silently | Same fixture | `notes/` paths not listed; no warning | Pending |
| 4 | Malformed-yml category skipped with warning | Same fixture | `broken/` paths not listed; one stderr warning naming `broken/.knowledge.yml` | Pending |
| 5 | Empty-triggers on-demand NOT loaded here | Same fixture | `empty-triggers/` paths not in always-on block | Pending |
| 6 | Determinism: same input → same output | Invoke twice, diff | Empty diff | Pending |
| 7 | `$_KNOWLEDGE_DIR=""` → no block emitted | Env unset | No `## Always-On Knowledge` section in output | Pending |
| 8 | Soft size warning above 50 KB | Temporarily swap `coding/style.md` for a >50 KB file | Warning mentions total size; paths still listed | Pending |
| 9 | WORKFLOW.md schema example parses as valid yml | Extract code block from docs; run through `yq` or bash parser | No parse error | Pending |
| 10 | `./scripts/validate.sh` still passes | Run validator | Exit 0 | Pending |

## Verification Steps

- [ ] Manual diff of SKILL.md — block lives right after Path Resolution / Knowledge Resolution, before Template Registry
- [ ] Claude-facing instruction is explicit enough that the E2E canary test (T000007 E1) can actually trigger Reads
- [ ] WORKFLOW.md schema example is copy-pasteable (no stray placeholders)
- [ ] Bash parser rejects obviously invalid yml (T000005 `broken/.knowledge.yml`) without crashing
- [ ] Implementation keeps the resolution block untouched (T000003's change is not reverted or reshaped)

## Environments Tested

| Environment | Build | Result |
|------------|-------|--------|
| macOS (dev) | local | Pending |
| Linux CI | branch build | Pending |
