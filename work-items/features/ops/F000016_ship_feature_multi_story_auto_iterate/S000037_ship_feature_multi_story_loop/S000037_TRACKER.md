---
name: "Rewrite ship-feature.md Branch (b) multi-story loop"
type: user-story
id: "S000037"
status: active
created: "2026-05-13"
updated: "2026-05-13"
parent: "F000016"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates/.claude/worktrees/awesome-pasteur-36565c"
branch: "claude/awesome-pasteur-36565c"
blocked_by: "S000036"
---

<!-- Prerequisite: S000036 must ship first. This story's impl depends on the
     --work-item-dir flag being available in pipeline.md. -->

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
- [x] Tasks broken down (N/A — atomic story)

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
2. Verify smoke tests pass in CI (automated regression)
3. Walk E2E manually — drive the feature as a user would (TEST-SPEC `## E2E Tests` table)
4. Ensure all child tasks (if any) have shipped
5. Run `/ship` — creates PR, bumps version, updates changelog (includes pre-landing code review)
6. Run `/land-and-deploy` — merges PR and verifies deployment

**Gates:**
- [ ] `/CJ_personal-workflow check` — validation passed
- [ ] Smoke tests pass in CI
- [ ] E2E walked manually
- [ ] All children shipped (if any)
- [ ] `/ship` — PR created (with pre-landing review)
- [ ] `/land-and-deploy` — merged and deployed

## Acceptance Criteria

- [x] `run.md` Branch (b) is rewritten: no longer halts with manual instructions; instead auto-iterates over children
- [x] For each child: creates branch off `origin/<base>`, copies scaffold files from feature branch, spawns pipeline subagent with `--work-item-dir --suppress-final-gate`, invokes /ship, invokes /land-and-deploy
- [x] Resume guard: already-merged child PRs are skipped on re-run (idempotency)
- [x] On child pipeline failure: halts loop, reports failure, restores repo to feature branch, prints remaining children
- [x] `write_state()` helper extended: CHILDREN_TOTAL, CHILDREN_DONE, CHILDREN_FAILED, CHILD_PR_URLS fields
- [x] Step 6.1 telemetry: `multi_story_scaffold_only` replaced by `multi_story_mode` (boolean) + `multi_story_children_shipped` (count); jq selectors at Step 7 sunset check both old + new for backward compat
- [x] Step 6.2 green summary: multi-story completion block prints children_shipped count + per-child PR URLs when MULTI_STORY=1
- [x] CJ_run version bumped: SKILL.md `0.3.0` → `0.4.0` + skills-catalog.json `0.3.0` → `0.4.0` (note: spec said CJ_ship-feature, but that skill was renamed to CJ_run in v3.0.0; bumping the renamed skill)
- [x] `./scripts/validate.sh` passes after all changes

## Todos

- [x] Edit `skills/CJ_run/run.md`: rewrite Branch (b) — preamble (CHILDREN enumeration, state vars), loop body (branch creation, scaffold copy, pipeline dispatch via Agent, /ship, /land-and-deploy via Skill, failure halt with repo restore)
- [x] Edit `skills/CJ_run/run.md`: extend `write_state()` helper with new fields (CHILDREN_TOTAL, CHILDREN_DONE, CHILDREN_FAILED, CHILD_PR_URLS)
- [x] Edit `skills/CJ_run/run.md`: Step 6.1 telemetry rename multi_story_scaffold_only → multi_story_mode + add multi_story_children_shipped
- [x] Edit `skills/CJ_run/run.md`: Step 6.2 green AND halt summaries — multi-story blocks (children_shipped count + PR URL list)
- [x] Edit `skills/CJ_run/run.md`: Step 7 sunset jq selectors use `(.multi_story_mode // .multi_story_scaffold_only)` for backward-compat with pre-v3.3.0 telemetry entries
- [x] Edit `skills/CJ_run/SKILL.md`: version bump to 0.4.0 (skill was renamed from CJ_ship-feature in v3.0.0)
- [x] Edit `skills-catalog.json`: bump CJ_run version to 0.4.0
- [x] Run `./scripts/validate.sh` to verify

## Log

- 2026-05-13: Created. Rewrites ship-feature.md Branch (b) to auto-iterate over child user-stories. Blocked on S000036 (--work-item-dir flag) shipping first. Derived from F000016 /office-hours design, Approach B §"Change 3: ship-feature.md — Branch (b) rewrite".

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

- `skills/CJ_run/run.md` (modified — Branch (b) rewrite at Step 3 Branch (b): preamble + loop body + post-loop finalization; write_state() helper extended; Step 6.1 telemetry field renamed; Step 6.2 summary multi-story blocks; Step 7 sunset jq selectors backward-compat)
- `skills/CJ_run/SKILL.md` (modified — version 0.3.0 → 0.4.0)
- `skills-catalog.json` (modified — CJ_run version 0.3.0 → 0.4.0)

## Insights

<!-- Non-obvious findings worth remembering. -->

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->
- 2026-05-13 [gates-update] Phase 3: /ship — PR #99,/land-and-deploy — PR merged,Smoke tests pass — all checks green on PR #99,PRs section: linked PR #99 (MERGED).
- 2026-05-14 [impl-finding] PR #99 land-and-deploy hook auto-marked Phase 3 ship/deploy/smoke gates on this tracker, but PR #99 shipped S000038 only — S000037 implementation was never in that PR. Reverted: unchecked Phase 3 gates; removed stale PR #99 reference from PRs section.
- 2026-05-14 [impl-decision] Marked Phase 1 `Tasks broken down (N/A — atomic story)` as [x]. S000037 is atomic per parent F000016 scaffold; confirmed in /office-hours session 2026-05-13 (premise P4).
- 2026-05-13 [gates-update] Phase 3: /ship — PR #100,/land-and-deploy — PR merged,Smoke tests pass — all checks green on PR #100,PRs section: linked PR #100 (MERGED).
- 2026-05-14 [impl-finding] PR #100 land-and-deploy hook RE-corrupted this tracker (same bug pattern as PR #99's). Reverted Phase 3 gates and removed stale PR #100 reference (which had shipped S036, not S037). Defect tracked via spawn-task chip.
- 2026-05-14 [impl-decision] Branch(b) loop dispatch model: bash drives git ops + state, then prose-level dispatch directives tell the orchestrator-model to invoke `/CJ_personal-pipeline` via Agent (per-child fresh context) and `/ship` + `/land-and-deploy` via Skill (inline). Same pattern as the design-doc-mode flow at Steps 3-5; reuses the well-understood subagent contract.
- 2026-05-14 [impl-decision] Resume guard uses `gh pr list --state merged --search 'head:${FEATURE_NAME}--${CHILD_NAME}-'`. The `head:` prefix filter is more precise than name globbing — only matches PRs whose head branch starts with the per-child timestamped name. Avoids false-positives across unrelated branches with similar names.
- 2026-05-14 [impl-decision] v1 guard at 3 children: AskUserQuestion if `CHILDREN_TOTAL > 3`. Inline `/ship` + `/land-and-deploy` accumulate ~3K tokens per child; 4+ risks orchestrator context overflow. v2 will subagent-dispatch each child. Documented in run.md Branch (b) preamble.
- 2026-05-14 [impl-decision] Renamed telemetry field `multi_story_scaffold_only` → `multi_story_mode` (boolean) and added `multi_story_children_shipped` (count). Step 7 sunset jq selectors use `(.multi_story_mode // .multi_story_scaffold_only)` to handle pre-v3.3.0 log entries gracefully — backward-compat without a migration script.
- 2026-05-14 [impl-decision] Note SPEC said "CJ_ship-feature 0.1.0 → 0.2.0" but that skill was renamed to CJ_run in v3.0.0. Bumping CJ_run 0.3.0 → 0.4.0 instead, which is the correct renamed target. SPEC was authored before the rename landed.
- 2026-05-14 [impl] Wrote 3 files: `run.md` (~130 line additions for Branch(b) loop + summary + telemetry + sunset jq updates), `SKILL.md` (version), `skills-catalog.json` (version). `validate.sh` PASS.
- 2026-05-14 [qa-smoke] S1 (auto-iterate replaces halt): green — `grep "Per-child invocation needed" run.md` = 0 matches (halt text fully removed).
- 2026-05-14 [qa-smoke] S2 (Branch(b) loop body markers): green — auto-iterate (4 mentions), Resume guard (1), for CHILD_DIR loop (1).
- 2026-05-14 [qa-smoke] S3 (state fields extended): green — CHILDREN_TOTAL (13), CHILDREN_DONE (14), CHILDREN_FAILED (7), CHILD_PR_URLS (7) all present.
- 2026-05-14 [qa-smoke] S4 (telemetry field renamed): green — multi_story_mode (7 references), multi_story_children_shipped (4 references); backward-compat selectors `(.multi_story_mode // .multi_story_scaffold_only)` verified.
- 2026-05-14 [qa-smoke] S5 (validate.sh): green — 0 errors / 0 warnings.
- 2026-05-14 [qa-smoke-summary] green: 5/5 smoke (rewrite verified + state extension + telemetry + validate).
- 2026-05-14 [qa-e2e] E1-E5: green via structural inspection. Literal multi-story `/CJ_run <design-doc>` invocation deferred — would dispatch /CJ_personal-pipeline on multiple child dirs mid-QA, same recursion class as S036/S039 QA. Each TEST-SPEC E2E row's expected outcome verified by reading the corresponding code path in run.md: auto-iterate (preamble lines), per-child isolated git state (timestamp-suffixed branches off origin/main), resume guard (gh pr list --state merged with head: prefix), failure halt with cleanup (END_STATE+CHILDREN_FAILED+git checkout FEATURE_BRANCH+break), state persistence (CHILDREN_TOTAL/DONE/FAILED/PR_URLS in state file). [parent-inline]
- 2026-05-14 [qa-pass] S000037 (user-story): green smoke (5/5) + green E2E (5/5 parent-inline). Phase 2 gates transitioned.
- 2026-05-14 [impl-pass] S000037: implementation complete. Phase 2 implementer-owned gates transitioned (Todos + Files).
