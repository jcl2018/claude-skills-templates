---
type: design
parent: S000053
title: "Delete skill and update docs — Story Design"
version: 1
status: Draft
date: 2026-05-15
author: chjiang
reviewers: []
---

<!-- A story-scope design stub linking to the parent feature's DESIGN.md for
     full context. Section completeness is enforced by /CJ_personal-workflow check. -->

## Problem

Once S000052 lands and removes `scripts/validate.sh` Error check 10, `deprecated/CJ_company-workflow/` is officially orphaned — no script depends on it, but it still occupies the repo and the `skills-catalog.json` entry, plus `scripts/test.sh` has ~35 assertions and a T000011 sync-check block that all still reference the deprecated paths. `CLAUDE.md` and `README.md` describe `work-copilot/` as a byte-mirror — language that becomes inaccurate. `template-registry.json` has a stale entry. The workbench operator needs all of this cleaned up so retirement actually completes, not just structurally.

## Shape of the solution

A cleanup-only story that runs after S000052. Delete the directory, remove the catalog entry, prune the coupled `test.sh` blocks (port any structural assertions to `work-copilot/` equivalents), update `CLAUDE.md` and `README.md` to describe `work-copilot/` as self-contained, clean `template-registry.json`, verify `scripts/copilot-deploy.py` and `scripts/skills-deploy` have no surprises, and run the full test suite plus `copilot-deploy.py doctor` to confirm no regressions. See parent F000023's [F000023_DESIGN.md](../F000023_DESIGN.md) for full feature context.

## Big decisions

| # | Decision | Why |
|---|----------|-----|
| 1 | `test.sh` deletes follow Principle 5 (explicit over clever): delete blocks testing gone implementation details; port only structural assertions to `work-copilot/` equivalents | The ~35 assertions and T000011 sync-check synthetic block test internals that will not exist post-retirement. Leaving them as zombies adds noise to test.sh and obscures intent. Structural assertions (template presence, manifest schema parity) still apply to `work-copilot/` and get ported. |
| 2 | Single PR vs sub-split into smaller PRs (catalog-delete, dir-delete, doc-update, test.sh-prune) | Implementer's call at write time. Single PR is the default for an internal-workbench cleanup; sub-split is acceptable if the diff feels large to review. Both produce the same end state. |
| 3 | `template-registry.json`: edit the entry out vs delete the entire file | Implementer's call after verifying no script reads the file. Autoplan review confirmed it's orphaned; either path is safe. Recommendation: delete the file if it has no other live entries; otherwise just remove the CJ_company-workflow entry. |
| 4 | Polish textual references in `check.md` / `implement.md` / `pipeline.md` | Optional; not blocking. These are comparison/documentation mentions with no runtime impact. Implementer can include them in S000053 if convenient; otherwise leave for a later doc-sweep ticket. |

## Risks & open questions

| Risk / Question | Next check |
|-----------------|-----------|
| `scripts/copilot-deploy.py` references `deprecated/CJ_company-workflow/` | Story todo — grep + read the file before the delete. |
| `scripts/skills-deploy install --include-deprecated` mis-handles a missing catalog entry | Story todo — read the code path, verify gracefully no-op behavior. |
| Hidden coupling beyond the autoplan-surfaced list (test.sh, template-registry.json, the design's expected hits) | Story acceptance criterion — pre-implementation grep against the codebase. |
| Ported `test.sh` structural assertions accidentally regress in coverage | Implementer maps each ported assertion to its `work-copilot/` equivalent before deleting the original; documents the mapping in commit message or PR body. |
| `template-registry.json` reader emerges later | Story todo — exhaustive grep before delete. Mitigated: autoplan review confirmed no live readers; design accepts the small residual risk. |

## Definition of done

- [ ] `deprecated/CJ_company-workflow/` no longer exists.
- [ ] `CJ_company-workflow` not in `skills-catalog.json`.
- [ ] `template-registry.json` no longer references CJ_company-workflow.
- [ ] `scripts/test.sh` PASSes; coupled blocks removed; ported assertions verified.
- [ ] `CLAUDE.md` + `README.md` describe `work-copilot/` as self-contained.
- [ ] `./scripts/validate.sh && ./scripts/test.sh && ./scripts/copilot-deploy.py doctor` all PASS.
- [ ] `grep -rn "CJ_company-workflow" .` returns only doc/changelog mentions.

## Not in scope

- The S000052 structural change to `scripts/validate.sh` (lives in S000052; S000053 depends on it).
- Migrating already-deployed Copilot bundles to a new layout — out of scope per parent feature non-goal.
- Deleting `deprecated/` top-level directory or `deprecated/README.md` — kept as convention support.
- Removing the `templates_source` catalog field handling in `scripts/skills-deploy` — kept for future deprecations.
- Removing the `status: deprecated` enum value from `validate.sh` — kept as convention support.

## Pointers

- Parent tracker: [S000053_TRACKER.md](S000053_TRACKER.md)
- SPEC: [S000053_SPEC.md](S000053_SPEC.md)
- TEST-SPEC: [S000053_TEST-SPEC.md](S000053_TEST-SPEC.md)
- Parent feature DESIGN: [../F000023_DESIGN.md](../F000023_DESIGN.md)
- Parent feature ROADMAP: [../F000023_ROADMAP.md](../F000023_ROADMAP.md)
- Blocker: [../S000052_invert_mirror_and_collapse_validator/S000052_TRACKER.md](../S000052_invert_mirror_and_collapse_validator/S000052_TRACKER.md)
