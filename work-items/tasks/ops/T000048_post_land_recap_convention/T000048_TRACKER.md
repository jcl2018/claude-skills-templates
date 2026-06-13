---
name: "Post-land recap convention"
type: task
id: "T000048"
status: active
created: "2026-06-13"
updated: "2026-06-13"
parent: ""
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "claude/cool-lichterman-cbb4b0"
blocked_by: ""
---

<!-- Source design doc:
     /Users/chjiang/.gstack/projects/jcl2018-claude-skills-templates/20260613-012005-design-post-land-recap.md
     (APPROVED 2026-06-13, via /CJ_goal_feature → /office-hours). The design context
     is distilled into ## Insights below; this is a convention-only doc addition,
     so no separate DESIGN.md per the skip-design-for-small-todos convention. -->

## Lifecycle

### Phase 1: Track

1. Read parent tracker to understand scope and acceptance criteria
2. Create working branch: `git checkout -b feat/{slug}`
   (use parent's branch if the task ships in the same PR; create a new branch if it warrants its own PR)
3. Scaffold required docs:
   - `test-plan.md` (test scenarios for this task) — from `templates/doc-test-plan.md`
4. Populate Files section with expected changed files
5. Write initial Todos from parent's acceptance criteria

**Gates:**
- [x] Parent scope read (parent tracker reviewed)
- [x] Working branch created (`branch` field populated)
- [x] Required docs scaffolded (test-plan)
- [x] Files section populated

### Phase 2: Implement

1. Work from `/office-hours` design doc + parent's acceptance criteria + your Todos
   → design doc at `~/.gstack/projects/{slug}/`
2. Commit changes incrementally with descriptive messages
3. Update Todos section — check off completed items, add discoveries
4. Update Files section with actual changed files

**Gates:**
- [ ] Core changes committed (>=1 commit SHA in Log)
- [x] Todos section reflects remaining work (no stale items)
- [x] Files section updated with changed files

### Phase 3: Ship

1. Run `/CJ_personal-workflow check` — verify no regressions
2. Verify test-plan: all test scenarios passing
3. Run `/ship` — creates PR, bumps version, updates changelog (includes pre-landing code review)
4. Run `/land-and-deploy` — merges PR and verifies deployment

❌ If tests fail: fix, re-run
❌ If CI fails: fix, push, re-run `/ship`

**Gates:**
- [ ] `/CJ_personal-workflow check` — validation passed
- [ ] Test-plan verified (all scenarios passing)
- [ ] `/ship` — PR created
- [ ] `/land-and-deploy` — merged and deployed

## Acceptance Criteria

<!-- From the design doc's Goal + Scope + Test plan. -->

- [ ] A new `## Post-land recap` section is added to the project `CLAUDE.md`,
      adjacent to the existing `## CI/CD merge convention` section.
- [ ] The section instructs the agent to surface a concise two-part recap
      AFTER any land/merge succeeds (verified MERGED): **What this merge did**
      (1–3 lines: change + version + PR#/merge SHA) and **How to verify it**
      (concrete commands/checks for that change).
- [ ] The section names both trigger paths: a direct `/land-and-deploy`
      invocation AND a `cj_goal` orchestrator's land step (`CJ_goal_defect`
      Step 10, `CJ_goal_todo_fix`'s `/ship → /land-and-deploy` tail).
- [ ] The section states the advisory posture: it never blocks, never changes
      the land outcome, and fires only after the merge is verified MERGED.
- [ ] `scripts/validate.sh` → `RESULT: PASS` (CLAUDE.md stays a declared root
      operational doc; Check 15/17 declared⇔on-disk green; Check 19 N/A).
- [ ] `scripts/test.sh` → full suite green (no behavioral surface touched).
- [ ] Doc-sync (`/CJ_document-release`) green: no other registered doc goes
      stale from this addition.

## Todos

<!-- Actionable items for this task. Not lifecycle duplicates — these are
     the actual things to build, fix, or investigate. -->

- [x] Add the `## Post-land recap` section to `CLAUDE.md`, placed adjacent to
      `## CI/CD merge convention`.
- [x] Write the two-part recap instruction (What this merge did / How to verify it)
      with the advisory framing and the MERGED-verified trigger.
- [x] Enumerate both trigger paths (direct `/land-and-deploy` + the two
      auto-land orchestrators).
- [ ] Run `scripts/validate.sh` and `scripts/test.sh`; confirm green (QA phase).

## Log

<!-- Chronological entries with dates and commit SHAs. Each entry records
     what happened, not what should happen. -->

- 2026-06-13: Created. Add a `## Post-land recap` convention section to CLAUDE.md
  so the agent auto-surfaces a what-changed / how-to-verify recap after every land.
- 2026-06-13: Built via /CJ_goal_feature (office-hours → silent build). Implemented the CLAUDE.md section; QA green (smoke 7/7; Step 8.6 doc+test audits 0 findings). Squashed to one `v6.0.71` commit at ship; STOPPED at the PR (PR-stop; no auto-merge).

## PRs

<!-- PR links with status (open/merged/closed). -->

- [#269](https://github.com/jcl2018/claude-skills-templates/pull/269) — open (v6.0.71) — add the `## Post-land recap` convention to CLAUDE.md.

## Files

<!-- Affected file paths. Populated during Track phase, updated during Implement. -->

- `CLAUDE.md` — add the `## Post-land recap` section.

## Insights

<!-- Non-obvious findings worth remembering. Things that surprised you,
     patterns discovered, or context that future readers will need. -->

- Convention-only is the only mechanism that can cover the **direct
  `/land-and-deploy`** path: `/land-and-deploy` is an upstream gstack skill this
  workbench never edits (same rule that makes `/CJ_document-release` *wrap*
  `/document-release`), so the recap cannot live inside the gstack skill, and
  there is no workbench-owned pipeline step on the direct-land path.
- The two auto-land orchestrators (`CJ_goal_defect`, `CJ_goal_todo_fix`) already
  read CLAUDE.md, so one convention covers all three paths — no per-pipeline
  churn, no new test-spec gate rows, no USAGE drift.
- A standalone `/CJ_land_recap` skill was rejected as overkill (a catalog entry +
  USAGE + tests + decision-tree docs is heavy for an advisory reminder).
- `CLAUDE.md` is a declared **operational** doc in the `doc-spec.md` registry
  (root `*.md`, pinned for an external-tool reason), so editing it is in-contract;
  it is NOT a human-doc, so the no-work-item-ID lint (Check 19) does not constrain it.
- Accepted risk: a convention only fires if the agent reads CLAUDE.md, and there
  is no machine enforcement that the recap fired — intentional, matching the
  posture of the other CLAUDE.md convention sections. If it proves unreliable in
  long auto-land runs, the deferred "orchestrator steps" alternative is the
  upgrade path.

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

- [decision] 2026-06-13 — Chose "Convention only" (add one `## Post-land recap`
  section to CLAUDE.md) over "Convention + orchestrator pipeline steps" and over
  a standalone `/CJ_land_recap` skill. Summary: convention-only is the single
  mechanism that covers the direct `/land-and-deploy` path (gstack skill is
  off-limits) while also covering the two auto-land orchestrators that already
  read CLAUDE.md; the alternatives add per-pipeline churn or a heavy skill for an
  advisory reminder. Out of scope (deferred): wiring explicit recap steps into
  the defect/todo pipelines and any standalone recap skill/helper.
- 2026-06-13 [impl-finding] Scaffold left all Phase 1 gates unchecked, but the
  Phase 1 work was genuinely done (branch `claude/cool-lichterman-cbb4b0`
  populated + matches HEAD, test-plan scaffolded, Files section populated, parent
  scope = the APPROVED design doc distilled into ## Insights). Marked the four
  Phase 1 gates to reflect true state rather than halt the silent --auto run on a
  bookkeeping gap.
- 2026-06-13 [impl] Added the `## Post-land recap` section to `CLAUDE.md`,
  inserted immediately before `## Work item templates` (at the end of the
  `## CI/CD merge convention` material). Verbatim approved content: two-part recap
  (What this merge did / How to verify it), all three land paths enumerated
  (direct `/land-and-deploy`, `CJ_goal_defect` Step 10, `CJ_goal_todo_fix` tail),
  MERGED-verified trigger, advisory posture. Single-file change; tracker
  bookkeeping the only other write.
- 2026-06-13 [impl-auto] Auto-mode run; --auto honored (1 file touched — CLAUDE.md;
  no sensitive surface — CLAUDE.md is a declared operational root doc, not catalog/
  manifest/template/validator/hook).
- 2026-06-13 [impl-pass] T000048: implementation complete. Phase 2
  implementer-owned gates transitioned.
- 2026-06-13 [qa-smoke] 1 (Section exists): green — `grep -c '^## Post-land recap' CLAUDE.md` prints `1` (exit 0).
- 2026-06-13 [qa-smoke] 2 (Two recap parts named): green — section names both parts: **What this merge did** (change + version + PR#/squash-merge SHA, CLAUDE.md:274) and **How to verify it** (concrete commands/checks for this change, CLAUDE.md:278).
- 2026-06-13 [qa-smoke] 3 (Both trigger paths named): green — section enumerates direct `/land-and-deploy` (CLAUDE.md:262), `CJ_goal_defect` land Step 10 (CLAUDE.md:263), and `CJ_goal_todo_fix` `/ship → /land-and-deploy` tail (CLAUDE.md:264).
- 2026-06-13 [qa-smoke] 4 (Advisory posture stated): green — section states recap never blocks, never changes the land outcome, adds no gate (CLAUDE.md:283), fires only after merge verified MERGED (CLAUDE.md:271).
- 2026-06-13 [qa-smoke] 5 (Placement): green — `## Post-land recap` (CLAUDE.md:256) sits immediately after `## CI/CD merge convention` (lines 91–255), adjacent to it.
- 2026-06-13 [qa-smoke] 6 (Doc contract green): green — `./scripts/validate.sh` → `RESULT: PASS` (exit 0); Check 15 declared⇔on-disk PASS, Check 17 root allowlist PASS, Check 19 N/A (CLAUDE.md operational, not human-doc; 5 human-docs scanned).
- 2026-06-13 [qa-smoke] 7 (Full suite green): green — `./scripts/test.sh` → `RESULT: PASS` (exit 0, 0 failures); no behavioral surface touched.
- 2026-06-13 [qa-smoke-summary] green: 7/7 non-manual rows green (0 manual rows pending).
- 2026-06-13 [qa-audit] AUDITS=doc:ok,test:ok,spec_updates:test-spec-custom:none,doc-spec-custom:none (Step 8.6a-d; findings ride the green RESULT — checkpoint decision belongs to the orchestrator). doc: STAGE1/2/3=0/0/0 (14 docs); test: STAGE1/2/3=0/0/0 (66 units). No test surface or new declared doc added by this change (doc-only).
- 2026-06-13 [qa-pass] T000048 (task): green smoke from test-plan rows (7 rows). No qa-owned Phase 2 gates per template; Phase 3 `Test-plan verified` gate awaits /ship-time inference.
