---
type: design
parent: F000065
title: "Self-healing contract-file reconcile for the audit skills — Feature Design"
version: 1
status: Draft
date: 2026-06-13
author: chjiang
reviewers: []
---

<!-- A feature's cross-story design doc. Captures the PROBLEM, the SHAPE of
     the solution, the BIG DECISIONS with rationale, the RISKS, the
     DEFINITION OF DONE, and out-of-scope boundaries. Story-scope detail
     (SPEC/TEST-SPEC) lives on the nested user-stories — do
     not duplicate it here. Source: /office-hours design doc
     chjiang-cj-feat-audit-self-heal-design-20260613-011741.md. -->

## Problem

The two audit skills (`/CJ_doc_audit`, `/CJ_test_audit`) already own the canonical
contract-file format (their `--seed` template: a 3-column Markdown table) and
position (`spec/`, with root accepted as a fallback), and already **seed a
missing** contract file. But they do nothing useful for a contract file that
**exists in a non-canonical shape**: a `doc-spec.md` still on the old YAML-registry
generation (pre-F000063) is rejected by the current engine with
`[doc-sync-no-config] … has no registry table` and a dead stop — no reconcile, no
refresh, no actionable next step. Run the audit in a legacy or
differently-generationed repo and you get a confusing failure instead of a
self-heal.

This is the real defect behind the earlier "missing docs" misdiagnosis; D000034/PR
#268 added a remediation pointer for the *genuinely-missing* case, which is
orthogonal. The user's ask: the audit skills should own the canonical template
(which files are **required vs optional**, where they live, their format) and, when
run in ANY repo, **detect legacy / duplicated / same-filename-but-different-format**
contract files, **refresh them to the canonical format, and at least prompt** to
confirm — so a future audit in a new or legacy repo "just handles it," no manual
migration.

## Shape of the solution

One feature, one atomic child story (Approach A). The audits classify each
contract file (canonical / legacy / duplicate / wrong-position / absent). Absent →
seed (today's behavior). Non-canonical → emit a `RECONCILE:` report directive
naming the issue + remedy; an opt-in `--reconcile` flag migrates legacy → canonical
**preserving declared rows**, dedups, and reports. Read-mostly by default; works
standalone AND inline-in-QA; writes only with the flag.

Two symmetric engines, two symmetric skills:

- **Engine** — `scripts/doc-spec.sh` and `scripts/test-spec.sh` each gain a
  read-only `--classify` (emits `GENERATION=`/`POSITIONS=`/`DUPLICATE=`/`CANONICAL_PATH=`)
  and an opt-in `--reconcile` (the ONLY new write path: legacy→canonical
  migrate, atomic temp→`--validate`-clean→`mv`, `.bak` kept, migration report;
  idempotent no-op on a canonical file).
- **Skills** — `skills/CJ_doc_audit/SKILL.md` and `skills/CJ_test_audit/SKILL.md`
  generalize their "seed if missing" step into a reconcile step driven by
  `--classify`, add an opt-in `--reconcile` flag that forwards to the engine
  (standalone only — the in-QA path never passes it), and keep the `RECONCILE:`
  directive advisory (it does NOT crash the audit or flip QA red).

| Concern | User-story | Artifact |
|---------|-----------|----------|
| Reconcile engines (`--classify` + `--reconcile` for both `doc-spec.sh`/`test-spec.sh`) + audit-skill wiring (Step-2 directive + opt-in flag) + canonical-template docs + tests | S000109 | [S000109_reconcile_engine_and_audit_wiring/S000109_TRACKER.md](S000109_reconcile_engine_and_audit_wiring/S000109_TRACKER.md) |

## Big decisions

<!-- Choices that shape the feature, with rationale. -->

| # | Decision | Why |
|---|----------|-----|
| 1 | Approach A — reconcile + migrate, flag-gated (CHOSEN) | The only option that preserves the repo's declared rows, works identically standalone and inline-in-QA, keeps the audit read-mostly (writes only behind `--reconcile`), and is the natural extension of "seed if missing" into "reconcile to canonical." Rejected B (auto re-seed + prompt — destructive: re-seed is the ~10-row template, a 47-doc registry would lose all declarations) and C (interactive AUQ in the audit — only works standalone, changes the read-mostly / no-AUQ design). |
| 2 | "Prompt to update" = report directive + opt-in `--reconcile` flag, NOT an interactive AUQ (D1) | The audit has no `AskUserQuestion` tool and runs inline inside QA (`/CJ_qa-work-item` Step 8.6c) as a subagent that cannot prompt. The directive is advisory (like D000034's `REMEDIATION:`) — surfaces in the per-stage report + QA digest, never crashes the audit or flips QA red; the cj_goal post-QA checkpoint owns Continue/Halt/act. |
| 3 | Duplicate handling is report-only in v1; no auto-delete (D2) | `--reconcile` reconciles the canonical-position copy and reports the redundant one (`RECONCILE-WARN: duplicate contract at <root path>; remove after verifying`). Auto-delete is unsafe by default; a future `--reconcile --prune-duplicates` is deferred. Root-only stays advisory `wrong-position` (root IS an accepted position) — relocation is opt-in future work. |
| 4 | `legacy` is distinguished from `genuinely malformed` | Only a file matching an old-generation signature (doc-spec: a fenced ```yaml block with `schema_version:` + `docs:`) is reconcilable; a malformed canonical file still halts `[doc-sync-no-config]`. This stops `--reconcile` from clobbering a hand-broken canonical file. |
| 5 | Migration parser stays awk/sed, POSIX-shell / bash-3.2, no python/yaml dep (D3) | Matches the existing `doc-spec.sh` / `test-spec.sh` idiom. The old-generation YAML grammar is recoverable from git history (root `doc-spec.md` @ pre-F000057, e.g. `716a537`) — the converter's input grammar. No new runtime dependency. |

## Risks & open questions

<!-- What could go wrong, and what's still undecided. -->

| Risk / Question | Next check |
|-----------------|-----------|
| A malformed canonical file mis-classified as `legacy` would get clobbered by `--reconcile` | `--classify` only labels `legacy` when an old-generation *signature* matches (fenced ```yaml + `schema_version:` + `docs:`); a no-table file lacking the signature stays the `[doc-sync-no-config]` halt, not `legacy`. |
| The migrate must preserve EVERY declared row (a 47-doc registry that silently drops rows is worse than a dead stop) | `--reconcile` writes atomically (temp → `--validate`-clean → `mv`), keeps a `.bak`, and the success criteria require a 40+-row fixture round-trips with every row preserved. |
| `audit_class` asymmetry on migration — a legacy `operational` row whose path derives `human-doc` could later trip Check 19 (no work-item IDs in human-docs) | The migrate fires `RECONCILE-WARN: <path-row> audit_class was 'operational' but path derives 'human-doc' — verify no work-item IDs` so the operator verifies before the next hard Check-19 run. |
| A new write path in a read-mostly skill could fire on a plain audit run | The `--reconcile` write is opt-in only; a plain (no-flag) run only ever emits the advisory `RECONCILE:` directive, never writes. The in-QA path never passes the flag. |
| Could regress `validate.sh` if the workbench's own (already-canonical) contract emitted reconcile noise | Success criteria require the live workbench classify `canonical` with zero reconcile lines and `validate.sh` stay 0/0. |
| The implement-subagent blind spot: each new engine behavior needs a parallel `scripts/test.sh` integration fixture | Call it out explicitly in the implement prompt; register the new `tests/*.test.sh` in BOTH `scripts/test.sh` and `spec/test-spec-custom.md` (the unregistered-test gate). |
| OQ1 — auto-delete duplicates? | v1 reports + reconciles the canonical copy but does NOT delete the redundant file (safe default). A future `--reconcile --prune-duplicates` deferred. |
| OQ2 — root→spec relocation? | Root is an accepted position, so v1 treats root-only as advisory `wrong-position` (reported, not moved). Relocation is opt-in future work. |
| OQ3 — test-spec legacy signature | doc-spec's old YAML generation is well characterized (git history). The exact old test-spec on-disk signature must be confirmed from git history during implementation; if test-spec never had a divergent legacy on-disk format, its `--classify` reduces to canonical/absent + duplicate and `--reconcile` is a dedup/no-op (still symmetric, less converter work). |

## Definition of done

<!-- Objective, measurable criteria for "shipped." -->

- [ ] `doc-spec.sh --classify` correctly labels `absent` / `canonical` / `legacy` / `duplicate` fixtures; `test-spec.sh --classify` likewise.
- [ ] `doc-spec.sh --reconcile` migrates a legacy YAML fixture (multi-row, incl. a 40+-row fixture) to canonical Markdown **with every declared row preserved**, `--validate`-clean, `.bak` written, idempotent on re-run.
- [ ] The `audit_class` asymmetry guard fires `RECONCILE-WARN` for a `docs/*` row that was `operational`.
- [ ] `/CJ_doc_audit` on a legacy fixture surfaces a `RECONCILE:` directive in the Stage-1 report; `/CJ_doc_audit --reconcile` performs the migration; a canonical repo emits zero reconcile lines. Symmetric coverage for `/CJ_test_audit`.
- [ ] The canonical contract-file template (required/optional/position/format) is documented in each audit's USAGE.md + the spec prose.
- [ ] `scripts/validate.sh` stays green (0/0); the live workbench classifies `canonical` with no reconcile noise. New `tests/*.test.sh` registered in `scripts/test.sh` AND `spec/test-spec-custom.md`.

## Not in scope

<!-- Explicit non-goals. -->

- Auto-deleting duplicate contract files — v1 reports + reconciles the canonical copy only; a `--reconcile --prune-duplicates` is deferred (OQ1).
- Relocating a root-only contract file into `spec/` — root is an accepted position; root-only is advisory `wrong-position`, not moved (OQ2).
- Redefining the canonical format or position — the audits already define it (Premise 1); this feature reconciles *existing files to it*.
- Auto-creating the docs/units a contract *declares* — those are already reported by Stage 1 (declared-exists), not created here.
- Any external/runtime dependency change — the migration parser stays the POSIX-shell awk/sed idiom, no python/yaml dep.

## Pointers

<!-- Cross-links to related artifacts. -->

- Parent tracker: [F000065_TRACKER.md](F000065_TRACKER.md)
- Roadmap: [F000065_ROADMAP.md](F000065_ROADMAP.md)
- Child story: [S000109_reconcile_engine_and_audit_wiring/S000109_TRACKER.md](S000109_reconcile_engine_and_audit_wiring/S000109_TRACKER.md)
- Source design doc: `~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-cj-feat-audit-self-heal-design-20260613-011741.md`
- Related: D000034/PR #268 (remediation pointer for the genuinely-missing case — orthogonal), F000063 (table-as-source doc-spec + gate-spec merge — the canonical format this reconciles TO), F000060/F000061 (two-tier audit contract + three-stage audit hardening), F000057 (relocate spec registry into `spec/`).
