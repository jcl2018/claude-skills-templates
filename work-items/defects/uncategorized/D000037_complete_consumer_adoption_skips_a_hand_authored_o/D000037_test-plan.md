---
type: test-plan
parent: D000037
created: 2026-06-29
---

# D000037 — Test Plan

| Test | Purpose | Type |
|------|---------|------|
| scripts/test-deploy.sh (Test S000117b) | regression test for D000037 root cause (a hand-authored-overlay consumer is completed append-only: gate BLOCKs pre-adoption → renders surfaces + splices new orphan declarations preserving curated rows → gate exits 0; idempotent + rollback) | smoke |
