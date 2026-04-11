#!/usr/bin/env bash
# Shared library for skill workbench scripts.
# Source this file: . "$(dirname "$0")/lib.sh"

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CATALOG="$REPO_ROOT/skills-catalog.json"
SKILLS_DIR="$REPO_ROOT/skills"
TEMPLATES_DIR="$REPO_ROOT/templates"
DOCS_DIR="$REPO_ROOT/docs"

require_jq() {
  command -v jq >/dev/null 2>&1 || {
    echo "ERROR: jq is required but not installed" >&2
    exit 1
  }
}

require_catalog() {
  [ -f "$CATALOG" ] || {
    echo "ERROR: skills-catalog.json not found at $CATALOG" >&2
    exit 1
  }
  jq empty "$CATALOG" 2>/dev/null || {
    echo "ERROR: skills-catalog.json contains invalid JSON" >&2
    exit 1
  }
}

validate_skill_name() {
  local name="$1"
  if ! echo "$name" | grep -qE '^[a-z][a-z0-9-]*$'; then
    echo "ERROR: skill name must be kebab-case (a-z, 0-9, hyphens), starting with a letter" >&2
    echo "  Got: '$name'" >&2
    exit 1
  fi
  # Reject names that collide with git tag namespace ({name}-v{version})
  if echo "$name" | grep -qE -- '-v[0-9]+$'; then
    echo "ERROR: skill name must not end with -v followed by digits (collides with git tag namespace)" >&2
    echo "  Got: '$name'" >&2
    exit 1
  fi
}

# Extract version from SKILL.md frontmatter
extract_frontmatter_version() {
  local skill_file="$1"
  sed -n '/^---$/,/^---$/p' "$skill_file" | grep '^version:' | head -1 | sed 's/^version:[[:space:]]*//'
}

# Validate a version string matches semver format
validate_version_string() {
  local version="$1"
  if ! echo "$version" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+$'; then
    echo "ERROR: invalid version format: '$version' (expected X.Y.Z)" >&2
    return 1
  fi
}

VERSION_FILE="${COLLECTION_VERSION_FILE:-$REPO_ROOT/VERSION}"

# Read VERSION file, trimming whitespace
read_version() {
  [ -f "$VERSION_FILE" ] || {
    echo "ERROR: VERSION file not found at $VERSION_FILE" >&2
    echo "  Fix: create it with a semver string, e.g. echo '0.1.0' > $VERSION_FILE" >&2
    return 1
  }
  local ver
  ver=$(tr -d '[:space:]' < "$VERSION_FILE")
  [ -n "$ver" ] || {
    echo "ERROR: VERSION file is empty" >&2
    echo "  Fix: write a semver string, e.g. echo '0.1.0' > $VERSION_FILE" >&2
    return 1
  }
  echo "$ver"
}

# SHA256 of a file (portable: macOS shasum, Linux sha256sum)
file_checksum() {
  (shasum -a 256 "$1" 2>/dev/null || sha256sum "$1" 2>/dev/null) | awk '{print $1}'
}

# Compare two semver strings: returns 0 if $1 >= $2
version_gte() {
  local IFS='.'
  local -a a=($1) b=($2)
  local i
  for i in 0 1 2; do
    if [ "${a[$i]:-0}" -gt "${b[$i]:-0}" ]; then return 0; fi
    if [ "${a[$i]:-0}" -lt "${b[$i]:-0}" ]; then return 1; fi
  done
  return 0  # equal
}

init() {
  require_jq
  require_catalog
}
