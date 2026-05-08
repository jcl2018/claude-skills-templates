---
type: design
parent: F000005_deprecated_skill_status
title: "deprecated-skill-status — Feature Design"
version: 1
status: Draft
date: 2026-05-02
author: chjiang
reviewers: []
---

<!-- A feature's cross-story design doc. Captures the PROBLEM, the SHAPE of
     the solution, the BIG DECISIONS with rationale, the RISKS, the
     DEFINITION OF DONE, and out-of-scope boundaries. Story-scope detail
     (PRD/ARCHITECTURE/TEST-SPEC) lives on the nested user-stories — do
     not duplicate it here. For a filled-in example, see
     `work-items/features/F000004_work_copilot/F000004_DESIGN.md`. -->

## Problem

The skill catalog (`skills-catalog.json`) has a `status` field, but it's a vestige: only `generate-readme.sh` reads it (for display), and every entry today is `"active"`. There's no way to say "this skill exists in the repo as upstream truth, but please don't install it on new machines."

The motivating case is `company-workflow`. It's a Claude Code implementation that has been superseded for the user's Windows work machine by the `work-copilot/` GitHub Copilot bundle (F000004, shipped v0.14.0). But `skills/company-workflow/` cannot be deleted: its files are byte-mirrored into `work-copilot/` and enforced via `scripts/validate.sh` Error check 10's `MIRROR_SPECS` array. Today, running `scripts/skills-deploy install` on a fresh machine still installs `company-workflow` into `~/.claude/skills/`, even though the user no longer wants it active there. We need a "keep the source, skip the install" signal.

## Shape of the solution

Three small, additive changes to existing files. No new scripts, no new directories.

| Concern | User-story | Artifact |
|---------|-----------|----------|
| Define `deprecated` as a valid catalog status; teach `skills-deploy` (install/doctor) and `generate-readme.sh` to honor it; add `--include-deprecated` escape hatch | S000012 | [S000012_deprecated_status_semantics/S000012_TRACKER.md](S000012_deprecated_status_semantics/S000012_TRACKER.md) |
| Flip `company-workflow` to `status: deprecated` and verify the new behavior end-to-end on a clean target | T000013 | [S000012_deprecated_status_semantics/T000013_migrate_company_workflow/T000013_TRACKER.md](S000012_deprecated_status_semantics/T000013_migrate_company_workflow/T000013_TRACKER.md) |

The bundle stays whole: the same 3 files (`skills-catalog.json`, `scripts/skills-deploy`, `scripts/generate-readme.sh`) plus the `company-workflow` catalog entry, all shipping in one PR.

## Big decisions

| # | Decision | Why |
|---|----------|-----|
| 1 | Default install behavior is **warn-but-skip** for deprecated skills (not silent-skip, not warn-and-install) | Silent-skip lets a deprecation slip past you when bootstrapping a new machine. Warn-and-install defeats the purpose. Warn-but-skip surfaces the state and forces an explicit `--include-deprecated` opt-in. |
| 2 | Escape hatch is `--include-deprecated` (boolean flag, install-time) — not a per-skill `--include=company-workflow` allow-list | Keeps the install command simple. If a user really wants a deprecated skill they'll usually want all of them (the case is rare). Per-skill granularity can be added later if a real need shows up. |
| 3 | `doctor` reports deprecated skills as INFO, not WARN | A deprecated-and-not-installed skill is the *expected* state, not a problem. WARN would create alert fatigue and train users to ignore the doctor output. INFO surfaces it without crying wolf. |
| 4 | `remove` does not special-case deprecated state | Removing a previously-installed deprecated skill is just a regular remove. No extra prompts, no extra annotations — the user already opted in to install via `--include-deprecated`, so they own the lifecycle. |
| 5 | README rendering: separate "Deprecated" section under the main skills table (not hidden, not interleaved) | A reader scanning the README needs to see at a glance that a skill exists but isn't recommended. Hiding deprecated entries makes the catalog look smaller than it is and obscures the migration story. Interleaving is noisy. A short trailing section with a one-line "why deprecated" pointer is the calmest UX. |
| 6 | Status is a string enum on the catalog entry, not a per-file annotation | The catalog is already the routing source of truth (`skills-deploy` reads it, `generate-readme.sh` reads it). Adding a second source (frontmatter banner in SKILL.md) would create drift. Keep one canonical signal. |
| 7 | `validate.sh` enum extended to `{active, experimental, deprecated}` (whatever it currently checks) — not loosened to "any string" | We want a typo (`status: depricated`) to fail validation, not silently behave like a missing status. Closed enum is cheap to maintain. |

## Risks & open questions

<!-- What could go wrong, and what's still undecided. Each row should
     have a "Next check" naming who/when resolves it — otherwise it
     will rot. -->

| Risk / Question | Next check |
|-----------------|-----------|
| `validate.sh` may not currently enforce a `status` enum at all — if it doesn't, the change might be a no-op or might require introducing the check | Resolved during S000012 ARCHITECTURE phase: read `validate.sh` and decide whether to extend an existing check or add a new one |
| The `--include-deprecated` flag must be parseable wherever today's flag-parsing lives in `skills-deploy` (bash `getopts` vs. ad-hoc `case` — TBD) | Resolved during S000012 ARCHITECTURE — read the script's current flag handling first |
| README rendering change might churn the file (line additions/deletions) and trigger spurious diffs in unrelated PRs until baselined | Land the README regeneration in the same PR as the code change so the baseline updates atomically |
| Some downstream consumer (a script, a doc) might `grep` for `"company-workflow"` in `skills-catalog.json` and assume `"active"` — flipping to `"deprecated"` could surface latent assumptions | T000013 verification: `./scripts/test.sh` end-to-end on the feature branch is the canary |
| If a user has `~/.claude/skills/company-workflow/` already installed (pre-this-feature) and runs the new `install`, today's behavior is "no-op (already installed)" — confirm that doesn't change unexpectedly | T000013 test-plan includes this as a verification case |

## Definition of done

- [ ] `skills-catalog.json` documents `deprecated` in its schema commentary (if any) and contains at least one entry with `status: deprecated` (`company-workflow`)
- [ ] `scripts/skills-deploy install` on a clean target with `company-workflow` deprecated does not create `~/.claude/skills/company-workflow/` and prints exactly one warning line for it
- [ ] `scripts/skills-deploy install --include-deprecated` on a clean target installs `company-workflow` and reports it identically to an active skill
- [ ] `scripts/skills-deploy doctor` reports deprecated skills under INFO, not WARN
- [ ] `scripts/validate.sh` accepts `deprecated` in the status field (no false errors); rejects typos like `depricated`
- [ ] `scripts/generate-readme.sh` produces a "Deprecated" section in the rendered README
- [ ] `./scripts/test.sh` passes
- [ ] PR shipped and merged via `/ship` + `/land-and-deploy`

## Not in scope

<!-- Explicit non-goals. Prevents scope creep and gives reviewers an
     unambiguous boundary. -->

- Deleting `skills/company-workflow/` from the repo — `work-copilot/` byte-mirrors it; deprecation only affects install/visibility.
- Adding an `archived` tier beyond `deprecated` — premature; can be added if `deprecated` proves too coarse.
- Dependency-graph-aware deprecation (warning if an active skill depends on a deprecated one) — no current skill depends on another skill.
- Auto-uninstalling already-installed deprecated skills — too aggressive; users own the lifecycle via `skills-deploy remove`.
- In-skill banners (modifying `SKILL.md` frontmatter to mark deprecated) — keep one canonical signal in the catalog; revisit only if a Copilot/Claude UX gap shows up.
- Per-user / per-machine deprecation profiles — global only.

## Pointers

- Parent tracker: [F000005_TRACKER.md](F000005_TRACKER.md)
- Roadmap: [F000005_ROADMAP.md](F000005_ROADMAP.md)
- Sibling feature that motivates the deprecation: [F000004_work_copilot](../F000004_work_copilot/F000004_TRACKER.md) — the Copilot bundle that supersedes `company-workflow` on the Windows work machine
- Relevant scripts: `scripts/skills-deploy`, `scripts/validate.sh`, `scripts/generate-readme.sh`
- Relevant catalog: `skills-catalog.json`
