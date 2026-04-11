# Contributing

## Creating a new skill

1. **Design:** Run `./scripts/skill-design.sh your-skill-name`
   - Creates `skills/your-skill-name/DESIGN.md` from template
   - Fill in Purpose and Behavior sections (required)

2. **Scaffold:** Run `./scripts/create-skill.sh your-skill-name`
   - Creates `skills/your-skill-name/SKILL.md` with frontmatter skeleton
   - Creates `skills/your-skill-name/CHANGELOG.md` with initial entry
   - Adds an entry to `skills-catalog.json`

3. **Write the skill:** Edit `skills/your-skill-name/SKILL.md`
   - Fill in the `description` field (be specific, >5 words)
   - Add `allowed-tools` frontmatter to restrict tool access
   - Write the skill instructions

4. **Validate:** Run `./scripts/skill-check.sh your-skill-name` to check lifecycle compliance

5. **Lint:** Run `./scripts/lint-skill.sh your-skill-name` for content quality checks

6. **Version:** Run `./scripts/skill-version.sh your-skill-name patch` to bump the version

7. **Ship:** Run `./scripts/skill-ship.sh your-skill-name` to commit, tag, and release

Or use `/skill-author your-skill-name` to run all stages in one guided conversation.

## Skill directory structure

```
skills/your-skill-name/
  DESIGN.md             # required: design rationale (created by skill-design.sh)
  SKILL.md              # required: skill instructions (created by create-skill.sh)
  CHANGELOG.md          # required: version history (created by create-skill.sh)
  *.md                  # optional: supporting files
```

## Naming conventions

- Skill names: kebab-case, starts with a letter (`my-skill`, not `2nd-skill`)
- Templates: `doc-` prefix for documents, `tracker-` prefix for work items
- All templates live in `templates/`, not in skill directories

## Template usage

| Template | When to use |
|----------|------------|
| `doc-PRD.md` | Product requirements for a feature |
| `doc-ARCHITECTURE.md` | Technical architecture document |
| `doc-TEST-SPEC.md` | Test specification with test matrix |
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
- [ ] New skill has DESIGN.md, SKILL.md, CHANGELOG.md
- [ ] `skills-catalog.json` updated if skill added/modified
- [ ] `README.md` regenerated if catalog changed (`./scripts/generate-readme.sh > README.md`)
