## Utility audits

### /CJ_portability-audit

**Status:** experimental (the static-lint Layer 1)
**Category:** workbench (operates ON the workbench — reaches its own root engine
via the deployed shared home; matches `skills-catalog.json`)
**Source:** `skills/CJ_portability-audit/SKILL.md` ·
`skills/CJ_portability-audit/USAGE.md` · engine
`scripts/cj-portability-audit.sh`

**Invoke when:** you want to verify the workbench's own skills HONESTLY declare
their `portability` — i.e. whether a skill declared `standalone` quietly reaches
for repo-local artifacts a fresh target repo will not have. Not part of a
`cj_goal` chain — a single-step utility (this section documents its correct
behavior verbatim, operator-requested; it is NOT a `CJ_goal_*` orchestrator, so
`validate.sh` Check 15b neither requires nor rejects it).

> This is the authoritative **correct-behavior spec** for the engine: the tier
> ladder, the EXECUTED-vs-documented rule, the carve-outs, and the
> expected-findings table. The operator reads this to confirm the implementation
> (`scripts/cj-portability-audit.sh`) matches the intended behavior. The same
> contract is mirrored in the skill's `SKILL.md`.

**Workflow:**

```
skills-catalog.json (+ optional portability_requires per entry)
   |  jq: status != "deprecated"  &&  (files | length) > 0   (runtime-derived; NO hardcoded count)
   v
for each audited skill:
   |   collect files = catalog files[] + skill-dir *.md + skill-dir scripts/*.sh
   v
classify each repo-local dependency reference:
   |   EXECUTED   = runnable position - bash "$X" / source "$X" / [ -f "$X" ] / [ -x "$X" ]
   |               inside a ```bash fence OR a .sh engine script
   |   DOCUMENTED = prose / table / comment mention
   |   (root scripts/*.sh helper set is GLOBBED at runtime - never hardcoded;
   |    only the root-config set + the GitHub slug are literals)
   v
apply carve-outs:
   |   bundled-own-script:        scripts/*.sh under skills/<name>/scripts/ -> OK (never a finding)
   |   self-resolution preamble:  root-script engine-locate reach-back ->
   |                              OK-with-note for workbench|local-only; FINDING for standalone
   |   portability_requires:      a listed (adjudicated) dep -> OK; a stale listed dep -> note
   v
classify each EXECUTED hit against the STRICT tier ladder:
   |   standalone  <  local-only  <  workbench
   |   dep within declared tier -> OK; dep exceeding it -> FINDING
   v
per-skill verdict:  portable  /  portable-with-notes  /  findings:<list>
   |   finding text: "<skill> declared <tier> but depends on <dep> (needs <higher-tier>)"
   v
three surfaces share the engine:
   |--  /CJ_portability-audit skill          -> rich per-skill verdict table
   |--  validate.sh advisory check           -> prints findings, EXITS 0 (advisory
   |                                            by design; PORTABILITY_STRICT=1 -> hard-fail)
   `--  cj_goal orchestrators' pre-ship gate -> cj-goal-common.sh --phase portability-audit
                                                runs PORTABILITY_STRICT=1; HALTs the run
                                                before /ship on a finding (the orchestrated
                                                path enforces; catalog currently FINDINGS=0)
```

**Strict tier ladder (each tier's ALLOWED dependency set; the bar is "works in a
repo that has never seen this workbench"):**

| Tier | ALLOWED | A dep beyond this is a FINDING |
|---|---|---|
| `standalone` | own bundled scripts (`skills/<name>/scripts/`) + the doc-spec contract files (`spec/doc-spec.md`, `docs/**`, `TODOS.md`, `work-items/`) | root `scripts/*.sh`, `CLAUDE.md` reads, root config, the GitHub slug |
| `local-only` | standalone's set PLUS the user's `~/.claude` deployed state | root workbench helpers, root config |
| `workbench` | everything PLUS root `scripts/*.sh`, `CLAUDE.md` reads, root config | (nothing — this is the tier for skills that operate ON the workbench) |

An unknown `portability` value (not in the closed enum `{standalone, local-only,
workbench}`) is itself a finding.

**Correctly NOT flagged (the EXECUTED-vs-documented precision rule at work):**

| Skill | Declared | Why NOT a finding |
|---|---|---|
| `CJ_qa-work-item` | `standalone` | references `scripts/test.sh` ONLY as a prose citation; it executes the per-work-item test-plan `Script/Command` column, NOT a hardcoded root helper -> **DOCUMENTED**, not executed -> not a finding. |
| `CJ_implement-from-spec` | `standalone` | references `scripts/validate.sh`/`test.sh`/`test-deploy.sh` ONLY in its sensitive-surface PATH-PATTERN list (backticked prose it scans FOR) -> **DOCUMENTED**, not executed -> not a finding |
| `CJ_document-release` | `local-only` | reaches its config helper via the deployed shared home (within-tier) -> **OK** |
| `CJ_suggest` | `local-only` | `~/.claude` deployed state + own bundled `scripts/suggest.sh` -> **OK** |
| `CJ_system-health`, `CJ_scaffold-work-item`, `CJ_improve-queue` | `standalone` | only the passive update-nudge, no executed ROOT `.sh` -> **OK** (`portable`) |
| `CJ_portability-audit` | `workbench` | its own ROOT engine via the deployed shared home (within-tier) -> **OK** (`portable-with-notes`) |

The audit does NOT auto-fix. The operator resolves each finding either by an
**honest relabel** of the skill's `portability` (the candid fix for the
orchestrators — they genuinely need the workbench) OR by **adjudicating** the dep
via the optional `portability_requires` accepted-deps catalog field. The
orchestrators are relabeled `workbench`; `portability_requires` is available for
any remaining adjudication so the default run + the advisory check land
**green**, while `--no-adjudication` still shows the reasoning above (proving the
audit is non-no-op).

**Posture:** ADVISORY in v1 — the `validate.sh` advisory check prints findings
and **exits 0**; the engine itself exits 0 in default mode. `PORTABILITY_STRICT=1`
flips it (and the engine's exit code) to hard-fail — the documented follow-up
once the workbench's declarations are fully reconciled.

**Touches:**

- **Skills dispatched:** none (a single-step utility; no chain).
- **Scripts / tools:** `scripts/cj-portability-audit.sh` (the shared engine, resolved repo-local-first then via the deployed shared home), invoked by the skill AND by `scripts/validate.sh`.
- **Docs it updates:** none — read-only. (Resolving a finding is a separate operator edit to `skills-catalog.json`.)

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
Stage 1 is ONE engine call (`doc-spec.sh --check-on-disk`, printed verbatim);
Stages 2 (requirement compliance — each `requirement:` quoted, clause-checked,
evidence cited) and 3 (implementation drift — ground truth enumerated first,
then each contract doc cross-walked) are agent-judged and, standalone, REQUIRED
to run in one fresh-context subagent. On cj_goal orchestrator paths QA defers
this audit (`DEFER_AUDIT: true`) and the orchestrator runs it ONCE post-sync
(after `/CJ_document-release`) as part of the combined read-only post-sync audit
subagent, feeding the post-QA checkpoint with the docs that will actually ship;
standalone `/CJ_qa-work-item` Step 8.6c still runs it INLINE (a subagent cannot
spawn subagents).

**Touches:**

- **Scripts · tools · shell:** `scripts/doc-spec.sh` (`--seed` / `--validate` /
  `--check-on-disk` — the Stage-1 engine — / the merged list subcommands),
  plus the Agent tool for the standalone fresh-context dispatch of
  Stages 2+3.
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
orchestrator paths QA defers this audit (`DEFER_AUDIT: true`) and the orchestrator
runs it ONCE post-sync (after `/CJ_document-release`) as part of the same combined
read-only post-sync audit subagent, feeding the post-QA checkpoint; standalone
`/CJ_qa-work-item` Step 8.6d still runs it INLINE.

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

