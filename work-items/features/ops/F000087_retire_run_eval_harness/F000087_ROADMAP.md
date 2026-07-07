---
type: roadmap
parent: F000087
title: "Retire the paid run-eval harness — keep the eval cases as in-session verify specs + the Check 28 gate (Testing roadmap Phase 0) — Roadmap"
date: 2026-07-06
author: chang
status: Draft
---

<!-- A feature's roll-up roadmap — merges what was previously in feature-summary
     + milestones. Captures scope/non-goals (the feature's identity), decomposition
     (which user-stories carry the work), and delivery timeline (when each piece
     ships). The /CJ_personal-workflow templates step produces this. -->

## Scope

Retire the paid `run-eval` harness (Phase 0 of the Testing roadmap saga): delete
`scripts/eval.sh` (the `tier: paid` runner that spawned a headless
`claude --print` per eval case) and remove its `run-eval` `runners:` row, replacing
metered model spend with in-session Claude verification ($0 marginal on the
subscription). KEEP everything durable: the `behaviors:`/`behavior_coverage:`
(`level: workflow`) axis, the `suite-eval` unit (re-anchored onto the
`tests/eval/` specs), the `tests/eval/<skill>/<case>/{prompt.md,expected.schema.json,fixture}`
dirs, and `validate.sh` Check 28. Also remove the two thin `goal-task-eval` +
`goal-feature-eval` `categories:` rows + their front-door docs, drop `cj-goal-eval`
from the unenrolled-topics prose, de-leak the eval prompts (preserving the Check 28
anchor strings), and regenerate the catalogs.

## Non-Goals

- Adding a new `/CJ_verify` skill or any wrapper — verification is an in-session ask; the durable value lives in the specs
- Phase 2 of the roadmap (promoting `defect` + `todo_fix` to first-class `categories: workflow` rows) — deferred; flagged in TODOS
- Editing CHANGELOG history; CLAUDE.md prose freshness is advisory (on-demand audit)
- Any change to the `behaviors:`/`behavior_coverage:` axis, the `suite-eval` family membership, the `tests/eval/` case dirs (beyond de-leaking prompts), or Check 28 — all KEPT
- Portability's agentic test or any portability un-enroll — the prerequisite is moot (F000086)

## Success Criteria

- [ ] `scripts/eval.sh` + the `run-eval` `runners:` row are GONE; no dangling `eval.sh` reference remains in scripts/tests/workflows/spec engines
- [ ] `./scripts/validate.sh` GREEN — Check 24 (`suite-eval` re-anchored, no dangling), Check 28 (4/4 orchestrators wired), Check 30 (`--check-topic-contract` exit 0, only advisory notes), Checks 26/27 (catalogs fresh)
- [ ] `/CJ_test_audit` reports NO orphaned eval family
- [ ] Every `tests/eval/<skill>/<case>/prompt.md` is honest + non-leaking (no expected-output); the `behavior_coverage` anchors still match live
- [ ] The full `./scripts/test.sh` suite passes; shellcheck green

## Decomposition

<!-- The user-stories that decompose this feature, with current status. The
     validator does not enforce this list, but it's the canonical map for human
     readers. Status values: Open, In Progress, Closed. -->

| User-Story | Title | Status |
|-----------|-------|--------|
| [S000136](S000136_retire_eval_runner_keep_specs/S000136_TRACKER.md) | Retire the eval runner, keep the specs + Check 28 gate | Open |

## Delivery Timeline

<!-- Forward-looking milestones for this feature. -->

| # | Milestone | Target Date | Status | Owner | Notes | Blocked By |
|---|-----------|-------------|--------|-------|-------|------------|
| 1 | Ship S000136 (delete eval.sh + sweep callers, overlay edits, doc-spec + front-door doc removal, prompt de-leak, catalog regen) | — | Not Started | chang | One coherent PR; implementation order per DESIGN | — |
| 2 | End-to-end pipeline run (validate.sh incl. Checks 24/26/27/28/30 + --check-structure, test.sh, shellcheck) | — | Not Started | chang | QA phase; success criteria above | #1 |

### Delivery History

<!-- Backward-looking record: PR links, merge dates, version bumps after ship. -->

- 2026-07-06: Feature scaffolded from the APPROVED /office-hours design doc (chang-claude-vigorous-mcclintock-e72fcb-design-20260706-165302.md).

## Dependency Graph

<!-- Visual representation of milestone ordering. -->

```
#1 Ship S000136 (delete eval.sh + sweep, overlay + doc-spec edits,
        front-door doc removal, prompt de-leak, catalog regen)
        |
        v
#2 End-to-end pipeline run (validate.sh Checks 24/26/27/28/30 +
        --check-structure / test.sh / shellcheck / --check-topic-contract)
        |
        v
(follow-up, roadmap Phase 2) revisit whether any cj-goal categories:
workflow rows are wanted, or the behaviors:/Check 28 axis is the sole gate
```

## Open Questions

<!-- Questions still being decided. -->

| Question | Next check |
|----------|-----------|
| Phase 2 ripple: does the roadmap still want `defect` + `todo_fix` as first-class `categories: workflow` rows now that `feature`+`task`'s rows are removed, or is `behaviors:`/Check 28 the sole workflow gate? | Flag in TODOS; revisit in Phase 2 — out of scope for this build |
| Does removing the two `categories:` rows leave a required `tests/workflow/local-hook/` subfolder empty? | `test-spec.sh --check-structure` in QA — doc-sync + e2e-local remain in that category/layer pair |
