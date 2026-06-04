---
name: "Consolidate doc-release required docs into CJ-DOC-RELEASE.md (repo-init prereq)"
type: feature
id: "F000046"
status: active
created: "2026-06-04"
updated: "2026-06-04"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "cj-feat-20260604-125130-66872"
blocked_by: ""
---

<!-- Prerequisite: Before scaffolding this work item, run /office-hours to
     produce a design plan in ~/.gstack/projects/. Distill that plan into
     DESIGN.md during Phase 1 below. -->

## Lifecycle

### Phase 1: Track

1. Create working branch: `git checkout -b feat/consolidate_doc_release_required_docs`
2. Scaffold work item directory and TRACKER.md
3. Distill `DESIGN.md` from the /office-hours output (problem shape, big decisions, risks) — from `templates/doc-DESIGN.md`
4. Scaffold `ROADMAP.md` (scope, non-goals, decomposition, delivery timeline) — from `templates/doc-ROADMAP.md`
5. Define acceptance criteria (what "done" looks like for the whole feature)
6. Decompose into child user-stories
   → detail (DESIGN, SPEC, TEST-SPEC) lives in child stories

**Gates:**
- [x] /office-hours design produced (in `~/.gstack/projects/`)
- [x] Working branch created (`branch` field populated)
- [x] DESIGN + ROADMAP scaffolded
- [x] Acceptance criteria scoped
- [x] Broken down into child stories

### Phase 2: Implement

1. Child user-stories drive implementation (feature tracker coordinates)
2. Monitor child progress — update this tracker when children complete phases
3. Update Todos section — check off completed children, add discoveries
4. Update Files section with top-level changed files

**Gates:**
- [ ] All child stories have entered Phase 2+
- [ ] Feature-level Todos reflect remaining coordination work

### Phase 3: Ship

1. Run `/CJ_personal-workflow check` — verify all children pass validation
2. Verify smoke tests pass in CI (automated regression)
3. Walk E2E manually — run user-scenario verification before ship
4. Run `/ship` — creates feature PR (includes pre-landing code review)
5. Run `/land-and-deploy` — merges and verifies deployment
6. Run `/document-release` — post-ship doc audit; fix drifts inline or spawn D-tickets

**Gates:**
- [ ] `/CJ_personal-workflow check` — all children pass validation
- [ ] Smoke tests pass in CI
- [ ] E2E walked manually
- [ ] `/ship` — PR created (with pre-landing review)
- [ ] `/land-and-deploy` — merged and deployed
- [ ] `/document-release` — post-ship doc audit done; drifts fixed inline or spawned as D-tickets

## Acceptance Criteria

<!-- What "done" looks like for this feature. Each criterion should be
     testable and specific. -->

- [ ] A new root `CJ-DOC-RELEASE.md` is the single canonical `/CJ_document-release` contract: the wrapper flow (halt-on-red, doc-only auto-commit whitelist gate), the `cj-document-release.json` schema reference, the registered-doc audit (registered set, verdict taxonomy, surfacing, posture), and an index of where each requirement is declared (catalog `doc_requirement` + manifest `requirement:`).
- [ ] `./scripts/cj-repo-init.sh` lists `CJ-DOC-RELEASE.md` as a 4th prerequisite (present/missing/invalid), and `--fix` seeds a generic portable starter on `missing` (invalid prints a `NOTE:` and does NOT overwrite) — mirroring the `verify_docrel`/`seed_docrel`/`collect()`/`--fix` slots.
- [ ] The three CLAUDE.md convention sections are slimmed-but-anchor-preserving: their narrative prose points at `CJ-DOC-RELEASE.md` as the canonical read, while the CARVE-OUT blocks (`### Tracked doc/ files manifest`, the per-entry `requirement:` strings, `### Reporting`, the `## Registered-doc requirements audit` + `## cj-document-release.json convention` headings) stay verbatim and in-place.
- [ ] `validate.sh` Check 17 accepts `CJ-DOC-RELEASE.md` via a `### Tracked root docs allowlist` entry (`- path:` / `  reason:`, no `#`-leading lines); Check 15a still finds `### Tracked doc/ files manifest`; Check 14/16 unchanged.
- [ ] `tests/cj-repo-init.test.sh` green: new-prereq case (missing→REPO_GAP; `--fix` seeds→ok; present→ok; headingless→invalid/gap) AND the literal count assertions updated (S1/S4 `GAPS=3`→`GAPS=4`); S3 post-`--fix` `GAPS=0` still holds.
- [ ] `scripts/validate.sh` + `scripts/test.sh` + `tests/cj-repo-init.test.sh` all green.
- [ ] Regression guard: after slimming CLAUDE.md, the Step 6.7 awk over CLAUDE.md still parses the tracked-doc/ manifest to 3 entries (CARVE-OUT held).
- [ ] No change to `cj-document-release.json` (data), `cj-document-release-config.sh` (parser), `validate.sh` Check 16, the registered-doc audit selector, or the Step 6.7 `awk`.

## Todos

<!-- Actionable items for this feature. Break into child tasks for
     large features. -->

- [ ] Author `CJ-DOC-RELEASE.md` (new root contract doc) — Touch 1.
- [ ] Update `CLAUDE.md`: Check 17 allowlist entry; slim the 3 convention sections' narrative prose (CARVE-OUT preserved); update the `## Skill routing` prereq enumeration; update the `### Posture` parenthetical — Touch 2.
- [ ] Update `rules/skill-routing.md` prereq enumeration if present — Touch 3.
- [ ] Wire `scripts/cj-repo-init.sh` 4th prereq across its 8 sites (mirror `docrel`): `NEED_DOCGUIDE` decl, `DETECT_SOURCE==none` branch, per-skill trigger loop, `*_PATH` var, `verify_docguide()`, `seed_docguide()`, `collect()` stanza, `--fix` ladder — Touch 4.
- [ ] Update `skills/CJ_repo-init/SKILL.md` (description 3→4, Overview bullets, health-table prose); bump `USAGE.md` `last-updated` — Touch 5.
- [ ] Update the `CJ_repo-init` `skills-catalog.json` `description` (3→4) so a README regen won't drift — Touch 6.
- [ ] (Optional) Add a thin "canonical convention home: CJ-DOC-RELEASE.md" pointer to `skills/CJ_document-release/SKILL.md`; bump its USAGE.md only if SKILL text changes — Touch 7.
- [ ] Add the new-prereq case + update literal count assertions in `tests/cj-repo-init.test.sh` — Touch 8.
- [ ] Update `doc/ARCHITECTURE.md`: L139 prereq enumeration (3→4) + mechanism roster — Touch 9.
- [ ] CHANGELOG.md / VERSION at `/ship` time — Touch 10.

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-06-04: Created. Consolidate the scattered /CJ_document-release "required docs" surface into one canonical root contract doc (CJ-DOC-RELEASE.md), keep cj-document-release.json as the adjacent machine config, and wire /CJ_repo-init to verify the doc as a 4th required prerequisite. Approach A (doc + adjacent JSON), CARVE-OUT honored.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. Populated during Track phase, updated during Implement. -->

- `CJ-DOC-RELEASE.md` (new) — canonical /CJ_document-release contract doc
- `CLAUDE.md` (modified) — Check 17 allowlist entry; slimmed convention prose (CARVE-OUT preserved); skill-routing prereq line; `### Posture` parenthetical
- `rules/skill-routing.md` (modified, if it enumerates prereqs) — add the new doc
- `scripts/cj-repo-init.sh` (modified) — 4th prereq across 8 sites (mirror `docrel`)
- `skills/CJ_repo-init/SKILL.md` (modified) — description + Overview + health-table (3→4)
- `skills/CJ_repo-init/USAGE.md` (modified) — `last-updated` bump
- `skills-catalog.json` (modified) — `CJ_repo-init` description (3→4)
- `skills/CJ_document-release/SKILL.md` (modified, optional) — thin canonical-home pointer
- `tests/cj-repo-init.test.sh` (modified) — new-prereq case + literal count assertions (3→4)
- `doc/ARCHITECTURE.md` (modified) — prereq enumeration + mechanism roster
- `CHANGELOG.md` / `VERSION` (modified at /ship)

## Insights

<!-- Non-obvious findings worth remembering. Design decisions,
     trade-offs, patterns discovered. -->

- The "required docs" surface for doc-release was scattered across four homes with two consumers: the machine config (`cj-document-release.json`), three CLAUDE.md convention sections, the per-doc `requirement:` strings in the tracked-doc manifest, and the per-skill `doc_requirement` in `skills-catalog.json`. A repo adopting the CJ_ family had to reconstruct the contract from 3 CLAUDE.md sections + 2 declaration sites — there was no single canonical "what /CJ_document-release requires" doc.
- CARVE-OUT (load-bearing, from adversarial review 6/10→fixed): several blocks inside the three CLAUDE.md convention sections are consumed by runnable parsers or referenced by SKILL.md prose anchors and MUST stay verbatim/in-place even as the narrative prose is slimmed — chiefly `### Tracked doc/ files manifest` (parsed by `validate.sh` Check 15a AND `skills/CJ_document-release/SKILL.md` Step 6.7 awk). Moving it → empty manifest → every tracked-doc/ verdict silently vanishes. This is what keeps Approach A truly low-risk; the Step 6.7 anchors stay pointing at CLAUDE.md (NO SKILL.md edit, NO awk change).
- The new doc is a root convention doc (allowlisted under Check 17), in the SAME out-of-scope bucket as CLAUDE.md for the registered-doc audit. It is structurally excluded (a root `.md` is in neither the catalog-skill set nor the tracked-doc/ manifest), so it is NOT itself a registered doc — `/CJ_repo-init` presence is its enforcement, not a new hard validate.sh check.
- A new `/CJ_repo-init` prereq touches 8 sites in `cj-repo-init.sh` — mirror the existing `docrel` prereq exactly, including the present-but-invalid `NOTE:` (no-overwrite) tier.

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

- [decision] 2026-06-04: Approach A (doc + adjacent JSON), operator-selected over B (true single file, embeds JSON) and C (JSON source-of-truth, doc generated). Summary: A delivers the operator's goal (one canonical contract doc caught by /CJ_repo-init) at the lowest risk — config parser, Check 16, AND the Step 6.7 awk stay untouched. B rewrites the parser + Check 16 + migrates the JSON (too much risk); C makes the doc derived + pulls declarations out of their co-located homes (violates Premise 1).
- [decision] 2026-06-04: The new doc DOCUMENTS + INDEXES the requirement declarations; it does NOT absorb them. Summary: catalog `doc_requirement` + manifest `requirement:` stay co-located at their declaration sites (Premise 1); `cj-document-release.json` stays the separate machine artifact with its parser + Check 16 untouched (Premise 2).
- [decision] 2026-06-04: Slim the NARRATIVE prose only in the three CLAUDE.md convention sections; keep machine-parsed blocks + heading anchors verbatim/in-place (the CARVE-OUT). Summary: the Step 6.7 producer keeps reading CLAUDE.md, so no `skills/CJ_document-release/SKILL.md` Step-6.7 awk change and no USAGE-bump-for-that-reason.
