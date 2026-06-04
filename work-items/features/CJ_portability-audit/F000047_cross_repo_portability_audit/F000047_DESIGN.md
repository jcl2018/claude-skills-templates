---
type: design
parent: F000047
title: "Cross-repo portability audit for delivered skills — Feature Design"
version: 1
status: Draft
date: 2026-06-04
author: chjiang
reviewers: []
---

<!-- A feature's cross-story design doc. Captures the PROBLEM, the SHAPE of
     the solution, the BIG DECISIONS with rationale, the RISKS, the
     DEFINITION OF DONE, and out-of-scope boundaries. Story-scope detail
     (SPEC/TEST-SPEC) lives on the nested user-stories. -->

## Problem

The workbench ships skills meant to run in ANY repo, but some declare
`portability: standalone` in `skills-catalog.json` while quietly depending on
repo-local artifacts a target repo will not have. Nothing today verifies the
declared `portability` field against a skill's actual dependencies. Live evidence
(grepped this session): `CJ_qa-work-item` (declared `standalone`) reaches
`scripts/test.sh`; `CJ_implement-from-spec` (`standalone`) reaches
`scripts/test.sh` + `scripts/validate.sh`; `CJ_goal_feature` / `CJ_goal_defect`
(`standalone`) reach `scripts/cj-goal-common.sh` + `scripts/cj-worktree-init.sh`;
many skills grep `CLAUDE.md` for workbench conventions.

`/CJ_repo-init` is the closest existing skill but solves the *consumer* side — it
verifies the per-repo prerequisites EXIST in a target repo (`cj-document-release.json`,
`CJ-DOC-RELEASE.md`, `TODOS.md`, `work-items/`) and scaffolds the missing ones. It
does NOT audit whether the skills themselves reach for repo-local things OUTSIDE
that prerequisite set. The gap: a skill can be "installed" everywhere and still
break at runtime in another repo because it hard-depends on a workbench file that
`/CJ_repo-init` never scaffolds.

## Shape of the solution

A new skill **`/CJ_portability-audit`** (Approach B — dedicated skill,
engine-in-script, like `/CJ_repo-init`), two layers sharing one static engine.
**Layer 1 (always-on, advisory):** a `scripts/cj-portability-audit.sh` engine
lints each catalog skill's actual repo-local dependencies against its declared
`portability` tier and emits a per-skill verdict (`portable` /
`portable-with-notes` / `findings:<list>`). The SAME engine is wired into
`validate.sh` as an advisory check (exit 0 in v1). **Layer 2 (opt-in / nightly):**
a new `scripts/eval.sh --portability` mode + fixture-prep helper that drives a real
skill via `claude --print` against a STRIPPED, `.source`-neutralized scratch repo
to prove graceful degradation.

The feature splits cleanly into two stories at the Layer boundary — which is also
the v1 / follow-up boundary:

| Concern | User-story | Artifact |
|---------|-----------|----------|
| Layer 1 static dependency lint (engine + skill + validate.sh advisory check + `portability_requires` field + docs + one local Layer-2 case) — **v1 must-ship** | S000083 | [S000083_layer1_static_dependency_lint/S000083_TRACKER.md](S000083_layer1_static_dependency_lint/S000083_TRACKER.md) |
| Layer 2 broad dynamic eval coverage + nightly CI + advisory→hard-gate hardening — **DEFERRED follow-up** | (not yet scaffolded) | Captured in this DESIGN's "Not in scope" + the ROADMAP's deferred row; scaffold as a sibling user-story when Story 1 lands. |

## Big decisions

| # | Decision | Why |
|---|----------|-----|
| 1 | Approach B (new `/CJ_portability-audit` skill, engine-in-script) | Over Approach A (script + validate.sh only — under-delivers on the "new skill" intent; not independently invokable/richly reported) and Approach C (unify with `/CJ_repo-init` — confused-dual-audience smell, biggest blast radius: rewrites shipped repo-init + tests + callers). |
| 2 | Advisory-first (exit 0 in v1), NOT a hard gate | The workbench HAS real declared-vs-actual mismatches today, so a hard gate would red-CI on merge. Mirrors the registered-doc requirements audit's "ADVISORY, agent-judged, NEVER a hard gate" posture. Hardening to `PORTABILITY_STRICT=1` is a documented Story-2 follow-up after the mismatches are reconciled. |
| 3 | Ship the optional `portability_requires` catalog field in v1 (engine honors it) | A v1 correctness prerequisite, NOT polish: without it the first run is all-red noise and the table is unusable. Mirrors the optional `doc_requirement` pattern; tolerated by validate.sh (no closed catalog schema). Workbench catalog pre-seeded with known-accepted deps so v1 lands green-by-adjudication, each dep visible + auditable. |
| 4 (premise gate D2/D3) | Layer 2 drives the REAL skill via `claude --print` against a stripped scratch repo, not just the preamble bash | Genuine coverage over a cheap preamble-only smoke. Accepts cost + flake. Honest scope: orchestrators can't run headless end-to-end (they invoke `/ship`, `/office-hours`, subagents) — real Layer-2 coverage is leaf utilities + a documented partial orchestrator run. |
| 5 (premise gate D4) | Strict tier ladder; the self-resolution preamble is a FINDING for `standalone` skills, OK-with-note for `workbench`/`local-only` | The bar is "works in a repo that has never seen this workbench." The `.source`/root-script reach-back IS a workbench dependency — for a `standalone` skill that contradicts its claim. This is the single most valuable finding class (catches the mislabeled orchestrators — the D4 headline). |
| 6 (premise gate D4) | Correct-behavior spec written verbatim into `doc/WORKFLOWS.md` | Operator-requested, for read-and-verify against the implementation. `/CJ_portability-audit` is a utility (by T000037 convention documents in `doc/ARCHITECTURE.md`), but adding a non-`CJ_goal_*` section to WORKFLOWS.md does NOT break Check 15b (it only ERRORs on a MISSING `CJ_goal_*` section). The standard ARCHITECTURE roster line + PHILOSOPHY decision-tree entry are ALSO added so the no-vanish checks pass. |
| 7 (spec review #6) | Layer-2 full reach (every runnable skill + nightly CI) split out as Story 2 | Making a green nightly Layer-2 case a v1 gate re-imports the parked-eval-harness cost/flake (D000023). v1 Layer-2 deliverable is just the `--portability` mode + fixture-prep helper running ONE leaf-skill case (`CJ_suggest`) locally green. Layer 1 is the sole v1 gate. |
| 8 | Engine is a ROOT script (`scripts/cj-portability-audit.sh`), NOT bundled under the skill dir | Bundling under `skills/CJ_portability-audit/scripts/` buys no real portability because the catalog + skill source the engine reads are not deployed either. Resolved at runtime via the manifest `.source` field, exactly like `cj-repo-init.sh` / `skills-update-check`. The skill's own declaration is `workbench` (it audits the workbench's own source tree, which exists only in the workbench clone). |

## Risks & open questions

| Risk / Question | Next check |
|-----------------|-----------|
| Advisory→hard-gate trajectory: *when* to flip the validate.sh check to hard-fail (`PORTABILITY_STRICT=1`). The mechanism is DECIDED (`portability_requires` ships in v1); only the timing is open. | Story 2 follow-up — once the workbench's declarations are fully adjudicated via `portability_requires`. |
| Graceful-degradation classifier is heuristic — detecting that a ref sits behind a `.source` fallback / presence guard is fuzzy. | v1 leans conservative (flag it; operator marks it accepted via `portability_requires`) over smart (parse the guard). Revisit if false-positive noise is high. |
| The `zzz-test-scaffold` integration edit to `scripts/test.sh` is systematically forgotten by the implement-subagent (F000032/F000034/F000035 all hit it). | Pre-flighted explicitly in S000083's SPEC + the implement prompt — every new validate.sh check needs the parallel test.sh edit. |
| Relationship to the `CJ-DOC-RELEASE.md → doc-requirements.md` rename TODO (a concrete instance of exactly what this audit flags). | Keep as separate work items; the audit MAY recommend the rename. Cross-reference, do not merge. |
| Layer 2 `.source` fall-through: inside a `git init`'d scratch tmpdir, `--show-toplevel` returns the tmpdir, so the engine falls through to `.source` pointing back at the REAL workbench — proving nothing unless redirected. | S000083's one local Layer-2 case MUST redirect resolution at a scratch `~/.claude` whose `.skills-templates.json` `.source` points at the stripped repo (or is unset). This is the crux of "stripped" actually being stripped. |

## Definition of done

- [ ] `/CJ_portability-audit` prints a per-skill portability verdict table over the Check-14/15b selector set (derived from the catalog at runtime, not hardcoded); each finding names the skill + the executed repo-local dep + why it is a risk (declared vs actual).
- [ ] The shared static-lint engine runs as a new `validate.sh` advisory check (exit 0 in v1, findings visible).
- [ ] The audit surfaces ≥1 REAL finding on a workbench skill before adjudication (proving non-no-op), then lands green via pre-seeded `portability_requires`.
- [ ] v1 ships the optional `portability_requires` catalog field + engine honoring (listed dep → OK; stale → informational note, never blocking).
- [ ] The engine has integration coverage in `scripts/test.sh` (the `zzz-test-scaffold` pattern).
- [ ] New skill documented: SKILL.md + USAGE.md (5 required H2 sections) + catalog entry + `doc/ARCHITECTURE.md` roster + `doc/PHILOSOPHY.md` decision tree.
- [ ] The strict-tier correct-behavior spec is written verbatim into `doc/WORKFLOWS.md` (tier ladder + EXECUTED-vs-documented rule + carve-outs + expected-findings table).
- [ ] First run flags the three `CJ_goal_*` orchestrators + `CJ_qa-work-item` + `CJ_implement-from-spec` as `standalone`-but-workbench-coupled (the D4 headline), then lands green via pre-seeded relabel/adjudication.
- [ ] `scripts/eval.sh --portability` mode + fixture-prep helper exist and run ONE leaf-skill case (`CJ_suggest`) locally green against a stripped + `.source`-neutralized scratch repo.

## Not in scope

- **Story 2 — Layer 2 broad dynamic coverage** — across all runnable leaf skills + orchestrator partial runs — DEFERRED. Re-imports the parked-eval-harness cost/flake (D000023); demoted from a v1 exit criterion per spec review #6.
- **Nightly-CI job wiring** in `.github/workflows/eval-nightly.yml` for the portability eval — DEFERRED to Story 2 (lean: extend the existing workflow with one cron, not a new workflow).
- **Advisory→hard-gate hardening** (`PORTABILITY_STRICT=1` flipping the validate.sh check to hard-fail) — DEFERRED to Story 2, after the workbench's declarations are reconciled.
- **Auto-fix** — the audit never auto-fixes. The operator either relabels the skill's `portability` (the honest fix for the orchestrators) or adjudicates the dep via `portability_requires`.
- **The `CJ-DOC-RELEASE.md → doc-requirements.md` rename** — a separate work item; the audit may recommend it. Cross-reference, do not merge.
- **Parsing the guard around a `.source` fallback** (smart graceful-degradation detection) — v1 stays conservative (flag-and-adjudicate).

## Pointers

<!-- Cross-links to related artifacts. -->

- Parent tracker: [F000047_TRACKER.md](F000047_TRACKER.md)
- Roadmap: [F000047_ROADMAP.md](F000047_ROADMAP.md)
- Story 1 (v1 must-ship): [S000083_layer1_static_dependency_lint/S000083_TRACKER.md](S000083_layer1_static_dependency_lint/S000083_TRACKER.md)
- Source /office-hours design: `~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-cj-feat-20260604-140945-869-design-20260604-142240.md`
- Related skill (consumer-side counterpart): `skills/CJ_repo-init/SKILL.md`
- Reused harness: `scripts/eval.sh` (Layer 2)
