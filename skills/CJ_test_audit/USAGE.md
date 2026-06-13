---
skill: CJ_test_audit
last-updated: "2026-06-12T00:00:00Z"
---

# Using /CJ_test_audit

## When to use

- You want one keystroke that answers "are this repo's tests aligned with its
  test contract?" — in the workbench OR any consumer repo — with verdicts
  that are EARNED: the deterministic engine floor, evidence-cited rule/unit
  judgments, and a drift pass over the live verification surfaces.
- You are adopting the test contract in a fresh repo: the first run creates
  `spec/` and seed-delivers `spec/test-spec.md` (`seeded: yes`) — the portable
  5-rule general contract, with the coverage cross-check honestly reported as
  inactive until the repo declares `units:` rows.
- Inside `/CJ_qa-work-item` Step 8.6d (a cj_goal run): the QA agent executes
  ALL THREE STAGES inline (the nested-subagent wall) and lifts the per-stage
  report into the QA RESULT's `AUDITS=` field for the post-QA checkpoint.
- After adding/renaming tests or validator checks: Stage 1's coverage
  cross-check catches orphaned units rows, unregistered test files (the
  silent-skip class), and extraction-grammar rot; Stage 2 catches a unit
  whose `purpose` text no longer tells the truth about its source (the anchor
  can still grep while the description rots); Stage 3 catches a surface class
  the contract never contemplated.

## When NOT to use

- As the test RUNNER — `./scripts/test.sh` (or the repo's declared runner)
  runs the suite; this skill audits the suite's alignment with its contract.
- To edit the contract itself — add `units:` rows to
  `spec/test-spec-custom.md` (never to the general file) when QA Step 8.6a or
  a manual change adds test surfaces; the audit verifies, it does not author.
- In a non-git directory (the skill refuses).
- To audit docs — that is `/CJ_doc_audit`, the symmetric verb.

## Mental model

Three stages, symmetric with `/CJ_doc_audit` (one shape, both audits).
**Stage 1 (deterministic — engine, unchanged mechanics):** the existing
`test-spec.sh --validate` + `--check-coverage` calls — forward anchors,
reverse sweep, token floor — mechanize `units-anchored` / `single-owner` /
`tests-discoverable` wherever units exist, and report "coverage cross-check
inactive" by name where they don't; findings carry the `stage1/` prefix.
**Stage 2 (requirement compliance — agent-judged, evidence-forced):** each
general RULE's `statement` is quoted and judged with cited evidence
(`suite-green` names the freshest full-suite run; `new-code-tested` names the
diff-vs-units comparison), AND each overlay UNIT's `purpose`/`label` is
judged for truthfulness against the source at its anchor. **Stage 3
(implementation drift — agent-judged):** the live verification surfaces
(tests on disk, validate banners, workflows, hooks) are enumerated first,
then coverage-in-substance is judged — where Stage 1 proves a mapping EXISTS,
Stage 3 judges whether it is still TRUE, and a NEW surface class the rules
don't contemplate is drift.

Standalone, Stages 2+3 are REQUIRED to run in ONE fresh-context subagent
(prompt = repo root + engine path + Stage-1 report + protocols only; when
both audits run together the same subagent may judge both). The report prints
findings PER STAGE (`STAGE1/2/3_FINDINGS=` + `UNITS_AUDITED=` + three
`--- stage N ---` sections); findings never crash or halt — in a cj_goal run
the operator decides at the post-QA checkpoint.

## Common pitfalls

- **Expecting the audit to halt a pipeline.** It never does. QA findings ride
  a GREEN RESULT; the orchestrator's checkpoint AUQ owns the Continue/Halt
  decision (waivers journal as `[qa-audit-waived]`).
- **Reading the "coverage cross-check inactive" note as a failure.** It is the
  honest rules-only state of a seeded consumer repo — declare `units:` rows in
  `spec/test-spec-custom.md` to activate the deterministic checks.
- **Adding a test file without a `units:` row.** In this workbench that flips
  the reverse sweep (and validate.sh Check 24) red — the row's `source` must
  be `scripts/test.sh` (the runner), never the test file itself (the source
  pin that defuses the self-satisfying-anchor bypass).
- **Trusting a green anchor as a green description.** Stage 1's forward grep
  only proves the anchor matches; a unit row's `purpose` can describe
  assertions the suite no longer makes. That rot is Stage 2's unique catch —
  expect per-unit truthfulness verdicts, not just anchor hits.
- **Skipping the fresh-context dispatch standalone.** Stages 2+3 judged in
  the invoking session inherit its beliefs about the tests. The dispatch is
  REQUIRED at top level; only the in-QA posture runs inline (and labels its
  stage headers `inline`, honestly).
- **Expecting `suite-green` to re-run a heavy suite on every standalone
  invocation.** The rule is judged on the freshest affordable evidence; the
  verdict cites what evidence it used (inside QA, the just-completed QA run).
- **Running in a repo without the deployed engine.** The skill resolves
  `test-spec.sh` repo-local then `~/.claude/_cj-shared/scripts/`; on a machine
  that never ran `skills-deploy install`, the `stage1/engine` finding tells
  you to.

## Related skills

- `/CJ_doc_audit` — the symmetric three-stage verb for the doc contract
  (`spec/doc-spec.md` + `spec/doc-spec-custom.md`); its Stage 1 engine is the
  `doc-spec.sh --check-on-disk` subcommand.
- `/CJ_qa-work-item` — refreshes the overlay (Step 8.6a) then runs this audit
  inline (Step 8.6d); its RESULT carries the per-stage findings to the
  cj_goal checkpoint.
- `/CJ_document-release` — stub-scaffolds a declared-but-missing
  `spec/test-spec.md` via `test-spec.sh --seed` (a generic stub would be a
  present-but-invalid registry and hard-halt this audit).
- `/CJ_portability-audit` — the explicitly-declared repo-custom verification
  unit this workbench's overlay enumerates (the operator's named example).
