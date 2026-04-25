---
name: "Eliminate contract.json — templates as single source of truth (supersedes D000004)"
type: defect
id: "D000007"
status: closed
created: "2026-04-17"
updated: "2026-04-25"
repo: "jcl2018/claude-skills-templates"
branch: "claude/nostalgic-volhard"
blocked_by: ""
---

## Lifecycle

### Phase 1: Track

1. Document reproduction steps in the Log section
2. Create working branch: `git checkout -b fix/eliminate-contract-json`
3. Scaffold required docs:
   - `D000007_RCA.md` (root cause analysis) — from `templates/personal-workflow/doc-RCA.md`
   - `D000007_test-plan.md` (regression test plan) — from `templates/personal-workflow/doc-test-plan.md`
4. Run `/investigate` to diagnose root cause
   → produces investigation findings in Log + Insights
5. Log initial symptoms and hypotheses

**Gates:**
- [x] Reproduction steps documented (drift class summarized; D000004 + D000006 partial + 4 audit findings cited)
- [ ] Working branch created (`branch` field populated — currently on shared `claude/nostalgic-volhard`)
- [x] Required docs scaffolded (RCA + test-plan)
- [x] Root cause identified (two-source-of-truth pattern: contract.json + templates)

### Phase 2: Implement

1. Work from `/office-hours` design doc (if applicable) + root cause analysis
2. Implement fix based on root cause analysis
3. Write regression test covering the defect scenario
4. Commit fix and test together
5. Update RCA doc with final root cause

**Gates:**
- [x] Fix committed (12 files modified, 2 contract.json deleted, 1 D000004 superseded; commit pending `/ship`)
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
- [x] `/personal-workflow check` — validation passed
- [x] Test-plan verified (regression scenarios passing) — `find . -name contract.json` returns nothing across the repo
- [x] `/ship` — PR created
- [x] `/land-and-deploy` — merged and deployed (contract.json removed from skills tree; F000003 DESIGN.md decision #2 codifies "templates are the single source of truth")

## Reproduction Steps

The defect is the **drift between `contract.json` and the templates** in both workflow skills (`company-workflow` and `personal-workflow`). This drift class has produced multiple defects already and will keep producing them as long as the architecture has two parallel sources of truth.

### How the drift manifests

1. Edit a template (e.g., `templates/company-workflow/tracker-defect.md`) to add a Phase 2 gate
2. Forget to update `skills/company-workflow/contract.json` to declare the new gate as required
3. Validator (`SKILL.md validate` / `personal-workflow check`) walks the template's section list against `contract.json`'s `expected_order`, but `contract.json` was never updated, so the new section either:
   - Silently passes (validator can't see it)
   - Falsely fails (validator says "section X appears in unexpected position" because `contract.json`'s declared order doesn't include it)
4. Symmetric problem in reverse: edit `contract.json` to declare a new required section, but forget to update the template — every freshly scaffolded tracker fails validation against its own skill's contract

### Drift instances on file

- **D000004 (BLOCKED):** `workflow_type` and `url` are checked by `SKILL.md` line 126/145 but not declared required in `contract.json`. `Acceptance Criteria` and `Reproduction Steps` are emitted by templates but missing from `contract.sections.expected_order`.
- **D000006 partial (deferred):** Phase 2 test-verification gates added to all 4 company-workflow trackers, but `contract.json` was not updated to require the new gate text or section. Author-asserted only.
- **Audit 2026-04-17 (4 new findings):**
  1. `company-workflow/contract.json` has no `type_specific_optional` field at all (personal-workflow has it). Validator can't distinguish "Reproduction Steps is OK for defects only" from "Insights is OK everywhere."
  2. `templates/company-workflow/doc-milestones.md:4-5` uses both `parent: {USER_STORY_ID}` and `feature: {FEATURE_ID}` — structural outlier vs every other doc template.
  3. `templates/company-workflow/doc-review-notes.md:8` uses `verdict: Pending` instead of canonical `status: Draft`.
  4. `templates/company-workflow/tracker-review.md:8-13` uses non-canonical placeholders (`{TITLE}`, `{DATE}`, `{ID}`) and lacks `blocked_by` — placeholder family mismatch.

**Environment:** macOS Darwin 25.3.0; both skills as deployed in this repo on branch `claude/nostalgic-volhard`.

## Todos

### Phase 1 — Architecture decision (DONE — chose Option A)

- [x] Surveyed 5 architectural options in D000004's RCA (A subset-validator-in-bash, B pre-rendered fixtures, C drop-the-runner, D self-test-in-skill, E shared-bash-library)
- [x] D000007 introduces a 6th option (F: eliminate contract.json — templates ARE the contract). Chose F.
- [x] Acknowledged tradeoff: lose ability to declare "recommended but not required" frontmatter and per-type optional sections. Accepted because (a) "recommended" is advisory-only today and not enforced, and (b) per-type optional sections become structural (the per-type template either includes the section or not — automatic inference, no declaration needed).

### Phase 2 — Validator rewrite (CORE WORK)

#### company-workflow

- [x] Delete `skills/company-workflow/contract.json`
- [x] Rewrite `skills/company-workflow/SKILL.md` validator section: replaced contract.json reads with template-driven derivation. Added "Template-Derived Rules" section codifying the derivation contract. Path Resolution updated to look for `company-artifact-manifests.json` instead of `contract.json` as the asset-found heuristic. File Mode now resolves the matching template by `type`, parses its frontmatter keys / section headers / phase headers / checkbox count, and validates the instance against THAT. Directory Mode reuses File Mode's logic for the TRACKER plus per-artifact frontmatter comparison (manifest-driven, unchanged). SKILL frontmatter version bumped 2.0.0 → 3.0.0.
- [x] Update `skills/company-workflow/WORKFLOW.md` — 3 references updated: Step 1 Generate Initial Docs paragraph, Using validate File Mode bullets, What Gets Deployed file tree
- [x] Audit `skills/company-workflow/fixtures/` — no rewrites needed. The 3 invalid-* fixtures still produce violations under template-derived rules (they're broken in ways the new validator catches: missing frontmatter, missing Lifecycle, wrong section order). The valid-feature-dir already had all 11 frontmatter keys including id/blocked_by/workflow_type/url, so it remains valid.

#### personal-workflow

- [x] Delete `skills/personal-workflow/contract.json`
- [x] Rewrite `skills/personal-workflow/check.md`: top intro updated to declare "templates are the single source of truth"; Normalization Rules section gained a "Template-derived rules" reference table; Step 2 (Read Contract) deleted; Steps 3-6 (now 2-6.5) rewritten to template-derive `required_fields`, `expected_sections`, `required_phases`, `min_checkboxes`. Step 12 (Directory Mode lifecycle check) rewritten to apply File Mode steps to the TRACKER. Error messages list updated: contract.json entry removed, Template-not-found and Unknown-type entries added.
- [x] Update `skills/personal-workflow/SKILL.md`: Path Resolution updated (looks for `personal-artifact-manifests.json` instead of `contract.json`); Overview rewritten with "templates as single source of truth" note; Error Handling table: contract.json entry removed, Template-not-found + Unknown-type entries added. SKILL frontmatter version bumped 1.0.0 → 2.0.0.
- [x] Update `skills/personal-workflow/WORKFLOW.md` — 2 references updated: Step 1 paragraph, What Gets Deployed file tree
- [x] Audit `skills/personal-workflow/fixtures/`: updated 2 valid fixtures to add `id` and `blocked_by` keys (they were valid under the old contract which only required name/type/status/created/updated — under the new template-derived rules they need every key the template emits). The 4 invalid-* fixtures still demonstrate violations under the new rules.

#### Cross-cutting

- [x] Update `skills-catalog.json`: removed `contract.json` from both skills' `files` arrays; bumped versions (personal 1.0.0 → 2.0.0, company 2.1.0 → 3.0.0); updated descriptions to mention "templates are the single source of truth"
- [x] Confirmed `scripts/validate.sh` does not reference contract.json (no changes needed)
- [x] Confirmed `scripts/skills-deploy` does not have contract.json-specific deployment paths beyond reading the catalog `files` array (which we updated above) — no script changes needed
- [x] Confirmed `CLAUDE.md` does not mention contract.json (no changes needed)

### Phase 3 — Regression tests

- [x] Added "Regression test (D000007)" block in `scripts/test.sh` (6 checks):
  - skills/company-workflow/contract.json absent
  - skills/personal-workflow/contract.json absent
  - 3 validator files (company SKILL, personal SKILL, personal check.md) do NOT load contract.json at runtime (regex matches `cat|jq|Read|read.*contract.json`)
  - skills-catalog.json `files` arrays for both skills no longer reference contract.json
- [x] Spot-checked existing work items against new template-derived rules: D000003, D000005, D000006, D000007 all match the template's frontmatter keys + sections + phase count + checkbox count exactly. F000002 and F000003 (legacy closed features) drift from the current tracker-feature.md template by 1 checkbox each ("Milestones scaffolded" gate added to template after they were authored). This drift is now correctly surfaced by the new validator — strictly stronger than before. Documented as "expected behavior change" per RCA's regression risk table; legacy backfill is a follow-up cleanup, not blocking D000007.

### Phase 4 — Ship + close D000004

- [x] Updated `work-items/defects/D000004_company_workflow_contract_template_drift/D000004_TRACKER.md`: status → `superseded`, updated → 2026-04-17, Log entry appended noting D000007 supersedes
- [ ] Update `CHANGELOG.md` and bump skill version per `scripts/collection-version.sh` (deferred to `/ship`)
- [ ] Ship via `/ship`

### Phase 5 — Out of scope (file separately if confirmed)

- [ ] Audit findings 2/3/4 (template-vs-template inconsistencies in `doc-milestones.md`, `doc-review-notes.md`, `tracker-review.md`) — these are template-level cleanups, not architectural. After D000007 lands, they become a small bundled cleanup defect (D000008) that the now-template-driven validator will help catch by surfacing the structural outliers explicitly.

## Log

- 2026-04-17: Created. Audit at 2026-04-17 (via /office-hours invocation, repurposed as direct review per user preference for skipping design ceremonies on small tasks) surfaced 4 new template/contract drift findings on top of D000004 (BLOCKED) and D000006's partial fix (deferred validator enforcement). User asked whether the validator is even needed. Conclusion: no — templates can be the single source of truth. This defect captures the architectural choice and supersedes D000004.
- 2026-04-17: Implemented. 12 files modified (validator rewrites, WORKFLOW updates, catalog cleanup, fixture backfills, test.sh regression block) + 2 contract.json files deleted + D000004 superseded. Verifications: `./scripts/validate.sh` PASS (0/0); `./scripts/test.sh` PASS (0 failures, all D000005/D000006/D000007 regression blocks green); manual rule-derivation spot-check shows D000007 itself + D000003/D000005/D000006 all match template-derived rules exactly; legacy F000002/F000003 features now surface 1-checkbox drift each (the "Milestones scaffolded" gate added to template after they were authored — strictly correct enforcement, documented as expected-behavior-change). No CI / deploy script changes needed beyond catalog. Pending: CHANGELOG + VERSION bump in `/ship`.
- 2026-04-25: Closed. The fix has been in main since shortly after 2026-04-17 — `contract.json` files don't exist anywhere in the repo, F000003 DESIGN.md decision #2 explicitly codifies "Templates are the single source of truth", and the validator derives every rule at runtime from the matching template. Tracker drift fixed during F000003 v1.0.0 cut.

## PRs

## Files

### To delete

- `skills/company-workflow/contract.json`
- `skills/personal-workflow/contract.json`

### To rewrite (validator core)

- `skills/company-workflow/SKILL.md` — Steps that read contract.json
- `skills/personal-workflow/SKILL.md` — path resolution + error table
- `skills/personal-workflow/check.md` — Steps 2, 4, 5, 6 (Tier 1) + Step 15-16 (Tier 2)

### To update (docs)

- `skills/company-workflow/WORKFLOW.md` — Using validate section
- `skills/personal-workflow/WORKFLOW.md` — Validation Rules section
- `CHANGELOG.md` — Changed entry
- `VERSION` — minor bump (this is an architectural change to the skill contract; consider 0.7.x → 0.8.0)

### To update (tests + tooling)

- `scripts/test.sh` — new "Regression test (D000007)" block
- `skills/{company,personal}-workflow/fixtures/` — audit + rewrite contract-specific fixtures
- `skills-catalog.json` — remove contract.json entries from `files` arrays if present

### To cross-reference

- `work-items/defects/D000004_company_workflow_contract_template_drift/D000004_TRACKER.md` — Log entry + status update marking it superseded

## Insights

### Why eliminate the contract instead of fixing the drift

D000004 surveyed 5 design options for **closing the drift**: round-trip validators (A, E), pre-rendered fixtures (B), CI lints (C), self-tests (D). All five preserve the two-source-of-truth pattern and add tooling to keep them aligned. They make the drift more expensive to introduce; they don't eliminate it.

D000007 introduces option F: collapse to one source. The validator already needs to read the template (Step 11/16 of `personal-workflow/check.md` does Template Frontmatter Comparison today). Extending that flow to also derive section order, lifecycle phases, and minimum checkboxes makes contract.json fully redundant. Single source. No drift possible. Whole class of defects disappears.

### What the contract.json was actually buying

Auditing what contract.json declares that templates can't:

| contract.json field | Templates can express? | Notes |
|---|---|---|
| `frontmatter.required` | Yes — fields in template are required | implicit |
| `frontmatter.recommended` | No | advisory only; nobody enforces today |
| `sections.required` | Yes — `##` headers in template | implicit |
| `sections.optional` | Partial — sections present in some per-type templates and absent in others | becomes per-type-structural |
| `sections.expected_order` | Yes — order in template | implicit |
| `sections.type_specific_optional` | Yes — per-type templates either include or omit | per-type-structural |
| `lifecycle.phases` | Yes — `### Phase N:` headers in template | implicit |
| `lifecycle.min_checkboxes` | Yes — count `- [ ]` in template | implicit |

Net loss: only `frontmatter.recommended`. Today's "recommended" fields (`repo`, `branch`) are advisory and never enforced (validator only flags `required` violations). Promoting them to required (or accepting the loss) is a one-line WORKFLOW.md note.

### Cross-skill consistency dividend

After D000007, both workflow skills follow the same model. Future template changes propagate to validator behavior automatically in both skills. A new skill that adopts the same pattern (e.g., a hypothetical `team-workflow`) doesn't need to ship a `contract.json` — it just needs templates and a validator that follows the same template-derivation pattern.

### Cross-reference

- **D000004** — superseded by D000007 (this defect). The architectural choice in D000004 was the gate; D000007 chooses option F (the 6th option, not in D000004's original 5).
- **D000006** — partially superseded. The Phase 2 test-verification gates landed as template-only with validator enforcement deferred. After D000007, the gates are validator-enforced automatically because the new template-derived validator counts `- [ ]` boxes and requires the gate sections.
- **D000003 + D000005** — independent, unaffected.

## Journal
