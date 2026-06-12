---
skill: CJ_doc_audit
last-updated: "2026-06-12T00:00:00Z"
---

# Using /CJ_doc_audit

## When to use

- You want one keystroke that answers "do this repo's docs follow its doc
  contract?" — in the workbench OR any consumer repo.
- You are adopting the doc contract in a fresh repo: the first run creates
  `spec/` and seed-delivers `spec/doc-spec.md` (`seeded: yes`), giving you the
  portable general contract with zero manual steps.
- Inside `/CJ_qa-work-item` Step 8.6c (a cj_goal run): the QA agent executes
  this skill's steps INLINE and lifts the report into the QA RESULT's
  `AUDITS=` field for the post-QA checkpoint.
- After a doc-heavy change, before shipping: a quick conformance + alignment
  pass that catches orphan docs, missing front tables, stale views, and
  requirement drift.

## When NOT to use

- To FIX docs or fold doc updates into a PR — that is `/CJ_document-release`
  (the Step 5.5 doc-sync wrapper). This skill only reports; its single write
  is the idempotent seed delivery.
- To edit the contract itself — add rows to `spec/doc-spec-custom.md` (never
  to the general file) by hand; the audit verifies, it does not author.
- In a non-git directory (the skill refuses).
- To audit tests — that is `/CJ_test_audit`, the symmetric verb.

## Mental model

Two tiers, one merged registry, two enforcement layers. The general contract
(`spec/doc-spec.md`) is byte-identical in every adopting repo — delivered by
`doc-spec.sh --seed`, never edited in place. Repo-specific docs live in the
`spec/doc-spec-custom.md` overlay; the parser merges the two so the audit (and
every other consumer) sees ONE registry. The audit then runs a deterministic
floor (declared ⇔ on-disk, no orphans, ID-free human docs, front tables,
views-in-sync) and an agent-judged alignment layer on top (each doc vs its
`requirement:` string). Findings ride the report — `DOC_AUDIT: findings` +
`FINDING:` lines — and never crash or halt; in a cj_goal run the operator
decides at the post-QA checkpoint.

## Common pitfalls

- **Expecting the audit to halt a pipeline.** It never does. QA findings ride
  a GREEN RESULT; the orchestrator's checkpoint AUQ owns the Continue/Halt
  decision (waivers journal as `[qa-audit-waived]`).
- **Editing `spec/doc-spec.md` to add a repo doc.** That breaks the
  seed byte-identity contract — the row belongs in `spec/doc-spec-custom.md`.
  A path declared in both files is a validate error (duplicate-path guard).
- **Reading `seeded: no` as a failure.** It is the idempotence signal — the
  contract already existed, nothing was re-delivered.
- **Running in a repo without the deployed engine.** The skill resolves
  `doc-spec.sh` repo-local then `~/.claude/_cj-shared/scripts/`; on a machine
  that never ran `skills-deploy install`, the engine finding tells you to.
- **Expecting view-sync findings in a consumer repo to name the generator.**
  Where `scripts/generate-doc-views.sh` is absent, views are judged against
  fresh `--render` output instead — same contract, different mechanism.

## Related skills

- `/CJ_test_audit` — the symmetric verb for the test contract
  (`spec/test-spec.md` + `spec/test-spec-custom.md`).
- `/CJ_document-release` — the fixer: stub-scaffolds missing declared docs,
  folds doc updates into the same PR (Step 5.5 doc-sync), and is the OTHER
  deliverer of the doc-spec seed (identical file, identical `spec/` path).
- `/CJ_qa-work-item` — runs this audit inline at Step 8.6c; its RESULT carries
  the findings to the cj_goal checkpoint.
- `/CJ_portability-audit` — the same audit-verb shape applied to skill
  portability declarations.
