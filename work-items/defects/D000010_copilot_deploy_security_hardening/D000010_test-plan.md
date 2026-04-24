---
name: "Test plan: copilot-deploy.py path/symlink hardening"
type: test-plan
id: "D000010_test-plan"
parent: "D000010"
created: "2026-04-23"
updated: "2026-04-23"
---

## Scope

Regression tests for the fix of D000010 (path traversal + symlink escape in
`scripts/copilot-deploy.py`). All tests live in `scripts/test.sh` alongside
the existing copilot-deploy smoke test.

## Test Cases

### T1: Poisoned manifest with `..` in dest is rejected

- **Setup:** install the bundle; rewrite `install-manifest.json` so one file's
  `dest` is `../../../etc/hosts`.
- **Run:** `python3 scripts/copilot-deploy.py doctor <target>`.
- **Expect:** exit code != 0; stderr contains `"escapes target"`; no file
  read outside `<target>`.

### T2: Poisoned manifest with absolute dest is rejected

- **Setup:** install; rewrite manifest so `dest` is `/tmp/attacker-controlled`.
- **Run:** `python3 scripts/copilot-deploy.py remove <target>`.
- **Expect:** exit code != 0; stderr names the rejected path; `/tmp/attacker-
  controlled` is not unlinked even if it exists.

### T3: Symlinked source file is skipped

- **Setup:** create `work-copilot/instructions/evil -> /etc/passwd` as a
  symlink in a fixture bundle.
- **Run:** `python3 scripts/copilot-deploy.py install --bundle-dir <fixture> <target>`.
- **Expect:** `<target>/.github/evil` is not created; stderr warns about the
  skipped symlink.

### T4: Symlinked destination path is rejected

- **Setup:** in a test target, make `<target>/.github -> /tmp/outside` a
  symlink.
- **Run:** `python3 scripts/copilot-deploy.py install <target>`.
- **Expect:** exit non-zero before any write; stderr names the symlinked path.

### T5: Happy-path install/doctor/remove still passes

- Existing smoke test (added in PR #43) continues to pass. Guard against
  hardening regressing the normal install path.

### T6: CRLF equivalence still holds

- Existing CRLF test (added in PR #43) continues to pass. Guard against the
  hardening pass removing the text-file CRLF normalization.

## Not in scope

- Non-transactional install rollback (separate defect if filed).
- `doctor` scanning outside `bundle_root` for orphans (medium-severity
  Codex finding #4; separate defect if filed).

## Sources

- D000010_RCA.md (root cause)
- scripts/test.sh (existing copilot-deploy smoke test as starting point)
