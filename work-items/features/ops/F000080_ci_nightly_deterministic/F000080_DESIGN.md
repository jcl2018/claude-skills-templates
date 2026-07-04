---
type: design
parent: F000080
title: "Make CI-nightly deterministic — delete the agentic evals + doc-sync audit, re-layer to local-hook — Feature Design"
version: 1
status: Draft
date: 2026-07-03
author: Charlie Jiang
reviewers: []
---

<!-- A feature's cross-story design doc. Captures the PROBLEM, the SHAPE of
     the solution, the BIG DECISIONS with rationale, the RISKS, the
     DEFINITION OF DONE, and out-of-scope boundaries. Story-scope detail
     (SPEC/TEST-SPEC) lives on the nested user-stories — do
     not duplicate it here. -->

## Problem

The `CI-nightly` verification layer currently carries THREE agentic (model-spending)
tests that run **unattended** in GitHub Actions on a cron schedule:

1. `goal-task-eval` — `bash scripts/eval.sh CJ_goal_task` (via `.github/workflows/eval-nightly.yml`, cron `17 9 * * *`)
2. `goal-feature-eval` — `bash scripts/eval.sh CJ_goal_feature` (same workflow)
3. `doc-sync` — `bash scripts/audit-nightly.sh` (via `.github/workflows/audit-nightly.yml`, cron `37 9 * * *`)

The operator wants `CI-nightly` to be **deterministic-only for now** — no unattended
model spend on a schedule. After this change the `CI-nightly` cadence runs ONLY the
deterministic `portability-deploy` test (`windows-nightly.yml`, KEEP). The agentic
proofs don't disappear; they re-layer to `local-hook` and run on-demand, joining
`e2e-local` (the already-established agentic local-hook workflow test).

## Shape of the solution

Approach A (delete + manual-local safety net): delete both `.yml` cron wrappers
outright, remove their `ci-eval-nightly` / `ci-audit-nightly` units, re-layer the 3
tests from `CI-nightly` → `local-hook`, move their front-door docs, and do a full
honest prose sweep ("nightly in CI via audit-nightly.yml" → "on-demand locally") so
no doc claims a nightly job that no longer exists. The whole change is a single
user-story (a coherent 7-part file set); it decomposes into one child that carries
the delivery.

| Concern | User-story | Artifact |
|---------|-----------|----------|
| Delete the two agentic cron wrappers, re-layer the 3 tests to `local-hook`, sweep the prose, regenerate + validate | S000130 | [S000130_delete_agentic_nightly_re_layer_local_hook/S000130_TRACKER.md](S000130_delete_agentic_nightly_re_layer_local_hook/S000130_TRACKER.md) |

## Big decisions

<!-- Choices that shape the feature, with rationale. Future readers need
     to know why this path over the rejected alternatives. -->

| # | Decision | Why |
|---|----------|-----|
| 1 | Delete both cron wrappers outright (Approach A) rather than neuter them (B — keep `workflow_dispatch`, drop `schedule:`) | A is the most truthful end-state; a dormant-but-referenced workflow (B) is exactly the semantic half-truth this change removes the auto-catch for. Reversibility = git revert. |
| 2 | Do NOT add a deterministic model-free nightly heartbeat (Approach C) | Highest ongoing surface for lowest marginal value — those checks already gate every PR, and main only advances via passing PRs, so a deterministic nightly rarely catches anything new. |
| 3 | KEEP `scripts/eval.sh` + `scripts/audit-nightly.sh` + the `test-audit-nightly` regression test | Only the two `.yml` cron wrappers are deleted; the scripts become on-demand/local runners. The `test-audit-nightly` test is anchored on the script, not the workflow, so it stays green. |
| 4 | Re-layer `CI-nightly` → `local-hook` for the 3 agentic tests; keep `mode: agentic` + `tier: paid` | They still spend tokens when run; only the layer (cadence/place) changes. `portability-deploy` stays the lone deterministic `CI-nightly` test. |
| 5 | Do the full prose sweep in the SAME PR | Removing the nightly job that auto-catches semantic prose drift means the docs must be made truthful in the same change — otherwise the docs claim a job that no longer exists and nothing catches it. |

## Risks & open questions

<!-- What could go wrong, and what's still undecided. Each row should
     have a "Next check" naming who/when resolves it — otherwise it
     will rot. -->

| Risk / Question | Next check |
|-----------------|-----------|
| Semantic prose freshness loses its automatic nightly catch (accepted "for now") | Operator runs `bash scripts/audit-nightly.sh` (or `/CJ_doc_audit` + `/CJ_test_audit`) by hand as the interim safety net; run once before merge per the design's assignment. |
| Prose-sweep breadth: "runs nightly in CI via audit-nightly.yml" appears in many `CJ_goal_*` SKILL.md/pipeline.md/USAGE.md files | Default: do the full sweep for truthfulness. If any single file's rewrite balloons the diff, split that sub-item to a follow-up TODO rather than block the PR — resolved during S000130 implement. |
| A lingering `ci-eval-nightly` / `ci-audit-nightly` unit whose `source:` file is deleted would fail Check 24's forward anchor-grep + is an orphan | Remove both units in the same edit that deletes the `.yml` files; `test-spec.sh --check-coverage` + `validate.sh` Check 24 confirm at QA. |
| Declared doc path must match on-disk after the `git mv` or Check 15/15a fails | Update `spec/doc-spec-custom.md`'s 3 declaration rows + `docs/tests/index.md` in the same change; `validate.sh` Checks 15/15a confirm. |

## Definition of done

<!-- Objective, measurable criteria for "shipped." Not aspirations. A
     reviewer should be able to verify each item without asking the
     author. -->

- [ ] `.github/workflows/eval-nightly.yml` and `audit-nightly.yml` no longer exist; the only scheduled workflow is `windows-nightly.yml`.
- [ ] `spec/test-spec-custom.md` declares `goal-task-eval` / `goal-feature-eval` / `doc-sync` at `layer: local-hook`; `ci-eval-nightly` / `ci-audit-nightly` units are gone.
- [ ] The 3 front-door docs live under `docs/tests/workflow/local-hook/`; `docs/tests/index.md` + `spec/doc-spec-custom.md` agree with disk.
- [ ] No doc/spec/skill text claims a nightly-CI audit or eval that no longer runs.
- [ ] `./scripts/validate.sh` and `./scripts/test.sh` GREEN; `test-spec.sh --check-structure` findings=0; Check 28 still passes (orchestrators=4, behaviors=4).

## Not in scope

<!-- Explicit non-goals. Prevents scope creep and gives reviewers an
     unambiguous boundary. -->

- Deleting or rewriting `scripts/eval.sh` / `scripts/audit-nightly.sh` — they are KEPT as on-demand/local runners; only the cron wrappers go.
- Removing the `test-audit-nightly` regression test (`tests/audit-nightly.test.sh`) — it is anchored on the script and STAYS.
- Adding a new model-free deterministic nightly heartbeat (Approach C) — deliberately rejected.
- Re-enabling an agentic (or split doc/test) nightly — a possible future follow-up TODO, not part of this PR.
- Rewriting historical CHANGELOG lines that merely record past work — only the new release entry is added (via `/ship`).
- Any change to the per-PR deterministic gate (`validate.sh` / `validate.yml` / the pre-commit hook) — it is UNCHANGED and still blocks a broken contract on every PR.

## Pointers

<!-- Cross-links to related artifacts: parent tracker, roadmap,
     upstream sources, related features/defects. Use relative paths
     from the feature directory. -->

- Parent tracker: [F000080_TRACKER.md](F000080_TRACKER.md)
- Roadmap: [F000080_ROADMAP.md](F000080_ROADMAP.md)
- Child story: [S000130_delete_agentic_nightly_re_layer_local_hook/S000130_TRACKER.md](S000130_delete_agentic_nightly_re_layer_local_hook/S000130_TRACKER.md)
- Source design doc: `~/.gstack/projects/jcl2018-claude-skills-templates/chang-claude-vigorous-volhard-9dcadc-design-20260703-210510.md`
- Builds on: F000078 (two-axis category × layer contract), F000076 (audit deferral), F000079 (sync deferral), F000075 (CI-push/nightly cadence split).
