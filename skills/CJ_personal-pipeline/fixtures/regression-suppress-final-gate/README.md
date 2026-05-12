# Fixture: regression-suppress-final-gate

Wrapper contract: `--suppress-final-gate` skips Step 8.5 + 9.2 AUQs, redirects
decision log via `GSTACK_PIPELINE_DECISION_LOG_PATH`, leaves telemetry +
tracker journal intact.

## What it tests

Two cases under one fixture:

1. **With-flag path** — invoking with `--suppress-final-gate` and a custom
   decision-log path. Step 8.5 must NOT surface its AUQ. Step 9.2 sunset must
   NOT surface its AUQ even if invocation count would normally trigger it.
   `[auto-final-gate-suppressed]` tracker journal entry must appear. Decisions
   land in the wrapper-specified log path, not the standalone one. Telemetry
   write at Step 9.1 happens normally.

2. **No-flag regression path** — invoking the same design doc WITHOUT the flag
   must behave exactly as v2.1.3 did: 8.5 surfaces (or empty-state short-circuits),
   sunset surfaces on the modulo-6 cadence, decisions land in the default
   standalone path.

## Setup

Use any clean-slate design doc fixture (the `example-design-doc/` happy path
case is fine). The point is exercising the suppression-flag plumbing, not the
inner pipeline phases — those are covered by the other fixtures.

```bash
DOC=~/.gstack/projects/jcl2018-claude-skills-templates/<some-approved-design-doc>.md
WRAPPER_LOG=/tmp/cj-pipeline-suppress-smoke-$(date +%s).jsonl
```

If no clean-slate design doc exists, scaffold one:

```bash
/office-hours  # produce a synthetic approved doc; or hand-craft one
```

## Invocation — with flag

```bash
export GSTACK_PIPELINE_DECISION_LOG_PATH="$WRAPPER_LOG"
/CJ_personal-pipeline --suppress-final-gate "$DOC"
# (alternative: pass env var inline if shell supports it)
```

## Expected outcome — with flag

- Step 1 stdout: NO warning about missing env var (because env var is set).
- Step 8.5: no AskUserQuestion fires. Tracker journal at `<WORK_ITEM>/<TRACKER>.md`
  contains a line matching `[auto-final-gate-suppressed] \d+ mechanical, \d+ taste, \d+ user-challenge-approved; decisions at /tmp/cj-pipeline-suppress-smoke-.*\.jsonl`.
- Step 9.1: telemetry line appended to `~/.gstack/analytics/CJ_CJ_personal-pipeline.jsonl`
  with `end_state=green` (assuming no earlier halt).
- Step 9.2: no AskUserQuestion fires even on a contrived invocation 6 (test by
  hand-padding the telemetry file before invocation if you want to exercise this).
- `cat "$WRAPPER_LOG"` — contains one line per logged decision from this run,
  filterable by `run_id`.
- Standalone log `~/.gstack/analytics/CJ_personal-pipeline-auto-decisions.jsonl` —
  unchanged from before the run (suppressed run didn't pollute it).

## Invocation — without flag (regression)

```bash
unset GSTACK_PIPELINE_DECISION_LOG_PATH
/CJ_personal-pipeline "$DOC"
```

## Expected outcome — without flag

- Step 1: no env-var warning (because flag is also absent).
- Step 8.5: behaves as v2.1.3 — either empty-state short-circuit (silent) or
  AskUserQuestion surfaces. NO `[auto-final-gate-suppressed]` journal line.
- Step 9.1: telemetry line appended.
- Step 9.2: AskUserQuestion surfaces ONLY if `INVOCATION_COUNT >= 6 && (INVOCATION_COUNT - 6) % 5 == 0` (the existing cadence rule).
- Decisions land in the standalone log path.

## Negative test — flag without env var

```bash
unset GSTACK_PIPELINE_DECISION_LOG_PATH
/CJ_personal-pipeline --suppress-final-gate "$DOC"
```

Expected: Step 1 emits the soft-warning to stderr:

```
warning: --suppress-final-gate set without GSTACK_PIPELINE_DECISION_LOG_PATH; decisions go to standalone log ~/.gstack/analytics/CJ_personal-pipeline-auto-decisions.jsonl
```

Pipeline still proceeds; decisions go to the standalone log (which is now
polluted with suppressed-gate decisions — by design, but the warning makes it
visible). This is the "we support it but don't recommend it" path.

## Cleanup

```bash
rm -f /tmp/cj-pipeline-suppress-smoke-*.jsonl
# If you hand-padded the telemetry file, restore it
```

No persistent artifacts created.
