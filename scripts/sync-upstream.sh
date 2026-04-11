#!/usr/bin/env bash
# Compare upstream gstack skills against local copies.
# Local-only developer tool — requires gstack installed.
# Usage: ./scripts/sync-upstream.sh [--apply]

. "$(dirname "$0")/lib.sh"
init

APPLY=false
[ "${1:-}" = "--apply" ] && APPLY=true

GSTACK_SKILLS="${GSTACK_SKILLS_PATH:-$HOME/.claude/skills/gstack}"
CHANGES=0

echo "=== Upstream Skill Sync ==="
echo "  Upstream: $GSTACK_SKILLS"
echo ""

for name in $(jq -r '.[] | select(.source == "upstream") | .name' "$CATALOG"); do
  upstream_file="$GSTACK_SKILLS/$name/SKILL.md"
  local_file="$SKILLS_DIR/$name/SKILL.md"

  if [ ! -f "$upstream_file" ]; then
    echo "  WARNING: upstream not found for '$name' at $upstream_file (skipping)"
    continue
  fi

  if [ ! -f "$local_file" ]; then
    echo "  WARNING: local skill '$name' has no SKILL.md (skipping)"
    continue
  fi

  if diff -q "$local_file" "$upstream_file" >/dev/null 2>&1; then
    echo "  UP-TO-DATE: $name"
  else
    echo "  CHANGED: $name"
    echo "  --- diff ---"
    diff --color=auto "$local_file" "$upstream_file" | head -20
    echo "  ..."
    CHANGES=$((CHANGES + 1))

    if [ "$APPLY" = true ]; then
      cp "$upstream_file" "$local_file"
      echo "  APPLIED: copied upstream version to skills/$name/SKILL.md"
    fi
  fi
  echo ""
done

echo "=== Sync Summary ==="
echo "  Skills with changes: $CHANGES"
if [ "$CHANGES" -gt 0 ] && [ "$APPLY" = false ]; then
  echo "  Run with --apply to copy upstream versions"
fi
exit 0
