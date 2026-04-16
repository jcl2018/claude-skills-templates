---
name: "skills-deploy fails on Windows — jq output has trailing \\r"
type: defect
id: "D000005"
status: active
created: "2026-04-16"
updated: "2026-04-16"
repo: "jcl2018/claude-skills-templates"
branch: "claude/nostalgic-volhard"
blocked_by: ""
---

## Lifecycle

### Phase 1: Track

1. Document reproduction steps in the Log section
2. Create working branch: `git checkout -b fix/skills-deploy-windows-jq-crlf`
3. Scaffold required docs:
   - `D000005_RCA.md` (root cause analysis) — from `templates/doc-RCA.md`
   - `D000005_test-plan.md` (regression test plan) — from `templates/doc-test-plan.md`
4. Run `/investigate` to diagnose root cause
   → produces investigation findings in Log + Insights
5. Log initial symptoms and hypotheses

**Gates:**
- [x] Reproduction steps documented
- [ ] Working branch created (`branch` field populated — currently on `claude/nostalgic-volhard`; no new branch since fix is single-line and already applied locally by the reporter)
- [x] Required docs scaffolded (RCA + test-plan)
- [x] Root cause identified (Windows jq emits CRLF line endings)

### Phase 2: Implement

1. Work from `/office-hours` design doc (if applicable) + root cause analysis
2. Implement fix based on root cause analysis
3. Write regression test covering the defect scenario
4. Commit fix and test together
5. Update RCA doc with final root cause

**Gates:**
- [x] Fix committed (`jq()` wrapper inserted in `scripts/skills-deploy:24`, `scripts/lib.sh:21-24`, and `scripts/test-deploy.sh:7-9` — covers all scripts reached during Windows install; commit pending `/ship`)
- [x] RCA doc updated with final fix location + commit SHA (SHA populated by `/ship`)
- [x] Todos section reflects remaining work (no stale items)

### Phase 3: Ship

1. Run `/personal-workflow check` — verify no regressions
2. Verify test-plan: regression test scenarios passing
3. Run `/ship` — creates fix PR (includes pre-landing code review)
4. Run `/land-and-deploy` — merges and verifies fix in production

❌ If regression test fails: investigate further
❌ If CI fails: fix, push, re-run `/ship`

**Gates:**
- [ ] `/personal-workflow check` — validation passed
- [ ] Test-plan verified (regression scenarios passing)
- [ ] `/ship` — PR created
- [ ] `/land-and-deploy` — merged and deployed

## Reproduction Steps

Surfaced while deploying the `/company-workflow` skill on Windows via `scripts/skills-deploy install`. The same root cause affects any skill install that runs jq on Windows.

1. On a Windows host, clone this repo and run `scripts/skills-deploy install`
2. Observe two classes of failure:
   - **Symptom A — template name validation:** template entries pulled from the catalog come back as `company-workflow/tracker-feature.md\r`. The `\.md$` regex check in the validator treats the `\r` as trailing garbage and rejects the name.
   - **Symptom B — integer comparison:** `files | length` returns `0\r`; the surrounding `[ "$count" -eq 0 ]` bash test fails with `[: : integer expression expected`.
3. Neither symptom reproduces on macOS or Linux — jq on those platforms emits bare `\n` line endings.

**Environment:** Windows (Git Bash / MSYS / WSL-mounted `jq.exe`). Any `jq.exe` built for Windows that writes in text mode appends CRLF. macOS Darwin 25.3.0 and mainstream Linux distros are unaffected.

**Discovered via:** reporter deploying `/company-workflow` to a Windows host. The bug is in `scripts/skills-deploy`, not in `/company-workflow` — it is a deployment-tooling defect that blocks Windows consumers of any skill.

## Todos

- [x] Add the `jq()` wrapper to `scripts/skills-deploy` after the `require_jq()` function (line 22):
  ```bash
  jq() { command jq "$@" | tr -d '\r'; }
  ```
- [x] Audit other scripts for direct jq usage — 13 scripts use jq; 8 source `lib.sh`, 2 are standalone (`skills-deploy`, `test-deploy.sh`).
- [x] Apply the wrapper consistently: added to `scripts/lib.sh` (covers the 8 sourcing scripts) and inline in `scripts/test-deploy.sh` (standalone). `skills-deploy` keeps its own (also standalone).
- [x] Add a regression test covering wrapper presence + CR stripping + `jq -e` exit-status propagation through the pipe (5 checks in `scripts/test.sh`).
- [x] Update `CHANGELOG.md` under 0.7.1 → Fixed + Added.
- [x] Bump version per `scripts/collection-version.sh` (0.7.0 → 0.7.1).
- [ ] Run `/personal-workflow check` to confirm validation clean (pending).
- [ ] Ship via `/ship` (in progress).

## Log

- 2026-04-16: Created. Reporter hit this on Windows while deploying `/company-workflow`. Fix already applied locally by the reporter (one-line jq wrapper after `require_jq()`). Just needs to land in the repo with a regression test.
- 2026-04-16: Applied the one-line `jq()` wrapper to `scripts/skills-deploy` at line 22 (between `require_jq()` and `manifest_read()`). Verified with `bash -n` (syntax OK) and `./scripts/validate.sh` (PASS, 0 errors / 0 warnings).
- 2026-04-16: Extended coverage — added wrapper to `scripts/lib.sh` (sourced by validate/test/doctor/lint/deps/generate-readme/sync-upstream/collection-version) and inline in `scripts/test-deploy.sh`. Confirmed `pipefail` is set in every affected script, so `jq -e` exit status still propagates through the tr pipe. Added 5 regression tests in `scripts/test.sh` (wrapper presence in each of the 3 files + CR-stripping behavior + `jq -e` false-exit propagation). Bumped VERSION 0.7.0 → 0.7.1 and wrote the 0.7.1 CHANGELOG entry.

## PRs

## Files

- `scripts/skills-deploy` (line 22, immediately after `require_jq()`) — insert `jq() { command jq "$@" | tr -d '\r'; }` wrapper
- `scripts/validate.sh`, `scripts/doctor.sh`, `scripts/lint-skill.sh`, `scripts/generate-readme.sh`, `scripts/sync-upstream.sh`, `scripts/collection-version.sh` — audit for direct jq usage; apply same wrapper if any run during Windows install
- `CHANGELOG.md` — Unreleased → Fixed entry
- `VERSION` — patch bump (via `scripts/collection-version.sh`)

## Insights

The fundamental issue is that `jq.exe` on Windows writes output in text mode, which translates `\n` to `\r\n`. Every bash script consuming jq output on Windows inherits this bug. A global wrapper at the script level (shell-function override of `jq`) is the smallest possible fix because bash function lookup beats `$PATH` lookup, so all existing `jq ...` call sites are transparently fixed without edits.

Alternative approaches considered:
- **Per-call `tr -d '\r'`** — noisy, easy to miss a call site. Rejected.
- **`jq --raw-output0` or `jq -j`** — changes semantics, doesn't address the line-ending issue. Rejected.
- **Setting `JQ_COLORS` or similar env var** — no env var controls line endings in jq. Not an option.
- **Running jq under `winpty` or redirecting through `dos2unix`** — heavier, external-tool dependency. Rejected.

The chosen shell-function wrapper is minimal, zero-dep, zero-behavior-change on Unix (where `tr -d '\r'` is a no-op on clean input), and fully transparent to call sites.

Cross-reference: no other active defects touch skills-deploy. D000003 and D000004 touch company-workflow contract/templates and are unrelated.

## Journal
