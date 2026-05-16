---
name: "Delete skill and update docs"
type: user-story
id: "S000053"
status: active
created: "2026-05-15"
updated: "2026-05-15"
parent: "F000023"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "worktree-rosy-tinkering-pearl"
blocked_by: "S000052"
---

<!-- Prerequisite: Before scaffolding this work item, run /office-hours to
     produce a design plan in ~/.gstack/projects/. Distill that plan into
     DESIGN.md during Phase 1 below. -->

## Lifecycle

### Phase 1: Track

1. Read parent tracker to understand scope
2. Create working branch: `git checkout -b feat/delete_skill_and_update_docs` (or use parent's branch if shipping in same PR)
3. Scaffold work item directory and TRACKER.md
4. Distill `DESIGN.md` from the /office-hours output (own session or parent's) — from `templates/doc-DESIGN.md`
5. Scaffold `SPEC.md` (requirements, acceptance criteria, architecture, tradeoffs) — from `templates/doc-SPEC.md`
6. Scaffold `TEST-SPEC.md` (smoke + E2E test scenarios) — from `templates/doc-TEST-SPEC.md`
7. Break into child tasks if scope warrants decomposition

**Gates:**
- [x] /office-hours design referenced (own or parent's, captured in DESIGN.md)
- [x] Working branch created (`branch` field populated)
- [x] DESIGN + SPEC + TEST-SPEC scaffolded
- [x] Acceptance criteria defined
- [x] Tasks broken down (or N/A — atomic story)

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
- [ ] Todos section reflects remaining work (no stale items)
- [ ] Files section updated with changed files

### Phase 3: Ship

1. Run `/CJ_personal-workflow check` — verify all validation passes
2. Verify smoke tests pass in CI (automated regression)
3. Walk E2E manually
4. Ensure all child tasks (if any) have shipped
5. Run `/ship`
6. Run `/land-and-deploy`

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

- [ ] `deprecated/CJ_company-workflow/` directory deleted in its entirety.
- [ ] `CJ_company-workflow` entry removed from `skills-catalog.json`.
- [ ] `template-registry.json` `CJ_company-workflow` entry removed (or the entire file deleted if confirmed orphaned).
- [ ] `scripts/test.sh` blocks coupled to `deprecated/CJ_company-workflow/` (~35 assertions, T000011 sync-check block) deleted; structural assertions ported to `work-copilot/` equivalents where they still apply.
- [ ] `CLAUDE.md` updated: "What this repo is" no longer mentions mirroring; "Work item templates" CJ_company-workflow bullet removed; "Template naming" `work-copilot/` paragraph rewritten as a self-contained bundle; "Deprecated skills convention" CJ_company-workflow example dropped (convention kept).
- [ ] `README.md` `CJ_company-workflow` row removed from the catalog table.
- [ ] `scripts/copilot-deploy.py` verified to have no references to `deprecated/CJ_company-workflow/` (likely already clean; verify).
- [ ] `scripts/skills-deploy install [--include-deprecated]` verified to gracefully handle the now-missing entry.
- [ ] `grep -rn "CJ_company-workflow" .` returns only doc/changelog mentions and comments — no runtime path references.
- [ ] `./scripts/validate.sh && ./scripts/test.sh` PASSes after all edits.
- [ ] `./scripts/copilot-deploy.py doctor` against a known target repo PASSes.

## Todos

<!-- Actionable items for this story. -->

- [ ] Confirm S000052 has landed first (blocker). Re-grep the codebase for any new `deprecated/CJ_company-workflow/` references that emerged since the autoplan review.
- [ ] Remove the `CJ_company-workflow` entry from `skills-catalog.json`.
- [ ] Delete `deprecated/CJ_company-workflow/` recursively.
- [ ] Edit `scripts/test.sh`: remove the ~35 assertions and T000011 sync-check synthetic block coupled to `deprecated/CJ_company-workflow/`. Port any structural assertions (template presence, manifest schema parity) to `work-copilot/` equivalents.
- [ ] Edit `CLAUDE.md`: drop byte-mirror language in 4 sections per design.
- [ ] Edit `README.md`: remove CJ_company-workflow row from catalog table.
- [ ] Edit `template-registry.json`: remove the CJ_company-workflow entry, or delete the file if confirmed orphaned (no readers).
- [ ] Verify `scripts/copilot-deploy.py` has no `deprecated/CJ_company-workflow/` references — grep + read.
- [ ] Verify `scripts/skills-deploy install` handles missing-entry edge case (read code; should be catalog-driven and gracefully no-op).
- [ ] (Optional polish) Update textual references in `skills/CJ_personal-workflow/check.md`, `skills/CJ_implement-from-spec/implement.md`, `skills/CJ_personal-pipeline/pipeline.md` — comparison/documentation mentions only; low priority.
- [ ] Run `./scripts/validate.sh && ./scripts/test.sh` from a clean tree — must PASS.
- [ ] Run `./scripts/copilot-deploy.py doctor <target_repo>` — must PASS.

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-05-15: Created. Cleanup story for F000023 — depends on S000052 landing first (which removes the byte-identity enforcement that keeps `deprecated/CJ_company-workflow/` alive).

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. -->

- `deprecated/CJ_company-workflow/` (directory deleted)
- `skills-catalog.json` (CJ_company-workflow entry removed)
- `scripts/test.sh` (deprecated/CJ_company-workflow/-coupled assertions removed; T000011 sync-check synthetic block removed; structural assertions ported to work-copilot/ where applicable)
- `CLAUDE.md` (4 sections updated per design's migration steps)
- `README.md` (catalog table row removed)
- `template-registry.json` (entry removed, or file deleted if orphaned)
- `scripts/copilot-deploy.py` (verified; likely no changes)
- `scripts/skills-deploy` (verified; likely no changes)
- (Optional) `skills/CJ_personal-workflow/check.md`, `skills/CJ_implement-from-spec/implement.md`, `skills/CJ_personal-pipeline/pipeline.md` (low-priority textual polish)

## Insights

<!-- Non-obvious findings worth remembering. -->

- This story is dependent on S000052 landing first — only then is the byte-identity enforcement gone and `deprecated/CJ_company-workflow/` officially orphaned. Trying to delete the dir while Error check 10 still exists would just break the validator.
- The autoplan review pre-surfaced that `scripts/test.sh` has ~35 assertions coupled to `deprecated/CJ_company-workflow/` paths plus a T000011 MIRROR_SPECS sync-check synthetic test block (~80 lines). These are gone-implementation-detail tests; deleting them is the right call per Principle 5 (explicit over clever). Any *structural* assertions (template presence, manifest schema parity) get ported to `work-copilot/` equivalents.
- `template-registry.json` is referenced only by history docs; no scripts read it. Confirmed orphaned by autoplan review. Implementer picks between editing it or deleting it.
- This story can be further sub-split into smaller PRs if churn is desired (e.g., catalog-entry-delete PR, directory-delete PR, doc-update PR, test.sh-prune PR). Single-PR is also acceptable. Implementer's call.

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

- [decision] 2026-05-15: Story scope explicitly includes the `test.sh` block deletions (autoplan finding folded in). Rationale: leaving zombie test blocks after the implementation they test is gone obscures the test suite's intent. Principle 5 (explicit over clever) applies.
- [decision] 2026-05-15: Story scope explicitly includes the `template-registry.json` cleanup (verification finding from /office-hours session folded in). The entry is orphaned (no script readers) and points at a directory that S000053 will delete.
- [finding] 2026-05-15: Blocked-by relationship to S000052 — captured in frontmatter `blocked_by` field. Validator + downstream automation should respect this.
