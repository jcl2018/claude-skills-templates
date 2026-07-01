#!/usr/bin/env bash
# Sandbox provisioning for the local-E2E harness (scripts/e2e-local.sh).
#
# SOURCE this file (do not execute). It exposes two functions:
#   e2e_sandbox_provision <src_repo_root>   -> prints the sandbox clone path on stdout
#   e2e_sandbox_teardown  <sandbox_clone>   -> removes the whole mktemp base
#
# A sandbox is:
#   * a mktemp clone of the repo (a LOCAL path clone — fast, no network), plus
#   * a `.cj-e2e-sandbox` marker at the clone root (the Part-A seam guard #2 — the
#     harness also sets CJ_GOAL_E2E_AUTO=1), plus
#   * a LOCAL bare origin (`git init --bare`) repointed as `origin`. The bare
#     origin accepts `git push` but has no GitHub remote, so `gh pr create` cannot
#     open a real PR — the sole `task` auto-ship backstop (task's /ship diff-review
#     AUQ is already suppressed, so this no-remote stop is load-bearing).
#
# All writes are confined to the tmpdir; the real repo is never touched.

# Provision a sandbox from <src_repo_root>. Prints the clone path (last line).
e2e_sandbox_provision() {
  local src="${1:?source repo root required}"
  local base clone bare branch
  base=$(mktemp -d "${TMPDIR:-/tmp}/cj-e2e-XXXXXX") || return 1
  clone="$base/clone"
  bare="$base/origin.git"

  git init --quiet --bare "$bare" || return 1
  git clone --quiet "$src" "$clone" || return 1
  git -C "$clone" remote set-url origin "$bare" || return 1

  # Push the current branch to the bare origin so the sandbox has an upstream to
  # push to at the /ship boundary (where gh pr create is then blocked).
  branch=$(git -C "$clone" symbolic-ref --short HEAD 2>/dev/null || echo "main")
  git -C "$clone" push --quiet origin "$branch" 2>/dev/null || true

  # The Part-A seam guard marker (#2). It is gitignored in the repo, so it stays
  # untracked in the clone (validate.sh Check 29 passes: only a TRACKED marker fails).
  : > "$clone/.cj-e2e-sandbox"

  printf '%s\n' "$clone"
}

# Tear down a sandbox given its clone path. Removes the whole mktemp base.
e2e_sandbox_teardown() {
  local clone="${1:?sandbox clone path required}"
  case "$clone" in
    */clone) rm -rf "$(dirname "$clone")" ;;
    *)       rm -rf "$clone" ;;
  esac
}
