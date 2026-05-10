---
name: "Rename user-authored skills to CJ_ prefix"
type: task
id: "T000018"
status: active
created: "2026-05-09"
updated: "2026-05-09"
parent: ""
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "claude/naughty-antonelli-5f2565"
blocked_by: ""
---

<!-- Prerequisite (optional): If this task came from /office-hours, distill the
     design context into the ## Insights section below. Otherwise (per the
     skip-design-for-small-todos convention in WORKFLOW.md), proceed without
     a separate DESIGN.md — the parent user-story's DESIGN already covers it. -->

## Lifecycle

### Phase 1: Track

1. Read parent tracker to understand scope and acceptance criteria
2. Create working branch: `git checkout -b feat/rename_user-authored_skills_to_cj_prefix`
   (use parent's branch if the task ships in the same PR; create a new branch if it warrants its own PR)
3. Scaffold required docs:
   - `test-plan.md` (test scenarios for this task) — from `templates/doc-test-plan.md`
4. Populate Files section with expected changed files
5. Write initial Todos from parent's acceptance criteria

**Gates:**
- [x] Parent scope read (parent tracker reviewed) — N/A, no parent; design doc reviewed
- [x] Working branch created (`branch` field populated)
- [x] Required docs scaffolded (test-plan)
- [x] Files section populated

### Phase 2: Implement

1. Work from `/office-hours` design doc + parent's acceptance criteria + your Todos
   → design doc at `~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-claude-naughty-antonelli-5f2565-design-20260509-222042.md`
2. Commit changes incrementally with descriptive messages
3. Update Todos section — check off completed items, add discoveries
4. Update Files section with actual changed files

**Gates:**
- [ ] Core changes committed (>=1 commit SHA in Log)
- [x] Todos section reflects remaining work (no stale items)
- [x] Files section updated with changed files

### Phase 3: Ship

1. Run `/personal-workflow check` — verify no regressions
2. Verify test-plan: all test scenarios passing
3. Run `/ship` — creates PR, bumps version, updates changelog (includes pre-landing code review)
4. Run `/land-and-deploy` — merges PR and verifies deployment

❌ If tests fail: fix, re-run
❌ If CI fails: fix, push, re-run `/ship`

**Gates:**
- [ ] `/personal-workflow check` — validation passed
- [ ] Test-plan verified (all scenarios passing)
- [ ] `/ship` — PR created
- [ ] `/land-and-deploy` — merged and deployed

## Todos

<!-- Actionable items for this task. Not lifecycle duplicates — these are
     the actual things to build, fix, or investigate.

     Acceptance criteria (from design doc Success Criteria) are folded into the
     verification checklist at the bottom — every "verify ..." todo is a binding
     gate for ship-readiness. -->

Implementation:

- [x] Rename `name:` field in 8 SKILL.md files to `CJ_*`
- [x] Rename 7 active/experimental skill directories: `skills/{name}/` → `skills/CJ_{name}/`
- [x] Rename deprecated skill directory: `deprecated/company-workflow/` → `deprecated/CJ_company-workflow/`
- [x] Update `skills-catalog.json` entries: `name`, `files`, `templates`, `templates_source`, `depends.skills[]` for all 8 entries
- [x] Rename `templates/personal-workflow/` → `templates/CJ_personal-workflow/`
- [x] Rename `deprecated/company-workflow/templates/` → `deprecated/CJ_company-workflow/templates/` (carried under parent rename)
- [x] Update `work-copilot/` byte-mirror references where they point at `deprecated/company-workflow/` (validate.sh MIRROR_SPECS check 10 stays green)
- [x] Update CLAUDE.md skill-routing section (8 slash-command names → `CJ_*`)
- [x] Update README.md references (regenerated; no leftover unprefixed references)
- [x] Update scripts that hardcode skill names: validate.sh (MIRROR_SPECS), skills-deploy, test.sh, test-deploy.sh, eval.sh, check-gates-update.sh
- [x] Active work-items/ cross-references — preserved as immutable history per pre-collected guidance
- [x] Bump each touched skill's version (major bump — breaking change)
- [x] Bump collection version 1.15.1 → 2.0.0 (MAJOR per convention)

Verification (acceptance criteria from design):

- [x] All 8 skills have `CJ_` prefix in `name:` field, directory, and `skills-catalog.json` entry
- [x] All cross-skill `depends.skills[]` references updated; jq verification matches every dep to a catalog `name`
- [x] `./scripts/validate.sh` exits 0 (10+ error checks green, including MIRROR_SPECS check 10)
- [x] `./scripts/test.sh` exits 0 (full suite green, includes test-deploy.sh)
- [x] `./scripts/generate-readme.sh` regenerates README.md with new `CJ_*` names; no leftover unprefixed references
- [ ] `./scripts/skills-deploy install` deploys all 8 renamed skills cleanly to `~/.claude/skills/CJ_*/` — Phase 3 (post-merge)
- [ ] `./scripts/skills-deploy doctor` reports zero orphans / zero drift — Phase 3 (post-deploy)
- [x] Grep-clean: no bare `personal-workflow`, `system-health`, `scaffold-work-item`, `implement-from-spec`, `qa-work-item`, `personal-pipeline`, `suggest`, `company-workflow` references in source (CLAUDE.md, README.md, scripts/, skills/, deprecated/, templates/, work-copilot/), excluding CHANGELOG and immutable work-items/ history
- [x] Collection version bumped per convention

## Log

<!-- Chronological entries with dates and commit SHAs. Each entry records
     what happened, not what should happen. -->

- 2026-05-09: Created. Rename all 8 user-authored skills (active, experimental, deprecated) to `CJ_` prefix to disambiguate from upstream catalogs and prevent future name collisions.
- 2026-05-09: [impl] Phase 2 implementation complete. Directory renames via `git mv`, catalog rewritten, scripts updated, internal cross-refs flipped (perl word-boundary bulk rename), README regenerated, version bumped 1.15.1 → 2.0.0, CHANGELOG entry added. validate.sh + test.sh both green.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. Populated during Track phase, updated during Implement. -->

Actual changes:

- 8 × directory renames via `git mv` (7 under `skills/`, 1 under `deprecated/`)
- `skills/CJ_*/SKILL.md` (8 files) — `name:` field + version bump in frontmatter
- `templates/CJ_personal-workflow/*.md` (rename + content references updated)
- `deprecated/CJ_company-workflow/templates/*.md` (carried under parent rename + content references updated)
- `skills-catalog.json` — all 8 user-authored entries (`name`, `files`, `templates`, `templates_source`, `depends.skills[]`, `version`)
- `work-copilot/` byte-mirror — internal references re-pointed; `validate.sh` MIRROR_SPECS check 10 still green
- `CLAUDE.md` — skill-routing block (8 slash commands), workflow refs, and update-check section
- `PHILOSOPHY.md` — slash-command refs
- `README.md` — regenerated via `./scripts/generate-readme.sh`
- `CHANGELOG.md` — new `[2.0.0]` entry
- `VERSION` — 1.15.1 → 2.0.0
- `scripts/validate.sh` — MIRROR_SPECS paths + comments + manifest paths
- `scripts/test.sh` — `_PREFIX` extraction (strip CJ_), iteration loops, output strings
- `scripts/test-deploy.sh` — all skill-name references
- `scripts/skills-deploy` — `deprecated/company-workflow` path, template-name validator example
- `scripts/eval.sh`, `scripts/check-gates-update.sh` — skill-name references in usage docstrings + path constants
- `skills/CJ_*/{SKILL,WORKFLOW,scaffold,implement,qa,pipeline,check}.md` — all internal cross-refs (paths, slash-command examples)
- `skills/CJ_*/fixtures/**` — fixture trackers and READMEs updated for self-consistency
- `deprecated/CJ_company-workflow/{SKILL,WORKFLOW}.md`, `bin/knowledge-helpers.sh` — internal refs
- `work-items/tasks/skills/T000018_*` — this tracker's gates + Files section

Out of scope (preserved as immutable history per pre-collected guidance):

- `deprecated/work-items/**` — historical company-workflow trackers
- Active `work-items/**` content under feature/defect/user-story trees authored before T000018
- `TODOS.md` — narrative log of past closed work
- `CHANGELOG.md` entries for prior versions

## Insights

<!-- Non-obvious findings worth remembering. Things that surprised you,
     patterns discovered, or context that future readers will need. -->

- The rename is **self-referential**: `/personal-pipeline` is in flight using the OLD name during this scaffold. Rename takes effect only after `skills-deploy install` re-syncs `~/.claude/skills/` post-merge. Expected; not blocking.
- The `work-copilot/` bundle is a **byte-identical mirror** of `deprecated/company-workflow/`. Both must update together. `validate.sh` Error check 10 (`MIRROR_SPECS` array) enforces this — adding a new mirror dir is one new line in the array. The rename touches mirror entries on both sides.
- **Catalog `templates_source` field** drives template path resolution for deprecated skills (per CLAUDE.md "Deprecated skills convention"). Updating the catalog field is the primary lever; physical rename of `deprecated/company-workflow/templates/` follows.
- Slash-command form becomes `/CJ_personal-pipeline`, `/CJ_personal-workflow`, etc. after deploy — a user-visible UX change. CHANGELOG entry should call it out as breaking with the one-line redeploy instruction.
- Convention alignment: matches `anthropic-skills:*` and `KB_*` namespacing already on this user's machine. Pure disambiguation — zero functional change.

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

- 2026-05-09: [decision] Approach B (full rename) chosen over A (frontmatter-only) and C (catalog annotation). Summary: only B achieves the stated goal of ownership clarity + collision prevention. A is a half-measure that breaks catalog conventions; C doesn't solve the slash-command collision.
- 2026-05-09: [decision] Prefix is `CJ_` (user explicitly chose). Summary: aligns with `anthropic-skills:*` / `KB_*` patterns; underscore separator avoids slug-character ambiguity in directory names.
- 2026-05-09: [decision] All 8 skills get the prefix uniformly — no opt-outs. Summary: deterministic, easy-to-explain rule; per-skill exceptions would re-introduce the disambiguation gap the rename is meant to close.
- 2026-05-09: [impl-decision] Used `perl -i -pe` with negative lookaround word boundaries `(?<![A-Za-z0-9_-])\Q${w}\E(?![A-Za-z0-9_-])` for bulk rename across 30+ files. Summary: avoids over-matching `CJ_personal-workflow` itself (already-prefixed forms must NOT be re-prefixed); shell `sed -i` word-boundary support is non-portable across BSD/GNU. The negative-lookaround form treats `_` and `-` as word characters, preserving identifiers like `personal-workflow` but allowing matches inside paths like `templates/personal-workflow/foo.md`.
- 2026-05-09: [impl-finding] Manifest filenames retained without CJ_ prefix: `personal-artifact-manifests.json` and `company-artifact-manifests.json`. Summary: only the directory was renamed; manifest filenames are catalog-referenced via `files[]` arrays and intentionally kept stable to localize the breaking surface. Updated `scripts/test.sh` D000014-guard `_PREFIX` extraction to strip the new `CJ_` prefix before computing manifest filename.
- 2026-05-09: [impl-finding] `validate.sh` MIRROR_SPECS check 10 stayed green throughout — `work-copilot/` byte-mirror was updated in the same wave as `deprecated/CJ_company-workflow/` source so byte-identity never broke between the two trees.
- 2026-05-09: [impl-decision] Major-bumped each renamed skill (system-health 1.0→2.0, personal-workflow 3.0→4.0, company-workflow 4.0→5.0, others 0.1→1.0) and the collection (1.15.1→2.0.0). Summary: matches "breaking change" per design; `name:` is part of every skill's public surface.
- 2026-05-09: [impl-pass] Validate + test green after rename. `scripts/validate.sh` exit 0 (zero errors, zero warnings); `scripts/test.sh` exit 0 (zero failures, includes test-deploy.sh end-to-end).
- 2026-05-09: [qa-smoke] 1: green — `./scripts/validate.sh` exit 0; 10+ error checks pass (Errors: 0, Warnings: 0, RESULT: PASS); MIRROR_SPECS check 10 green between `deprecated/CJ_company-workflow/` and `work-copilot/`.
- 2026-05-09: [qa-smoke] 2: green — `./scripts/test.sh` exit 0; full suite green (Failures: 0); includes `test-deploy.sh` end-to-end against renamed skills.
- 2026-05-09: [qa-smoke] 3: green — `./scripts/generate-readme.sh` regenerates README.md cleanly; diff shows `CJ_*` names replacing old unprefixed ones; zero added lines reference old bare skill names.
- 2026-05-09: [qa-smoke] 6: green — catalog cross-references resolve; every `.depends.skills[]` entry (CJ_implement-from-spec, CJ_personal-workflow, CJ_qa-work-item, CJ_scaffold-work-item) matches a catalog `name`; zero dangling refs.
- 2026-05-09: [qa-smoke] 7: green — bare-old-skill-name reference count is 0 when run with the test-plan's literal regex (escaped pipes, as written). With un-escaped ERE the regex over-matches the English verb "suggest" 5 times (CLAUDE.md L42; work-copilot/philosophy/* prose) — none reference the old skill name; with `suggest` removed from the regex, count drops to 0. Intent of row 7 (no leftover skill-name references) satisfied.
- 2026-05-09: [qa-smoke] 9: green — all 8 catalog entries got major version bumps (system-health 1.0→2.0, personal-workflow 3.0→4.0, company-workflow 4.0→5.0, others 0.1→1.0); collection VERSION 1.15.1 → 2.0.0.
- 2026-05-09: [qa-deferred] 4: `skills-deploy install` mutates `~/.claude/`; defer to /ship's land+deploy phase post-merge.
- 2026-05-09: [qa-deferred] 5: `skills-deploy doctor` reads/reports on `~/.claude/`; defer to post-deploy state in /ship's land+deploy phase.
- 2026-05-09: [qa-deferred] 8: `/CJ_personal-workflow check` slash-command works post-deploy; deferred — requires post-deploy registration of new slash-command name; will validate post-merge.
- 2026-05-09: [qa-deferred] 10: self-rename of `personal-workflow` doesn't break Phase 3 boundary check; deferred — requires post-deploy state with renamed skills live; will validate post-merge.
- 2026-05-09: [qa-smoke-summary] green: 6/6 non-deferred non-manual rows green (rows 1, 2, 3, 6, 7, 9); 4 rows (4, 5, 8, 10) deferred to post-merge land+deploy phase.
- 2026-05-09: [qa-pass] T000018 (task): green smoke from test-plan rows (6/6 executable rows green; 4 deferred to post-deploy). No qa-owned Phase 2 gates per task template; Phase 3 `Test-plan verified` gate awaits /ship-time inference and post-deploy execution of deferred rows 4/5/8/10.
- 2026-05-09: [auto-final-gate-approved] Step 8.5 final approval gate green. 1 mechanical + 4 user_challenge_approved decisions accepted. Ready for /ship pre-landing review. run_id=20260509-222321-64825
