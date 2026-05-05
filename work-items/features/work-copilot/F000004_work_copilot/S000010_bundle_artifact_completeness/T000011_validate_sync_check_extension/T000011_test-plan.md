---
type: test-plan
parent: T000011_validate_sync_check_extension
title: "Validate Sync-Check Extension — Test Plan"
date: 2026-04-26
author: chjiang
status: Draft
---

<!-- Scope: ONE task. Cases are concrete and reproducible.
     Test plan locked in plan-eng-review D5 (2026-04-26). -->

## Scope

Extends `scripts/validate.sh` Error check 10 from a single hard-coded
template-sync check to a config-driven `MIRROR_SPECS` array iterating
multiple mirror entries. The check loops the array, branches on glob
shape (single-file / flat-glob / recursive-glob), and runs `cmp -s` per
file. Same binary comparison the existing check uses (re: D000005 — CRLF
on Windows would otherwise make checksums flap).

**Files modified:**

- `scripts/validate.sh` — Error check 10 generalized to iterate `MIRROR_SPECS`
- `scripts/test.sh` — 9 negative-path synthetic cases + 1 happy-path case (~150 lines added)
- `skills/company-workflow/company-artifact-manifests.json` — description field updated to name both audiences
- `work-copilot/copilot-artifact-manifests.json` — description field updated; content becomes byte-identical to upstream

**`MIRROR_SPECS` config (locked):**

```bash
MIRROR_SPECS=(
  "templates/company-workflow/*.md:work-copilot/templates/*.md"
  "skills/company-workflow/WORKFLOW.md:work-copilot/WORKFLOW.md"
  "skills/company-workflow/reference/*.md:work-copilot/reference/*.md"
  "skills/company-workflow/philosophy/*.md:work-copilot/philosophy/*.md"
  "skills/company-workflow/examples/*.md:work-copilot/examples/*.md"
  "skills/company-workflow/fixtures/**/*.md:work-copilot/fixtures/**/*.md"
  "skills/company-workflow/company-artifact-manifests.json:work-copilot/copilot-artifact-manifests.json"
)
```

## Regression Test Cases

The following 10 test cases run as a self-contained block in `scripts/test.sh`.
Each case builds a tmpdir with a stripped Error check 10 callable, asserts
expected behavior, then cleans up. Reuses the `mktemp -d -t ...` +
post-test cleanup pattern from `scripts/test.sh:1454-1510`.

The 9 negative cases are 3 glob shapes × 3 failure modes:

| # | Test Case | Steps | Expected Result | Status |
|---|-----------|-------|-----------------|--------|
| 1 | **Single-file shape, drift** | Build tmpdir; create `src/A.md` and `dst/A.md` with different content; run check with spec `src/A.md:dst/A.md` | Exit non-zero; error string mentions `A.md` and "drift" (or equivalent token) | Pending |
| 2 | **Single-file shape, missing-file** | Build tmpdir; create only `src/A.md`; run check with spec `src/A.md:dst/A.md` | Exit non-zero; error string mentions `dst/A.md` is missing | Pending |
| 3 | **Single-file shape, orphan** | Build tmpdir; create only `dst/A.md`; run check with spec `src/A.md:dst/A.md` | Exit non-zero; error string mentions `src/A.md` is missing (orphan in dst) | Pending |
| 4 | **Flat-glob shape, drift** | Build tmpdir; create `src/{A,B}.md` and `dst/{A,B}.md` with B differing; run check with spec `src/*.md:dst/*.md` | Exit non-zero; error string mentions `B.md` and "drift" | Pending |
| 5 | **Flat-glob shape, missing-file** | Build tmpdir; create `src/{A,B}.md`, only `dst/A.md`; run check with spec `src/*.md:dst/*.md` | Exit non-zero; error string mentions `dst/B.md` is missing | Pending |
| 6 | **Flat-glob shape, orphan** | Build tmpdir; create `src/A.md`, `dst/{A,B}.md`; run check with spec `src/*.md:dst/*.md` | Counterpart-warning loop emits a warning for `dst/B.md`; main check still exits 0 (orphan is warn, not fail — preserves existing behavior). Verify the warning string mentions `B.md` | Pending |
| 7 | **Recursive-glob shape, drift** | Build tmpdir with nested dirs (`src/sub/A.md`, `dst/sub/A.md` with different content); run check with spec `src/**/*.md:dst/**/*.md` | Exit non-zero; error string mentions nested `sub/A.md` | Pending |
| 8 | **Recursive-glob shape, missing-file** | Build tmpdir with nested dirs; create only `src/sub/A.md`; run check with spec `src/**/*.md:dst/**/*.md` | Exit non-zero; error string mentions `dst/sub/A.md` is missing | Pending |
| 9 | **Recursive-glob shape, orphan** | Build tmpdir; create `src/sub/A.md`, `dst/sub/{A,B}.md`; run check with spec `src/**/*.md:dst/**/*.md` | Counterpart-warning emits warning for `dst/sub/B.md`; main check still exits 0 | Pending |
| 10 | **Happy path — all in sync** | Build tmpdir with multiple specs covering all 3 shapes, all pairs byte-identical; run check | Exit 0; no error / warning output | Pending |

### Additional regression cases (existing v1 behavior must still pass)

| # | Test Case | Steps | Expected Result | Status |
|---|-----------|-------|-----------------|--------|
| 11 | **v1 templates check still passes** | After T000011 lands, run the full `scripts/validate.sh` against the actual repo state | Exit 0 (assuming `templates/company-workflow/*.md` and `work-copilot/templates/*.md` are still in sync, which they were pre-T000011) | Pending |
| 12 | **OS-junk filter (macOS)** | Build tmpdir with `dst/.DS_Store` present; run flat-glob shape spec | Check ignores `.DS_Store` — exits 0 (or whatever the in-sync `*.md` files dictate) | Pending |
| 13 | **OS-junk filter (Windows)** | Build tmpdir with `dst/Thumbs.db` present; run flat-glob shape spec | Check ignores `Thumbs.db` — exits 0 | Pending |
| 14 | **Binary-mode comparison (CRLF safety)** | Build tmpdir with `src/A.md` (LF line endings) and `dst/A.md` (same content but CRLF line endings); run single-file spec | Exit non-zero — `cmp -s` correctly identifies the byte difference, re-protecting against D000005 | Pending |
| 15 | **Manifest-pair sync** | After T000011 lands, both manifest files contain unified description naming both audiences AND have byte-identical remaining content | `cmp -s skills/company-workflow/company-artifact-manifests.json work-copilot/copilot-artifact-manifests.json` exits 0 | Pending |

## Verification Steps

<!-- How was the fix verified beyond the test cases above? -->

- [ ] Local build succeeds (macOS — primary dev box)
- [ ] `scripts/validate.sh` passes against the post-S000010 repo state (templates + 5 new mirror dirs all in sync)
- [ ] `scripts/test.sh` passes (existing tests + 10 new negative/happy cases + 5 additional regressions)
- [ ] Manual reproduction: introduce a single-file drift (e.g., edit `work-copilot/WORKFLOW.md`), run `scripts/validate.sh`, confirm non-zero exit with named diverged file; revert
- [ ] Manual reproduction: introduce a flat-glob drift (e.g., edit `work-copilot/reference/guide-task.md`), run `scripts/validate.sh`, confirm same; revert
- [ ] Manual reproduction: introduce a recursive-glob drift (e.g., edit `work-copilot/fixtures/valid-feature-dir/TRACKER.md`), run `scripts/validate.sh`, confirm same; revert
- [ ] Cross-platform smoke: CI (Linux runner) passes the full test suite — confirms no macOS-specific bash assumptions slipped in
- [ ] Future-extensibility check: add a synthetic 8th `MIRROR_SPECS` entry, confirm the loop picks it up without other code changes

## Environments Tested

| Environment | Build | Result |
|------------|-------|--------|
| macOS (primary dev) | feat/v1-cut branch | Pending |
| Linux (CI runner) | feat/v1-cut branch | Pending |
| Windows (work box) | n/a — `validate.sh` is bash-only; runs in CI / on the maintainer's box, not on Copilot users' machines | n/a |
