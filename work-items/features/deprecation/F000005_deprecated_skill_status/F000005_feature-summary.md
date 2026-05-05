---
type: feature-summary
parent: F000005_deprecated_skill_status
title: "deprecated-skill-status — Feature Summary"
date: 2026-05-02
author: chjiang
status: Draft
---

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

## Constituent User-Stories

<!-- Markdown links to the nested user-story TRACKER files that decompose
     this feature. The validator does not enforce this list, but it's the
     canonical map for human readers. -->

- [S000012 — Deprecated Status Semantics](S000012_deprecated_status_semantics/S000012_TRACKER.md) — define the `deprecated` value, implement install filter + `--include-deprecated` flag, doctor INFO label, README rendering
- [T000013 — Migrate company-workflow](S000012_deprecated_status_semantics/T000013_migrate_company_workflow/T000013_TRACKER.md) — flip `company-workflow` to `status: deprecated`; verify install skips it on a clean target

## Out-of-Scope

<!-- Explicit non-goals. Things this feature deliberately does NOT do, and
     why. Prevents scope creep during Implement and gives reviewers an
     unambiguous boundary. -->

- Removing `skills/company-workflow/` from the repo — the source files stay because `work-copilot/` byte-mirrors several of them via `validate.sh` Error check 10. Deprecation is a *visibility / install* change, not a deletion.
- An `archived` status (third-tier beyond `deprecated`) — not needed today; can be added later if `deprecated` proves too coarse.
- Dependency-graph-aware deprecation (warn if an active skill depends on a deprecated one) — none of the current skills depend on each other, so this is theoretical.
- Auto-uninstall of a previously-installed deprecated skill on the next `install` run — too aggressive; users decide when to remove via `skills-deploy remove`. We only refuse to *create* it on a clean install.
- Changing the SKILL.md frontmatter of `company-workflow` itself (e.g., adding "DEPRECATED" to the description) — out of scope for this feature; the catalog `status` is the canonical signal. Can be revisited if Copilot/Claude users want an in-skill banner.
- Per-user / per-machine deprecation profiles — global per-catalog only.
