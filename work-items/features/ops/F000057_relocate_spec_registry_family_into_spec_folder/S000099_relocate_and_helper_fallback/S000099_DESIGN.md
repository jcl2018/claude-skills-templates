---
type: design
parent: S000099
title: "Relocate the spec-registry family to spec/ with a back-compat helper fallback — Design"
version: 1
status: Draft
date: 2026-06-08
author: chjiang
reviewers: []
---

<!-- Atomic-story design. Story-scope detail (requirements, AC, architecture)
     lives in SPEC.md + TEST-SPEC.md; this captures the story-local shape and
     decisions. For full cross-story context see the parent F000057_DESIGN.md. -->

## Problem

The 3 spec-registry files (`doc-spec.md`, `gate-spec.md`, `permission-policy.md`) sit at
the repo root next to human docs and look like hand-read documentation when they are
actually machine config (one fenced `yaml` block parsed by a sibling `.sh` helper). This
story carries the whole relocation into a `spec/` folder plus the back-compat fallback
that keeps the one external consumer working. See parent
[F000057_DESIGN.md](../F000057_DESIGN.md) for the full pressure-test history and the
Approach A vs B/C decision.

## Shape of the solution

8 deltas, landing in ONE lockstep commit:

1. `git mv` the 3 files into `spec/` (preserve history).
2. Back-compat resolution in each helper (`spec/` first, root second, env override OUTERMOST).
3. Update the 3 `section: custom` registry self-declarations to `path: spec/<name>.md`.
4. Teach `validate.sh` (Check 17 root allowlist, Check 15a + new `spec/*.md` orphan scan, Checks 21/22 via fallback, Check 23 regen) + mirror into `test.sh`.
5. `--expand-whitelist` literal `doc-spec.md` → `spec/doc-spec.md`.
6. Regenerate views + fix the generated-from header in `generate-doc-views.sh`.
7. Sweep all prose/path references (~30/18/15 files).
8. (Skipped) a `spec/` README.

Plus reviewer must-fixes A–G (the silent-SKIP class in `validate.sh`, the hard-FAIL class
in `test.sh`, the CJ_document-release self-bootstrap duplicate-file bug, env-override
nesting, lockstep + the zzz fixture, the prose sweep, the confirmed-SAFE set). The SPEC's
Requirements + Acceptance Criteria enumerate these precisely; the TEST-SPEC's rows assert
each verifiable outcome.

## Big decisions

| # | Decision | Why |
|---|----------|-----|
| 1 | All path-gating consumers probe `spec/`-then-root, not just the helpers | The helper fallback does NOT save callers that gate on a literal root `[ -f ]` BEFORE invoking the helper — they would silently SKIP or re-create a duplicate root file. |
| 2 | Env override is OUTERMOST: `X="${ENV:-<spec-if-exists-else-root>}"` | `test.sh:113` asserts `PERMISSION_POLICY_PATH=/nonexistent --validate` FAILS; the override must win over the fallback. |
| 3 | One lockstep commit | `git mv` + the 3 registry self-paths + helper fallbacks + the new orphan scan + its test.sh mirror must land together, else validate transiently ERRORs 3 orphan/missing and blocks the pre-commit hook. |
| 4 | WRITE target for a genuinely-missing-everywhere `doc-spec.md` stays root-style | Keeps the consumer convention + seed byte-identity (test #13). Only the READ/guard probes spec/-then-root. |

## Risks & open questions

| Risk / Question | Next check |
|-----------------|-----------|
| A missed path reference among 30+ files | Adversarial completeness review of the diff before ship (find every stale `doc-spec.md`/`gate-spec.md`/`permission-policy.md` PATH); the fallback resolves missed *resolution* refs via root rather than breaking. |
| A silent-SKIP regression (validate PASS with a check disabled) | TEST-SPEC row S2 asserts Checks 16/19/20/21/22 print `PASS:` not `SKIP:`. |
| The test.sh zzz orphan-scan mirror forgotten (standing implement blind spot) | Pre-flight in the implement prompt; TEST-SPEC + AC call it out explicitly. |

## Definition of done

- [ ] The 3 files at `spec/`; root has none; all 3 `--validate` green.
- [ ] validate.sh PASS 0/0, Checks 16/19/20/21/22 print `PASS:`; new orphan scan green; Check 23 in sync.
- [ ] test.sh PASS incl. S94/S96; seed #13 green; env-override FAILS as asserted.
- [ ] Views regenerated + reference `spec/doc-spec.md`; no stale root-path ref anywhere; root-only fallback proven via temp.

## Not in scope

- Approach B (ecosystem-wide convention change) — deferred.
- knowledge-base consumer migration — keeps resolving root via fallback.
- Seed / `_emit_seed` / `templates/doc-spec-common.md` changes — root-style by construction.
- A `spec/` README.

## Pointers

- Parent feature design: [../F000057_DESIGN.md](../F000057_DESIGN.md)
- Parent tracker: [../F000057_TRACKER.md](../F000057_TRACKER.md)
- This story's spec: [S000099_SPEC.md](S000099_SPEC.md)
- This story's test spec: [S000099_TEST-SPEC.md](S000099_TEST-SPEC.md)
- Source design: `~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-claude-sleepy-cerf-e8f24b-design-20260608-spec-folder.md`
