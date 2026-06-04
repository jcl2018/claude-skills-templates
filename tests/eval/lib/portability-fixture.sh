#!/usr/bin/env bash
# portability-fixture.sh — prepare a STRIPPED, .source-neutralized scratch repo
# + a scratch skill-resolution dir for the Layer-2 portability eval
# (scripts/eval.sh --portability). F000047 / S000083.
#
# WHY a new helper (not a parameterization of seed-fixture.sh): the default eval
# fixture does `cp -RP fixture/. tmpdir + git init`, which leaves the engine's
# `.source` fall-through pointing at the REAL workbench clone. Inside a git-init'd
# scratch tmpdir, `git rev-parse --show-toplevel` returns the tmpdir (no
# scripts/cj-*.sh), so a CJ_ engine FALLS THROUGH to the manifest `.source` — which,
# unredirected, points back at the real workbench. A skill "run in the stripped
# repo" would then happily reach the real scripts/ and prove NOTHING. This helper
# makes the strip actually strip:
#   1. Builds a stripped scratch REPO (git-init'd) with NONE of the workbench's
#      portability-bearing artifacts: no scripts/, no CLAUDE.md, no root config,
#      no work-items/, no TODOS.md. (The skill must degrade gracefully here.)
#   2. Builds a scratch SKILL-RESOLUTION dir ($scratch_claude) holding a
#      .skills-templates.json whose `.source` points AT THE STRIPPED REPO (so any
#      `.source` fall-through resolves into the stripped repo, not the real
#      workbench) — the crux of the test.
#
# It deliberately does NOT scrub HOME (macOS OAuth/keychain auth lives there) —
# scripts/eval.sh --portability redirects ONLY the skill-resolution surface via a
# scratch CLAUDE_CONFIG_DIR-style dir + the neutralized manifest, leaving the
# auth-bearing parts of HOME intact so the subsequent `claude -p` authenticates.
#
# Usage:
#   portability-fixture.sh <repo_root> <scratch_repo_dir> <scratch_claude_dir>
# where <repo_root> is the real workbench (source of the skill dir to deploy),
#       <scratch_repo_dir>   is an empty tmpdir to populate as the stripped repo,
#       <scratch_claude_dir> is an empty tmpdir to populate as the resolution dir.
# Exit 0 = ready; non-zero = a setup step failed.

set -euo pipefail

repo_root="${1:?repo_root required}"
scratch_repo="${2:?scratch_repo dir required}"
scratch_claude="${3:?scratch_claude dir required}"

[ -d "$repo_root" ]    || { echo "portability-fixture: repo_root not a dir: $repo_root" >&2; exit 1; }
[ -d "$scratch_repo" ] || { echo "portability-fixture: scratch_repo not a dir: $scratch_repo" >&2; exit 1; }
[ -d "$scratch_claude" ] || { echo "portability-fixture: scratch_claude not a dir: $scratch_claude" >&2; exit 1; }

# ---- 1. stripped scratch repo: a bare git repo with NO workbench artifacts ----
# We intentionally create a minimal, unrelated project tree so the skill runs in a
# repo that "has never seen this workbench": no scripts/, no CLAUDE.md, no root
# config (skills-catalog.json / cj-document-release.json / VERSION), no TODOS.md,
# no work-items/. A lone README so the dir is a believable project.
cat > "$scratch_repo/README.md" <<'MD'
# scratch-target

A stripped scratch repo for the portability eval. It deliberately has NONE of the
workbench's repo-local artifacts (no scripts/, CLAUDE.md, root config, TODOS.md,
or work-items/) so a skill run here must degrade gracefully rather than crash.
MD

(
  cd "$scratch_repo"
  git init -q
  git -c user.email=eval@local -c user.name=eval-harness -c commit.gpgsign=false add -A
  git -c user.email=eval@local -c user.name=eval-harness -c commit.gpgsign=false commit -q -m "stripped scratch repo seed"
) || { echo "portability-fixture: git init/commit of scratch repo failed" >&2; exit 1; }

# ---- 2. scratch skill-resolution dir (.source neutralized) --------------------
# Deploy the SKILL DIR(s) under $scratch_claude/skills/ as real copies so the
# `/`-command resolves, and write a manifest whose `.source` points AT THE
# STRIPPED REPO. Any engine `.source` fall-through then lands in the stripped
# repo (which has no scripts/cj-*.sh), NOT the real workbench — proving the strip.
#
# We copy the skill dirs that the case may invoke. The caller passes the skill
# name(s) via the env var CJ_PA_SKILLS (space-separated); default: CJ_suggest.
mkdir -p "$scratch_claude/skills"
_skills="${CJ_PA_SKILLS:-CJ_suggest}"
for _sk in $_skills; do
  if [ -d "$repo_root/skills/$_sk" ]; then
    cp -RP "$repo_root/skills/$_sk" "$scratch_claude/skills/$_sk"
  fi
done

# The neutralized manifest: `.source` -> the STRIPPED repo (NOT the workbench).
# `collection_version` is cosmetic here. The update-check preamble reads `.source`
# and finds scripts/skills-update-check ABSENT in the stripped repo -> the `[ -x ]`
# guard fails and the `|| true` swallows it (fail-soft), so no crash.
cat > "$scratch_claude/.skills-templates.json" <<EOF
{
  "source": "$scratch_repo",
  "collection_version": "0.0.0-portability-eval",
  "skills": {}
}
EOF

echo "PORTABILITY_FIXTURE_READY"
echo "  scratch_repo:   $scratch_repo"
echo "  scratch_claude: $scratch_claude"
echo "  source ->       $scratch_repo (neutralized; NOT the real workbench)"
exit 0
