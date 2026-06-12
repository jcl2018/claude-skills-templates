---
type: design
parent: F000060
title: "Two-tier audit contract — /CJ_doc_audit + /CJ_test_audit, spec seeds + custom overlays, QA-wired audit checkpoint — Feature Design"
version: 1
status: Draft
date: 2026-06-12
author: chjiang
reviewers: []
---

<!-- Distilled from the APPROVED /office-hours design doc
     ~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-claude-unruffled-kalam-e25974-design-20260612-140815.md
     (Status: APPROVED, Mode: Startup). That doc SUPERSEDES the earlier
     same-day orchestrator-gate design (operator redo). Story-scope detail
     (SPEC/TEST-SPEC) lives on the nested user-story S000102. -->

## Problem

The workbench has no operator-facing way to ask, in ANY repo, "do this repo's
docs follow its doc contract, and do its tests follow its test contract?" —
and no moment inside a cj_goal run where the operator SEES those answers
before the pipeline moves on. The doc contract exists (`spec/doc-spec.md`)
but its custom half is fused into the same file, so the general contract can
never be delivered as a byte-identical seed. The test contract exists only as
the workbench-specific 66-row `spec/test-pipeline.md` registry — far too
heavy to deliver to a consumer repo, and invisible to the operator mid-run.

The operator's ask (2026-06-12, superseding the earlier same-day design):
two audit skills callable standalone in any repo, skill-delivered general
spec seeds + optional repo-custom overlays for both contracts, four new QA
steps (update both custom specs, then run both audits), and a HALT-and-PROMPT
checkpoint surfacing the four steps' findings before the pipeline moves on.

## Shape of the solution

Two-tier files + parsers + skills + QA wiring + a demolition, in one PR,
carried by ONE atomic user-story (single-story scope, `/CJ_goal_feature` v1):

| Concern | User-story | Artifact |
|---------|-----------|----------|
| Two-tier spec files (doc + test, general seeds + custom overlays), `doc-spec.sh` overlay merge, NEW `scripts/test-spec.sh` (full parser parity), `/CJ_doc_audit` + `/CJ_test_audit` skills, QA Steps 8.6a–d + checkpoint AUQ in all four pipelines, gate-spec `qa-audit` row, the F000059 test-pipeline demolition + enumerated reference sweep, document-release seeding-path updates, docs/routing/catalog/README sweep, three new test suites | S000102 | [S000102_audit_skills_specs_and_qa_checkpoint/S000102_TRACKER.md](S000102_audit_skills_specs_and_qa_checkpoint/S000102_TRACKER.md) |

The two-tier model: `spec/doc-spec.md` becomes the GENERAL contract,
byte-identical to `doc-spec.sh --seed` output; this repo's custom entries
move to `spec/doc-spec-custom.md` (3 migrated + 2 self-declared rows). The
test contract gets the symmetric pair: `spec/test-spec.md` (NEW seed — 5
portable rules: tests-discoverable, suite-green, new-code-tested,
units-anchored, single-owner) + `spec/test-spec-custom.md` (NEW overlay —
the old 66-row enumeration migrated verbatim in the old row shape, plus an
explicit portability-audit unit). `scripts/test-spec.sh` ports the old
Check-24 coverage engine (forward anchor-grep + reverse sweep + units-gated
≥20-token floor) onto the merged registry. The two skills deliver the seeds
into any repo (`seeded: yes`/`seeded: no` idempotency), run deterministic
conformance + agent-judged alignment, and emit findings reports. QA gains
Steps 8.6a–d (update test-spec-custom, update doc-spec-custom, run doc
audit inline, run test audit inline) with findings riding a GREEN RESULT's
`AUDITS=` field; every cj_goal pipeline then prompts the operator with the
four-step findings digest (Continue / Halt `[qa-audit-declined]`,
end_state `halted_at_qa_audit`) before doc-sync.

## Big decisions

| # | Decision | Why |
|---|----------|-----|
| 1 | D5.1 — `spec/` is the single canonical home for all four spec files | One delivery path; `doc-spec.sh`'s spec/-then-root read fallback stays for back-compat, but seeding + documentation standardize on `spec/` |
| 2 | D5.2 — demolish the F000059 test-pipeline machinery, don't wrap it | One format, fully enforced — never two formats, half enforced; a compatibility layer would keep a 66-row workbench-only registry alive that no consumer repo can carry |
| 3 | D5.3 — custom doc entries migrate to an overlay FILE; `doc-spec.sh` merges internally | Existing consumers (validate.sh Checks 15–23, document-release, generate-doc-views.sh) stay untouched at their call sites; the general file becomes seed-deliverable (amended: document-release IS touched by the demolition + spec/-path standardization) |
| 4 | D5.4 — the checkpoint ALWAYS prompts in interactive runs | The operator sees doc/test audit findings before the PR budget is spent; `--quiet` auto-continues on green, halts on red |
| 5 | D6 — full parser parity (Approach A over B/C) | Agent-only alignment (B) would vary run-to-run and the demolition would net-reduce determinism; pure prose (C) lets a malformed spec silently degrade both audits; the deterministic floor is PORTED, not dropped |
| 6 | Promote `front_table` into the portable seed schema (optional field, enforced only when present) | Seed byte-identity + the duplicate-path-is-an-error rule leave no legal home for workbench-only fields on common docs; the old "workbench-local extension" wording is retired as no longer true |
| 7 | Keep the old unit row shape verbatim in `spec/test-spec-custom.md` | The 66-row migration is a literal row copy (no field mapping, no synthesized values); the coverage engine ports with its extraction grammar and reverse-sweep id conventions intact |
| 8 | Audit findings do NOT flip the QA RESULT red | Tests own the green/red verdict; a red RESULT would halt at the existing qa gate and the operator would never see the findings prompt — the checkpoint owns the findings decision, with auditable `[qa-audit-waived]` / `[qa-audit-declined]` journal lines |
| 9 | `REGISTRY=absent` is a distinct exit-0 path in `test-spec.sh`; reverse floor applies ONLY when `units:` rows exist | Callers classify skip-vs-findings without parsing halt text; a seeded-general-only consumer repo (rules, no units) gets a named note instead of a misleading extraction-grammar finding |

## Risks & open questions

| Risk / Question | Next check |
|-----------------|-----------|
| Seed byte-identity lockstep across 3 copies (general file, `doc-spec.sh` heredoc, `templates/doc-spec-common.md`) breaks in a half-state commit | `tests/doc-spec-overlay.test.sh` adds the general-file⇔seed assertion on top of config-test 13's copy⇔copy identity; pre-commit validate.sh fails half-states |
| Step 8.6d self-application flags the four orchestrators stale on this feature's OWN run | The zero-AUQ contract wording sweep (SKILL.md prose + catalog descriptions + USAGE.md + telemetry enums) lands in the same PR — verified at this feature's own QA |
| Demolition reference sweep misses a `test-pipeline` reference | The sweep is ENUMERATED in the design (CLAUDE.md, architecture.md, document-release SKILL/USAGE, generate-readme.sh heredoc, test.sh blocks, doc-spec rows, TODOS row 12); success criterion 3's grep is the backstop, not the plan |
| Nested-subagent wall: QA (already a subagent) cannot spawn the audit skills as subagents | Both skills document the dual posture — INLINE execution by the QA agent reading the skill files in subagent context; Skill-tool dispatch standalone |
| The four spec-family helpers' resolution idioms drift (spec/-then-root vs `_cj-shared`) | `test-spec.sh` copies `doc-spec.sh`'s registry resolution verbatim; engine resolution in the skills is repo-local → `_cj-shared` (S000088 idiom) |
| Deferred: a generated readable view for the test-spec registry (the old `docs/test-pipeline.md` had one) | TODOS row added in this PR; v1 ships without it |
| Deferred: concern-taxonomy orientation (old TODOS row 12) | Struck as obsolete in this PR; re-evaluated against the new format later |
| Deferred: the portability gate false-halt row | Stays open; not bundled |

## Definition of done

- [ ] Standalone, any repo: in a bare temp git repo, `/CJ_doc_audit` creates `spec/doc-spec.md` from the seed (`seeded: yes` + a verdict); `/CJ_test_audit` does the same for `spec/test-spec.md`; second runs are idempotent (`seeded: no`); in this workbench both run green (FINDINGS=0)
- [ ] Two-tier files: `spec/doc-spec.md` == `doc-spec.sh --seed` byte-for-byte; custom entries live in `spec/doc-spec-custom.md`; merged lists drive Checks 15/17/19/20 + document-release unchanged; generated views regenerate cleanly (Check 23 green)
- [ ] Demolition complete: the four retired files are gone; no `test-pipeline` grep hit outside CHANGELOG, work-items history, and TODOS.md; Check 24 runs `test-spec.sh --check-coverage`, green on the migrated registry
- [ ] Coverage parity: deleting a unit row for an existing test, or adding an unregistered `tests/*.test.sh`, flips Check 24 red
- [ ] QA wiring: `/CJ_qa-work-item` on this feature's own story executes Steps 8.6a–d and returns the extended RESULT + AUDIT_FINDINGS block; all four pipelines carry the checkpoint AUQ + the literal `[qa-audit-declined]` marker; gate-spec row present; Check 22 green
- [ ] This run itself pauses at the new checkpoint — the feature ships through its own gate
- [ ] `./scripts/validate.sh` + `./scripts/test.sh` green; README regenerated; catalog entries valid; portability audit green (FINDINGS=0)

## Not in scope

- A generated readable view for the test-spec registry — deferred TODOS row; the old `docs/test-pipeline.md` had one, v1 of the new format ships without it
- Concern-taxonomy orientation (old TODOS row 12) — struck as obsolete; re-evaluated against the new format later
- The portability gate false-halt row — stays open, not bundled into this PR
- Upstream gstack modification — none; squash-merge repo, POSIX + LF shell conventions unchanged
- Multi-story decomposition — single-story scope (`/CJ_goal_feature` v1)
- Reducing determinism — the old Check-24 deterministic coverage cross-check is ported in full (D6), not dropped or thinned

## Pointers

- Parent tracker: [F000060_TRACKER.md](F000060_TRACKER.md)
- Roadmap: [F000060_ROADMAP.md](F000060_ROADMAP.md)
- Child story: [S000102_audit_skills_specs_and_qa_checkpoint/S000102_TRACKER.md](S000102_audit_skills_specs_and_qa_checkpoint/S000102_TRACKER.md)
- Source design doc (APPROVED, /office-hours): `~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-claude-unruffled-kalam-e25974-design-20260612-140815.md`
- Superseded design (operator redo, same day): `~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-claude-unruffled-kalam-e25974-design-20260612-124229.md`
- Donor machinery being retired: `work-items/features/ops/F000059_test_pipeline_generated_view/`
- Doc-contract lineage: `work-items/features/ops/F000050_doc_spec_driven_dev/`, `F000056_cleaner_doc_contract_generated_views/`, `F000057_relocate_spec_registry_family_into_spec_folder/`, `F000058_general_docs_required/`
