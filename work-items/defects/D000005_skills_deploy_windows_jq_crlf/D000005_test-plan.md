---
type: test-plan
parent: D000005
title: "skills-deploy fails on Windows — jq output has trailing \\r — Regression Test Plan"
date: 2026-04-16
author: chjiang
status: Draft
---

## Scope

Validates the one-line `jq()` wrapper fix in `scripts/skills-deploy` (inserted after `require_jq()` at line 22) and its downstream effect on Windows deployments.

Files in scope:
- `scripts/skills-deploy` (the only required edit)
- Any other script under `scripts/` that invokes `jq` and is reachable during a Windows `install` run (audit outcome dictates whether fixes are added)

Out of scope:
- Unrelated skill-contract or template-drift defects (D000003, D000004)
- jq invocations in `.github/workflows/` or other CI config (if any) — separate defect if found

## Regression Test Cases

### Pre-fix baseline (current state on Windows — should be RED)

| # | Test Case | Steps | Expected Result | Status |
|---|-----------|-------|-----------------|--------|
| 1 | **Pre-fix:** `skills-deploy install` on Windows rejects template names | Run `scripts/skills-deploy install` on Windows Git Bash; capture stderr | Error referencing `...\.md\r` or the `\.md$` regex check failing | Pending |
| 2 | **Pre-fix:** `skills-deploy install` on Windows hits integer-comparison error | Run `scripts/skills-deploy install` on Windows Git Bash; capture stderr | `[: : integer expression expected` on a `files \| length` comparison | Pending |

### Post-fix expected behavior

| # | Test Case | Steps | Expected Result | Status |
|---|-----------|-------|-----------------|--------|
| 3 | **Fix present:** wrapper function defined in `skills-deploy` | Grep `scripts/skills-deploy` for `jq() { command jq "$@" \| tr -d '\r'; }` | Exactly one match immediately after `require_jq()` | Pending |
| 4 | **Wrapper strips CR in output:** simulate Windows jq | `printf '{"files":[]}\r\n' \| jq '.files \| length'` with wrapper active | Output is `0` with no trailing `\r` (verify with `xxd`) | Pending |
| 5 | **Install succeeds on Windows:** run end-to-end | Windows Git Bash: clone repo; `scripts/skills-deploy install` | Exit 0; manifest written; no `\.md\r` regex errors; no `integer expression expected` errors | Pending |
| 6 | **Install succeeds on macOS:** regression check | macOS: `scripts/skills-deploy install` into a scratch target | Exit 0; behavior unchanged from pre-fix | Pending |
| 7 | **Install succeeds on Linux:** regression check | Linux: `scripts/skills-deploy install` into a scratch target | Exit 0; behavior unchanged from pre-fix | Pending |
| 8 | **Template-name regex accepts catalog entries:** catalog path sanity | After install, inspect the template names recorded in `$HOME/.claude/.skills-templates.json` | No `\r` bytes anywhere in the manifest (`xxd` / grep -P '\r') | Pending |
| 9 | **Numeric comparison paths work:** catalog with zero-file entry | Run install against a catalog entry whose `files` array is empty; confirm the `files \| length` branch takes the zero path cleanly on Windows | No bash arithmetic error; script takes the expected zero-files branch | Pending |
| 10 | **Other reachable scripts audited:** jq-call survey | `grep -rn 'jq ' scripts/` | For every script invoked during install on Windows, either uses the wrapper (via sourcing) or has its own wrapper | Pending |

### Cross-platform regression (always required)

| # | Test Case | Steps | Expected Result | Status |
|---|-----------|-------|-----------------|--------|
| 11 | `./scripts/validate.sh` exits 0 on macOS | run script | Exit 0 | Pending |
| 12 | `./scripts/test.sh` exits 0 on macOS | run script | Exit 0 | Pending |
| 13 | `/personal-workflow check` on `work-items/` — no new violations | run skill | No new violations vs. pre-fix baseline | Pending |
| 14 | No unintended edits outside `scripts/skills-deploy` | `git diff --name-only main...HEAD` | Only `scripts/skills-deploy`, `CHANGELOG.md`, `VERSION`, and the D000005 work-item files | Pending |

### Post-ship verification

| # | Test Case | Steps | Expected Result | Status |
|---|-----------|-------|-----------------|--------|
| 15 | Reporter re-runs original workflow | Reporter on Windows: `skills-deploy install` + `/company-workflow` scaffold | Both steps clean, no CRLF-related errors | Pending |
| 16 | Catalog round-trip on Windows | Reporter: `skills-deploy doctor` on the installed target | Clean report, no false "drift" flagged due to CRLF | Pending |

## Verification Steps

- [ ] Wrapper function added to `scripts/skills-deploy` after `require_jq()` (line 22)
- [ ] `./scripts/validate.sh` exits 0 on macOS (sanity)
- [ ] `./scripts/test.sh` exits 0 on macOS
- [ ] Windows reproduction of Symptoms A and B confirms both are gone post-fix
- [ ] `xxd` inspection of an installed manifest on Windows shows no `\r` bytes
- [ ] CHANGELOG.md updated under Unreleased → Fixed
- [ ] VERSION bumped (patch level) via `scripts/collection-version.sh`
- [ ] Audit of `scripts/*.sh` for other reachable jq call sites — decide per-script whether wrapper or pipe is needed
- [ ] `/personal-workflow check` passes
- [ ] PR created via `/ship`
- [ ] PR reviewed and merged via `/land-and-deploy`

## Environments Tested

| Environment | Build | Result |
|-------------|-------|--------|
| Windows (Git Bash, native `jq.exe`) | branch `fix/skills-deploy-windows-jq-crlf` | Pending |
| macOS Darwin 25.3.0 | branch `claude/nostalgic-volhard` (current work) | Pending |
| Linux (any mainstream distro with jq) | latest | Pending |
