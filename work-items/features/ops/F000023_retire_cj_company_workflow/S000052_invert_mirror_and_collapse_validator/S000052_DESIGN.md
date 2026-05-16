---
type: design
parent: S000052
title: "Invert mirror and collapse validator — Story Design"
version: 1
status: Draft
date: 2026-05-15
author: chjiang
reviewers: []
---

<!-- A story-scope design stub linking to the parent feature's DESIGN.md for
     full context. Section completeness is enforced by /CJ_personal-workflow check;
     each section gets at least a brief sentence even when content largely lives
     upstream. -->

## Problem

`scripts/validate.sh` Error check 10 enforces byte-identity between `deprecated/CJ_company-workflow/` and `work-copilot/` via a MIRROR_SPECS loop (7 entries, multiple shape handlers). That enforcement is the only thing keeping `deprecated/CJ_company-workflow/` alive in the repo. To retire the deprecated skill (F000023), this enforcement must come out first — but the Copilot bundle's `work-copilot/` content still needs to be guarded against accidental deletion. The validator must therefore be rewritten to enforce existence-only against `work-copilot/` as the canonical source.

## Shape of the solution

Delete `validate.sh` Error check 10's MIRROR_SPECS array, its loop, its four shape handlers (`flat`/`recursive`/`single`/`manifest`), and its orphan-policy handlers. Extend Error check 10b's `EXPECTED_BUNDLE_FILES` array (today covers F000015's bundle-only files) to also cover the 7 paths that MIRROR_SPECS previously enforced — templates, WORKFLOW.md, reference/, philosophy/, examples/, fixtures/, copilot-artifact-manifests.json. The result is a single existence-only check against `work-copilot/`. See parent F000023's [F000023_DESIGN.md](../F000023_DESIGN.md) for full feature context.

## Big decisions

| # | Decision | Why |
|---|----------|-----|
| 1 | `EXPECTED_BUNDLE_FILES` shape — flat list extension vs directory-shape enumerator | Deferred to the implementer at write time. Flat: ~61 entries, mechanical, easy to grep. Enumerator: smaller diff, requires a small helper. Both valid; pick on legibility. |
| 2 | Verify byte-identity ONE MORE TIME before deleting Error check 10 | Run `./scripts/validate.sh` first; only proceed with the rewrite if it PASSes. Insurance: catches a hand-edited drift in `work-copilot/` that would otherwise be silently locked in by removing the cross-check. |
| 3 | No changes to `scripts/copilot-deploy.py`, `work-copilot/` content, or any other file | Single-file diff (`scripts/validate.sh`) keeps S000052 small and reviewable. All filesystem-level cleanup (delete `deprecated/CJ_company-workflow/`, drop catalog entry, prune test.sh, update docs) lives in S000053. |

## Risks & open questions

| Risk / Question | Next check |
|-----------------|-----------|
| Removing Error check 10 silently masks a pre-existing byte drift in `work-copilot/` | Big decision #2 — final `./scripts/validate.sh` run before any edit. |
| F000015 bundle-only files lose coverage if the array refactor misses them | Acceptance criterion in TRACKER — explicit verification that `work-copilot/prompts/*.prompt.md` and `work-copilot/domain/*.template.md` remain in the expanded check. |
| Error-check numbering becomes inconsistent if 10 is removed but 11+ stay numbered | Validator implementer adjusts section headers as part of the rewrite. |
| `EXPECTED_BUNDLE_FILES` shape choice — flat vs enumerator | Implementer picks at write time; both are valid (Big Decision #1). |

## Definition of done

- [ ] `./scripts/validate.sh` PASSes before any edit (byte-identity baseline confirmed).
- [ ] Error check 10 + MIRROR_SPECS + shape handlers + orphan-policy handlers deleted from `scripts/validate.sh`.
- [ ] Error check 10b's `EXPECTED_BUNDLE_FILES` extended to cover the 7 previously-mirrored paths and all their leaf files.
- [ ] All F000015 bundle-only files remain covered (`work-copilot/prompts/*.prompt.md`, `work-copilot/domain/*.template.md`).
- [ ] `./scripts/validate.sh` PASSes after the rewrite.
- [ ] Diff is limited to `scripts/validate.sh` only — no other files touched.

## Not in scope

- Deleting `deprecated/CJ_company-workflow/` — that lives in S000053.
- Removing the `CJ_company-workflow` catalog entry — that lives in S000053.
- Updating `scripts/test.sh`, `CLAUDE.md`, `README.md`, `template-registry.json` — all in S000053.
- Renaming `copilot-artifact-manifests.json` — already at its canonical name; the upstream `company-artifact-manifests.json` disappears with S000053's `deprecated/` delete.

## Pointers

- Parent tracker: [S000052_TRACKER.md](S000052_TRACKER.md)
- SPEC: [S000052_SPEC.md](S000052_SPEC.md)
- TEST-SPEC: [S000052_TEST-SPEC.md](S000052_TEST-SPEC.md)
- Parent feature DESIGN: [../F000023_DESIGN.md](../F000023_DESIGN.md)
- Parent feature ROADMAP: [../F000023_ROADMAP.md](../F000023_ROADMAP.md)
