#!/usr/bin/env bash
# Collection version management: get, bump, and generate manifests.
# Usage: collection-version.sh <get|bump|manifest> [args]

. "$(dirname "$0")/lib.sh"

case "${1:-}" in
  get)
    read_version
    ;;

  bump)
    BUMP_TYPE="${2:-}"
    case "$BUMP_TYPE" in
      major|minor|patch) ;;
      *) echo "ERROR: bump type must be major, minor, or patch (got: '$BUMP_TYPE')" >&2
         echo "  Usage: collection-version.sh bump <major|minor|patch>" >&2
         exit 1 ;;
    esac

    CURRENT=$(read_version) || exit 1
    validate_version_string "$CURRENT" || exit 1

    IFS='.' read -r MAJOR MINOR PATCH <<< "$CURRENT"
    case "$BUMP_TYPE" in
      major) MAJOR=$((MAJOR + 1)); MINOR=0; PATCH=0 ;;
      minor) MINOR=$((MINOR + 1)); PATCH=0 ;;
      patch) PATCH=$((PATCH + 1)) ;;
    esac
    NEW_VERSION="$MAJOR.$MINOR.$PATCH"

    if [ "${3:-}" = "--dry-run" ]; then
      echo "$CURRENT -> $NEW_VERSION ($BUMP_TYPE)"
      exit 0
    fi

    # Atomic write to VERSION
    local_tmp=$(mktemp "$VERSION_FILE.tmp.XXXXXX")
    echo "$NEW_VERSION" > "$local_tmp"
    mv "$local_tmp" "$VERSION_FILE"

    # Update CHANGELOG.md
    CHANGELOG="$REPO_ROOT/CHANGELOG.md"
    if [ ! -f "$CHANGELOG" ]; then
      cat > "$CHANGELOG" << 'CEOF'
# Changelog

All notable changes to this collection will be documented in this file.
Format follows [Keep a Changelog](https://keepachangelog.com/).
CEOF
    fi

    TODAY=$(date +%Y-%m-%d)
    NEW_HEADER="## [$NEW_VERSION] - $TODAY"
    CHANGELOG_BAK=$(mktemp "$CHANGELOG.tmp.XXXXXX")
    awk -v header="$NEW_HEADER" '
      NR == 1 { print; next }
      !inserted && /^## \[/ { print ""; print header; print "### Changed"; print "- "; print ""; inserted=1 }
      { print }
      END { if (!inserted) { print ""; print header; print "### Changed"; print "- " } }
    ' "$CHANGELOG" > "$CHANGELOG_BAK"
    mv "$CHANGELOG_BAK" "$CHANGELOG"

    echo "$NEW_VERSION"
    ;;

  manifest)
    require_jq
    require_catalog

    COMMIT=$(git -C "$REPO_ROOT" rev-parse --short HEAD 2>/dev/null || echo "unknown")
    # Use git commit date for determinism
    COMMIT_DATE=$(git -C "$REPO_ROOT" log -1 --format=%cI 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)
    VERSION=$(read_version) || exit 1

    # Build skills array
    SKILLS_JSON=$(jq '[.[] | {name: .name, version: .version, files: .files}]' "$CATALOG")

    # Build templates array with checksums
    TEMPLATES_JSON="["
    first=true
    for tmpl in "$TEMPLATES_DIR"/*.md; do
      [ -f "$tmpl" ] || continue
      tmpl_name=$(basename "$tmpl")
      checksum=$(file_checksum "$tmpl" 2>/dev/null)
      if [ -z "$checksum" ]; then
        echo "  WARN: cannot checksum $tmpl_name" >&2
        checksum="UNREADABLE"
      fi
      if [ "$first" = true ]; then first=false; else TEMPLATES_JSON+=","; fi
      TEMPLATES_JSON+=$(jq -n --arg n "$tmpl_name" --arg s "$checksum" '{name: $n, sha256: $s}')
    done
    TEMPLATES_JSON+="]"

    # Build dependency graph
    DEPS_JSON=$(jq '[.[] | {(.name): (.depends.skills // [])}] | add // {}' "$CATALOG")

    # Assemble manifest
    jq -n \
      --arg cv "$VERSION" \
      --arg commit "$COMMIT" \
      --arg date "$COMMIT_DATE" \
      --argjson skills "$SKILLS_JSON" \
      --argjson templates "$TEMPLATES_JSON" \
      --argjson deps "$DEPS_JSON" \
      '{
        collection_version: $cv,
        commit: $commit,
        date: $date,
        skills: $skills,
        templates: $templates,
        skill_dependencies: $deps
      }'
    ;;

  *)
    echo "Usage: collection-version.sh <get|bump|manifest>"
    echo ""
    echo "Commands:"
    echo "  get                          Print current collection version"
    echo "  bump <major|minor|patch>     Bump version and update CHANGELOG.md"
    echo "  bump <type> --dry-run        Preview bump without writing"
    echo "  manifest                     Generate collection manifest (JSON to stdout)"
    exit 1
    ;;
esac
