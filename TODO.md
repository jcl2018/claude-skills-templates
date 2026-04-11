# TODO

## ~~Documentation~~ DONE

- [x] **P2:** Write a proper README with: overview of all 9 skills and what each does, the skill authoring workflow (design, scaffold, author, check, ship), install instructions (`setup.sh` / `skills-deploy`), and how to create a new skill from scratch using `/skill-author`.

## ~~skill-author~~ DONE

- [x] **P3:** Delegate to gstack `/ship` skill for the ship stage instead of using the custom `skill-ship.sh` script. Reuse the existing `/ship` workflow (commit, version bump, PR creation) rather than reimplementing it.

## ~~Deploy logic (gstack-style)~~ DONE

Build a deploy/install pipeline modeled after gstack's `setup` script. The target machine should NOT need this repo cloned manually — the installer handles everything.

### Requirements

- **Single install command**: e.g. `curl ... | bash` or a bootstrap script that clones the repo to a known location (`~/.claude/skills-templates/`)
- **Symlink-based deployment**: create real dirs at `~/.claude/skills/{name}/`, symlink only `SKILL.md` back to the cloned source (same pattern as gstack)
- **No collision with gstack skills**: detect existing gstack-managed symlinks and skip them
- **Update = git pull**: symlinks auto-resolve, no re-copy needed
- **Relink script**: like `gstack-relink`, repairs/recreates symlinks if anything drifts
- **Selective install**: allow installing specific skills, not just all-or-nothing
- **Uninstall**: clean removal of symlinks without touching gstack or other skills

### Scripts to build

1. `scripts/setup.sh` — clone repo + deploy symlinks (entry point for new machines)
2. `scripts/deploy-local.sh` — symlink skills from an existing clone
3. `scripts/relink.sh` — repair symlinks
4. `scripts/uninstall.sh` — remove deployed symlinks

### Reference

- gstack's setup: `~/.claude/skills/gstack/setup` (~840 lines)
- gstack's relink: `~/.claude/skills/gstack/bin/gstack-relink`
- gstack's uninstall: `~/.claude/skills/gstack/bin/gstack-uninstall`
