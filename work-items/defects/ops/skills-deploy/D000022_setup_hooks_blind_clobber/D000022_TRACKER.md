---
name: "setup-hooks.sh blind-clobbers operator/tooling-owned git hooks (no sentinel check, no backup)"
type: defect
id: "D000022"
status: active
created: "2026-05-16"
updated: "2026-05-16"
repo: "jcl2018/claude-skills-templates"
branch: "claude/wonderful-feistel-20b8fc"
blocked_by: ""
---

## Lifecycle

### Phase 1: Track

1. Document reproduction steps in the Log section
2. Create working branch: `git checkout -b fix/setup_hooks_blind_clobber`
3. Scaffold required docs:
   - `RCA.md` (root cause analysis) — from `templates/CJ_personal-workflow/doc-RCA.md`
   - `test-plan.md` (regression test plan) — from `templates/CJ_personal-workflow/doc-test-plan.md`
4. Run `/investigate` to diagnose root cause
   → produces investigation findings in Log + Insights
5. Log initial symptoms and hypotheses

**Gates:**
- [x] Reproduction steps documented
- [x] Working branch created (`branch` field populated)
- [x] Required docs scaffolded (RCA + test-plan)
- [x] Root cause identified (`setup-hooks.sh` does `cat > "$HOOK_DIR/<hook>"` — unconditional, no-backup clobber — and `setup.sh` runs it on every re-invocation since PR #150/D000021)

### Phase 2: Implement

1. Work from `/office-hours` design doc (if applicable) + root cause analysis
   → no design doc: well-scoped follow-up explicitly carved out in PR #150's v4.6.5 CHANGELOG; route was direct-implement (small P2, fix shape fully specified)
2. Implement fix based on root cause analysis
3. Write regression test covering the defect scenario
4. Commit fix and test together
5. Update RCA doc with final root cause

**Gates:**
- [ ] Fix committed
- [x] RCA doc updated
- [x] Todos section reflects remaining work (no stale items)

### Phase 3: Ship

1. Run `/CJ_personal-workflow check` — verify no regressions
2. Verify test-plan: regression test scenarios passing
3. Run `/ship` — creates fix PR (includes pre-landing code review)
4. Run `/land-and-deploy` — merges and verifies fix in production

❌ If regression test fails: investigate further
❌ If CI fails: fix, push, re-run `/ship`

**Gates:**
- [ ] `/CJ_personal-workflow check` — validation passed
- [ ] Test-plan verified (regression scenarios passing)
- [ ] `/ship` — PR created
- [ ] `/land-and-deploy` — merged and deployed

## Reproduction Steps

1. In a clone of this repo, customize a git hook the workbench also manages, e.g.
   `printf '#!/bin/sh\necho my-custom-precommit\n' > .git/hooks/pre-commit` (or
   install Husky/lefthook, which write `.git/hooks/pre-commit`).
2. Run the documented update path: `./scripts/setup.sh` (NOT first-run only —
   `setup.sh` takes its update branch on every re-invocation; since D000021/PR
   #150 it now unconditionally calls `scripts/setup-hooks.sh`).
3. **Pre-fix observation:** the custom `.git/hooks/pre-commit` is **gone** —
   `setup-hooks.sh` did `cat > "$HOOK_DIR/pre-commit"` with no existence check,
   no sentinel check, and no backup. Same for `post-merge`. There is no
   `.git/hooks/pre-commit.bak`; the operator's hook is unrecoverable.
4. **Post-fix expectation:** the custom hook is preserved at
   `.git/hooks/pre-commit.bak` (timestamped if a `.bak` already exists), a
   `WARN:` line is printed on stderr naming the backup, and the workbench hook
   is installed. A re-run is a NO-OP (our own hook carries the sentinel, so it
   is recognized as ours and quietly refreshed — no spurious `.bak`).

**Environment:** workbench at `main` ≥ v4.6.5 (D000021 wired `setup-hooks.sh`
into `setup.sh`). `setup.sh` runs under `set -euo pipefail` and guards the
`setup-hooks.sh` call with `|| echo WARN >&2` (setup.sh:37). macOS workbench +
Linux CI; `mktemp`/`mv`/`cp -p`/`grep -F` behave identically on both (BSD + GNU).

## Todos

**In scope (this PR):**

- [x] `scripts/setup-hooks.sh` — replace the two unguarded `cat > "$HOOK_DIR/<hook>"` blocks with an `install_hook <name>` helper that: (1) writes the heredoc body to `mktemp "$HOOK_DIR/.<name>.XXXXXX"` and `chmod +x` it BEFORE touching the target (atomic — a mid-write/chmod failure leaves the real hook untouched, never truncated/non-executable); (2) before overwriting, if the target exists AND lacks the sentinel `# Auto-installed by scripts/setup-hooks.sh`, treats it as operator/tooling-owned: `cp -p` to `<hook>.bak` (timestamped if `.bak` exists) then `mv` ours in, emitting a `WARN:` to stderr; if the backup `cp` fails it ABORTS without clobbering (returns non-zero — never destroy a custom hook with no backup); (3) `mv` temp → target (atomic rename, same filesystem since temp lives in `$HOOK_DIR`); (4) propagates a non-zero exit so `setup.sh`'s `|| echo WARN >&2` guard fires on failure.
- [x] `scripts/setup-hooks.sh` — our own re-install is a NO-OP: when the existing hook carries the sentinel it is recognized as ours and refreshed with no `.bak` written (idempotent; repeated `setup.sh` runs do not spawn backup litter).
- [x] `scripts/test.sh` — **re-anchor** the existing D000013 guard (was `grep -q 'cat > "$HOOK_DIR/post-merge"'`, now `grep -qE 'install_hook[[:space:]]+post-merge'`): same regression intent ("setup-hooks.sh still writes a post-merge hook"), new code shape. Required — leaving the old anchor would make `test.sh` RED on this correct refactor (a false regression). Also updated the in-block comment example at the D000021 guard that cited the now-removed `cat > "$HOOK_DIR/post-merge"` token, and the SC2016 disable rationale comment.
- [x] `scripts/test.sh` — add the D000022 regression assertions inside the existing D000013 block (after the D000021 bootstrap-wiring guard, before the block's trailing blank line), matching the block's `if grep ... ; then ok ... ; else fail_test ... ; fi` idiom: (a) setup-hooks.sh greps the sentinel before clobber (`grep -qF '# Auto-installed by scripts/setup-hooks.sh' ... && a sentinel-guarded write path exists`); (b) setup-hooks.sh writes via `mktemp` + `mv` (atomic) and backs up to `.bak`. Source-level static checks only — no `git init`, no hook execution (same CI-safety rationale the D000013 block documents).
- [x] Negative test confirmed: temporarily stripping the sentinel/backup logic from a `mktemp` copy of `setup-hooks.sh` makes the new `test.sh` assertions `fail_test`; positive case `ok`s. Real file never destructively mutated.
- [ ] **Required disclosure (owned by `/ship`):** the v4.6.x CHANGELOG entry MUST note that this CLOSES the v4.6.5 carry-forward ("Making `setup-hooks.sh` sentinel-aware / backup-on-clobber is tracked as a separate follow-up defect"), and that the new behavior is opt-out-by-customization: a non-workbench hook is now preserved-and-backed-up, not silently destroyed. [Carried forward to `/ship`; not closeable at implement time.]

**Out of scope (deliberately NOT taken):**

- [ ] **Option (b) skip-and-warn** (refuse to install when a custom hook is present, tell the user to rename it to opt in) — rejected: task guidance says option (a) backup-then-install is friendlier, and it matches this repo's established "atomic mv; backup rotation" style (CLAUDE.md, `/CJ_improve-queue`).
- [ ] **`core.hooksPath` / multi-hook chaining / Husky-aware merge** — out of scope; backup-then-replace is the minimal safe fix. Operators who want chaining restore from `.bak` and wire it themselves.
- [ ] **`.bak` retention/GC policy** — timestamped backups can accumulate across many runs against an ever-changing custom hook. Accepted: backups are only written when a NON-sentinel hook is found (our own re-runs write none), so steady state produces zero litter. Revisit only if real accumulation is observed.
- [ ] **`test-deploy.sh` hermetic git-init fixture** — same over-build call as D000021; the D000013-block source greps in `test.sh` are the right altitude for a workbench (no network/`.git/hooks` mutation in CI).

## Log

- 2026-05-16: Created. Follow-up defect deferred at `/CJ_goal_run` GATE #2 during PR #150 (D000021, v4.6.5). PR #150 wired `setup-hooks.sh` into `setup.sh`'s bootstrap; its v4.6.5 CHANGELOG explicitly disclosed and deferred this: `setup-hooks.sh` does `cat > "$HOOK_DIR/pre-commit"` / `cat > "$HOOK_DIR/post-merge"` — a blind, no-backup clobber — and because `setup.sh` runs `setup-hooks.sh` on EVERY invocation (its update branch, not just first-run), any operator/tooling-customized hook (Husky, lefthook, local debug) is now silently destroyed on the next `setup.sh`. Root cause is unconditional `cat >` with no existence/sentinel/backup guard; the hook bodies already carry the sentinel `# Auto-installed by scripts/setup-hooks.sh`, so detection is a one-line `grep -F`. Adversarial review of PR #150 additionally flagged that `setup.sh`'s `|| echo >&2` guard swallows partial-write failures, leaving a truncated hook present rather than absent — addressed by the temp-file + atomic `mv` write (a failure now leaves the prior hook, or nothing, never a corrupt file). Route: direct-implement (small, well-scoped P2; fix shape fully specified by the task + CHANGELOG carry-forward; `/office-hours` overkill per skill-routing).

## PRs

## Files

- `scripts/setup-hooks.sh` — **modified**: two unguarded `cat > "$HOOK_DIR/<hook>"` blocks replaced by one `install_hook <name>` helper (sentinel-aware backup-on-clobber + `mktemp`+`chmod +x`+atomic `mv`); success `echo`s preserved on the success path; `exit $rc` added so failures reach `setup.sh`'s guard. Hook BODIES are byte-identical (sentinel line unchanged) so D000013's body-content guards (`skills-deploy install --overwrite`, path filter) stay green.
- `scripts/test.sh` — **modified**: D000013 post-merge guard re-anchored from `cat > "$HOOK_DIR/post-merge"` to `install_hook post-merge` (regression intent preserved); D000021-guard comment example + SC2016 rationale updated to the new token; two D000022 regression assertions added inside the same D000013 block (sentinel-before-clobber + atomic-mktemp-mv-backup). No fixture, no network, no hook execution.
- `.git/hooks/pre-commit` + `.git/hooks/post-merge` — **not modified by this PR** (untracked, per-machine). Behavior delta is preservation: a non-workbench hook is now backed up to `.bak`, not destroyed. Disclosure owned by `/ship`.

## Insights

<!-- D000022 is the backup-safety follow-up to D000021 (same file, `setup-hooks.sh`; same domain dir, `work-items/defects/ops/skills-deploy/`). D000021 wired the hook installer into the bootstrap and CONSCIOUSLY deferred clobber-safety to hold minimal scope, disclosing it in the v4.6.5 CHANGELOG — D000022 is the named, tracked discharge of that carry-forward (closing the loop, not new scope). The sentinel was already designed-in by D000013 (`# Auto-installed by scripts/setup-hooks.sh` in both hook bodies); D000022 just consumes it for ownership detection — no new contract, one `grep -F`. The atomic temp+mv write also incidentally closes the pre-existing low-severity note D000021's TRACKER explicitly parked ("setup-hooks.sh can exit 0 with a non-executable hook if chmod fails"): chmod now runs on the temp file before the mv, so a chmod failure aborts before the real hook is touched. Backup-then-install (option a) over skip-and-warn (option b) matches the repo's established atomic-mv + backup-rotation idiom (CLAUDE.md / `/CJ_improve-queue`). -->

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

- [finding] 2026-05-16 — Root cause confirmed by reading `scripts/setup-hooks.sh`: lines 23 + 36 do `cat > "$HOOK_DIR/pre-commit"` / `cat > "$HOOK_DIR/post-merge"` with zero guards (no `[ -e ]`, no sentinel grep, no backup). `setup.sh:37` calls it unconditionally on every run (D000021/PR #150). Both hook bodies already contain the sentinel `# Auto-installed by scripts/setup-hooks.sh` (pre-commit exact; post-merge with a trailing `.`), so a `grep -qF` substring on the no-period prefix matches BOTH and cleanly distinguishes "ours" from "theirs."
- [decision] 2026-05-16 — Chose option (a) backup-then-install over option (b) skip-and-warn. Rationale: explicit task guidance ("(a) is probably friendlier"), and (a) matches this repo's documented style ("atomic mv; backup rotation" — CLAUDE.md, `/CJ_improve-queue`). Backup `cp` failure ABORTS without clobbering (the one case where destroying an unbacked custom hook is unacceptable) — degrade to "workbench hook not installed," never to "custom hook lost."
- [decision] 2026-05-16 — Atomic write via `mktemp "$HOOK_DIR/.<name>.XXXXXX"` (same dir ⇒ same filesystem ⇒ `mv` is an atomic `rename(2)`; dotfile name ⇒ git never executes the temp). `chmod +x` on the temp BEFORE `mv` closes the adversarial-review partial-write finding AND D000021's parked non-executable-hook note in one move: any failure leaves the prior hook intact (or nothing), never a truncated/non-exec file.
- [decision] 2026-05-16 — `test.sh` change is NOT purely additive: the D000013 guard at the former line 627 grep'd the literal `cat > "$HOOK_DIR/post-merge"`, a token this refactor removes. Re-anchored it to `install_hook post-merge` (same regression intent). Leaving it would turn a correct refactor RED (false regression). Scoped, necessary, called out explicitly — not scope creep.
- [impl] 2026-05-16 — Modified 2 files: `scripts/setup-hooks.sh` (cat-blocks → `install_hook` helper, hook bodies byte-identical), `scripts/test.sh` (re-anchor D000013 post-merge guard + update its comment/SC2016 rationale + add 2 D000022 assertions in the same block). No new files beyond the D000022 work-item. No `test-deploy.sh`/`skills-deploy`/VERSION/catalog changes.
- [impl-finding] 2026-05-16 — Negative test verified against a `mktemp` copy of `setup-hooks.sh` with the sentinel/backup logic stripped: new `test.sh` assertions correctly `fail_test`; positive case `ok`s. Real working tree never destructively mutated.
