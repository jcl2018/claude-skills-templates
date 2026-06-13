---
type: design
parent: F000061
title: "Three-stage audit hardening — engine-backed Stage 1, evidence-forced Stage 2, drift-hunting Stage 3, fresh-context judging, per-stage findings reports — Feature Design"
version: 1
status: Draft
date: 2026-06-12
author: chjiang
reviewers: []
---

<!-- Distilled from the APPROVED /office-hours design doc
     ~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-claude-unruffled-kalam-e25974-design-20260612-170600.md
     (Status: APPROVED, Mode: Startup). Story-scope detail (SPEC/TEST-SPEC)
     lives on the nested user-story S000103. -->

## Problem

F000060's audit skills (v6.0.65) landed with three soft spots, all surfaced by
the same-day dogfood run and the operator's follow-up question ("does it check
the actual doc items against the implementation?"):

1. **Stage 1 (deterministic) is prose-described bash, not an engine call** —
   the dogfood run reimplemented it ad hoc and hit the Bash-tool zsh
   word-split gotcha: two phantom findings and one silently VACUOUS check (the
   human-doc ID lint iterated a multi-line string as one filename and
   `|| true` swallowed the open failure). Every executor re-derives the loops;
   each derivation can rot differently.
2. **Stage 2 (requirement compliance) is judgment without forced evidence** —
   the in-run audit's verdicts leaned on "the build just updated these docs":
   resident-context rubber-stamping, exactly the bias the operator called out.
3. **Stage 3 (implementation drift) does not exist** — nothing cross-walks a
   doc's CONTENT against the live repo state (does `docs/workflow.md` mention
   every routable skill? does `docs/architecture.md`'s named machinery still
   exist on disk?). The honest answer to the operator's question was "only as
   deep as the requirement string, agent-judged, no cross-walk."

The ask (operator, 2026-06-12): harden with clean stages — (1) the existing
deterministic checks as a tested engine, (2) actually check whether each doc
follows its `requirement:`, (3) for contract docs, check the implementation /
current repo state for drift; 2 and 3 stay agent-judged but run with FRESH
context; the report prints findings PER STAGE.

## Shape of the solution

One engine subcommand + two SKILL.md restructures + the qa.md block shape +
tests, carried by ONE atomic user-story (single-story scope):

| Concern | User-story | Artifact |
|---------|-----------|----------|
| NEW `doc-spec.sh --check-on-disk` (6 deterministic checks, registry-absent probe carve-out, orphans-counts-undeclared-overlay), BOTH skills' three-stage restructure (verdict grammars incl. `missing-requirement (soft)`/`n/a`, pre-stage findings as STAGE1, skipped-stage grammar), REQUIRED fresh-context subagent dispatch standalone (+ `Agent` tool in both skills + catalog), per-stage report contract (`STAGE1/2/3_FINDINGS=` + sections + `stageN/` prefixes), qa.md AUDIT_FINDINGS per-stage template (pipelines: ZERO edits), docs sweep + TODOS convergence row, two extended test suites | S000103 | [S000103_check_on_disk_engine_and_staged_audits/S000103_TRACKER.md](S000103_check_on_disk_engine_and_staged_audits/S000103_TRACKER.md) |

The three stages: **Stage 1 (deterministic)** becomes ONE call —
`doc-spec.sh --check-on-disk` runs declared-exists / orphans / root-declared /
human-doc-ids / front-table / views-render against the MERGED registry, one
line per check + `CHECKS_RUN=`/`FINDINGS=` tail, exit 0 clean / 1 findings
(the test audit's Stage 1 is already engine calls — `test-spec.sh --validate`
+ `--check-coverage` — unchanged mechanics, `stage1/` prefixes). **Stage 2
(requirement compliance)** quotes each doc's `requirement:` string, decomposes
it into clauses, checks each clause against the doc's actual content, and
emits evidence-cited verdicts (`satisfies` / `missing-requirement (soft)` /
`n/a` / `FINDING: stage2/<path>`; only FINDING lines count; the F000060
`up-to-date`/`stale:` wording is RETIRED). **Stage 3 (implementation drift)**
enumerates ground truth FIRST (routable skills, `scripts/*.sh`, workflows,
spec-registry family, top-level dirs), then cross-walks each contract doc
against it per the doc-type playbook (`no-drift` / `FINDING: stage3/<path>` —
named delta). Standalone, Stages 2+3 are executed by ONE fresh-context
subagent (REQUIRED — D10.2) whose prompt carries ONLY repo root + engine path
+ Stage-1 report + the stage protocols; inside QA the agent executes them
inline (the nested-subagent wall — documented honestly). The report prints
`STAGE1/2/3_FINDINGS=` + three `--- stage N ---` sections; `DOC_AUDIT: ok`
requires all three counts = 0; qa.md's AUDIT_FINDINGS block adopts the same
shape with zero pipeline edits.

## Big decisions

| # | Decision | Why |
|---|----------|-----|
| 1 | D10.1 — Stage 1 becomes an engine call (`doc-spec.sh --check-on-disk`); `test-spec.sh` grows NONE | The word-split bug class is designed out (loops live in ONE tested script); consumer repos gain a real CI-able conformance check — closing the deferred follow-up already on record; the test audit's Stage 1 is already engine calls |
| 2 | D10.2 — standalone runs MUST dispatch Stages 2+3 to a fresh-context subagent; in-QA executes inline | Fresh context is what makes the verdicts earned (no resident-context rubber-stamping); a subagent cannot spawn subagents, so the in-QA degradation is documented honestly in both SKILL.mds |
| 3 | D10.3 — BOTH audits get the identical three-stage shape + per-stage report in this PR | Operator chose symmetry over the smaller doc-only diff — one format, fully enforced, never two shapes of the same thing |
| 4 | D11 — Approach A: skill-layer only; validate.sh untouched | Checks 15/17/19/20 keep their own implementations; rewiring the highest-blast-radius file in the same diff as a skill restructure is rejected; convergence onto `--check-on-disk` is a tracked TODOS row |
| 5 | Registry-absent probe BEFORE the parse gates (subcommand-local carve-out) | The list subcommands HALT on a missing registry — wrong for this caller; absent ⇒ `REGISTRY=absent` + exit 0 (the caller's seed-delivery step owns that case); present-but-invalid keeps the `[doc-sync-no-config]` exit-1 posture |
| 6 | `orphans` counts a non-self-declaring overlay file as an orphan | An overlay MUST self-declare (the workbench's does); the finding is honest guidance for a consumer repo that created one without declaring it |
| 7 | `views-render` compares TABLE BLOCKS, not whole files | View headers legitimately differ between workbench (generator header) and consumer (portable stub header); the whole-file regen-diff remains Check 23 (workbench CI), unchanged |
| 8 | Pre-stage findings count as STAGE1; skipped stages keep their section headers | Engine-unreachable / seed-failure / registry-invalid findings are deterministic (`stage1/engine`, `stage1/seed`, `stage1/registry`); unjudgeable stages print `skipped: <reason>` + `STAGE*_FINDINGS=0` — the per-stage shape never collapses on the error path |
| 9 | Report contract EXTENDS, never breaks, the F000060 shape | `DOC_AUDIT:`/`TEST_AUDIT:`, `FINDINGS=`, `DOCS_AUDITED=`/`UNITS_AUDITED=`, `seeded:` keep their meaning; stage fields + sections are additions; consumers (qa.md Step 8.6, the checkpoint AUQ) update in the same PR — pipelines need zero edits |
| 10 | Extend the two existing registered suites; no new suites | Avoids new registration; the suites' purpose text in `spec/test-spec-custom.md` updates (anchors unchanged), keeping Check 24 green |

## Risks & open questions

| Risk / Question | Next check |
|-----------------|-----------|
| The `--check-on-disk` battery's seeded violations don't isolate (one violation flips multiple check ids) | The extended `tests/doc-spec-overlay.test.sh` asserts each of the seven violations flips EXACTLY its own `FINDING: stage1/<id>` line |
| Fresh-context dispatch needs the `Agent` tool — both skills today carry only Bash/Read/Glob/Grep | Both skills' `allowed-tools` frontmatter + catalog `depends.tools` gain `Agent` in this PR (D10.2 is impossible otherwise) — verified at QA |
| architecture.md's "future `--check-on-disk` … deferred" passage (~L285–296) goes stale the moment this lands | Rewritten in the same PR to describe the shipped subcommand — otherwise this run's own Stage 2/3 dogfood flags it |
| SKILL.md edits flip Check 14 USAGE.md drift on both audit skills | USAGE.mds updated with real content in the same PR (the normal path) |
| Stage 2/3 agent verdicts vary run-to-run | Inherent — deliberately layered ABOVE the deterministic Stage-1 floor; the evidence-citation protocol makes them spot-checkable |
| Deferred: converge validate.sh Checks 15/17/19/20 onto `--check-on-disk` (Approach B) | TODOS row added in this PR; revisit after v1 lands |

## Definition of done

- [ ] `bash scripts/doc-spec.sh --check-on-disk` on the clean workbench: every check line PASS, `FINDINGS=0`, exit 0; each of the seven seeded test-battery violations flips exactly its own `FINDING: stage1/<id>` + exit 1; registry-absent ⇒ `REGISTRY=absent` + exit 0
- [ ] `/CJ_doc_audit` standalone emits the per-stage report (`STAGE1/2/3_FINDINGS=` + three sections), Stages 2+3 from a dispatched fresh-context subagent, `DOC_AUDIT: ok` only when all three counts are 0; same for `/CJ_test_audit` with `UNITS_AUDITED=`
- [ ] Stage 2 verdict lines each cite a clause + evidence (spot-checkable); Stage 3 opens with the ground-truth enumeration line and each drift finding names the delta
- [ ] A deliberately planted drift (fixture workflow doc omitting a catalog skill) produces a `FINDING: stage3/...` naming the missing skill — proven in the extended `cj-audit-skills` battery
- [ ] qa.md's AUDIT_FINDINGS template carries the per-stage shape; the four pipelines need zero edits (verified by grep)
- [ ] `./scripts/validate.sh` PASS (validate.sh untouched — Check 24 green with the updated purpose texts); `./scripts/test.sh` PASS; both audits green end-to-end on the workbench
- [ ] Catalog descriptions + `doc_requirement` + USAGE.md files current (the registered-doc audit on this run's own QA passes)

## Not in scope

- validate.sh delegation (Approach B) — rejected for this PR: highest-blast-radius file in the same diff as a skill restructure; Check-24 anchors on validate.sh banners would need re-verification; tracked as a TODOS row
- Any registry schema change or seed change — `--check-on-disk` reads the merged registry; no byte-identity churn
- `test-spec.sh` subcommands — grows NONE; the test audit's Stage 1 is already engine calls
- Checkpoint AUQ wiring — the four pipelines consume the AUDIT_FINDINGS block verbatim already; ZERO edits
- New test suites — both extended suites are already registered + wired in test.sh
- Breaking the F000060 report contract — stage fields/sections are pure additions; existing grep-able fields keep their meaning

## Pointers

- Parent tracker: [F000061_TRACKER.md](F000061_TRACKER.md)
- Roadmap: [F000061_ROADMAP.md](F000061_ROADMAP.md)
- Child story: [S000103_check_on_disk_engine_and_staged_audits/S000103_TRACKER.md](S000103_check_on_disk_engine_and_staged_audits/S000103_TRACKER.md)
- Source design doc (APPROVED, /office-hours): `~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-claude-unruffled-kalam-e25974-design-20260612-170600.md`
- Hardened machinery (dependency, landed): `work-items/features/ops/F000060_two_tier_audit_contract/` (v6.0.65 — the two audit skills, the two-tier registries, `doc-spec.sh` overlay merge, qa.md Step 8.6, the checkpoint wiring)
