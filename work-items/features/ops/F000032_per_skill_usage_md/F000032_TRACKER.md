---
name: "Per-skill USAGE.md convention + audit"
type: feature
id: "F000032"
status: active
created: "2026-06-01"
updated: "2026-06-01"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "cj-feat-20260601-152835-3769"
blocked_by: ""
---

<!-- Prerequisite: Before scaffolding this work item, run /office-hours to
     produce a design plan in ~/.gstack/projects/. Distill that plan into
     DESIGN.md during Phase 1 below. -->

## Lifecycle

### Phase 1: Track

1. Create working branch: `git checkout -b cj-feat-20260601-152835-3769`
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

- [ ] `templates/doc-SKILL-USAGE.md` exists with the five required H2 sections (When to use / When NOT to use / Mental model / Common pitfalls / Related skills) and DESIGN.md-shaped frontmatter (skill-name, version, status, created, last-updated).
- [ ] `skills/{name}/USAGE.md` exists for every routable non-deprecated skill in `skills-catalog.json` (predicate: `status != "deprecated"` AND non-empty `files`). Current audit set = 11 skills (CJ_system-health, CJ_personal-workflow, CJ_goal_todo_fix, CJ_scaffold-work-item, CJ_qa-work-item, CJ_implement-from-spec, CJ_personal-pipeline, CJ_suggest, CJ_improve-queue, CJ_goal_feature, CJ_goal_defect).
- [ ] Every USAGE.md contains all five required H2 sections, line-anchored (`^## When to use$`, `^## When NOT to use$`, `^## Mental model$`, `^## Common pitfalls$`, `^## Related skills$`) — no placeholder content; each section has at least a short paragraph distilled from the skill's SKILL.md description + rules/skill-routing.md.
- [ ] `scripts/validate.sh` has a new Check 13 ("per-skill USAGE.md present + required sections") that fires ERROR on missing USAGE.md or missing required H2 for any routable non-deprecated skill.
- [ ] `./scripts/validate.sh` exits 0 with 0 errors / 0 warnings on this PR's HEAD.
- [ ] `./scripts/test.sh` exits 0 on this PR's HEAD.
- [ ] `doc/PHILOSOPHY.md` has a NEW top-level section `## Documentation surfaces` placed between `## Key patterns and conventions` and `## Decision tree`, documenting the three-doc-per-skill model (SKILL.md required, USAGE.md required for routable non-deprecated skills, DESIGN.md optional) and the validate.sh Check 13 audit rule.
- [ ] Each entry under `doc/PHILOSOPHY.md ## Decision tree` for an active routable skill gains a one-line link to its USAGE.md (e.g., `[USAGE](../skills/{name}/USAGE.md)`).
- [ ] `CLAUDE.md` "Skill directory structure" lists `USAGE.md` as required between `SKILL.md` and `*.md  # optional supporting files`.
- [ ] `CLAUDE.md` "Creating a new skill" instructs new-skill authors to create `skills/{name}/USAGE.md` from `templates/doc-SKILL-USAGE.md`; existing step about DESIGN.md is updated to clarify DESIGN.md stays optional.
- [ ] `skills-catalog.json` is NOT modified to add USAGE.md to per-skill `files` arrays or as a deployed template — USAGE.md is human-reading, in-repo only, not deployed to `~/.claude/skills/{name}/`. The `templates/doc-SKILL-USAGE.md` template likewise lives in-repo and is not added to any catalog `templates` entry.
- [ ] No `deprecated/` skills get USAGE.md (audit predicate excludes `status: deprecated`); `work-copilot/` is untouched (workbench-only scope).
- [ ] CHANGELOG.md has an entry for the next free version slot describing the feature in user-forward voice ("feat: F000032 per-skill USAGE.md convention + validate.sh audit — every routable non-deprecated skill now has a USAGE.md best-practice doc next to its SKILL.md; PHILOSOPHY.md decision tree links each entry to the new USAGE.md.").

## Todos

<!-- Actionable items for this feature. Break into child tasks for
     large features. -->

- [ ] Ship S000065 (`per_skill_usage_md_impl`) — implementation user-story (new template + 11 USAGE.md backfills + validate.sh Check 13 + CLAUDE.md edits + PHILOSOPHY.md edits)
- [ ] End-to-end pipeline run — `/ship` opens PR; `./scripts/validate.sh` PASS; `./scripts/test.sh` PASS; manual smoke = follow PHILOSOPHY decision-tree link into a random USAGE.md and confirm it answers "should I invoke this skill?"

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-06-01: Created. Adds per-skill USAGE.md convention (operator + agent "when to use / when not / mental model / pitfalls / related" surface) + validate.sh Check 13 audit + 11 backfill files + PHILOSOPHY.md documentation-surfaces section + decision-tree USAGE links. Extends F000030's named-doc audit pattern from the workbench-overview level down to the per-skill leaf level.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. Populated during Track phase, updated during Implement. -->

- `templates/doc-SKILL-USAGE.md` (NEW — template with five required H2 sections + DESIGN.md-shaped frontmatter)
- `skills/CJ_system-health/USAGE.md` (NEW)
- `skills/CJ_personal-workflow/USAGE.md` (NEW)
- `skills/CJ_goal_todo_fix/USAGE.md` (NEW)
- `skills/CJ_scaffold-work-item/USAGE.md` (NEW)
- `skills/CJ_qa-work-item/USAGE.md` (NEW)
- `skills/CJ_implement-from-spec/USAGE.md` (NEW)
- `skills/CJ_personal-pipeline/USAGE.md` (NEW)
- `skills/CJ_suggest/USAGE.md` (NEW)
- `skills/CJ_improve-queue/USAGE.md` (NEW)
- `skills/CJ_goal_feature/USAGE.md` (NEW)
- `skills/CJ_goal_defect/USAGE.md` (NEW)
- `scripts/validate.sh` (MODIFIED — add Check 13: per-skill USAGE.md present + required sections)
- `doc/PHILOSOPHY.md` (MODIFIED — new `## Documentation surfaces` section + decision-tree USAGE links)
- `CLAUDE.md` (MODIFIED — Skill directory structure + Creating a new skill steps)
- `CHANGELOG.md` (MODIFIED — F000032 entry)

## Insights

<!-- Non-obvious findings worth remembering. Design decisions,
     trade-offs, patterns discovered. -->

- **Smallest self-documentation feature that survives 12 months.** One new file class (USAGE.md), one new template, one new validate.sh check, 11 backfills. SKILL.md (loaded into agent context every invocation) stays unchanged — operator-facing best-practice prose lands in a sibling file with no per-turn token cost.
- **Audit predicate diverges from F000030's intentionally.** F000030's `## New-skills check` uses `status == "active"` because it gates `doc/PHILOSOPHY.md ## Decision tree` placement (decision tree = ship-stable only). F000032's predicate uses `status != "deprecated"` because operators + the agent route to `experimental` skills today (CJ_goal_feature/defect/scaffold-work-item/etc.); routability requires USAGE.md too. The 5 deprecated shims (CJ_goal_run, CJ_goal_auto, CJ_goal_investigate, cj_goal_feature, cj_goal_defect) and tooling-only `templates` entry (files: []) are excluded automatically.
- **USAGE.md is NOT deployed to ~/.claude/.** Constraint #6 (no deploy surface): USAGE.md is human-reading, agent has SKILL.md already. Less to deploy = less drift. Reconsider if a future /skill-help skill needs USAGE.md at runtime.
- **DESIGN.md stays optional, distinct from USAGE.md.** Two different readers: USAGE.md = operator + agent ("when / why"); DESIGN.md = developer ("how was this built"). Only 1/13 skills had DESIGN.md after 8 days — proves "optional" decays. USAGE.md is required from day 1 + audited.
- **Audit grep is line-anchored, not substring.** `^## When to use$` rejects substring matches inside code fences. Without line-anchor, a USAGE.md that quotes its own required headings inside a fenced block would falsely pass.
- **Atomic-commit ordering matters for pre-commit hook.** validate.sh runs in setup-hooks.sh's pre-commit. If Check 13 lands separately from the 11 USAGE.md backfills, intermediate commits fail. /ship's commit-once-at-end is the natural mitigation; the only failure mode is operator running `git commit` between stages mid-implement.

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

- 2026-06-01 [decision] Chose Approach B (new required USAGE.md file class with five required H2 sections, validate.sh Check 13 audit) over Approach A (lift existing DESIGN.md from optional to required) and Approach C (required `## Philosophy` H2 section inside each SKILL.md). Summary: B directly matches the user's "best-practice per skill" framing; A would force 12 backfills of a doc shape the user didn't ask for (design-rationale, not when-to-use); C grows every SKILL.md with operator-facing prose, paying a per-turn token cost on every invocation. B's cost — one new file class + new template + one new audit check + 11 backfills — is bounded and the audit prevents decay (F000030's 1/13 DESIGN.md adoption proved unenforced docs rot).
- 2026-06-01 [decision] Audit predicate is `status != "deprecated"` with non-empty `files`, NOT F000030's `status == "active"`. Summary: F000030's predicate gates decision-tree placement (ship-stable only). F000032 audits routability — operators route to `experimental` skills (CJ_goal_feature, CJ_goal_defect, CJ_scaffold-work-item, etc.) today, so USAGE.md must cover them. The 5 deprecated shims + tooling-only `templates` entry are excluded automatically. Re-verified against catalog HEAD on 2026-06-01: audit set = 11 skills (3 active + 8 experimental).
- 2026-06-01 [decision] USAGE.md stays in-repo; NOT deployed by skills-deploy install. Summary: USAGE.md is human-reading. Agent gets SKILL.md (the agent-facing file) on every invocation; USAGE.md doesn't need runtime delivery. Less surface to deploy = less drift between source and `~/.claude/`. If a future `/skill-help` skill wants USAGE.md at runtime, deployment can be added without breaking changes.
- 2026-06-01 [decision] Audit is ERROR severity, not WARN. Summary: F000030 establishes that missing PHILOSOPHY.md decision-tree entries are ERROR. USAGE.md matches that severity — both are mandatory per-skill documentation surfaces. WARN would replay F000030's 1/13 adoption story (the failure mode the audit exists to prevent).
- 2026-06-01 [decision] Single child user-story decomposition. Summary: The work is one cohesive change (template + 11 backfills + validate.sh check + CLAUDE.md + PHILOSOPHY.md edits) that ships together — they atomic-commit under the pre-commit hook. Splitting into multiple stories adds bookkeeping cost without splitting the actual risk surface. F000030 used the same shape (single S000063 child) with no regrets.
- 2026-06-01 [decision] Frontmatter recommended but NOT audited. Summary: The template ships with skill-name/version/status/created/last-updated frontmatter for visual consistency with DESIGN.md, but Check 13 does not validate frontmatter presence or shape — only the five H2 section headings. Over-constraining frontmatter is a separate, lower-value concern.
- 2026-06-01 [decision] No README.md changes. Summary: scripts/generate-readme.sh regenerates README.md from skills-catalog.json. Adding a USAGE.md column would require a catalog field + script change + regeneration. Deferred to a TODOS follow-up row tagged P3/S if the user finds README.md insufficient after v1 ships.
- 2026-06-01 [gates-update] Child S000065 Phase 2 Implement complete. Summary: 11 USAGE.md backfills + template + validate.sh Check 13 + CLAUDE.md + PHILOSOPHY.md edits written in worktree cj-feat-20260601-152835-3769 via /CJ_implement-from-spec leaf subagent under /CJ_goal_feature. Atomic commit at /ship (next phase).
- 2026-06-01 [qa-fail] Child S000065 QA RED via /CJ_qa-work-item leaf subagent. Summary: validate.sh PASS + 4 of 5 smoke tests PASS (S1 template H2; S2 11 USAGE.md H2; S3 missing-file ERROR; S4 missing-section ERROR). Smoke S5 FAIL: ./scripts/test.sh exit 1 — integration test at scripts/test.sh:179-204 (`Integration test: manual skill creation cycle`) scaffolds `zzz-test-scaffold` with only SKILL.md (the pre-F000032 CLAUDE.md-guided shape) and Check 13 now ERRORs because no USAGE.md was created. Fix is mechanical: extend test.sh to also write a templated USAGE.md for zzz-test-scaffold and add the USAGE.md path to the EXIT trap cleanup. Feature blocked at Phase 2 gate `All child stories have entered Phase 2+` until S000065 turns green. See S000065_TRACKER.md journal for verbatim snippets.

- 2026-06-01T23:09:08Z [qa-reverify] Orchestrator applied one-line fix to scripts/test.sh:194 (added USAGE.md scaffolding for zzz-test-scaffold inside the existing integration-test heredoc block; EXIT trap unchanged — `rm -rf $SKILLS_DIR/zzz-test-scaffold` already covers the new file). Re-ran ./scripts/test.sh → RESULT: PASS (Failures: 0, all 12 tests OK). ./scripts/validate.sh → PASS (0 errors / 0 warnings; Check 13 + all 11 USAGE.md). Phase 2 QA-owned gates now green; ready for /ship.
