---
name: CJ_test_run
description: "Execute a repo's test contract and report evidence-derived pass/fail — the 'does it pass?' companion to /CJ_test_audit's 'is it wired?'. Runs a deterministic Stage-1 audit pre-step (the four test-spec.sh engine calls — --validate / --check-coverage / --render-docs --check / --check-workflow-coverage — printed verbatim, with the invalid-registry-HALTS / valid-with-findings-surface-and-continue / absent-registry-SKIP split), then scripts/test-run.sh which reads the runners: axis of the merged test-spec registry and runs the selected tier's runners ONCE each (default tier: free; --evals adds paid, --e2e adds local-only, --all everything — a default run NEVER touches a model), then narrates the materialized report (tests/test-run/reports/<UTC-ts>.md) + machine-readable ledger (.json: schema 1, timestamp, HEAD SHA, aggregate, per-runner rc/outcome/covered-families). Aggregate is the closed enum {pass, fail, all-skipped}: any executed runner failing => fail + exit 1; >=1 green and none failed => pass; zero executed => all-skipped (NEVER rendered pass). Registry edges are honest: absent => REGISTRY=absent + exit 0; invalid => the [test-spec-no-config] passthrough + exit 1; valid with zero runners => 'SKIP: no runners declared' + exit 0 (no report, no ledger, no inference). Two selection modes: the default runners mode runs the whole tiered suite; category mode (the two-axis contract — --category <workflow|regression|infra> the KIND, --layer <CI-push|CI-nightly|pipeline-gate|local-hook> the cadence/place, their composition, or a single test NAME) runs exactly the selected command(s) from the categories: axis, reusing the docs/tests/<category>/<layer>/<name>.md name and honoring the SAME cost tiers (a default run touches no paid model; a paid/local-only test is skip(tier-not-selected) without --evals/--e2e/--all); an unadopted repo reports 'category contract not adopted / inactive'. Runnable in ANY repo the skills are installed for; engines resolve sibling-in-scriptdir -> $REPO_ROOT/scripts/ -> deployed _cj-shared. Use when: 'run the tests', 'do the tests pass', 'execute the test suite'."
version: 0.2.0
allowed-tools:
  - Bash
  - Read
  - Glob
  - Grep
---

## Preamble

Check for collection updates (silent if none, banner if a newer version is available):

```bash
_UC="${CJ_SHARED_SCRIPTS:-$HOME/.claude/_cj-shared/scripts}/skills-update-check"
[ -x "$_UC" ] && "$_UC" 2>/dev/null || true
```

Verify this is a git repository:

```bash
git rev-parse --show-toplevel 2>/dev/null || echo "NOT_A_GIT_REPO"
```

If `NOT_A_GIT_REPO`: tell the user "Error: /CJ_test_run requires a git repository." and stop.

## Update Nudge Handling (skip silently if preamble printed nothing about updates)

If preamble output contains `SKILLS_UPGRADE_AVAILABLE <old> <new>`, follow the
upgrade flow defined in `~/.claude/skills/CJ_personal-workflow/SKILL.md`. If
`SKILLS_JUST_UPGRADED <from> <to>`, print "claude-skills-templates upgraded to
v\<to\> (was v\<from\>)" and continue.

## Overview

`/CJ_test_run` answers one question in ANY repo: **do this repo's tests pass?**
It is the execution companion to `/CJ_test_audit` (which is READ-ONLY — it proves
tests are WIRED, never that they PASS). The test CONTRACT itself defines what
runs: the `runners:` axis of the merged two-tier test-spec registry declares HOW
to run the repo's tests (command + cost tier + covered families), so any adopting
repo — `npm test`, `make check`, whatever — gets real execution from the same
portable engine, not a hardcoded table. **Two selection modes (F000074):** the
default runners mode runs the whole tiered suite; **category mode** (`--category
<workflow|regression|infra>`, `--layer <CI-push|CI-nightly|pipeline-gate|local-hook>`,
their composition, or a single test NAME) runs exactly the selected command(s)
from the two-axis `categories:` axis, reusing the
`docs/tests/<category>/<layer>/<name>.md` name — that per-test doc is the test's
authoritative What/How/Why front door, and a single-name run surfaces/links its
`## How to run` so the executed and documented command agree — and honoring the
SAME cost tiers. The category contract is **two orthogonal axes** (F000078):
`category` is the KIND `{workflow, regression, infra}` and `layer` is WHERE/WHEN
`{CI-push, CI-nightly, pipeline-gate, local-hook}`, plus a per-test `mode`
`{deterministic, agentic}` (agentic ⇒ tier ≠ free), so you can select by kind
(`--category workflow`), by cadence (`--layer CI-nightly`), or their intersection.

The flow is three parts, in order:

1. **Stage-1 audit pre-step (deterministic).** The four `test-spec.sh` engine
   calls, printed verbatim. An INVALID registry HALTS (the `[test-spec-no-config]`
   passthrough); an ABSENT registry is a named SKIP; findings on a VALID registry
   are surfaced but do NOT block execution — the run proceeds and the findings
   ride the final report.
2. **Execution (`scripts/test-run.sh`).** Reads the `runners:` axis, plans a
   tiered run, executes the selected runners ONCE each, derives every outcome
   from captured evidence (rc + output).
3. **Narration.** The report + ledger paths and the aggregate verdict.

**Cost tiers are the hard UX law.** A default invocation runs ONLY `tier: free`
runners. `tier: paid` (evals) and `tier: local-only` (e2e) execute only behind
explicit flags. A default run NEVER surprises the operator with model spend.

## Step 1: Resolve the engines

Resolve `test-spec.sh` AND `test-run.sh` via the established chain:
sibling-in-scriptdir → `$REPO_ROOT/scripts/` → deployed `_cj-shared` — so a
consumer repo with no repo-local `scripts/` still resolves both from the deployed
shared home.

```bash
_REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
_SHARED="${CJ_SHARED_SCRIPTS:-$HOME/.claude/_cj-shared/scripts}"
_resolve() {
  # $1 = script basename; echoes the first existing candidate.
  for _c in "$_REPO_ROOT/scripts/$1" "$_SHARED/$1"; do
    [ -f "$_c" ] && { echo "$_c"; return 0; }
  done
  return 1
}
TEST_SPEC_SH=$(_resolve test-spec.sh) || { echo "ERROR: cannot resolve test-spec.sh"; exit 1; }
TEST_RUN_SH=$(_resolve test-run.sh)   || { echo "ERROR: cannot resolve test-run.sh"; exit 1; }
echo "TEST_SPEC_SH: $TEST_SPEC_SH"
echo "TEST_RUN_SH:  $TEST_RUN_SH"
```

If either engine is unreachable: tell the user "Error: /CJ_test_run cannot
resolve its engines (test-spec.sh / test-run.sh). Run `skills-deploy install` or
check the repo structure." and stop.

## Step 2: Stage-1 audit pre-step (the four engine calls, verbatim)

Run the four deterministic Stage-1 engine calls and print their output VERBATIM
(no executor-authored loops, no paraphrase). This is the same Stage-1 subset
`/CJ_test_audit` runs — the "is it wired?" check, ahead of the "does it pass?"
run.

```bash
echo "=== Stage 1: test-spec.sh --validate ==="
_v_out=$(bash "$TEST_SPEC_SH" --validate 2>&1); _v_rc=$?
printf '%s\n' "$_v_out"
```

**Split on the result of `--validate`:**

- **ABSENT registry** — `--validate` printed `REGISTRY=absent` (exit 0): the repo
  has not adopted the test contract. Print a named SKIP
  (`SKIP: no test-spec registry — nothing to run or audit`) and STOP. Do NOT run
  the remaining engine calls or `test-run.sh`.
- **INVALID registry** — `--validate` exited non-zero with a
  `[test-spec-no-config] <reason>` line: HALT. Print the passthrough marker line
  verbatim and STOP. Do NOT run `test-run.sh` against a broken contract.
- **VALID registry** — `--validate` printed `OK schema_version=<n>` (exit 0):
  continue. Run the three remaining Stage-1 calls, printing each verbatim:

```bash
echo "=== Stage 1: test-spec.sh --check-coverage ==="
bash "$TEST_SPEC_SH" --check-coverage 2>&1 || true
echo "=== Stage 1: test-spec.sh --render-docs --check ==="
bash "$TEST_SPEC_SH" --render-docs --check 2>&1 || true
echo "=== Stage 1: test-spec.sh --check-workflow-coverage ==="
bash "$TEST_SPEC_SH" --check-workflow-coverage 2>&1 || true
```

Stage-1 FINDINGS on a VALID registry (a coverage drift, a stale catalog, a
missing workflow behavior) are SURFACED here but do NOT block execution — the run
proceeds and the findings ride the final narration. (This mirrors the design: an
invalid registry halts; findings on a valid registry surface and continue.)

## Step 3: Execute (test-run.sh with forwarded flags)

Forward the operator's flags to `test-run.sh` unchanged. Two selection modes:

- **Runners mode (default).** With no `--category` and no single test name,
  `test-run.sh` runs the `runners:` axis (the full tiered suite). Tier flags
  (`--dry-run`, `--evals`, `--e2e`, `--all`) apply; default (no flags) runs only
  `tier: free`.
- **Category mode (F000074; two-axis reframe F000078).** `--category
  <workflow|regression|infra>` runs every declared test in that KIND; `--layer
  <CI-push|CI-nightly|pipeline-gate|local-hook>` runs every test at that
  cadence/place; the two MAY be composed (`--category workflow --layer CI-nightly`
  = the intersection); a bare positional NAME runs the single test of that name
  (reusing the `docs/tests/<category>/<layer>/<name>.md` name). Selection maps
  `name → command` via the `categories:` axis; the SAME cost tiers apply (a default
  run touches no paid model — a `paid`/`local-only` category test is
  `skip(tier-not-selected)` unless `--evals`/`--e2e`/`--all` is passed). A single
  name is mutually exclusive with `--category`/`--layer`.

```bash
# $ARGS = the flags/args the operator passed to /CJ_test_run (default: none).
#   e.g. (none) | --dry-run | --evals | --category workflow | --layer CI-nightly | doc-sync | --category workflow --layer CI-nightly --dry-run
bash "$TEST_RUN_SH" $ARGS
_run_rc=$?
```

`test-run.sh` handles the registry edges itself, consistent with Step 2:
- absent → `REGISTRY=absent` + exit 0 (should not reach here — Step 2 stops on absent)
- invalid → `[test-spec-no-config]` passthrough + exit 1 (should not reach here — Step 2 halts)
- valid with zero `runners:` rows → `SKIP: no runners declared` + exit 0, NO
  report, NO ledger (runners mode only). Narrate that honestly: the contract is
  adopted but declares no runners, so there is nothing to execute.
- category mode with no `categories:` axis → `category contract not adopted /
  inactive` + exit 0. Narrate: the repo hasn't adopted the category contract.
- category mode: unknown test name / a category outside
  `{workflow, regression, infra}` / a layer outside
  `{CI-push, CI-nightly, pipeline-gate, local-hook}` / mixing a single name with
  `--category`/`--layer` → exit 2 with a named error. Surface it verbatim.

On `--dry-run` (either mode), `test-run.sh` prints the plan and writes nothing —
narrate the plan and stop.

## Step 4: Narrate the report + ledger

On a real (non-dry-run) execution with ≥1 runner row, `test-run.sh` writes a
`.md` report + `.json` ledger under `tests/test-run/reports/<UTC-ts>.` Narrate:

- The **aggregate verdict** (`pass` / `fail` / `all-skipped`) and the exit code.
- The **report path** (`tests/test-run/reports/<UTC-ts>.md`) and the **ledger
  path** (`.json`).
- Any Stage-1 findings surfaced in Step 2 (they rode along; call them out so the
  operator sees "the suite passed BUT the catalog is stale" as one picture).

**Per-test doc surfacing (category / single-name mode; F000077).** In category
mode — especially a single-name run (`/CJ_test_run <name>`) — the selected test's
`docs/tests/<category>/<layer>/<name>.md` IS its authoritative What/How/Why front
door, and its `## How to run` section is the canonical statement of the command.
When you narrate a single named test (or a small category selection), ALSO
surface/link that per-test doc so the run and the doc agree on the command:
name-to-doc is the `doc` column of `test-spec.sh --list-categories`
(`docs/tests/<category>/<layer>/<name>.md`). Pointing the operator at the front door keeps
the executed command and the documented `## How to run` from disagreeing — the
same command flows from the `categories:` row into both the run and the doc.

Do NOT re-interpret the aggregate — `test-run.sh` derives it from evidence. A
`fail` means an executed runner returned non-zero; a `skipped(<reason>)` runner
is never counted green; an `all-skipped` aggregate (every runner tier/platform/
self-gated) is exit 0 but is NEVER rendered `pass`.

## Usage

```
/CJ_test_run                      # Stage-1 pre-step, then run the runners: suite (tier: free), then narrate
/CJ_test_run --dry-run            # Stage-1 pre-step, then print the plan (execute nothing)
/CJ_test_run --evals              # + paid tier (evals — real model spend)
/CJ_test_run --e2e                # + local-only tier (the local E2E harness)
/CJ_test_run --all                # every tier
/CJ_test_run --category workflow    # (F000074) run every workflow-KIND test (portability + cj_goal evals + doc-sync + e2e-local)
/CJ_test_run --category infra       # (F000078) run every infra-KIND test (validate/suite/test-deploy)
/CJ_test_run --layer CI-push        # (F000078) run every CI-push-layer test (validate/suite/test-deploy/portability-smoke)
/CJ_test_run --layer CI-nightly     # (F000078) run every CI-nightly-layer test (portability-deploy/goal-*-eval/doc-sync)
/CJ_test_run --category workflow --layer CI-nightly  # (F000078) the intersection (the nightly workflow tests)
/CJ_test_run doc-sync               # (F000074) run the single test named "doc-sync" (docs/tests/workflow/CI-nightly/doc-sync.md)
/CJ_test_run --layer CI-push --dry-run  # print the layer plan (execute nothing)
```

Routing phrases: "run the tests", "do the tests pass", "execute the test suite".

## Error Handling

| Error | Message | Recovery |
|---|---|---|
| Not a git repo | "Error: /CJ_test_run requires a git repository." | Run inside a repo |
| Engines not found | "Error: /CJ_test_run cannot resolve its engines (test-spec.sh / test-run.sh)." | Run `skills-deploy install` or check the repo structure |
| Registry absent | `SKIP: no test-spec registry — nothing to run or audit` | Adopt the contract (`test-spec.sh --seed`) if you want a test run |
| Registry invalid | the verbatim `[test-spec-no-config] <reason>` line | Fix the registry, then re-run |
| Zero runners | `SKIP: no runners declared` (runners mode only) | Add `runners:` rows to `spec/test-spec-custom.md` |
| A runner failed | aggregate `fail` + exit 1 + verbatim FAIL lines in the report | Fix the failing runner's tests; re-run |
| No categories axis (category mode) | `category contract not adopted / inactive` + exit 0 | Add a `categories:` axis to `spec/test-spec-custom.md` |
| Unknown test name (category mode) | `no category test named '<name>'` + exit 2 | Check `test-spec.sh --list-categories --names` |
| Bad category/layer / name + `--category`/`--layer` together | named error + exit 2 | Pass a valid selection: `--category workflow\|regression\|infra`, `--layer CI-push\|CI-nightly\|pipeline-gate\|local-hook` (composable), OR a single name |
| A category test failed | aggregate `fail` + exit 1 + verbatim FAIL lines in the report | Fix the failing test; re-run |
