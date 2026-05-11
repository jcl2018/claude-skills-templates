# work-copilot

Portable GitHub Copilot bundle that mirrors the `CJ_company-workflow` skill from
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

A re-install from a v2.1.0+ workbench picks up the F000015 pipeline prompts
(`/wc-scaffold`, `/wc-investigate`, `/wc-implement`, `/wc-qa`, `/wc-ship`,
`/wc-pipeline`) and seeds `.github/work-copilot/domain/` with three skeleton
`.md` files for you to fill in once. If a domain file already exists on the
target (you've filled in `domain-knowledge.md` etc.), re-install emits
`[KEEP-USER]` and preserves your content byte-for-byte — domain/ is per-target
user data, not a byte-mirror. Same goes for `.github/work-copilot/designs/`,
where `/wc-investigate` writes its output: an empty `.gitkeep` seeds the
folder on first install, and subsequent installs never touch its contents.

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
| `prompts/investigate.prompt.md` | The `/wc-investigate` slash command — reads `domain/*.md` ambient context, greps the target codebase for entities in the user prompt, walks scoping conversation in chat, synthesizes a design doc to `.github/work-copilot/designs/<slug>-design-<datetime>.md` and writes `receipts.investigate` to its frontmatter (F000015 build #4 of 6) |
| `prompts/scaffold.prompt.md` | The `/wc-scaffold` slash command — reads a design-doc path's frontmatter for `status:` + `receipts.investigate`, reads the bundle manifest + templates, picks the next work-item ID, writes the directory tree with required artifacts, runs `/validate <new-dir>` as a structural gate, propagates `receipts.investigate` into the new tracker, writes `receipts.scaffold`, updates the design doc's `status: SCAFFOLDED` (F000015 build #3 of 6) |
| `prompts/implement.prompt.md` | The `/wc-implement` slash command — per-type implementation dispatch with walkthrough flow. Reads different input artifacts depending on tracker `type:` field (user-story → PRD + ARCHITECTURE + TEST-SPEC; defect → RCA + test-plan; task → TRACKER + test-plan; feature → delegates to child user-story; review → degenerate receipt path). Walkthrough mode only — never auto. Writes a `receipts.implement` block to tracker frontmatter (F000015 build #2 of 6) |
| `prompts/qa.prompt.md` | The `/wc-qa` slash command — QA walkthrough that writes a `receipts.qa` block into tracker frontmatter (F000015 build #1 of 6; locks the receipt schema for the remaining 5 pipeline prompts) |
| `prompts/ship.prompt.md` | The `/wc-ship` slash command — runs `/validate`, reads tracker + PRD/RCA (per type) + `PR-DESCRIPTION.md` template, runs the Working-Tree Rule paste pattern in WARN mode, synthesizes a PR description from journal + AC coverage + commit list, prints to chat for clipboard paste, writes `receipts.ship` with `pr_opened: false` (user flips `true` after opening PR on GitHub) (F000015 build #5 of 6) |
| `prompts/pipeline.prompt.md` | The `/wc-pipeline` read-only status compiler — reads receipts from work-item tracker frontmatter or design-doc frontmatter (mode auto-detected), reads `.git/HEAD` via the `codebase` tool for stale-check, computes five drift rules (Missing, Stale, Coverage holes, Diff audit drift, Ship-not-opened) plus Next Legal. No mutations. (F000015 build #6 of 6, **final**) |
| `instructions/copilot-instructions.md` | Always-on Copilot context (work-item conventions, sources of truth, bundle layout, troubleshooting) |
| `templates/*.md` | Required frontmatter / sections / phases per work-item type |
| `domain/*.template.md` | Domain-knowledge skeletons. On install, suffix is stripped and written to `<target>/.github/work-copilot/domain/<name>.md` ONLY if missing — preserves user-filled content on re-install via `[KEEP-USER]`. Read by `/wc-investigate` as ambient context. Per-target user data; never byte-mirrored. |
| `WORKFLOW.md` | Procedural backbone — phases, scaffolding rules, when to validate |
| `reference/guide-*.md` | How to write each artifact (PRD, ARCHITECTURE, RCA, TEST-SPEC, task, etc.) |
| `philosophy/rationale-*.md` | Why each artifact is structured the way it is |
| `examples/example-*.md` | Worked examples to copy from |
| `fixtures/` | Validator self-tests (`/validate` against these should produce known output) |
| `copilot-artifact-manifests.json` | Which artifacts each work-item type requires |

On a fresh install, `<target>/.github/work-copilot/designs/.gitkeep` is also created — an
empty per-target folder where `/wc-investigate` lands its design docs. Re-install never
touches `designs/` contents (per-target user data).

The bundle is byte-identically mirrored from `deprecated/CJ_company-workflow/` and
`deprecated/CJ_company-workflow/templates/` in the parent repo. Drift is enforced by
`scripts/validate.sh` Error check 10 (CI). Edit upstream first; the mirror
follows. Bundle-only files (the F000015 pipeline prompts; no upstream counterpart)
are covered by `scripts/validate.sh` Error check 10b instead — fails fast if any
expected prompt file is missing from `work-copilot/`. As of v2.1.0 the
`EXPECTED_BUNDLE_FILES` array covers all 10 F000015 bundle files (6 prompts +
3 domain skeletons + the existing `validate.prompt.md`).
