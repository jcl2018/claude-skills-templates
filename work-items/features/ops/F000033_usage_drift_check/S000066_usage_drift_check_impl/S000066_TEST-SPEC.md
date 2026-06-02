---
type: test-spec
parent: S000066
feature: F000033
title: "USAGE.md drift detection — Test Specification"
version: 1
status: Draft
date: 2026-06-01
author: chjiang
spec: SPEC.md
reviewers: []
---

<!-- Scope: ENTIRE user story. Smoke + E2E together must cover every SPEC P0
     acceptance criterion. -->

## Smoke Tests

<!-- Automated regression. Fast, deterministic, runnable from a script or CI.
     Soft cap: 5 rows. -->

| # | Tag | AC | Check | What It Validates | Script/Command |
|---|-----|-----|-------|-------------------|----------------|
| S1 | core | AC-1, AC-2, AC-4 | Check 14 block exists with matching audit predicate and uses git-log %ct, NOT mtime | Story #1, #2, #4 — Check 14 is structurally what we designed | `grep -q 'Check 14' scripts/validate.sh && grep -q "status != .deprecated." scripts/validate.sh && grep -q "git log -1 --format=%ct" scripts/validate.sh && ! grep -q "stat -f %m" scripts/validate.sh` |
| S2 | resilience | AC-10 | validate.sh green on PR HEAD (all 11 USAGE.md share atomic %ct with their SKILL.md from F000032) | Story #10 — Check 14 PASSes on the steady state | `./scripts/validate.sh` |
| S3 | core, observability | AC-3, AC-5, AC-9 | Drift → ERROR with override embedded; override clears the drift | Story #3 + #5 + #9 — full positive cycle | The new `scripts/test.sh` test exercises: (a) record SKILL.md %ct, (b) commit a real SKILL.md content change, (c) assert validate.sh exits non-zero with `Check 14` + override commands in output, (d) run override (sed `last-updated:` + git add + git commit), (e) assert validate.sh exits 0, (f) `git reset --hard <prior-sha>` cleans up |
| S4 | observability | AC-6 | SKIP (not ERROR) when git log returns empty | Story #6 — freshness vs presence handoff | `tmp=$(mktemp -d); git init -q "$tmp" && cd "$tmp" && mkdir -p skills/zz && echo "# zz" > skills/zz/SKILL.md && touch skills/zz/USAGE.md && bash -c 'CT=$(git log -1 --format=%ct -- skills/zz/USAGE.md); [ -z "$CT" ] && echo SKIP-OK || exit 1'; rm -rf "$tmp"` (one-shot verification of the SKIP precondition; the validate.sh skip line itself is asserted by S3's setup phase being non-fatal) |
| S5 | resilience | AC-11 | test.sh green on PR HEAD (full superset suite) | Story #11 — no regressions | `./scripts/test.sh` |

<!-- Tag vocabulary: core, resilience, observability, usability, security, integration. -->

## E2E Tests

<!-- Manual end-to-end verification, run after implementing and before /ship.
     Soft cap: 5 rows. -->

| # | Tag | AC | Scenario | Steps (as a real user would) | Expected Outcome | Rubric |
|---|-----|-----|----------|------------------------------|------------------|--------|
| E1 | usability | AC-14 | The Assignment (post-ship, after both PRs merge) | After merging this PR + PR #186: open `skills/CJ_system-health/SKILL.md`, make a one-character cosmetic edit (e.g. fix a typo), `git add` + `git commit`. Run `./scripts/validate.sh`. Read the Check 14 ERROR output. Copy-paste the override commands as-shown. Run them. Re-run `./scripts/validate.sh`. | Check 14 fires ERROR with override commands embedded; copy-paste runs without error; re-run shows Check 14 PASS. | PASS if the full loop takes < 60 sec. FAIL if any step requires fishing for syntax docs or the override doesn't actually clear Check 14 — file a follow-up. |
| E2 | usability | AC-7 | CLAUDE.md `### USAGE.md drift detection` is discoverable | Open `CLAUDE.md`. Search for "drift" using your editor's find. | The new subsection appears under `## Conventions`. It explains Check 14, the override one-liner, and the `--allow-empty` warning. | PASS if a reader unfamiliar with F000033 can resolve a Check 14 ERROR using only the CLAUDE.md text. FAIL if they need to read scripts/validate.sh source. |
| E3 | usability | AC-8 | PHILOSOPHY.md drift-rule paragraph is in the right section | Open `doc/PHILOSOPHY.md ## Documentation surfaces`. | The paragraph is appended after F000032's content; it documents the drift rule + override + the `last-updated:` audit-trail role. | PASS if the section reads as a coherent F000032+F000033 unit (presence + structure + freshness). FAIL if the paragraph feels bolted on or contradicts F000032's framing. |
| E4 | observability post-ship | AC-3 | CI catches a future drift regression | After merge, on a throwaway branch: touch + commit a SKILL.md change without updating USAGE.md. Push. | CI `validate.sh` step fails with Check 14 ERROR naming the stale USAGE.md and showing the override. | PASS if CI red on the throwaway branch with a clear ERROR. FAIL if green or if the ERROR doesn't surface the override. (Post-ship — workflow only exists after merge.) |

<!-- If an E2E test skill exists for this feature, reference it here:
     N/A — manual smoke. -->

## Coverage Gaps

<!-- What is explicitly NOT tested and why. -->

| Gap | Why Not Tested | Risk Accepted |
|-----|----------------|---------------|
| Whether the override produces "good" USAGE.md content (i.e., that the operator actually read SKILL.md and confirmed currency before bumping `last-updated:`) | Cannot be encoded in a structural audit | Mitigation = the friction itself: forcing the operator to acknowledge the edit is the audit trail. If someone routinely bumps `last-updated:` without reading, the failure surfaces downstream (USAGE.md says one thing, SKILL.md says another) and a different audit/review catches it. |
| Distinguishing "real" vs "cosmetic" SKILL.md edits | Heuristic (Approach B from parent design); over-budget for v1 | A cosmetic SKILL.md edit (typo) fires Check 14 unnecessarily; the override is the documented cost. |
| BSD sed compatibility under exotic locales (LC_ALL, etc.) | Out of scope; macOS default locale is the target | If an operator runs the override in a non-default locale, sed might behave differently — they get a clear error and can adjust. |
| Concurrent-PR collision (two PRs both editing SKILL.md without touching USAGE.md) | Out of scope; Check 14 runs at validate-time per-PR | Each PR's own validate.sh run catches drift within that PR; cross-PR coordination is /ship's queue-collision check, not Check 14's job. |
| work-copilot/ skills | Workbench-only scope (Constraint #1 from design) | Copilot bundle has no USAGE.md surface; no Check 14 needed there. |
| Per-skill snooze of Check 14 | Single global ERROR is sufficient for v1 | If a specific skill genuinely shouldn't have a USAGE.md but is routable, the right fix is to deprecate / hide it from the audit predicate, not to add per-skill snooze. |
