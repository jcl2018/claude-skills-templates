---
type: design
parent: S000116
title: "Forced contract seeding + stale-engine-shadow fix — Story Design"
version: 1
status: Draft
date: 2026-06-29
author: chjiang
reviewers: []
---

<!-- Atomic story design. Full epic context: ../F000069_DESIGN.md and the parent's
     /office-hours design doc (Part 3 / U2). Story-3 design doc:
     ~/.gstack/projects/jcl2018-claude-skills-templates/forced-seeding-design-20260629-010904.md -->

## Problem

The operator's original observation: "the audit skills don't force generate the
seeding" in a consumer repo. Two root causes:

1. **Stale-engine shadow (the actual bug).** The audits resolve their engine
   **repo-local `scripts/<engine>.sh` → `_cj-shared`** with NO staleness check. A
   consumer repo that vendored an OLD `scripts/doc-spec.sh` (or test/workflow) has
   that stale copy WIN over the current `_cj-shared` one — and the stale engine
   lacks the current `--classify`/`--seed`/`--render-docs` behavior, so the audit's
   seed step silently no-ops. The seeding "doesn't fire."
2. **Lazy + incomplete seeding.** Even when it fires, seeding is lazy (only on the
   first audit run) and each audit seeds only ITS OWN contract (`/CJ_doc_audit` →
   `doc-spec`; `/CJ_test_audit` → `test-spec`). The new `workflow-spec` (Story 2)
   is seeded by NO audit. There is no single "force-seed everything at adoption"
   entry point.

Net: contract seeding is neither forced nor reliable. This story makes it both.

## Shape of the solution

Two halves, one goal — force-generate ALL THREE contracts (`doc-spec` +
`test-spec` + `workflow-spec`) reliably, through every adoption path.

| Concern | Mechanism | Where |
|---------|-----------|-------|
| The actual bug — stale repo-local engine shadows `_cj-shared` | Capability probe (`--classify` → `GENERATION=`) in both audits' Step-1 engine resolution; stale ⇒ fall back to `_cj-shared` + emit `stage1/engine-stale` | `skills/CJ_doc_audit/SKILL.md`, `skills/CJ_test_audit/SKILL.md` |
| Single shared seeding routine | `do_seed_contracts` — 3-contract loop, engine-resolve (with the stale probe), corruption-guarded temp→validate→mv, idempotent present-skip, airtight workbench-self-repo skip | `scripts/skills-deploy` |
| Trigger (a) — explicit adoption command | `seed-contracts` subcommand (cwd or `--repo`) | `scripts/skills-deploy` |
| Trigger (b) — forced on consumer install | `install` always-seeds the cwd when it is a git repo AND not the workbench self-repo | `do_install` / `do_bundle_install` |
| Trigger (c) — lazy on first audit | `/CJ_doc_audit` Step 2 also seeds `workflow-spec`; `/CJ_test_audit` Step 2 unchanged; both reliable via the stale probe | `skills/CJ_doc_audit/SKILL.md` |

```
adoption (any of: seed-contracts / consumer install / first audit run)
        │
        ▼  do_seed_contracts  (or the audit Step-2 lazy seed)
   for each contract in {doc-spec, test-spec, workflow-spec}:
        resolve engine (repo-local → STALE-PROBE → _cj-shared)
        if spec/<contract>.md ABSENT:
             engine --seed > $TMP  ;  require non-empty AND --validate-clean  ;  mv $TMP spec/<contract>.md
        else: present (skip)
   workbench self-repo? ⇒ skip entirely (data-loss guard)
```

## Big decisions

| # | Decision | Why |
|---|----------|-----|
| 1 | The stale-engine capability probe is IN regardless | It is the ACTUAL bug behind "doesn't force generate the seeding" — a stale repo-local engine shadows `_cj-shared` and the seed step silently no-ops. Highest-value single fix; it makes the EXISTING lazy seeding work. |
| 2 | Maximal/forced proactive seeding — three triggers, not one | The operator chose the maximal combination so EVERY adoption path (explicit command, consumer install, first audit run) force-generates the seeding. A single `do_seed_contracts` is the shared implementation. |
| 3 | `--classify` is the probe (not `--seed`/`--render-docs`) | It is SIDE-EFFECT-FREE (read-only) and every current engine emits `GENERATION=`. Probing with a mutating subcommand would risk a write before the staleness verdict. |
| 4 | Corruption-guarded seed (temp → non-empty + `--validate`-clean → mv) | Mirrors the doc-release self-bootstrap guard: a half-written or invalid `--seed` output must never land in `spec/`. The validate-before-mv makes a botched seed a `seed-failed` report, not a corrupt registry. |
| 5 | Workbench self-repo detection must be airtight (data-loss guard) | A false negative would re-seed the workbench's real `spec/*.md` with empty skeletons (DATA LOSS). Detect via manifest `source == repo toplevel` AND/OR canonical-contract presence; the corruption guard + idempotent present-skip + a hermetic assertion are defense-in-depth. |
| 6 | `/CJ_doc_audit` owns the lazy `workflow-spec` seed | The doc audit's Stage 1 freshness-checks the `docs/workflows/` surface, so it is the natural owner of seeding `workflow-spec` when absent; `/CJ_test_audit` Step 2 stays unchanged (already seeds test-spec). |

## Risks & open questions

| Risk / Question | Next check |
|-----------------|-----------|
| Workbench self-repo detection false negative → re-seeds the real contracts with skeletons (data loss) | Implement: detect via manifest `source == repo toplevel` AND/OR canonical-contract presence; the corruption guard + idempotent present-skip are second/third lines; the hermetic test asserts a workbench-like temp repo is SKIPPED. |
| `install` always-seeds is a new surprise write surface (consumer install now writes `spec/*.md`) | Implement: idempotent (skip if present), git-repo guarded, visible one-line note, skeletons are valid+minimal. Accepted per the operator's forced/always choice. |
| `--classify` probe assumes every current engine supports it | Implement: true for doc-spec/test-spec/workflow-spec today; a future engine must keep `--classify` side-effect-free — note it in the engine convention. |
| `skills-deploy` is a sensitive deploy surface | PR-stop + human review is the gate; the change is additive (new subcommand + a guarded consumer-only hook + a new routine). |
| A new test must register in the test contract | Implement: add the `spec/test-spec-custom.md` units row(s) so Check 24 reverse-sweep resolves them (else a hard failure). |

## Definition of done

- [ ] Both audits' Step-1 engine resolution probes the repo-local engine with `--classify`; stale ⇒ fall back to `_cj-shared` + emit `stage1/engine-stale` naming the remedy; documented in each error-path grammar.
- [ ] `do_seed_contracts` exists in `scripts/skills-deploy`: 3-contract loop, engine-resolve (stale-probe), corruption-guarded temp→validate→mv, idempotent present-skip, per-contract report, airtight workbench-self-repo skip.
- [ ] `seed-contracts` subcommand + usage line; operates on cwd (or `--repo`).
- [ ] `install` always-seeds the cwd consumer repo (git-repo guarded, self-repo skip, visible note); workbench self-install skips.
- [ ] `/CJ_doc_audit` Step 2 also lazily seeds `workflow-spec` when absent (corruption-guarded shape); `/CJ_test_audit` Step 2 unchanged.
- [ ] `scripts/test-deploy.sh` covers `seed-contracts` + the install always-seeds path.
- [ ] NEW hermetic test proves seed-all-3 + idempotent + workbench-self skip AND the stale-engine probe fallback + `engine-stale` finding; `spec/test-spec-custom.md` units row(s) added; Check 24 resolves them.
- [ ] `scripts/validate.sh` 0/0; `scripts/test.sh` green incl. the new test + test-deploy coverage; post-sync `/CJ_doc_audit` + `/CJ_test_audit` report 0 findings.

## Not in scope

- The test catalog generation (Story 1 — S000114, shipped) and the workflow generation (Story 2 — S000115, shipped) — separate, already-landed stories.
- Consumer-repo deterministic Stage-1 enforcement gate (Story 4 — `scripts/cj-contract-gate.sh` + hook/CI install) — remains deferred.
- Changing the CONTENT of any seeded contract beyond what each engine's `--seed` already emits — this story delivers the seeding triggers + the stale-engine fix, not a rewrite of the seed skeletons.
- Editing upstream gstack skills.

## Pointers

- Parent feature design: [../F000069_DESIGN.md](../F000069_DESIGN.md)
- Story tracker: [S000116_TRACKER.md](S000116_TRACKER.md)
- Story spec: [S000116_SPEC.md](S000116_SPEC.md)
- Story test-spec: [S000116_TEST-SPEC.md](S000116_TEST-SPEC.md)
- Sibling stories: [../S000114_gen_tests_catalog_freshness/S000114_SPEC.md](../S000114_gen_tests_catalog_freshness/S000114_SPEC.md) (test-catalog generation), [../S000115_workflows_full_symmetric_generation/S000115_SPEC.md](../S000115_workflows_full_symmetric_generation/S000115_SPEC.md) (workflow generation — adds the `workflow-spec` contract this story seeds)
- Reference guard primitive: `/CJ_document-release` self-bootstrap (corruption-guarded `--seed` temp→validate→mv); engine resolution idiom in `scripts/doc-spec.sh` / `scripts/test-spec.sh` / `scripts/workflow-spec.sh`
- Source design doc: `~/.gstack/projects/jcl2018-claude-skills-templates/forced-seeding-design-20260629-010904.md` (Part 3 / U2)
