#!/usr/bin/env bash
# Auto-generate the readable general/custom doc-spec views from the
# spec/doc-spec.md registry — the same way generate-readme.sh generates README.md
# from the skill catalog. The spec/doc-spec.md registry is the ONE source of
# truth; these two files are generated views of it (grouped by `section`), so
# there is no second list to keep in sync.
#
# Writes <output-dir>/doc-general.md (section: common) and
#        <output-dir>/doc-custom.md  (section: custom).
#
# Idempotent — no timestamps, no run-specific metadata. validate.sh Check 23
# regenerates into a temp dir and diffs against docs/ to catch drift.
#
# Usage:
#   scripts/generate-doc-views.sh [--output-dir <dir>]   # default: docs

set -eu

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel 2>/dev/null || echo "$SCRIPT_DIR/..")"
DOC_SPEC_SH="$SCRIPT_DIR/doc-spec.sh"

# Default to the repo-root docs/ dir so the no-arg invocation writes the right place
# regardless of cwd (Check 23 passes an explicit --output-dir temp).
OUTPUT_DIR="$REPO_ROOT/docs"
while [ $# -gt 0 ]; do
  case "$1" in
    --output-dir) OUTPUT_DIR="${2:?--output-dir requires a value}"; shift 2 ;;
    --output-dir=*) OUTPUT_DIR="${1#--output-dir=}"; shift ;;
    -h|--help)
      echo "Usage: $0 [--output-dir <dir>]   # default: docs"
      exit 0
      ;;
    *) echo "generate-doc-views.sh: unknown argument '$1'" >&2; exit 2 ;;
  esac
done

# Render BOTH sections first, into vars. If the registry is invalid, --render
# exits non-zero (and emits a halt string to stdout); capturing into a var lets
# us fail cleanly here instead of truncating a real doc-*.md with the halt text
# (the silent-corruption class the doc-spec.sh --seed comment warns about).
GENERAL_BODY="$(bash "$DOC_SPEC_SH" --render general)" || {
  echo "generate-doc-views.sh: 'doc-spec.sh --render general' failed (invalid registry?) — not writing views." >&2; exit 1; }
CUSTOM_BODY="$(bash "$DOC_SPEC_SH" --render custom)" || {
  echo "generate-doc-views.sh: 'doc-spec.sh --render custom' failed (invalid registry?) — not writing views." >&2; exit 1; }

mkdir -p "$OUTPUT_DIR"

# doc-general.md — the section:common (general-tier) docs.
{
  echo "<!-- AUTO-GENERATED from scripts/generate-doc-views.sh — do not edit -->"
  echo "# Doc contract — general docs"
  echo ""
  echo "The general-tier docs (\`section: common\`) every adopting repo carries, generated from the \`spec/doc-spec.md\` registry. Do not hand-edit; regenerate with \`scripts/generate-doc-views.sh\`."
  echo ""
  printf '%s\n' "$GENERAL_BODY"
} > "$OUTPUT_DIR/doc-general.md"

# doc-custom.md — the section:custom (this-repo) docs.
{
  echo "<!-- AUTO-GENERATED from scripts/generate-doc-views.sh — do not edit -->"
  echo "# Doc contract — custom docs"
  echo ""
  echo "This repo's custom-tier docs (\`section: custom\`) beyond the general set, generated from the \`spec/doc-spec.md\` registry. Do not hand-edit; regenerate with \`scripts/generate-doc-views.sh\`."
  echo ""
  printf '%s\n' "$CUSTOM_BODY"
} > "$OUTPUT_DIR/doc-custom.md"
