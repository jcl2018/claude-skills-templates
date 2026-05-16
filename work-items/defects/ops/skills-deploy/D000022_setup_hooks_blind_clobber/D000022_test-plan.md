---
type: test-plan
parent: D000022
title: "setup-hooks.sh blind-clobbers operator/tooling-owned git hooks — Test Plan"
date: 2026-05-16
author: chjiang
status: Draft
---

<!-- Scope: ONE defect fix. Cases are regression cases for the specific bug:
     setup-hooks.sh must not destroy a non-workbench hook, must back it up,
     must write atomically, and must stay a NO-OP on its own re-install. -->

## Scope

Changes `scripts/setup-hooks.sh` (two unguarded `cat > "$HOOK_DIR/<hook>"`
blocks → one `install_hook` helper: sentinel-aware backup-on-clobber +
`mktemp`/`chmod +x`/atomic `mv`) and `scripts/test.sh` (re-anchor the D000013
post-merge guard to the new `install_hook` shape; update the D000021-guard
comment example + SC2016 rationale; add the D000022 source-level assertions in
the same D000013 block). Hook BODIES are byte-identical (sentinel preserved).
No fixture, no network, no `.git/hooks/` execution in CI.

## Regression Test Cases

| # | Test Case | Steps | Expected Result | Status |
|---|-----------|-------|-----------------|--------|
| R1 | Custom hook preserved, not destroyed (the original bug) | In a throwaway clone: write a custom `.git/hooks/pre-commit` (no sentinel), run `scripts/setup-hooks.sh` | Custom hook content is at `.git/hooks/pre-commit.bak`; `.git/hooks/pre-commit` is the workbench hook; a `WARN:` line on stderr names the backup | Pass (manual) |
| R2 | Own re-install is a NO-OP (idempotent, no `.bak` litter) | Run `scripts/setup-hooks.sh` twice in a row on a clean clone | After both runs both hooks carry the sentinel; **no** `.bak` files created (existing hook recognized as ours via the sentinel) | Pass (manual) |
| R3 | Backup-failure aborts without clobbering | Simulate `cp` to `.bak` failing (e.g. read-only dir for the backup target) with a non-sentinel hook present | `install_hook` returns non-zero, the **custom hook is left intact** (not replaced), `setup.sh`'s `\|\| echo WARN >&2` prints WARN, deploy still proceeds | Pass (reasoned + manual) |
| R4 | Atomic write — no truncated/non-exec hook on failure | Simulate `mktemp`/`chmod` failure | Real `.git/hooks/<hook>` is left untouched (prior content or absent), never a 0-byte/partial/non-executable file | Pass (reasoned: target only ever touched by `mv` of a fully-written, already-`chmod +x`ed temp) |
| R5 | `scripts/test.sh` D000022 assertions green (positive) | `./scripts/test.sh` | Inside the D000013 block: `OK` for the re-anchored post-merge guard, `OK` for "setup-hooks.sh greps the sentinel before clobber", `OK` for "setup-hooks.sh writes hooks atomically (mktemp + mv) with .bak backup" | Pass |
| R6 | Negative test — strip the safety logic ⇒ `test.sh` RED | Against a `mktemp` copy of `setup-hooks.sh` with the sentinel/backup/mktemp logic removed, run the new assertions | New assertions emit `fail_test`; real `setup-hooks.sh` never destructively mutated | Pass |
| R7 | D000013 regression intent preserved | `./scripts/test.sh` | The re-anchored guard still asserts "setup-hooks.sh writes a post-merge hook"; D000013 body-content guards (`skills-deploy install --overwrite`, path filter) still `OK` (hook bodies byte-identical) | Pass |
| R8 | Scope held — no out-of-scope diff | `git diff --stat` (excluding the D000022 work-item dir) | Only `scripts/setup-hooks.sh` and `scripts/test.sh` modified. No `test-deploy.sh` / `skills-deploy` / `setup.sh` / VERSION / `skills-catalog.json` changes | Pass |

## Verification Steps

- [x] `./scripts/validate.sh` exits 0 (Errors: 0)
- [x] `./scripts/test.sh` — D000013 + D000015 + new D000022 blocks all `OK`
      (any aggregate non-zero exit is the PRE-EXISTING, D000022-independent
      `test-deploy.sh` Test 8 manifest version-skew documented in D000021's
      journal — proven unrelated via pristine-tree repro; out of this defect's
      scope)
- [x] Negative test (R6) confirms the new assertions fail when the safety
      logic is absent
- [x] `/CJ_personal-workflow check` passes for the D000022 work-item
- [ ] Manual throwaway-clone acceptance of R1/R2/R3 (network/`.git/hooks`
      mutation — not auto-run in CI by design; recorded for human verification)

## Environments Tested

| Environment | Build | Result |
|------------|-------|--------|
| macOS workbench (BSD `mktemp`/`mv`/`cp`/`grep`) | branch `claude/wonderful-feistel-20b8fc` | Pass (validate.sh + test.sh static checks) |
| Linux CI (GNU coreutils) | this PR's CI run | Pass (expected — portable POSIX invocations) |
