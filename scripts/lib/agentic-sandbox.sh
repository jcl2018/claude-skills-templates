#!/usr/bin/env bash
# agentic-sandbox.sh — reusable repo-neutral agentic-test sandbox helpers (F000082).
#
# SOURCE this file (do not execute). It generalizes the throwaway-sandbox pattern
# that eval.sh --portability (tests/eval/lib/run-portability-case.sh) and the
# local-E2E harness (tests/e2e-local/lib/sandbox.sh) each grew independently, so the
# next topic that wants an agentic proof writes ~20 lines, not a new harness.
#
# It exposes THREE POSIX-sh helpers (YAGNI — only what the first consumer, the
# portability version-notification agentic test, actually calls; no speculative 4th):
#
#   mk_neutral_sandbox
#       Create a throwaway scratch dir that makes NO assumption about the current
#       repo — the agentic-test analogue of eval.sh --portability's stripped repo.
#       Prints (last line) the scratch dir path. Inside it writes a `.source`-ABSENT
#       manifest (`.skills-templates.json` with collection_version + upstream_url but
#       NO `.source` git checkout) so skills-update-check's checkout-independent path
#       is exercised. The caller points SKILLS_TEMPLATES_MANIFEST at
#       "<sandbox>/.skills-templates.json" and SKILLS_UPDATE_STATE_DIR at the sandbox.
#       Args: [<local-version>] (default 1.0.0) [<upstream-url>] (default the bare
#       repo placeholder; real callers override via mk_tagged_bare_upstream).
#
#   mk_tagged_bare_upstream <newer-version> [<parent-dir>]
#       `git init --bare` a throwaway repo and publish a `v<newer-version>` tag into
#       it (pushed from a tiny working clone), so `git ls-remote --tags` reads it.
#       Prints (last line) the bare repo path — feed it to skills-update-check via
#       SKILLS_UPDATE_REMOTE_URL. This is the neutral upstream: NO PATH-prepended
#       `git` shim (fragile on Windows Git Bash; reinvents the documented remote seam)
#       — it reuses the SKILLS_UPDATE_REMOTE_URL hook the same way e2e-local's bare
#       origin does.
#
#   run_preamble_via_claude <sandbox> <manifest> <state-dir> <remote-url> <max-budget-usd> [<prompt-out-path>]
#       Drive the skills-update-check skill preamble through `claude --print` (JSON
#       output) inside the neutral sandbox on `--model sonnet` (a real operator's
#       Claude Code default, so the cold-agent proof mirrors real behavior), capped
#       at <max-budget-usd> (the caller passes 1.00 — headroom over a cold sonnet
#       call's ~$0.55 context-read floor). The prompt asks the model to
#       run the update-check exactly as a skill preamble does and report a verdict
#       JSON {surfaced_nudge: bool, evidence: string} — PASS is the CALLER's job
#       (verdict == true). Prints the raw `claude` JSON on stdout; returns claude's
#       exit code. The caller extracts .result | fromjson via a CR-stripping jq.
#
#       EXPOSING THE PROMPT (T000057): if the optional 6th arg <prompt-out-path> is a
#       non-empty path, the EXACT `_rpc_prompt` sent to `claude --print` is written to
#       that file (verbatim, before the claude call), so the caller can render the
#       cold agent's prompt in a detailed report. This does NOT change what is sent to
#       claude — it only makes a copy available. Writing to a caller-provided path
#       (not a stderr marker) keeps the function's stdout the raw claude JSON and stays
#       clean under the `2>&1` capture. Absent/empty ⇒ no copy is written (unchanged).
#
# POSIX + LF. Windows Git Bash clean: no GNU-only flags; any jq consumption in a
# CALLER must go through a CR-stripping jq() wrapper (a Windows jq emits CRLF).
# All writes are confined to mktemp dirs; the real repo + ~/.claude are never touched.
#
# Teardown is the CALLER's responsibility (a single `rm -rf` of the returned dirs,
# typically via a trap) — these helpers create, they do not register cleanup, so a
# caller composes several sandboxes under one trap.

# Create a repo-neutral scratch sandbox with a `.source`-absent manifest.
# $1 = local collection_version (default 1.0.0); $2 = upstream_url (default a
# placeholder the caller overrides). Prints the sandbox dir (last line).
mk_neutral_sandbox() {
  _mns_ver="${1:-1.0.0}"
  _mns_upstream="${2:-https://example.invalid/neutral-upstream.git}"
  _mns_dir=$(mktemp -d "${TMPDIR:-/tmp}/cj-agentic-sbox-XXXXXX") || return 1
  # A `.source`-ABSENT manifest: collection_version + upstream_url present (so the
  # checkout-independent staleness path runs) but no `.source` key / no git checkout,
  # exactly the shape a remote/consumer install carries. Hand-written (no jq needed —
  # keeps the helper dependency-free); a Windows jq's CRLF never enters here.
  cat > "$_mns_dir/.skills-templates.json" <<JSON
{
  "collection_version": "$_mns_ver",
  "upstream_url": "$_mns_upstream"
}
JSON
  printf '%s\n' "$_mns_dir"
}

# `git init --bare` a throwaway repo tagged v<newer> for SKILLS_UPDATE_REMOTE_URL.
# $1 = the newer version (bare X.Y.Z, no leading v); $2 = optional parent dir (a new
# mktemp base otherwise). Prints the bare repo path (last line).
mk_tagged_bare_upstream() {
  _mtu_ver="${1:?newer version required (X.Y.Z)}"
  _mtu_parent="${2:-$(mktemp -d "${TMPDIR:-/tmp}/cj-agentic-up-XXXXXX")}" || return 1
  _mtu_bare="$_mtu_parent/upstream.git"
  _mtu_work="$_mtu_parent/seed"

  git init --quiet --bare "$_mtu_bare" || return 1

  # Seed the tag from a tiny working clone: a bare repo cannot `git tag` directly, so
  # commit once in a work clone and push the tag. Isolate git identity + config so a
  # missing user.name / a hostile global hook never breaks the seed (hermetic).
  git init --quiet "$_mtu_work" || return 1
  (
    cd "$_mtu_work" || exit 1
    git config user.email "agentic-sandbox@example.invalid"
    git config user.name  "agentic-sandbox"
    git config commit.gpgsign false
    : > .keep
    git add .keep
    git commit --quiet -m "seed" || exit 1
    git tag "v$_mtu_ver" || exit 1
    git push --quiet "$_mtu_bare" "v$_mtu_ver" || exit 1
  ) || return 1

  printf '%s\n' "$_mtu_bare"
}

# Drive the skills-update-check skill preamble through `claude --print` in the
# neutral sandbox and print the raw claude JSON. Returns claude's exit code.
# $1=sandbox $2=manifest-path $3=state-dir $4=remote-url $5=max-budget-usd
# $6=optional prompt-out-path (write the exact prompt sent to claude here, verbatim).
# The verdict schema is {surfaced_nudge: bool, evidence: string} — the caller
# extracts + judges it (PASS iff surfaced_nudge == true).
run_preamble_via_claude() {
  _rpc_sandbox="${1:?sandbox dir required}"
  _rpc_manifest="${2:?manifest path required}"
  _rpc_state="${3:?state dir required}"
  _rpc_remote="${4:?remote url required}"
  _rpc_budget="${5:-1.00}"
  _rpc_prompt_out="${6:-}"

  # The update-check script itself (resolved from this lib's sibling scripts/ dir —
  # this file lives at scripts/lib/agentic-sandbox.sh, so scripts/ is one up).
  _rpc_lib_dir=$(CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]:-$0}")" && pwd)
  _rpc_uc="$_rpc_lib_dir/../skills-update-check"

  # The prompt: run the update-check exactly as a skill preamble does (the same
  # env-seamed invocation), then report whether the operator would SEE an upgrade
  # nudge — not merely that some banner text exists. The schema forces a
  # machine-checkable verdict, mirroring run-portability-case.sh's
  # {degraded_gracefully, evidence} shape.
  _rpc_prompt="You are standing in for a Claude Code skill preamble in a throwaway sandbox at $_rpc_sandbox. This install is STALE: its manifest records an older collection_version than the newer release published on its upstream. Run the passive update check exactly as a skill preamble would, by executing this command and reading its output:

  SKILLS_TEMPLATES_MANIFEST='$_rpc_manifest' SKILLS_UPDATE_STATE_DIR='$_rpc_state' SKILLS_UPDATE_REMOTE_URL='$_rpc_remote' bash '$_rpc_uc'

A skill preamble SURFACES an available upgrade to the operator when that command prints a line beginning 'SKILLS_UPGRADE_AVAILABLE <local> <remote>'. Report your verdict as JSON: {\"surfaced_nudge\": true|false, \"evidence\": \"<one-line quote of the actual command output>\"}. surfaced_nudge is true ONLY if you actually ran the command AND its output contained a SKILLS_UPGRADE_AVAILABLE line naming a newer remote version — relay it to the operator. If the command produced no such line, surfaced_nudge is false."

  _rpc_schema='{"type":"object","properties":{"surfaced_nudge":{"type":"boolean"},"evidence":{"type":"string"}},"required":["surfaced_nudge","evidence"],"additionalProperties":false}'

  # T000057: expose the EXACT prompt to the caller (for the detailed report) by
  # writing it verbatim to the caller-provided path BEFORE the claude call. This is a
  # copy only — the identical $_rpc_prompt is still what `claude -p` receives below.
  # printf '%s' (no trailing newline) preserves the prompt byte-for-byte.
  if [ -n "$_rpc_prompt_out" ]; then
    printf '%s' "$_rpc_prompt" > "$_rpc_prompt_out" 2>/dev/null || true
  fi

  # HOME stays intact for auth (macOS OAuth / subscription login lives there); only
  # the update-check's manifest + state surface is redirected via env (above, inside
  # the prompt's command). --add-dir grants the sandbox so the model can run there.
  claude -p "$_rpc_prompt" \
    --print \
    --output-format json \
    --json-schema "$_rpc_schema" \
    --add-dir "$_rpc_sandbox" \
    --model sonnet \
    --max-budget-usd "$_rpc_budget" \
    --no-session-persistence \
    --permission-mode bypassPermissions \
    --allowedTools "Bash,Read" 2>&1
}
