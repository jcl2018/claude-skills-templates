---
type: design
parent: F000042
title: "CJ_repo-init — verify/scaffold per-repo prerequisites for the CJ_ skill family — Feature Design"
version: 1
status: Draft
date: 2026-06-03
author: chjiang
reviewers: []
---

<!-- A feature's cross-story design doc. Captures the PROBLEM, the SHAPE of
     the solution, the BIG DECISIONS with rationale, the RISKS, the
     DEFINITION OF DONE, and out-of-scope boundaries. -->

## Problem

The CJ_ skill family carries hard **per-repo** prerequisites that nothing currently
verifies or creates. A repo can have every skill installed under `~/.claude/` and still
fail at runtime because a repo-root config or directory is missing:
`/CJ_document-release` HALTs with `[doc-sync-no-config]` if `cj-document-release.json` is
absent — and it runs at Step 5.5 of every cj_goal orchestrator, so a missing config
breaks `/CJ_goal_feature`, `/CJ_goal_defect`, and `/CJ_goal_todo_fix`. `/CJ_suggest`,
`/CJ_goal_todo_fix`, and `/CJ_improve-queue` exit 1 if `TODOS.md` is missing. The
scaffold→implement→qa pipeline expects a `work-items/` tree.

`setup.sh` + `skills-deploy install` cover **installation** (deploying SKILL.md,
manifests, templates to `~/.claude/`); `CJ_system-health` audits `~/.claude/` install
health; `skills-deploy doctor` audits template deployment. None of them validate or
scaffold the per-repo config files a freshly-cloned or brand-new target repo needs. That
gap — the last unautomated seam between "I installed the skills" and "the skills actually
work here" — is what this feature closes.

## Shape of the solution

One standalone utility, `/CJ_repo-init`, that detects which CJ_ skills are deployed, maps
each to its per-repo prerequisite(s), verifies the union of those, prints a health table,
and (on one confirm) scaffolds the missing repo-level prerequisites from generic portable
seeds. Idempotent: re-running on a healthy repo is a no-op that prints the health table.

Architecture follows the documented detection-in-script / AUQ-in-prose split: a testable
bash engine (`scripts/cj-repo-init.sh`) does detect/verify/scaffold (pure, idempotent),
and the SKILL.md prose owns the single confirm AskUserQuestion. The whole feature is one
cohesive change carried by a single user-story.

| Concern | User-story | Artifact |
|---------|-----------|----------|
| Detection engine + skill wrapper + tests + catalog/doc/routing wiring | S000075 | [S000075_cj_repo_init_skill/S000075_TRACKER.md](S000075_cj_repo_init_skill/S000075_TRACKER.md) |

## Big decisions

| # | Decision | Why |
|---|----------|-----|
| 1 | Script-engine + SKILL.md-AUQ wrapper (Approach A) over pure-SKILL.md (Approach B) | Matches the repo's documented detection-in-script / AUQ-in-prose pattern (`skills-doc-sync-check`); unit-testable via `tests/*.test.sh`; idempotent logic lives in one verifiable place; QA-able by `/CJ_qa-work-item`. Pure-SKILL.md is not unit-testable and diverges from the script+test convention every other mechanism in this repo follows. |
| 2 | Name is `CJ_repo-init`, not `cj_goal_init` | `cj_goal_*` is reserved for topic→PR orchestrators; a standalone utility belongs in the `CJ_<thing>` namespace alongside `CJ_suggest` / `CJ_system-health`. Keeps the orchestrator prefix legible. |
| 3 | "Detect-deployed" scope | Read the deployed-skills manifest (`~/.claude/.skills-templates.json`, falling back to `ls ~/.claude/skills/CJ_*` and the repo-local `skills/` for self-dev), map each detected skill to its prereq(s), verify/scaffold only the union. Avoids scaffolding config for skills the repo doesn't use. |
| 4 | Seed content is generic portable defaults, inline in the script (heredocs) for v1 | Must not leak workbench-specific paths so the skill is portable to any adopting repo. The two seed files are tiny + generic, so no `templates/CJ_repo-init/` deployment surface — avoids new skills-catalog `templates` entries + manifest churn. Revisit if seeds grow. |
| 5 | `cj-document-release.json` validity checked beyond existence | Must be parseable JSON with a supported `schema_version` (currently 1), mirroring `validate.sh` Check 16 — a present-but-invalid config still HALTs the consuming skills, so existence alone is insufficient. |

## Risks & open questions

| Risk / Question | Next check |
|-----------------|-----------|
| Should `--fix` pre-create the `work-items/` top-level dirs, or leave them to first scaffold? | Lean: create them (cheap, makes the repo visibly "ready"; first scaffold is a no-op over them). Resolve in SPEC. |
| Future `--add <skill>` mode to set up one specific skill's prereqs on demand | Deferred — v1 is whole-repo detect-and-fix. Revisit post-ship if demand appears. |
| Seed `cj-document-release.json` must pass `validate.sh` Check 16 in any adopting repo, not just the workbench | TEST-SPEC smoke row asserts the generated JSON parses + has a supported schema_version. |

## Definition of done

- [ ] `scripts/cj-repo-init.sh` implements default detect, `--dry-run`, and `--fix`; default + `--dry-run` write nothing; exit 1 when repo-level gaps remain, exit 0 when none.
- [ ] `skills/CJ_repo-init/SKILL.md` runs detection, prints the table, surfaces one confirm AUQ on gaps, and calls `--fix` on confirm; owns the branch-free, in-place, no-worktree/ship behavior.
- [ ] `tests/cj-repo-init.test.sh` covers fresh-repo gap detection, idempotent re-run no-op, invalid-config detection, `--dry-run` writes-nothing, and clean degradation on not-a-git-repo / missing manifest; wired into `scripts/test.sh`.
- [ ] `validate.sh` green end-to-end (catalog entry, USAGE.md 5 sections, SKILL-CATALOG section + tag, routing rule).

## Not in scope

- Installation of skills / templates into `~/.claude/` — owned by `setup.sh` / `skills-deploy install`; CJ_repo-init reports install-level gaps but never installs.
- `~/.claude/` install-health auditing — owned by `CJ_system-health` / `skills-deploy doctor`.
- `--add <skill>` per-skill targeted setup — deferred to a future version; v1 is whole-repo detect-and-fix.
- A `templates/CJ_repo-init/` deployment surface — seeds are inline heredocs in v1.

## Pointers

<!-- Cross-links to related artifacts. -->

- Parent tracker: [F000042_TRACKER.md](F000042_TRACKER.md)
- Roadmap: [F000042_ROADMAP.md](F000042_ROADMAP.md)
- Source design doc: `~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-cj-feat-20260603-174453-41356-design-20260603-175343.md`
- Pattern precedent: `scripts/skills-doc-sync-check` (detection-in-script / AUQ-in-prose split, CLAUDE.md "Novel pattern callout")
- Related config convention: `cj-document-release.json` (F000037) + `validate.sh` Check 16
