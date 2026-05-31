#!/usr/bin/env bash
# Install per-machine git hooks for the skill workbench.
# - pre-commit: runs validate.sh + per-skill checks
# - post-merge: re-deploys skills + templates after pulls that touch them (D000013),
#               auto-updates Phase 3 lifecycle gates on touched work-items (F000011),
#               and writes a doc-sync marker on main-moving merges (F000028).
# - post-rewrite: writes the same doc-sync marker on rebase pulls (F000028).
# Usage: ./scripts/setup-hooks.sh

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# --git-common-dir resolves to the shared .git for both regular checkouts and
# worktrees (where $REPO_ROOT/.git is a file, not a directory). It returns an
# absolute path in worktrees but a relative ".git" in main checkouts, so
# normalize to absolute by prefixing REPO_ROOT when relative.
GIT_COMMON_DIR="$(git -C "$REPO_ROOT" rev-parse --git-common-dir 2>/dev/null)"
case "$GIT_COMMON_DIR" in
  /*) HOOK_DIR="$GIT_COMMON_DIR/hooks" ;;
  *)  HOOK_DIR="$REPO_ROOT/$GIT_COMMON_DIR/hooks" ;;
esac

if [ ! -d "$HOOK_DIR" ]; then
  echo "ERROR: cannot resolve git hooks directory. Are you in a git repo?" >&2
  exit 1
fi

# Sentinel embedded in every hook body this script writes (see the heredocs
# below). Lets install_hook tell a workbench-owned hook from an
# operator/tooling-owned one (Husky, lefthook, a local debug hook) so a custom
# hook is never blindly destroyed. grep -F substring match: tolerates the
# post-merge body's trailing '.' after the sentinel.
SENTINEL='# Auto-installed by scripts/setup-hooks.sh'

# install_hook <name>   (hook body on stdin)
# Clobber-safe, atomic install of .git/hooks/<name>:
#   - Stage the body into a temp file in $HOOK_DIR and chmod +x it BEFORE the
#     target is touched. The live hook is only ever changed by an atomic mv of
#     a fully-written file (same dir => same filesystem => rename(2)), so a
#     mid-write/chmod failure leaves the prior hook intact — never a truncated
#     or non-executable hook (the prior `cat >` truncated the target up front;
#     setup.sh's `|| echo WARN >&2` then masked the partial write).
#   - If an existing hook lacks $SENTINEL it is operator/tooling-owned: back it
#     up to <hook>.bak (timestamped if .bak exists) and warn, instead of
#     silently destroying it. If the backup itself fails, abort WITHOUT
#     clobbering — losing an un-backed custom hook is the one unacceptable
#     outcome.
#   - An existing hook that already carries $SENTINEL is our own prior install:
#     refreshed in place, no backup, so repeated setup.sh runs stay a no-op.
# Returns non-zero on failure so setup.sh's `|| echo WARN >&2` guard fires.
install_hook() {
  hook_name="$1"
  hook_path="$HOOK_DIR/$hook_name"
  tmp="$(mktemp "$HOOK_DIR/.${hook_name}.XXXXXX" 2>/dev/null)" || {
    echo "ERROR: cannot create temp file in $HOOK_DIR for $hook_name hook" >&2
    return 1
  }
  if ! cat > "$tmp"; then
    rm -f "$tmp"
    echo "ERROR: failed to write $hook_name hook body" >&2
    return 1
  fi
  if ! chmod +x "$tmp"; then
    rm -f "$tmp"
    echo "ERROR: chmod +x failed for $hook_name hook" >&2
    return 1
  fi
  if [ -e "$hook_path" ] && ! grep -qF "$SENTINEL" "$hook_path" 2>/dev/null; then
    backup="$hook_path.bak"
    [ -e "$backup" ] && backup="$hook_path.bak.$(date +%Y%m%d%H%M%S)"
    if ! cp -p "$hook_path" "$backup"; then
      rm -f "$tmp"
      echo "ERROR: existing .git/hooks/$hook_name is not workbench-owned and could not be backed up — refusing to overwrite (your custom hook is untouched)" >&2
      return 1
    fi
    echo "WARN: existing .git/hooks/$hook_name is not workbench-owned — backed up to $(basename "$backup") before installing the workbench hook" >&2
  fi
  if ! mv "$tmp" "$hook_path"; then
    rm -f "$tmp"
    echo "ERROR: failed to install $hook_name hook" >&2
    return 1
  fi
}

rc=0

if install_hook pre-commit << 'HOOK'
#!/usr/bin/env bash
# Auto-installed by scripts/setup-hooks.sh
# Runs repo-wide validation. Per-skill skill-check.sh was retired (see TODOS.md);
# validate.sh + scripts/test.sh now cover skill-level invariants.

./scripts/validate.sh || exit 1
HOOK
then
  echo "Pre-commit hook installed at .git/hooks/pre-commit"
  echo "Commits will now run validate.sh."
else
  rc=1
fi

if install_hook post-merge << 'HOOK'
#!/usr/bin/env bash
# Auto-installed by scripts/setup-hooks.sh.
# Combined post-merge handler:
#   - D000013: re-deploy skills + templates if relevant files changed
#   - F000011/S000020: auto-update Phase 3 lifecycle gates on touched work-items
# Closes D000012 Option C2: deploy is the per-machine sync-up. Templates are ready
# at ~/.claude/ before the next skill invocation needs them.

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)"
[ -z "$REPO_ROOT" ] && exit 0

# Section 1: D000013 re-deploy on relevant file change
CHANGED=$(git diff-tree -r --name-only --no-commit-id ORIG_HEAD HEAD 2>/dev/null \
  | grep -E '^(templates/|skills/|skills-catalog\.json|rules/)' || true)
if [ -n "$CHANGED" ]; then
  echo "[skills-deploy] templates/skills/catalog/rules changed — re-deploying..."
  "$REPO_ROOT/scripts/skills-deploy" install --overwrite
fi

# Section 2: F000011 Phase 3 lifecycle-gate auto-update.
# Only fires on main; silently no-ops on feature branches. Best-effort:
# prints warnings but exits 0 to never block git operations.
BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
if [ "$BRANCH" = "main" ]; then
  TOUCHED_TRACKERS=$(git diff-tree -r --name-only --no-commit-id ORIG_HEAD HEAD 2>/dev/null \
    | grep -E '^work-items/.*_TRACKER\.md$' || true)
  if [ -n "$TOUCHED_TRACKERS" ]; then
    while IFS= read -r tracker_path; do
      [ -z "$tracker_path" ] && continue
      dir=$(dirname "$tracker_path")

      # Guard: only fire on trackers whose Phase 2 implementer-owned gates
      # transitioned from [ ] to [x] in this merge. Pure tracker-edit changes
      # (journal cleanup, doc edits on sibling-story trackers) MUST NOT
      # trigger Phase 3 gate inference. The engine resolves PRs via
      # `gh pr list --search <id>`, which matches the work-item ID anywhere
      # in title OR body — producing false positives when one PR references
      # multiple sibling stories (observed twice: PR #99 marked S036/S037/S039
      # gates while shipping only S038; PR #100 re-corrupted S037/S039 while
      # shipping only S036). /CJ_implement-from-spec marks Phase 2 gates [x]
      # only when it writes code, so a Phase 2 [x]-count delta is a strong
      # proxy for "this work-item shipped code in this merge."
      before=$(git show "ORIG_HEAD:$tracker_path" 2>/dev/null \
        | awk '/^### Phase 2:/{f=1; next} f && /^### Phase /{f=0} f' \
        | grep -cE '^[[:space:]]*-[[:space:]]*\[[xX]\]')
      [ -z "$before" ] && before=0
      after=$(awk '/^### Phase 2:/{f=1; next} f && /^### Phase /{f=0} f' "$tracker_path" 2>/dev/null \
        | grep -cE '^[[:space:]]*-[[:space:]]*\[[xX]\]')
      [ -z "$after" ] && after=0

      if [ "$after" -le "$before" ]; then
        echo "  [skip] $dir: Phase 2 [x]-count $before -> $after (no shipped code in this merge)"
        continue
      fi

      if [ -x "$REPO_ROOT/scripts/check-gates-update.sh" ]; then
        "$REPO_ROOT/scripts/check-gates-update.sh" "$dir" 2>&1 | sed 's/^/  /' || \
          echo "  [WARN] check-gates-update.sh failed for $dir; run manually" >&2
      fi
    done <<< "$TOUCHED_TRACKERS"
  fi
fi

# Section 3: F000028 doc-sync trigger block.
# Writes a marker to ~/.gstack/doc-sync-pending/<repo-slug>.json when main moves
# non-trivially, so the next CJ_ skill session can surface a /document-release AUQ.
# Best-effort: wrapped in `{ ... } || true` so any failure exits 0 without
# blocking the merge. Idempotency via .doc-sync-last-head in --git-common-dir.
# Triviality regex anchored at start to avoid READMEs.py false-positives.
# Opt out via DOC_SYNC_FORCE=1 override (forces marker write on doc-only diffs).
{
  # doc-sync trigger block
  _BRANCH=$(git symbolic-ref --short HEAD 2>/dev/null || echo "")
  if [ "$_BRANCH" = "main" ]; then
    _LAST_SYNCED_FILE="$(git rev-parse --git-common-dir)/.doc-sync-last-head"
    _CURRENT_HEAD=$(git rev-parse HEAD)
    _LAST_SYNCED=$(cat "$_LAST_SYNCED_FILE" 2>/dev/null || echo "")
    if [ "$_LAST_SYNCED" != "$_CURRENT_HEAD" ]; then
      _DIFF_BASE="${_LAST_SYNCED:-HEAD^}"
      git rev-parse --verify "$_DIFF_BASE" >/dev/null 2>&1 || \
        _DIFF_BASE="$(git hash-object -t tree /dev/null)"
      _CHANGED_NON_DOCS=$(git diff --name-only "$_DIFF_BASE" HEAD 2>/dev/null \
        | grep -vE '^(README\.md|CHANGELOG\.md|CLAUDE\.md|CONTRIBUTING\.md|ARCHITECTURE\.md|docs/)' \
        | wc -l | tr -d ' ')
      if [ "$_CHANGED_NON_DOCS" -eq 0 ] && [ "${DOC_SYNC_FORCE:-0}" != "1" ]; then
        echo "[doc-sync] main moved but only docs changed; skipping /document-release." >&2
        echo "$_CURRENT_HEAD" > "$_LAST_SYNCED_FILE"
      else
        _MARKER_DIR="$HOME/.gstack/doc-sync-pending"
        if mkdir -p "$_MARKER_DIR" 2>/dev/null; then
          _REPO_SLUG=$(basename "$(git rev-parse --show-toplevel)" 2>/dev/null || echo "unknown")
          _MARKER_PATH="$_MARKER_DIR/${_REPO_SLUG}.json"
          _TMP_MARKER=$(mktemp "${_MARKER_DIR}/.${_REPO_SLUG}.XXXXXX" 2>/dev/null)
          if [ -n "$_TMP_MARKER" ]; then
            cat > "$_TMP_MARKER" <<EOF
{
  "repo": "$_REPO_SLUG",
  "head_sha": "$_CURRENT_HEAD",
  "main_moved_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "diff_base": "$_DIFF_BASE",
  "changed_files": $_CHANGED_NON_DOCS
}
EOF
            if mv "$_TMP_MARKER" "$_MARKER_PATH" 2>/dev/null; then
              echo "[doc-sync] main moved. Marker written: $_MARKER_PATH" >&2
              echo "[doc-sync] Run /document-release in your next Claude session to sync README/ARCHITECTURE/CLAUDE.md." >&2
              echo "$_CURRENT_HEAD" > "$_LAST_SYNCED_FILE"
            else
              rm -f "$_TMP_MARKER" 2>/dev/null
              echo "[doc-sync] WARN: failed to install marker at $_MARKER_PATH" >&2
            fi
          else
            echo "[doc-sync] WARN: mktemp failed; skipping marker." >&2
          fi
        else
          echo "[doc-sync] WARN: cannot create $_MARKER_DIR; skipping marker." >&2
        fi
      fi
    fi
  fi
} || true

# Best-effort: always exit 0 to avoid blocking git operations.
exit 0
HOOK
then
  echo "Post-merge hook installed at .git/hooks/post-merge"
  echo "  - Pulls that change templates/skills/catalog/rules auto-redeploy ~/.claude/."
  echo "  - Pulls on main that touch work-items/**/*_TRACKER.md auto-update Phase 3 gates."
  echo "  - Pulls on main that move HEAD non-trivially write a doc-sync marker."
else
  rc=1
fi

if install_hook post-rewrite << 'HOOK'
#!/usr/bin/env bash
# Auto-installed by scripts/setup-hooks.sh.
# F000028 post-rewrite handler — covers `git pull --rebase` on main.
# Carries the same doc-sync trigger block as section 3 of post-merge.
# Best-effort: always exits 0 to avoid blocking git operations.

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)"
[ -z "$REPO_ROOT" ] && exit 0

{
  # doc-sync trigger block
  _BRANCH=$(git symbolic-ref --short HEAD 2>/dev/null || echo "")
  if [ "$_BRANCH" = "main" ]; then
    _LAST_SYNCED_FILE="$(git rev-parse --git-common-dir)/.doc-sync-last-head"
    _CURRENT_HEAD=$(git rev-parse HEAD)
    _LAST_SYNCED=$(cat "$_LAST_SYNCED_FILE" 2>/dev/null || echo "")
    if [ "$_LAST_SYNCED" != "$_CURRENT_HEAD" ]; then
      _DIFF_BASE="${_LAST_SYNCED:-HEAD^}"
      git rev-parse --verify "$_DIFF_BASE" >/dev/null 2>&1 || \
        _DIFF_BASE="$(git hash-object -t tree /dev/null)"
      _CHANGED_NON_DOCS=$(git diff --name-only "$_DIFF_BASE" HEAD 2>/dev/null \
        | grep -vE '^(README\.md|CHANGELOG\.md|CLAUDE\.md|CONTRIBUTING\.md|ARCHITECTURE\.md|docs/)' \
        | wc -l | tr -d ' ')
      if [ "$_CHANGED_NON_DOCS" -eq 0 ] && [ "${DOC_SYNC_FORCE:-0}" != "1" ]; then
        echo "[doc-sync] main moved but only docs changed; skipping /document-release." >&2
        echo "$_CURRENT_HEAD" > "$_LAST_SYNCED_FILE"
      else
        _MARKER_DIR="$HOME/.gstack/doc-sync-pending"
        if mkdir -p "$_MARKER_DIR" 2>/dev/null; then
          _REPO_SLUG=$(basename "$(git rev-parse --show-toplevel)" 2>/dev/null || echo "unknown")
          _MARKER_PATH="$_MARKER_DIR/${_REPO_SLUG}.json"
          _TMP_MARKER=$(mktemp "${_MARKER_DIR}/.${_REPO_SLUG}.XXXXXX" 2>/dev/null)
          if [ -n "$_TMP_MARKER" ]; then
            cat > "$_TMP_MARKER" <<EOF
{
  "repo": "$_REPO_SLUG",
  "head_sha": "$_CURRENT_HEAD",
  "main_moved_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "diff_base": "$_DIFF_BASE",
  "changed_files": $_CHANGED_NON_DOCS
}
EOF
            if mv "$_TMP_MARKER" "$_MARKER_PATH" 2>/dev/null; then
              echo "[doc-sync] main moved. Marker written: $_MARKER_PATH" >&2
              echo "[doc-sync] Run /document-release in your next Claude session to sync README/ARCHITECTURE/CLAUDE.md." >&2
              echo "$_CURRENT_HEAD" > "$_LAST_SYNCED_FILE"
            else
              rm -f "$_TMP_MARKER" 2>/dev/null
              echo "[doc-sync] WARN: failed to install marker at $_MARKER_PATH" >&2
            fi
          else
            echo "[doc-sync] WARN: mktemp failed; skipping marker." >&2
          fi
        else
          echo "[doc-sync] WARN: cannot create $_MARKER_DIR; skipping marker." >&2
        fi
      fi
    fi
  fi
} || true

exit 0
HOOK
then
  echo "Post-rewrite hook installed at .git/hooks/post-rewrite"
  echo "  - Rebase pulls on main that move HEAD non-trivially write a doc-sync marker."
else
  rc=1
fi

exit $rc
