---
type: roadmap
parent: F000038
title: "Root-doc placement convention + validate.sh Check 17 — Roadmap"
date: 2026-06-02
author: chjiang
status: Draft
---

<!-- A feature's roll-up roadmap — merges what was previously in feature-summary
     + milestones. Captures scope/non-goals (the feature's identity), decomposition
     (which user-stories carry the work), and delivery timeline (when each piece
     ships). -->

## Scope

Codify and enforce the workbench's root-vs-`doc/` placement boundary with ZERO file moves. Add a `## Doc placement convention (root vs doc/)` section to `CLAUDE.md` containing a prose rule (human-readable *explanation* docs live in `doc/` + the tracked-doc/ manifest from F000034; root-level `*.md` is limited to an allowlist, each entry pinned at root for an external-tool or operational reason; configs stay at root because tooling hardcodes `./` paths; docs under `skills/`/`templates/`/`work-copilot/`/`work-items/`/`tests/` follow their own conventions) plus a `### Tracked root docs allowlist` YAML block with 5 entries (README.md, CLAUDE.md, CHANGELOG.md, CONTRIBUTING.md, TODOS.md — each with a `reason:`). Add a new `scripts/validate.sh` Check 17 (inserted after Check 16) that parses the allowlist via a flag-based awk disarming on ANY heading, enumerates root `*.md` via `find . -maxdepth 1`, ERRORs on orphan (root `*.md` not allowlisted) and missing (allowlist entry → missing file) via the inline `echo "  ERROR:"; ERRORS=$((ERRORS+1))` form, and prints a count-once PASS line. Extend `scripts/test.sh`'s zzz-test-scaffold integration test with the Check 17 orphan assertion (`touch STRAY.md` → ERROR+exit1; `rm` → exit0) — the known recurring blind spot. Bump VERSION (6.0.3 → next free slot) + add a user-forward CHANGELOG entry. Symmetric with F000034's tracked-doc/ manifest — together the two partition the top-level doc surface. Workbench-internal — no SKILL.md/USAGE.md/catalog edits, no upstream skill changes, no /land-and-deploy in this PR.

## Non-Goals

<!-- Explicit non-goals. Things this feature deliberately does NOT do, and why.
     Prevents scope creep during Implement and gives reviewers an unambiguous
     boundary. -->

- File moves of any kind — codify + enforce only; nothing relocates (zero blast radius).
- Config-file placement enforcement (a "tracked root configs" manifest) — deferred to v2. Configs are tooling-pinned (skills-catalog.json ~246 refs, VERSION ~120); the prose documents the rule only.
- Non-`.md` root files (LICENSE, .shellcheckrc, .gitignore) — the convention governs human-readable `*.md` only.
- `doc/` coverage — that is Check 15's job; Check 17 is scoped to root `*.md` (`find . -maxdepth 1`).
- Per-subtree docs (skills/, templates/, work-copilot/, work-items/, tests/) — own conventions, out of scope.
- Retrofitting Check 15's parser to disarm-on-any-heading — Check 17 uses the robust form; Check 15 works as-is.
- `.github/`-style relocation of CONTRIBUTING — keeping it at root preserves GitHub's auto-surfaced link.
- SKILL.md / USAGE.md / skills-catalog.json / manifest-JSON edits — none touched; no doc-drift (Check 13/14 untouched), no catalog churn.
- Upstream `/document-release` modification — not ours to edit (memory `feedback_workbench_scope`).
- `/land-and-deploy` step in this PR — /CJ_goal_feature stops at PR by design.
- work-copilot/ analog convention — workbench-only scope.

## Success Criteria

<!-- Bulleted, measurable outcomes. Each criterion should be observable from
     the outside (a user, an SLO, a stakeholder report) — not internal code
     state. -->

- [ ] `CLAUDE.md` has a new `## Doc placement convention (root vs doc/)` section with the prose rule + a `### Tracked root docs allowlist` block containing all 5 entries (path + reason): README.md, CLAUDE.md, CHANGELOG.md, CONTRIBUTING.md, TODOS.md.
- [ ] The CLAUDE.md prose just above the YAML block (NOT inside the fence) states the two load-bearing constraints: (1) no `#`-leading comment lines inside the block; (2) the `### Tracked root docs allowlist` heading text is matched literally.
- [ ] `scripts/validate.sh` Check 17 present (after Check 16): flag-based-awk allowlist parser disarming on any heading; `find . -maxdepth 1 -type f -name '*.md'` enumeration; orphan + missing ERROR branches via inline `echo "  ERROR:"; ERRORS=$((ERRORS+1))`; count-once PASS line `PASS: root *.md allowlist parsed (N entries)`.
- [ ] On the clean PR HEAD, `./scripts/validate.sh` exits 0 (Check 17 PASS, 0 errors, 0 warnings).
- [ ] Synthesized violation: `touch STRAY.md` at repo root → `./scripts/validate.sh` exits non-zero with `  ERROR: root doc STRAY.md is not in the CLAUDE.md ...`. `rm STRAY.md` → exits 0.
- [ ] `scripts/test.sh` `zzz-test-scaffold` integration extended with the Check 17 orphan assertion (touch STRAY.md → assert ERROR + exit1 with the literal prefix `  ERROR: root doc STRAY.md is not in the CLAUDE.md`; rm STRAY.md → assert exit0).
- [ ] `./scripts/test.sh` exits 0 on PR HEAD (superset suite, including the extended integration test).
- [ ] No `SKILL.md` / `USAGE.md` / `skills-catalog.json` / manifest-JSON modified.
- [ ] README.md, CLAUDE.md, and all 4 root config files remain at root, byte-for-byte unchanged.
- [ ] `CHANGELOG.md` has a new `### Added` entry in user-forward voice naming F000038 + the convention + Check 17 + F000034 symmetry. `VERSION` bumped to the next free slot (6.0.3 → likely 6.0.4); `./scripts/check-version-queue.sh` confirms the slot is free before /ship.
- [ ] PR opened against main via `/ship` (pre-landing review included). PR body notes F000034 lineage (symmetric root-side counterpart) + F000037 (the root-JSON event that made root consolidation a live question). /CJ_goal_feature stops at PR per design.

## Decomposition

<!-- The user-stories that decompose this feature, with current status. -->

| User-Story | Title | Status |
|-----------|-------|--------|
| [S000071](S000071_root_doc_placement_convention_impl/S000071_TRACKER.md) | Root-doc placement convention + validate.sh Check 17 — implementation (CLAUDE.md convention section + allowlist manifest + Check 17 + test.sh zzz-test-scaffold assertion + VERSION + CHANGELOG) | Open |

## Delivery Timeline

<!-- Forward-looking milestones for this feature. Owner = primary person responsible.
     Status: Done, In Progress, Not Started, At Risk, Deferred.
     Blocked By = milestone number(s) that must complete first, or "—" if none. -->

| # | Milestone | Target Date | Status | Owner | Notes | Blocked By |
|---|-----------|-------------|--------|-------|-------|------------|
| 1 | Ship S000071 (CLAUDE.md convention + allowlist + Check 17 + test.sh assertion + VERSION + CHANGELOG) | 2026-06-02 | Not Started | chjiang | One atomic PR via /ship against main; /CJ_goal_feature stops at PR | — |
| 2 | End-to-end pipeline run — validate.sh PASS (Check 17), test.sh PASS, synthesized-violation smoke (touch STRAY.md → ERROR+exit1; rm → exit0) walked before ship | 2026-06-02 | Not Started | chjiang | Verifies the check fires on a real orphan and clears on removal | #1 |
| 3 | After merge: live dogfood — drop a stray `FOO.md` at root on a feature branch, confirm pre-commit hook's validate.sh blocks the commit with the Check 17 orphan ERROR | 2026-06+ | Not Started | chjiang | Confirms the enforcement bites in the real pre-commit path, not just `./scripts/validate.sh` | #1 |

### Delivery History

<!-- Backward-looking record: PR links, merge dates, version bumps after ship.
     Append-only. -->

- 2026-06-02: Created — F000038 scaffolded from /office-hours design doc (`chjiang-cj-feat-20260602-152028-3848-root-doc-convention-design-20260602-154648.md`).

## Dependency Graph

<!-- Visual representation of milestone ordering. Format: #N description --> #M
     description (arrow = "blocks"). Keep in sync with the Blocked By column. -->

```
(branches from origin/main HEAD post-F000037 merged at PR #194, v6.0.3, commit 10644ac)
                                  |
                                  v
#1 Ship S000071 (CLAUDE.md convention + ### Tracked root docs allowlist + validate.sh Check 17
   + scripts/test.sh zzz-test-scaffold orphan assertion + VERSION + CHANGELOG)
                                  |
                                  v
#2 End-to-end pipeline run: validate.sh PASS (Check 17), test.sh PASS,
   synthesized-violation smoke (touch STRAY.md → ERROR+exit1; rm → exit0)
                                  |
                                  v
                            (PR review = architecture gate; human merge)
                                  |
                                  v
#3 Live dogfood (post-merge): drop a stray FOO.md at root on a feature branch;
   confirm pre-commit hook validate.sh blocks the commit with the Check 17 orphan ERROR
```

## Open Questions

<!-- Questions still being decided. -->

| Question | Next check |
|----------|-----------|
| Config-placement enforcement (a sibling "tracked root configs" manifest)? | Deferred to v2. Configs are tooling-pinned + stable; documenting the rule (prose) is enough now. Revisit if a stray root config lands without notice. |
| Non-`.md` root files (LICENSE, .shellcheckrc, .gitignore) governance? | Out of scope — convention governs human-readable `*.md` only. Revisit only if a stray non-md root file becomes a recurring problem. |
| Retrofit Check 15's parser to disarm-on-any-heading for consistency with Check 17? | Out of scope; Check 15 works as-is given its position. Revisit if Check 15 ever over-captures after a CLAUDE.md section reorder. |
| `.github/`-style relocation of CONTRIBUTING? | Not pursued — keeping it at root preserves GitHub's auto-surfaced "Contributing guidelines" link. Revisit only if GitHub changes its surfacing rules. |
