---
type: roadmap
parent: F000060
title: "Two-tier audit contract — /CJ_doc_audit + /CJ_test_audit, spec seeds + custom overlays, QA-wired audit checkpoint — Roadmap"
date: 2026-06-12
author: chjiang
status: Draft
---

<!-- A feature's roll-up roadmap — merges what was previously in feature-summary
     + milestones. Captures scope/non-goals (the feature's identity), decomposition
     (which user-stories carry the work), and delivery timeline (when each piece
     ships). The /CJ_personal-workflow templates step produces this. -->

## Scope

Give the operator one keystroke, in ANY repo, to answer "do this repo's docs
follow its doc contract, and do its tests follow its test contract?" — and one
pause inside every cj_goal run where those answers are seen before ship budget
is spent. Delivered as: two standalone audit skills (`/CJ_doc_audit`,
`/CJ_test_audit`); both contracts split into skill-delivered general seeds
(`spec/doc-spec.md`, `spec/test-spec.md`) + optional repo-custom overlays
(`spec/doc-spec-custom.md`, `spec/test-spec-custom.md`); a new
`scripts/test-spec.sh` parser carrying the old deterministic coverage engine
at full parity; four new QA steps (refresh both custom specs, run both
audits); and an always-prompt findings checkpoint in all four cj_goal
pipelines — while the F000059 test-pipeline machinery (registry, parser,
test suite, generated view, check branches) is retired wholesale with every
reference swept.

## Non-Goals

- A generated readable view for the test-spec registry — deferred (TODOS row in this PR); v1 of the new format ships without the old `docs/test-pipeline.md` equivalent
- Concern-taxonomy orientation (old TODOS row 12) — struck as obsolete; re-evaluated against the new format later
- The portability gate false-halt fix — separate open row, not bundled
- Upstream gstack modification — none
- Keeping the old test-pipeline format alive as a compatibility layer — demolition over coexistence (D5.2)

## Success Criteria

- [ ] In a bare temp git repo, `/CJ_doc_audit` seeds `spec/doc-spec.md` (`seeded: yes` + verdict) and `/CJ_test_audit` seeds `spec/test-spec.md`; second runs report `seeded: no` (idempotent); in this workbench both run green (FINDINGS=0)
- [ ] `spec/doc-spec.md` == `doc-spec.sh --seed` byte-for-byte; custom entries live in `spec/doc-spec-custom.md`; merged lists drive Checks 15/17/19/20 + document-release unchanged; Check 23 green
- [ ] Demolition complete: the four retired files gone; no `test-pipeline` grep hit outside CHANGELOG, work-items history, TODOS.md; Check 24 runs `test-spec.sh --check-coverage` green on the migrated registry
- [ ] Coverage parity: a deleted unit row or an unregistered `tests/*.test.sh` flips Check 24 red
- [ ] QA on this feature's own story executes Steps 8.6a–d, returns the extended RESULT + AUDIT_FINDINGS block; all four pipelines carry the checkpoint AUQ + literal `[qa-audit-declined]`; gate-spec row present; Check 22 green
- [ ] This run itself pauses at the new checkpoint — the feature ships through its own gate
- [ ] `./scripts/validate.sh` + `./scripts/test.sh` green; README regenerated; catalog valid; portability audit FINDINGS=0

## Decomposition

<!-- The user-stories that decompose this feature, with current status. The
     validator does not enforce this list, but it's the canonical map for human
     readers. Status values: Open, In Progress, Closed. -->

| User-Story | Title | Status |
|-----------|-------|--------|
| [S000102](S000102_audit_skills_specs_and_qa_checkpoint/S000102_TRACKER.md) | Audit skills + two-tier spec files + QA checkpoint + test-pipeline demolition (full build, atomic) | Open |

## Delivery Timeline

<!-- Forward-looking milestones for this feature. Owner = primary person responsible.
     Status: Done, In Progress, Not Started, At Risk, Deferred.
     Blocked By = milestone number(s) that must complete first, or "—" if none. -->

| # | Milestone | Target Date | Status | Owner | Notes | Blocked By |
|---|-----------|-------------|--------|-------|-------|------------|
| 1 | Ship S000102 (full build through its own QA checkpoint to the PR-stop) | — | Not Started | chjiang | One atomic PR: files + parsers + skills + QA wiring + demolition + sweep + tests; success criterion 6 fires DURING this milestone's QA | — |
| 2 | End-to-end pipeline run + post-land assignment | — | Not Started | chjiang | After merge + `post-land-sync.sh`: run `/CJ_doc_audit` + `/CJ_test_audit` in the portfolio consumer repo (seeds delivered first run, `seeded: no` second run; crash / false hard-halt / re-seed = the bug class to catch) | #1 |

### Delivery History

<!-- Backward-looking record: PR links, merge dates, version bumps after ship.
     Append-only. -->

- 2026-06-12: Scaffolded F000060 + S000102 from the APPROVED 2026-06-12 design doc (supersedes the same-day orchestrator-gate design; IDs reclaimed via cj-id-claim.sh same-branch reuse)

## Dependency Graph

<!-- Visual representation of milestone ordering. -->

```
#1 Ship S000102 (skills + seeds + overlays + parser + QA checkpoint + demolition, one PR)
        |
        v
#2 Post-land assignment (consumer-repo seed delivery + idempotency verification)
```

## Open Questions

<!-- Questions still being decided. -->

| Question | Next check |
|----------|-----------|
| Does the test-spec registry need a generated readable view (old `docs/test-pipeline.md` equivalent)? | Deferred TODOS row in this PR; revisit after v1 lands |
| Where does concern-taxonomy orientation land under the new format? | Old TODOS row 12 struck as obsolete this PR; re-evaluate later |
