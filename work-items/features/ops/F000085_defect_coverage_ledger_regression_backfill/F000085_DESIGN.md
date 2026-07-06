---
type: design
parent: F000085
title: "Defect-coverage ledger + regression-category materialization — Feature Design"
version: 1
status: Draft
date: 2026-07-06
author: chang
reviewers: []
---

<!-- A feature's cross-story design doc. Captures the PROBLEM, the SHAPE of
     the solution, the BIG DECISIONS with rationale, the RISKS, the
     DEFINITION OF DONE, and out-of-scope boundaries. Story-scope detail
     (SPEC/TEST-SPEC) lives on the nested user-stories — do
     not duplicate it here. Source: the APPROVED /office-hours design at
     ~/.gstack/projects/jcl2018-claude-skills-templates/chang-claude-affectionate-villani-b5b6f4-design-20260706-014929.md -->

## Problem

The two-axis test contract (F000074/F000078) promises "defects earn regression
tests," but the promise is unenforced and undeclared for the backlog: 38 defect
work-item dirs exist under `work-items/defects/**` while the `categories:` axis
in `spec/test-spec-custom.md` carries ZERO `regression` rows. Proof that a past
defect stays fixed is scattered — ~14 dedicated `tests/*.test.sh` files, ~11
inline guard blocks in `scripts/test.sh` (the `Regression test (D0000NN):`
battery), ~5 process/doc-only defects with nothing to automate, and a few with
no proof at all — and nothing links a defect to its proof.

The cost was demonstrated live in the design session: an inventory agent
mapping defects→proofs confidently cited two test files that do not exist.
Without a declared ledger, proof is indistinguishable from folklore. The
maintainer (and the `/CJ_test_audit` + `/CJ_test_run` verbs acting on their
behalf) cannot answer "is defect X still protected, and by what?" without
archaeology.

## Shape of the solution

Single-PR Full (Approach B), built ledger-first: the ledger (a new
`defect_coverage:` overlay axis + a deterministic engine check wired as HARD
`validate.sh` Check 32 + a verified 38-dir backfill) PLUS the scoped physical
migration of pure defect drills into `tests/regression/<layer>/`, in one
reviewable PR whose commits are ordered LEDGER-FIRST so a migration red at QA
descopes to ledger-only without losing the ledger.

Stage 1 (commits 1–3): grammar + parser (`defect_coverage:` rows keyed on full
dir path relative to `work-items/defects/`, disposition closed-enum
`{covered-by, covered-by-anchor, waived}`, `--list-defect-coverage`); the
`--check-defect-coverage` engine check (forward: every `D??????_*` dir has
exactly one row; reverse: every row resolves — dir exists, proof live, mode
gate); gate wiring (Check 32 + `validate-check-32` units row + hermetic
negative test with two plants) + the full verified backfill + `/CJ_test_audit`
Stage-1 wiring + TODOS rows.

Stage 2 (commits 4–6): reverse-sweep token grammar (full relative-path tokens
at both sweep sites, recursed glob, doc-sync orphan wired + owned); `git mv`
the 4 pure drills → `tests/regression/CI-push/` with same-commit
invocation-line + anchor updates; regression `categories:` rows + front-door
docs + doc-spec declarations + stale-prose fix + catalog regen.

| Concern | User-story | Artifact |
|---------|-----------|----------|
| Ledger (axis + gate + backfill) + migration (sweep grammar + moves + rows/docs), single PR, ledger-first commits | S000134 | [S000134_defect_ledger_gate_backfill_migration/S000134_TRACKER.md](S000134_defect_ledger_gate_backfill_migration/S000134_TRACKER.md) |

## Big decisions

| # | Decision | Why |
|---|----------|-----|
| 1 | Linkage home is a NEW overlay axis `defect_coverage:` in `spec/test-spec-custom.md`, mirroring the `behavior_coverage:` row shape; the general seed is untouched | Check 19 bans work-item IDs in per-test docs (human-docs), so the defect↔test linkage cannot live in docs; the overlay is operational tier (D-IDs allowed); avoids the dual-write footgun entirely |
| 2 | Ledger keys on FULL dir paths relative to `work-items/defects/`, never bare D-IDs | D000021 is a genuinely duplicated bare ID across two component dirs — bare IDs are ambiguous |
| 3 | Three closed dispositions: `covered-by` (dedicated runnable-by-name regression row, must be `mode: deterministic`), `covered-by-anchor` (proof inside a shared file, anchor must grep live), `waived` (reason; gaps as `waived: "gap — …"` + a TODOS row) | The inline `scripts/test.sh` D-block battery is collectively owned by ONE coarse units row — per-defect `categories:` rows would mint junk; anchors reuse the forward-grep idiom the `units:`/`behavior_coverage:` axes already use; gap waivers keep gaps enumerable without blocking the ledger |
| 4 | Deterministic-only (engine-enforced): every backfilled regression row is `mode: deterministic` + `tier: free`; a `covered-by` citing a `mode: agentic` row is a FINDING | Operator directive — the planned agentic-test purge must not be able to orphan defect coverage; the contract-wide `mode: agentic ⇒ tier ≠ free` rule + the mode gate pin the tier without a separate engine check |
| 5 | Single-PR Full over two PRs, with LEDGER-FIRST commit ordering | Operator chose the complete end state; commit ordering preserves the descope-on-red property the two-PR packaging would have given |
| 6 | Reverse-sweep change is a TOKEN GRAMMAR change, not glob surgery: full relative-path tokens at both sweep sites, recursed glob, `$5 == "scripts/test.sh"` source pin preserved; each moved file's units row updates `anchor:` while `source:` stays `scripts/test.sh` | Tokens are BASENAMES today and the awk pins the source — naive recursion breaks token matching; a row pointing `source:` at the test file itself would self-satisfy the forward grep (engine comment at `scripts/test-spec.sh:1603-1609`) |
| 7 | Only PURE dedicated defect drills move; shared suites and the inline battery stay put and are referenced in place | Single-owner constraint: shared suites are not moved and not re-owned; rejected Approach C (inline extraction) destabilizes a proven battery |
| 8 | Verify-before-declare: every backfilled mapping is re-verified against the live repo (grep the anchor + run the drill); the in-session inventory is INPUT, not truth; every verification failure defaults to `waived: "gap — …"` + TODOS row | The inventory hallucinated two nonexistent files — no row lands on an unverified claim; in-PR gap drills only when ≤30-line grep/shape-guard, capped at 3 |
| 9 | Intermediate-state rule: the four MIGRATE defects land as `covered-by-anchor` at commit 3, re-anchor in commit 5 (same commit as the `git mv` + invocation-line rewrite), flip to `covered-by` at commit 6 | Every intermediate commit AND the descoped ledger-only end state stay green under Check 32 — descope-on-red made real |
| 10 | Consumer-safety: every new engine check SKIPs vacuously (named SKIP, exit 0) when the registry / axis / `work-items/defects/` is absent | The engines run standalone in ANY repo (`/CJ_test_audit` contract); the Check 28/30/31 precedent |

## Risks & open questions

| Risk / Question | Next check |
|-----------------|-----------|
| Token-grammar change touches Check 24 machinery — a regression there breaks the reverse sweep for every existing row | The existing Check 24 negative tests + full `scripts/test.sh` green before push; migration commits ordered AFTER ledger commits so a red descopes |
| Exact final pure-drill migration list — implement-time verification may demote a candidate that proves shared/feature behavior to stay-put | Re-verify each of the 4 candidates at implement time (read each file's header + owning units row) before `git mv` |
| ~13 provisional-table rows carry VERIFY flags (incl. two the inventory hallucinated proofs for) — dispositions may shift covered→waived | Verify-before-declare during commit 3; default every failure to `waived: "gap — …"` + TODOS row |
| Whether D000018 gets a cheap deterministic shape-guard (grep qa.md for the E2E-subagent directive) or a waiver | Implementer decides by cost at commit 3 (≤30-line cap, no new fixture) |
| Parser block-close regressions: `defect_coverage:` must be added to the eight hardcoded block-close regexes and placed LAST in the overlay yaml | The `categories:`/F000074 precedent + `--validate` duplicate/enum drills in the negative test |
| Future agentic purge collides with Check 30's HARD `local-hook`+`agentic` requirement for the enrolled `portability` topic | Out of scope here; file the TODOS row (un-enroll `portability` from `topic_contracts:` first) before any purge |

## Definition of done

- [ ] `bash scripts/test-spec.sh --check-defect-coverage`: 38/38 dirs dispositioned, 0 findings; named vacuous SKIP in a bare consumer repo
- [ ] `validate.sh` green including new Check 32; the hermetic negative test proves the gate fires (plant → finding → restore → pass; two plants incl. the agentic-citation FINDING)
- [ ] `--list-categories --category regression` returns ≥4 rows, ALL `mode: deterministic` + `tier: free`; `/CJ_test_run --category regression` runs them green with zero model spend
- [ ] Check 24 green after the token-grammar change; the doc-sync orphan is wired (invoked by `scripts/test.sh` + owned by a `units:` row)
- [ ] Structure checks (a–f) green with `tests/regression/CI-push/` + `docs/tests/regression/CI-push/*.md` (three front-door sections, no D-IDs)
- [ ] Full `scripts/test.sh` + shellcheck green locally before push (the CI gate runs all three)
- [ ] Stale ~:1580 migration comment rewritten to the scoped truth; waived-gap + agentic-purge-prep TODOS rows filed

## Not in scope

- Splitting the 11 inline `scripts/test.sh` D-blocks into per-defect files (Approach C) — destabilizes a proven inline battery; explicitly rejected by the cold read
- Moving shared suites (`setup-hooks`, `cj-worktree-cleanup`, `doc-spec-overlay`, `seed-contracts`, `cj-id-claim`, `scripts/test-deploy.sh`) — single-owner constraint; referenced in place via `covered-by-anchor`
- Authoring the remaining waived-gap drills — filed as TODOS rows, shipped in follow-up runs (except the ≤30-line/no-fixture/cap-3 exception)
- The agentic-test purge itself and the `portability` topic un-enrollment it requires — tracked as a TODOS row, must precede the purge
- Any `spec/test-spec.md` general-seed edit (dual-write footgun) or gstack/upstream change
- Separate engine enforcement of `tier:` on regression rows — the contract-wide `mode: agentic ⇒ tier ≠ free` rule plus the mode gate already pin it

## Pointers

- Parent tracker: [F000085_TRACKER.md](F000085_TRACKER.md)
- Roadmap: [F000085_ROADMAP.md](F000085_ROADMAP.md)
- Child story: [S000134_defect_ledger_gate_backfill_migration/S000134_TRACKER.md](S000134_defect_ledger_gate_backfill_migration/S000134_TRACKER.md)
- Source design doc (APPROVED, /office-hours): `~/.gstack/projects/jcl2018-claude-skills-templates/chang-claude-affectionate-villani-b5b6f4-design-20260706-014929.md`
- Lineage: F000074/F000078 (`categories:` axis + structure checks), F000082/F000083 (Check 30/31 gate + negative-test patterns), F000066 (`behavior_coverage:` grammar)
