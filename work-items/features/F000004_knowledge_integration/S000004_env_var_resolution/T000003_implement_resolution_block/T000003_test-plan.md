---
type: test-plan
parent: T000003
title: "implement-resolution-block — Test Plan"
date: 2026-04-16
author: chjiang
status: Draft
---

<!-- Scope: ONE fix (defect) or ONE task. Cases must be concrete and reproducible. -->

## Scope

Implementation + scripted tests for S000004 (env-var resolution + missing-folder warning). Covers three artifacts: SKILL.md `## Knowledge Resolution` section, WORKFLOW.md `## Knowledge Configuration` section, and `scripts/test.sh` assertions that exercise the resolution bash block in isolation.

**Testability note (Codex outside-voice, 2026-04-18):** `/company-workflow validate` is an LLM-driven SKILL.md, not an executable. Bash CI cannot invoke the whole skill end-to-end (see `work-items/defects/D000004_company_workflow_contract_template_drift/D000004_RCA.md:53`). Tier 2 cases below test the Knowledge Resolution bash block by EXTRACTING it from SKILL.md (`awk '/^## Knowledge Resolution/,/^## Template Registry/' ... | awk '/^\`\`\`bash/,/^\`\`\`$/'`) and executing it against mocked env states. This validates the block's own behavior, which IS the implementation for S000004. End-to-end skill invocation remains manual-verification-only (case 9).

## Regression Test Cases

| # | Test Case | Steps | Expected Result | Status |
|---|-----------|-------|-----------------|--------|
| 1 | Tier 1: SKILL.md has Knowledge Resolution section | Run `scripts/test.sh`; grep check | Assertion passes | Pass |
| 2 | Tier 1: SKILL.md references `AI_KNOWLEDGE_DIR` and exposes `_KNOWLEDGE_DIR` | grep both symbols | Both present | Pass |
| 3 | Tier 1: WORKFLOW.md documents `AI_KNOWLEDGE_DIR` | grep workflow doc | Non-empty | Pass |
| 4 | Tier 1: repo `./scripts/validate.sh` passes | Run validate | Exit 0 | Pass |
| 5 | Tier 2 E1 (extract-and-exec): env unset → warning | Extract Knowledge Resolution block from SKILL.md to `/tmp/kr.sh`; `unset AI_KNOWLEDGE_DIR; bash /tmp/kr.sh` | Exactly one stderr warning; exit 0; stdout empty | Pass |
| 6 | Tier 2 E2 (extract-and-exec): env set to valid dir → silent | `AI_KNOWLEDGE_DIR=$(mktemp -d) bash /tmp/kr.sh` | Zero warnings on stderr; stdout empty; exit 0; `$_KNOWLEDGE_DIR` equals the path | Pass |
| 7 | Tier 2 E3 (extract-and-exec): env set to non-existent path | `AI_KNOWLEDGE_DIR=/does/not/exist bash /tmp/kr.sh` | Warning names path + "not found"; exit 0 | Pass |
| 8 | Tier 2 E4 (extract-and-exec): env set to file | `touch /tmp/kx; AI_KNOWLEDGE_DIR=/tmp/kx bash /tmp/kr.sh` | Warning mentions "not a directory"; exit 0 | Pass |
| 9 | Regression diff: baseline validate output unchanged by SKILL.md edits | Before this branch: `git stash`, run validate manually on fixture, capture stdout. After: restore, run manually, diff. (Manual verification only — see note at top.) | Empty diff on stdout | Pending (manual) |
| 10 | Tier 2 E1b (extract-and-exec): empty-string env → same "not set" warning as unset | `AI_KNOWLEDGE_DIR="" bash /tmp/kr.sh` | Warning identical to E1; exit 0. Behavior parity across unset and empty paths. | Pass |
| 11 | Tier 1 S6: SKILL.md resolution block does not emit to stdout | Extract the block; run with env unset; assert `bash /tmp/kr.sh` produces zero stdout (all output goes to stderr or `$_KNOWLEDGE_DIR` capture) | Empty stdout | Pass |
| 12 | Tier 2 E5 (extract-and-exec): set -e safety — block runs cleanly with `set -e` | `bash -c "set -e; source /tmp/kr.sh"` with env unset, then env set to bad path, then env set to valid dir | No `set -e` propagation from internal `[ -d ]` or `[ -e ]` failures. Exit 0 in all three sub-cases. Pins the if/elif structural invariant from ARCHITECTURE. | Pass |
| 13 | Tier 2 E6 (hostile input): env contains newline / control chars → warning stays single-line | `AI_KNOWLEDGE_DIR=$'/tmp/evil\npath' bash /tmp/kr.sh` | Exactly one warning line on stderr (control chars stripped in display). Truncation applies at 200 chars. Exit 0. | Pass |

**Cases 10–12 added during /plan-eng-review on 2026-04-18.** Empty-string parity closes the branch-1 sub-case not exercised by E1. Stdout-empty assertion (S6) prevents future edits from silently leaking output. set -e test pins the structural invariant that guards exit-code stability.

**Case 13 added 2026-04-18 (Codex outside-voice finding F3):** Pins the log-injection defense after SKILL.md sanitization patch. Hostile AI_KNOWLEDGE_DIR inputs (embedded newlines, terminal escape sequences) must not break the single-line warning contract.

**Cases 5–8, 10–13 rewritten 2026-04-18 (Codex outside-voice finding F1):** Clarified from "invoke skill validate on fixture" (not possible from bash CI) to "extract-and-exec the Knowledge Resolution bash block." The block IS the implementation for S000004; testing it in isolation is meaningful coverage. End-to-end `/company-workflow validate` invocation is manual-only (case 9).

## Verification Steps

- [x] `./scripts/test.sh` passes locally
- [ ] All Tier 2 scenarios reproduced manually in a terminal (not just script run)
- [x] New assertions added run in under 5 seconds (fast enough for pre-commit hook)
- [ ] Warning text in assertions references the SAME constant used in SKILL.md (single source of truth — deferred)
- [x] Cases 10–13 pass alongside 1–9 (no regression from the additions)

## Environments Tested

| Environment | Build | Result |
|------------|-------|--------|
| macOS (dev) | local | Pass |
| Linux CI | branch build | Pass |
