#!/usr/bin/env bash
# setup.sh — Bootstrap installer for claude-skills-templates.
# Clone the repo (or update) and deploy all skills.
#
# Usage:
#   git clone https://github.com/jcl2018/claude-skills-templates.git ~/.claude/skills-templates
#   ~/.claude/skills-templates/scripts/setup.sh
#
# Or from an existing clone:
#   ./scripts/setup.sh

set -euo pipefail

CLONE_DIR="${HOME}/.claude/skills-templates"
REPO_URL="https://github.com/jcl2018/claude-skills-templates.git"

# If run from inside the repo, use that location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/skills-deploy" ]; then
  CLONE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
fi

# Clone or update
if [ -d "$CLONE_DIR/.git" ]; then
  echo "Updating $CLONE_DIR..."
  git -C "$CLONE_DIR" pull --ff-only 2>/dev/null || echo "WARN: git pull failed, using current state"
else
  echo "Cloning to $CLONE_DIR..."
  git clone "$REPO_URL" "$CLONE_DIR"
fi

# Deploy
exec "$CLONE_DIR/scripts/skills-deploy" install
