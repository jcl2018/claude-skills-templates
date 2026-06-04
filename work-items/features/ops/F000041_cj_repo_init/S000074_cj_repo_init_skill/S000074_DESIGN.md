---
type: design
parent: S000074
title: "cj-repo-init detection engine + skill + tests + wiring — Design"
version: 1
status: Draft
date: 2026-06-03
author: chjiang
reviewers: []
---

<!-- User-story design. Brief is fine for an atomic story; sections are not omitted. -->

## Problem

A repo with CJ_ skills installed under `~/.claude/` can still fail at runtime because the
per-repo config files those skills require (`cj-document-release.json`, `TODOS.md`,
`work-items/` tree) are absent. This story builds the engine + skill that detects and
scaffolds those prerequisites. See parent [F000041_DESIGN.md](../F000041_DESIGN.md) for
the full problem framing.

## Shape of the solution

Two artifacts plus wiring: `scripts/cj-repo-init.sh` (pure detect/verify/scaffold engine
with `--dry-run` / `--fix`) and `skills/CJ_repo-init/SKILL.md` (wrapper that runs
detection, prints the health table, and surfaces one confirm AUQ before calling `--fix`).
Tests in `tests/cj-repo-init.test.sh`; catalog/doc/routing entries complete the surface.
The detection-in-script / AUQ-in-prose split mirrors `skills-doc-sync-check`.

## Big decisions

| # | Decision | Why |
|---|----------|-----|
| 1 | Script engine + SKILL.md AUQ wrapper | Unit-testable, idempotent, matches repo convention. See parent DESIGN decision #1. |
| 2 | Inline heredoc seeds (no templates dir) | Tiny generic files; avoids skills-catalog `templates` + manifest churn. |
| 3 | Detection reads deployed manifest with fallbacks | `~/.claude/.skills-templates.json` → `ls ~/.claude/skills/CJ_*` → repo-local `skills/` for self-dev. |

## Risks & open questions

| Risk / Question | Next check |
|-----------------|-----------|
| Octal-string pitfalls / portability of bash arithmetic across zsh | Covered by writing the script POSIX-bash-safe; smoke test runs it under the repo's shell. |
| `--fix` pre-creates `work-items/` dirs vs deferring to first scaffold | Lean create (cheap, idempotent); locked in SPEC. |

## Definition of done

- [ ] Engine + skill + tests + catalog/doc/routing wiring shipped; `validate.sh` green. See SPEC acceptance criteria for the full list.

## Not in scope

- Installation into `~/.claude/` and `~/.claude/` health auditing — owned by other tools (see parent DESIGN "Not in scope").
- `--add <skill>` targeted mode — deferred.

## Pointers

<!-- Cross-links to related artifacts. -->

- Parent feature design: [../F000041_DESIGN.md](../F000041_DESIGN.md)
- Parent tracker: [../F000041_TRACKER.md](../F000041_TRACKER.md)
- Spec: [S000074_SPEC.md](S000074_SPEC.md)
- Test spec: [S000074_TEST-SPEC.md](S000074_TEST-SPEC.md)
- Pattern precedent: `scripts/skills-doc-sync-check`
