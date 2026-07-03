---
type: roadmap
parent: F000076
title: "QA-gate slimming — relocate the agent-judged audit to CI-nightly — Roadmap"
date: 2026-07-03
author: chang
status: Draft
---

<!-- A feature's roll-up roadmap. Captures scope/non-goals (identity),
     decomposition (which user-stories carry the work), and delivery timeline. -->

## Scope

Remove the inline agent-judged post-sync audit (Step 5.6) + the QA-audit
checkpoint (Step 3.4/4.5/8.5) from all four `CJ_goal_*` orchestrator paths, and
relocate the audit to a new CI-nightly Claude job (`.github/workflows/audit-nightly.yml`
+ `scripts/audit-nightly.sh` + `tests/audit-nightly.test.sh`) that sweeps `main`
via `/CJ_doc_audit` + `/CJ_test_audit` and files findings to an `audit-drift`
GitHub issue. `DEFER_AUDIT: true` STAYS as the skip-inline-audit switch. The
deterministic per-PR gate (validate.sh / validate.yml / pre-commit) is untouched;
standalone `/CJ_qa-work-item` + `/CJ_doc_audit` + `/CJ_test_audit` are unchanged.
This is a single atomic multi-file change — all edits land together so the
pre-commit `validate.sh` + CI `test.sh` stay green.

## Non-Goals

- Touching the deterministic per-PR gate (`scripts/validate.sh`, `.github/workflows/validate.yml`, the pre-commit hook) — it stays the hard merge gate.
- Changing standalone `/CJ_qa-work-item`'s inline Step 8.6c/8.6d audit — only the orchestrator-driven `DEFER_AUDIT: true` path changes meaning; `qa.md` gets a prose reword only.
- Touching `/CJ_doc_audit` or `/CJ_test_audit` (the audit verbs) — the nightly job calls them unchanged.
- Removing the `DEFER_AUDIT: true` directive — it is kept and repurposed as the skip-inline switch.
- Removing Step 5.5 doc-sync or the pre-doc-sync commit — only the audit step that followed doc-sync is removed.
- Physically moving test scripts into `tests/<category>/`, cleaning the dormant `qa-audit` arm out of `cj-e2e-gate.sh`, or adding email/Discord notification — deferred follow-up TODOs.

## Success Criteria

- [ ] `grep -rn "halted_at_qa_audit\|qa-audit-declined\|qa-audit-waived"` over the four `skills/CJ_goal_*/` dirs returns nothing (the inline audit + checkpoint are gone).
- [ ] `.github/workflows/audit-nightly.yml` + `scripts/audit-nightly.sh` + `tests/audit-nightly.test.sh` exist; `bash scripts/audit-nightly.sh` with no `ANTHROPIC_API_KEY` prints `SKIP` and exits 0.
- [ ] `./scripts/validate.sh` passes (esp. Check 24 gate-marker drift clean, Check 26 test-catalog fresh, Check 27 workflow docs fresh, Check 28 workflow coverage).
- [ ] `./scripts/test.sh` full suite green, incl. the new `tests/audit-nightly.test.sh` + the updated `cj-audit-skills` / `cj-goal-doc-sync-wiring` tests.
- [ ] `shellcheck scripts/audit-nightly.sh` clean.
- [ ] The deterministic per-PR gate + standalone audit verbs still function unchanged.

## Decomposition

<!-- The user-stories that decompose this feature, with current status. -->

| User-Story | Title | Status |
|-----------|-------|--------|
| [S000126](S000126_relocate_audit_to_nightly/S000126_TRACKER.md) | Remove the inline audit + checkpoint from the cj_goal paths and relocate it to a CI-nightly job | Open |

## Delivery Timeline

<!-- Forward-looking milestones. Status: Done, In Progress, Not Started, At Risk, Deferred. -->

| # | Milestone | Target Date | Status | Owner | Notes | Blocked By |
|---|-----------|-------------|--------|-------|-------|------------|
| 1 | Ship S000126 (remove inline audit + checkpoint from the four orchestrators; add the CI-nightly job) | — | Not Started | chang | Single atomic multi-file change | — |
| 2 | End-to-end pipeline run: a cj_goal build's tail is doc-sync → `/ship` with no audit node + full suite green + `audit-nightly.sh` SKIPs without a key | — | Not Started | chang | Success criteria 1-6 verified | #1 |

### Delivery History

<!-- Backward-looking record: PR links, merge dates, version bumps after ship. Append-only. -->

- 2026-07-03: Scaffolded from /office-hours design doc.

## Dependency Graph

<!-- Format: #N description --> #M description (arrow = "blocks"). -->

```
#1 Ship S000126 (remove inline audit + checkpoint; add CI-nightly job) --> #2 E2E: tail is doc-sync -> /ship, suite green, audit-nightly.sh SKIPs w/o key
```

## Open Questions

<!-- Questions still being decided. -->

| Question | Next check |
|----------|-----------|
| None — scope, safety net (deterministic gate + standalone verbs kept), and file inventory are pinned in DESIGN.md + the child SPEC.md + the source design doc's "Implementation surface (blast radius)". | Resolved at scaffold time. |
