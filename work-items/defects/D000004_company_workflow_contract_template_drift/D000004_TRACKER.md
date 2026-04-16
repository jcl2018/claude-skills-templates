---
name: "company-workflow contract/template drift (workflow_type, section order)"
type: defect
id: "D000004"
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
2. Create working branch: `git checkout -b fix/company-workflow-contract-template-drift`
3. Scaffold required docs:
   - `D000004_RCA.md` (root cause analysis) — from `templates/doc-RCA.md`
   - `D000004_test-plan.md` (regression test plan) — from `templates/doc-test-plan.md`
4. Run `/investigate` to diagnose root cause
   → produces investigation findings in Log + Insights
5. Log initial symptoms and hypotheses

**Gates:**
- [x] Reproduction steps documented
- [ ] Working branch created (`branch` field populated)
- [x] Required docs scaffolded (RCA + test-plan)
- [x] Root cause identified (or best hypothesis logged)

### Phase 2: Implement

1. Work from `/office-hours` design doc (if applicable) + root cause analysis
2. Implement fix based on root cause analysis
3. Write regression test covering the defect scenario
4. Commit fix and test together
5. Update RCA doc with final root cause

**Gates:**
- [ ] Fix committed
- [ ] RCA doc updated
- [ ] Todos section reflects remaining work (no stale items)

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

Surfaced by deploying and using `/company-workflow` against the ai-content repo (master branch). Two related drift defects between the skill's contract and its own templates / scaffolding behavior. Both inherit from a single architectural question: how to enforce a CI round-trip invariant when the validators are LLM-driven SKILL.md (not executable scripts).

### Issue 1 — `workflow_type` frontmatter field (template-vs-contract drift)

1. Deploy company-workflow skill to ai-content repo
2. Scaffold any tracker (feature, user-story, task, defect) — templates emit `workflow_type` in YAML frontmatter
3. Read `skills/company-workflow/contract.json` — required frontmatter is `[name, type, status, created, updated]`; `workflow_type` is not required
4. Read `skills/company-workflow/SKILL.md` lines 126, 145 — the file-mode validator's company-specific check does check `workflow_type` and `url`
5. **Observe:** templates generate a field the contract docs say is unrequired, but the validator quietly enforces it

### Issue 3 — Section-order drift (Acceptance Criteria / Reproduction Steps)

1. Scaffold a feature or user-story tracker — template inserts `## Acceptance Criteria` between `## Lifecycle` and `## Todos`
2. Scaffold a defect tracker — template inserts `## Reproduction Steps` between `## Lifecycle` and `## Todos`
3. Run the company-workflow validator's section-order check — `expected_order` lists `Lifecycle, Todos, Log, PRs, Files, Meetings, Insights, Journal` (no `Acceptance Criteria`, no `Reproduction Steps`)
4. **Observe:** files freshly scaffolded from the skill's own templates fail the skill's own validator on section-order

**Environment:** macOS 25.3.0; deployed via `skills-deploy install` to `~/.claude/skills/company-workflow/`; consumed in the ai-content repo, master branch.

**Note on parentage:** This defect was spun out of D000003 on 2026-04-16. D000003 originally bundled three issues; Issue 2 (artifact duplication) was kept under D000003 because it's a pure manifest fix with no validator-runner dependency. Issues 1 and 3 are kept here because they share the same architectural question (the "how does CI catch template-vs-contract drift" question) and benefit from being fixed together.

## Todos

### Architectural rethink (BLOCKING — must resolve before fix work)

- [ ] Decide which round-trip / drift-detection mechanism to adopt. Five options surfaced in /office-hours:
  - **A. Subset-validator-in-bash** — runner re-implements contract.json structural checks (frontmatter required, sections required, section order, lifecycle phases) in pure bash + jq + grep. Catches Issues 1 + 3 fully. ~120 lines. Duplicates a subset of validator logic.
  - **B. Pre-rendered fixtures + git-diff** — commit one scaffolded fixture per (skill, type). Runner re-scaffolds and diffs against the committed fixture. Catches template drift but not contract.json drift directly.
  - **C. Drop the runner** — pre-commit lint that grep-checks templates against contract.json fields/sections. Smaller surface, less safety net.
  - **D. Self-test inside the SKILL itself** — `/personal-workflow check --self-test` invocation runs the validator on freshly-scaffolded templates as part of the skill. Lives in Claude Code, not bash CI. Loses CI gate.
  - **E. Shared bash library** — extract structural validation logic into `scripts/lib-validate.sh` that both the SKILL.md and a runner consume. Single source of truth, executable. Heaviest refactor.
- [ ] Re-run `/office-hours` with the LLM-validator constraint surfaced upfront. Treat the inherited design doc (`chjiang-claude-nostalgic-volhard-design-20260416-142220.md`, Status: NEEDS_REVISION) as the starting point.

### Issue 1 fix (after architectural choice)

- [ ] Issue 1 — Pre-step: grep ai-content's existing trackers for `workflow_type` to confirm it's universally present before promoting to required. If any tracker lacks it, demote to recommended.
- [ ] Issue 1 — Add `workflow_type` to `contract.json` (required or recommended per pre-step) and `url` to recommended (grandfather policy for legacy ai-content trackers).
- [ ] Issue 1 — Update `SKILL.md` line 126 to reference `contract.json` instead of inlining the field list. Line 145 is an example error string; leave alone.

### Issue 3 fix (after architectural choice)

- [ ] Issue 3 — Add `Acceptance Criteria` and `Reproduction Steps` to `contract.sections.optional`.
- [ ] Issue 3 — Insert both in `expected_order` between `Lifecycle` and `Todos`.
- [ ] Issue 3 — Add `order_skip_absent: true`.
- [ ] Issue 3 — Add `type_specific_optional` mirroring personal-workflow's pattern. tracker-task and tracker-review are unaffected (no optional sections — empty arrays).

### Per architectural choice

- [ ] If A or E selected: implement the round-trip runner per the chosen design.
- [ ] Add fixture skills (`skills/zzz-test-roundtrip-bad/`, `skills/zzz-test-roundtrip-malformed/`) for self-tests if a runner is built.
- [ ] Wire the chosen mechanism into `scripts/test.sh`.
- [ ] Verify R1 (personal-workflow CLEAN) and R2 (company-workflow CLEAN after Issue 1 + 3 fix) regressions per the chosen mechanism.

### Coda

- [ ] Update `CHANGELOG.md` and bump skill version per `scripts/collection-version.sh`.
- [ ] After ship: deploy to ai-content via `skills-deploy install --overwrite`; run `/company-workflow validate` against existing trackers to confirm no false positives.

## Log

- 2026-04-16: Created. Spun out of D000003 (`D000003_company_workflow_contract_template_drift`, now narrowed and renamed to `D000003_company_workflow_feature_artifact_duplication`). Carries Issues 1 (workflow_type) and 3 (section order) plus the architectural rethink for the round-trip runner.
- 2026-04-16: Inherited design doc `chjiang-claude-nostalgic-volhard-design-20260416-142220.md` (Status: NEEDS_REVISION) which already documents the architectural finding and the 5 design-space options A-E. The doc still applies to D000004; the feature-summary.md / artifact-split portion (Issue 2) has moved to D000003.
- 2026-04-16: Status remains BLOCKED on the architectural choice. No code work until A/B/C/D/E is decided.

## PRs

## Files

- `skills/company-workflow/contract.json` — frontmatter required-fields list, sections.optional, sections.expected_order, order_skip_absent, type_specific_optional
- `skills/company-workflow/SKILL.md` (line 126) — file-mode validator's company-specific frontmatter check; should reference contract.json
- `templates/company-workflow/tracker-feature.md` — emits `workflow_type` and `## Acceptance Criteria`
- `templates/company-workflow/tracker-user-story.md` — emits `workflow_type` and `## Acceptance Criteria`
- `templates/company-workflow/tracker-defect.md` — emits `workflow_type` and `## Reproduction Steps`
- `templates/company-workflow/tracker-task.md` — emits `workflow_type` only (no extra sections)
- `templates/company-workflow/tracker-review.md` — emits `workflow_type` only (no extra sections)
- `scripts/test.sh` — receives the round-trip / lint integration once architectural choice is made
- (per architectural choice) `scripts/test-roundtrip.sh` and/or `scripts/lib-validate.sh` and/or pre-rendered fixtures under each skill's `fixtures/`

## Insights

Both Issues 1 and 3 share a single underlying cause: the contract and the templates are maintained as two independent sources of truth, with no test that scaffolds a fresh tracker and runs the validator against it end-to-end.

The `workflow_type` case is also a soft signal that the contract's "required frontmatter" list is not the only place the validator reads frontmatter — the company-specific check has its own implicit requirement set. Consolidating these into one declarative source would prevent future drift.

**Inherited architectural finding (2026-04-16, post-design, pre-implementation):** the "round-trip runner" approach assumed a bash-executable validator. The validators are SKILL.md files run by Claude Code. Bash CI cannot directly exec them. Five design directions worth exploring before implementation:

- **A. Subset-validator-in-bash** — runner re-implements the contract.json structural checks (frontmatter required, sections required, section order) in pure bash + jq + grep. Catches Issues 1 + 3 fully, but duplicates a subset of validator logic in two places (SKILL.md + bash).
- **B. Pre-rendered fixtures + git-diff** — commit one scaffolded fixture per (skill, type). Runner re-scaffolds and diffs against the committed fixture. Catches template drift but not contract.json drift directly.
- **C. Drop the runner** — add a smaller pre-commit lint that grep-checks templates against contract.json fields/sections. Less safety net but no duplication.
- **D. Self-test inside the SKILL itself** — `/personal-workflow check --self-test` invocation runs the validator on freshly-scaffolded templates as part of the skill. Lives in Claude Code, not bash CI. Closest to the original "round-trip" framing but loses CI gate.
- **E. Shared bash library** — extract the structural validation logic into `scripts/lib-validate.sh` that both the SKILL.md and the round-trip runner consume. Single source of truth, executable. Heaviest refactor but architecturally cleanest.

The choice depends on whether CI gating is required (favors A or E) or whether interactive Claude Code coverage is sufficient (favors D).

**Cross-reference:** D000003 (`D000003_company_workflow_feature_artifact_duplication`) ships Issue 2 independently — it's a pure manifest + new template edit with no architectural dependency on this defect.

## Journal

