---
type: roadmap
parent: F000061
title: "Three-stage audit hardening — engine-backed Stage 1, evidence-forced Stage 2, drift-hunting Stage 3, fresh-context judging, per-stage findings reports — Roadmap"
date: 2026-06-12
author: chjiang
status: Draft
---

<!-- A feature's roll-up roadmap — merges what was previously in feature-summary
     + milestones. Captures scope/non-goals (the feature's identity), decomposition
     (which user-stories carry the work), and delivery timeline (when each piece
     ships). The /CJ_personal-workflow templates step produces this. -->

## Scope

Make the F000060 audit verdicts EARNED: a Stage 1 that cannot be
re-implemented wrong (ONE tested engine call — the NEW
`doc-spec.sh --check-on-disk` subcommand running the six deterministic
conformance checks against the merged registry, with the word-split bug class
designed out), a Stage 2 that quotes what it checked (clause-by-clause
verdicts against each doc's `requirement:` string, citing decisive evidence),
a NEW Stage 3 that names the ground truth it compared against (live-repo
enumeration + per-doc cross-walk for implementation drift), fresh-context
subagent judging for Stages 2+3 on standalone runs (inline inside QA — the
nested-subagent wall, documented honestly), and a report where each stage's
findings are separable at a glance (`STAGE1/2/3_FINDINGS=` + three sections +
grep-able `stageN/` prefixes) — applied to BOTH `/CJ_doc_audit` and
`/CJ_test_audit` symmetrically, with qa.md's AUDIT_FINDINGS template refined
in place and the four cj_goal pipelines untouched.

## Non-Goals

- validate.sh delegation (Approach B — rewiring Checks 15/17/19/20 onto `--check-on-disk`) — deferred to a tracked TODOS row; validate.sh stays out of this diff (D11)
- Any registry schema change or seed change — `--check-on-disk` reads the merged registry; no byte-identity churn
- New `test-spec.sh` subcommands — the test audit's Stage 1 is already engine calls (`--validate` + `--check-coverage`)
- Checkpoint AUQ wiring changes — the four pipelines print the AUDIT_FINDINGS block verbatim already; ZERO edits (verified by grep)
- New test suites — the two existing registered suites are extended instead (no new registration)
- Breaking the F000060 report contract — stage fields and sections are pure additions; `DOC_AUDIT:`/`TEST_AUDIT:`/`FINDINGS=`/`seeded:` keep their meaning

## Success Criteria

- [ ] `bash scripts/doc-spec.sh --check-on-disk` on the clean workbench: every check line PASS, `FINDINGS=0`, exit 0; each of the seven seeded violations in the test battery flips exactly its own `FINDING: stage1/<id>` line + exit 1; registry-absent ⇒ `REGISTRY=absent` + exit 0
- [ ] `/CJ_doc_audit` standalone emits the per-stage report (`STAGE1/2/3_FINDINGS=` + three sections), Stages 2+3 produced by a dispatched fresh-context subagent, `DOC_AUDIT: ok` only when all three counts are 0; same for `/CJ_test_audit` with `UNITS_AUDITED=`
- [ ] Stage 2 verdict lines each cite a clause + evidence (spot-checkable); Stage 3 opens with the ground-truth enumeration line and each drift finding names the delta
- [ ] A deliberately planted drift (fixture workflow doc omitting a catalog skill) produces a `FINDING: stage3/...` naming the missing skill — proven in the extended `cj-audit-skills` battery
- [ ] qa.md's AUDIT_FINDINGS template carries the per-stage shape; the four pipelines need zero edits (verified by grep — they print the block verbatim)
- [ ] `./scripts/validate.sh` PASS (validate.sh itself untouched — Check 24 green with the updated purpose texts); `./scripts/test.sh` PASS; both audits run green end-to-end on the workbench (FINDINGS=0 at all three stages, or honest findings fixed before ship)
- [ ] Catalog descriptions + `doc_requirement` + USAGE.md files current (the registered-doc audit on this run's own QA passes)

## Decomposition

<!-- The user-stories that decompose this feature, with current status. The
     validator does not enforce this list, but it's the canonical map for human
     readers. Status values: Open, In Progress, Closed. -->

| User-Story | Title | Status |
|-----------|-------|--------|
| [S000103](S000103_check_on_disk_engine_and_staged_audits/S000103_TRACKER.md) | `--check-on-disk` Stage-1 engine + three-stage restructure of both audit skills + fresh-context dispatch + per-stage reports (full build, atomic) | Open |

## Delivery Timeline

<!-- Forward-looking milestones for this feature. Owner = primary person responsible.
     Status: Done, In Progress, Not Started, At Risk, Deferred.
     Blocked By = milestone number(s) that must complete first, or "—" if none. -->

| # | Milestone | Target Date | Status | Owner | Notes | Blocked By |
|---|-----------|-------------|--------|-------|-------|------------|
| 1 | Ship S000103 (engine + both skill restructures + qa.md template + docs sweep + extended tests, one PR to the PR-stop) | — | Not Started | chjiang | Single atomic PR; this run's own QA exercises the refined AUDIT_FINDINGS shape | — |
| 2 | End-to-end pipeline run + post-land assignment | — | Not Started | chjiang | After merge + `post-land-sync.sh`: re-run the dogfood (`/CJ_doc_audit` standalone — single engine call, fresh-context Stage 2/3 with cited evidence, per-stage counts), then plant a one-line drift in a scratch worktree and confirm Stage 3 names it | #1 |

### Delivery History

<!-- Backward-looking record: PR links, merge dates, version bumps after ship.
     Append-only. -->

- 2026-06-12: Scaffolded F000061 + S000103 from the APPROVED 2026-06-12 design doc (fresh feature run; the prior F000060 run on this branch shipped as v6.0.65 and is the dependency, not the subject)

## Dependency Graph

<!-- Visual representation of milestone ordering. -->

```
#1 Ship S000103 (--check-on-disk engine + three-stage skills + dispatch + per-stage reports, one PR)
        |
        v
#2 Post-land assignment (dogfood re-run + planted-drift Stage-3 confirmation)
```

## Open Questions

<!-- Questions still being decided. -->

| Question | Next check |
|----------|-----------|
| When does validate.sh converge Checks 15/17/19/20 onto `--check-on-disk` (Approach B)? | Deferred TODOS row added in this PR; revisit after v1 lands |
| May the single fresh-context subagent judge BOTH audits' Stages 2+3 in one dispatch? | Yes when the operator runs both — stated in the design; exact prompt shape decided at implementation against both SKILL.mds |
