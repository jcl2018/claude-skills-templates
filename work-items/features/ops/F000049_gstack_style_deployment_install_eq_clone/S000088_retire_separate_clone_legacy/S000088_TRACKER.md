---
name: "Retire the separate-clone legacy (drop runtime .source, declare install==clone-in-place)"
type: user-story
id: "S000088"
status: active
created: "2026-06-05"
updated: "2026-06-05"
parent: "F000049"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "cj-feat-20260605-195021-17485"
blocked_by: ""
---

## Lifecycle

### Phase 1: Track

1. Read parent tracker (F000049) + S000085/86/87 (the foundation this completes)
2. Use this story's working branch: `cj-feat-20260605-195021-17485`
3. Scaffold work item directory and TRACKER.md
4. Distill `DESIGN.md` from the /office-hours S4 design (`.gstack/gstack-s4-retire-legacy-design-20260605.md`)
5. Scaffold `SPEC.md` (requirements, acceptance criteria, architecture, tradeoffs)
6. Scaffold `TEST-SPEC.md` (smoke + E2E test scenarios)
7. Atomic story — no child-task decomposition

**Gates:**
- [x] /office-hours design referenced (the S4 design doc, with the de-risking finding + the D1-B/D2/D3 calls)
- [x] Working branch created (`branch` field populated)
- [x] DESIGN + SPEC + TEST-SPEC scaffolded
- [x] Acceptance criteria defined
- [x] Tasks broken down (N/A — atomic story)

### Phase 2: Implement

1. Read DESIGN + SPEC for context
2. Implement per the SPEC architecture, in the i1→i2 order with a green checkpoint between
3. Run smoke tests as you go (TEST-SPEC `## Smoke Tests`)
4. Run `/CJ_personal-workflow check` on modified docs after updates
5. Update tracker: move through lifecycle phases, add journal entries
6. Update Files section with changed file paths

**Gates:**
- [ ] Acceptance criteria verified met
- [ ] Smoke tests pass
- [ ] Todos section reflects remaining work (no stale items)
- [ ] Files section updated with changed files

### Phase 3: Ship

1. Run `/CJ_personal-workflow check` — verify all validation passes
2. Verify smoke tests pass in CI (automated regression)
3. Walk E2E manually — a default install declares in-place; an orchestrator resolves shared scripts with zero `.source` reach
4. Ensure all child tasks (if any) have shipped — N/A (atomic)
5. Run `/ship` — creates PR, bumps version, updates changelog (includes pre-landing code review)
6. STOP at PR (skill-work, security-sensitive surface — `/land-and-deploy` is a separate human step)

❌ If `/CJ_personal-workflow check` finds issues: fix findings, re-run until clean
❌ If smoke or E2E fails: fix, re-run

**Gates:**
- [ ] `/CJ_personal-workflow check` — validation passed
- [ ] Smoke tests pass in CI
- [ ] E2E walked manually
- [ ] All children shipped (N/A — atomic)
- [ ] `/ship` — PR created (with pre-landing review)
- [ ] STOP at PR (operator reviews + merges)

## Acceptance Criteria

- [ ] Default `skills-deploy install` declares install==clone-in-place: stamps `install_mode: "in-place"` + `bundle_path` = the install-from checkout (= manifest `source`)
- [ ] The 4 orchestrator skills (CJ_goal_feature/defect/todo_fix/document-release) resolve `cj-goal-common.sh` with NO `.source` tier — 2-tier repo-local → `_cj-shared` only
- [ ] All 10 `.source`-reaching skills repoint the passive update-check snippet to the `_cj-shared` deployed home — no skill reads `manifest.source` at runtime
- [ ] `/CJ_portability-audit --no-adjudication` shows the family `local-only`/`standalone` with NO `.source`-reachback PREAMBLE finding; `skills-deploy bundle-status` recognizes `in-place` mode
- [ ] The install==clone-in-place model is documented (PHILOSOPHY/ARCHITECTURE/WORKFLOWS/CLAUDE.md); the sync helpers (`post-land-sync`, `--phase sync`) are RE-FRAMED to the in-place checkout, NOT deleted (a post-remote-merge `git pull` is still required); worktrees retained (D2); `validate.sh` + `scripts/test.sh` green, shellcheck clean

## Todos

- [ ] i1: default-install in-place receipt (`install_mode`/`bundle_path`) + drop the 4 orchestrators' `.source` cj-goal-common tier + repoint all 10 update-check snippets to `_cj-shared` + audit/bundle-status precision
- [ ] i1 green checkpoint: `validate.sh` + `scripts/test.sh` + portability audit `FINDINGS=0`
- [ ] i2: reframe the sync machinery (`post-land-sync`/`--phase sync`/`cj-goal-common`/`do_install` comments) to install==clone-in-place; document `--bundle` as the fresh-consumer bootstrap (default IS install==clone)
- [ ] Tests: `scripts/test.sh` S000088 hermetic block (in-place stamp + no-`.source`-tier + update-check repoint) + bump touched USAGE.md (Check 14)
- [ ] Docs: PHILOSOPHY/ARCHITECTURE/WORKFLOWS/CLAUDE.md + CHANGELOG/VERSION
- [ ] (S5) Windows/Git-Bash copy-mode parity + CI + `skills-update-check` on the in-place checkout

## Log

- 2026-06-05: Created. S4 of F000049 — retire the separate-clone legacy. The de-risking finding (manifest `source` already == the dev checkout; `install_mode: null`) means install==clone is reachable IN PLACE (D1-B) rather than by relocating the checkout. Operator chose "Build full S4 now". SCOPE HONESTY: "flip `--bundle` to default" is realized as declaring the default install install==clone-in-place (`--bundle` retained as the consumer bootstrap, no forced relocation); "retire post-land-sync/`--phase sync`" is realized as REFRAMING them to the in-place checkout — NOT deletion, because `gh pr merge` is a REMOTE merge and the in-place checkout still needs a post-merge `git pull`. Worktrees stay (D2).

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

- `scripts/skills-deploy` — default `do_install` in-place receipt (`install_mode`/`bundle_path`); `do_bundle_status` recognizes `in-place`; comment reframe
- `skills/CJ_goal_feature|CJ_goal_defect|CJ_goal_todo_fix|CJ_document-release/SKILL.md` — drop the `.source` cj-goal-common resolution tier (2-tier)
- `skills/*/SKILL.md` (10 skills) — repoint the passive update-check snippet from `.source` to `_cj-shared`
- `skills/*/USAGE.md` — `last-updated` bumps (Check 14 drift from the preamble edits)
- `scripts/cj-portability-audit.sh` — `.source`-reachback note reframe (fewer notes once `.source` is gone)
- `scripts/post-land-sync.sh`, `scripts/cj-goal-common.sh` — comment/doc reframe to the in-place checkout (functional pull retained)
- `scripts/test.sh` — S000088 hermetic test block
- `doc/PHILOSOPHY.md`, `doc/ARCHITECTURE.md`, `doc/WORKFLOWS.md`, `CLAUDE.md`, `CHANGELOG.md`, `VERSION`
- `.gstack/gstack-s4-retire-legacy-design-20260605.md` — the S4 /office-hours design

## Insights

The de-risking finding reframes the whole story: for a single-dev workbench whose `.source` already equals the dev checkout, "install == clone" is reachable IN PLACE — you don't relocate anything, you just (a) DECLARE the default install install==clone (`install_mode: in-place`) and (b) drop the now-redundant runtime `.source` reach-backs (the `_cj-shared` deposit from S1 already carries the shared scripts cross-repo; repo-local carries them in-workbench). The literal roadmap verbs ("retire post-land-sync", "flip --bundle to default") over-promise a subtractive cutover that is partly UNSAFE under the in-place + remote-merge reality: `gh pr merge` lands code remotely, so the in-place checkout still needs a post-merge `git pull` — `post-land-sync`/`--phase sync` are reframed, not deleted. The honest S4 delivers every F000049 acceptance criterion (install==clone, no runtime `.source` reach-back, develop-in-place, consumer install via `--bundle`) without breaking the running dev flow.

## Journal

- 2026-06-05T19:50:00Z [decision] Operator chose "Build full S4 now" at the design-gate AUQ after a full /office-hours S4 design pass (`.gstack/gstack-s4-retire-legacy-design-20260605.md`). Built inline (accumulated context on the exact `.source` sites + safe ordering > a fresh-context implement subagent). Scoped to the safe full-S4: the de-risking finding makes install==clone reachable in place; the literally-subtractive roadmap verbs are reframed (documented in the SPEC Tradeoffs) where deletion would break the post-remote-merge pull.
