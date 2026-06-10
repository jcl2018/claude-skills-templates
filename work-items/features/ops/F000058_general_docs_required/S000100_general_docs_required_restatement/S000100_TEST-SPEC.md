---
type: test-spec
parent: S000100
feature: F000058
title: "General docs required — complete contract restatement — Test Specification"
version: 1
status: Draft
date: 2026-06-09
author: chjiang
spec: SPEC.md
reviewers: []
---

<!-- Scope: ENTIRE user story. Smoke + E2E together cover every SPEC P0 AC.
     Soft cap: 5 rows per tier. -->

## Smoke Tests

<!-- Automated regression. Fast, deterministic, CI-runnable. AC maps to a SPEC #. -->

| # | Tag | AC | Check | What It Validates | Script/Command |
|---|-----|-----|-------|-------------------|----------------|
| S1 | core | AC-3 | Render row counts after the flip | `--render general` emits exactly 10 doc rows; `--render custom` emits exactly 3 (`CONTRIBUTING.md`, `spec/gate-spec.md`, `spec/permission-policy.md`) | `bash scripts/doc-spec.sh --render general; bash scripts/doc-spec.sh --render custom` |
| S2 | core | AC-2 | Seed validates + 3-way byte-identity | Seed written to a temp repo passes `--validate` with 10 entries (test 12 path); drift test 13 (heredoc == template) green; workbench Common section byte-identical to the seed prose | `bash tests/cj-document-release-config.test.sh` |
| S3 | resilience | AC-7 | Growth-safe seed assertions regress loudly | Seed `--list-declared` (via the `DOC_SPEC_PATH` temp-file idiom) includes `CLAUDE.md`, `TODOS.md`, `docs/doc-general.md`; seed output greps the literal "General docs are required"; test-5 ok-message reworded | `bash tests/cj-document-release-config.test.sh` (new assertions) |
| S4 | core | AC-1 | Contract invariants + repo checks | Registry schema validates (Check 16); declared ⇔ on-disk (15/15a/17); no work-item IDs in human-docs incl. both views (19); front tables (20); views in sync (23); exactly one ```` ```yaml ```` fence in `spec/doc-spec.md`; "what docs this repo carries" preserved; Check 14 green after the USAGE.md refresh | `./scripts/validate.sh` |
| S5 | integration | AC-7 | Full suite green, check-neutral build | `./scripts/test.sh` fully green with NO new validate.sh check and NO `scripts/test.sh` fixture edits | `./scripts/test.sh` |

<!-- Tag vocabulary: core, resilience, observability, usability, security, integration. -->

## E2E Tests

<!-- Manual end-to-end verification before /ship. One user-visible scenario per row. -->

| # | Tag | AC | Scenario | Steps (as a real user would) | Expected Outcome | Rubric |
|---|-----|-----|----------|------------------------------|------------------|--------|
| E1 | core | AC-1, AC-3 | The contract reads the new 10/3 tier split | Open `spec/doc-spec.md`; read the Common section table and the rule bullet; open `docs/doc-general.md` + `docs/doc-custom.md` | 6 entries now `section: common` (audit_class unchanged); Common table lists the 10 general docs sub-grouped (human / operational / generated views (human docs)) with the "General docs are required." bullet; general view = 10 rows incl. both views; custom view = exactly the 3 custom docs | PASS iff entry count + identity match exactly AND the rule bullet is present |
| E2 | core | AC-2 | The portable seed is whole and self-consistent | Run `bash scripts/doc-spec.sh --seed > $T/doc-spec.md`; run `DOC_SPEC_PATH=$T/doc-spec.md bash scripts/doc-spec.sh --validate` and `--render general`; `diff` the seed prose against `templates/doc-spec-common.md` and the workbench Common section | Seed validates (schema_version 1); render lists 10 root-style entries with portable requirement strings (doc-spec.md entry includes "registry declares every general-contract doc"); all three prose copies byte-identical; diagram-line drift gone | PASS iff validate OK + 10 portable entries + 3-way byte-identity |
| E3 | core | AC-4 | The skill states the tier logic and audits the gap honestly | Open `skills/CJ_document-release/SKILL.md`; locate the tier-logic statement and the Step 6.7 advisory rule; verify the enumeration idiom, basename equivalence, the `stale: registry missing general-contract doc(s): <paths>` verdict shape, the portable render-first stub shape for the views, and the TODOS dual-creation note; confirm USAGE.md is fresh | Statement present (general = REQUIRED + stub-scaffolded; custom = per-repo); advisory rule complete and explicitly never-a-halt; stub header names no workbench-only paths; Check 14 green | PASS iff all five elements present AND posture is advisory |
| E4 | usability | AC-5 | Philosophy states required-ness in the right home | Open `docs/philosophy.md`; read `## Topic: Doc contract` → `### Two tiers, one portable pass` | The principle states the general tier is required in every adopting repo and the custom tier is per-repo; no new principle; front summary table unchanged; no work-item IDs | PASS iff required-ness stated in the amended principle with Checks 19/20 green |
| E5 | integration | AC-6 | No live doc contradicts the new tier split | Run the sweep grep: `grep -rn "four human docs\|four common human docs\|section: custom" --include='*.md' . \| grep -v "CHANGELOG.md\|work-items/\|\.cj-goal"`; inspect each hit | Remaining hits are only legitimate registry-SCHEMA mentions (seed Custom placeholder, doc-custom.md generated header, architecture.md schema comment) or generated-view content; CLAUDE.md's root-`*.md` line reads the reconciled wording; no live "four human docs" claim survives | PASS iff every remaining hit is classified legitimate |

## Coverage Gaps

<!-- What is explicitly NOT tested and why. -->

| Gap | Why Not Tested | Risk Accepted |
|-----|----------------|---------------|
| Consumer-repo behavior of the Step 6.7 advisory rule (no catalog, root-style registry) | No consumer fixture repo in this suite; the enumeration + basename-equivalence logic is verified by inspection (E3) and exercised by the workbench's own run | A consumer-only edge (e.g. odd registry path) could mis-verdict — advisory only, never halts |
| Stub-scaffold render-fallback path (when `--render` fails) | Hard to force a render failure deterministically without mutating the deployed helper | A failed render falls back to a plain stub that is immediately `stale:`-flagged — self-surfacing |
| Approach C hard enforcement | Deliberately out of scope (Premise 3) | A repo can still hand-delete a general doc; Check 15/17 + stub-scaffold + the advisory line catch it on the next pass |
