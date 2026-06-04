---
type: design
parent: F000046
title: "Consolidate doc-release required docs into CJ-DOC-RELEASE.md (repo-init prereq) — Feature Design"
version: 1
status: Draft
date: 2026-06-04
author: chjiang
reviewers: []
---

<!-- A feature's cross-story design doc. Captures the PROBLEM, the SHAPE of
     the solution, the BIG DECISIONS with rationale, the RISKS, the
     DEFINITION OF DONE, and out-of-scope boundaries. Story-scope detail
     (SPEC/TEST-SPEC) lives on the nested user-stories — do
     not duplicate it here. -->

## Problem

The "required docs" surface for the doc-release machinery is scattered across four
places with two different consumers, and there is no single canonical "what
`/CJ_document-release` requires and what each registered doc must satisfy" document:

- **Machine config** — `cj-document-release.json` (root). Parsed by
  `cj-document-release-config.sh` (whitelist gate + `--docs` category resolution);
  schema enforced by `validate.sh` Check 16; presence already verified by
  `/CJ_repo-init`.
- **Human/agent convention prose** — three CLAUDE.md sections
  (`## cj-document-release.json convention`, `## Registered-doc requirements audit`,
  `## /document-release workbench audit conventions`).
- **Per-doc requirement declarations** — the `requirement:` strings on each
  tracked-doc manifest entry (in CLAUDE.md).
- **Per-skill requirement declarations** — the `doc_requirement` field in
  `skills-catalog.json`.

A new repo adopting the CJ_ family has to reconstruct the contract from three
CLAUDE.md sections + two declaration sites. The fix: one canonical contract doc that
both humans and the two consuming skills point at — `/CJ_repo-init` treats it as a
required prerequisite (the way it already gates `cj-document-release.json` /
`TODOS.md` / `work-items/`), and `/CJ_document-release` names it as the home of its
convention. A repo is "ready" when the doc is present; the contract stops being
tribal knowledge spread across CLAUDE.md.

## Shape of the solution

**Approach A — Doc + adjacent JSON.** A new root `CJ-DOC-RELEASE.md` becomes the prose
contract + schema documentation; `cj-document-release.json` stays the parsed artifact
beside it (the machine sidecar the doc explains). `/CJ_repo-init` requires both.
The three CLAUDE.md convention sections are slimmed in their *narrative prose only* to
point at the new doc as the canonical read, while their machine-parsed blocks + heading
anchors stay verbatim and in-place (the CARVE-OUT — see Big decisions #4). The whole
change is one PR via the `/CJ_goal_feature` pipeline.

This is one cohesive change (a new doc + a 4th `/CJ_repo-init` prereq + anchor-preserving
prose slimming), so it decomposes into a single user-story carrying all 10 touches.

| Concern | User-story | Artifact |
|---------|-----------|----------|
| New contract doc + `/CJ_repo-init` 4th prereq + CLAUDE.md slim (CARVE-OUT preserved) + supporting touches | S000082 | [S000082_cj_doc_release_contract_doc/S000082_TRACKER.md](S000082_cj_doc_release_contract_doc/S000082_TRACKER.md) |

The 10 concrete touches (review-expanded; full detail in the child SPEC):

1. **`CJ-DOC-RELEASE.md`** (NEW root doc) — the canonical contract.
2. **`CLAUDE.md`** — Check 17 allowlist entry; slim the 3 convention sections' narrative
   prose (CARVE-OUT preserved); update the `## Skill routing` prereq line; update the
   `### Posture` parenthetical.
3. **`rules/skill-routing.md`** — update the `/CJ_repo-init` prereq enumeration if present.
4. **`scripts/cj-repo-init.sh`** — the 4th prereq across 8 sites (mirror `docrel`).
5. **`skills/CJ_repo-init/SKILL.md`** — description + Overview + health-table (3→4); USAGE bump.
6. **`skills-catalog.json`** — the `CJ_repo-init` `description` (3→4).
7. **`skills/CJ_document-release/SKILL.md`** — thin canonical-home pointer (optional; NO Step-6.7 anchor edits).
8. **`tests/cj-repo-init.test.sh`** — new-prereq case + literal count assertions (3→4).
9. **`doc/ARCHITECTURE.md`** — prereq enumeration (3→4) + mechanism roster.
10. **CHANGELOG.md / VERSION** — at `/ship` time.

## Big decisions

<!-- Choices that shape the feature, with rationale. -->

| # | Decision | Why |
|---|----------|-----|
| 1 | Approach A (doc + adjacent JSON) over B (true single file embedding JSON) and C (JSON source-of-truth, doc generated). | A is the smallest blast radius — config parser, Check 16, AND the Step 6.7 awk stay untouched. B rewrites the parser + Check 16 + migrates the JSON + re-tests the whole F000037 path (too much risk for the gain). C makes the doc derived, adds a generator + drift-check surface, and pulls declarations out of their co-located homes (violates Premise 1). |
| 2 | The new doc DOCUMENTS + INDEXES the requirement declarations; it does NOT absorb them. | The requirement *declarations* stay co-located (catalog `doc_requirement` + manifest `requirement:`) — the doc points at them. Keeps the existing declaration sites as the single source of each requirement. |
| 3 | `cj-document-release.json` stays the separate machine artifact. | The config parser (`cj-document-release-config.sh`) and Check 16 are untouched; the JSON must stay machine-readable (it is parsed programmatically). |
| 4 | CARVE-OUT: slim the NARRATIVE prose only; keep machine-parsed blocks + heading anchors verbatim/in-place. | Several blocks inside the three CLAUDE.md sections are consumed by runnable parsers or referenced by SKILL.md prose anchors — chiefly `### Tracked doc/ files manifest` (parsed by `validate.sh` Check 15a AND `skills/CJ_document-release/SKILL.md` Step 6.7 awk ≈L402/L411). Moving it → empty manifest → every tracked-doc/ verdict silently vanishes. Also preserve the per-entry `requirement:` strings (read at runtime by Step 6.7), `### Reporting`, and the `## Registered-doc requirements audit` + `## cj-document-release.json convention` headings (SKILL.md prose anchors ≈L382/L505). Therefore the Step 6.7 producer's anchors stay pointing at CLAUDE.md — NO SKILL.md edit, NO Step-6.7 awk change, NO USAGE-bump-for-that-reason. This is what keeps Approach A truly low-risk. |
| 5 | The new doc is a root convention doc (Check 17 allowlist), in the same out-of-scope bucket as CLAUDE.md for the registered-doc audit; `/CJ_repo-init` presence is its enforcement (no new hard `validate.sh` check). | A root `.md` is structurally in neither the catalog-skill set nor the `### Tracked doc/ files manifest`, so it is NOT itself a registered doc. Presence is a per-repo prerequisite like `TODOS.md`, enforced by `/CJ_repo-init` — not a CI check. The `### Posture` parenthetical `(README/CHANGELOG/CLAUDE.md)` is updated to name the category, not a closed list. |

## Risks & open questions

<!-- What could go wrong, and what's still undecided. -->

| Risk / Question | Next check |
|-----------------|-----------|
| Slimming CLAUDE.md prose accidentally removes/moves a CARVE-OUT block → Step 6.7 awk parses an empty manifest, every tracked-doc/ verdict silently vanishes. | Regression guard in the child TEST-SPEC: after slimming, run the Step 6.7 awk over CLAUDE.md and confirm the tracked-doc/ manifest still parses to 3 entries. |
| The 4th `/CJ_repo-init` prereq misses one of the 8 mirror sites (e.g., the `collect()` stanza or the `--fix` ladder), so the gap is detected but never seeded (or seeded but never counted). | `tests/cj-repo-init.test.sh` new-prereq case exercises missing→REPO_GAP, `--fix` seeds→ok, present→ok, headingless→invalid/gap; plus S1/S4 literal `GAPS` count 3→4 and S3 post-`--fix` `GAPS=0`. |
| The doc drifts from the JSON schema it documents (Approach A's named con). | Mitigated by the doc's own `doc_requirement` naming the schema reference as the thing to keep current; the audit surfaces a stale verdict. |
| Filename choice: `CJ-DOC-RELEASE.md` vs `CJ-DOCUMENT-RELEASE.md`. | Resolved (mechanical default): `CJ-DOC-RELEASE.md` — brevity + `CJ-` family prefix, matching the design doc's proposed name. |
| `verify_docguide` required-headings set could be too strict (cosmetic edits flap invalid) or too loose (a stub passes). | Pick a small, stable set in the child SPEC: H1 title + a `## ` schema-reference heading + the registered-doc section heading, so a stub fails `invalid` but cosmetic edits don't. |

## Definition of done

<!-- Objective, measurable criteria for "shipped." -->

- [ ] One root `CJ-DOC-RELEASE.md` is the single canonical contract; the three CLAUDE.md sections are slimmed-but-anchor-preserving pointers.
- [ ] `./scripts/cj-repo-init.sh` lists the doc as a 4th prerequisite; `--fix` seeds it (missing→seed; invalid→`NOTE:` no-overwrite; present→ok).
- [ ] `validate.sh` + `test.sh` + `cj-repo-init.test.sh` green; the Step 6.7 awk over CLAUDE.md still parses the tracked-doc/ manifest to 3 entries.
- [ ] No change to `cj-document-release.json`, its parser (`cj-document-release-config.sh`), Check 16, the registered-doc audit selector, or the Step 6.7 awk.

## Not in scope

<!-- Explicit non-goals. -->

- `cj-document-release.json` (data) — stays as-is; it is the machine sidecar the new doc explains.
- `cj-document-release-config.sh` (parser) + `validate.sh` Check 16 — untouched (Approach A's whole point).
- The Step 6.7 `awk` in `skills/CJ_document-release/SKILL.md` and its CLAUDE.md anchors — unchanged (CARVE-OUT); the producer keeps reading CLAUDE.md.
- A new hard `validate.sh` check for the doc's presence/content — presence is a per-repo prerequisite enforced by `/CJ_repo-init`, like `TODOS.md`; the only `validate.sh` interaction is the Check 17 allowlist *data* entry.
- Approaches B (embed JSON) and C (generate the doc) — rejected on risk/co-location grounds.
- Upstream gstack modification — scope is workbench-only (this repo).

## Pointers

<!-- Cross-links to related artifacts. -->

- Parent tracker: [F000046_TRACKER.md](F000046_TRACKER.md)
- Roadmap: [F000046_ROADMAP.md](F000046_ROADMAP.md)
- Child user-story: [S000082_cj_doc_release_contract_doc/S000082_TRACKER.md](S000082_cj_doc_release_contract_doc/S000082_TRACKER.md)
- Source design: `~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-cj-feat-20260604-125130-66872-design-20260604-125832.md`
- Related features: F000037 (`cj-document-release.json` convention), F000036 (`/CJ_document-release`), F000042 (`/CJ_repo-init`), F000038 (root doc placement convention), F000030 (doc/ folder + workbench audit), T000037 / T000038 (registered-doc requirements audit).
