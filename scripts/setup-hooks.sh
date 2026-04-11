#!/usr/bin/env bash
# Install pre-commit hook that runs validate.sh.
# Usage: ./scripts/setup-hooks.sh

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
HOOK_DIR="$REPO_ROOT/.git/hooks"

if [ ! -d "$HOOK_DIR" ]; then
  echo "ERROR: .git/hooks directory not found. Are you in a git repo?" >&2
  exit 1
fi

cat > "$HOOK_DIR/pre-commit" << 'HOOK'
#!/usr/bin/env bash
# Auto-installed by scripts/setup-hooks.sh
# Runs validate.sh before each commit.
./scripts/validate.sh
HOOK

chmod +x "$HOOK_DIR/pre-commit"
echo "Pre-commit hook installed at .git/hooks/pre-commit"
echo "Commits will now run validate.sh automatically."
