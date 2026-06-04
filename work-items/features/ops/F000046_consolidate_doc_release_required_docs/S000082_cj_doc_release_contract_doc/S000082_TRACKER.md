---
name: "CJ-DOC-RELEASE.md contract doc + /CJ_repo-init 4th prereq"
type: user-story
id: "S000082"
created: "2026-06-04"
updated: "2026-06-04"
parent: "F000046"
status: active
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "cj-feat-20260604-125130-66872"
blocked_by: ""
---

<!-- Prerequisite: Before scaffolding this work item, run /office-hours to
     produce a design plan in ~/.gstack/projects/. Distill that plan into
     DESIGN.md during Phase 1 below. (For atomic stories that derive directly
     from the parent feature's /office-hours session, the parent's design is
     sufficient context — DESIGN.md may be a brief stub linking to the parent.) -->

## Lifecycle

### Phase 1: Track

1. Read parent tracker to understand scope
2. Create working branch: `git checkout -b feat/{slug}` (or use parent's branch if shipping in same PR)
3. Scaffold work item directory and TRACKER.md
4. Distill `DESIGN.md` from the /office-hours output (own session or parent's) — from `templates/doc-DESIGN.md`
5. Scaffold `SPEC.md` (requirements, acceptance criteria, architecture, tradeoffs) — from `templates/doc-SPEC.md`
6. Scaffold `TEST-SPEC.md` (smoke + E2E test scenarios) — from `templates/doc-TEST-SPEC.md`
7. Break into child tasks if scope warrants decomposition (per WORKFLOW.md, tasks are optional for atomic stories)

**Gates:**
- [x] /office-hours design referenced (own or parent's, captured in DESIGN.md)
- [x] Working branch created (`branch` field populated)
- [x] DESIGN + SPEC + TEST-SPEC scaffolded
- [x] Acceptance criteria defined
- [x] Tasks broken down (N/A — atomic story; the 10 touches are one cohesive change shipped in one PR)

### Phase 2: Implement

1. Read DESIGN + SPEC for context
2. Implement according to architecture decisions in SPEC
3. Run smoke tests as you go (TEST-SPEC `## Smoke Tests` table)
4. Run `/CJ_personal-workflow check` on modified docs after updates
5. Update tracker: move through lifecycle phases, add journal entries
6. Update Files section with changed file paths

**Gates:**
- [x] Acceptance criteria verified met
- [x] Smoke tests pass
- [x] Todos section reflects remaining work (no stale items)
- [x] Files section updated with changed files

### Phase 3: Ship

1. Run `/CJ_personal-workflow check` — verify all validation passes
   → should show PASS for template, lifecycle, traceability badges
2. Verify smoke tests pass in CI (automated regression)
3. Walk E2E manually — drive the feature as a user would (TEST-SPEC `## E2E Tests` table)
4. Ensure all child tasks (if any) have shipped
5. Run `/ship` — creates PR, bumps version, updates changelog (includes pre-landing code review)
6. Run `/land-and-deploy` — merges PR and verifies deployment

❌ If `/CJ_personal-workflow check` finds issues: fix findings, re-run until clean
❌ If smoke or E2E fails: fix, re-run

**Gates:**
- [ ] `/CJ_personal-workflow check` — validation passed
- [ ] Smoke tests pass in CI
- [ ] E2E walked manually
- [ ] All children shipped (if any) — N/A (atomic story)
- [ ] `/ship` — PR created (with pre-landing review)
- [ ] `/land-and-deploy` — merged and deployed

## Acceptance Criteria

<!-- What "done" looks like for this story. -->

- [ ] `CJ-DOC-RELEASE.md` exists at repo root and is the single canonical `/CJ_document-release` contract (wrapper flow + halt-on-red + doc-only auto-commit whitelist gate + `cj-document-release.json` schema reference + registered-doc audit + a declaration-site index for catalog `doc_requirement` and manifest `requirement:`).
- [ ] `CLAUDE.md` updated: a `### Tracked root docs allowlist` entry for `CJ-DOC-RELEASE.md` (`- path:` / `  reason:`, no `#`-leading lines); narrative prose of the 3 convention sections points at the new doc; the `## Skill routing` prereq line enumerates the new doc; the `### Posture` parenthetical names the category. CARVE-OUT blocks preserved verbatim/in-place.
- [ ] `scripts/cj-repo-init.sh` verifies `CJ-DOC-RELEASE.md` as a 4th prereq across all 8 mirror sites; `--fix` seeds a generic portable starter on `missing`; `invalid` prints a `NOTE:` and does NOT overwrite.
- [ ] `skills/CJ_repo-init/SKILL.md` (description 3→4, Overview bullets, health-table prose) + `USAGE.md` `last-updated` bump; `skills-catalog.json` `CJ_repo-init` `description` (3→4); `doc/ARCHITECTURE.md` prereq enumeration (3→4) + roster.
- [ ] `tests/cj-repo-init.test.sh` new-prereq case green (missing→REPO_GAP; `--fix` seeds→ok; present→ok; headingless→invalid/gap) AND literal count assertions updated (S1/S4 `GAPS=3`→`GAPS=4`); S3 post-`--fix` `GAPS=0` holds.
- [ ] `scripts/validate.sh` (Check 17 accepts the allowlisted root doc; Check 15a still finds `### Tracked doc/ files manifest`; Check 14/16 unchanged), `scripts/test.sh`, and `tests/cj-repo-init.test.sh` all green.
- [ ] Regression guard: the Step 6.7 awk over CLAUDE.md still parses the tracked-doc/ manifest to 3 entries after the slim.
- [ ] No change to `cj-document-release.json`, `cj-document-release-config.sh`, `validate.sh` Check 16, the registered-doc audit selector, or the Step 6.7 awk.

## Todos

<!-- Actionable items for this story. -->

- [x] Author `CJ-DOC-RELEASE.md` (sections: contract overview, wrapper flow + halt-on-red, doc-only auto-commit whitelist gate, `cj-document-release.json` schema reference, registered-doc audit, declaration-site index). — Touch 1
- [x] `CLAUDE.md`: Check 17 allowlist entry; slim the 3 convention sections' prose (CARVE-OUT preserved); update `## Skill routing` prereq line; update `### Posture` parenthetical. — Touch 2
- [x] `rules/skill-routing.md`: verify whether it enumerates the `/CJ_repo-init` prereqs; if so, add the new doc. — Touch 3 (verified NO-OP: skill-routing.md carries only the one-line trigger mapping for /CJ_repo-init, no prereq enumeration, so no edit needed)
- [x] `scripts/cj-repo-init.sh`: add the 4th prereq across 8 sites (`NEED_DOCGUIDE`, `DETECT_SOURCE==none`, per-skill trigger loop, `*_PATH` var, `verify_docguide()`, `seed_docguide()`, `collect()` stanza, `--fix` ladder). — Touch 4
- [x] `skills/CJ_repo-init/SKILL.md` (3→4 in description/Overview/health-table) + `USAGE.md` `last-updated` bump. — Touch 5
- [x] `skills-catalog.json`: `CJ_repo-init` `description` (3→4). — Touch 6
- [x] (Optional) `skills/CJ_document-release/SKILL.md`: thin "canonical convention home: CJ-DOC-RELEASE.md" pointer (added in Overview, away from Step 6.7); USAGE.md `last-updated` bumped; NO Step-6.7 anchor edits. — Touch 7
- [x] `tests/cj-repo-init.test.sh`: new-prereq case (S6) + literal count assertions (S1/S4 3→4). — Touch 8
- [x] `doc/ARCHITECTURE.md`: prereq enumeration (3→4) + mechanism roster (F000046 note in the F000037 section). — Touch 9
- [ ] CHANGELOG.md / VERSION at `/ship`. — Touch 10 (deferred to /ship phase)

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-06-04: Created. Child of F000046 — carries the full feature scope (the 10 touches) as one cohesive change: new `CJ-DOC-RELEASE.md` contract doc, `/CJ_repo-init` 4th prereq, and anchor-preserving CLAUDE.md prose slim.
- 2026-06-04 (base 2b226e7): Implemented Touches 1–9 (Touch 3 a verified no-op; Touch 10 deferred to /ship). Phase 2 implementer-owned gates green. validate/test/cj-repo-init.test all green; in-repo health table shows 4 prereqs / GAPS=0; CARVE-OUT regression guard parses 3 manifest entries.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. -->

- `CJ-DOC-RELEASE.md` (new) — canonical /CJ_document-release prose contract at repo root
- `CLAUDE.md` (modified) — Check 17 allowlist entry; 3 convention-section prose pointers (CARVE-OUT preserved); Skill-routing prereq line 3→4; Posture parenthetical
- `rules/skill-routing.md` (NOT modified) — verified it does not enumerate /CJ_repo-init prereqs (Touch 3 no-op)
- `scripts/cj-repo-init.sh` (modified) — NEED_DOCGUIDE 4th prereq across all 8 mirror sites + verify_docguide/seed_docguide
- `skills/CJ_repo-init/SKILL.md` (modified) — description/Overview/health-table/error-table 3→4
- `skills/CJ_repo-init/USAGE.md` (modified) — no-overwrite pitfall + Related-skills note + last-updated bump
- `skills-catalog.json` (modified) — CJ_repo-init description 3→4 (mirrors SKILL frontmatter)
- `skills/CJ_document-release/SKILL.md` (modified) — thin canonical-home pointer in Overview (NO Step-6.7 awk/anchor edits)
- `skills/CJ_document-release/USAGE.md` (modified) — last-updated bump (Check 14)
- `tests/cj-repo-init.test.sh` (modified) — new S6 docguide case + S1/S4 GAPS 3→4
- `doc/ARCHITECTURE.md` (modified) — roster prereq enumeration 3→4 + F000046 note in the F000037 section
- `CHANGELOG.md` / `VERSION` (deferred to /ship)

## Insights

<!-- Non-obvious findings worth remembering. -->

- A new `/CJ_repo-init` prereq is an 8-site change in `cj-repo-init.sh` — mirror the existing `docrel` prereq exactly (decl, none-branch, trigger loop, `*_PATH` var, verify fn, seed fn, `collect()` stanza, `--fix` ladder), including the present-but-invalid `NOTE:` (no-overwrite) tier. Missing one site means the gap is detected but never seeded, or seeded but never counted.
- The implement-subagent blind spot (every new validate.sh check needs a parallel `scripts/test.sh` zzz-test-scaffold edit) does NOT apply here: there is no new validate.sh check. The only validate.sh interaction is a Check 17 allowlist *data* entry, and the Check-17 fixture uses a non-allowlisted `STRAY.md` (no collision). The test surface that DOES change is `tests/cj-repo-init.test.sh` (new-prereq case + literal `GAPS` count 3→4).
- The CARVE-OUT is the load-bearing risk: `### Tracked doc/ files manifest` in CLAUDE.md is parsed by BOTH `validate.sh` Check 15a AND the Step 6.7 awk in `skills/CJ_document-release/SKILL.md`. Slimming the prose must not touch that block, the per-entry `requirement:` strings, `### Reporting`, or the two heading anchors (`## Registered-doc requirements audit`, `## cj-document-release.json convention`).

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

- [decision] 2026-06-04: Single atomic user-story (no task children). Summary: the 10 touches are one cohesive change shipped in one PR (a new doc + a 4th repo-init prereq + anchor-preserving prose slimming); decomposing into tasks would add tracking overhead without parallelizable sub-units. Phase 1 gate recorded as `Tasks broken down (N/A — atomic story)`.
- [decision] 2026-06-04: `verify_docguide` required-headings set = H1 title + a `## ` schema-reference heading + the registered-doc section heading. Summary: small + stable so a stub fails `invalid` but cosmetic edits don't flap; mirrors the `verify_docrel` present/missing/invalid tiering.
- 2026-06-04 [impl-decision] `verify_docguide` anchors chosen as `^# .+`, `^## .*cj-document-release\.json`, `^## .*[Rr]egistered-doc` (grep -Eq). Both the real root `CJ-DOC-RELEASE.md` AND the portable `seed_docguide` heredoc carry exactly these three headings, so a fresh seed self-validates and the in-repo dogfood reports `ok`. Case-insensitive registered-doc match tolerates "Registered-doc"/"registered-doc".
- 2026-06-04 [impl-decision] Touch 3 (`rules/skill-routing.md`) resolved as a NO-OP per the SPEC's verify-first clause: grep confirmed the file carries only the one-line `/CJ_repo-init` trigger mapping, with no prereq enumeration to update. Recorded so a later reader doesn't re-open it.
- 2026-06-04 [impl-decision] CLAUDE.md prose-slim implemented as ADDITIVE pointer blockquotes at the top of each of the 3 convention sections, leaving the existing narrative + every CARVE-OUT block byte-for-byte unchanged. `git diff` shows only 2 deletion lines, both deliberate single-line rewrites (Skill-routing prereq enumeration + Posture parenthetical) — neither a CARVE-OUT block.
- 2026-06-04 [impl-finding] CARVE-OUT held: the Step 6.7 awk (extracted verbatim from skills/CJ_document-release/SKILL.md) over the slimmed CLAUDE.md parses exactly 3 tracked-doc/ manifest entries (PHILOSOPHY/ARCHITECTURE/WORKFLOWS), all 3 `requirement:` strings intact. The `## Registered-doc requirements audit` / `## cj-document-release.json convention` / `### Tracked doc/ files manifest` / `### Reporting` anchors are unchanged. NO edit to the Step 6.7 awk.
- 2026-06-04 [impl] Wrote 1 new file (CJ-DOC-RELEASE.md); modified 9 (CLAUDE.md, scripts/cj-repo-init.sh, skills/CJ_repo-init/SKILL.md + USAGE.md, skills-catalog.json, skills/CJ_document-release/SKILL.md + USAGE.md, tests/cj-repo-init.test.sh, doc/ARCHITECTURE.md). 8 mirror sites wired in cj-repo-init.sh; new S6 test case + GAPS 3→4.
- 2026-06-04 [impl-auto] Auto-mode run (--auto, /CJ_goal_feature leaf): the parent orchestrator pre-gated this approved-design build, so the sensitive-surface/non-trivial propose AUQ was satisfied by the orchestrator contract; implemented silently per the runner role.
- 2026-06-04 [impl] Verification green: `./scripts/validate.sh` 0 errors / 0 warnings (Check 14 current for both edited skills, Check 15a manifest intact, Check 16 unchanged, Check 17 allowlist 6 entries incl. CJ-DOC-RELEASE.md); `./scripts/test.sh` 0 failures (incl. cj-repo-init integration + T000038/T000039 wiring); `bash tests/cj-repo-init.test.sh` 42 OK / 0 FAIL (S1–S6); in-repo `./scripts/cj-repo-init.sh` shows 4 prereqs, GAPS=0; regression guard parses 3 manifest entries.
- 2026-06-04 [impl-pass] S000082: implementation complete. Phase 2 implementer-owned gates transitioned (Todos + Files). QA-owned gates (Acceptance criteria verified met / Smoke tests pass) left for /CJ_qa-work-item.
- 2026-06-04 [qa-smoke] S1 (AC-3, AC-4): green — `bash tests/cj-repo-init.test.sh` 42 OK / 0 FAIL; new S6 docguide case green (missing→REPO_GAP/exit1, --fix seeds, present→ok, headingless→invalid+no-overwrite) and S1/S4 GAPS=4 + S2/S3 post-`--fix` GAPS=0 assertions hold.
- 2026-06-04 [qa-smoke] S2 (AC-6): green — `./scripts/validate.sh` exit 0, 0 errors / 0 warnings; Check 17 parsed root *.md allowlist (6 entries) with CJ-DOC-RELEASE.md present, no orphan ERROR, no `#`-leading line introduced.
- 2026-06-04 [qa-smoke] S3 (AC-7, AC-2): green — Step 6.7 awk (extracted verbatim from skills/CJ_document-release/SKILL.md) over slimmed CLAUDE.md yields exactly 3 tracked-doc/ manifest entries (PHILOSOPHY/ARCHITECTURE/WORKFLOWS), all 3 `requirement:` strings intact; CARVE-OUT held.
- 2026-06-04 [qa-smoke] S4 (AC-5): green — `./scripts/test.sh` exit 0, 0 failures (incl. cj-repo-init integration, catalog/README-regen non-drift, Check 14 USAGE freshness for both edited skills, T000038/T000039 wiring).
- 2026-06-04 [qa-smoke] S5 (AC-2): green — `git diff -- CLAUDE.md`: the `### Tracked doc/ files manifest` block, `### Reporting`, both anchors (`## Registered-doc requirements audit`, `## cj-document-release.json convention`), and the ```yaml manifest fence are byte-for-byte unchanged; the only carve-out-token changed lines are additive `+>` pointer blockquotes; 2 deliberate deletions = Skill-routing prereq line + Posture parenthetical rewrites.
- 2026-06-04 [qa-smoke-summary] green: 5/5 non-manual rows green (0 manual rows pending)
- 2026-06-04 [qa-e2e-run-start] RUN_ID=20260604-133953-86554 commit=2b226e7
- 2026-06-04 [qa-e2e] E1 (AC-3): green — scratch repo (fake CJ_REPO_INIT_CLAUDE_HOME): detect lists `CJ-DOC-RELEASE.md ... MISSING` + `REPO_GAP CJ-DOC-RELEASE.md missing` (exit 1); `--fix` seeds a 3077-byte portable starter carrying all 3 required headings (H1 / cj-document-release.json schema / registered-doc); re-detect reports OK, exit 0, idempotent. [parent-inline]
- 2026-06-04 [qa-e2e] E2 (AC-3): green — headingless CJ-DOC-RELEASE.md flagged INVALID + `REPO_GAP CJ-DOC-RELEASE.md invalid (missing required headings)` (exit 1); `--fix` prints `NOTE: ... present but invalid ... NOT overwritten` and leaves the file byte-for-byte unchanged. [parent-inline]
- 2026-06-04 [qa-e2e] E3 (AC-1): green — CJ-DOC-RELEASE.md read cold: wrapper flow (halt-on-red [doc-sync-red] + inline Step 5.5), doc-only auto-commit whitelist gate ([doc-sync-non-doc-write]), cj-document-release.json v1 schema reference, registered-doc audit (registered set/verdict taxonomy/surfacing/posture), and the declaration-site index table are all present + coherent; runnable from the doc alone, no CLAUDE.md needed. [parent-inline]
- 2026-06-04 [qa-e2e] E4 (AC-2): green — in-repo `./scripts/cj-repo-init.sh`: health table shows all 4 prereqs (cj-document-release.json, CJ-DOC-RELEASE.md, TODOS.md, work-items/) = OK, GAPS=0, exit 0; the docguide row reads OK; slimmed CLAUDE.md carries 8 CJ-DOC-RELEASE.md references incl. the canonical-read pointer blockquotes atop the 3 convention sections. [parent-inline]
- 2026-06-04 [qa-e2e-summary] green (0s subagent; 4 rows parent-inline; 0 deferred): all 4 E2E criteria green (E1 seed-cycle, E2 invalid-no-overwrite, E3 cold-read coherence, E4 in-repo dogfood). Tracker journal updated.
- 2026-06-04 [qa-pass] S000082 (user-story): green smoke (5/5 rows) + green E2E (4/4 rows). Phase 2 QA-owned gates transitioned (Acceptance criteria verified met / Smoke tests pass). Implementation verified UNCOMMITTED in the working tree (expected at QA time in the /CJ_goal_feature pipeline — commit happens after QA-green).
