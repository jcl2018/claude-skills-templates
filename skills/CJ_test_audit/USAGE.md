---
skill: CJ_test_audit
last-updated: "2026-07-06T16:58:45Z"
---

# Using /CJ_test_audit

## The canonical contract-file template

The audit owns the canonical shape of the test contract — what files are
required, where they live, and their format:

- **Required** — the general file `spec/test-spec.md` (delivered verbatim by
  `test-spec.sh --seed`; the audit seed-delivers it when absent). The
  doc-contract partner `spec/doc-spec.md` is required symmetrically by
  `/CJ_doc_audit`.
- **Optional** — the overlay `spec/test-spec-custom.md` next to the general
  file (the repo's `units:` enumeration + per-mode `gates:` array, merged in by
  the parser). A repo without an overlay carries the general rules + layers
  alone (the coverage cross-check stays "inactive" until `units:` rows exist).
- **Position** — `spec/` is canonical; the repo root (`test-spec.md`) is an
  accepted fallback. The engine resolves `spec/`-then-root.
- **Format** — a single fenced `yaml` registry (`schema_version` + `rules:` +
  `layers:`; the overlay adds `units:` + `gates:`). The block IS the source of
  truth, parsed directly.

A first run in a repo with no contract seeds this general file.
`test-spec.sh --classify` reports the contract's generation
(`canonical`/`absent`/`duplicate`). Unlike doc-spec, **test-spec has no legacy
on-disk format** — its fenced-yaml shape has been canonical since introduction
(confirmed from git history) — so `/CJ_test_audit --reconcile` is a **dedup /
no-op**: a canonical contract is a clean no-op, and a duplicated contract
(present at both `spec/` and root) is surfaced as an advisory `RECONCILE:`
directive (reconcile reports the redundant copy; it does not auto-delete and
never migrates a format).

## When to use

- You want one keystroke that answers "are this repo's tests aligned with its
  test contract?" — in the workbench OR any consumer repo — with verdicts
  that are EARNED: the deterministic engine floor, evidence-cited rule/unit
  judgments, and a drift pass over the live verification surfaces.
- You are adopting the test contract in a fresh repo: the first run creates
  `spec/` and seed-delivers `spec/test-spec.md` (`seeded: yes`) — the portable
  5-rule general contract, with the coverage cross-check honestly reported as
  inactive until the repo declares `units:` rows.
- Standalone `/CJ_qa-work-item` Step 8.6d (no `DEFER_AUDIT: true`): the QA agent
  executes ALL THREE STAGES inline (the nested-subagent wall) and lifts the
  per-stage report into the QA RESULT's `AUDITS=` field. On a cj_goal
  orchestrator run QA carries `DEFER_AUDIT: true`, so these stages are skipped on
  the build path — the agent-judged audit runs on-demand (locally via
  `/CJ_doc_audit` + `/CJ_test_audit`, or `bash scripts/audit-nightly.sh`) instead.
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
**Stage 1 (deterministic — engine):** the `test-spec.sh --validate` +
`--check-coverage` calls — forward anchors, reverse sweep, token floor —
mechanize `units-anchored` / `single-owner` / `tests-discoverable` wherever
units exist, and report "coverage cross-check inactive" by name where they
don't; PLUS, when the engine carries them, `--render-docs --check` —
the generated `docs/tests/` test-catalog freshness gate (the same owner
`validate.sh` Check 26 calls), so a stale catalog is caught standalone in any
repo — AND `--check-workflow-coverage` — the forward+reverse workflow-coverage
gate (the same owner `validate.sh` Check 28 calls), so a documented-but-untested
`CJ_goal_*` orchestrator (a missing `level: workflow` behavior or an orphan
`workflow:` link) is caught standalone in any repo; AND, when the engine carries
it, `--check-structure` — the category-based test contract's six structural
checks a–f (a `tests/` folder, one `tests/<category>/<layer>/` subfolder per
(category,layer) pair with a FILE-backed test — the TWO orthogonal axes category
`{workflow, regression, infra}` × layer
`{CI-push, CI-nightly, pipeline-gate, local-hook}`, command-only rows exempt so a
repo whose category tests are all command invocations is never forced to create an
empty folder, a category-scoped spec, one `docs/tests/<category>/<layer>/<name>.md`
per declared test, a `docs/tests/index.md` INDEX, and check (f) — each per-test doc
carrying the three front-door section headings `## What it is` / `## How to run` /
`## Explanation`),
preceded by an idempotent `--seed-docs` that seeds missing per-test doc stubs —
already carrying those three sections — + the index (present ⇒ skip)
but NEVER moves test scripts — findings are the product (exit 0 always), and an
unadopted repo reports the honest "category contract not adopted / inactive" note;
AND, when the engine carries them, `--check-topic-contract` + `--check-topic-docs`
— the three-layer topic contract + its topic-docs companion (the same owners
`validate.sh` Checks 30/31 call): every ENROLLED topic (`topic_contracts:`) must
reach CI-push + CI-nightly + local-hook{deterministic}, each row with its
front-door doc, plus a dream doc (`docs/goals/<topic>.md`) + topic-by-layer
subdir (`docs/tests/topics/<topic>/`); a missing local-hook AGENTIC test is an
ADVISORY per-topic `note:` reported verbatim, never a finding (agentic proofs
run on-demand, not required).
Findings carry the `stage1/` prefix.
**Stage 2 (requirement compliance — agent-judged, evidence-forced):** each
general RULE's `statement` is quoted and judged with cited evidence
(`suite-green` names the freshest full-suite run; `new-code-tested` names the
diff-vs-units comparison), each overlay UNIT's `purpose`/`label` is
judged for truthfulness against the source at its anchor, AND — when the overlay
declares the behavior-coverage axis — each declared BEHAVIOR is judged for the
substance the deterministic check can't reach (statement falsifiable/specific?
`level` correct? the linked test proves vs merely mentions the behavior? one
broad test over-claimed against many behaviors?), findings prefixed
`stage2/behavior:<id>`, AND — when the overlay declares the `categories:` axis —
each per-test category DOC (`docs/tests/<category>/<layer>/<name>.md`) is judged for
front-door truthfulness the check-(f) heading presence can't reach (does
`## How to run` match the declared `command`? are `## What it is` /
`## Explanation` accurate? does the family cross-link resolve?), findings prefixed
`stage2/doc:<category>/<layer>/<name>`, AND — where an enrolled topic declares a
`local-hook`+`agentic` row (conditional; lawfully vacuous for agentic-row-less
topics under the advisory posture) — that row is judged to name a REAL sandbox
test, not a hollow prompt, findings prefixed `stage2/topic:<t>`. **Stage 3
(implementation drift — agent-judged):** the live verification surfaces
(tests on disk, validate banners, workflows, hooks) are enumerated first,
then coverage-in-substance is judged — where Stage 1 proves a mapping EXISTS,
Stage 3 judges whether it is still TRUE, and a NEW surface class the rules
don't contemplate is drift. The generated `docs/tests/` + `docs/test-catalog.md`
view is recognized as the catalog's OWN rendered output (its freshness is a
Stage-1 finding when stale), never flagged as an uncontemplated surface.

Before the three stages, **Step 2 ensures the contract is canonical** via
`test-spec.sh --classify`: `absent` → seed-deliver (as before); `canonical` →
ok; `duplicate` → an advisory `RECONCILE:` directive into the Stage-1 report
(NO auto-write on a plain run; there is no `legacy` branch — test-spec's format
never diverged). The directive is advisory like a `REMEDIATION:` line. The
dedup runs ONLY under the opt-in standalone `--reconcile` flag (the in-QA path
never passes it).

Standalone, Stages 2+3 are REQUIRED to run in ONE fresh-context subagent
(prompt = repo root + engine path + Stage-1 report + protocols only; when
both audits run together the same subagent may judge both). The report prints
findings PER STAGE (`STAGE1/2/3_FINDINGS=` + `UNITS_AUDITED=` + three
`--- stage N ---` sections); findings never crash or halt — on the cj_goal
build path this audit does not run inline (it runs on-demand off the build path); standalone,
the operator reads the report directly.

## Common pitfalls

- **Expecting the audit to halt a pipeline.** It never does. Standalone, QA
  findings ride a GREEN RESULT and the operator reads them; on the cj_goal
  build path the inline audit is skipped entirely and the on-demand audit
  surfaces findings out of band.
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
- **A stale vendored `scripts/test-spec.sh` silently shadowing `_cj-shared`.**
  The repo-local engine is used ONLY if it is CURRENT, proven by a side-effect-
  free `--classify` capability probe (F000069/S000116). A stale copy (no
  `--classify`) is detected, `_cj-shared` is used instead, and the audit emits
  `stage1/engine-stale` naming the remedy (update/remove the vendored engine or
  re-run `skills-deploy install`) — so the seeding + the audit no longer silently
  no-op behind a stale engine.

## Related skills

- `/CJ_doc_audit` — the symmetric three-stage verb for the doc contract
  (`spec/doc-spec.md` + `spec/doc-spec-custom.md`); its Stage 1 engine is the
  `doc-spec.sh --check-on-disk` subcommand.
- `/CJ_qa-work-item` — refreshes the overlay (Step 8.6a) then runs this audit
  inline (Step 8.6d) standalone; on a cj_goal run it carries `DEFER_AUDIT: true`
  and skips the inline audit (it runs on-demand off the build path).
- `/CJ_document-release` — stub-scaffolds a declared-but-missing
  `spec/test-spec.md` via `test-spec.sh --seed` (a generic stub would be a
  present-but-invalid registry and hard-halt this audit).
- `scripts/cj-portability-audit.sh` + `validate.sh` Check 18 — the explicitly
  -declared repo-custom verification unit this workbench's overlay enumerates
  (the `portability-audit` / `validate-check-18` rows). Its former standalone
  `/CJ_portability-audit` verb was retired by F000081; the engine + Check 18 stay,
  and portability is covered as `infra` category tests at all three levels.
