---
skill: CJ_test_audit
last-updated: "2026-06-12T00:00:00Z"
---

# Using /CJ_test_audit

## When to use

- You want one keystroke that answers "are this repo's tests aligned with its
  test contract?" — in the workbench OR any consumer repo.
- You are adopting the test contract in a fresh repo: the first run creates
  `spec/` and seed-delivers `spec/test-spec.md` (`seeded: yes`) — the portable
  5-rule general contract, with the coverage cross-check honestly reported as
  inactive until the repo declares `units:` rows.
- Inside `/CJ_qa-work-item` Step 8.6d (a cj_goal run): the QA agent executes
  this skill's steps INLINE and lifts the report into the QA RESULT's
  `AUDITS=` field for the post-QA checkpoint.
- After adding/renaming tests or validator checks: the deterministic coverage
  cross-check catches orphaned units rows, unregistered test files (the
  silent-skip class), and extraction-grammar rot.

## When NOT to use

- As the test RUNNER — `./scripts/test.sh` (or the repo's declared runner)
  runs the suite; this skill audits the suite's alignment with its contract.
- To edit the contract itself — add `units:` rows to
  `spec/test-spec-custom.md` (never to the general file) when QA Step 8.6a or
  a manual change adds test surfaces; the audit verifies, it does not author.
- In a non-git directory (the skill refuses).
- To audit docs — that is `/CJ_doc_audit`, the symmetric verb.

## Mental model

Two tiers, one merged registry, two enforcement layers. The general contract
(`spec/test-spec.md`) carries the five portable rules and is byte-identical in
every adopting repo — delivered by `test-spec.sh --seed`, never edited in
place. The repo's unit-level enumeration of its verification surface lives in
the `spec/test-spec-custom.md` overlay; the parser merges the two so the audit
sees ONE registry. The deterministic floor (`--check-coverage`: forward
anchors, reverse sweep, token floor) mechanizes `units-anchored` /
`single-owner` / `tests-discoverable` wherever units exist — and reports
"coverage cross-check inactive" by name where they don't. The agent-judged
layer (`suite-green`, `new-code-tested`) sits on top, never replacing the
floor. Findings ride the report and never crash or halt; in a cj_goal run the
operator decides at the post-QA checkpoint.

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
- **Expecting `suite-green` to re-run a heavy suite on every standalone
  invocation.** The rule is judged on the freshest affordable evidence; the
  verdict says what evidence it used (inside QA, the just-completed QA run).
- **Running in a repo without the deployed engine.** The skill resolves
  `test-spec.sh` repo-local then `~/.claude/_cj-shared/scripts/`; on a machine
  that never ran `skills-deploy install`, the engine finding tells you to.

## Related skills

- `/CJ_doc_audit` — the symmetric verb for the doc contract
  (`spec/doc-spec.md` + `spec/doc-spec-custom.md`).
- `/CJ_qa-work-item` — refreshes the overlay (Step 8.6a) then runs this audit
  inline (Step 8.6d); its RESULT carries the findings to the cj_goal
  checkpoint.
- `/CJ_document-release` — stub-scaffolds a declared-but-missing
  `spec/test-spec.md` via `test-spec.sh --seed` (a generic stub would be a
  present-but-invalid registry and hard-halt this audit).
- `/CJ_portability-audit` — the explicitly-declared repo-custom verification
  unit this workbench's overlay enumerates (the operator's named example).
