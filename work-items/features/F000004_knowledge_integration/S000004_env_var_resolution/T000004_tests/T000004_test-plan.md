---
type: test-plan
parent: T000004
title: "tests — Test Plan"
date: 2026-04-16
author: chjiang
status: Draft
---

<!-- Scope: ONE fix (defect) or ONE task. Cases must be concrete and reproducible.
     For broader coverage of a user story, use TEST-SPEC.md instead.
     For defects, the test cases are regression cases for the specific bug. -->

## Scope

Adds automated tests for S000004 (env-var resolution + missing-folder warning). Covers Tier 1 structural assertions (grep-based), Tier 2 bash-block-extraction scenarios (awk out the Knowledge Resolution block from SKILL.md and exec in isolation), and a regression diff against existing fixtures. No production code changes — this task only adds test code and wiring.

**Important testability note (surfaced by /plan-eng-review outside-voice, 2026-04-18):** `/company-workflow validate` is an LLM-driven SKILL.md, not an executable. Bash CI cannot invoke the whole skill end-to-end (see `work-items/defects/D000004_company_workflow_contract_template_drift/D000004_RCA.md:53`). Tier 2 cases below test the Knowledge Resolution bash block by EXTRACTING it from SKILL.md (`awk '/^## Knowledge Resolution/,/^## Template Registry/' ... | awk '/^\`\`\`bash/,/^\`\`\`$/'`) and executing it against mocked env states. This validates the block's own behavior, which is the implementation. End-to-end skill invocation remains a manual-verification-only path.

## Regression Test Cases

| # | Test Case | Steps | Expected Result | Status |
|---|-----------|-------|-----------------|--------|
| 1 | Tier 1: SKILL.md has Knowledge Resolution section | Run `scripts/test.sh`; check grep result | Assertion passes | Pending |
| 2 | Tier 1: SKILL.md references `AI_KNOWLEDGE_DIR` and exposes `_KNOWLEDGE_DIR` | grep both symbols | Both present | Pending |
| 3 | Tier 1: WORKFLOW.md documents `AI_KNOWLEDGE_DIR` | grep workflow doc | Non-empty | Pending |
| 4 | Tier 1: repo `./scripts/validate.sh` passes | Run validate | Exit 0 | Pending |
| 5 | Tier 2 E1 (extract-and-exec): env unset → warning | Extract Knowledge Resolution block from SKILL.md to `/tmp/kr.sh`; `unset AI_KNOWLEDGE_DIR; bash /tmp/kr.sh` | Exactly one stderr warning; exit 0; stdout empty | Pending |
| 6 | Tier 2 E2 (extract-and-exec): env set to valid dir → silent | `AI_KNOWLEDGE_DIR=$(mktemp -d) bash /tmp/kr.sh` | Zero warnings on stderr; stdout empty; exit 0; `$_KNOWLEDGE_DIR` equals the path | Pending |
| 7 | Tier 2 E3 (extract-and-exec): env set to non-existent path | `AI_KNOWLEDGE_DIR=/does/not/exist bash /tmp/kr.sh` | Warning names path + "not found"; exit 0 | Pending |
| 8 | Tier 2 E4 (extract-and-exec): env set to file | `touch /tmp/kx; AI_KNOWLEDGE_DIR=/tmp/kx bash /tmp/kr.sh` | Warning mentions "not a directory"; exit 0 | Pending |
| 9 | Regression diff: baseline validate output unchanged by SKILL.md edits | Before this branch: `git stash`, run validate manually on fixture, capture stdout. After: restore, run manually, diff. (Manual verification only — see note at top.) | Empty diff on stdout | Pending (manual) |
| 10 | Tier 2 E1b (extract-and-exec): empty-string env → same "not set" warning as unset | `AI_KNOWLEDGE_DIR="" bash /tmp/kr.sh` | Warning identical to E1; exit 0. Behavior parity across unset and empty paths. | Pending |
| 11 | Tier 1 S6: SKILL.md resolution block does not emit to stdout | Extract the block; run with env unset; assert `bash /tmp/kr.sh` produces zero stdout (all output goes to stderr or `$_KNOWLEDGE_DIR` capture) | Empty stdout | Pending |
| 12 | Tier 2 E5 (extract-and-exec): set -e safety — block runs cleanly with `set -e` | `bash -c "set -e; source /tmp/kr.sh"` with env unset, then env set to bad path, then env set to valid dir | No `set -e` propagation from internal `[ -d ]` or `[ -e ]` failures. Exit 0 in all three sub-cases. Pins the if/elif structural invariant from ARCHITECTURE. | Pending |
| 13 | Tier 2 E6 (hostile input): env contains newline / control chars → warning stays single-line | `AI_KNOWLEDGE_DIR=$'/tmp/evil\npath' bash /tmp/kr.sh` | Exactly one warning line on stderr (control chars stripped in display). Truncation applies at 200 chars. Exit 0. | Pending |

**Cases 10–12 added during /plan-eng-review on 2026-04-18.** Empty-string parity closes the branch-1 sub-case not exercised by E1. Stdout-empty assertion (S6) prevents future edits from silently leaking output. set -e test pins the structural invariant that guards exit-code stability.

**Case 13 added 2026-04-18 (Codex outside-voice finding F3):** Pins the log-injection defense after SKILL.md sanitization patch. Hostile AI_KNOWLEDGE_DIR inputs (embedded newlines, terminal escape sequences) must not break the single-line warning contract.

**Cases 5–8, 10–13 rewritten 2026-04-18 (Codex outside-voice finding F1):** Clarified from "invoke skill validate on fixture" (which is not possible from bash CI) to "extract-and-exec the Knowledge Resolution bash block." The block IS the implementation for S000004; testing it in isolation is meaningful coverage. End-to-end `/company-workflow validate` invocation is manual-only (case 9).

**Cases 10–12 added during /plan-eng-review on 2026-04-18.** Empty-string parity closes the branch-1 sub-case not exercised by E1. Stdout-empty assertion (S6) prevents future edits from silently leaking output. set -e test pins the structural invariant that guards exit-code stability.

## Verification Steps

- [ ] `./scripts/test.sh` passes locally
- [ ] All Tier 2 scenarios reproduced manually in a terminal (not just script run)
- [ ] New assertions added run in under 5 seconds (fast enough for pre-commit hook)
- [ ] Warning text in assertions references the SAME constant used in SKILL.md (single source of truth)
- [ ] Cases 10–12 pass alongside 1–9 (no regression from the additions)

## Environments Tested

| Environment | Build | Result |
|------------|-------|--------|
| macOS (dev) | local | Pending |
| Linux CI | branch build | Pending |
