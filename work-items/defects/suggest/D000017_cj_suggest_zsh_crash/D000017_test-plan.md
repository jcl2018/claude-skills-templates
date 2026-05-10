---
type: test-plan
parent: D000017
title: "/CJ_suggest crashes under zsh — Test Plan"
date: 2026-05-10
author: chjiang
status: Draft
---

<!-- Scope: ONE fix (defect) or ONE task. Cases must be concrete and reproducible.
     For broader coverage of a user story, use TEST-SPEC.md instead.
     For defects, the test cases are regression cases for the specific bug. -->

## Scope

The fix covers three files in the workbench repo:

- `skills/CJ_suggest/SKILL.md` — heredoc bash body replaced by a one-liner
  `bash "$(git rev-parse --show-toplevel)/skills/CJ_suggest/scripts/suggest.sh"`;
  the now-obsolete "Single-file by design" caveat in Notes is trimmed.
- `skills/CJ_suggest/scripts/suggest.sh` — new file containing the existing
  bash body verbatim with `#!/usr/bin/env bash` shebang and `set -euo pipefail`.
- `skills-catalog.json` — `CJ_suggest` entry's `files` array gains
  `skills/CJ_suggest/scripts/suggest.sh`.

User-facing surface (markdown output, catalog metadata, CLAUDE.md routing rules)
is unchanged by design.

## Regression Test Cases

| # | Test Case | Steps | Expected Result | Status |
|---|-----------|-------|-----------------|--------|
| 1 | Original zsh crash no longer reproduces | On a zsh-harness machine, invoke `/CJ_suggest` after the fix lands | Skill prints a 5-row markdown ranked table; no `(eval):33: read-only variable: status` error; exit 0 | Pending |
| 2 | Direct script invocation works under bash | From repo root, run `bash skills/CJ_suggest/scripts/suggest.sh` with the canonical fixture (current `TODOS.md` + `work-items/`) | 5-row markdown table identical in ordering to the in-session reproducer's table | Pending |
| 3 | Direct script invocation works under zsh | From repo root, run `zsh -c 'bash skills/CJ_suggest/scripts/suggest.sh'` | Same 5-row table as case 2 — shebang pins to bash regardless of caller | Pending |
| 4 | `scripts/validate.sh` passes | After catalog update, run `./scripts/validate.sh` from repo root | Exit 0; no "missing files" / "orphaned files" / "catalog drift" errors | Pending |
| 5 | `scripts/test.sh` passes | After catalog update, run `./scripts/test.sh` from repo root | Exit 0 (covers validate + any existing eval case for /CJ_suggest) | Pending |
| 6 | `skills-deploy install` propagates the script | In a scratch `HOME=/tmp/scratch-home`, run `./scripts/skills-deploy install` from repo root | `/tmp/scratch-home/.claude/skills/CJ_suggest/scripts/suggest.sh` exists, contents match source byte-for-byte | Pending |
| 7 | Identical output across both harness shells | Run `/CJ_suggest` once on a zsh-harness machine and once on a bash-harness machine (or simulate via `SHELL=zsh /CJ_suggest` vs `SHELL=bash /CJ_suggest`) | Tables are byte-identical (same top-5, same order, same scores) | Pending |
| 8 | `set -euo pipefail` does not regress today's tolerated paths | With the canonical fixture, run the script through every code path that today exits non-zero gracefully (e.g., empty `TODOS.md`, no work-items) | Each path still produces the appropriate human-readable error and the right exit code; no surprise abort from `pipefail` | Pending |

## Verification Steps

<!-- How was the fix verified beyond the test cases above? -->

- [ ] Local build succeeds (Windows/Linux) — N/A; skill is macOS-only by design.
- [ ] L1 regression suite passes — covered by test case 5 (`scripts/test.sh`).
- [ ] Manual reproduction of original bug confirms fix — covered by test case 1.
- [ ] `scripts/validate.sh` exits 0 — covered by test case 4.
- [ ] `skills-deploy install` deploys the script with executable bit set — covered by test case 6 (extend to verify `chmod +x` if shebang requires it; otherwise `bash <path>` invocation makes the bit irrelevant).
- [ ] `tests/eval/CJ_suggest/` case updated or deferred to F000013 V1 per design's Open Question Q1.

## Environments Tested

| Environment | Build | Result |
|------------|-------|--------|
| macOS (Darwin 25.3.0), Claude Code with `Shell: zsh` | `claude-skills-templates` HEAD post-fix | Pending |
| macOS, Claude Code with `Shell: bash` (if available) | `claude-skills-templates` HEAD post-fix | Pending |
| Scratch `HOME` (skills-deploy install verification) | `claude-skills-templates` HEAD post-fix | Pending |
