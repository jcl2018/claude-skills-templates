---
type: test-spec
parent: S000029
feature: F000014
title: "/personal-pipeline auto-default — Test Specification"
version: 1
status: Draft
date: 2026-05-09
author: chjiang
spec: SPEC.md
reviewers: []
---

<!-- Scope: ENTIRE user story. Smoke + E2E together must cover every SPEC P0
     acceptance criterion. Two tiers — Smoke = automated regression in CI;
     E2E = manual user-scenario verification before /ship. Soft cap: 5 rows
     per tier. The smoke tests are mostly grep-shaped because the work is
     code-deletion + structural-replacement; the E2E covers the actual
     orchestrator runs. -->

## Smoke Tests

<!-- Automated regression. Fast, deterministic, runnable from a script or CI.
     Once written, you should not need to edit these. Soft cap: 5 rows.
     Each row maps to a SPEC AC story number via the AC column. -->

| # | Tag | AC | Check | What It Validates | Script/Command |
|---|-----|-----|-------|-------------------|----------------|
| S1 | core | AC-4 | `$AUTO_MODE` variable fully removed from pipeline.md | Story #4: zero references AND zero assignments of `$AUTO_MODE` in the file | `! grep -nE '(\$AUTO_MODE|^AUTO_MODE=|[^=]AUTO_MODE=)' skills/personal-pipeline/pipeline.md` |
| S2 | core | AC-12 | Per-step "Auto mode (Step N)" headers all collapsed | Story #12: all 7 conditional headers gone | `! grep -n 'Auto mode (Step' skills/personal-pipeline/pipeline.md` |
| S3 | core | AC-5,AC-6 | SKILL.md `## Auto Mode` section deleted; Usage shows single invocation only | Stories #5, #6: documented surface matches single-mode runtime | `! grep -n '^## Auto Mode' skills/personal-pipeline/SKILL.md && ! grep -nE '/personal-pipeline.*\[--auto\]' skills/personal-pipeline/SKILL.md` |
| S4 | core | AC-9,AC-10 | CHANGELOG contains explicit reversal phrase; VERSION shows 1.16.0 | Stories #9, #10: release artifacts encode the honest reversal | `grep -q 'reverses S000028 premise 1' CHANGELOG.md && grep -qx '1.16.0' VERSION` |
| S5 | core | AC-11 | Top-level repo validation suite passes after the change | Story #11: validate.sh and test.sh both green; catches catalog/structure drift, manifest sync, etc. | `./scripts/validate.sh && ./scripts/test.sh` |

<!-- Tag vocabulary: core, resilience, observability, usability, security, integration -->

## E2E Tests

<!-- Manual end-to-end verification, run after implementing and before /ship.
     You drive the feature as a real user would and observe the outcome.
     Soft cap: 5 rows. Each row should be one user-visible scenario. -->

| # | Tag | AC | Scenario | Steps (as a real user would) | Expected Outcome | Rubric |
|---|-----|-----|----------|------------------------------|------------------|--------|
| E1 | core | AC-2 | `--auto` flag is silent no-op | (1) Install v1.16.0 via `./scripts/skills-deploy install`. (2) Run `/personal-pipeline --auto /tmp/does-not-exist.md`. (3) Observe parser output and exit code. | The parser strips `--auto` silently (no warning, no error from arg parsing); the pipeline proceeds to Step 1 design-doc-existence check and exits with the standard "Error: design doc not found at /tmp/does-not-exist.md" message. Exit code matches the no-flag invocation against the same fixture. | PASS if no `--auto` warning appears in output AND exit code matches no-flag baseline. FAIL if any "unknown flag" or "deprecated flag" warning surfaces. |
| E2 | core | AC-3 | `--manual` flag is silent no-op (symmetric) | (1) Same v1.16.0 install. (2) Run `/personal-pipeline --manual /tmp/does-not-exist.md`. (3) Observe parser output and exit code. | Same as E1: `--manual` stripped silently; standard "design doc not found" error from Step 1; exit code matches the no-flag invocation. | PASS if no `--manual` warning appears AND exit code matches no-flag baseline. FAIL if asymmetric handling surfaces (e.g., `--manual` errors but `--auto` silently passes). |
| E3 | core | AC-1,AC-7,AC-8 | No-flag default invocation runs end-to-end in auto mode with Step 8.5 firing and telemetry recording | (1) Same v1.16.0 install. (2) Run `/personal-pipeline ~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-claude-vigilant-ride-11f98a-design-20260509-221215.md` (this very design doc, post-merge — the self-dogfood). (3) Watch the orchestrator walk Phase 2-4. (4) Observe Step 8.5 final approval gate. (5) Tail the telemetry JSONL. | Pipeline runs end-to-end without prompting for `--auto`. Step 8.5 fires with the structured summary (Taste + User-Challenge-Approved decisions surfaced). Telemetry JSONL row appended with `mode: "auto"` literal. Sub-skills (`/scaffold-work-item`, `/implement-from-spec`, `/qa-work-item`) execute as fresh-context subagents per the file-only handoff contract. | PASS if pipeline completes (or halts cleanly at a real gate, not a flag-parsing artifact), Step 8.5 fires per its existing carve-out logic, AND telemetry shows `mode: "auto"`. FAIL if any "manual mode" prompt or `$AUTO_MODE` reference surfaces in runtime output. |
| E4 | usability | AC-6,AC-14,AC-15 | SKILL.md, catalog, README all reflect single-mode UX consistently | (1) `cat skills/personal-pipeline/SKILL.md | grep -A2 '^## Usage'` — confirm Usage shows `/personal-pipeline <design-doc-path>` only. (2) `jq '.[] | select(.name == "personal-pipeline") | .description' skills-catalog.json` — confirm description has no "auto vs manual" duality. (3) `grep -A3 'personal-pipeline' README.md` — confirm regenerated README matches catalog. | All three surfaces narrate single-mode consistently. No `[--auto]` token in Usage; no "manual" duality in catalog description; README regeneration matches the catalog change. | PASS if all three surfaces are consistent. FAIL if any surface still mentions `--auto` as a flag option or "manual mode" as an alternative. |
| E5 | observability | AC-16 | TODOS.md follow-up entry added for v1.17.0 telemetry field deletion | (1) `grep -n 'v1.17.0' TODOS.md`. (2) Inspect the matched entry's contents. | One entry exists describing the v1.17.0 telemetry `mode` field deletion: "drop telemetry `mode` field from `~/.gstack/analytics/personal-pipeline.jsonl` JSONL writes (always `auto` literal in v1.16.0; no consumer needs the field)." Entry is sized P4/S. | PASS if entry exists with the v1.17.0 reference, the field name (`mode`), and the rationale. FAIL if entry missing or vague. |

<!-- If an E2E test skill exists for this feature, reference it here:
     E2E test skill: /personal-pipeline (the orchestrator itself is the dogfood vehicle for E3)
     Run with: `/personal-pipeline ~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-claude-vigilant-ride-11f98a-design-20260509-221215.md` (after merge) -->

## Coverage Gaps

<!-- What is explicitly NOT tested and why. Honesty beats false confidence. -->

| Gap | Why Not Tested | Risk Accepted |
|-----|----------------|---------------|
| Telemetry JSONL backwards-compat with external readers (no `mode` field consumers known) | Scale=1, no external readers identified; would require synthesizing a hypothetical consumer | If an unknown consumer breaks on the `"auto"` literal in v1.16.0 (unlikely, since the field stays present), fix is to roll forward to v1.17.0 with field deletion clearly documented. The deferral was specifically to give one release of grace; this gap is the cost. |
| Auto Mode Overlay substance correctness post-promotion (the 6 principles, decision classification, $DECISION_LOG schema) | These are preserved verbatim per Big Decision #5; no substantive logic change | If a copy-paste error occurs during promotion (drops a principle, mangles a classification rule), the classification table grep + manual code review catches it. /personal-workflow check + validate.sh + test.sh sanity-check structure but not semantic preservation. Mitigation: line-range diff inspection during /review. |
| Step 8.5 carve-out behavior under `subagent_crashed` end-state (rare path) | Hard to synthesize a crash deterministically in smoke; covered by existing v1.14.0 → v1.15.1 contract that didn't change here | If the carve-out regresses (Step 8.5 fires when it shouldn't), the user sees a spurious approval gate in a crash scenario. Recoverable; non-blocking for ship. |
| Concurrent invocations of `/personal-pipeline` against the same design doc | scale=1; not a real concern | None — the user serially invokes this skill. |
| Cross-skill telemetry aggregation (e.g., does `/suggest` or `/system-health` consume the `mode` field?) | Out of scope per source design's "Out of scope" block | If a downstream consumer is found, deal with it in the v1.17.0 deletion PR. |
