---
type: design
parent: F000075
title: "Split CI into push/nightly cadence categories; move slow Windows suite to nightly — Feature Design"
version: 1
status: Draft
date: 2026-07-03
author: chang
reviewers: []
---

<!-- A feature's cross-story design doc. Captures the PROBLEM, the SHAPE of
     the solution, the BIG DECISIONS with rationale, the RISKS, the
     DEFINITION OF DONE, and out-of-scope boundaries. Story-scope detail
     (SPEC/TEST-SPEC) lives on the nested user-stories — do
     not duplicate it here. -->

## Problem

The workbench CI has one PR-gating cost the maintainer feels on every push: the
`windows-latest` Git Bash job (`.github/workflows/windows.yml`) runs on every
`pull_request` AND every `push` to `main`, spinning up a slow Windows runner to
run `windows-smoke.sh` AND the full `test-deploy.sh` skills-deploy suite. It is
too long to gate every PR.

At the same time, the category-based test contract (F000074 — the `categories:`
axis in `spec/test-spec-custom.md`, taxonomy `{workflow, CI}`) has no notion of
*when* a test runs. So the two skills that consume that contract —
`/CJ_test_audit` (is it wired?) and `/CJ_test_run` (does it pass?) — cannot
express or act on "runs on every push" vs "runs nightly." The fix is two
coordinated halves: a real CI change that moves the slow Windows work off the PR
path onto a nightly schedule while keeping a fast Windows signal at PR time, and
a contract change that teaches the category taxonomy a push-vs-nightly cadence so
the split is first-class, auditable, and locally runnable.

## Shape of the solution

Bump the portable category taxonomy from V1 `{workflow, CI}` to V2
`{workflow, CI-push, CI-nightly}`, where the category name IS the cadence:
`workflow` (unchanged) proves a whole workflow runs; `CI-push` is the deploy-gate
tests that run on every push/PR (`validate`, `suite`, `test-deploy`, `windows`);
`CI-nightly` is the deploy-gate tests that run nightly (a new `windows-deploy`
test = `test-deploy.sh` on `windows-latest`). Because the category name carries
the cadence, `--category CI-push` / `--category CI-nightly` is the whole
selection API — no new flag. The work spans eight deliverables (portable seed +
parser, contract overlay rows, folders + docs + the doc-spec registry, the
runner, the two real CI workflows, the two cj_test skills, tests, and convention
docs) that together form one coherent feature, carried by a single user-story.

| Concern | User-story | Artifact |
|---------|-----------|----------|
| Taxonomy V2 bump + parser/runner + contract rows + folders/docs + both CI workflows + both cj_test skills + tests | S000125 | [S000125_ci_cadence_taxonomy_split/S000125_TRACKER.md](S000125_ci_cadence_taxonomy_split/S000125_TRACKER.md) |

## Big decisions

<!-- Choices that shape the feature, with rationale. -->

| # | Decision | Why |
|---|----------|-----|
| 1 | Change the real `.github/workflows/windows.yml`, not just the contract | Operator rejected "contract only"; the slow Windows work must actually move off the PR path, not merely be described. |
| 2 | Keep a fast Windows check on PRs (`windows-smoke.sh`); move only the slow `test-deploy.sh`-on-`windows-latest` run to nightly | Protects the per-PR Windows signal. Accepted tradeoff: a PR still pays a smaller `windows-latest` spin-up; native-Windows `test-deploy` regressions surface nightly, not at PR time (per-PR POSIX coverage of `windows-smoke.sh` via `test.sh` on ubuntu is unchanged). |
| 3 | Model the split by expanding the category taxonomy, not an orthogonal `cadence:` field | Cadence IS the category, so `--category` is the selection mechanism with no new flag. This is effectively V2 of the PORTABLE taxonomy, inherited by any consumer repo through the seed. |
| 4 | `--check-structure` folder checks (b/c/d) DERIVE from the distinct declared categories, not a hardcoded three-set | Naively hardcoding three categories would FORCE a mandatory (often empty) `tests/CI-nightly/` on THIS repo AND every consumer that upgrades the seed — even one declaring no nightly test. Deriving from declared rows keeps the V2 bump from silently red-ing every consumer's `--check-structure`. |
| 5 | The `spec/doc-spec-custom.md` registry rewrite lands in the implementation commit, NOT Step 5.5 doc-sync | The `docs/tests/{workflow,CI}/*.md` rows are doc-CONTRACT (registry) entries; skipping/deferring the rewrite orphans the declared rows and leaves the new on-disk docs undeclared → `validate.sh` Check 15/15a HARD fail. |
| 6 | Keep `test-deploy` (ubuntu/push) AND `windows-deploy` (nightly) as two rows | Same script, two distinct CI contexts (platform + cadence); two rows read clearest. The two per-test docs must explain WHY the identical command appears twice; a `platform:` field is the deferred refinement that would let `windows-deploy` self-skip off Windows. |

## Risks & open questions

<!-- What could go wrong, and what's still undecided. -->

| Risk / Question | Next check |
|-----------------|-----------|
| Editing the taxonomy in only ONE of the two byte-identical copies breaks `tests/test-spec.test.sh`'s `cmp -s` seed==file assertion | Implement — edit `spec/test-spec.md` and the `scripts/test-spec.sh --seed` heredoc in lockstep; keep the byte-identity assertion green. |
| Missing a category-enum site in `scripts/test-spec.sh` (there are several: parser `--validate` enum + three `--check-structure` loops) leaves stale V1 behavior | Implement — enumerate and update EVERY category-enum site, not one place; the design lists the specific line regions. |
| Case-insensitive-FS trap: renaming the lowercase `docs/tests/ci.md` (the `ci` FAMILY render, units axis) alongside the `CI` category dir would corrupt an unrelated surface | Implement — rename only the `docs/tests/CI/` category dir; leave `docs/tests/ci.md` untouched. |
| `--category CI-nightly` runs `test-deploy.sh` on the LOCAL platform locally, not a real `windows-latest` run (no `platform:` field on the axis) | Accepted — the value is intent-declaration + audit cross-check; `platform:` is a deferred follow-up. The two per-test docs must explain the redundant-local-command reason. |
| Does `goal-task-eval` (the nightly eval) move to `CI-nightly`? | Recommend NO — it is a `workflow`-kind test; its nightly scheduling lives in `eval-nightly.yml` + its `paid` tier. `CI-nightly` stays focused on the newly-nightly'd Windows deploy suite. |
| Backward-compat alias for `CI`? | Recommend NO — the workbench is the only real consumer; a hard rename is cleaner than a deprecated alias. Flag if a consumer repo is known to declare `category: CI`. |

## Definition of done

<!-- Objective, measurable criteria for "shipped." -->

- [ ] `test-spec.sh --validate` passes with the V2 taxonomy; `--seed` stays byte-identical to `spec/test-spec.md`.
- [ ] `test-spec.sh --list-categories` shows `CI-push` + `CI-nightly` rows.
- [ ] `test-spec.sh --check-structure` reports against the new folder/category set, deriving folders from declared categories.
- [ ] `test-run.sh --category CI-push` and `--category CI-nightly` select correctly (verified via `--dry-run` plan).
- [ ] `validate.sh` green — esp. Check 15/15a (after the `spec/doc-spec-custom.md` rewrite) and Checks 24/26/28; full `test.sh` green; shellcheck clean.
- [ ] `windows.yml` runs only `windows-smoke.sh` on PR; `windows-nightly.yml` runs `test-deploy.sh` on `windows-latest` on schedule + dispatch.
- [ ] Both cj_test skills' SKILL.md + USAGE.md document the cadence categories.
- [ ] `CLAUDE.md` taxonomy + Windows-CI references updated (via doc-sync).

## Not in scope

<!-- Explicit non-goals. -->

- Physical relocation of test scripts into `tests/<category>/` — deferred by F000074 and remains deferred here; this feature changes the taxonomy/contract/checks/docs/workflows, not the on-disk location of test scripts.
- A `platform:` field on the `categories:` axis — the deferred refinement that would let `windows-deploy` self-skip off Windows; without it, `--category CI-nightly` runs the identical command on the local platform.
- Moving `goal-task-eval` (or any `workflow`-kind test) into `CI-nightly` — cadence does not subsume kind in V1/V2.
- A backward-compat `CI` alias — the rename is hard; no deprecated alias is added.
- Any upstream gstack edits — all changes are workbench-owned.

## Pointers

<!-- Cross-links to related artifacts. -->

- Parent tracker: [F000075_TRACKER.md](F000075_TRACKER.md)
- Roadmap: [F000075_ROADMAP.md](F000075_ROADMAP.md)
- Child story: [S000125_ci_cadence_taxonomy_split/S000125_TRACKER.md](S000125_ci_cadence_taxonomy_split/S000125_TRACKER.md)
- Source /office-hours design: `~/.gstack/projects/jcl2018-claude-skills-templates/chang-claude-eloquent-cohen-54b476-design-20260702-235650.md`
- Extends: `work-items/features/ops/F000074_category_test_contract_v1/` (the category contract V1 this bumps to V2)
- Coordinates with: `work-items/features/ops/F000044_windows_wsl2_git_bash_support/` (Windows support) and `work-items/features/ops/F000072_cj_test_run_execute_test_contract/` (the `runners:` executor)
