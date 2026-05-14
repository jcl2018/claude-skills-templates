# /CJ_run fixtures

End-to-end wrapper from APPROVED design doc to verified deploy. Fixtures
document manual smoke scenarios — automated runners are deferred (full
end-to-end tests would create real PRs and deploys, which isn't appropriate
for fixture-shaped tests).

## Cases

| Case | Tests | Expected end_state |
|---|---|---|
| `synthetic-approved-design.md` | Happy path: minimal APPROVED design doc → full chain → green deploy | `green` |
| `regression-not-approved/` (TODO) | Pre-flight refuses if doc lacks `Status: APPROVED` | exit 1 (no telemetry write) |
| `regression-multi-story-halt/` (TODO) | Phase 2 returns green w/ multi-story shape → Steps 4-5 skipped | `green` + `multi_story_scaffold_only: true` |

## How to use

Manual workflow (no auto-runner in v1):

```bash
# Pre-flight smoke (refuses cleanly on bad input)
/CJ_run ./skills/CJ_run/fixtures/synthetic-approved-design.md
# Should immediately fail: "design doc must be under ~/.gstack/projects/"

# Real smoke (in a scratch repo, not claude-skills-templates itself —
# you don't want /ship trying to ship a fixture):
cp skills/CJ_run/fixtures/synthetic-approved-design.md \
   ~/.gstack/projects/scratch/test-design-$(date +%s).md
cd /path/to/scratch/repo
/CJ_run ~/.gstack/projects/scratch/test-design-*.md
# Stop manually before /ship creates a real PR (Ctrl-C after /autoplan finishes)
```

## What the synthetic design doc exercises

`synthetic-approved-design.md` is the minimum valid APPROVED design doc:

- `Status: APPROVED` line (Step 1 pre-flight passes)
- One Approaches Considered section + one Recommended Approach (autoplan has
  something to review)
- A Success Criteria section (pipeline has acceptance criteria to write tests
  against)
- Distribution Plan = "Not applicable" (no deploy verification expected)

It is intentionally MINIMAL — autoplan's review will likely find gaps and
surface them at the final-approval AUQ. The point is exercising the wrapper
plumbing, not exercising a deep design.

## Coverage gaps (intentional, v1 scope)

- **Multi-story feature dispatch.** Step 3 Branch (b) handling. No fixture
  yet; will be exercised by the first real multi-story input.
- **Subagent crash mid-pipeline.** Hard to inject deterministically. Re-run
  pattern is the test.
- **Sunset checkpoint AUQ.** Requires 6 real invocations; deferred to first
  real-run encounter.
- **/autoplan abort path.** Manual exercise: invoke on a contrived doc, abort
  at autoplan's final gate, verify `end_state=halted_at_autoplan` in telemetry.
- **/ship abort path.** Manual exercise: invoke real, abort at ship's diff
  review, verify `end_state=halted_at_ship` + commits-not-pushed state.
- **/land-and-deploy canary red.** Requires a real production URL with
  health-check failure. Out of scope for fixtures.

## Adding a fixture

1. Create `fixtures/<case-name>/` (or single file for synthetic-design type)
2. Document setup + invocation + expected outcome
3. Add a row to the table above
4. If the case adds new synthetic artifacts (e.g., a multi-story doc),
   include them under the case dir alongside the README
