---
name: "/cj_goal_defect skill — reshape of investigate v1.1 + no-doc bug-report scaffolding"
type: user-story
id: "S000058"
status: active
created: "2026-05-21"
updated: "2026-05-21"
parent: "F000027"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "claude/hardcore-hermann-c2b955"
blocked_by: ""
# pr: ""
---

<!-- Prerequisite: derives directly from the parent feature's /office-hours
     session; the parent F000027_DESIGN.md is sufficient design context. -->

## Lifecycle

### Phase 1: Track

1. Read parent tracker to understand scope
2. Create working branch: `git checkout -b feat/cj_goal_two_verb_refactor` (or use parent's branch if shipping in same PR)
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
- [ ] Acceptance criteria verified met
- [ ] Smoke tests pass
- [x] Todos section reflects remaining work (no stale items)
- [x] Files section updated with changed files

### Phase 3: Ship

1. Run `/CJ_personal-workflow check` — verify all validation passes
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
- [ ] All children shipped (if any)
- [ ] `/ship` — PR created (with pre-landing review)
- [ ] `/land-and-deploy` — merged and deployed

## Acceptance Criteria

<!-- What "done" looks like for this story. -->

- [ ] `/cj_goal_defect "<bug>"` with no pre-existing defect dir scaffolds a bug report into `.inbox/<slug>/DRAFT.md` (no existing defect dir assumed).
- [ ] `/investigate` runs as an Agent subagent with sentinel-wrapped JSON output; the Iron-Law holds — no fix promotes without a populated root cause.
- [ ] On root cause, RCA + test-plan are written and the `.inbox` draft is promoted to `work-items/defects/.../D000NNN_<slug>/`.
- [ ] The tail keeps the human `/ship` Gate #2 then runs `/land-and-deploy --suppress-readiness-gate`; halt taxonomy + telemetry inherit `/CJ_goal_investigate` unchanged.
- [ ] Nesting depth ≤ 2 (orchestrator → leaf subagent); no subagent-spawns-subagent path.

## Todos

<!-- Actionable items for this story. -->

- [x] Author `skills/cj_goal_defect/SKILL.md` reshaping investigate v1.1's flat `pipeline.md` (~80% reuse). (SKILL.md + pipeline.md split, mirroring CJ_goal_investigate.)
- [x] Implement no-doc bug-report scaffolding (`.inbox/<slug>/DRAFT.md` → promote after Iron-Law). (pipeline.md Steps 2 + 7.4.)
- [x] Wire `/investigate` as an Agent subagent with sentinel-wrapped JSON; reuse the v1.1 halt taxonomy. (pipeline.md Steps 5–7; isolation gate Step 5.0.)
- [x] Wire the tail: `/CJ_qa-work-item` → `/ship` (Gate #2) → `/land-and-deploy --suppress-readiness-gate` + tracker journal + telemetry. (pipeline.md Steps 8–11; telemetry → `CJ_goal_defect.jsonl`.)
- [x] Add a catalog entry (`experimental`). (Routing line is out of scope here — S000059/S000060 own `rules/skill-routing.md`.)
- [ ] (Deferred — S000059/S000060) Add the `/cj_goal_defect` routing line to `rules/skill-routing.md`.

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-05-21: Created. The `defect` verb — a reshape of `/CJ_goal_investigate` v1.1's flat pipeline with no-doc bug-report scaffolding; ~80% reuse, defect-first per Approach C.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. -->

- `skills/cj_goal_defect/SKILL.md` (NEW) — defect orchestrator: preamble, worktree-via-common, path resolution, overview, usage, error table, halt taxonomy, idempotency, notes.
- `skills/cj_goal_defect/pipeline.md` (NEW) — flat flow: parse → scaffold draft → isolation gate → /investigate dispatch → FIX_PLAN/DEBUG_REPORT parse (Iron-Law) → promote → RCA+test-plan → QA → ship → land-and-deploy → journal + telemetry. (Reshape kept the separate flow doc, mirroring CJ_goal_investigate.)
- `skills-catalog.json` (MODIFIED) — added the `experimental` `cj_goal_defect` entry (v0.1.0; depends CJ_qa-work-item + CJ_personal-workflow; files = SKILL.md + pipeline.md).
- `scripts/cj-goal-common.sh` (CONSUMED, not modified; owned by S000057) — `--mode defect` for the worktree + pr-check + telemetry-receipt phases.

## Insights

<!-- Non-obvious findings worth remembering. -->

- `defect` mirrors current `/CJ_goal_investigate` (human `/ship` gate → deploy), so the Iron-Law gate comes for free via `/investigate` and ~80% of the existing flat `pipeline.md` is reusable.
- The two tails genuinely differ from `feature` (defect human-ships-then-deploys; feature PR-stops), which is why there is no shared tail doc — the common bits are the deterministic `cj-goal-common.sh` only.

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

- [decision] 2026-05-21: `defect` keeps the human `/ship` Gate #2 then deploys (Open Question 4 RESOLVED). Summary: symmetry with current investigate; the human diff review is the autonomy ceiling for bug fixes too.
- [decision] 2026-05-21: Build `defect` first (Approach C sequencing). Summary: ~80% reuse of investigate v1.1 makes it the lower-risk first ship; pair with S000057's early feature smoke harness so the feature path isn't left unvalidated.
- [impl-decision] 2026-05-21: Kept the SKILL.md + pipeline.md split (mirrored CJ_goal_investigate) rather than a single SKILL.md. Summary: matches the reuse source 1:1 so the ~80% reshape is auditable side-by-side; SKILL.md owns frontmatter/overview/halt-table/notes, pipeline.md owns the step logic.
- [impl-decision] 2026-05-21: Dropped the defect resolver entirely — `cj_goal_defect` is always-draft. Summary: investigate v1.1 resolves a D-ID/fragment then optionally captures a draft on zero-match; the defect verb starts from raw text by contract, so Step 2 unconditionally scaffolds `.inbox/<slug>/DRAFT.md` (IS_DRAFT=1 always) and the canonical-resolve halts (`halted_at_resolve_ambiguous`/`_zero`) + the R/F/P/M fix-in-tree anomaly row are dropped as inapplicable on the entry path.
- [impl-decision] 2026-05-21: Telemetry written inline to `~/.gstack/analytics/CJ_goal_defect.jsonl` (capital-CJ), NOT delegated to cj-goal-common.sh's `cj-goal-defect.jsonl` stream. Summary: SPEC Architecture + TEST-SPEC S5 + the build-scope all name the capital-CJ family path (matches CJ_goal_investigate.jsonl / CJ_goal_auto.jsonl); the helper writes a distinct lowercase receipt stream. Honored the documented path inline (Step 11, investigate-shaped) and call the helper's telemetry phase only as a best-effort secondary receipt — respects "consume, do not modify cj-goal-common.sh".
- [impl-decision] 2026-05-21: Consumed cj-goal-common.sh `--phase worktree --mode defect` for the worktree entry, but resolved cj-worktree-init.sh DIRECTLY for the Step 5.0 `--assert-isolated` gate. Summary: the common helper does not wrap `--assert-isolated`; the isolation gate needs the raw helper verdict, so it re-resolves the helper (repo-local → manifest .source) the same way investigate does.
- [impl-finding] 2026-05-21: Catalog `files` array intentionally minimal — SKILL.md + pipeline.md only (no per-skill test scripts like CJ_goal_investigate/scripts/). Summary: the build-scope + TEST-SPEC smoke S1–S5 run via `scripts/validate.sh` + `scripts/test.sh` + grep on the SKILL.md; no dedicated test scripts were requested, so none were added (minimal-scope per saved feedback).
- [impl-finding] 2026-05-21: Sensitive-surface AUQ (skills-catalog.json edit) was pre-answered APPROVED by the implementation-runner role; proceeded without AskUserQuestion per instruction (auto-equivalent mode). Summary: the only sensitive surface in scope; logged here per the propose-and-confirm safety-override audit convention.
- [impl-finding] 2026-05-21: `scripts/test-deploy.sh` (and thus `scripts/test.sh`) is RED on a clean HEAD independent of this change — `skills-deploy doctor` WARNs "CJ_goal_auto — source directory missing in repo" because it inspects the globally-deployed ~/.claude/ manifest (v4.6.7, predates the newer experimental orchestrators; see the SKILLS_UPGRADE_AVAILABLE 4.6.7→5.0.2 preamble banner). This change adds one more WARN of the identical class (cj_goal_defect) but does not change the pass/fail outcome. `scripts/validate.sh` is GREEN (0 errors, 0 warnings); both S000057 non-regression smoke tests are GREEN.
- [impl] 2026-05-21: Wrote 2 files (skills/cj_goal_defect/SKILL.md, skills/cj_goal_defect/pipeline.md); modified 1 (skills-catalog.json — added experimental cj_goal_defect entry). validate.sh PASS (0/0); cj-goal-feature-smoke.test.sh PASS (0 failures); cj-worktree-init.test.sh PASS (0 failures, incl. --caller defect → cj-def). TEST-SPEC smoke S1–S4 verified.
- [impl-auto] 2026-05-21: Auto-equivalent run via /CJ_implement-from-spec --auto; the lone sensitive surface (skills-catalog.json) was pre-approved by the runner role, so no AUQ fired.
- [impl-pass] 2026-05-21: S000058 implementation complete. Phase 2 implementer-owned gates transitioned (Todos + Files). QA-owned gates (Acceptance criteria verified met, Smoke tests pass) left for /CJ_qa-work-item.
