# Reference

External references for building this workbench — the repos, docs, standards, and
tools this codebase demonstrably leans on. Every entry is grounded in something the
repo actually references (a cited URL, a tool the scripts/CI invoke, or a standard
the conventions follow) — not an aspirational reading list. Each note says, in a
line or two, **why it matters here and when you'd reach for it**, so this reads as
a working operator's shelf rather than a link dump. The set is the operator's to
prune and extend.

**New here?** Read **Claude Code** (the surface everything ships on) and **gstack**
(the upstream skills the `CJ_goal_*` orchestrators wrap) first — together they
explain ~80% of what this repo does. Then skim **Keep a Changelog** + **Semantic
Versioning**, the two conventions every `/ship` touches. Everything under *Tooling*
is situational: reach for it only when you're in that corner of the repo.

## Claude Code & agents — the delivery surface (read first)

- [Claude Code](https://docs.claude.com/en/docs/claude-code/overview) — **the one
  doc to read before touching `skills/`.** This workbench *is* a family of Claude
  Code skills (the `CJ_` family, auto-discovered as a plugin); the skill / plugin /
  `~/.claude/` model these docs describe is exactly what `skills-deploy` installs
  into. When a skill behaves unexpectedly, the mental model lives here.
- [Anthropic developer docs](https://docs.claude.com/) — the canonical home for the
  Agent SDK and the agent patterns the `CJ_` skills are built on. Reach for it when
  you're designing a *new* skill, not maintaining an existing one.

## gstack — the upstream this composes on

- [gstack](https://github.com/garrytan/gstack) — **the skills the `CJ_goal_*`
  orchestrators delegate to.** `/office-hours`, `/ship`, `/land-and-deploy`,
  `/investigate`, and `/document-release` are gstack's; the workbench *wraps* them
  (never edits them), and `scripts/sync-upstream.sh` diffs against it. Read this
  when a wrapped step behaves differently than the `CJ_` prose implies — upstream
  is authoritative for the wrapped half.

## Conventions & standards — what every `/ship` obeys

- [Keep a Changelog](https://keepachangelog.com/) — the `CHANGELOG.md` format
  (cited in the changelog header and `scripts/collection-version.sh`). The
  load-bearing rule in practice: a new entry goes *above* the prior version header —
  the single most common place a hand-edit silently drops a heading.
- [Semantic Versioning](https://semver.org/) — the shape of `VERSION`, enforced by
  `scripts/skills-update-check`'s `is_semver` guard. Note the local twist: this repo
  pins a **3-digit `X.Y.Z`** variant, which is why stock 4-digit ship tooling needs
  adapting rather than using as-is.

## Tooling — reach for these when you're in that corner

- [GitHub CLI (`gh`)](https://cli.github.com/) — **a hard prerequisite, not a
  convenience.** The whole merge/ship convention is `gh` (`gh pr merge`, `gh pr
  view`, `gh api`), and `CLAUDE.md`'s merge rules assume it; when `gh` is offline,
  the version-queue and land steps degrade with a note rather than failing.
- [jq](https://jqlang.github.io/jq/) — the other hard prerequisite. Every script
  that reads `skills-catalog.json` or a manifest goes through `jq`, so a missing
  `jq` breaks validation itself, not just niceties.
- [ShellCheck](https://www.shellcheck.net/) — the linter CI and the Windows smoke
  job run. Worth knowing before you push: CI's apt build is *stricter* than a
  typical local one (it flags info-level checks a local 0.x misses), so lint
  locally first; intentional findings carry targeted `# shellcheck disable`
  directives.
- [GitHub Actions](https://docs.github.com/en/actions) — the CI under
  `.github/workflows/`. The per-PR gates are `validate.yml` + `windows.yml` (the
  fast Git Bash smoke); `windows-nightly.yml` (the slower `skills-deploy` suite on
  `windows-latest`) runs on a nightly schedule instead of every PR. The behavioral
  eval harness (`scripts/eval.sh`) and the doc/test-drift audit
  (`scripts/audit-nightly.sh`) run on-demand / locally — they no longer have CI
  workflows. Open the workflow file when a check passes locally but fails in CI.
- [Git for Windows](https://gitforwindows.org/) — the Git Bash shell this POSIX
  workbench supports on Windows (copy-mode install, the `windows-latest` smoke job);
  it bundles `git` and `jq`. Only relevant if you touch the cross-platform path.
- [GitHub Copilot](https://github.com/features/copilot) — the non-Claude delivery
  target the self-contained `work-copilot/` bundle serves (via
  `scripts/copilot-deploy.py`). Skip it unless you're working the Copilot bundle.
- [Python 3](https://www.python.org/) — the interpreter for
  `scripts/copilot-deploy.py`, and nothing else; a prerequisite for the Copilot
  path only. The rest of the workbench is POSIX shell.
