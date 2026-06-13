# Reference

Curated external references for building this workbench — the repos, docs,
standards, and tools that this codebase demonstrably leans on. Every entry below
is grounded in something the repo actually references (a cited URL, a tool the
scripts/CI invoke, or a standard the conventions follow); this is not an
aspirational reading list. Grouped by category, each entry carries a one-line
note on why it matters here. The set is the operator's to prune and extend.

## Claude Code & agents

- [Claude Code](https://docs.claude.com/en/docs/claude-code/overview) — this
  workbench's primary delivery surface is a family of Claude Code skills (the
  `CJ_` family under `skills/`, auto-discovered as a plugin); the docs explain
  the skill, plugin, and `~/.claude/` model these scripts deploy into.
- [Anthropic developer docs](https://docs.claude.com/) — the canonical home for
  Claude Code, the Agent SDK, and the agent patterns the `CJ_` skills are built
  on.

## gstack

- [gstack](https://github.com/garrytan/gstack) — the upstream skill collection
  this workbench composes on top of: the `CJ_goal_*` orchestrators wrap gstack's
  `/office-hours`, `/ship`, `/land-and-deploy`, `/investigate`, and
  `/document-release`, and `scripts/sync-upstream.sh` compares against it.

## Conventions & standards

- [Keep a Changelog](https://keepachangelog.com/) — the format `CHANGELOG.md`
  follows (cited verbatim in the changelog header and in
  `scripts/collection-version.sh`).
- [Semantic Versioning](https://semver.org/) — the shape of the repo's `VERSION`
  string; `scripts/skills-update-check` validates versions with an `is_semver`
  guard (this repo pins a 3-digit `X.Y.Z` variant).

## Tooling

- [GitHub CLI (`gh`)](https://cli.github.com/) — a stated prerequisite (README)
  and the tool the merge/ship convention drives (`gh pr merge`, `gh pr view`,
  `gh api`) throughout `CLAUDE.md` and the scripts.
- [ShellCheck](https://www.shellcheck.net/) — the shell linter the CI and the
  Windows Git-Bash smoke job run; the scripts carry targeted `# shellcheck
  disable` directives where a finding is intentional.
- [jq](https://jqlang.github.io/jq/) — a stated prerequisite (README) used to
  read `skills-catalog.json` and the manifests across the skills and validators.
- [GitHub Actions](https://docs.github.com/en/actions) — the CI surface under
  `.github/workflows/` (`validate.yml`, `windows.yml`, `eval-nightly.yml`) that
  gates every PR.
- [Git for Windows](https://gitforwindows.org/) — ships the Git Bash shell this
  POSIX workbench supports on Windows (copy-mode install, the `windows-latest`
  smoke job); `git` and `jq` come bundled with it.
- [GitHub Copilot](https://github.com/features/copilot) — the non-Claude
  delivery target the self-contained `work-copilot/` bundle carries the same
  work-item templates and validation set to (deployed via
  `scripts/copilot-deploy.py`).
- [Python 3](https://www.python.org/) — the interpreter `scripts/copilot-deploy.py`
  runs on; a stated prerequisite for the Copilot bundle path only.
