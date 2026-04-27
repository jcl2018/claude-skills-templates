# work-copilot

Portable GitHub Copilot bundle that mirrors the `company-workflow` skill from
`claude-skills-templates`. Gives a Copilot user the same `/validate` workflow
and ambient knowledge a Claude Code user gets at home.

## Prerequisites

- Python 3.8+ (stdlib only — no pip)
- VS Code with the GitHub Copilot extension signed in
- `jq` if you want to run `scripts/validate.sh` from the parent repo (optional;
  installer doesn't need it)

## Install

```sh
# From the claude-skills-templates checkout:
python3 scripts/copilot-deploy.py install <path-to-target-repo>
```

Output you should see:

```
copilot-deploy install -> /path/to/target
  [WRITE]     .github/copilot-instructions.md
  [WRITE]     .github/prompts/validate.prompt.md
  [WRITE]     .github/work-copilot/WORKFLOW.md
  ... (about 50 files total)

SUMMARY: installed=53 updated=0 skipped=0 overwritten=0 total=53
```

Preview without writing:

```sh
python3 scripts/copilot-deploy.py install --dry-run <target>
```

## Use

In the target repo, open VS Code and Copilot Chat. Then:

```
/validate work-items/F000001_my_feature/
```

Output uses the canonical tags:

- `[PASS]` — artifact present and frontmatter complete
- `[MISSING]` — required artifact not found
- `[DRIFT]` — artifact found but doesn't match its template
- `[EXTRA]` — non-required section present (advisory)

Self-test (any installed target):

```
/validate .github/work-copilot/fixtures/valid-feature-dir/
```

Should print `[PASS]` for every artifact. If it doesn't, the bundle install is
broken — see Troubleshooting.

## Upgrade

```sh
git -C <claude-skills-templates-checkout> pull
python3 scripts/copilot-deploy.py install <target>     # idempotent re-install
```

If you've manually edited any installed file, re-install reports `[DRIFT]`
and exits non-zero. Either restore the file, or accept the upstream copy:

```sh
python3 scripts/copilot-deploy.py install --overwrite <target>
```

A re-install on an existing v0.14.0 target picks up the new v0.15.0 mirror
artifacts (`WORKFLOW.md`, `reference/`, `philosophy/`, `examples/`, complete
`fixtures/`) automatically. If you happened to drop a `WORKFLOW.md` (or any
other newly-mirrored file) into `.github/work-copilot/` manually before
upgrading, re-install will report `[DRIFT]` on it — use `--overwrite`.

## Health check

```sh
python3 scripts/copilot-deploy.py doctor <target>
```

Reports each installed file as `[PASS]` / `[MISSING]` / `[DRIFT]` / `[ORPHAN]`.
Exit non-zero if anything is off.

## Uninstall

```sh
python3 scripts/copilot-deploy.py remove <target>
# Preview without deleting:
python3 scripts/copilot-deploy.py remove --dry-run <target>
```

Removes everything the install manifest tracked, plus the manifest itself.

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| `/validate` not recognized in Copilot Chat | Reload VS Code window after install |
| `/validate` output is generic, no `[PASS]`/`[MISSING]` tags | Rerun: "use the canonical tags from the prompt verbatim" |
| Copilot answers from training instead of `WORKFLOW.md` for procedural questions | Verify `.github/copilot-instructions.md` exists; prefix the question: "read `.github/work-copilot/WORKFLOW.md` and answer from there" |
| `ERROR: copilot-deploy requires Python 3.8+` | Upgrade Python (python.org installer or Homebrew) |
| `ERROR: install-manifest entry escapes target directory` | Manifest is corrupt — delete `<target>/.github/work-copilot/install-manifest.json` and re-run install |
| Re-install reports DRIFT on a file you don't recognize | Probably a manual experiment in a prior session — `--overwrite` accepts upstream |

For more, see [`instructions/copilot-instructions.md`](instructions/copilot-instructions.md)
(installs as `<target>/.github/copilot-instructions.md`).

## What's in the bundle

| Path | Role |
|------|------|
| `prompts/validate.prompt.md` | The `/validate` slash command logic |
| `instructions/copilot-instructions.md` | Always-on Copilot context (work-item conventions, sources of truth, bundle layout, troubleshooting) |
| `templates/*.md` | Required frontmatter / sections / phases per work-item type |
| `WORKFLOW.md` | Procedural backbone — phases, scaffolding rules, when to validate |
| `reference/guide-*.md` | How to write each artifact (PRD, ARCHITECTURE, RCA, TEST-SPEC, task, etc.) |
| `philosophy/rationale-*.md` | Why each artifact is structured the way it is |
| `examples/example-*.md` | Worked examples to copy from |
| `fixtures/` | Validator self-tests (`/validate` against these should produce known output) |
| `copilot-artifact-manifests.json` | Which artifacts each work-item type requires |

The bundle is byte-identically mirrored from `skills/company-workflow/` and
`templates/company-workflow/` in the parent repo. Drift is enforced by
`scripts/validate.sh` Error check 10 (CI). Edit upstream first; the mirror
follows.
