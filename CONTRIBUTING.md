# Contributing

## Creating a new skill

1. **Scaffold:** Run `./scripts/create-skill.sh your-skill-name`
   - Creates `skills/your-skill-name/SKILL.md` with frontmatter skeleton
   - Creates `docs/your-skill-name/PRD.md`, `ARCHITECTURE.md`, `TEST-SPEC.md`
   - Adds an entry to `skills-catalog.json`

2. **Write the skill:** Edit `skills/your-skill-name/SKILL.md`
   - Fill in the `description` field (be specific, >5 words)
   - Add `allowed-tools` frontmatter to restrict tool access
   - Write the skill instructions

3. **Fill in docs:** Edit the doc triplet in `docs/your-skill-name/`
   - PRD.md: problem statement, requirements, acceptance criteria
   - ARCHITECTURE.md: technical approach, component boundaries
   - TEST-SPEC.md: test matrix, coverage plan

4. **Validate:** Run `./scripts/validate.sh` to check everything is consistent

5. **Lint:** Run `./scripts/lint-skill.sh your-skill-name` for content quality checks

## Skill directory structure

```
skills/your-skill-name/
  SKILL.md              # required: skill instructions
  *.md                  # optional: supporting files

docs/your-skill-name/
  PRD.md                # product requirements
  ARCHITECTURE.md       # technical architecture
  TEST-SPEC.md          # test specification
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
- [ ] New skill has doc triplet (PRD, ARCHITECTURE, TEST-SPEC)
- [ ] `skills-catalog.json` updated if skill added/modified
- [ ] `README.md` regenerated if catalog changed (`./scripts/generate-readme.sh > README.md`)
