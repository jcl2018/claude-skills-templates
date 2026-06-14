---
type: test-plan
parent: D000034
created: "2026-06-13"
---

# D000034 — Test Plan

| Test | Scenario | Type |
|------|----------|------|
| `tests/doc-spec-overlay.test.sh` (8b-2) | A repo with a missing declared doc emits `REMEDIATION: stage1/declared-exists` naming `/CJ_document-release`; the line is advisory (FINDINGS unchanged) | regression |
| `tests/doc-spec-overlay.test.sh` (8a-2) | A clean repo (all declared docs present) emits NO remediation line — the pointer is scoped to the missing-doc case | regression |
| `scripts/validate.sh` | Repo-wide validation stays green (0 errors / 0 warnings), incl. Check 14 USAGE drift + the portability audit | smoke |
