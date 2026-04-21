#!/usr/bin/env bash
# Shared fixture builder for F000004 knowledge-integration tests (S000005).
#
# Materializes a knowledge dir tree under a caller-provided root, based on
# category specs. Each test case builds its fixture in mktemp -d so the user's
# $AI_KNOWLEDGE_DIR is never touched. No fixtures are committed under skills/.
#
# Usage (source from a bash test script — zsh word-splitting differs):
#   source scripts/test-helpers/knowledge.sh
#   root=$(mktemp -d)
#   build_knowledge_fixture "$root" "coding:always" "broken:malformed" "notes" "runbooks:on-demand:pricing"
#
# Spec grammar (each positional arg after root):
#   <cat>                              → category dir with no .knowledge.yml
#   <cat>:always                       → surface: always
#   <cat>:on-demand                    → surface: on-demand with empty triggers
#   <cat>:on-demand:<trigger>          → surface: on-demand with one trigger
#                                        (wrapped in double quotes if it contains
#                                        a space; v1 tests don't need multi-trigger
#                                        lists — that's c3)
#   <cat>:malformed                    → .knowledge.yml with invalid yml
#
# Each category gets:
#   - <cat>/a.md      containing "CANARY_<cat>_TOP"
#   - <cat>/sub/b.md  containing "CANARY_<cat>_NESTED"
#
# Idempotent on repeat calls within a test run (unique root each time).
# Prints the fixture root on stdout.

build_knowledge_fixture() {
  local root="$1"
  shift
  if [ -z "$root" ]; then
    echo "build_knowledge_fixture: root arg required" >&2
    return 1
  fi
  mkdir -p "$root"

  local spec cat rest mode trigger
  for spec in "$@"; do
    [ -z "$spec" ] && continue

    # Parse: <cat>[:mode[:trigger]]
    cat="${spec%%:*}"
    if [ "$cat" = "$spec" ]; then
      mode=""
      trigger=""
    else
      rest="${spec#*:}"
      mode="${rest%%:*}"
      if [ "$mode" = "$rest" ]; then
        trigger=""
      else
        trigger="${rest#*:}"
      fi
    fi

    mkdir -p "$root/$cat/sub"

    # Canary files (unique strings for unambiguous E2E assertions)
    printf '# %s top\nCANARY_%s_TOP\n' "$cat" "$cat" > "$root/$cat/a.md"
    printf '# %s nested\nCANARY_%s_NESTED\n' "$cat" "$cat" > "$root/$cat/sub/b.md"

    # Materialize .knowledge.yml per mode
    case "$mode" in
      always)
        printf 'surface: always\n' > "$root/$cat/.knowledge.yml"
        ;;
      on-demand)
        {
          printf 'surface: on-demand\n'
          if [ -z "$trigger" ]; then
            printf 'triggers: []\n'
          elif printf '%s' "$trigger" | grep -q ' '; then
            printf 'triggers: ["%s"]\n' "$trigger"
          else
            printf 'triggers: [%s]\n' "$trigger"
          fi
        } > "$root/$cat/.knowledge.yml"
        ;;
      malformed)
        # Intentionally invalid: unclosed list + unknown root key
        printf 'surface: always\ntriggers: [unclosed,\nxxx:: bad\n' > "$root/$cat/.knowledge.yml"
        ;;
      "")
        # No .knowledge.yml by design (tests "missing yml = silent skip")
        ;;
      *)
        echo "build_knowledge_fixture: unknown mode '$mode' for spec '$spec'" >&2
        return 1
        ;;
    esac
  done

  printf '%s\n' "$root"
}
