---
name: "/CJ_doc_audit reports missing required docs but doesn't point at the remedy"
type: defect
id: "D000034"
status: active
created: "2026-06-13"
updated: "2026-06-13"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "claude/heuristic-wilson-280dbe"
blocked_by: ""
---

## Lifecycle

### Phase 1: Track

1. Reproduction documented (see Reproduction Steps)
2. Working branch created: claude/heuristic-wilson-280dbe
3. Required docs scaffolded (D000034 RCA + test-plan)
4. Root cause identified

**Gates:**
- [x] Reproduction steps documented
- [x] Working branch created (branch field populated)
- [x] Required docs scaffolded (RCA + test-plan)
- [x] Root cause identified

### Phase 2: Implement

1. Fix written to `scripts/doc-spec.sh` `_check_on_disk` (emit a REMEDIATION pointer)
2. Regression test added (`tests/doc-spec-overlay.test.sh` 8a-2 + 8b-2)
3. Doc surfaces updated (SKILL.md Step 3/6, USAGE.md)
4. RCA updated with the final root cause

**Gates:**
- [x] Fix committed
- [x] RCA doc updated
- [x] Todos section reflects remaining work (no stale items)

### Phase 3: Ship

1. Validation: `scripts/validate.sh` (0/0), both affected test suites green, shellcheck clean
2. /ship — open the fix PR
3. PR is the review gate — STOP (skill-surface work, no auto-deploy)

**Gates:**
- [x] Test-plan verified (regression scenarios passing)
- [ ] /ship — PR created
- [ ] Reviewed + landed (operator-driven; deploy is a separate human step)

## Reproduction Steps

In any repo (most visibly a fresh consumer repo):

1. Run `/CJ_doc_audit` (or `scripts/doc-spec.sh --check-on-disk`) where the
   doc-spec contract is seeded but its declared docs (e.g. `docs/workflow.md`)
   do not yet exist on disk.
2. Observe: Stage 1 emits `FINDING: stage1/declared-exists — declared doc
   missing on disk: …` for each missing doc, then `CHECKS_RUN=`/`FINDINGS=`.
3. Expected: the operator is told how to fix it (which verb scaffolds the
   missing docs). Actual: the report ends at a bare list of missing docs with
   no next step — a dead-end.

## Todos

- [ ] Ship via /ship (Gate #2 human diff review)

## Log

- 2026-06-13: Root-caused interactively. Disposition chosen by operator:
  "remediation pointer only" (no force-regenerate; the audit stays read-mostly).

## PRs

<!-- PR link populated at /ship. -->

## Files

- `scripts/doc-spec.sh` — `_check_on_disk`: emit the REMEDIATION pointer.
- `skills/CJ_doc_audit/SKILL.md` — Step 3 + Step 6 report grammar.
- `skills/CJ_doc_audit/USAGE.md` — Stage-1 mental-model note.
- `tests/doc-spec-overlay.test.sh` — 8a-2 (clean ⇒ no line) + 8b-2 (missing ⇒ pointer).

## Insights

The doc-spec contract self-bootstraps (`--seed`) but the docs it *declares*
were reported-only, with no pointer to the scaffolder (`/CJ_document-release`).
The fix preserves the audit's read-mostly design — it names the remedy, it does
not scaffold. See the D000034 RCA.

## Journal
- 2026-06-13 [defect-opened] D000034 opened from an interactive /CJ_goal_defect investigation; root cause found, fix implemented + validated, shipping to PR.
