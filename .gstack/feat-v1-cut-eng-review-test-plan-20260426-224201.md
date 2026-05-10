# /autoplan Eng Review — Test Plan Addendum

Generated: 2026-04-26
Branch: feat/v1-cut
Plan packet: F000004 v2 + S000010 + T000011

This addendum lists test gaps identified in /autoplan Eng phase that are NOT
covered by S000010_TEST-SPEC.md or T000011_test-plan.md as currently written.

## Critical Gap (must add before T000011 lands)

### G1 — Bash version / globstar availability assertion

**Gap:** T000011 spec uses `**/*.md` recursive glob in MIRROR_SPECS. On bash
3.2 (macOS default at `/bin/bash`, version 3.2.57 verified on dev box), `**`
expands as `*` — single level only. The recursive shape is silently broken
on stock macOS; would only surface when fixtures gain a third nesting level
or when running on a fresh CI runner.

**Required test:**

```bash
# scripts/validate.sh prelude (BEFORE the MIRROR_SPECS loop)
if [ -z "${BASH_VERSINFO[0]:-}" ] || [ "${BASH_VERSINFO[0]}" -lt 4 ]; then
  fail "validate.sh requires bash 4+ for globstar (currently bash $BASH_VERSION). Re-run with /opt/homebrew/bin/bash or use find -print0."
  exit 1
fi
shopt -s globstar nullglob
```

**Alternative:** rewrite recursive shape using `find ... -print0 | while IFS= read -r -d ''` — POSIX-portable, works on bash 3.2.

## High-Severity Gaps

### G2 — Mirror-extras-fail vs warn

T000011 case 6 + 9 preserve "extras are warn-only" behavior from existing
v1 templates check. For authoritative mirrors (`reference/`, `philosophy/`,
`examples/`, `fixtures/` are upstream-derived), stale bundle-side files
should FAIL not WARN. Otherwise a removed upstream file leaves a stale
bundle-side copy that Copilot reads.

**Required test:** assert removing an upstream file while keeping the bundle
copy causes `validate.sh` to fail with `[ORPHAN]` for the now-stale bundle
file under any of the 4 new mirror dirs (not warn).

### G3 — Path traversal in copilot-deploy.py doctor/remove

Codex flagged: `scripts/copilot-deploy.py:183-191` and `:227-230` trust
`install-manifest.json` `entry["dest"]` and join onto target without
`Path.resolve().is_relative_to(target.resolve())` check. Out of v2 scope
strictly speaking (no installer changes per design), but v2 widens the
mirror surface — defense-in-depth justifies adding the assertion.

**Required test:** craft a malicious install-manifest.json with
`"dest": "../../etc/passwd"` (or platform equivalent), run
`copilot-deploy.py doctor`, assert it exits non-zero with a path-traversal
error rather than reading the out-of-target file.

### G4 — Manifest unification verification (not just byte-equality)

T000011 case 15 asserts `cmp -s` between the two manifest files exits 0.
But a trivial fix that left BOTH descriptions stale (or BOTH set to a
placeholder) would also pass `cmp -s`. The intent is "both files have a
unified description naming both audiences."

**Required test:** assert the description field literally contains both
"company-workflow validate" and "validate.prompt.md" tokens (or whatever
the agreed unified text becomes). `grep -F` on the description field of
both files.

**Open question (Codex):** does anything actually consume the description
field? `rg description` shows no programmatic consumer. If true, the
unification may be wrong abstraction — consider exempting the description
field from sync-check instead.

## Medium-Severity Gaps

### G5 — Files with spaces

Existing `validate.sh:169` uses unquoted `for src in <glob>` and works
because filenames have no spaces today. v2 generalization should fix this
proactively rather than inherit the latent bug.

**Required test:** add a fixture file with a space in its name (e.g.,
`valid feature dir/TRACKER.md`) — assert sync check handles it correctly.

### G6 — Symlinks

`cmp -s` follows symlinks. If a maintainer ever symlinks
`work-copilot/WORKFLOW.md` → `../skills/company-workflow/WORKFLOW.md`,
sync check passes by tautology and `copilot-deploy.py rglob("*").copy()`
copies the symlink target's bytes (silently OK in this case, but a footgun
for any future use).

**Required test:** create a symlink fixture, assert sync check either
accepts (with warning) or rejects (per policy). Document the choice.

### G7 — Empty source dir / accidental upstream deletion

If `skills/company-workflow/reference/` is emptied (refactor, accidental
deletion), `for src in skills/company-workflow/reference/*.md` silently
iterates zero times and reports `[PASS]`. Bundle-side files are not
counter-checked because counterpart-warning loop is the only protection.

**Required test:** assert min-count per spec OR assert the orphan-warn
loop catches the bundle-side files when src dir is empty.

### G8 — .gitkeep / hidden files

T000011 cases 12-13 cover `.DS_Store` and `Thumbs.db`. Real risk:
`fixtures/valid-feature-dir/.gitkeep` (used to commit empty dirs) would be
flagged ORPHAN under recursive shape unless the filter also excludes
`.gitkeep`, `.gitattributes`, `.editorconfig`.

**Required test:** add `.gitkeep` fixtures, assert sync check ignores them
(or whatever the chosen policy is — document).

### G9 — Doctor reports DRIFT on nested fixture (not just top-level)

S000010 TEST-SPEC #12 mutates `WORKFLOW.md` only. The nested
`fixtures/valid-feature-dir/TRACKER.md` is the file that historically
drifted (per design's "5-file fixture gap" finding) — a regression test
should mutate that exact file post-install, assert doctor catches it.

### G10 — Install-then-validate-target

Run `validate.sh` against `$TMPDIR/.github/work-copilot/` after install.
If MIRROR_SPECS paths are repo-relative only, the check is useless on
installed bundles. Document scope intentionally (CI-only check) or extend
to handle installed-path mode.

## Lower-Severity Gaps (defer to follow-up)

### G11 — Filename collision across spec entries

If two MIRROR_SPECS entries both glob `*.md` from different roots, their
counts shouldn't merge. Edge case; unlikely with current spec set.

### G12 — Recursive: src has 2 nested dirs, dst has 1

Coverage gap in T000011 case 7-9 — only covers single nesting level.
Recursive walk could short-circuit on the first dir.

### G13 — Non-UTF8 / BOM in JSON manifest

If a Windows editor saves the manifest with BOM, `cmp -s` fails. Low
likelihood; doc convention "edit JSON in plain editor" suffices.

## Summary

| ID | Gap | Severity | Recommendation |
|---|---|---|---|
| G1 | bash 3.2 globstar broken | CRITICAL | Block T000011 land until fixed |
| G2 | Mirror extras warn vs fail | HIGH | Decide policy; default = FAIL for authoritative mirrors |
| G3 | copilot-deploy.py path traversal | HIGH | Defense-in-depth; add resolve-and-check |
| G4 | Manifest description verification | HIGH | Add literal-token assert OR exempt field from sync |
| G5 | Files with spaces | MED | Quote all glob expansions |
| G6 | Symlinks | MED | Document + test policy |
| G7 | Empty src dir false-pass | MED | Add min-count assertion |
| G8 | .gitkeep / hidden files | MED | Document filter policy |
| G9 | Doctor DRIFT on nested file | MED | Add to S000010 TEST-SPEC |
| G10 | Install-then-validate-target | MED | Document CI-only scope |
| G11 | Cross-spec filename collision | LOW | Defer |
| G12 | Recursive multi-level nesting | LOW | Defer |
| G13 | UTF8/BOM in JSON | LOW | Doc convention |

**Of these:** G1 must be fixed BEFORE T000011 lands (silent breakage on dev box).
G2-G4 should be addressed in S000010/T000011 before the v0.15.0 release.
G5-G10 should be added to T000011 test-plan or S000010 TEST-SPEC.
G11-G13 can defer to a follow-up cleanup.
