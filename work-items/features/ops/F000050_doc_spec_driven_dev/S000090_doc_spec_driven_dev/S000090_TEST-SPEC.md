---
type: test-spec
parent: S000090
feature: F000050
title: "doc-spec.md doc-driven development (12-step migration + 3 retirements) — Test Specification"
version: 1
status: Draft
date: 2026-06-06
author: chjiang
spec: SPEC.md
reviewers: []
---

<!-- Scope: ENTIRE user story. Smoke + E2E together cover every SPEC P0 AC.
     Smoke = automated regression (CI/script). E2E = manual user-scenario.
     Soft cap 5 rows/tier is advisory; exceeded here with justification — the
     feature is a CI-gate + engine + retirements change whose proof requires
     several distinct automated structural checks (including the explicitly
     mandated test.sh-fixture-lockstep and planted-F000999 negative rows). -->

## Smoke Tests

<!-- Automated regression. Fast, deterministic, runnable from a script or CI.
     AC column maps each row to a SPEC acceptance criterion. -->

| # | Tag | AC | Check | What It Validates | Script/Command |
|---|-----|-----|-------|-------------------|----------------|
| S1 | integration | AC-5 | **`validate.sh` green end-to-end** | The migrated repo passes the full validator, including Checks 15/15a parsing doc-spec.md (declared ⇔ on-disk), 15b on `docs/workflow.md`, 16 on the doc-spec schema, 17 on the migrated root-docs allowlist, and the new 19 on scrubbed human-docs. Exit 0. | `bash scripts/validate.sh; echo "exit=$?"` |
| S2 | resilience | AC-6 | **`test.sh` green WITH the `zzz-test-scaffold` fixture updated in lockstep** — KNOWN BLIND SPOT (own row) | The full suite passes AND the `zzz-test-scaffold` integration fixture was edited in the SAME step as every validate.sh check change (15/15a/15b/16/17/19). This parallel-fixture edit was forgotten on F000032/F000034/F000035 — it is called out as its own mandatory regression row, not folded into S1. Exit 0. | `bash scripts/test.sh; echo "exit=$?"` (and confirm the `zzz-test-scaffold` block in `scripts/test.sh` exercises Checks 15/15a/15b/16/17/19) |
| S3 | security | AC-5 | **Planted-`F000999` negative test for new Check 19** | Check 19 ERRORs when a `[FSTD][0-9]{6}` ref is planted in a `human-doc` fixture (e.g. `docs/philosophy.md` in the scaffold fixture), and passes again once removed — proving the lint actually fires, not just defaults green. | Plant `F000999` in the human-doc fixture → `bash scripts/validate.sh` exits non-zero with a Check-19 ERROR; remove → exits 0 |
| S4 | core | AC-3, AC-4 | **No-work-item-refs in human docs (+ tracked rename)** | `grep -E '[FSTD][0-9]{6}'` over `docs/philosophy.md`, `docs/workflow.md`, `docs/architecture.md`, and `README.md` returns ZERO matches; the three docs/ files exist (lowercase, `workflow.md` singular) and no file remains under `doc/`. | `grep -rE '[FSTD][0-9]{6}' docs/philosophy.md docs/workflow.md docs/architecture.md README.md` (expect no output); `test ! -d doc && ls docs/` |
| S5 | core | AC-1 | **doc-spec.md schema parses** | `doc-spec.md` exists; its fenced ```yaml registry parses; `schema_version: 1`; every `docs[]` entry has `path`/`section`/`audit_class`; every `audit_class` ∈ {human-doc, operational}. | `bash scripts/validate.sh` Check 16 passes; manual `yaml`/`grep` parse of the registry block in `doc-spec.md` |
| S6 | core | AC-8, AC-9, AC-10 | **Grep-clean of the 3 retired surfaces** | No live references to `cj-document-release.json`, `CJ-DOC-RELEASE.md`, or `CJ_repo-init` remain in `scripts/`, `skills/`, `rules/skill-routing.md`, or `CLAUDE.md`; `cj-document-release.json` and `CJ-DOC-RELEASE.md` no longer exist; `/CJ_repo-init` has no active routing/catalog entry. | `grep -rn -e 'cj-document-release.json' -e 'CJ-DOC-RELEASE.md' -e 'CJ_repo-init' scripts/ skills/ rules/ CLAUDE.md` (expect no live refs); `test ! -e cj-document-release.json && test ! -e CJ-DOC-RELEASE.md` |

<!-- Tag vocabulary: core, resilience, observability, usability, security, integration. -->

## E2E Tests

<!-- Manual end-to-end verification, run after implementing and before /ship.
     AC column maps each row to a SPEC acceptance criterion. -->

| # | Tag | AC | Scenario | Steps (as a real user would) | Expected Outcome | Rubric |
|---|-----|-----|----------|------------------------------|------------------|--------|
| E1 | core | AC-7, AC-12 | **`/CJ_document-release` self-bootstrap + stub-scaffold in a scratch tree** | In a scratch worktree/copy: (1) delete `doc-spec.md`, run `/CJ_document-release` → observe it scaffold `doc-spec.md` from the portable Common seed + commit; (2) with doc-spec.md present, delete `docs/workflow.md`, run `/CJ_document-release` → observe it recreate a stub (title + required skeleton + `<!-- TODO: fill in -->`) + commit, audit reports `stub — needs content`; (3) re-run → no second stub (idempotent). | doc-spec.md is recreated from the seed; the missing declared doc is recreated as a TODO stub and audited `stub — needs content`; the derived doc-only whitelist (declared paths + doc-spec.md + `docs/**/*.md`) gates the auto-commit; re-run is a NO-OP. | PASS if all three sub-steps behave as described and the audit verdict + idempotency hold; FAIL on auto-generated prose (not a stub), a non-derived whitelist, or a duplicate stub on re-run. |
| E2 | usability | AC-1, AC-2, AC-3, AC-4 | **A human reads the migrated docs** | Open `doc-spec.md` and read the Common + Custom prose + registry; open `docs/philosophy.md`, `docs/workflow.md`, `docs/architecture.md`, and `README.md`. | One file (`doc-spec.md`) answers "what docs does this repo carry + what is each for"; the four human docs read as human-facing (no work-item IDs, ASCII charts present); README has folder-structure + getting-started naming the major workflows. | PASS if a human can answer "what are this repo's docs" from doc-spec.md alone AND no `[FSTD][0-9]{6}` ref is visible in any human doc; FAIL otherwise. |
| E3 | core | AC-9, AC-10, AC-11 | **The three retirements are clean end-to-end** | Try to route to `/CJ_repo-init` (confirm it is gone from `rules/skill-routing.md` + the `docs/philosophy.md` decision tree + `docs/workflow.md`); confirm `skills/CJ_repo-init/` source + its work-item history are relocated and catalog status flipped; confirm `cj-document-release.json` + `CJ-DOC-RELEASE.md` are gone and their content (whitelist → registry; contract/mechanism → docs/architecture.md + doc-spec.md) is preserved; confirm `CLAUDE.md` no longer carries the two manifests and points to doc-spec.md. | No retired surface routes or is referenced live; all relocated/absorbed content is preserved in its new home; CLAUDE.md is consistent with the new doc surfaces. | PASS if no retired surface is reachable AND no content was lost (each retired surface's content has a verified new home); FAIL on any dangling reference or lost content. |
| E4 | integration | AC-13 | **Orchestrator Step 5.5 doc-sync stays green** | During this feature's own `/cj_goal` build (or a dry-run smoke), reach Step 5.5 doc-sync, which dispatches the new doc-spec-driven `/CJ_document-release`. | Step 5.5 doc-sync completes green — no `[doc-sync-no-config]`, `[doc-sync-red]`, or `[doc-sync-non-doc-write]` halt — against the migrated repo. | PASS if doc-sync completes without a `[doc-sync-*]` halt and folds any doc updates into the same PR; FAIL on any doc-sync halt. |

<!-- If an E2E test skill exists for this feature, reference it here. None required;
     the doc-release scratch-tree scenario (E1) is run manually per the design's test plan. -->

## Coverage Gaps

<!-- What is explicitly NOT tested and why. -->

| Gap | Why Not Tested | Risk Accepted |
|-----|----------------|---------------|
| Cross-repo adoption (a non-workbench repo, e.g. the portfolio repo, actually dropping in doc-spec.md) | Out of scope for v1 — portability is designed-in + seeded but validated only in the workbench (workbench-first convention); rollout is a separate follow-up | A second repo's adoption could surface a Common-seed assumption not caught in the workbench; mitigated by the byte-identical seed + E1 self-bootstrap proof |
| Full new-repo non-doc bootstrap (replacing all of /CJ_repo-init's non-doc duties beyond lazy-create of `work-items/` + `TODOS.md`) | v1 relies on lazy-create in consuming skills; a fuller bootstrap is a noted follow-up | A brand-new repo may need a manual nudge for non-doc prerequisites until the follow-up lands |
| Behavior of every individual `/CJ_document-release` audit verdict beyond the no-ref + stub paths (e.g. nuanced `stale: <why>` requirement judgments) | The audit is advisory + agent-judged (never a hard gate per the existing convention); S3 covers the one hard lint (Check 19) | A subtle requirement-judgment miss is advisory-only and surfaces in the PR body for human review |
