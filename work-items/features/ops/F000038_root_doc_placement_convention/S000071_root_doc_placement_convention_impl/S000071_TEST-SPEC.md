---
type: test-spec
parent: S000071
feature: F000038
title: "Root-doc placement convention + validate.sh Check 17 — Test Specification"
version: 1
status: Draft
date: 2026-06-02
author: chjiang
spec: SPEC.md
reviewers: []
---

<!-- Scope: ENTIRE user story. Smoke + E2E together must cover every SPEC P0
     acceptance criterion. Soft cap: 5 rows per tier. -->

## Smoke Tests

<!-- Automated regression. Fast, deterministic, runnable from a script or CI.
     AC column maps each row to a SPEC acceptance criterion (Story #n). Soft cap: 5 rows. -->

| # | Tag | AC | Check | What It Validates | Script/Command |
|---|-----|-----|-------|-------------------|----------------|
| S1 | core | AC-3 | Clean validate.sh exits 0 with Check 17 PASS (5 entries) | The check passes on the clean PR HEAD; all 5 current root docs are allowlisted; 0 errors / 0 warnings | `./scripts/validate.sh && ./scripts/validate.sh 2>&1 \| grep -q 'PASS: root \*\.md allowlist parsed (5 entries)'` |
| S2 | resilience | AC-3 | Synthesized violation: STRAY.md at root → ERROR + exit 1; rm → exit 0 | Check 17 fires on a real orphan root doc and clears on removal (enforcement proven both directions) | `touch STRAY.md; ! ./scripts/validate.sh >/tmp/v17.out 2>&1; grep -q '  ERROR: root doc STRAY.md is not in the CLAUDE.md' /tmp/v17.out; rm -f STRAY.md; ./scripts/validate.sh` |
| S3 | integration | AC-4 | scripts/test.sh zzz-test-scaffold integration asserts the Check 17 orphan path (KNOWN BLIND SPOT — every prior new check forgot this) | The integration fixture synthesizes STRAY.md → asserts validate.sh non-zero + literal `  ERROR: root doc STRAY.md is not in the CLAUDE.md`; then rm → asserts exit 0. The new validate.sh check is wired into the integration test, not just shipped naked | `./scripts/test.sh` (zzz-test-scaffold phase exercises the Check 17 orphan assertion); spot-check the assertion is present: `grep -q 'STRAY.md' scripts/test.sh && grep -q 'root doc STRAY.md is not in the CLAUDE.md' scripts/test.sh` |
| S4 | core | AC-1, AC-2 | CLAUDE.md has the convention section + 5-entry allowlist; validate.sh has Check 17 with both branches | The two substantive surfaces (CLAUDE.md manifest + validate.sh check) landed with the required shape | `grep -q '^## Doc placement convention (root vs doc/)' CLAUDE.md && grep -q '^### Tracked root docs allowlist' CLAUDE.md && [ "$(awk '/^### Tracked root docs allowlist$/{f=1;next} /^#/{f=0} f&&/^- path:/{c++} END{print c+0}' CLAUDE.md)" = "5" ] && grep -q '=== Check 17: root-doc placement allowlist ===' scripts/validate.sh && grep -q 'is in the CLAUDE.md root-docs allowlist but missing from disk' scripts/validate.sh` |
| S5 | core | AC-5 | VERSION bumped + CHANGELOG entry present + no SKILL.md/USAGE.md/catalog churn + full test.sh green | Ancillary artifacts wired; no collateral doc-drift or catalog churn; superset suite passes | `grep -qE '^6\.0\.[4-9]' VERSION && grep -qi 'F000038' CHANGELOG.md && [ -z "$(git diff --name-only main...HEAD -- 'skills/**/SKILL.md' 'skills/**/USAGE.md' skills-catalog.json 2>/dev/null)" ] && ./scripts/test.sh` |

<!-- Tag vocabulary: core, resilience, observability, usability, security, integration.
     Modifiers (can combine with any tag): post-ship (see E2E Tests section below). -->

## E2E Tests

<!-- Manual end-to-end verification, run after implementing and before /ship.
     AC column maps each row to a SPEC acceptance criterion (Story #n). Soft cap: 5 rows. -->

| # | Tag | AC | Scenario | Steps (as a real user would) | Expected Outcome | Rubric |
|---|-----|-----|----------|------------------------------|------------------|--------|
| E1 | usability | AC-1 | A contributor reads the new CLAUDE.md section and learns where a new doc belongs | Open `CLAUDE.md`. Read `## Doc placement convention (root vs doc/)` top to bottom, including the prose rule, the load-bearing-constraint comment, and the `### Tracked root docs allowlist` block. | A contributor who hasn't seen F000038 can answer: "If I write a new explanation doc, where does it go? If I must add a root `*.md`, what do I do? Why is CLAUDE.md itself allowed at root?" | PASS if all three answered from the CLAUDE.md section alone (doc/ + tracked-doc manifest; allowlist it with a reason; CLAUDE auto-load). FAIL if any answer requires reading validate.sh or this TEST-SPEC. |
| E2 | core | AC-1, AC-2 | Diff review: the convention section + Check 17 are well-formed and constraint-compliant | `git diff main...HEAD -- CLAUDE.md scripts/validate.sh` | The CLAUDE.md block has 5 entries, each `- path:` + `reason:`, NO `#`-leading lines inside the block, and the constraint comment is OUTSIDE the fence. Check 17 disarms on `/^#/` (not `^###`), uses the inline `  ERROR:` form (not `fail()`/`  FAIL:`), and has both 17-orphan and 17-missing branches + a count-once PASS line. | PASS if the diff confirms all of the above. FAIL if the block has a stray `#` line, the constraint comment is inside the fence, the parser disarms only on `^###`, the ERROR form uses `  FAIL:`, or either branch / the PASS line is missing. |
| E3 | resilience | AC-3, AC-4 | Walk the full local pipeline: clean PASS, synthesized violation, removal, full test suite | `./scripts/check-version-queue.sh; ./scripts/validate.sh; touch STRAY.md; ./scripts/validate.sh; rm STRAY.md; ./scripts/validate.sh; ./scripts/test.sh` | check-version-queue.sh confirms the next free slot (6.0.4). First validate.sh: exit 0, Check 17 PASS (5 entries), 0 errors / 0 warnings. With STRAY.md: non-zero exit + `  ERROR: root doc STRAY.md is not in the CLAUDE.md`. After rm: exit 0. test.sh: exit 0 (zzz-test-scaffold Check 17 assertion runs + passes). | PASS if every command behaves as expected AND validate.sh explicitly names `Check 17` PASS AND the existing Checks 1–16 still PASS (no regression). FAIL if Check 17 silently skips, the orphan ERROR is missing/misspelled, test.sh fails, or any prior check regresses. |
| E4 | integration post-ship | AC-2 | Live dogfood: the pre-commit hook blocks a real stray root doc | After this PR merges + on a feature branch: create `FOO.md` at the repo root with some content; `git add FOO.md`; `git commit -m "test: stray root doc"`. Then `rm FOO.md` and retry. | The pre-commit hook runs validate.sh, Check 17 fires the orphan ERROR for `FOO.md`, and the commit is BLOCKED (non-zero). After removing FOO.md (or allowlisting it in CLAUDE.md with a reason), the commit succeeds. | PASS if the hook blocks the stray-root-doc commit with the Check 17 orphan ERROR and allows it once the file is removed/allowlisted. FAIL if the commit goes through with a stray root `*.md`, or the hook errors for an unrelated reason. |

<!-- If an E2E test skill exists for this feature, reference it here:
     N/A — manual smoke (S1-S5 are script-runnable) + manual E2E walk (E1-E3) + post-merge dogfood (E4). -->

## Coverage Gaps

<!-- What is explicitly NOT tested and why. Honesty beats false confidence. -->

| Gap | Why Not Tested | Risk Accepted |
|-----|----------------|---------------|
| The 17-missing branch (allowlist entry → missing file) is not exercised by an automated smoke row | Would require temporarily renaming/removing a real root doc (README/CLAUDE/etc.) inside the test, which is fragile in the live repo. The orphan branch (S2/S3) covers the symmetric logic; the missing branch is verified by S4's grep that the branch code exists, and optionally by a manual one-off in E3. | Mitigation: the two branches share the same inline `  ERROR:`+`ERRORS++` shape; if orphan works, missing works. A manual `mv README.md /tmp; ./scripts/validate.sh; mv back` confirms it on demand. |
| Behavior when a root `*.md` is a symlink | `find . -maxdepth 1 -type f -name '*.md'` matches regular files; a symlink to a `.md` would not be `-type f`-matched (it is `-type l`) | Mitigation: the workbench has no root `*.md` symlinks; if one is introduced, it silently escapes Check 17 — acceptable for v1 (unusual setup). Revisit only if root md-symlinks become a real pattern. |
| Behavior when CLAUDE.md is absent or unreadable | Check 17 awk-parses CLAUDE.md; if CLAUDE.md is missing, the allowlist parses empty → every root `*.md` ERRORs as orphan | Mitigation: CLAUDE.md is itself on the allowlist AND is a tracked repo file; its absence is a far larger failure than Check 17 (Claude Code auto-load breaks, many checks fail). Not Check 17's job to special-case. |
| Whether `find . -maxdepth 1` behaves identically across macOS/BSD find and GNU find | The workbench targets macOS (BSD find); CI may run GNU find | Mitigation: `-maxdepth 1 -type f -name '*.md'` is POSIX-portable across both BSD and GNU find. No find-specific extensions used. The clean-PASS smoke (S1) on CI is the cross-platform check. |
| Empty-allowlist failure mode (renamed heading / `#`-comment mid-block) | Not a dedicated automated row | Mitigation: design-intentional — an empty allowlist surfaces as an orphan ERROR for every root `*.md` (fails loudly). S4 asserts the heading + 5 entries are present; E2 diff-review confirms no stray `#` lines. The fail-loud behavior is the guard. |
| Whether `/document-release` actually reads the new CLAUDE.md section at its Step 2 project-context read | Out of scope for this story's tests; that is upstream /document-release behavior (F000034 already established CLAUDE.md is read as project context) | Mitigation: the section is plain CLAUDE.md prose under a `##` heading; /document-release's existing project-context read picks it up with no new wiring. No upstream change made or needed. |
| Non-`.md` root files (LICENSE, .shellcheckrc, .gitignore) | Explicitly out of scope — the convention governs human-readable `*.md` only | Mitigation: deferred by design (parent F000038 Not-in-scope). Check 17's `-name '*.md'` filter never sees them. |
