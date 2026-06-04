---
name: "WORKFLOWS granular skill/step/tool/shell enumeration rule + Check 15b structural sub-check"
type: task
id: "T000040"
status: active
created: "2026-06-04"
updated: "2026-06-04"
parent: ""
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "cj-feat-20260604-140658-97792"
blocked_by: ""
---

<!-- Source design doc (/office-hours, APPROVED — hardened through an adversarial spec
     review, 7/10, whose fixes are folded into the Scope/Constraints below):
     ~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-cj-feat-20260604-140658-97792-design-20260604-141201.md
     Design context distilled into ## Insights below. This task tightens doc/WORKFLOWS.md's
     requirement so each CJ_goal_* section must enumerate ALL skills/steps/tools/shell at the
     granular helper+step level (worktree init/delete, cj-goal-common.sh --phase sync, etc.),
     enforces the STRUCTURE of that via a validate.sh Check 15b sub-check (4 anchored Touches
     sub-bullets) + a standalone test.sh smoke check, and brings the 3 existing sections to bar.
     Completeness stays AGENT-judged (Step 6.7 registered-doc audit + the rewritten requirement);
     the hard check asserts STRUCTURE (the 4 anchored bullets are present), not completeness. -->

## Lifecycle

### Phase 1: Track

1. Read parent tracker to understand scope and acceptance criteria
   (no parent — standalone task scaffolded from an APPROVED /office-hours design doc)
2. Create working branch: `git checkout -b feat/{slug}`
   (ships in the existing `cj-feat-20260604-140658-97792` worktree branch / same PR)
3. Scaffold required docs:
   - `test-plan.md` (test scenarios for this task) — from `templates/doc-test-plan.md`
4. Populate Files section with expected changed files
5. Write initial Todos from the design's "Scope — concrete touches" (the 8 touches) + Success Criteria

**Gates:**
- [x] Parent scope read (N/A — standalone task; scope read from APPROVED design doc)
- [x] Working branch created (`branch` field populated: cj-feat-20260604-140658-97792)
- [x] Required docs scaffolded (test-plan)
- [x] Files section populated

### Phase 2: Implement

1. Work from `/office-hours` design doc + the 8-touch scope in ## Todos
   → design doc at `~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-cj-feat-20260604-140658-97792-design-20260604-141201.md`
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
   (NOTE: under /CJ_goal_feature this task STOPS at the PR; deploy is a separate human step)

❌ If tests fail: fix, re-run
❌ If CI fails: fix, push, re-run `/ship`

**Gates:**
- [ ] `/CJ_personal-workflow check` — validation passed
- [ ] Test-plan verified (all scenarios passing)
- [ ] `/ship` — PR created
- [ ] `/land-and-deploy` — merged and deployed

## Todos

<!-- The 8 concrete touches from the design's "Scope — concrete touches (review-expanded)".
     LOAD-BEARING: Check 15b parses the WHOLE section body (flag-based awk: arm at `### <name>`,
     disarm at next `^### `), so the structural sub-check MUST be line-anchored on the bullet
     shape (`^- \*\*Skills`, `^- \*\*Steps`, `^- \*\*Scripts`, `^- \*\*Docs`) — NOT bare substrings,
     which would false-match a chart node (`Step 5.5`) or an Invoke-when sentence. List
     `--phase sync` (F000045 Fork 2), NOT `post-land-sync.sh` (NOT an orchestrator step). -->

- [x] **§1 doc/WORKFLOWS.md — intro L3 rewrite.** Parenthetical's THREE dimensions removed; new **Granular-enumeration rule** paragraph states the 4 dimensions (Skills dispatched / Steps · phases / Scripts · tools · shell / Docs touched) + the granular-helper rule + the granularity ceiling (named helpers + steps, NOT raw git/gh, NOT `post-land-sync.sh`). Section-7 Check-15b intro line also updated to name the 4 anchored bullets.
- [x] **§1 doc/WORKFLOWS.md — the 3 sections → 4-bullet Touches shape.** All 3 `**Touches:**` rewritten to **Skills dispatched** / **Steps · phases** / **Scripts · tools · shell** / **Docs touched**. Per-section gaps filled:
  - **ALL THREE:** `cj-goal-common.sh --phase sync` (F000045 Fork 2) + Fork-1 base-freshness now in every chart + Steps/Scripts bullets (were absent).
  - **CJ_goal_feature:** Step 1.9 isolation gate (`--assert-isolated`) + Step 6.5 worktree-cleanup (`--phase cleanup`) added to chart + Steps bullet.
  - **CJ_goal_defect:** `--phase sync` + Fork-1 + Step 5.0 isolation gate added; `check-version-queue.sh` added to Scripts.
  - **CJ_goal_todo_fix:** `--phase sync` + Fork-1 added; `cj-goal-common.sh` added to Scripts (was entirely absent); `check-version-queue.sh` added.
- [x] **§1 doc/WORKFLOWS.md — charts gained the omitted nodes** (sync, Fork-1, isolation gate, cleanup) for parity in all 3 charts.
- [x] **§2 CLAUDE.md tracked-doc manifest — `doc/WORKFLOWS.md` `requirement:` VALUE rewritten in place** to mandate the 4-dimension granular enumeration. Single double-quoted YAML scalar (no bare `#`, no unquoted `:`); block shape intact. Verified Check 15a still parses exactly 3 doc/ path entries (PHILOSOPHY/ARCHITECTURE/WORKFLOWS).
- [x] **§3 templates/doc-WORKFLOWS-section.md — Touches block rewritten** to the 4-bullet shape; the "Keep it to the three bullets above" comment rewritten to "ALL FOUR bullets are REQUIRED … enumerate to the named-helper + named-step level" (zero matches for the old "three bullets" instruction).
- [x] **§4 scripts/validate.sh Check 15b — anchored sub-check ADDED.** Keeps the chart/tag check; adds 4 anchored sub-checks (`^- \*\*Skills`/`^- \*\*Steps`/`^- \*\*Scripts`/`^- \*\*Docs`) per `CJ_goal_*` section, ERROR-per-missing-bullet with a precise per-dimension message. Section-parse awk otherwise untouched.
- [x] **§5 scripts/test.sh — standalone hermetic smoke check ADDED** (mirrors the F000045/S000081 + T000038/T000039 blocks): asserts each of the 3 real sections carries all 4 anchored Touches bullets. zzz-test-scaffold fixture UNTOUCHED + re-verified unaffected (the "manual skill creation cycle" integration still reports "validate.sh passes with manually created skill"; Check 15b's `startswith("CJ_goal_")` loop never iterates the non-orchestrator fixture).
- [x] **§6 CJ-DOC-RELEASE.md — one-line reference added** (a row in the Declaration-site index table: the WORKFLOWS granular-enumeration rule → Step 6.7 audit (completeness) + Check 15b (structural)).
- [x] **§7 CLAUDE.md "Creating a new skill" step 6 — names the 4 dimensions** (and the skill-directory convention paragraph at L189-193 too).
- [ ] **§8 CHANGELOG.md / VERSION — at `/ship`** (version reconciled per the version queue).
- [ ] **Dogfood (best-effort, at /ship/Step 4.6).** `doc/WORKFLOWS.md` is itself a registered doc → after the rewrite Step 6.7 must judge it `up-to-date` against the NEW requirement; THIS PR's own body should carry a real `### Registered-doc requirements` section, all current. NON-BLOCKING; the deterministic proof is the §4 Check 15b sub-check + the §5 smoke check.
- [x] **Negative spot-check (manual, not committed).** Dropped the `**Steps · phases:**` bullet from CJ_goal_feature → validate.sh exited 1 with exactly `ERROR: doc/WORKFLOWS.md section 'CJ_goal_feature' Touches block missing the 'Steps · phases' bullet (expected a line matching '^- **Steps')` (Errors: 1 — no whole-body false-positive) → restored → validate.sh PASS (0 errors) again.

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-06-04: Created. Tightens doc/WORKFLOWS.md's requirement so each CJ_goal_* section must enumerate ALL skills/steps/tools/shell at the granular helper+step level (worktree init/delete, `cj-goal-common.sh --phase sync`, isolation gate, worktree-cleanup, check-version-queue, the verdict-surfacing producer steps). Enforces the STRUCTURE via a validate.sh Check 15b sub-check (4 anchored Touches sub-bullets: `^- \*\*Skills`/`^- \*\*Steps`/`^- \*\*Scripts`/`^- \*\*Docs`) + a standalone test.sh smoke check; completeness stays agent-judged (Step 6.7 + the rewritten requirement). 8 touches: doc/WORKFLOWS.md (intro + 3 sections + charts), CLAUDE.md tracked-doc requirement value, templates/doc-WORKFLOWS-section.md (4-bullet shape + contradicting comment fix), validate.sh Check 15b sub-check, test.sh smoke check, CJ-DOC-RELEASE.md one-liner, CLAUDE.md "Creating a new skill" step 6, CHANGELOG/VERSION at /ship. Scaffolded from APPROVED /office-hours design doc via /CJ_scaffold-work-item under /CJ_goal_feature.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. Populated during Track phase, updated during Implement. -->

- `doc/WORKFLOWS.md` (MODIFIED — §1: intro rewritten — removed the 3-dimension parenthetical, added the **Granular-enumeration rule** paragraph [4 dimensions + granular-helper rule + granularity ceiling] + updated the Check-15b intro line; all 3 `CJ_goal_*` charts gained the sync/Fork-1/isolation-gate/cleanup nodes; all 3 `**Touches:**` rewritten to the 4-bullet shape with per-section gaps filled)
- `CLAUDE.md` (MODIFIED — §2: the `doc/WORKFLOWS.md` `requirement:` VALUE inside `### Tracked doc/ files manifest` rewritten in place to mandate the 4-dimension granular enumeration [single double-quoted YAML scalar; block shape intact, Check 15a parses 3 paths]; §7: "Creating a new skill" step 6 names the 4 dimensions; the skill-directory convention paragraph [L189-193] also names the 4-bullet Touches block)
- `templates/doc-WORKFLOWS-section.md` (MODIFIED — §3: Touches block rewritten from 3 bullets to the 4-bullet shape; the "Keep it to the three bullets above" authoring comment rewritten to require all four bullets at the named-helper + named-step level)
- `scripts/validate.sh` (MODIFIED — §4: Check 15b keeps the chart/tag check + ADDS the 4 anchored sub-checks `^- \*\*Skills`/`^- \*\*Steps`/`^- \*\*Scripts`/`^- \*\*Docs` per `CJ_goal_*` section, ERROR-per-missing-bullet with a precise per-dimension message; the section-parse awk is otherwise untouched)
- `scripts/test.sh` (MODIFIED — §5: a standalone hermetic smoke check [mirrors F000045/S000081 + T000038/T000039] asserting each of the 3 real sections carries all 4 anchored Touches bullets; zzz-test-scaffold fixture UNTOUCHED + re-verified unaffected)
- `CJ-DOC-RELEASE.md` (MODIFIED — §6: one-line reference [Declaration-site index table row] to the WORKFLOWS granular-enumeration rule)
- `CHANGELOG.md` (TO MODIFY — §8: new entry at /ship; version reconciled per the version queue)

## Insights

<!-- Design context distilled from the APPROVED /office-hours design doc
     (hardened through an adversarial spec review, 7/10 → fixes folded in). -->

- **The gap: the requirement doesn't mandate exhaustiveness.** doc/WORKFLOWS.md's 3 `CJ_goal_*` sections each carry a `**Workflow:**` ASCII chart + a `**Touches:**` block, but the governing `requirement:` (in the CLAUDE.md tracked-doc manifest) only says "an ASCII chart + a Touches block reflecting the current chain." A thin section that names the top-level skills but omits the granular helpers (worktree init via `cj-worktree-init.sh`, teardown via `cj-worktree-cleanup.sh`, the pre-build skills-sync `--phase sync`, the verdict-surfacing producer steps) still passes. The operator wants the rule to DEMAND that level of detail — "show all skills/steps/tools/shell used, like worktree init / delete worktree."
- **Worth doing: full blast radius at a glance.** A reader (or a new repo's author) gets every skill, every named pipeline step, every script/shell helper, every doc touched. The granular helpers are exactly the load-bearing, easy-to-forget pieces (worktree lifecycle, skills-sync, version-queue) — the review confirmed the pre-build `--phase sync` is currently ABSENT from ALL THREE sections.
- **Premise: Advisory + a structural hard check (operator-selected, D1).** "Did they list EVERYTHING" is NOT deterministically greppable — completeness is agent-judged (Step 6.7 registered-doc audit + the rewritten requirement string). The hard check asserts STRUCTURE (the required Touches sub-bullets are present), not completeness.
- **The 4-dimension canonical shape, NOT 3.** The Touches block gets: **Skills dispatched** / **Steps · phases** / **Scripts · tools · shell** / **Docs touched**. The **Steps · phases** bullet is the deterministically-checkable place that guarantees the named steps (worktree init … teardown) are listed — the chart is only asserted to EXIST, never to be complete, so a Steps bullet is NOT redundant (it is the enforceable completeness anchor). 4 bullets, not 3. The existing template's "Keep it to the three bullets above" comment directly contradicts this and must be fixed.
- **LOAD-BEARING — Check 15b parses the WHOLE section body, so the sub-check must be line-anchored.** Check 15b's awk arms at `### <name>` and disarms at the next `^### `; it reads the entire section, not just the Touches block. So the structural grep MUST be anchored on the bullet shape (`^- \*\*Skills`, `^- \*\*Steps`, `^- \*\*Scripts`, `^- \*\*Docs`) — NOT bare substrings, which would false-match a chart node (`Step 5.5`) or an Invoke-when sentence and pass a section that has NO Touches bullet (defeating the whole check). Review-verified: the anchored patterns match each planned bullet exactly once, never a chart line or sibling bullet, and tolerate the `· phases` / `· tools · shell` label punctuation.
- **Wrap-safety of the requirement edit CONFIRMED.** The `doc/WORKFLOWS.md` `requirement:` lives inside CLAUDE.md `### Tracked doc/ files manifest` (a CARVE-OUT block). Check 15a (`flag && /^- path:/ {print $3}`) reads ONLY `path:` lines — the requirement value's length is irrelevant to it; the Step 6.7 awk joins wrapped `requirement:` continuation lines. Keep the rewritten value a SINGLE double-quoted YAML scalar; no bare `#`, no unquoted `:` that could confuse the wrap-join.
- **zzz-fixture no-op CONFIRMED — no fixture edit, standalone smoke check instead.** `scripts/test.sh`'s scaffold fixture skill is non-`CJ_goal_*`; Check 15b's loop is `select(.name | startswith("CJ_goal_"))`, so the new sub-check never iterates the fixture. The correct test is a STANDALONE hermetic smoke check (mirrors the existing F000045/S000081 block) against the 3 real sections — NOT a zzz-fixture edit. This sidesteps the `project_implement_subagent_blind_spot_test_sh` trap because the task adds a Check 15b SUB-check (not a new top-level check), but the implementer must still explicitly re-verify the fixture is unaffected.
- **Granularity ceiling — named helpers + steps, NOT raw git/gh, NOT `post-land-sync.sh`.** List NAMED workbench helpers + pipeline steps (worktree init/delete, `cj-goal-common.sh` phases incl. `--phase sync`, version-queue, the Step 4.6/5.6/9.5 producers) — NOT every raw `git`/`gh` call. Critically NOT `post-land-sync.sh`: it is NOT an orchestrator step — it is the internal core `--phase sync` reuses + a manual operator step; listing it as a touch would be factually WRONG.
- **Dogfood in the same PR.** `doc/WORKFLOWS.md` is itself a registered doc → after the rewrite its sections must satisfy the new requirement (Step 6.7 judges it `up-to-date`; THIS PR's body carries the `### Registered-doc requirements` section).
- **Deliberately NOT touched:** the Check 15b section-parse awk (only an anchored sub-check appended), the registered-doc audit selector, the zzz-test-scaffold fixture, `post-land-sync.sh`, raw git/gh enumeration. No drift in ARCHITECTURE.md / PHILOSOPHY.md (grepped — zero Touches-shape references).
- **Scaffolded as a task, mirroring T000037/T000038/T000039.** The change is a single, coherent, directly-implementable refinement (doc rewrite + a structural sub-check + a smoke check + 2 contradicting-text fixes) with a test plan. Under `/CJ_goal_feature`'s silent subagent context a user-story would error at scaffold.md Step 8 (user-stories must nest under a parent feature); a standalone task (TRACKER + test-plan) is the established on-disk convention (work-items/tasks/ops/). Component `ops` matches the F000030/F000034/F000037/T000037/T000038/T000039 doc-infra lineage.

## Journal

<!-- Structured entries (decision/finding/blocker) with Summary fields. -->

- [decision] 2026-06-04 — Scaffolded as a **task** (not a user-story or parent feature). Rationale: the design is a single, coherent, directly-implementable refinement (doc/WORKFLOWS.md requirement tightening + a Check 15b structural sub-check + a standalone test.sh smoke check + 2 contradicting-text fixes + bringing the 3 sections to bar) with a test plan; under /CJ_goal_feature's silent subagent context a user-story would error at scaffold.md Step 8 (user-stories must nest under a parent feature, which the directly-implementable mandate forbids), while a standalone task (TRACKER + test-plan) is an established on-disk convention. Mirrors T000037 (Job 1) / T000038 (Job 2) / T000039 (Job-2.1), all scaffolded as tasks for the identical reason. Component `ops` matches the doc-infra lineage (F000030/F000034/F000037/T000037/T000038/T000039).
- [decision] 2026-06-04 — Enforcement = **Advisory + a structural hard check** (D1, operator-selected). Completeness ("did they list EVERYTHING") is NOT deterministically greppable, so it stays agent-judged by Step 6.7 + the rewritten requirement string. The hard validate.sh Check 15b sub-check asserts only STRUCTURE — the 4 anchored Touches bullets are PRESENT — never completeness. This is the same Advisory/structural split the workbench already uses (Check 14 hard-checks USAGE.md freshness; Step 6.7 soft-judges content).
- [decision] 2026-06-04 — The Touches block gets **4 dimensions, not 3**: Skills dispatched / Steps · phases / Scripts · tools · shell / Docs touched. The **Steps · phases** bullet is the enforceable completeness anchor (it is where the named steps — worktree init … teardown — are listed). The chart is asserted only to EXIST, never to be complete, so the Steps bullet is NOT redundant with the chart. The existing templates/doc-WORKFLOWS-section.md "Keep it to the three bullets above" comment contradicts this and is rewritten as part of §3.
- [decision] 2026-06-04 — LOAD-BEARING: the Check 15b sub-check patterns are LINE-ANCHORED on the bullet shape (`^- \*\*Skills`, `^- \*\*Steps`, `^- \*\*Scripts`, `^- \*\*Docs`), NOT bare substrings. Check 15b's awk reads the WHOLE section body (arm at `### <name>`, disarm at next `^### `), so a bare substring like `Steps` would false-match a chart node (`Step 5.5`) or an Invoke-when sentence and pass a section that has NO Touches bullet — defeating the check. Review-verified the anchored patterns match each planned bullet exactly once, never a chart line, tolerating `· phases` / `· tools · shell` punctuation.
- [decision] 2026-06-04 — Granularity ceiling: list NAMED workbench helpers + pipeline steps (worktree init via cj-worktree-init.sh, teardown via cj-worktree-cleanup.sh / `--phase cleanup`, `cj-goal-common.sh` phases incl. `--phase sync`, `check-version-queue.sh`, the Step 4.6/5.6/9.5 verdict-surfacing producers) — NOT every raw git/gh call, and explicitly NOT `post-land-sync.sh` (it is NOT an orchestrator step — it is the internal core `--phase sync` reuses + a manual operator step; listing it would be factually wrong). The review confirmed the pre-build `--phase sync` (F000045 Fork 2) + Fork-1 base-freshness are ABSENT from ALL THREE sections today — the primary gap to fill.
- [decision] 2026-06-04 — Test = STANDALONE hermetic smoke check, NOT a zzz-test-scaffold fixture edit. Check 15b's loop is `select(.name | startswith("CJ_goal_"))` and the fixture skill is non-`CJ_goal_*`, so the new sub-check never iterates the fixture; the correct test mirrors the existing F000045/S000081 standalone block, asserting the 3 real sections carry all 4 anchored bullets. `project_implement_subagent_blind_spot_test_sh` is partially N/A (this is a Check 15b SUB-check, not a new top-level check needing a parallel fixture edit) — but the implementer must still explicitly re-verify the zzz-fixture passes validate unchanged.
- [finding] 2026-06-04 — Wrap-safety of the CLAUDE.md `requirement:` edit CONFIRMED by the review: Check 15a (`flag && /^- path:/ {print $3}`) reads ONLY `path:` lines, so the requirement value's length is irrelevant; the Step 6.7 awk joins wrapped `requirement:` continuation lines. Keep the rewritten value a SINGLE double-quoted YAML scalar (no bare `#`, no unquoted `:`) and do not disturb the `- path:`/`audit_class:`/`owner:`/`requirement:` block shape.
- [impl-finding] 2026-06-04 — `--auto` demoted to propose-equivalent semantics (the safety override): the change touches sensitive surfaces (`scripts/validate.sh`, `scripts/test.sh`) AND >2 files (6 modified), so the trivial-change fast path does not apply. Run under the silent `/CJ_goal_feature` subagent contract (mechanical defaults: sensitive-surface writes approved, plan applied) rather than blocking on an AUQ.
- [impl-finding] 2026-06-04 — Anchored-grep guardrail honored: the Check 15b sub-check + the test.sh smoke check key on the BULLET-LINE shape (`^- \*\*Skills`/`^- \*\*Steps`/`^- \*\*Scripts`/`^- \*\*Docs`), NOT bare words. `SECTION` in Check 15b is the WHOLE section body (chart + prose + Touches), so a bare `Steps` would have false-matched the chart node `Step 1.9` / `Step 5.5` and passed a Touches-less section. Verified each anchored pattern matches its bullet exactly once and never a chart line (the negative spot-check produced exactly one ERROR, not zero, with the precise per-dimension message).
- [impl-finding] 2026-06-04 — `post-land-sync.sh` deliberately NOT listed as a touch in any `CJ_goal_*` Touches block (granularity ceiling): it is the internal core `--phase sync` reuses + a manual operator step, not an orchestrator step — `grep -n 'post-land-sync' doc/WORKFLOWS.md` returns zero hits in the section bodies. Listed `cj-goal-common.sh --phase sync` instead in all three.
- [impl] 2026-06-04 — Implemented the 7 in-PR touches (§8 CHANGELOG/VERSION lands at /ship). Modified 6 files: doc/WORKFLOWS.md (intro rule + 3 charts + 3 Touches blocks → 4-bullet shape, gaps filled), CLAUDE.md (tracked-doc `requirement:` value + step-6 + skill-dir convention), templates/doc-WORKFLOWS-section.md (4-bullet shape + contradicting-comment fix), scripts/validate.sh (Check 15b 4 anchored sub-checks), scripts/test.sh (standalone smoke check), CJ-DOC-RELEASE.md (declaration-site index row). `./scripts/validate.sh` → exit 0, 0 errors (Check 15b sub-check green for all 3 sections; Check 15a parses 3 doc/ paths). `./scripts/test.sh` → exit 0, 0 failures (new T000040 smoke green for all 3 sections; zzz-test-scaffold fixture unaffected — "validate.sh passes with manually created skill"). Negative spot-check confirmed (precise per-bullet ERROR on a dropped Steps bullet, restored to green).
- [impl-auto] 2026-06-04 — Auto-mode invocation under the silent `/CJ_goal_feature` runner; the safety override demoted `--auto` (sensitive surfaces + 6 files) but the runner contract supplies mechanical defaults, so no interactive gate was raised.
- [impl-pass] 2026-06-04 — T000040: implementation complete. Phase 2 implementer-owned gates transitioned (Todos section reflects remaining work; Files section updated with changed files). `Core changes committed` left unchecked (user/`/ship`-owned commit gate).
- [qa-boundary] 2026-06-04 — /CJ_qa-work-item (silent /CJ_goal_feature runner): boundary check at start found the task-type Phase 2 commit gate `Core changes committed (>=1 commit SHA in Log)` UNCHECKED (no SHA in Log; working tree uncommitted — 6 tracked `M` files + the untracked T000040 dir). Per qa.md Step 2 the QA contract REFUSES to transition gates / write `[qa-pass]` on an uncommitted tree; this is the EXPECTED /CJ_goal_feature pre-commit state (commit happens after QA-green, at /ship). No commit performed; no gate transitioned. Test rows nonetheless verified green against the working tree as-is (see [qa-smoke-equiv] below) so the halt carries evidence.
- [qa-smoke-equiv] 2026-06-04 — All deterministic test-plan rows GREEN against the working tree (smoke-equivalent; task type → no E2E). T1 `./scripts/validate.sh` → exit 0, 0 errors, RESULT: PASS (Check 15b's anchored sub-check PASS for all 3 CJ_goal_* sections; Check 15a parses exactly 3 doc/ manifest paths PHILOSOPHY/ARCHITECTURE/WORKFLOWS). T2 `./scripts/test.sh` → exit 0, 0 failures, RESULT: PASS (new standalone T000040 smoke emits OK per section for feature/defect/todo; zzz-test-scaffold fixture UNTOUCHED — +41/-0 diff, "validate.sh passes with manually created skill" still green). T3 NEGATIVE (transient edit + restore, NOT committed): dropping the `**Steps · phases**` bullet from CJ_goal_feature → validate exit 1, EXACTLY ONE precise ERROR (`section 'CJ_goal_feature' Touches block missing the 'Steps · phases' bullet (expected a line matching '^- **Steps')`), no whole-body false-positive; restored byte-identical (sha 90376b3…), validate green again. T4 all 3 sections name `cj-goal-common.sh --phase sync` (F000045 Fork 2) + Fork-1 base-freshness in chart + Steps/Scripts bullets. T5 per-section gaps filled (feature: `--assert-isolated` + `--phase cleanup`; defect: isolation + `check-version-queue.sh`; todo: `cj-goal-common.sh` [was absent] + `check-version-queue.sh`). T6 granularity ceiling honored — `post-land-sync.sh` appears 0× in any section body (only in the L5 negative-rule prose). T7 CLAUDE.md `doc/WORKFLOWS.md` `requirement:` rewritten in place (single double-quoted scalar; block shape intact). T8 template → 4-bullet shape, zero "three bullets". T9 CJ-DOC-RELEASE.md row + CLAUDE.md step-6/skill-dir name the 4 dimensions. Diff is workbench-owned only (no upstream gstack /ship or /document-release); ARCHITECTURE.md/PHILOSOPHY.md unmodified, zero Touches-shape drift. Verdict: green pending commit — re-run /CJ_qa-work-item (or let /ship commit) to transition the gate + record [qa-pass].
