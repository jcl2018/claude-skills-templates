---
type: roadmap
parent: F000080
title: "Make CI-nightly deterministic — delete the agentic evals + doc-sync audit, re-layer to local-hook — Roadmap"
date: 2026-07-03
author: Charlie Jiang
status: Draft
---

<!-- A feature's roll-up roadmap — captures scope/non-goals (the feature's identity),
     decomposition (which user-stories carry the work), and delivery timeline
     (when each piece ships). -->

## Scope

Make the `CI-nightly` verification layer deterministic-only: delete the two agentic
cron wrappers (`.github/workflows/eval-nightly.yml` and `audit-nightly.yml`) so nothing
on a schedule burns model tokens, and re-layer the three agentic tests they drove
(`goal-task-eval`, `goal-feature-eval`, `doc-sync`) from `CI-nightly` to `local-hook`
where they run on-demand. Keep the underlying scripts (`scripts/eval.sh`,
`scripts/audit-nightly.sh`) as local runners. Because the deleted `audit-nightly.yml`
was the job that auto-caught semantic prose drift, do the full honest prose sweep
("nightly in CI via audit-nightly.yml" → "on-demand locally") in the same PR so no doc
claims a nightly job that no longer exists. After this change the only scheduled
workflow is the deterministic `windows-nightly.yml` (`portability-deploy`).

## Non-Goals

<!-- Explicit non-goals. Things this feature deliberately does NOT do, and why. -->

- Deleting or rewriting `scripts/eval.sh` / `scripts/audit-nightly.sh` — KEPT as on-demand/local runners; only the cron wrappers are deleted.
- Removing the `test-audit-nightly` regression test — anchored on the script, not the workflow; STAYS.
- Adding a deterministic model-free nightly heartbeat (Approach C) — deliberately rejected as near-redundant with the per-PR gate.
- Changing the per-PR deterministic gate (`validate.sh` / `validate.yml` / pre-commit hook) — UNCHANGED; still blocks a broken contract on every PR.
- Re-enabling an agentic (or split doc/test) nightly — a possible future follow-up, not this feature.

## Success Criteria

<!-- Bulleted, measurable outcomes. Each criterion should be observable from
     the outside — not internal code state. -->

- [ ] `.github/workflows/eval-nightly.yml` and `audit-nightly.yml` no longer exist; `ls .github/workflows/*nightly*.yml` shows only `windows-nightly.yml`.
- [ ] `spec/test-spec-custom.md` declares `goal-task-eval` / `goal-feature-eval` / `doc-sync` at `layer: local-hook`; the `ci-eval-nightly` / `ci-audit-nightly` units are gone.
- [ ] The 3 front-door docs live under `docs/tests/workflow/local-hook/`; `docs/tests/index.md` + `spec/doc-spec-custom.md` agree with disk.
- [ ] `grep -r "nightly in CI"` (and the "audit-nightly.yml" nightly framing) returns no claim of a nightly-CI audit/eval that no longer runs.
- [ ] `./scripts/validate.sh` and `./scripts/test.sh` GREEN; `test-spec.sh --check-structure` findings=0; Check 28 passes (orchestrators=4, behaviors=4).

## Decomposition

<!-- The user-stories that decompose this feature, with current status. -->

| User-Story | Title | Status |
|-----------|-------|--------|
| [S000130](S000130_delete_agentic_nightly_re_layer_local_hook/S000130_TRACKER.md) | Delete agentic cron wrappers + re-layer the 3 tests to local-hook + prose sweep | Open |

## Delivery Timeline

<!-- Forward-looking milestones for this feature. -->

| # | Milestone | Target Date | Status | Owner | Notes | Blocked By |
|---|-----------|-------------|--------|-------|-------|------------|
| 1 | Ship S000130 — the 7-part file set (delete wrappers, re-layer rows, move docs, fix index + doc-spec, prose sweep, regenerate + validate) | — | Not Started | Charlie Jiang | Single cohesive change; validate.sh + test.sh green | — |
| 2 | End-to-end pipeline run — QA (DEFER_AUDIT), deterministic doc-regen (Step 5.5), `/ship` → PR | — | Not Started | Charlie Jiang | PR is the review/architecture gate | 1 |

### Delivery History

<!-- Backward-looking record: PR links, merge dates, version bumps after ship. Append-only. -->

- (none yet)

## Dependency Graph

<!-- Visual representation of milestone ordering. -->

```
#1 Ship S000130 (delete wrappers + re-layer + prose sweep) --> #2 End-to-end pipeline run (QA + doc-regen + /ship -> PR)
```

## Open Questions

<!-- Questions still being decided. -->

| Question | Next check |
|----------|-----------|
| Does any single `CJ_goal_*` SKILL.md/pipeline.md/USAGE.md prose rewrite balloon the diff enough to split to a follow-up TODO? | Decided during S000130 implement; default is the full sweep in this PR. |
| Track re-enabling an agentic (or split doc/test) nightly later as a TODOS row? | Operator decision post-merge; not required for this PR (related "split audit-nightly into doc/test workflows" idea already in TODOS). |
