#!/usr/bin/env bash
# portability-version-agentic.test.sh — the AGENTIC local proof that the
# deploy/install harness's version-notification actually SURFACES an upgrade nudge
# to a human (F000082). Portability's local-hook + agentic test level — the
# counterpart to the DETERMINISTIC portability-version-check (a stubbed-ls-remote
# unit test): where the deterministic test proves the SCRIPT emits the banner, this
# proves an AGENT running the skill preamble in a stale install actually RELAYS the
# nudge. That is the green-but-inert blind spot the agentic layer closes.
#
# LOCAL-ONLY. Gated on CJ_E2E_LOCAL=1 AND a usable claude login (ANTHROPIC_API_KEY,
# or a `claude auth login` CONFIRMED by a live probe) + claude + gh present — the
# exact e2e-local.sh gate (a stored login is NOT trusted blindly: some managed
# environments report logged-in yet a `claude -p` subprocess 401s). With the flag
# unset or any prerequisite missing it SKIPs (exit 0, NO `claude` call), so
# scripts/test.sh and CI never touch a model. mode:agentic ⇒ tier: local-only, so
# /CJ_test_run runs it only under --e2e/--all (a default free run SKIPs it).
#
# When live: builds a repo-NEUTRAL sandbox (a .source-absent manifest) + a
# `git init --bare` upstream tagged v<newer> via SKILLS_UPDATE_REMOTE_URL (the
# documented remote seam — NO PATH-prepended `git` shim), drives the
# skills-update-check skill preamble through `claude --print` (JSON, sonnet, budget $1.00),
# and extracts a {surfaced_nudge, evidence} verdict — PASS iff the agent surfaces the
# SKILLS_UPGRADE_AVAILABLE nudge, not merely that the banner text exists.
#
# Exit: 0 = SKIP (flag/prereq missing) OR PASS (agent surfaced the nudge).
#       non-zero = a real FAIL (the agent did not surface the nudge, or an infra error).

set -euo pipefail

SCRIPT_DIR=$(CDPATH='' cd "$(dirname "$0")" && pwd)
REPO_ROOT=$(CDPATH='' cd "$SCRIPT_DIR/.." && pwd)
LIB="$REPO_ROOT/scripts/lib/agentic-sandbox.sh"

# CR-stripping jq wrapper (a Windows jq emits CRLF; any $(jq ...) fed into parsing
# must strip it). No-op on Unix.
jq() { command jq "$@" | tr -d '\r'; }

# ---- Pre-flight gate: SKIP (exit 0) unless the flag AND all prereqs hold --------
# In CI + a normal test.sh this SKIPs here and never reaches claude. The auth block's
# live probe fires ONLY on the interactive login path (ANTHROPIC_API_KEY unset AND a
# logged-in `claude auth status`), itself gated behind CJ_E2E_LOCAL=1 + claude — so
# CI (key set) and test.sh (flag unset) never hit it.
skip() { echo "SKIP: portability-version-agentic — $1 (this test is local-only; set CJ_E2E_LOCAL=1 with a usable claude login [ANTHROPIC_API_KEY or 'claude auth login'] + claude + gh to run)"; exit 0; }

[ "${CJ_E2E_LOCAL:-}" = "1" ] || skip "CJ_E2E_LOCAL is not set"

_missing=""
command -v claude >/dev/null 2>&1 || _missing="$_missing claude"
command -v gh     >/dev/null 2>&1 || _missing="$_missing gh"
command -v git    >/dev/null 2>&1 || _missing="$_missing git"
[ -f "$LIB" ] || _missing="$_missing scripts/lib/agentic-sandbox.sh"
[ -x "$REPO_ROOT/scripts/skills-update-check" ] || _missing="$_missing skills-update-check"
if [ -n "$_missing" ]; then
  skip "missing prerequisites:$_missing"
fi

# Auth: the subprocess `claude -p` build needs USABLE subprocess credentials. Accept
# an explicit ANTHROPIC_API_KEY OR a `claude auth login`, but a stored login is NOT
# proof a fresh subprocess authenticates — confirm the login path with a tiny live
# probe (free on a subscription), never a false pass. `timeout` is used when present.
if [ -n "${ANTHROPIC_API_KEY:-}" ]; then
  _auth="api-key"
elif claude auth status 2>/dev/null | grep -qE '"loggedIn"[[:space:]]*:[[:space:]]*true'; then
  if command -v timeout >/dev/null 2>&1; then
    _probe=$(timeout 60 claude -p "reply with the single word: ok" --max-budget-usd 0.05 2>&1 || true)
  else
    _probe=$(claude -p "reply with the single word: ok" --max-budget-usd 0.05 2>&1 || true)
  fi
  if printf '%s' "$_probe" | grep -qiE '401|unauthor|invalid.*credential|failed to authenticate'; then
    skip "claude reports logged-in but a fresh subprocess could not authenticate (a 'claude -p' probe returned an auth error) — run 'claude auth login' here, or export ANTHROPIC_API_KEY"
  fi
  _auth="claude-login"
else
  skip "no usable claude credentials — export ANTHROPIC_API_KEY, or run 'claude auth login'"
fi
echo "[PORTABILITY-AGENTIC] auth: $_auth"

# ---- Live path: build the neutral sandbox + tagged upstream, drive claude --------
# shellcheck source=scripts/lib/agentic-sandbox.sh
. "$LIB"

BUDGET="${PORTABILITY_AGENTIC_BUDGET_USD:-1.00}"
LOCAL_VER="6.0.100"     # the STALE installed version recorded in the sandbox manifest
NEWER_VER="9.9.9"       # the newer release published on the tagged bare upstream

echo "[PORTABILITY-AGENTIC] provisioning neutral sandbox + tagged bare upstream (local=$LOCAL_VER, upstream=$NEWER_VER) ..."
SANDBOX=$(mk_neutral_sandbox "$LOCAL_VER" "https://github.com/jcl2018/claude-skills-templates.git") || { echo "FAIL: portability-version-agentic (neutral sandbox provision failed)"; exit 1; }
BARE=$(mk_tagged_bare_upstream "$NEWER_VER") || { echo "FAIL: portability-version-agentic (tagged bare upstream provision failed)"; rm -rf "$SANDBOX"; exit 1; }
STATE=$(mktemp -d "${TMPDIR:-/tmp}/cj-agentic-state-XXXXXX")
MANIFEST="$SANDBOX/.skills-templates.json"
# Clean up all three throwaway dirs regardless of how we exit.
trap 'rm -rf "$SANDBOX" "$(dirname "$BARE")" "$STATE"' EXIT INT TERM

# Sanity pre-check (deterministic, no model): the seam itself must produce the banner,
# so a FAIL below is unambiguously the AGENT not surfacing it, not a broken sandbox.
_pre=$(SKILLS_TEMPLATES_MANIFEST="$MANIFEST" SKILLS_UPDATE_STATE_DIR="$STATE" SKILLS_UPDATE_REMOTE_URL="$BARE" bash "$REPO_ROOT/scripts/skills-update-check" 2>&1 || true)
if ! printf '%s\n' "$_pre" | grep -q '^SKILLS_UPGRADE_AVAILABLE '; then
  echo "FAIL: portability-version-agentic (sandbox pre-check did not emit SKILLS_UPGRADE_AVAILABLE — the seam is broken, not the agent): $_pre"
  exit 1
fi
# Reset the update-check cache so the agent's run re-reads the remote (the pre-check
# above wrote a 24h cache; a fresh state dir keeps the model's run honest).
rm -rf "$STATE"; STATE=$(mktemp -d "${TMPDIR:-/tmp}/cj-agentic-state-XXXXXX")

echo "[PORTABILITY-AGENTIC] driving the skills-update-check preamble through claude --print (budget \$$BUDGET) ..."
OUTPUT=$(run_preamble_via_claude "$SANDBOX" "$MANIFEST" "$STATE" "$BARE" "$BUDGET") && CLAUDE_RC=0 || CLAUDE_RC=$?

VERDICT=$(printf '%s' "$OUTPUT" | jq -r '.result | fromjson | .surfaced_nudge' 2>/dev/null || echo "parse-error")
EVIDENCE=$(printf '%s' "$OUTPUT" | jq -r '.result | fromjson | .evidence' 2>/dev/null || echo "")
COST=$(printf '%s' "$OUTPUT" | jq -r '.total_cost_usd // 0' 2>/dev/null || echo 0)

if [ "$CLAUDE_RC" -ne 0 ]; then
  echo "FAIL: portability-version-agentic (claude exit $CLAUDE_RC, subtype: $(printf '%s' "$OUTPUT" | jq -r '.subtype // "unknown"' 2>/dev/null))"
  echo "  cost_usd: $COST" >&2
  echo "  output: $OUTPUT" >&2
  exit 1
fi

if [ "$VERDICT" = "true" ]; then
  echo "PASS: portability-version-agentic (\$$COST) — the agent surfaced the upgrade nudge: $EVIDENCE"
  exit 0
else
  echo "FAIL: portability-version-agentic (\$$COST) — the agent did NOT surface the upgrade nudge (verdict=$VERDICT): $EVIDENCE"
  echo "  output: $OUTPUT" >&2
  exit 1
fi
