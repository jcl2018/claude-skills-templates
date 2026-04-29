---
name: "work-copilot install requires full claude-skills-templates checkout"
type: defect
id: "D000011"
status: active
created: "2026-04-28"
updated: "2026-04-28"
repo: "jcl2018/claude-skills-templates"
branch: ""
blocked_by: ""
---

## Lifecycle

### Phase 1: Track

1. Document reproduction steps in the Log section
2. Create working branch: `git checkout -b fix/copilot-bundle-install-requires-full-repo`
3. Scaffold required docs:
   - `RCA.md` (root cause analysis) — from `templates/doc-RCA.md`
   - `test-plan.md` (regression test plan) — from `templates/doc-test-plan.md`
4. Run `/investigate` to diagnose root cause
   → produces investigation findings in Log + Insights
5. Log initial symptoms and hypotheses

**Gates:**
- [x] Reproduction steps documented
- [ ] Working branch created (`branch` field populated)
- [x] Required docs scaffolded (RCA + test-plan)
- [x] Root cause identified (or best hypothesis logged)

### Phase 2: Implement

1. Work from `/office-hours` design doc (if applicable) + root cause analysis
   → design doc at `~/.gstack/projects/{slug}/`
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

❌ If regression test fails: investigate further
❌ If CI fails: fix, push, re-run `/ship`

**Gates:**
- [ ] `/personal-workflow check` — validation passed
- [ ] Test-plan verified (regression scenarios passing)
- [ ] `/ship` — PR created
- [ ] `/land-and-deploy` — merged and deployed

## Reproduction Steps

<!-- Steps to reproduce the defect. Include environment details. -->

**Environment:** Windows work box, VS Code + GitHub Copilot, no Claude Code installed.

1. On Windows, follow the v1.1.0 install instructions:
   `git clone https://github.com/jcl2018/claude-skills-templates.git`
2. Observe what gets pulled to disk: the entire repo (~350 files) lands locally,
   including paths irrelevant to a Copilot user:
   - `.claude/` — Claude Code workspace settings
   - `skills/personal-workflow/` and `skills/system-health/` — Claude-only skills
   - `skills/company-workflow/` — the upstream the bundle mirrors (only the
     mirror copy under `work-copilot/` is needed for Copilot install)
   - `templates/personal-workflow/` — Claude-only template set
   - `work-items/` — the workbench's own work-tracking history
   - `docs/`, `.docs/`, `scripts/` (most of `scripts/` is workbench tooling,
     not bundle-install machinery)
   - root configs: `package.json`, `bun.lockb`, `.github/workflows/`, etc.
3. The Copilot user actually only needs:
   - `work-copilot/` (the bundle itself)
   - `scripts/copilot-deploy.py` (the installer)
   - Total surface needed: ~50 files / ~200 KB (vs ~350 files / multi-MB checkout)
4. Run `python scripts/copilot-deploy.py install <work-target>` — works correctly,
   only installs the bundle into `<work-target>/.github/`. The bug is in the
   *distribution path*, not the install command itself.

## Todos

<!-- Actionable items for this defect fix. -->

- [ ] Decide on distribution mechanism (RCA — pick one of: GitHub release tarball, sparse-checkout helper, dedicated bundle-only repo, `gh release download`)
- [ ] Implement the chosen mechanism
- [ ] Update `work-copilot/README.md` install section with the new path
- [ ] Update CLAUDE.md and v1.1.0 release notes if the install workflow changed
- [ ] Add regression test covering "fresh Windows machine with no clone" install path

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-04-28: Created. User reported: "the remote copilot just downloads everything including claude settings. but we should just need that copilot things." Surfaced during Windows-box install of v1.1.0 (commit 9f9187f, branch feat/v1-cut). Bundle install itself works correctly; the bug is that the *distribution mechanism* (full git clone) is too coarse — Copilot users get ~7× more bytes and ~10× more files than they need, including Claude-specific settings/skills/templates that are irrelevant on Windows.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. -->

- README.md                                    # likely needs an "install for Copilot users" section
- work-copilot/README.md                       # quickstart needs to point at the chosen distribution mechanism, not `git clone`
- scripts/copilot-deploy.py                    # may need a `--from-url` mode that fetches just the bundle from a release tarball
- (TBD per RCA decision) — possibly a new `scripts/release-bundle.sh` that publishes `work-copilot/` + `scripts/copilot-deploy.py` as a release asset

## Insights

<!-- Root cause analysis, patterns discovered, related defects. -->

- The F000004 design ([F000004_DESIGN.md](../../features/F000004_work_copilot/F000004_DESIGN.md)) addressed the *runtime* port (templates + manifest + `validate.prompt.md` + installer) but did not address the *distribution path* — it implicitly assumed Copilot users would clone the workbench repo. That assumption is wrong for the actual target user (work box with no Claude Code, no maintainer history needed).
- The bundle is already self-contained inside `work-copilot/` (this is design Decision #1: "self-contained — all skill assets live under `skills/company-workflow/` ... all templates under `templates/company-workflow/`"). The mirror under `work-copilot/` brings everything Copilot needs into one directory + the installer script. The distribution mechanism is the one missing piece.
- Closest comparable project: [skills-deploy](../../../scripts/skills-deploy) — but that's Claude-side, installs to `~/.claude/`, not analogous to a Windows-box bundle distribution.
- Related: F000004 milestone #7 ("Symlink setup docs") is about symlinks for power-users with a checkout. This defect is the parallel concern for users who don't want a checkout at all.

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

### 2026-04-28 — finding
v1.1.0 install workflow on Windows requires `git clone https://github.com/jcl2018/claude-skills-templates.git` — pulls the full workbench repo (~350 files) when the bundle Copilot users need is ~50 files (`work-copilot/` + `scripts/copilot-deploy.py`). The full-clone surface includes Claude Code settings (`.claude/`), Claude-only skills (`skills/personal-workflow/`, `skills/system-health/`), the upstream of the bundle mirror (`skills/company-workflow/` — duplicated content vs `work-copilot/`), and workbench-internal tooling. None of this is needed on the work box.

### 2026-04-28 — finding
Distribution-path concern was out of scope for F000004 v1 (validator core) and v2.1 (artifact completeness). The F000004 design assumed cloners; the fix is a separate concern with its own design surface. Candidate mechanisms (to settle in RCA):

1. **GitHub release tarball** — publish `work-copilot/` + `scripts/copilot-deploy.py` as a release asset on every tag. User runs `curl -L .../v1.1.0/work-copilot-bundle.tar.gz | tar xz` then `python copilot-deploy.py install <target>`. Pro: zero git complexity for end-user. Con: requires a release-publishing step in the workbench's CI/ship flow.
2. **Sparse checkout helper** — `git clone --filter=blob:none --no-checkout` + `git sparse-checkout set work-copilot scripts/copilot-deploy.py`. Pro: still git-native, version-pinned via tags. Con: harder to explain to a non-git-native user; ~6 commands instead of 2.
3. **Dedicated bundle-only repo** — publish `work-copilot/` + the installer to a separate `jcl2018/work-copilot` repo on every release. User clones that. Pro: clean install path (`git clone <bundle-repo>` → install). Con: adds a second repo to maintain in sync; sync drift becomes a new defect class.
4. **`gh release download`** — same as #1 but via `gh` CLI. Pro: less friction than `curl + tar`. Con: requires `gh` on Windows work box (likely available, but adds a dependency).

Leaning #1 (release tarball) — fewest moving parts on the consumer side, the publish step is one new line in `/ship` flow.

### 2026-04-28 — decision
Defer mechanism choice to RCA authoring. Implementation gated on RCA + an /office-hours run if the choice ends up being non-obvious.
