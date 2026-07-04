<!-- GENERATED FILE — do not edit by hand.
     Rendered from the workflow-docs registry (spec/workflow-spec.md) by:
     scripts/workflow-spec.sh --render-docs
     Re-run that command to regenerate; validate.sh Check 27 enforces freshness. -->

## Utility audits

### /CJ_doc_audit

**Status:** experimental
**Category:** local-only (runs in ANY repo; resolves its engine repo-local
`scripts/doc-spec.sh` then the deployed `_cj-shared` home; matches
`skills-catalog.json`)
**Source:** `skills/CJ_doc_audit/SKILL.md` · `skills/CJ_doc_audit/USAGE.md` ·
engine `scripts/doc-spec.sh`

**Invoke when:** you want one keystroke that answers "do this repo's docs follow
its doc contract?" — in the workbench or any consumer repo. First run in a fresh
repo seed-delivers the two-tier contract (`spec/doc-spec.md` from
`doc-spec.sh --seed`, `seeded: yes`; second run `seeded: no`). Three stages:
Stage 1 is ONE engine call (`doc-spec.sh --check-on-disk`, printed verbatim) plus
the workflow-docs freshness check (`workflow-spec.sh --render-docs --check` when
the engine is present); Stages 2 (requirement compliance — each `requirement:`
quoted, clause-checked, evidence cited) and 3 (implementation drift — ground
truth enumerated first, then each contract doc cross-walked; `docs/workflow.md` +
`docs/workflows/` are recognized as a GENERATED surface sourced from
`spec/workflow-spec.md`, never an orphan/drift) are agent-judged and, standalone,
REQUIRED to run in one fresh-context subagent. On cj_goal orchestrator paths QA
skips this inline audit (`DEFER_AUDIT: true`) and it is NOT re-run on the build
path — the agent-judged audit runs on-demand (locally via `/CJ_doc_audit` +
`/CJ_test_audit`, or `bash scripts/audit-nightly.sh`), off the build path;
standalone `/CJ_qa-work-item` Step 8.6c still runs it INLINE
(a subagent cannot spawn subagents).

**Touches:**

- **Scripts · tools · shell:** `scripts/doc-spec.sh` (`--seed` / `--validate` /
  `--check-on-disk` — the Stage-1 engine — / the merged list subcommands),
  `scripts/workflow-spec.sh` (`--render-docs --check` — the workflow-docs
  freshness check folded into Stage 1), plus the Agent tool for the standalone
  fresh-context dispatch of Stages 2+3.
- **Reads / writes:** reads the merged registry (`spec/doc-spec.md` +
  `spec/doc-spec-custom.md`), every declared doc, and the live repo state
  (catalog skills, scripts, workflows, dirs — the Stage-3 ground truth); its
  ONLY write is the idempotent seed delivery of a missing `spec/doc-spec.md`.
  Findings ride the per-stage `DOC_AUDIT:` report (`STAGE1/2/3_FINDINGS=` +
  `stageN/` prefixes) — never a halt.

### /CJ_test_audit

**Status:** experimental
**Category:** local-only (runs in ANY repo; resolves its engine repo-local
`scripts/test-spec.sh` then the deployed `_cj-shared` home; matches
`skills-catalog.json`)
**Source:** `skills/CJ_test_audit/SKILL.md` · `skills/CJ_test_audit/USAGE.md` ·
engine `scripts/test-spec.sh`

**Invoke when:** you want one keystroke that answers "are this repo's tests
aligned with its test contract?". First run in a fresh repo seed-delivers the
general 5-rule contract (`spec/test-spec.md` from `test-spec.sh --seed`); the
coverage cross-check activates once the repo declares `units:` rows in
`spec/test-spec-custom.md` (a rules-only repo gets the named "coverage
cross-check inactive" note). Three stages, symmetric with `/CJ_doc_audit`:
Stage 1 is the existing engine calls (`test-spec.sh --validate` +
`--check-coverage`, `stage1/`-prefixed findings); Stage 2 judges each rule's
`statement` with cited evidence AND each unit's `purpose`/`label` truthfulness
against the source at its anchor; Stage 3 enumerates the live verification
surfaces and judges coverage-in-substance. Standalone, Stages 2+3 run in one
fresh-context subagent (shared with `/CJ_doc_audit` when both run). On cj_goal
orchestrator paths QA skips this inline audit (`DEFER_AUDIT: true`) and it is NOT
re-run on the build path — the agent-judged audit runs on-demand (locally via
`/CJ_doc_audit` + `/CJ_test_audit`, or `bash scripts/audit-nightly.sh`);
standalone `/CJ_qa-work-item` Step 8.6d still runs it INLINE.

**Touches:**

- **Scripts · tools · shell:** `scripts/test-spec.sh` (`--seed` / `--validate` /
  `--list-rules` / `--list-units` / `--check-coverage` — the forward + reverse
  + floor engine), the repo's declared suite runner when judging `suite-green`
  standalone, plus the Agent tool for the standalone fresh-context dispatch of
  Stages 2+3.
- **Reads / writes:** reads the merged registry (`spec/test-spec.md` +
  `spec/test-spec-custom.md`) and the live verification surface
  (`scripts/validate.sh` banners, `tests/*.test.sh`, workflows, hooks — also
  the Stage-3 ground truth); its ONLY write is the idempotent seed delivery of
  a missing `spec/test-spec.md`. Findings ride the per-stage `TEST_AUDIT:`
  report (`STAGE1/2/3_FINDINGS=` + `stageN/` prefixes) — never a halt.
