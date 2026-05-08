---
type: roadmap
parent: F000005
title: "deprecated-skill-status — Roadmap"
date: 2026-05-02
author: chjiang
status: Draft
---

<!-- Migrated from F000005_feature-summary.md + F000005_milestones.md during
     F000008 v1.5.0 sweep. Section content preserved verbatim from the
     two source files for historical fidelity. The new doc-ROADMAP.md
     template suggests Scope / Non-Goals / Success Criteria / Decomposition
     / Delivery Timeline (with Delivery History sub-section) / Dependency
     Graph / Open Questions; refine over time as needed. -->

<!-- ===== From F000005_feature-summary.md ===== -->

## Scope

Give the `status` field in `skills-catalog.json` real meaning by introducing a `deprecated` value that the deploy tooling honors. Today the field is read only by `generate-readme.sh` for display — `scripts/skills-deploy` ignores it. After this feature: a skill marked `status: deprecated` stays in the repo (so its source remains the truth-of-record for any byte-mirrored bundle, e.g. `work-copilot/`) but `skills-deploy install` skips it by default, prints a one-line warning, and only installs it if the user passes `--include-deprecated`. The first migration target is `company-workflow`, which has been superseded by the GitHub Copilot bundle for the Windows work machine but must stay in-tree as the upstream source the bundle is mirrored from.

## Success Criteria

<!-- Bulleted, measurable outcomes. Each criterion should be observable from
     the outside (a user, an SLO, a stakeholder report) — not internal code
     state. If you can't measure it, it's not a success criterion; it's
     an aspiration. -->

- [ ] On a clean machine, `scripts/skills-deploy install` does NOT create `~/.claude/skills/company-workflow/` after `company-workflow` is flipped to `status: deprecated`
- [ ] Running the same command prints exactly one warning line per deprecated skill (format: `WARN: skipping deprecated skill: <name> (use --include-deprecated to install)`)
- [ ] `scripts/skills-deploy install --include-deprecated` produces a fully-installed `~/.claude/skills/company-workflow/` identical to today's behavior
- [ ] `scripts/skills-deploy doctor` lists deprecated-and-not-installed skills under an INFO line, not a WARN line; deprecated-and-installed skills produce no warning either
- [ ] `scripts/skills-deploy remove` cleans up a deprecated skill if it was previously installed (no special-casing of the deprecated state for removal)
- [ ] README rendered by `scripts/generate-readme.sh` separates active and deprecated skills (or hides deprecated with a count footnote — final shape decided in DESIGN.md)
- [ ] `./scripts/validate.sh` and `./scripts/test.sh` pass on the feature branch with `company-workflow` deprecated
- [ ] The `work-copilot/` byte-mirror invariant (`validate.sh` Error check 10) still holds — deprecating `company-workflow` does not break the mirror, because the source files stay in `skills/company-workflow/`

## Decomposition

<!-- Markdown links to the nested user-story TRACKER files that decompose
     this feature. The validator does not enforce this list, but it's the
     canonical map for human readers. -->

- [S000012 — Deprecated Status Semantics](S000012_deprecated_status_semantics/S000012_TRACKER.md) — define the `deprecated` value, implement install filter + `--include-deprecated` flag, doctor INFO label, README rendering
- [T000013 — Migrate company-workflow](S000012_deprecated_status_semantics/T000013_migrate_company_workflow/T000013_TRACKER.md) — flip `company-workflow` to `status: deprecated`; verify install skips it on a clean target

## Non-Goals

<!-- Explicit non-goals. Things this feature deliberately does NOT do, and
     why. Prevents scope creep during Implement and gives reviewers an
     unambiguous boundary. -->

- Removing `skills/company-workflow/` from the repo — the source files stay because `work-copilot/` byte-mirrors several of them via `validate.sh` Error check 10. Deprecation is a *visibility / install* change, not a deletion.
- An `archived` status (third-tier beyond `deprecated`) — not needed today; can be added later if `deprecated` proves too coarse.
- Dependency-graph-aware deprecation (warn if an active skill depends on a deprecated one) — none of the current skills depend on each other, so this is theoretical.
- Auto-uninstall of a previously-installed deprecated skill on the next `install` run — too aggressive; users decide when to remove via `skills-deploy remove`. We only refuse to *create* it on a clean install.
- Changing the SKILL.md frontmatter of `company-workflow` itself (e.g., adding "DEPRECATED" to the description) — out of scope for this feature; the catalog `status` is the canonical signal. Can be revisited if Copilot/Claude users want an in-skill banner.
- Per-user / per-machine deprecation profiles — global per-catalog only.

<!-- ===== From F000005_milestones.md ===== -->

## Delivery Timeline
<!-- Canonical milestone tracker for this feature. Scrum docs snapshot this table.
     Owner = primary person responsible. Status values: Done, In Progress, Not Started, At Risk, Deferred.
     Blocked By = milestone number(s) that must complete first, or "—" if none.
     This file is the SINGLE SOURCE OF TRUTH. Edit milestones here. -->

| # | Milestone | Target Date | Status | Owner | Notes | Blocked By |
|---|-----------|-------------|--------|-------|-------|------------|
| 1 | Feature scaffolded (F000005 + S000012 + T000013 docs) | 2026-05-02 | Done | chjiang | Track-phase artifacts created on `feat/deprecated-skill-status`; `/personal-workflow check` clean | — |
| 2 | S000012 implementation: catalog schema, install filter, `--include-deprecated`, doctor INFO, README rendering | 2026-05-02 | Done | chjiang | Edits to skills-deploy (install + doctor), validate.sh (Error check 9b), generate-readme.sh, CLAUDE.md | #1 |
| 3 | T000013 migration: flip `company-workflow` to `deprecated`; verify install skips it on clean target | 2026-05-02 | Done | chjiang | Catalog flipped, README regenerated, all 10 regression cases Pass | #2 |
| 4 | `/personal-workflow check` + `./scripts/test.sh` clean on feature branch | 2026-05-02 | Done | chjiang | validate.sh PASS (0 errors / 0 warnings); test.sh PASS (Failures: 0); work-copilot mirror intact | #3 |
| 5 | PR shipped via `/ship`; merged + deployed via `/land-and-deploy` | 2026-05-05 | Not Started | chjiang | Squash-merge per repo CI/CD convention; remote branch deletion via `gh api -X DELETE` if worktree-blocked | #4 |

### Delivery History

<!-- Backward-looking record: PR links, merge dates, version bumps after ship.
     Append-only. Don't edit historical entries — they're the durable record
     of what shipped when. Migrated content has no recorded delivery history
     entries; left empty. -->

- _none recorded at migration time_

## Dependency Graph
<!-- Visual representation of milestone ordering and blocking relationships.
     Update when milestones or dependencies change.
     Format: #N description --> #M description (arrow = "blocks")
     Keep in sync with the Blocked By column above. -->

```
#1 scaffold --> #2 implement S000012 --> #3 migrate company-workflow (T000013) --> #4 validate clean --> #5 ship
```

## Open Questions

<!-- Questions still being decided. Migrated content has no recorded open
     questions; left empty intentionally. -->

| Question | Next check |
|----------|-----------|
| _none recorded at migration time_ | _N/A_ |
