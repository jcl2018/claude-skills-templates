---
type: design
parent: S000130
title: "Delete agentic cron wrappers + re-layer the 3 tests to local-hook + prose sweep — Feature Design"
version: 1
status: Draft
date: 2026-07-03
author: Charlie Jiang
reviewers: []
---

<!-- Atomic user-story design. Derives from the parent feature's /office-hours
     session; sections are brief and link to the parent for full context. -->

## Problem

`CI-nightly` runs three unattended agentic (model-spending) tests on a cron
(`goal-task-eval`, `goal-feature-eval` via `eval-nightly.yml`; `doc-sync` via
`audit-nightly.yml`). The operator wants no unattended/scheduled model spend. This
story delivers the concrete file changes that make `CI-nightly` deterministic-only.
See parent [F000080_DESIGN.md](../F000080_DESIGN.md) for the full problem framing.

## Shape of the solution

A single coordinated edit (the 7-part file set): (1) delete the two `.yml` cron
wrappers; (2) re-layer the 3 `categories:` rows `CI-nightly` → `local-hook` in
`spec/test-spec-custom.md` and remove the `ci-eval-nightly` / `ci-audit-nightly`
units; (3) `git mv` the 3 front-door docs into `docs/tests/workflow/local-hook/` and
reframe each `## How to run`; (4) move the 3 `docs/tests/index.md` INDEX rows; (5)
update `spec/doc-spec-custom.md`'s 3 declaration paths; (6) sweep "nightly in CI via
audit-nightly.yml" → "on-demand locally" across CLAUDE.md, docs, workflow-spec, and
the `CJ_goal_*` / `CJ_qa-work-item` / `CJ_doc_audit` skill files; (7) regenerate the
catalogs + validate. It must land atomically so `validate.sh`/`test.sh` stay green.

## Big decisions

- **Delete outright (Approach A), not neuter (B) or add a heartbeat (C).** A dormant-
  but-referenced workflow is the exact half-truth this change removes the auto-catch
  for; a deterministic nightly is near-redundant with the per-PR gate. Reversibility =
  git revert. See parent DESIGN Big decisions.
- **Keep the scripts + the `test-audit-nightly` test.** Only the `.yml` cron wrappers
  are deleted; `scripts/eval.sh` + `scripts/audit-nightly.sh` become on-demand/local
  runners, and `test-audit-nightly` (anchored on the script) stays green.
- **Keep `mode: agentic` + `tier: paid` on the re-layered rows.** They still spend
  tokens when run; only the layer changes.

## Risks & open questions

- Semantic prose drift loses its automatic nightly catch (accepted "for now"; interim
  net = hand-run `scripts/audit-nightly.sh` / `/CJ_doc_audit` + `/CJ_test_audit`).
- Prose-sweep breadth across many `CJ_goal_*` files — default is the full sweep; split
  a ballooning single-file rewrite to a follow-up TODO only if it threatens the PR.
- A lingering deleted-source unit would fail Check 24 — remove both units in the same
  edit as the `.yml` deletion. Next check: `validate.sh` Checks 15/15a/24 + `--check-structure` at QA.

## Definition of done

- [ ] The two cron wrappers are gone; only `windows-nightly.yml` remains scheduled.
- [ ] `test-spec-custom.md` + `doc-spec-custom.md` + `docs/tests/index.md` + the moved docs all agree on `local-hook`; `ci-eval-nightly` / `ci-audit-nightly` units removed.
- [ ] No text claims a nightly-CI eval/audit that no longer runs.
- [ ] `validate.sh` + `test.sh` GREEN; `--check-structure` findings=0; Check 28 passes (orchestrators=4, behaviors=4).

## Not in scope

- Deleting/rewriting `scripts/eval.sh` / `scripts/audit-nightly.sh` — KEPT.
- Removing `test-audit-nightly` — STAYS (anchored on the script).
- Adding a deterministic nightly heartbeat (Approach C) — rejected.
- Changing the per-PR deterministic gate — UNCHANGED.

## Pointers

- Parent design: [F000080_DESIGN.md](../F000080_DESIGN.md)
- Parent tracker: [F000080_TRACKER.md](../F000080_TRACKER.md)
- This story's spec: [S000130_SPEC.md](S000130_SPEC.md)
- This story's test-spec: [S000130_TEST-SPEC.md](S000130_TEST-SPEC.md)
- Source design doc: `~/.gstack/projects/jcl2018-claude-skills-templates/chang-claude-vigorous-volhard-9dcadc-design-20260703-210510.md`
