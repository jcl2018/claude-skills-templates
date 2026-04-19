---
type: test-plan
parent: T000009
title: "implement-matching-block — Test Plan"
date: 2026-04-16
author: chjiang
status: Draft
---

<!-- Scope: ONE fix (defect) or ONE task. Cases must be concrete and reproducible. -->

## Scope

Implements the On-Demand Matching section of SKILL.md and extends WORKFLOW.md docs. Developed against T000005 fixtures (possibly extended). Automated tests land in T000010; this task's test plan is the dev-loop gate.

## Regression Test Cases

| # | Test Case | Steps | Expected Result | Status |
|---|-----------|-------|-----------------|--------|
| 1 | On-demand candidates block emitted | Invoke skill against `valid-knowledge-dir`; inspect output | `## On-Demand Knowledge Candidates` lists `runbooks` + triggers + file paths | Pending |
| 2 | Always-on category NOT in candidates | Same | `coding/` paths absent from candidates block | Pending |
| 3 | Empty-triggers category NOT in candidates | Same | `empty-triggers/` NOT emitted as a candidate (zero triggers make it unreachable) | Pending |
| 4 | Malformed-yml category skipped with warning | Same | `broken/` not emitted; one warning line | Pending |
| 5 | `$_KNOWLEDGE_DIR=""` → no candidates block | env unset | No `## On-Demand Knowledge Candidates` section | Pending |
| 6 | Claude instruction block specifies the match rule | grep SKILL.md for key phrases: "case-insensitive", "whole-word", "phrase" | All present | Pending |
| 7 | Match log format documented | grep SKILL.md for `[knowledge] matched:` example | Match | Pending |
| 8 | WORKFLOW.md has on-demand worked example | grep + manual read | Example present + parseable yml | Pending |
| 9 | WORKFLOW.md has security callout | grep "prompt injection" or "trust boundary" | Present | Pending |
| 10 | `./scripts/validate.sh` passes | Run validator | Exit 0 | Pending |

## Verification Steps

- [ ] SKILL.md section order respected: Knowledge Resolution → Knowledge Loading → On-Demand Matching (in that order) → Knowledge Helpers (if helper is a sibling section)
- [ ] Candidates block is machine-readable (stable per-category key/value layout for test assertions)
- [ ] Manual E2E in a real Claude Code session: prompts containing triggers cause Claude to Read matched paths (verifiable by asking Claude to cite canary strings)
- [ ] Prior-turns scope decision documented in SKILL.md (Claude should only tokenize the latest user message)
- [ ] Security callout explicit about knowledge file content being trusted input (same as any Read)

## Environments Tested

| Environment | Build | Result |
|------------|-------|--------|
| macOS (dev) | local | Pending |
| Linux CI | branch build | Pending |
