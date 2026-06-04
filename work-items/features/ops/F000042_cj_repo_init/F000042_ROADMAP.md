---
type: roadmap
parent: F000042
title: "CJ_repo-init — verify/scaffold per-repo prerequisites for the CJ_ skill family — Roadmap"
date: 2026-06-03
author: chjiang
status: Draft
---

<!-- A feature's roll-up roadmap. -->

## Scope

CJ_repo-init delivers a standalone utility (`/CJ_repo-init`) that takes a repo from
"skills installed but not wired up" to "ready to run the CJ_ family." It detects deployed
CJ_ skills, maps each to its per-repo prerequisite (`cj-document-release.json`, `TODOS.md`,
`work-items/` tree), verifies the union, prints a health table, and scaffolds the missing
repo-level prerequisites from generic portable seeds after one confirm. It is the
`doctor` + `init` for the repo side of the workbench, idempotent on re-run.

## Non-Goals

- Installing skills/templates into `~/.claude/` — owned by `setup.sh` / `skills-deploy install`. CJ_repo-init reports install-level gaps but never installs.
- Auditing `~/.claude/` install health — owned by `CJ_system-health` / `skills-deploy doctor`.
- `--add <skill>` targeted per-skill setup — deferred; v1 is whole-repo detect-and-fix.
- A `templates/CJ_repo-init/` deployment surface — seeds are inline heredocs in v1.

## Success Criteria

- [ ] Fresh repo with CJ_ skills deployed → 3-row gap table, then valid `TODOS.md` + `cj-document-release.json` + `work-items/` scaffolded after one confirm; re-run is a clean no-op (exit 0).
- [ ] Scaffolded `cj-document-release.json` passes `validate.sh` Check 16.
- [ ] Invalid/unparseable `cj-document-release.json` is detected (not just missing).
- [ ] `--dry-run` writes nothing.
- [ ] Not-a-git-repo and missing-deployed-manifest paths error / degrade cleanly.
- [ ] `validate.sh` green (catalog, USAGE.md, SKILL-CATALOG section + tag, routing rule).

## Decomposition

| User-Story | Title | Status |
|-----------|-------|--------|
| [S000075](S000075_cj_repo_init_skill/S000075_TRACKER.md) | cj-repo-init detection engine + skill + tests + wiring | Open |

## Delivery Timeline

| # | Milestone | Target Date | Status | Owner | Notes | Blocked By |
|---|-----------|-------------|--------|-------|-------|------------|
| 1 | Ship S000075 (engine + skill + tests + catalog/doc/routing wiring) | — | Not Started | chjiang | Single cohesive user-story carries the whole feature | — |
| 2 | End-to-end pipeline run (fresh repo → detect → confirm → scaffold → no-op re-run) | — | Not Started | chjiang | Validates the success criteria as a user would experience them | #1 |

### Delivery History

<!-- Backward-looking record: PR links, merge dates, version bumps after ship. -->

- 2026-06-03: F000042 scaffolded from /office-hours design doc.

## Dependency Graph

<!-- Visual representation of milestone ordering. -->

```
#1 Ship S000075 (engine + skill + tests + wiring) --> #2 End-to-end pipeline run
```

## Open Questions

<!-- Questions still being decided. -->

| Question | Next check |
|----------|-----------|
| `--fix` pre-creates `work-items/` top-level dirs vs leaving to first scaffold? | Lean create; resolve in S000075 SPEC. |
| Future `--add <skill>` targeted mode | Deferred to post-v1; revisit if demand appears. |
