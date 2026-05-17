#!/usr/bin/env bash
# Plant-test for the F3 fail-closed scrub assert in run-case.sh (D000023,
# Approach C, Success Criterion 3).
#
# WHY THIS EXISTS: the fail-closed post-assert in run-case.sh is the guard
# against a malicious eval case exfiltrating a credential from env. If a future
# edit narrows the assert regex, broadens the allowlist, or reorders the spawn
# before the assert, the protection silently regresses to fail-OPEN and nothing
# notices. This test deliberately plants secret-shaped vars and asserts that
# run-case.sh ABORTS NON-ZERO *before* spawning the model. It runs with ZERO
# API cost (a `claude` stub on PATH proves the spawn is never reached) so it is
# safe to run on every ref in CI and locally.
#
# Lives under tests/eval/lib/ so scripts/eval.sh's discover_cases() skips it
# (it explicitly `continue`s on lib/ and schemas/) — this is a regression
# harness, not an eval case.
#
# Exit 0 = assert fired correctly for every planted var (PASS).
# Exit 1 = the assert FAILED to fire, or fired for the wrong reason (FAIL —
#          the fail-closed protection has regressed).

set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
run_case="$script_dir/run-case.sh"

[ -f "$run_case" ] || { echo "plant-test FAIL: run-case.sh not found at $run_case" >&2; exit 1; }

workdir=$(mktemp -d)
trap 'rm -rf "$workdir"' EXIT INT TERM

# A `claude` stub: if run-case.sh ever reaches the spawn (i.e. the assert
# failed open), the stub drops a sentinel file. Its presence => fail-open
# regression => this test FAILS. The stub also exits non-zero so a fail-open
# run still doesn't accidentally look green for the wrong reason.
stub_bin="$workdir/bin"
mkdir -p "$stub_bin"
cat > "$stub_bin/claude" <<EOF
#!/usr/bin/env bash
if [ "\${1:-}" = "--version" ]; then echo "claude-stub 0.0.0-planttest"; exit 0; fi
touch "$workdir/CLAUDE_WAS_SPAWNED"
echo '{"result":"{}","subtype":"stub","is_error":false,"total_cost_usd":0}'
exit 0
EOF
chmod +x "$stub_bin/claude"

# Minimal throwaway case dir so run-case.sh clears its input-file preconditions
# (prompt.md + expected.schema.json present) AND its fixture-seed step
# (seed-fixture.sh runs `git add -A && git commit`; an empty fixture/ makes the
# commit fail with "nothing to commit" and run-case.sh would abort at the seed
# BEFORE reaching the scrub/assert). The fixture therefore must contain at
# least one regular file so the seed commit succeeds and execution reaches the
# fail-closed assert under test.
case_dir="$workdir/case"
mkdir -p "$case_dir/fixture"
echo "plant-test prompt (never sent — assert must fire first)" > "$case_dir/prompt.md"
printf '{"type":"object"}\n' > "$case_dir/expected.schema.json"
echo "plant-test fixture seed file (makes seed-fixture.sh git commit non-empty)" \
  > "$case_dir/fixture/.plant-test-seed"

overall_rc=0

run_one() {
  # $1 = planted var name, $2 = human label
  local var="$1" label="$2"
  rm -f "$workdir/CLAUDE_WAS_SPAWNED"

  set +e
  env -i \
    HOME="$HOME" \
    PATH="$stub_bin:/usr/bin:/bin" \
    "$var=planted-fake-value-do-not-use" \
    bash "$run_case" "$workdir/skills" "$workdir/templates" "_security" "$case_dir" \
    >"$workdir/out.txt" 2>&1
  local rc=$?
  set -e

  local ok=1

  if [ "$rc" -eq 0 ]; then
    echo "  [$label] FAIL: run-case.sh exited 0 — the fail-closed assert did NOT fire (fail-OPEN regression)" >&2
    ok=0
  fi
  if [ -f "$workdir/CLAUDE_WAS_SPAWNED" ]; then
    echo "  [$label] FAIL: claude was spawned despite a planted secret-shaped var (assert ran too late / failed open)" >&2
    ok=0
  fi
  if ! grep -q 'fail-closed scrub assert' "$workdir/out.txt"; then
    echo "  [$label] FAIL: aborted, but not via the fail-closed scrub assert (wrong failure reason):" >&2
    sed 's/^/      /' "$workdir/out.txt" >&2
    ok=0
  fi

  if [ "$ok" -eq 1 ]; then
    echo "  [$label] PASS: run-case.sh aborted non-zero via the fail-closed assert before spawning claude (planted: $var)"
  else
    overall_rc=1
  fi
}

echo "plant-test: exercising run-case.sh fail-closed scrub assert (untrusted path, GITHUB_REF unset)..."
# Case 1: the exact credential F3 is about.
run_one ANTHROPIC_API_KEY "ANTHROPIC_API_KEY"
# Case 2: an UNENUMERATED secret-shaped var — proves the allowlist posture
# (not a denylist): a brand-new *_API_KEY the old denylist never listed must
# still be caught.
run_one FOO_API_KEY "unenumerated *_API_KEY (allowlist, not denylist)"
# Case 3: a *_TOKEN variant — covers the _TOKEN arm of the assert regex.
run_one SOME_SERVICE_TOKEN "*_TOKEN variant"

if [ "$overall_rc" -eq 0 ]; then
  echo "plant-test PASS: fail-closed scrub assert fires for every planted secret-shaped var; spawn never reached."
else
  echo "plant-test FAIL: the fail-closed scrub assert has regressed (see failures above)." >&2
fi
exit "$overall_rc"
