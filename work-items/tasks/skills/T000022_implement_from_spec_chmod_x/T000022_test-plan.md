---
type: test-plan
parent: T000022
title: "/CJ_implement-from-spec chmod +x — Test Plan"
date: 2026-05-14
author: chjiang
status: Draft
---

<!-- Concrete, reproducible cases scoped to the chmod +x fix in
     skills/CJ_implement-from-spec/implement.md Step 9. -->

## Scope

The fix adds a post-write `chmod +x` step to `skills/CJ_implement-from-spec/implement.md` Step 9 for any newly-written file matching:
- `*.sh` (shell scripts)
- `*.bash` (bash scripts)
- No-extension files whose first line starts with `#!` (shebang scripts)

Step 11 boundary block may also be tightened to re-verify the executable bit (advisory in v1).

Modified file: `skills/CJ_implement-from-spec/implement.md`.

## Regression Test Cases

| # | Test Case | Steps | Expected Result | Status |
|---|-----------|-------|-----------------|--------|
| 1 | Step 9 source documents post-write chmod +x for `*.sh` files | grep `chmod +x` in implement.md Step 9 region (lines ~395-430) | Match present; bash snippet or prose instruction names `.sh`/`.bash`/shebang heuristic | Pending |
| 2 | Step 9 documents `*.bash` extension coverage | grep `\.bash` in implement.md Step 9 region | Match present; documented as part of the chmod heuristic | Pending |
| 3 | Step 9 documents shebang (no-extension) coverage | grep `shebang\|#!` in implement.md Step 9 region | Match present in the chmod heuristic prose or example | Pending |
| 4 | Implementer rationale documented in journal/prose | grep `chmod +x\|executable bit` for inline comment naming D000017 / TODOS:97 as the source | Match present; rationale traceable to the original bug | Pending |
| 5 | No regression: other implement.md sections (Step 5, 7, 8, 10, 11) unchanged in structure | diff vs v3.4.1 main: only Step 9 region changed (and optionally Step 11 advisory) | Diff scoped; no unrelated edits | Pending |

## Verification Steps

- [ ] `./scripts/validate.sh` passes (skill catalog + structural checks)
- [ ] `./scripts/test.sh` passes (full test suite)
- [ ] All 5 grep smoke rows above pass
- [ ] Manual inspection: read implement.md Step 9 region — the chmod +x instruction is unambiguous (an implementer reading it knows what to do)

## Environments Tested

| Environment | Build | Result |
|------------|-------|--------|
| macOS 25.3 (Darwin) | main @ v3.4.1 + this PR | Pending |
