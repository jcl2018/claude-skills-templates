# test-run report — 20260701T120000Z
Aggregate: pass
Flags:     (default)
HEAD:      7d01a5c
Host:      posix

## Runners
| id | command | tier | rc | outcome | covered families | units | duration |
|----|---------|------|----|---------|------------------|-------|----------|
| run-test-sh | `bash scripts/test.sh` | free | 0 | pass | validate test test-deploy eval windows-smoke | 77 | 214s |
| run-e2e-local | `CJ_E2E_LOCAL=1 bash scripts/e2e-local.sh` | local-only | — | skipped(tier-not-selected) | test | 44 | n/a |

## Runner-less families (by design — not skipped)
| family | status |
|--------|--------|
| ci | ci-only (runs on GitHub) |
| hook | hook-check: pass (installed pre-commit hook present) |

## Legend
outcome pass/fail = the runner executed (rc derived). skipped(<reason>) = not executed
(tier-not-selected / platform / self-gated). all-skipped aggregate is NEVER rendered pass.

<!--
This is a COMMITTED SAMPLE (the only tracked file under tests/test-run/reports/;
the rest is gitignored). It shows the shape a real run emits so the format is
reviewable in a PR. A real report's outcome column is DERIVED from each runner's
captured rc + output: a runner not executed renders skipped(<named reason>),
never a false pass; an all-skipped aggregate is never rendered `pass`. Each run
also writes a machine-readable .json ledger sibling (schema: 1, timestamp, HEAD
SHA, repo root, flags, aggregate, per-runner rows). Regenerate a real one:
  bash scripts/test-run.sh            # free tier
  bash scripts/test-run.sh --all      # every tier
-->
