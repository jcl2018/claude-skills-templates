# Test: `test-deploy` (`CI-push` category)

<!-- The authoritative per-test front door (What it is / How to run / Explanation).
     Seeded by /CJ_test_audit from the spec/test-spec-custom.md categories: axis;
     filled by hand. The audit seeds this only when absent (idempotent; present =>
     skip), so edits are safe. -->

| Field | Value |
|-------|-------|
| Name | `test-deploy` |
| Category | `CI-push` |
| Command | `bash scripts/test-deploy.sh` |
| Tier | `free` |

## What it is

The `skills-deploy` end-to-end suite. It runs `install` / `remove` / `relink` /
`doctor` plus drift detection in isolated temp dirs, verifying the deploy tool
correctly installs, removes, and re-links skills, templates, and rules — the
POSIX-host push-cadence run.

## How to run

```bash
bash scripts/test-deploy.sh
```

Run via the category contract: `/CJ_test_run test-deploy` (single test) or
`/CJ_test_run --category CI-push` (every push-cadence test).

## Explanation

`skills-deploy` is how the workbench installs itself into `~/.claude/`, so a
regression there silently breaks every consumer. This suite exercises the whole
lifecycle in throwaway dirs (never touching the real `~/.claude/`), which is why
it runs on every push. Its Windows-latest sibling runs nightly — see the
`windows-deploy` front door
([docs/tests/CI-nightly/windows-deploy.md](../CI-nightly/windows-deploy.md)). For
the per-unit breakdown, see the units-detail page
[docs/tests/test-deploy.md](../test-deploy.md).
