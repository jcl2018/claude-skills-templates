---
skill: CJ_doc_audit
last-updated: "2026-06-13T07:33:53Z"
---

# Using /CJ_doc_audit

## When to use

- You want one keystroke that answers "do this repo's docs follow its doc
  contract?" — in the workbench OR any consumer repo — with verdicts that are
  EARNED: a deterministic engine floor, evidence-cited requirement judgments,
  and a drift cross-walk against the live repo state.
- You are adopting the doc contract in a fresh repo: the first run creates
  `spec/` and seed-delivers `spec/doc-spec.md` (`seeded: yes`), giving you the
  portable general contract with zero manual steps.
- Inside `/CJ_qa-work-item` Step 8.6c (a cj_goal run): the QA agent executes
  ALL THREE STAGES inline (the nested-subagent wall — no fresh-context
  dispatch there) and lifts the per-stage report into the QA RESULT's
  `AUDITS=` field for the post-QA checkpoint.
- After a doc-heavy change, before shipping: Stage 1 catches orphan docs,
  missing front tables, and stale views in one engine call; Stage 2 catches
  requirement drift; Stage 3 catches content that no longer matches the
  implementation (a workflow doc missing a routable skill, an architecture
  doc naming retired machinery).

## When NOT to use

- To FIX docs or fold doc updates into a PR — that is `/CJ_document-release`
  (the Step 5.5 doc-sync wrapper). This skill only reports; its single write
  is the idempotent seed delivery.
- To edit the contract itself — add rows to `spec/doc-spec-custom.md` (never
  to the general file) by hand; the audit verifies, it does not author.
- In a non-git directory (the skill refuses).
- To audit tests — that is `/CJ_test_audit`, the symmetric verb.

## Mental model

Three stages, split exactly along the deterministic/judged boundary. **Stage 1
(deterministic — engine):** ONE call to `doc-spec.sh --check-on-disk` — the
four conformance checks (declared⇔on-disk, orphans, root-declared, ID-free
human docs) live inside a tested script, so no
executor can re-derive the loops wrong (the word-split defect class is
designed out). When declared docs are missing, Stage 1 also prints a trailing
`REMEDIATION:` pointer to `/CJ_document-release` (the scaffolder) — the audit
names the fix for a dead-end "doc missing" list, but stays read-mostly and
never scaffolds the docs itself. **Stage 2 (requirement compliance — agent-judged,
evidence-forced):** each declared doc's `Requirement` cell is quoted,
decomposed into clauses, and judged clause-by-clause with cited evidence —
verdicts `satisfies` / `missing-requirement (soft)` / `n/a` /
`FINDING: stage2/<path>`. **Stage 3 (implementation drift — agent-judged):**
ground truth first (enumerate catalog skills, scripts, workflows, dirs), then
each contract doc is cross-walked against it — verdicts `no-drift` /
`FINDING: stage3/<path> — <named delta>`.

Standalone, Stages 2+3 are REQUIRED to run in ONE fresh-context subagent
whose prompt carries only repo root + engine path + the Stage-1 report + the
stage protocols — never the invoking session's beliefs (the
resident-context-rubber-stamp defense). The report prints findings PER STAGE
(`STAGE1/2/3_FINDINGS=` + three `--- stage N ---` sections, `stageN/`
prefixes); findings never crash or halt — in a cj_goal run the operator
decides at the post-QA checkpoint.

## Common pitfalls

- **Expecting the audit to halt a pipeline.** It never does. QA findings ride
  a GREEN RESULT; the orchestrator's checkpoint AUQ owns the Continue/Halt
  decision (waivers journal as `[qa-audit-waived]`).
- **Re-deriving Stage 1 by hand.** The deterministic pass is the engine call —
  printed verbatim. Hand-rolled conformance loops are exactly the defect class
  `--check-on-disk` exists to kill; if you find yourself writing a `for` loop
  over docs, you are doing it wrong.
- **Skipping the fresh-context dispatch standalone.** Stages 2+3 judged in the
  invoking session inherit its beliefs about the docs ("we just updated X").
  The dispatch is REQUIRED at top level; only the in-QA posture runs inline
  (and labels its stage headers `inline`, honestly).
- **Editing `spec/doc-spec.md` to add a repo doc.** That breaks the
  seed byte-identity contract — the row belongs in `spec/doc-spec-custom.md`.
  A path declared in both files is a validate error (duplicate-path guard).
  And an overlay that does not declare ITSELF is an orphan finding by design.
- **Reading `seeded: no` as a failure.** It is the idempotence signal — the
  contract already existed, nothing was re-delivered.
- **Reading `REGISTRY=absent` from the engine as a crash.** It is the
  machine-classifiable "no contract yet" state (exit 0) — the skill's seed
  delivery owns that case before the engine ever runs.
- **Running in a repo without the deployed engine.** The skill resolves
  `doc-spec.sh` repo-local then `~/.claude/_cj-shared/scripts/`; on a machine
  that never ran `skills-deploy install`, the `stage1/engine` finding tells
  you to.

## Related skills

- `/CJ_test_audit` — the symmetric three-stage verb for the test contract
  (`spec/test-spec.md` + `spec/test-spec-custom.md`); when both run together,
  one fresh-context subagent may judge both audits' Stages 2+3.
- `/CJ_document-release` — the fixer: stub-scaffolds missing declared docs,
  folds doc updates into the same PR (Step 5.5 doc-sync), and is the OTHER
  deliverer of the doc-spec seed (identical file, identical `spec/` path).
- `/CJ_qa-work-item` — runs this audit inline at Step 8.6c; its RESULT carries
  the per-stage findings to the cj_goal checkpoint.
- `/CJ_portability-audit` — the same audit-verb shape applied to skill
  portability declarations.
