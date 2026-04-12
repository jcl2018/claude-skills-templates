# Contributing

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
- [ ] New skill has SKILL.md with valid frontmatter
- [ ] `skills-catalog.json` updated if skill added/modified
