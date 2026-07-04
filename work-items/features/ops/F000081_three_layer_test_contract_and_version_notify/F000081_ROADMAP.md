---
type: roadmap
parent: F000081
title: "Three-layer test contract per category + portability reclass + git version-notification + retire CJ_portability-audit — Roadmap"
date: 2026-07-04
author: Charlie Jiang
status: Draft
---

<!-- A feature's roll-up roadmap — merges what was previously in feature-summary
     + milestones. Captures scope/non-goals (the feature's identity), decomposition
     (which user-stories carry the work), and delivery timeline (when each piece
     ships). The /CJ_personal-workflow templates step produces this. -->

## Scope

Complete the F000078 two-axis test contract along five reinforcing seams and land them as
one PR: (1) give every test category a self-describing three-level home — CI-push (quick
deterministic), CI-nightly (large deterministic), local-hook (quick agentic) — with an
ADVISORY per-category × 3-layer coverage matrix that reports gaps but never gates;
(2) reclassify the two portability harness tests from `workflow` to `infra` and backfill
portability's missing local-hook level; (3) make the version-notification checkout-independent
via `git ls-remote` so remote/foreign-repo installs finally get a "you're out of date"
nudge; (4) add a nightly full-suite CI workflow + a targeted-negative-test refactor that
kills the ~16× re-run OOM flake (safe-additive — the per-PR `validate.yml` trim is a
deferred follow-up); and (5) retire the now-redundant `/CJ_portability-audit` verb while
keeping its engine + Check 18.

## Non-Goals

- Trimming `validate.yml`'s per-PR coverage + the matching `layer` reclass to `CI-nightly` — deferred to a separate attended work-item; an autonomous PR-stop can't verify a trimmed gate.
- A truly agentic portability local-hook variant — deferred; the local-hook cell is backfilled deterministically (a stubbed-remote local sandbox), which the advisory matrix permits.
- Touching the `CJ_portability-audit` catalog `portability` tier or Check 18 — only the two `categories:` TEST rows are reclassified; the engine + its per-PR lint stay.
- Migrating any existing flat `tests/*.test.sh` files under `tests/<category>/<layer>/` — `test`-family units stay at root; category cells use command-only rows.
- Changing the version-check cache TTL or any per-skill preamble — the existing cache/snooze/skip machinery is reused unchanged and the rework is internal to `skills-update-check`.

## Success Criteria

<!-- Bulleted, measurable outcomes. -->

- [ ] `test-spec.sh --seed` stays byte-identical to the edited `spec/test-spec.md`; `--check-structure` prints the per-category × 3-layer matrix + advisory `NOTE:`s and exits 0.
- [ ] Portability rows read `category: infra`; the four front-door docs live under `docs/tests/infra/…`; `spec/doc-spec.md` updated; Checks 15a/16/26/27 green; the `portability-version-check` (infra/local-hook) command-row exists.
- [ ] `skills-update-check`, given a `.source`-absent manifest + a stubbed ls-remote, emits `SKILLS_UPGRADE_AVAILABLE` when remote > local, silent when equal, fail-soft when unreachable — proven by the new root `tests/skills-update-check.test.sh` (Check 24 green).
- [ ] `nightly.yml` exists + is registered as a `ci` unit (Check 24 green); negative tests are targeted; full `test.sh` + full `validate.sh` green; `validate.yml` is UNTRIMMED this feature.
- [ ] `/CJ_portability-audit` is gone (catalog / dir / routing / workflow-spec / philosophy) with the engine + Check 18 intact; whole `validate.sh` green.
- [ ] VERSION bumped; README + generated catalogs regenerated; the deferred `validate.yml`-trim follow-up work-item is filed.

## Decomposition

<!-- The user-stories that decompose this feature, with current status. -->

| User-Story | Title | Status |
|-----------|-------|--------|
| [S000131](S000131_three_layer_contract_portability_infra_version_notify/S000131_TRACKER.md) | Three-layer contract + advisory matrix + portability→infra reclass + git ls-remote version-notification + safe-additive CI + retire /CJ_portability-audit | Open |

## Delivery Timeline

<!-- Forward-looking milestones for this feature. -->

| # | Milestone | Target Date | Status | Owner | Notes | Blocked By |
|---|-----------|-------------|--------|-------|-------|------------|
| 1 | WS1 — contract prose + seed lockstep + advisory matrix + fixture tests | — | Not Started | Charlie Jiang | The foundation; the seed byte-identity is the single most fragile edit | — |
| 2 | WS3 — `skills-update-check` git-ls-remote rework + the root unit test | — | Not Started | Charlie Jiang | The local-hook cell WS2 points at | #1 |
| 3 | WS2 — portability reclass + doc moves (+ doc-spec rows) + the local-hook command-row (+ optional Check-18 row) | — | Not Started | Charlie Jiang | Command-only rows ⇒ no folder move | #1, #2 |
| 4 | WS5 — retire /CJ_portability-audit (all consistency touchpoints) + CHANGELOG | — | Not Started | Charlie Jiang | Mirror the /CJ_repo-init retirement; keep engine + Check 18 | #3 |
| 5 | WS4 — nightly workflow + register the `ci` unit + the targeted-negative-test refactor (defer the trim) | — | Not Started | Charlie Jiang | Both verifiable in-PR | #1 |
| 6 | Regenerate catalogs/README, bump VERSION, `/ship` to a PR (STOP — human review) | — | Not Started | Charlie Jiang | The CI + skill-retirement surfaces especially want scrutiny | #4, #5 |
| 7 | End-to-end pipeline run — whole `validate.sh` + full `test.sh` + shellcheck green | — | Not Started | Charlie Jiang | The full green gate before PR | #6 |

### Delivery History

<!-- Backward-looking record: PR links, merge dates, version bumps after ship. -->

- 2026-07-04: Scaffolded from the APPROVED /office-hours design doc.

## Dependency Graph

<!-- Visual representation of milestone ordering. -->

```
#1 WS1 contract + seed + advisory matrix
      |
      +--> #2 WS3 skills-update-check git-ls-remote + root test
      |         |
      |         +--> #3 WS2 portability reclass + doc moves + local-hook command-row
      |                    |
      |                    +--> #4 WS5 retire /CJ_portability-audit + CHANGELOG
      |                                       |
      +--> #5 WS4 nightly.yml + ci unit + negative-test refactor
                                              |
                    #4, #5 --> #6 regenerate + VERSION + /ship (PR-stop) --> #7 full green gate
```

## Open Questions

<!-- Questions still being decided. -->

| Question | Next check |
|----------|-----------|
| Portability's local-hook mode: the backfill fills it DETERMINISTICALLY (a stubbed-remote local sandbox); the canonical level is "quick agentic". Is the deterministic fill sufficient for this increment? | Settled by Q1 (advisory matrix permits it); a truly agentic variant is a noted deferred follow-up. Confirm during implement. |
| `v`-tag assumption for ls-remote: WS3 reads the latest release `v<X.Y.Z>` tag; a consumer repo that doesn't tag releases fail-softs to silent. | Accepted per Q2 (no false nudge); holds today (v-tags ratcheted by Error check 8). Note the assumption in the script. |
| Exact backing/scope of the deferred `validate.yml`-trim follow-up (which units reclass to `CI-nightly`, how the trimmed gate is attended-verified). | Filed as a separate work-item at ship; resolved when that attended change is planned. |
