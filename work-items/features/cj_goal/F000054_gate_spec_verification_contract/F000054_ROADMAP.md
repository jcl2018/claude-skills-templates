---
type: roadmap
parent: F000054
title: "gate-spec.md — one human-readable verification contract for all cj_goals — Roadmap"
date: 2026-06-07
author: chjiang
status: Draft
---

<!-- A feature's roll-up roadmap — merges what was previously in feature-summary
     + milestones. Captures scope/non-goals (the feature's identity), decomposition
     (which user-stories carry the work), and delivery timeline (when each piece
     ships). The /CJ_personal-workflow templates step produces this. -->

## Scope

This feature makes the workbench's verification story legible: it introduces ONE
declarative contract — `gate-spec.md` — that answers, top-to-bottom and without
opening a script, "what stops a broken cj_goal change from landing, and at which
layer?" It applies the proven in-repo `doc-spec.md` pattern (a single file that is
both the human-readable map and a machine-parsed `yaml` registry) to the four
verification layers (local-hook / ci / pipeline-gate / ratchet), adds a
`scripts/gate-spec.sh` reader, and adds an advisory `validate.sh` Check 22 that
cross-checks the four cj_goal pipelines against the one registry. It is the third
member of the `doc-spec → permission-policy → gate-spec` family. Delivered as a
single child user-story, PR-stopped for human review.

## Non-Goals

<!-- Explicit non-goals. Things this feature deliberately does NOT do, and why.
     Prevents scope creep during Implement and gives reviewers an unambiguous
     boundary. -->

- **Re-plumbing gate *execution* into a shared runner** (`--run-all-gates`) — explicitly deferred to a future multi-PR epic; gate implementations stay exactly where they are.
- **`--seed` / `--list-for <mode>` reader subcommands** — no v1 consumer; added when an actual caller appears.
- **Flipping Check 22 advisory → strict** — its own follow-up TODO once the registry runs clean across a few real cj_goal builds (Check 21 ratchet precedent).
- **A `skills-catalog.json` entry for `gate-spec.sh`** — it is a root script like `doc-spec.sh` (not a catalog skill); confirm at implement.
- **Downstream-consumer / cross-repo scope** — workbench-only (this repo, macOS + POSIX shell).

## Success Criteria

<!-- Bulleted, measurable outcomes. Each criterion should be observable from
     the outside (a user, an SLO, a stakeholder report) — not internal code
     state. If you can't measure it, it's not a success criterion; it's
     an aspiration. -->

- [ ] `gate-spec.md` exists at root and is self-contained: a reader who has NOT seen the design can answer "what stops a broken cj_goal change from landing, and at which layer?" in under a minute, reading only that file (S000096 ACs).
- [ ] `scripts/gate-spec.sh --validate` exits 0 on the committed registry; `--list-gates` / `--list-layers` emit the right sets (S000096 ACs).
- [ ] The advisory `validate.sh` Check 22 is GREEN on the clean tree and REPORTS a finding when a declared literal marker is removed from the registry or from both of its mode's files (advisory in v1 — a finding prints but does not exit non-zero) (S000096 ACs).
- [ ] The word "gate" is disambiguated in the docs and architecture.md no longer mislabels validate.sh as "the CI gate" without qualification (S000096 ACs).
- [ ] One PR, green on `validate.sh` + `test.sh` + the windows-latest Git-Bash job, PR-stopped for human review; doc-sync + portability green; the PR carries the registered-doc + portability verdicts.

## Decomposition

<!-- The user-stories that decompose this feature, with current status. The
     validator does not enforce this list, but it's the canonical map for human
     readers. Status values: Open, In Progress, Closed. -->

| User-Story | Title | Status |
|-----------|-------|--------|
| [S000096](S000096_gate_spec_contract/S000096_TRACKER.md) | gate-spec.md contract — the doc-spec mirror for gates (declarative contract + reader + advisory conformance check) | Open |

## Delivery Timeline

<!-- Forward-looking milestones for this feature. Owner = primary person responsible.
     Status: Done, In Progress, Not Started, At Risk, Deferred.
     Blocked By = milestone number(s) that must complete first, or "—" if none.
     Forward roadmap entries go here; historical entries (PR links, merge dates
     after ship) move to the ### Delivery History sub-section below. -->

| # | Milestone | Target Date | Status | Owner | Notes | Blocked By |
|---|-----------|-------------|--------|-------|-------|------------|
| 1 | Ship S000096 (gate-spec.md contract) | — | Not Started | chjiang | The single child story. Author `gate-spec.md` (prose map + table + ASCII + yaml registry); write `scripts/gate-spec.sh` (`--validate` / `--list-layers` / `--list-gates`); add advisory `validate.sh` Check 22 (+ parallel `test.sh` fixture); wire docs (doc-spec.md entry, architecture.md section + "CI gate" relabel, philosophy.md §4 pointer, the four pipeline reference lines, CLAUDE.md pointer). | — |
| 2 | End-to-end: gate-spec landed, verification legible | — | Not Started | chjiang | One PR, PR-stopped + green on validate/test/windows; doc-sync + portability green; the "what stops a broken change, at which layer?" question answerable from one file. | 1 |

### Delivery History

<!-- Backward-looking record: PR links, merge dates, version bumps after ship.
     Append-only. Don't edit historical entries — they're the durable record
     of what shipped when. Use this section to absorb any pre-existing
     milestones content during a feature-summary+milestones → ROADMAP migration. -->

- 2026-06-07: Feature scaffolded — TRACKER + DESIGN + ROADMAP + one child user-story (S000096).

## Dependency Graph

<!-- Visual representation of milestone ordering. Format: #N description --> #M
     description (arrow = "blocks"). Keep in sync with the Blocked By column. -->

```
Single-story feature. One child carries all the work.

F000054 (gate-spec.md — one human-readable verification contract for all cj_goals)
   |
   +--> S000096  gate-spec.md contract          [ship #1 — the only story]
   |
   +--> #2 End-to-end: gate-spec landed, verification legible
              ^ blocked by S000096
```

## Open Questions

<!-- Questions still being decided. -->

| Question | Next check |
|----------|-----------|
| Exact gate enumeration — the full `gates[]` list is derived from the four live pipelines at implement time. | Low risk; the marker universe is known (per-mode `markers` map + `enforced_by` escape + `order`). Implement greps each mode's actual markers. |
| Advisory→strict ratchet timing for Check 22. | Land advisory first (Check 21 precedent); a follow-up PR flips it strict once the registry runs clean across a few real cj_goal builds. |
