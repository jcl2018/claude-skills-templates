#!/usr/bin/env bash
# Dependency graph visualization with cycle detection.
# Advisory — exits 0 normally, warns on cycles.

. "$(dirname "$0")/lib.sh"
init

echo "=== Skill Dependency Graph ==="
echo ""

# Print dependency tree
jq -r '
  .[] |
  .name as $name |
  .portability as $port |
  .depends.skills as $deps |
  if ($deps | length) > 0 then
    "\($name) (\($port))",
    ($deps[] | "  -> \(.)")
  else
    "\($name) (\($port))"
  end
' "$CATALOG"

echo ""

# Cycle detection using jq topological sort
# If topo sort can't order all nodes, there's a cycle.
CYCLE_CHECK=$(jq -r '
  # Build node list and edge list
  [.[] | .name] as $nodes |
  [.[] | .name as $from | .depends.skills[] | {from: $from, to: .}] as $edges |

  # Compute in-degrees
  [$nodes[] | {key: ., value: 0}] | from_entries as $base_deg |
  reduce $edges[] as $e ($base_deg; .[$e.to] = (.[$e.to] + 1)) |

  # Kahn topological sort
  . as $in_deg |
  {
    queue: [to_entries[] | select(.value == 0) | .key],
    sorted: [],
    in_deg: $in_deg,
    edges: $edges
  } |
  until(.queue | length == 0;
    .queue[0] as $node |
    .queue = .queue[1:] |
    .sorted += [$node] |
    reduce (.edges[] | select(.from == $node) | .to) as $dep (.;
      .in_deg[$dep] = (.in_deg[$dep] - 1) |
      if .in_deg[$dep] == 0 then .queue += [$dep] else . end
    )
  ) |
  if (.sorted | length) < ($nodes | length) then
    "CYCLE_DETECTED"
  else
    "OK"
  end
' "$CATALOG" 2>/dev/null)

if [ "$CYCLE_CHECK" = "CYCLE_DETECTED" ]; then
  echo "WARNING: Circular dependencies detected in the skill graph!"
  echo "  Run 'jq . skills-catalog.json' and inspect depends.skills fields."
  echo ""
fi

echo "=== Summary ==="
echo "  Total skills: $(jq 'length' "$CATALOG")"
echo "  Standalone:   $(jq '[.[] | select(.portability == "standalone")] | length' "$CATALOG")"
echo "  Pipeline:     $(jq '[.[] | select(.portability == "pipeline")] | length' "$CATALOG")"

if [ "$CYCLE_CHECK" = "CYCLE_DETECTED" ]; then
  exit 1
fi
exit 0
