# /personal-pipeline fixtures

Four fixtures cover the pipeline's design failure modes plus one happy path.
Each is a README stub documenting setup steps; fully-self-contained test
artifacts are deferred to v2 (would balloon the skill's surface).

## Cases

| Case | Tests | Expected end_state |
|---|---|---|
| `example-design-doc/` | Happy path: clean-slate design doc → full pipeline green | `green` |
| `regression-pre-scaffold-idempotency/` | Step 2 branch (a): footer present, dir exists, re-run reuses | `green` (Phase 1 skipped) |
| `regression-partial-write-halt/` | Step 2 branch (c): footer absent, partial dir references design | `halted_at_gate` (no Phase 1 dispatch) |
| `regression-broken-validate/` | Step 6 post-implement gate: validate.sh failure halts before Phase 3 | `halted_at_gate` |

## How to use

Each case's README documents:
- The setup commands (touch + write the necessary preconditions)
- The orchestrator invocation
- The expected stdout + tracker state + telemetry line

Manual workflow (no auto-runner in v1):

```bash
cd <fixture-dir>
cat README.md           # read the setup
# ...follow setup steps...
/personal-pipeline <fixture-design-doc>
# ...inspect the result against expected outcome in README...
# Cleanup: documented at end of each README
```

## Coverage gaps (intentional, v1 scope)

- **Multi-story feature dispatch.** Step 4's halt-after-scaffold for ≥1-child features. No fixture; first multi-story feature post-v1 will exercise the path.
- **Subagent crash mid-phase.** Hard to inject deterministically. Re-run pattern is the test.
- **Sunset checkpoint AUQ.** Requires 6 real invocations; deferred to first real-run encounter.
- **Sensitive-surface pre-scan miss + ESCALATION_NEEDED.** Conditional path — only exercised when SPEC has a sensitive surface the regex doesn't catch. Fix at first miss.

## Adding a fixture

1. Create `fixtures/<case-name>/`
2. Write a `README.md` documenting setup + invocation + expected outcome (mirror the existing case structure)
3. Add a row to the table above
4. If the case adds a new dependency (e.g., a fake design doc, a partial scaffold dir), include the synthetic artifacts under the case dir alongside the README
