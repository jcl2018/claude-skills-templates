---
type: test-spec
parent: S000082
feature: F000046
title: "CJ-DOC-RELEASE.md contract doc + /CJ_repo-init 4th prereq — Test Specification"
version: 1
status: Draft
date: 2026-06-04
author: chjiang
spec: SPEC.md
reviewers: []
---

<!-- Scope: ENTIRE user story. Smoke + E2E together cover every SPEC P0 AC.
     Smoke = automated regression (CI / scripts). E2E = manual user-scenario
     verification before /ship. Soft cap 5 rows/tier. -->

## Smoke Tests

<!-- Automated regression. Fast, deterministic, script/CI-runnable.
     AC column maps each row to a SPEC acceptance criterion. -->

| # | Tag | AC | Check | What It Validates | Script/Command |
|---|-----|-----|-------|-------------------|----------------|
| S1 | core | AC-3, AC-4 | `tests/cj-repo-init.test.sh` new-prereq case + updated literal `GAPS` counts (S1/S4 3→4; S3 post-`--fix` `GAPS=0`) all green | The 4th prereq is detected as a gap, seeded by `--fix`, reported `ok` when present, and `invalid` when headingless; the count assertions reflect 4 prereqs | `bash tests/cj-repo-init.test.sh` |
| S2 | core | AC-6 | `validate.sh` Check 17 passes with `CJ-DOC-RELEASE.md` allowlisted | The new root doc is allowlisted (no orphan ERROR), and no `#`-leading line was introduced into the `### Tracked root docs allowlist` block | `./scripts/validate.sh` |
| S3 | resilience | AC-7, AC-2 | The Step 6.7 awk (extracted from `skills/CJ_document-release/SKILL.md`) over the slimmed `CLAUDE.md` yields exactly 3 tracked-doc/ manifest entries | The CARVE-OUT held: slimming the prose did not move/empty `### Tracked doc/ files manifest`; no verdict silently vanished | `awk`-over-`CLAUDE.md` extraction (Step 6.7 logic) → assert 3 entries (PHILOSOPHY/ARCHITECTURE/WORKFLOWS) |
| S4 | integration | AC-5 | Full suite green incl. catalog/README-regen non-drift (`CJ_repo-init` catalog description matches SKILL frontmatter; USAGE Check 14 satisfied) | The skill-facing surfaces all read "4" and `generate-readme.sh` won't drift; USAGE not flagged stale | `./scripts/test.sh` |
| S5 | core | AC-2 | `git diff` shows the CLAUDE.md CARVE-OUT blocks (`### Tracked doc/ files manifest`, per-entry `requirement:` strings, `### Reporting`, the two heading anchors) byte-for-byte unchanged | No accidental edit to the machine-parsed blocks / SKILL.md prose anchors | `git diff -- CLAUDE.md` (review the carve-out line ranges show no change) |

<!-- Tag vocabulary: core, resilience, observability, usability, security, integration. -->

## E2E Tests

<!-- Manual end-to-end verification, run after implementing and before /ship.
     Drive it as a real operator would. AC column maps to a SPEC AC. -->

| # | Tag | AC | Scenario | Steps (as a real user would) | Expected Outcome | Rubric |
|---|-----|-----|----------|------------------------------|------------------|--------|
| E1 | integration | AC-3 | Fresh-repo `/CJ_repo-init` seeds the 4th prereq | In a scratch dir with CJ_ skills deployed and no `CJ-DOC-RELEASE.md`: run `./scripts/cj-repo-init.sh` (observe the gap row), then `./scripts/cj-repo-init.sh --fix`, then re-run | First run lists `CJ-DOC-RELEASE.md` as a missing prereq (REPO_GAP, non-zero exit); `--fix` writes a generic portable starter; re-run reports it `ok` (clean, exit 0) | Pass = gap shown → seeded → ok on re-run; Fail = not detected, or seed leaves it still-gapped, or re-run not idempotent |
| E2 | resilience | AC-3 | Present-but-invalid doc is NOT overwritten | In a scratch dir, create a `CJ-DOC-RELEASE.md` missing the required headings; run `./scripts/cj-repo-init.sh --fix` | Reports `invalid`, prints a `NOTE:`, and leaves the existing file untouched (byte-for-byte) | Pass = `invalid` + `NOTE:` + file unchanged; Fail = silent overwrite, or reported `ok`, or `--fix` clobbers it |
| E3 | usability | AC-1 | The doc reads as a usable canonical contract | Open `CJ-DOC-RELEASE.md` and read it cold (as a new adopter) | The wrapper flow (halt-on-red, doc-only auto-commit whitelist gate), the `cj-document-release.json` schema reference, the registered-doc audit, and the declaration-site index are all present and coherent — no need to consult CLAUDE.md to understand the contract | Pass = a reader can run `/CJ_document-release` from this doc alone; Fail = key contract element missing or only resolvable from CLAUDE.md |
| E4 | usability | AC-2 | Dogfood: workbench's own `/CJ_repo-init` shows the doc present | Run `./scripts/cj-repo-init.sh` in this repo (which ships its own `CJ-DOC-RELEASE.md`) | The health table shows the new prereq as present/ok; the slimmed CLAUDE.md sections point at the new doc as the canonical read | Pass = in-repo run reports the 4th prereq ok and CLAUDE.md points at it; Fail = reported missing/invalid in-repo, or prose still self-contained |

<!-- No dedicated E2E test skill for this feature. -->

## Coverage Gaps

<!-- What is explicitly NOT tested and why. -->

| Gap | Why Not Tested | Risk Accepted |
|-----|----------------|---------------|
| `cj-document-release-config.sh` parser behavior + `validate.sh` Check 16 | Out of scope — unchanged by this story (Approach A leaves them untouched); their existing tests still run in `test.sh` | If a change accidentally touched the parser/Check 16, the full `test.sh` suite (S4) would catch it |
| The optional `/CJ_document-release` SKILL.md pointer (P1 #8) end-to-end | P1, prose-only, conditional; the CARVE-OUT guard (S3) already proves the Step 6.7 awk/anchors are unchanged | A thin prose pointer carries no behavioral risk; if added and USAGE not bumped, Check 14 (S4) flags it |
| `rules/skill-routing.md` enumeration (P1 #9) | Conditional (verify-first) — only edited if the enumeration exists; no behavioral surface | If edited inconsistently, it is a deployed-rules doc-only drift, caught on next `skills-deploy`/review, not a runtime failure |
| Cross-repo adoption (a different repo adding the prereq) | Workbench-only scope; the generic portable `seed_docguide` heredoc is exercised by E1/E2 in a scratch dir | A non-workbench repo seeding the starter is the same code path E1 exercises |
