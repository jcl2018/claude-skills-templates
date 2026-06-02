# Contributing

This repo ships **two surfaces** from one source of truth: Claude Code skills under `skills/`, and a self-contained **GitHub Copilot** bundle under `work-copilot/`. Contributing guides for both follow.

## Creating a new skill

1. **Design:** Use `/office-hours` to produce a design doc, or create `skills/your-skill-name/DESIGN.md` manually using `templates/doc-SKILL-DESIGN.md`

2. **Create the skill directory and files:**
   ```
   skills/your-skill-name/
     SKILL.md              # required: skill instructions with YAML frontmatter
     DESIGN.md             # recommended: design rationale
     CHANGELOG.md          # recommended: version history
     *.md                  # optional: supporting files
   ```

3. **Write SKILL.md** with required YAML frontmatter:
   ```yaml
   ---
   name: your-skill-name
   description: "One-line description of what this skill does."
   version: 0.1.0
   allowed-tools:
     - Bash
     - Read
   ---
   ```

4. **Add a catalog entry** to `skills-catalog.json` (see CLAUDE.md for the JSON schema)

5. **Validate:** Run `./scripts/validate.sh` to check catalog consistency

6. **Ship:** Use `/ship` to commit and create a PR

## Contributing to the Copilot bundle (`work-copilot/`)

`work-copilot/` is a self-contained GitHub Copilot bundle — **not** a Claude skill (no `SKILL.md`, no `skills-catalog.json` entry). It is the canonical source (no upstream sync), deployed to non-Claude target repos via `scripts/copilot-deploy.py`.

1. **Edit in place.** The canonical files live under `work-copilot/`: `templates/`, `WORKFLOW.md`, `copilot-artifact-manifests.json`, `prompts/` (the `/wc-*` + `/validate` commands), `reference/`, `philosophy/`, `examples/`, `fixtures/`, `domain/`, and `instructions/copilot-instructions.md`.

2. **Adding a bundle file:** create it under the right `work-copilot/<subdir>/`, then **append one entry** to the `EXPECTED_BUNDLE_FILES` array in `scripts/validate.sh` (Error check 10). That array is the registration point — a new file not listed there fails `validate.sh`.

3. **Keep `copilot-instructions.md` under budget.** `scripts/test.sh` enforces a size budget on `work-copilot/instructions/copilot-instructions.md` (≤ 8 KB).

4. **Validate + test:** `./scripts/validate.sh` (bundle integrity) and `./scripts/test.sh` (size budget + install round-trip). To dry-run a deploy: `python3 scripts/copilot-deploy.py install <target>` then `python3 scripts/copilot-deploy.py doctor <target>`.

5. **Ship:** use `/ship` to commit and open a PR, same as skill changes.

## Naming conventions

- Skill names: kebab-case, starts with a letter (`my-skill`, not `2nd-skill`)
- Templates: `doc-` prefix for documents, `tracker-` prefix for work items
- All templates live in `templates/`, not in skill directories

## Template usage

| Template | When to use |
|----------|------------|
| `doc-DESIGN.md` | Condensed feature/story design — distilled from /office-hours output |
| `doc-SPEC.md` | User-story specification: requirements (`### P0/P1/P2`) + acceptance criteria + architecture + tradeoffs |
| `doc-ROADMAP.md` | Feature roll-up: scope, non-goals, decomposition, delivery timeline (with `### Delivery History` sub-section) |
| `doc-TEST-SPEC.md` | Test specification: `## Smoke Tests` (automated, CI) + `## E2E Tests` (manual, pre-`/ship`) + `## Coverage Gaps`. Soft cap of 5 rows per tier. |
| `doc-RCA.md` | Root cause analysis for incidents |
| `tracker-feature.md` | Feature work item |
| `tracker-defect.md` | Bug/defect work item |
| `tracker-task.md` | Generic task work item |

## Running validation locally

Before pushing:

```bash
./scripts/validate.sh    # structural checks (must pass)
./scripts/test.sh        # full test suite (must pass)
./scripts/lint-skill.sh  # content quality (recommended)
./scripts/doctor.sh      # health diagnostics (recommended)
```

## PR checklist

- [ ] `validate.sh` passes (required)
- [ ] `test.sh` passes (required)
- [ ] `lint-skill.sh` is clean (recommended, not required)
- [ ] `doctor.sh` shows no errors (recommended)
- [ ] New skill has SKILL.md with valid frontmatter
- [ ] `skills-catalog.json` updated if skill added/modified
- [ ] If you touched `work-copilot/`, every new file is listed in `EXPECTED_BUNDLE_FILES` (validate.sh Error check 10)
