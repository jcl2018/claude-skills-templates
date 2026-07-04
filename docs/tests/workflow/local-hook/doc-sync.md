# Test: `doc-sync` (`workflow` / `local-hook`)

<!-- SEEDED STUB — the authoritative per-test front door (What it is / How
     to run / Explanation). Seeded by /CJ_test_audit from the
     spec/test-spec-custom.md categories: axis. Safe to edit: the audit seeds
     this only when absent (idempotent; present => skip). Fill each section and
     link the relevant docs/tests/<family>.md units-detail page. -->

| Field | Value |
|-------|-------|
| Name | `doc-sync` |
| Category | `workflow` |
| Layer | `local-hook` |
| Mode | `agentic` |
| Command | `bash scripts/audit-nightly.sh --dry-run` |
| Tier | `paid` |

## What it is

The doc/test-sync audit workflow — exercises the /CJ_doc_audit + /CJ_test_audit logic end to end via the scripts/audit-nightly.sh runner; agentic (claude --print), so it runs on-demand at the local-hook layer and never on the free-tier default.

## How to run

```bash
bash scripts/audit-nightly.sh --dry-run
```

Run via the category contract: `/CJ_test_run doc-sync` (single test),
`/CJ_test_run --category workflow` (the whole category), or
`/CJ_test_run --layer local-hook` (the whole layer).

## Explanation

This test proves the **doc/test-sync audit workflow** runs end to end — the
`/CJ_doc_audit` + `/CJ_test_audit` three-stage audits, driven by the
`scripts/audit-nightly.sh` runner, run on-demand (locally) to file drift to the
`audit-drift` GitHub issue. It no longer runs on a nightly CI schedule (the
scheduled workflow was removed; the runner script stays for on-demand use). It
backs the `workflow-doc-audit-runs` behavior (a `level: integration` behavior —
deliberately NOT `level: workflow`, because `/CJ_doc_audit` is not a `CJ_goal_*`
orchestrator and Check 28 governs only orchestrator ↔ `level: workflow`). The
category `command` is `agentic` (the real run is `claude --print`), so it lives at
the `local-hook` layer and never runs on the free-tier default; the `--dry-run`
form prints the plan (with a model key) or self-gates with a leading `SKIP:` (no
key), spending nothing. A deterministic, no-model sibling guard lives at
`tests/workflow/local-hook/doc-sync.test.sh`.

For the per-unit breakdown of the audit engines this workflow drives, see the
`cj-audit-skills` suite (`tests/cj-audit-skills.test.sh`) — the deterministic
audit-engine assertions behind this front door.
