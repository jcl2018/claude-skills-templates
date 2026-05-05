---
name: "company-workflow phase 2 lacks test-verification gate; test-plan vs test-spec roles unclear"
type: defect
id: "D000006"
status: active
created: "2026-04-16"
updated: "2026-04-16"
repo: "jcl2018/claude-skills-templates"
branch: "claude/nostalgic-volhard"
blocked_by: ""
---

## Lifecycle

### Phase 1: Track

1. Document reproduction steps in the Log section
2. Create working branch: `git checkout -b fix/company-workflow-test-verification-gates`
3. Scaffold required docs:
   - `D000006_RCA.md` (root cause analysis) — from `templates/personal-workflow/doc-RCA.md`
   - `D000006_test-plan.md` (regression test plan) — from `templates/personal-workflow/doc-test-plan.md`
4. Run `/investigate` to diagnose root cause
   → produces investigation findings in Log + Insights
5. Log initial symptoms and hypotheses

**Gates:**
- [x] Reproduction steps documented
- [ ] Working branch created (`branch` field populated — currently on shared `claude/nostalgic-volhard`)
- [x] Required docs scaffolded (RCA + test-plan)
- [x] Root cause identified (template/contract gap; no validator enforcement)

### Phase 2: Implement

1. Work from `/office-hours` design doc (if applicable) + root cause analysis
2. Implement fix based on root cause analysis
3. Write regression test covering the defect scenario
4. Commit fix and test together
5. Update RCA doc with final root cause

**Gates:**
- [x] Fix committed (4 tracker templates + 4 test-doc templates + WORKFLOW.md edited; commit pending `/ship`)
- [x] RCA doc updated (Fix Description matches what shipped; commit SHA populated by `/ship`)
- [x] Todos section reflects remaining work (no stale items)

### Phase 3: Ship

1. Run `/personal-workflow check` — verify no regressions
2. Verify test-plan: regression test scenarios passing
3. Run `/ship` — creates fix PR (includes pre-landing code review)
4. Run `/land-and-deploy` — merges and verifies fix in production

❌ If regression test fails: investigate further
❌ If CI fails: fix, push, re-run `/ship`

**Gates:**
- [ ] `/personal-workflow check` — validation passed
- [ ] Test-plan verified (regression scenarios passing)
- [ ] `/ship` — PR created
- [ ] `/land-and-deploy` — merged and deployed

## Reproduction Steps

Surfaced by reviewing the company-workflow tracker templates after deploying `/company-workflow` and walking through Phase 2 → Phase 3 transitions on a real work item. Two sibling gaps in the same area: the **tracker → test-doc** contract is not enforced by the lifecycle gates, and the **test-plan vs test-spec** roles are not documented in the templates.

### Issue 1 — Phase 2 has no "tests verified per test-plan/test-spec" gate

1. Open `templates/company-workflow/tracker-defect.md` Phase 2 — gates list `Regression test added` (added, not verified)
2. Open `templates/company-workflow/tracker-task.md` Phase 2 — no test-related gate at all (tasks own a `test-plan.md` per the manifest, but the tracker never references it)
3. Open `templates/company-workflow/tracker-user-story.md` Phase 2 — gate says `Acceptance criteria met` but never references the sibling `TEST-SPEC.md`; nothing requires that the Test Matrix rows actually have a `Pass` status before Ship
4. Open `templates/company-workflow/tracker-feature.md` Phase 2 — same pattern; no roll-up test verification gate
5. **Observe:** a tracker can advance from Phase 2 → Phase 3 (Review) → Phase 4 (Ship) without any explicit confirmation that the test cases declared in the linked `test-plan.md` / `TEST-SPEC.md` were actually executed and marked Pass. Phase 4 has a generic "Regression tests pass" gate, but that refers to CI suite runs, not the per-item test docs

### Issue 2 — test-plan vs test-spec roles are not documented

1. Open `templates/company-workflow/doc-test-plan.md` — header is `{Defect Name} — Regression Test Plan`; intended for task + defect (per manifest), but template body uses defect-only language and gives no guidance on the appropriate level of detail
2. Open `templates/company-workflow/doc-TEST-SPEC.md` — Test Matrix + Tier 1/Tier 2 structure implies broader scope, but no top-of-file commentary states the contract
3. **Observe:** new authors generating a task `test-plan.md` from the same template that drives a defect `test-plan.md` have no signal about scope. test-plan should stay **concrete** (specific cases for one fix/one task); TEST-SPEC should stay **broader** (full coverage for a user story, mapped to PRD ACs, across happy/edge/error paths)

**Environment:** macOS 25.3.0; company-workflow as deployed from `templates/company-workflow/` in this repo.

**Discovered via:** review of company-workflow templates after the D000004 architectural rethink surfaced the broader question of "what does the contract actually enforce." The two issues here are pure template/contract content; no SKILL.md validator changes are required for the template-content portion (gate text changes), though the section-required validator may need an update if Issue 1 is wired to a `## Test Verification` section instead of inline gate text.

## Todos

### Issue 1 — Phase 2 test-verification gate

- [x] `templates/company-workflow/tracker-defect.md` — Phase 2: replaced `Regression test added` with `Regression test added AND all cases in test-plan.md marked Pass` (line 26)
- [x] `templates/company-workflow/tracker-task.md` — Phase 2: added gate `All test cases in test-plan.md marked Pass` (line 25)
- [x] `templates/company-workflow/tracker-user-story.md` — Phase 2: added gate `All P0 cases in TEST-SPEC.md marked Pass; remaining cases marked Pending/Skip with reason` (line 25)
- [x] `templates/company-workflow/tracker-feature.md` — Phase 2: added roll-up gate `Each child user-story's TEST-SPEC has all P0 cases Pass` (line 26)
- [ ] Decide whether to also add a parallel update to `templates/personal-workflow/tracker-*.md` (out of scope for this defect — file follow-up if confirmed)
- [ ] If validator enforcement is added (vs. template-only): update `skills/company-workflow/contract.json` to require the new gate text or a `## Test Verification` section (deferred — pending D000004 architectural decision)

### Issue 2 — test-plan vs test-spec scope contract

- [x] `templates/company-workflow/doc-test-plan.md` — added top-of-file comment "Scope: ONE fix (defect) or ONE task..." (line 10-12)
- [x] `templates/company-workflow/doc-test-plan.md` — generalized title from `{Defect Name} — Regression Test Plan` to `{ITEM_NAME} — Test Plan`; also generalized `parent: {DEFECT_ID}` to `parent: {ITEM_ID}`. Both placeholders match the canonical `{ITEM_NAME}` / `{ITEM_ID}` form in `skills/company-workflow/WORKFLOW.md` and are detectable by the directory-mode validator's `\{[A-Za-z_]+\}` placeholder regex (post-adversarial-review correction — initial draft used `{Item Name}` which the regex misses)
- [x] `templates/company-workflow/doc-TEST-SPEC.md` — added top-of-file comment "Scope: ENTIRE user story..." (line 15-16)
- [x] `skills/company-workflow/WORKFLOW.md` — added `### test-plan vs TEST-SPEC` subsection under Scaffolding Conventions (line 91)
- [x] Mirrored scope comments in `templates/personal-workflow/doc-test-plan.md` and `templates/personal-workflow/doc-TEST-SPEC.md`. Title generalization ALSO mirrored to `templates/personal-workflow/doc-test-plan.md` (parent: `{DEFECT_ID}` → `{ITEM_ID}`, title: `{Defect Name} — Regression Test Plan` → `{ITEM_NAME} — Test Plan`) per adversarial review finding that the personal-workflow scaffolding has the same defect-flavored-title-for-tasks problem

### Validation + ship

- [x] Verified structural compliance manually (required sections + lifecycle phases + zero unresolved `{PLACEHOLDER}` patterns in D000006 docs)
- [x] Verified regression test (per `D000006_test-plan.md`) — all 12 grep cases Pass; both `validate.sh` and `test.sh` clean
- [ ] Update `CHANGELOG.md` and bump skill version per `scripts/collection-version.sh` (pending `/ship`)
- [ ] Ship via `/ship`

## Log

- 2026-04-16: Created. Filed by user during walk-through of `/company-workflow` Phase 2 → Phase 3 transition. Two related issues bundled because both touch the test-doc contract: (1) tracker Phase 2 doesn't gate on test-doc verification, (2) test-plan vs TEST-SPEC scope contract is undocumented. No code work yet — pending choice between template-only fix vs. validator enforcement.
- 2026-04-16: Chose option (a) template-only fix on the existing `claude/nostalgic-volhard` branch (matching D000005's pattern; no new branch). Edited 4 company-workflow trackers (Phase 2 gates), 2 company-workflow test-doc templates (scope comments + title generalization on doc-test-plan), 2 personal-workflow test-doc templates (mirrored scope comments), and `skills/company-workflow/WORKFLOW.md` (new `### test-plan vs TEST-SPEC` subsection). Also generalized `parent: {DEFECT_ID}` to `parent: {ITEM_ID}` in company doc-test-plan to align with the canonical `{ITEM_ID}` placeholder in WORKFLOW.md. Verified: `./scripts/validate.sh` PASS (0/0), `./scripts/test.sh` PASS (0 failures), all 12 regression grep cases in D000006_test-plan.md Pass. No `contract.json` or SKILL.md validator changes — defer per RCA's minimum-landing scope.
- 2026-04-16: During `/ship`, merged `origin/main` (clean — squash commit content already in branch). Added 10 new D000006 regression tests to `scripts/test.sh` (mirrors D000005 pattern). Spawned Claude adversarial subagent which found 3 fixable issues, all auto-applied: (1) `{Item Name}` → `{ITEM_NAME}` (canonical placeholder; validator regex `\{[A-Za-z_]+\}` doesn't match spaces — would have left the placeholder undetectable), (2) mirrored title generalization to personal-workflow doc-test-plan.md (same defect class), (3) tightened test.sh greps with `^- \[ \]` checkbox prefix anchors so a future reword can't silently break the gate detection. One INVESTIGATE finding deferred to follow-up: validator-enforcement of "test-plan.md status: Pass" — already noted in RCA as deferred pending D000004 architectural choice.

## PRs

## Files

- `templates/company-workflow/tracker-defect.md` — Phase 2 gate strengthening
- `templates/company-workflow/tracker-task.md` — Phase 2 add test-verification gate
- `templates/company-workflow/tracker-user-story.md` — Phase 2 add TEST-SPEC verification gate
- `templates/company-workflow/tracker-feature.md` — Phase 2 add roll-up gate
- `templates/company-workflow/doc-test-plan.md` — top-of-file scope comment + generalize title for task use
- `templates/company-workflow/doc-TEST-SPEC.md` — top-of-file scope comment
- `skills/company-workflow/WORKFLOW.md` — Scaffolding Conventions section addition
- `skills/company-workflow/contract.json` — only if validator enforcement chosen
- `templates/personal-workflow/doc-test-plan.md` — mirror scope comment
- `templates/personal-workflow/doc-TEST-SPEC.md` — mirror scope comment
- `CHANGELOG.md` — Fixed entry
- `VERSION` — patch bump

## Insights

Both issues stem from the same architectural gap: the company-workflow lifecycle treats the **test docs** (`test-plan.md`, `TEST-SPEC.md`) as scaffolded artifacts but never closes the loop by gating Phase transitions on their content. A tracker can ship with a half-empty test-plan that nobody ever ran.

The **scope contract** (concrete vs. broader) is implicit in the templates but never stated. Without it, authors copy-paste structure across types and end up with task `test-plan.md` files that look like full TEST-SPEC matrices, or user-story `TEST-SPEC.md` files that read like one-fix regression checklists.

The minimum-cost fix is template-only: edit the gate text in 4 trackers, add 2 top-of-file scope comments, add a paragraph to WORKFLOW.md. No validator changes; no contract.json changes. The trade-off is that the gates are advisory (a careless author can still tick them without doing the work) — but that matches the rest of the lifecycle gates today, which are all author-asserted.

A heavier fix would add a `## Test Verification` section to each tracker template and require it via `contract.json sections.required`, mirroring how Phase gates already work. Defer that decision until the broader D000004 architectural choice (round-trip validator vs. template-only) is settled, so this defect can either ride its mechanism or land standalone if D000004 stalls.

**Cross-reference:**
- D000003 (`D000003_company_workflow_feature_artifact_duplication`) — independent manifest fix, no overlap
- D000004 (`D000004_company_workflow_contract_template_drift`) — same skill, related architectural question (validator enforcement vs. template-only); if D000004 lands a shared validator, this defect's Issue 1 can plug into it

## Journal
