#!/usr/bin/env bash
# Auto-generate the readable general/custom doc-spec views from the doc-spec.md
# registry — the same way generate-readme.sh generates README.md from the skill
# catalog. The root doc-spec.md registry is the ONE source of truth; these two
# files are generated views of it (grouped by `section`), so there is no second
# list to keep in sync.
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
    --output-dir) OUTPUT_DIR="$2"; shift 2 ;;
    --output-dir=*) OUTPUT_DIR="${1#--output-dir=}"; shift ;;
    -h|--help)
      echo "Usage: $0 [--output-dir <dir>]   # default: docs"
      exit 0
      ;;
    *) echo "generate-doc-views.sh: unknown argument '$1'" >&2; exit 2 ;;
  esac
done

mkdir -p "$OUTPUT_DIR"

# doc-general.md — the section:common (general-tier) docs.
{
  echo "<!-- AUTO-GENERATED from scripts/generate-doc-views.sh — do not edit -->"
  echo "# Doc contract — general docs"
  echo ""
  echo "The general-tier docs (\`section: common\`) every adopting repo carries, generated from the \`doc-spec.md\` registry. Do not hand-edit; regenerate with \`scripts/generate-doc-views.sh\`."
  echo ""
  bash "$DOC_SPEC_SH" --render general
} > "$OUTPUT_DIR/doc-general.md"

# doc-custom.md — the section:custom (this-repo) docs.
{
  echo "<!-- AUTO-GENERATED from scripts/generate-doc-views.sh — do not edit -->"
  echo "# Doc contract — custom docs"
  echo ""
  echo "This repo's custom-tier docs (\`section: custom\`) beyond the general set, generated from the \`doc-spec.md\` registry. Do not hand-edit; regenerate with \`scripts/generate-doc-views.sh\`."
  echo ""
  bash "$DOC_SPEC_SH" --render custom
} > "$OUTPUT_DIR/doc-custom.md"
