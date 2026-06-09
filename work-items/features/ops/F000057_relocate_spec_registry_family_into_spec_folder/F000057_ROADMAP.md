---
type: roadmap
parent: F000057
title: "Relocate the spec-registry family (doc-spec/gate-spec/permission-policy) into a spec/ folder — Roadmap"
date: 2026-06-08
author: chjiang
status: Draft
---

<!-- A feature's roll-up roadmap — captures scope/non-goals (the feature's
     identity), decomposition (which user-stories carry the work), and delivery
     timeline (when each piece ships). -->

## Scope

Relocate the 3 spec-registry files (`doc-spec.md`, `gate-spec.md`,
`permission-policy.md`) into a dedicated `spec/` folder in this workbench repo, with a
back-compat `spec/`→root resolution fallback in each of the 3 parsing helpers so the one
external consumer (knowledge-base, root `doc-spec.md`) and fresh adopters keep working
unchanged. The portable seed + self-bootstrap stay root-style. Delivers the operator's
glance-level "these are machine config, not human docs" structural signal without any
cross-ecosystem migration or consumer risk.

## Non-Goals

- Ecosystem-wide `spec/` convention change (migrate the knowledge-base + change the seed) — deferred; out of scope.
- Changing the portable seed / `templates/doc-spec-common.md` / `_emit_seed` heredoc — they stay root-style (keeps test #13 byte-identical).
- A `spec/` README/intro file — skipped (minimal).

## Success Criteria

- [ ] `spec/{doc-spec,gate-spec,permission-policy}.md` exist (history preserved via `git mv`); root no longer has them.
- [ ] All 3 helpers resolve `spec/` first then root (env override outermost); `doc-spec.sh`/`gate-spec.sh`/`permission-policy.sh --validate` all green from the repo.
- [ ] `validate.sh` PASS 0/0 — Checks 16/19/20/21/22 print `PASS:` not `SKIP:`; Check 17 correct; new `spec/*.md` orphan scan green; Check 23 (views in sync) green.
- [ ] `PERMISSION_POLICY_PATH=/nonexistent … --validate` still FAILS (env-override regression intact).
- [ ] `scripts/test.sh` PASS incl. S94 + S96; seed test #13 green (byte-identity).
- [ ] Generated views regenerated; reference `spec/doc-spec.md`; Check 23 in sync.
- [ ] No stale root-path reference to the 3 files remains anywhere (adversarial sweep clean).
- [ ] A simulated root-only repo still resolves via the fallback; portability gate green; PR opens and STOPS.

## Decomposition

<!-- The user-stories that decompose this feature, with current status. -->

| User-Story | Title | Status |
|-----------|-------|--------|
| [S000099](S000099_relocate_and_helper_fallback/S000099_TRACKER.md) | Relocate the spec-registry family to spec/ with a back-compat helper fallback | Open |

## Delivery Timeline

<!-- Forward-looking milestones for this feature. -->

| # | Milestone | Target Date | Status | Owner | Notes | Blocked By |
|---|-----------|-------------|--------|-------|-------|------------|
| 1 | Ship S000099 (8 deltas + reviewer must-fixes A–G in one lockstep commit) | — | Not Started | chjiang | git mv → helper fallbacks → registry self-paths → validate Check 17/15a/spec-orphan + test mirror → --expand-whitelist → regenerate views + header → reference sweep | — |
| 2 | End-to-end pipeline run (QA-green: all 3 --validate green; validate.sh + test.sh green; seed #13 green; root-only fallback proven; portability green; PR opens + STOPS) | — | Not Started | chjiang | — | #1 |

### Delivery History

<!-- Backward-looking record: PR links, merge dates, version bumps after ship. -->

- 2026-06-08: Scaffolded F000057 / S000099 from the /office-hours design doc.

## Dependency Graph

<!-- Visual representation of milestone ordering. -->

```
#1 Ship S000099 (relocate + fallback + must-fixes) --> #2 E2E pipeline run (QA-green, PR opens + STOPS)
```

## Open Questions

<!-- Questions still being decided. -->

| Question | Next check |
|----------|-----------|
| Env-override symmetry — add a `DOC_SPEC_PATH` override to `doc-spec.sh` for parity? | Resolved in design: yes, add it (outermost) — cheap and harmless. |
| `spec/` README? | Resolved in design: skip (minimal). Reopen only if the folder needs a guide. |
