---
name: "copilot-deploy.py: path traversal + symlink escape hardening"
type: defect
id: "D000010"
status: active
created: "2026-04-23"
updated: "2026-04-23"
repo: "jcl2018/claude-skills-templates"
branch: ""
blocked_by: ""
---

## Lifecycle

### Phase 1: Track

1. Document reproduction steps in the Log section
2. Create working branch: `git checkout -b fix/copilot-deploy-hardening`
3. Scaffold required docs:
   - `D000010_RCA.md` (root cause analysis) — from `templates/personal-workflow/doc-RCA.md`
   - `D000010_test-plan.md` (regression test plan) — from `templates/personal-workflow/doc-test-plan.md`
4. Run `/investigate` to diagnose root cause
   → produces investigation findings in Log + Insights
5. Log initial symptoms and hypotheses

**Gates:**
- [x] Reproduction steps documented
- [ ] Working branch created (`branch` field populated)
- [x] Required docs scaffolded (RCA + test-plan)
- [x] Root cause identified (see RCA.md — 2 categories: path-validation + symlink-following)

### Phase 2: Implement

1. Work from `/office-hours` design doc (if applicable) + root cause analysis
2. Implement fix based on root cause analysis
3. Write regression test covering the defect scenario
4. Commit fix and test together
5. Update RCA doc with final root cause

**Gates:**
- [ ] Fix committed
- [ ] RCA doc updated
- [ ] Todos section reflects remaining work (no stale items)

### Phase 3: Ship

1. Run `/personal-workflow check` — verify no regressions
2. Verify test-plan: regression test scenarios passing
3. Run `/ship` — creates fix PR (includes pre-landing code review)
4. Run `/land-and-deploy` — merges and verifies fix in production

**Gates:**
- [ ] `/personal-workflow check` — validation passed
- [ ] Test-plan verified (regression scenarios passing)
- [ ] `/ship` — PR created
- [ ] `/land-and-deploy` — merged and deployed

## Reproduction Steps

<!-- Two separate categories of concern. Both were surfaced by adversarial review
     (Claude subagent + Codex) during the /ship of F000005 (PR #43). User chose
     to defer because single-user self-install on own machine is a low-risk
     threat model. Hardening before wider distribution. -->

### Category 1: Path traversal via poisoned install-manifest.json

1. Install `copilot-deploy` bundle into a target repo (creates `install-manifest.json`).
2. Edit `install-manifest.json` and replace a `dest` value with `../../../etc/hosts`
   or `/tmp/attacker-controlled`.
3. Run `scripts/copilot-deploy.py doctor <target>` — reads the file outside the repo.
4. Run `scripts/copilot-deploy.py remove <target>` — unlinks the file outside the repo.

**Affected lines:** `scripts/copilot-deploy.py:173-176` (doctor), `:217-220` (remove).

### Category 2: Symlink escape in install/doctor

1. Add a symlink inside the source bundle (`work-copilot/instructions/evil -> /etc/passwd`).
2. Run `scripts/copilot-deploy.py install <target>` — copies through the symlink,
   exfiltrating `/etc/passwd` content into `<target>/.github/`.
3. Alternatively: make `<target>/.github` itself a symlink to outside the repo —
   `install --overwrite` clobbers files outside the intended sandbox.

**Affected lines:** `scripts/copilot-deploy.py:51-57` (build_file_map walks
follows symlinks), `:102-123` (dest-side copy via `shutil.copy2`).

## Todos

- [ ] Canonicalize every manifest `dest` value: resolve to absolute path, require
  that `Path(target).resolve() in Path(dest).resolve().parents` before any I/O.
- [ ] Reject absolute paths and any `..` component in manifest `dest` at parse time.
- [ ] In `build_file_map`: skip entries where `p.is_symlink()` or any parent in
  the walk is a symlink (use `Path.lstat()` and check `stat.S_ISLNK`).
- [ ] In `cmd_install` and `cmd_remove`: reject any `dest_abs` whose resolved path
  is not under `target.resolve()`.
- [ ] Add regression tests to `scripts/test.sh`:
  - Poisoned manifest with `../` in dest → doctor/remove exit with error, no I/O outside target.
  - Symlinked source file → install skips or errors, no exfil.
  - Symlinked target subtree → install refuses to follow.

## Log

- 2026-04-23: Created. Deferred from F000005 `/ship` (PR #43) after adversarial
  review (Claude subagent + Codex) surfaced these findings. User's current
  threat model is single-user self-install on own machine, so these are
  low-probability in practice. Hardening before publishing `copilot-deploy.py`
  for other users.

## PRs

## Files

- scripts/copilot-deploy.py (to be modified)
- scripts/test.sh (to add regression tests)

## Insights

- Both findings are a direct consequence of `copilot-deploy.py` being
  pure-stdlib: `shutil.copy2` follows symlinks by default; `Path.rglob`
  follows directory symlinks; JSON manifests are trusted verbatim.
  Hardening is ~30-40 LoC with a single `_safe_dest(target, rel)` helper
  and a pre-pass symlink check in `build_file_map`.

## Journal

### 2026-04-23 — deferral decision

User deferred this work at the /ship of F000005 because the immediate threat
model (own machine, own target repos, no hostile manifests) makes the HIGH-
severity label misleading. Fixing before the tool is recommended to anyone
else is the right tradeoff; fixing mid-ship would have delayed the bundle
delivery for a vulnerability nobody could exploit today.
