---
type: design
parent: S000082
title: "CJ-DOC-RELEASE.md contract doc + /CJ_repo-init 4th prereq — Story Design"
version: 1
status: Draft
date: 2026-06-04
author: chjiang
reviewers: []
---

<!-- Atomic story deriving directly from the parent feature's /office-hours
     session. The parent's design (F000046_DESIGN.md) is the full context;
     this stub keeps the 7 sections per /CJ_personal-workflow check Step 16. -->

## Problem

The `/CJ_document-release` "required docs" contract is scattered across four homes
(machine config, three CLAUDE.md sections, per-doc `requirement:` strings, per-skill
`doc_requirement`) with no single canonical doc. This story creates that doc and makes
`/CJ_repo-init` enforce its presence. See parent [F000046_DESIGN.md](../F000046_DESIGN.md)
for the full problem framing.

## Shape of the solution

Approach A (doc + adjacent JSON): a new root `CJ-DOC-RELEASE.md` is the prose contract;
`cj-document-release.json` stays the parsed sidecar; `/CJ_repo-init` requires both; the
three CLAUDE.md sections are slimmed in narrative prose only (CARVE-OUT blocks preserved).
One story, 10 touches, one PR. The implementation contract (requirements, AC,
architecture, the 8 `cj-repo-init.sh` mirror sites) is in [S000082_SPEC.md](S000082_SPEC.md).

## Big decisions

See parent [F000046_DESIGN.md](../F000046_DESIGN.md) `## Big decisions` for the
authoritative set. The three that most shape this story:

| # | Decision | Why |
|---|----------|-----|
| 1 | Slim NARRATIVE prose only; keep machine-parsed blocks + heading anchors verbatim/in-place (CARVE-OUT). | `### Tracked doc/ files manifest` is parsed by `validate.sh` Check 15a AND the Step 6.7 awk; moving it silently empties every tracked-doc/ verdict. Step 6.7 anchors stay pointing at CLAUDE.md — no SKILL.md/awk edit. |
| 2 | The new doc DOCUMENTS + INDEXES requirement declarations; does not absorb them. | Catalog `doc_requirement` + manifest `requirement:` stay co-located at their declaration sites. |
| 3 | The doc is a root convention doc (Check 17 allowlist), NOT a registered doc; `/CJ_repo-init` presence is its enforcement. | A root `.md` is structurally outside the catalog-skill set AND the tracked-doc/ manifest, so no new hard `validate.sh` check is added. |

## Risks & open questions

| Risk / Question | Next check |
|-----------------|-----------|
| Prose slim accidentally moves/removes a CARVE-OUT block → Step 6.7 awk parses an empty manifest. | TEST-SPEC regression guard: Step 6.7 awk over CLAUDE.md → tracked-doc/ manifest still 3 entries. |
| Missing one of the 8 `cj-repo-init.sh` mirror sites → gap detected but not seeded (or seeded but not counted). | TEST-SPEC new-prereq case + literal `GAPS` 3→4 + S3 post-`--fix` `GAPS=0`. |
| `verify_docguide` headings set too strict/loose. | Pinned in SPEC: H1 title + a `## ` schema-reference heading + the registered-doc section heading. |

## Definition of done

- [ ] `CJ-DOC-RELEASE.md` is the single canonical contract; CLAUDE.md sections slimmed-but-anchor-preserving.
- [ ] `./scripts/cj-repo-init.sh` lists the doc as a 4th prereq; `--fix` seeds it (missing→seed; invalid→`NOTE:` no-overwrite).
- [ ] `validate.sh` + `test.sh` + `cj-repo-init.test.sh` green; Step 6.7 manifest still parses to 3.
- [ ] No change to the JSON config, its parser, Check 16, or the Step 6.7 awk.

## Not in scope

- `cj-document-release.json` (data), `cj-document-release-config.sh` (parser), `validate.sh` Check 16 — untouched.
- The Step 6.7 `awk` + its CLAUDE.md anchors — unchanged (CARVE-OUT).
- A new hard `validate.sh` check for the doc — presence is enforced by `/CJ_repo-init`.
- Upstream gstack modification.

## Pointers

- Parent design: [../F000046_DESIGN.md](../F000046_DESIGN.md)
- Parent tracker: [../F000046_TRACKER.md](../F000046_TRACKER.md)
- This story's spec: [S000082_SPEC.md](S000082_SPEC.md)
- This story's test-spec: [S000082_TEST-SPEC.md](S000082_TEST-SPEC.md)
- Source design: `~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-cj-feat-20260604-125130-66872-design-20260604-125832.md`
