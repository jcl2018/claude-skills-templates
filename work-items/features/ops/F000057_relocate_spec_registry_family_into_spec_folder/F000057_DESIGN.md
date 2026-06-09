---
type: design
parent: F000057
title: "Relocate the spec-registry family (doc-spec/gate-spec/permission-policy) into a spec/ folder — Feature Design"
version: 1
status: Draft
date: 2026-06-08
author: chjiang
reviewers: []
---

<!-- A feature's cross-story design doc. Captures the PROBLEM, the SHAPE of
     the solution, the BIG DECISIONS with rationale, the RISKS, the
     DEFINITION OF DONE, and out-of-scope boundaries. Story-scope detail
     (SPEC/TEST-SPEC) lives on the nested user-stories — do
     not duplicate it here. -->

## Problem

`doc-spec.md` and its two identical siblings `gate-spec.md` and `permission-policy.md`
are machine registries — `.md` files carrying one fenced `yaml` block, parsed by a
sibling `.sh` helper — but they sit at the repo root next to human docs, so they *look*
like hand-read documentation. The operator wants an unambiguous, glance-level signal
that these are machine config, not human docs.

This feature is the conclusion of a pressure-test that started at "is `doc-spec.md`
unnecessary?" The verdict chain: keep all guarantees (so `doc-spec.md` stays as the
single source) → the readable views are generated *from* it (can't replace it) → the
remaining itch is role clarity → a header banner would do it cheaply, but the operator
chose the **structural** fix: move the family into a dedicated `spec/` folder.

## Shape of the solution

Move the 3 registry files into a new `spec/` folder **in this repo only** (history
preserved via `git mv`), and add a back-compat `spec/<name>.md` → root `<name>.md`
resolution fallback to each of the 3 helpers. This repo resolves `spec/`; the one
external consumer (the knowledge-base repo, which has a root `doc-spec.md`) keeps
working unchanged via the fallback; a fresh adopter can drop the file at either
location. The portable seed + self-bootstrap stay root-style, so the consumer
convention and seed byte-identity (test #13) are untouched. The work decomposes into a
single atomic user-story carrying all 8 implementation deltas plus the reviewer
must-fixes A–G.

| Concern | User-story | Artifact |
|---------|-----------|----------|
| Move the 3 files + back-compat helper fallback + validate/test teach + view regen + full prose sweep (all 8 deltas + must-fixes A–G in one lockstep commit) | S000099 | [S000099_relocate_and_helper_fallback/S000099_TRACKER.md](S000099_relocate_and_helper_fallback/S000099_TRACKER.md) |

## Big decisions

<!-- Choices that shape the feature, with rationale. -->

| # | Decision | Why |
|---|----------|-----|
| 1 | Workbench-internal move (Approach A), not ecosystem-wide convention change (Approach B) | B forces a knowledge-base migration + a seed change (test #13 churn) + a new-adopter convention break, for no extra benefit to THIS repo. The folder is what the operator wanted; the ecosystem stays untouched. B remains a possible later follow-up. |
| 2 | Move the family of 3, not single out `doc-spec.md` | All three are the same pattern (root `.md` + one `yaml` block + `scripts/<name>.sh`). Moving only one makes it an odd-one-out; moving the family is the consistent fix. |
| 3 | Structural folder, not a header banner (Approach C rejected) | The operator wants the glance-level signal to be the layout itself ("these are machine files, not docs"), not a comment inside the file. |
| 4 | Keep the portable seed + self-bootstrap root-style | `doc-spec.sh --seed` still emits a root `doc-spec.md`; `/CJ_document-release` still self-bootstraps to root. This keeps test #13 (seed byte-identity) green and means no consumer-convention change and no knowledge-base migration. |
| 5 | Env override is OUTERMOST in each helper's resolution: `X="${ENV:-<spec-if-exists-else-root>}"` | `test.sh:113` runs `PERMISSION_POLICY_PATH=/nonexistent … --validate` and asserts FAILURE. If the fallback ignored the override, that regression would wrongly pass. Add a `DOC_SPEC_PATH` override to `doc-spec.sh` for parity. |
| 6 | All path-gating consumers (validate.sh Checks 16/19/20/21/22, test.sh S94/S96, the CJ_document-release self-bootstrap guard + Step 6.7.1 parser) probe `spec/`-then-root | The helper fallback does NOT save callers that gate on a literal root `[ -f ]` BEFORE invoking the helper. Left unfixed, those would silently SKIP (validate.sh PASS with checks disabled) or RE-create a duplicate root `doc-spec.md`. |

## Risks & open questions

<!-- What could go wrong, and what's still undecided. -->

| Risk / Question | Next check |
|-----------------|-----------|
| A missed reference among 30+ files (the main risk) | Three nets: (a) the back-compat fallback means a missed *path-resolution* ref still resolves via root rather than breaking; (b) validate.sh + test.sh + Windows CI fail loudly on broken parsing/paths; (c) an adversarial completeness review of the diff before ship. |
| Silent-SKIP class — validate.sh would PASS with checks disabled if a literal-root `[ -f ]` guard isn't taught the new path | Post-build assertion: `./scripts/validate.sh` MUST print `PASS:` (not `SKIP:`) for Checks 16/19/20/21/22. A SKIP is a regression — TEST-SPEC row asserts this. |
| Seed / test #13 churn | Untouched by construction (seed stays root-style) → green. TEST-SPEC row asserts byte-identity. |
| knowledge-base consumer breakage | Untouched (resolves root `doc-spec.md` via fallback). A simulated root-only temp repo proves it; a separate optional follow-up could move the consumer to `spec/` later. |
| Env-override symmetry — `doc-spec.sh` has no `DOC_SPEC_PATH` override today | Adding one for parity with the other two helpers is cheap and harmless. Recommended (resolved: add it, outermost). |
| A `spec/` README | Skipped by default (minimal — the files self-document). Reopen only if the folder needs a guide. |

## Definition of done

- [ ] `spec/{doc-spec,gate-spec,permission-policy}.md` exist (history preserved); root has none of the three.
- [ ] All 3 helpers' `--validate` green from the repo; resolution is `spec/` first, root second, env override outermost.
- [ ] `validate.sh` PASS 0/0 — Checks 16/19/20/21/22 print `PASS:` not `SKIP:`; Check 17 correct; new `spec/*.md` orphan scan green; Check 23 in sync.
- [ ] `test.sh` PASS incl. S94 + S96; seed test #13 green (byte-identity).
- [ ] `PERMISSION_POLICY_PATH=/nonexistent … --validate` still FAILS (env outermost).
- [ ] Generated views regenerated + reference `spec/doc-spec.md`.
- [ ] No stale root-path reference to the 3 files remains anywhere.
- [ ] Root-only fallback proven via temp; portability gate green; PR opens and STOPS.

## Not in scope

- Ecosystem-wide `spec/` convention change (Approach B) — deferred; a possible later follow-up if the operator wants `spec/` to be the portable default.
- Migrating the knowledge-base consumer to `spec/` — out of scope; it keeps resolving root via the fallback.
- Changing the portable seed / `templates/doc-spec-common.md` / the `_emit_seed` heredoc — they stay root-style by construction (keeps test #13 byte-identical).
- A `spec/` README/intro file — skipped (minimal).
- Touching `.github/workflows/`, `work-copilot/` + `EXPECTED_BUNDLE_FILES`, `skills-deploy` — confirmed SAFE (0 refs) by the reviews.

## Pointers

- Parent tracker: [F000057_TRACKER.md](F000057_TRACKER.md)
- Roadmap: [F000057_ROADMAP.md](F000057_ROADMAP.md)
- Source design: `~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-claude-sleepy-cerf-e8f24b-design-20260608-spec-folder.md`
