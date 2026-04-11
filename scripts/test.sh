#!/usr/bin/env bash
# Smoke tests for the skill workbench. Superset of validate.sh.
# Exit 0 = all tests pass. Exit 1 = one or more failures.

. "$(dirname "$0")/lib.sh"
init

ERRORS=0

ok() { echo "  OK: $1"; }
fail_test() { echo "  FAIL: $1" >&2; ERRORS=$((ERRORS + 1)); }

echo "=== Running validate.sh ==="
if "$REPO_ROOT/scripts/validate.sh"; then
  ok "validate.sh passed"
else
  fail_test "validate.sh failed"
fi

echo ""
echo "=== Additional smoke tests ==="

# Test: No duplicate skill names in catalog
echo ""
echo "Checking for duplicate skill names..."
dupes=$(jq -r '.[].name' "$CATALOG" | sort | uniq -d)
if [ -z "$dupes" ]; then
  ok "No duplicate skill names"
else
  fail_test "Duplicate skill names found: $dupes"
fi

# Test: All SKILL.md files have parseable frontmatter
echo ""
echo "Checking SKILL.md frontmatter parseability..."
for name in $(jq -r '.[].name' "$CATALOG"); do
  skill_file="$SKILLS_DIR/$name/SKILL.md"
  [ -f "$skill_file" ] || continue
  # Check frontmatter exists between --- markers
  fm=$(sed -n '/^---$/,/^---$/p' "$skill_file")
  if echo "$fm" | grep -q 'name:' && echo "$fm" | grep -q 'description:'; then
    ok "$name frontmatter is parseable"
  else
    fail_test "$name SKILL.md frontmatter is not parseable"
  fi
done

# Test: Doc triplets have required sections
echo ""
echo "Checking doc triplet required sections..."
for name in $(jq -r '.[].name' "$CATALOG"); do
  doc_dir="$DOCS_DIR/$name"
  [ -d "$doc_dir" ] || continue

  if [ -f "$doc_dir/PRD.md" ]; then
    if grep -q '## Problem Statement' "$doc_dir/PRD.md" 2>/dev/null; then
      ok "$name PRD.md has ## Problem Statement"
    else
      fail_test "$name PRD.md missing ## Problem Statement section"
    fi
  fi

  if [ -f "$doc_dir/ARCHITECTURE.md" ]; then
    if grep -qE '## (Overview|Architecture)' "$doc_dir/ARCHITECTURE.md" 2>/dev/null; then
      ok "$name ARCHITECTURE.md has ## Overview or ## Architecture"
    else
      fail_test "$name ARCHITECTURE.md missing ## Overview or ## Architecture section"
    fi
  fi

  if [ -f "$doc_dir/TEST-SPEC.md" ]; then
    if grep -q '## Test Matrix' "$doc_dir/TEST-SPEC.md" 2>/dev/null; then
      ok "$name TEST-SPEC.md has ## Test Matrix"
    else
      fail_test "$name TEST-SPEC.md missing ## Test Matrix section"
    fi
  fi
done

# Test: Advisory scripts run without crashing
echo ""
echo "Smoke-testing advisory scripts..."

if "$REPO_ROOT/scripts/doctor.sh" >/dev/null 2>&1; then
  ok "doctor.sh runs without crash"
else
  fail_test "doctor.sh crashed"
fi

if "$REPO_ROOT/scripts/lint-skill.sh" >/dev/null 2>&1; then
  ok "lint-skill.sh runs without crash"
else
  fail_test "lint-skill.sh crashed"
fi

deps_output=$("$REPO_ROOT/scripts/deps.sh" 2>&1)
if [ $? -eq 0 ]; then
  if echo "$deps_output" | grep -q "work"; then
    ok "deps.sh runs and output contains known skills"
  else
    fail_test "deps.sh runs but output missing expected skill names"
  fi
else
  fail_test "deps.sh crashed"
fi

if "$REPO_ROOT/scripts/generate-readme.sh" >/dev/null 2>&1; then
  ok "generate-readme.sh runs without crash"
  # Idempotency check
  first=$("$REPO_ROOT/scripts/generate-readme.sh" 2>/dev/null)
  second=$("$REPO_ROOT/scripts/generate-readme.sh" 2>/dev/null)
  if [ "$first" = "$second" ]; then
    ok "generate-readme.sh is idempotent"
  else
    fail_test "generate-readme.sh produces different output on repeated runs"
  fi
else
  fail_test "generate-readme.sh crashed"
fi

# Integration test: scaffold a temp skill, validate, cleanup
echo ""
echo "Integration test: create-skill.sh scaffold cycle..."

# Backup catalog for safe restore
cp "$CATALOG" "/tmp/catalog-backup-$$"
cp "$REPO_ROOT/README.md" "/tmp/readme-backup-$$"
[ -f "$REPO_ROOT/VERSION" ] && cp "$REPO_ROOT/VERSION" "/tmp/version-backup-$$"
[ -f "$REPO_ROOT/CHANGELOG.md" ] && cp "$REPO_ROOT/CHANGELOG.md" "/tmp/changelog-backup-$$"
trap 'cp "/tmp/catalog-backup-$$" "$CATALOG"; cp "/tmp/readme-backup-$$" "$REPO_ROOT/README.md"; [ -f "/tmp/version-backup-$$" ] && cp "/tmp/version-backup-$$" "$REPO_ROOT/VERSION"; [ -f "/tmp/changelog-backup-$$" ] && cp "/tmp/changelog-backup-$$" "$REPO_ROOT/CHANGELOG.md"; rm -rf "$SKILLS_DIR/zzz-test-scaffold" "$DOCS_DIR/zzz-test-scaffold" "/tmp/catalog-backup-$$" "/tmp/readme-backup-$$" "/tmp/version-backup-$$" "/tmp/changelog-backup-$$"; git tag -d zzz-test-scaffold-v0.1.0 2>/dev/null || true; git tag -d zzz-test-scaffold-v0.1.1 2>/dev/null || true; for vtag in $(git tag -l "v[0-9]*" 2>/dev/null | grep -v "^v0\.1\.0$"); do git tag -d "$vtag" 2>/dev/null || true; done' EXIT

# Step 1: scaffold DESIGN.md first (required by lifecycle pipeline)
if "$REPO_ROOT/scripts/skill-design.sh" zzz-test-scaffold >/dev/null 2>&1; then
  ok "skill-design.sh scaffolded DESIGN.md"
else
  fail_test "skill-design.sh failed to scaffold DESIGN.md"
fi

# Fill in required DESIGN.md sections so skill-check passes
sed -i '' 's/What problem does this skill solve.*/Test skill for integration testing/' "$SKILLS_DIR/zzz-test-scaffold/DESIGN.md" 2>/dev/null || \
sed -i 's/What problem does this skill solve.*/Test skill for integration testing/' "$SKILLS_DIR/zzz-test-scaffold/DESIGN.md"
sed -i '' 's/What does the skill do, step by step.*/Runs integration tests./' "$SKILLS_DIR/zzz-test-scaffold/DESIGN.md" 2>/dev/null || \
sed -i 's/What does the skill do, step by step.*/Runs integration tests./' "$SKILLS_DIR/zzz-test-scaffold/DESIGN.md"

# Step 2: scaffold SKILL.md + CHANGELOG.md
if "$REPO_ROOT/scripts/create-skill.sh" zzz-test-scaffold >/dev/null 2>&1; then
  ok "create-skill.sh scaffolded zzz-test-scaffold"

  # Verify the scaffold is valid
  if "$REPO_ROOT/scripts/validate.sh" >/dev/null 2>&1; then
    ok "validate.sh passes with scaffolded skill"
  else
    fail_test "validate.sh fails after scaffolding zzz-test-scaffold"
  fi

  # Step 3: skill-check should pass
  if "$REPO_ROOT/scripts/skill-check.sh" zzz-test-scaffold >/dev/null 2>&1; then
    ok "skill-check.sh passes for scaffolded skill"
  else
    fail_test "skill-check.sh fails for scaffolded skill"
  fi
else
  fail_test "create-skill.sh failed to scaffold zzz-test-scaffold"
fi

# Trap EXIT restores catalog and cleans up dirs

# Integration test: version bump cycle
echo ""
echo "Integration test: skill-version.sh bump cycle..."

if [ -d "$SKILLS_DIR/zzz-test-scaffold" ]; then
  # Current version should be 0.1.0
  CURRENT_VER=$(sed -n '/^---$/,/^---$/p' "$SKILLS_DIR/zzz-test-scaffold/SKILL.md" | grep '^version:' | head -1 | sed 's/^version:[[:space:]]*//')
  if [ "$CURRENT_VER" = "0.1.0" ]; then
    ok "initial version is 0.1.0"
  else
    fail_test "expected initial version 0.1.0, got: $CURRENT_VER"
  fi

  # Bump patch version
  if "$REPO_ROOT/scripts/skill-version.sh" zzz-test-scaffold patch >/dev/null 2>&1; then
    ok "skill-version.sh patch bump succeeded"

    # Verify SKILL.md frontmatter updated
    NEW_VER=$(sed -n '/^---$/,/^---$/p' "$SKILLS_DIR/zzz-test-scaffold/SKILL.md" | grep '^version:' | head -1 | sed 's/^version:[[:space:]]*//')
    if [ "$NEW_VER" = "0.1.1" ]; then
      ok "SKILL.md version bumped to 0.1.1"
    else
      fail_test "expected version 0.1.1, got: $NEW_VER"
    fi

    # Verify catalog updated
    CAT_VER=$(jq -r '.[] | select(.name == "zzz-test-scaffold") | .version' "$CATALOG")
    if [ "$CAT_VER" = "0.1.1" ]; then
      ok "catalog version bumped to 0.1.1"
    else
      fail_test "expected catalog version 0.1.1, got: $CAT_VER"
    fi

    # Verify CHANGELOG has new entry
    if grep -q '## \[0.1.1\]' "$SKILLS_DIR/zzz-test-scaffold/CHANGELOG.md"; then
      ok "CHANGELOG.md has [0.1.1] entry"
    else
      fail_test "CHANGELOG.md missing [0.1.1] entry"
    fi
  else
    fail_test "skill-version.sh patch bump failed"
  fi
fi

# Integration test: ship cycle (uses git, so we need to be careful)
echo ""
echo "Integration test: skill-ship.sh cycle..."

if [ -d "$SKILLS_DIR/zzz-test-scaffold" ]; then
  # skill-ship.sh requires no staged changes and a clean skill-check
  # Reset any staged changes from the version bump
  git reset HEAD -- . >/dev/null 2>&1 || true

  SHIP_OUTPUT=$("$REPO_ROOT/scripts/skill-ship.sh" zzz-test-scaffold 2>&1) || true
  if echo "$SHIP_OUTPUT" | grep -q "=== Shipped"; then
    ok "skill-ship.sh succeeded"

    # Verify tag was created
    if git tag -l "zzz-test-scaffold-v0.1.1" | grep -q "zzz-test-scaffold-v0.1.1"; then
      ok "git tag zzz-test-scaffold-v0.1.1 created"
    else
      fail_test "git tag zzz-test-scaffold-v0.1.1 not found"
    fi

    # Verify commit was created
    if git log -1 --oneline | grep -q "zzz-test-scaffold"; then
      ok "commit message references zzz-test-scaffold"
    else
      fail_test "latest commit doesn't reference zzz-test-scaffold"
    fi

    # Clean up: remove the commit and tag (restore previous state)
    git reset --soft HEAD~1 >/dev/null 2>&1 || true
    git reset HEAD -- . >/dev/null 2>&1 || true
  else
    echo "  skill-ship.sh output: $SHIP_OUTPUT" >&2
    fail_test "skill-ship.sh failed"
  fi
fi

# Negative test: create orphan directory, verify validate catches it
echo ""
echo "Negative test: orphan directory detection..."
mkdir -p "$SKILLS_DIR/zzz-test-orphan"
if "$REPO_ROOT/scripts/validate.sh" >/dev/null 2>&1; then
  fail_test "validate.sh should have detected orphan zzz-test-orphan but passed"
else
  ok "validate.sh correctly detected orphan directory"
fi
rmdir "$SKILLS_DIR/zzz-test-orphan"

# Summary
echo ""
echo "=== Test Summary ==="
echo "  Failures: $ERRORS"
if [ "$ERRORS" -gt 0 ]; then
  echo "  RESULT: FAIL"
  exit 1
else
  echo "  RESULT: PASS"
  exit 0
fi
