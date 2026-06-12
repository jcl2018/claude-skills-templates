---
name: CJ_test_audit
description: "Audit a repo's tests against its test contract — runnable standalone in ANY repo. Ensures the two-tier test contract exists (seed-delivers spec/test-spec.md via test-spec.sh --seed when missing, creating spec/ if needed, reporting seeded: yes; idempotent seeded: no on re-run), validates the MERGED registry (the general 5-rule contract + the optional spec/test-spec-custom.md units overlay), runs the deterministic coverage cross-check (test-spec.sh --check-coverage: forward anchor-grep per unit, reverse sweep of live surfaces, >=20-token floor — all units-gated, so a rules-only consumer repo gets a named 'coverage cross-check inactive' note, never a misleading finding), judges the agent-judged rules (suite-green, new-code-tested) against the repo's current state, and emits a findings report: TEST_AUDIT: <ok|findings> + FINDINGS=<n> + UNITS_AUDITED=<n> + per-finding lines. Findings never crash the audit — a broken contract IS the report. Engine resolution repo-local scripts/test-spec.sh then ~/.claude/_cj-shared/scripts/. Dual posture: standalone invocations may use the Skill tool; inside a QA subagent (qa.md Step 8.6d) the logic executes INLINE by the agent reading this file (a subagent cannot spawn subagents). Use when: 'audit this repo's tests', 'are tests aligned with the test spec', 'check the test coverage contract'."
version: 0.1.0
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

If `NOT_A_GIT_REPO`: tell the user "Error: /CJ_test_audit requires a git repository." and stop.

## Overview

`/CJ_test_audit` answers one question in ANY repo: **are this repo's tests
aligned with its test contract?** The contract is the two-tier test-spec
registry — the portable general rules (`spec/test-spec.md`, byte-identical to
`test-spec.sh --seed`: tests-discoverable, suite-green, new-code-tested,
units-anchored, single-owner) plus an optional repo-specific units overlay
(`spec/test-spec-custom.md`) the parser merges in. The audit:

1. **Seed-delivers** the contract when missing (creating `spec/` if needed).
2. **Validates** the merged registry.
3. Runs the **deterministic coverage cross-check** (units-gated).
4. Judges the **agent-judged rules** against the repo's current state.
5. Emits a grep-able **findings report**.

Findings never crash the audit and never halt a caller: a broken contract IS
the report. The audit is read-mostly — its ONLY write is the seed delivery
(step 1), which is idempotent.

**Dual posture.** Standalone (operator keystroke in any repo): invoke this
skill directly — it may be dispatched via the Skill tool. Inside a QA subagent
(`/CJ_qa-work-item` qa.md Step 8.6d, inside a cj_goal run): a subagent cannot
spawn subagents (the nested-subagent wall), so the QA agent executes this
file's steps INLINE by reading it. Both postures produce the identical report
shape.

## Step 1: Resolve the engine

The deterministic half runs on `test-spec.sh`. Resolve it repo-local first,
then the deployed shared home:

```bash
_TA_ROOT=$(git rev-parse --show-toplevel)
_TA_ENGINE=""
if [ -x "$_TA_ROOT/scripts/test-spec.sh" ]; then
  _TA_ENGINE="$_TA_ROOT/scripts/test-spec.sh"
elif [ -x "${CJ_SHARED_SCRIPTS:-$HOME/.claude/_cj-shared/scripts}/test-spec.sh" ]; then
  _TA_ENGINE="${CJ_SHARED_SCRIPTS:-$HOME/.claude/_cj-shared/scripts}/test-spec.sh"
fi
if [ -z "$_TA_ENGINE" ]; then
  echo "TEST_AUDIT: findings"
  echo "FINDINGS=1"
  echo "UNITS_AUDITED=0"
  echo "FINDING: engine — test-spec.sh unreachable (repo-local scripts/ + deployed _cj-shared both absent); run 'skills-deploy install'"
  # stop here — nothing else can run without the engine
fi
```

## Step 2: Ensure the contract exists (seed delivery)

If NEITHER `spec/test-spec.md` NOR a root `test-spec.md` exists, create
`spec/` and deliver the seed. Write to a temp file, verify non-empty AND
`--validate`-clean, THEN move into place (the corruption guard). Report
`seeded: yes`; when the contract already exists report `seeded: no` (the
idempotence contract — a second run never re-seeds):

```bash
SEEDED=no
if [ ! -f "$_TA_ROOT/spec/test-spec.md" ] && [ ! -f "$_TA_ROOT/test-spec.md" ]; then
  _TA_TMP=$(mktemp -d)
  if bash "$_TA_ENGINE" --seed > "$_TA_TMP/test-spec.md" 2>/dev/null \
     && [ -s "$_TA_TMP/test-spec.md" ] \
     && TEST_SPEC_PATH="$_TA_TMP/test-spec.md" bash "$_TA_ENGINE" --validate >/dev/null 2>&1; then
    mkdir -p "$_TA_ROOT/spec"
    mv "$_TA_TMP/test-spec.md" "$_TA_ROOT/spec/test-spec.md"
    SEEDED=yes
  fi
  rm -rf "$_TA_TMP"
fi
echo "seeded: $SEEDED"
```

A failed seed delivery (the `if` falls through) is a finding:
`FINDING: seed — test-spec.sh --seed did not emit a valid test-spec.md`.

## Step 3: Validate the merged registry

```bash
bash "$_TA_ENGINE" --validate
```

The engine merges `spec/test-spec.md` + `spec/test-spec-custom.md`-if-present
(overlay-absent repos: nothing to merge, no finding; `REGISTRY=absent` cannot
occur here — Step 2 just guaranteed the general file). A non-zero exit
(present-but-invalid registry: schema, closed enums, duplicate ids, the test-row
source pin, a work-item ID in a rendered field) is ONE finding quoting the
engine's `[test-spec-no-config]` reason; skip Steps 4–5 and go to Step 6.

On success, capture the unit count:

```bash
UNITS_AUDITED=$(bash "$_TA_ENGINE" --list-units 2>/dev/null | grep -c . || true)
```

## Step 4: Deterministic coverage cross-check

```bash
bash "$_TA_ENGINE" --check-coverage
```

- Exit 0 with `OK coverage ...` — the forward anchor-grep (`units-anchored`),
  reverse sweep (`single-owner` + `tests-discoverable`), and token floor are
  all clean.
- Exit 0 with the named note `no units declared — coverage cross-check
  inactive; declare units in spec/test-spec-custom.md to activate` — a
  rules-only registry (the seeded consumer default). NOT a finding; report
  the note verbatim (the honest "inactive" state).
- Exit 1 — each `FINDING:` line the engine printed is one audit finding,
  quoted verbatim.

## Step 5: Agent-judged rules

Judge the two rules the deterministic engine cannot, against the repo's
CURRENT state:

- **`suite-green`** — the declared full-suite runner passes before ship. Use
  the freshest full-suite evidence available: inside a cj_goal QA run, the QA
  pass that just completed IS the evidence; standalone, run the repo's
  declared runner when one exists and is affordable (this workbench:
  `./scripts/test.sh`), else verdict `n/a — no affordable full-suite evidence
  this run` with the reason. A red suite is a finding.
- **`new-code-tested`** — behavior-adding changes carry test rows. Inspect the
  current branch's diff against its base (`git diff --name-only @{upstream}`
  or the default branch): new/changed non-doc code with NO corresponding test
  surface (no new/changed `tests/*` and no `units:` row addition) is a
  finding (`code-without-units drift`); doc-only diffs are vacuously green.

These verdicts are judgment, layered ABOVE the deterministic floor (D6) —
run-to-run wording may vary; the deterministic findings beneath them stay
stable.

## Step 6: Emit the findings report

Always emit, in this order (the grep-able contract callers parse):

```
TEST_AUDIT: <ok|findings>
FINDINGS=<n>
UNITS_AUDITED=<n>         # --list-units count post-validate (0 = rules-only)
seeded: <yes|no>
FINDING: <area> — <detail>     # one line per finding, omitted when none
### Rule verdicts
<rule-id>: <verdict>           # one line per general rule
```

`TEST_AUDIT: ok` requires FINDINGS=0. The inactive-coverage note and `n/a`
rule verdicts do not block `ok`.

## Error handling

| Condition | Behavior |
|---|---|
| Not a git repo | "Error: /CJ_test_audit requires a git repository." — stop |
| Engine unreachable | `TEST_AUDIT: findings` + the engine finding (Step 1) |
| Seed delivery fails | finding; audit continues on whatever exists |
| Registry present-but-invalid | ONE finding quoting `[test-spec-no-config]`; Steps 4–5 skipped |
| No units declared | the named inactive note — never a finding |
| Findings | reported, exit clean — findings are the product, not a crash |
