---
type: roadmap
parent: F000046
title: "Consolidate doc-release required docs into CJ-DOC-RELEASE.md (repo-init prereq) — Roadmap"
date: 2026-06-04
author: chjiang
status: Draft
---

<!-- A feature's roll-up roadmap — scope/non-goals (identity), decomposition
     (which user-stories carry the work), and delivery timeline (when each
     piece ships). -->

## Scope

Consolidate the scattered `/CJ_document-release` "required docs" surface into one
canonical root contract doc, `CJ-DOC-RELEASE.md` (prose), keeping
`cj-document-release.json` as the adjacent machine config, and wire `/CJ_repo-init`
to verify the new doc as a 4th required prerequisite (mirroring its existing
`verify_docrel` / `seed_docrel` / `collect()` / `--fix` slots). The three CLAUDE.md
convention sections are slimmed in their narrative prose to point at the new doc as
the canonical read, while their machine-parsed blocks + heading anchors stay
verbatim and in-place (the CARVE-OUT). Approach A (doc + adjacent JSON), chosen for
the smallest blast radius — config parser, Check 16, and the Step 6.7 awk all
untouched.

## Non-Goals

- `cj-document-release.json` (data) — not modified; it stays the machine sidecar.
- `cj-document-release-config.sh` (parser) + `validate.sh` Check 16 — not touched.
- The Step 6.7 `awk` + its CLAUDE.md anchors in `skills/CJ_document-release/SKILL.md` — not changed (CARVE-OUT; producer keeps reading CLAUDE.md).
- A new hard `validate.sh` check for the doc — presence is a per-repo prerequisite enforced by `/CJ_repo-init` (like `TODOS.md`); the only `validate.sh` interaction is the Check 17 allowlist data entry.
- Upstream gstack modification — workbench-only.

## Success Criteria

<!-- Bulleted, measurable outcomes observable from the outside. -->

- [ ] One root `CJ-DOC-RELEASE.md` is the single canonical contract; the three CLAUDE.md sections are slimmed-but-anchor-preserving pointers.
- [ ] `./scripts/cj-repo-init.sh` lists the doc as a 4th prerequisite (present/missing/invalid); `--fix` seeds it (missing→seed; invalid→`NOTE:` no-overwrite).
- [ ] `validate.sh` + `test.sh` + `cj-repo-init.test.sh` green; the Step 6.7 awk over CLAUDE.md still parses the tracked-doc/ manifest to 3 entries (CARVE-OUT held).
- [ ] No change to the JSON config, its parser, Check 16, or the Step 6.7 awk.

## Decomposition

<!-- The user-stories that decompose this feature. -->

| User-Story | Title | Status |
|-----------|-------|--------|
| [S000082](S000082_cj_doc_release_contract_doc/S000082_TRACKER.md) | CJ-DOC-RELEASE.md contract doc + /CJ_repo-init 4th prereq | Open |

## Delivery Timeline

<!-- Forward-looking milestones. -->

| # | Milestone | Target Date | Status | Owner | Notes | Blocked By |
|---|-----------|-------------|--------|-------|-------|------------|
| 1 | Ship S000082 (contract doc + repo-init prereq + CLAUDE.md slim, CARVE-OUT preserved) | — | Not Started | chjiang | All 10 touches land in one PR via /CJ_goal_feature | — |
| 2 | End-to-end pipeline run (scaffold → implement → QA → doc-sync → /ship → STOP at PR) | — | Not Started | chjiang | Feature is the PR; human review is the architecture gate | #1 |

### Delivery History

<!-- Backward-looking record: PR links, merge dates, version bumps after ship. -->

- 2026-06-04: Created via /CJ_goal_feature (scaffold phase). PR/version pending /ship.

## Dependency Graph

<!-- #N description --> #M description (arrow = "blocks"). -->

```
#1 Ship S000082 (CJ-DOC-RELEASE.md + repo-init 4th prereq + CLAUDE.md slim) --> #2 End-to-end pipeline run (PR opened)
```

## Open Questions

<!-- Questions still being decided. -->

| Question | Next check |
|----------|-----------|
| Filename: `CJ-DOC-RELEASE.md` vs `CJ-DOCUMENT-RELEASE.md`. | Resolved (mechanical default): `CJ-DOC-RELEASE.md` (brevity + `CJ-` family prefix). |
| `verify_docguide` required-headings set — small + stable so a stub fails `invalid` but cosmetic edits don't. | Pinned in the child SPEC (H1 title + a `## ` schema-reference heading + the registered-doc section heading). |
