---
type: review-notes
parent: R000099
title: "Rate Limiter Core Implementation — Code Review Notes"
date: 2026-03-13
reviewer: Raj Gupta
status: Complete
pr: "#142"
branch: "feature/F000099-rate-limiting"
commit: "a3f7c21..e9b4d08"
verdict: Approve with Comments
---

## Review Metadata

| Field | Value |
|-------|-------|
| PR / Branch | #142 / feature/F000099-rate-limiting |
| Commit range | a3f7c21..e9b4d08 |
| Reviewer | Raj Gupta |
| Date | 2026-03-13 |
| Files changed | 9 |
| Lines changed | +487 / -12 |

## Findings

| # | Severity | Category | Location | Description | Recommendation |
|---|----------|----------|----------|-------------|---------------|
| 1 | Major | correctness | redis-sync.ts:34 | Race condition: two concurrent requests can both read count=99, both INCR to 100, allowing 101 requests through | Use Redis MULTI/EXEC or Lua script to make read+compare+incr atomic |
| 2 | Major | resilience | redis-sync.ts:78 | Fallback timeout hardcoded to 5000ms; if Redis is slow but not dead, requests block for 5s | Reduce to 500ms and make configurable via env var |
| 3 | Minor | performance | rate-limiter.ts:52 | Config cache lookup called twice per request (once in middleware, once in bucket check) | Cache the result in the request context to avoid double lookup |
| 4 | Minor | style | rate-limiter.ts:91 | Magic number 60 (window size in seconds) used inline | Extract to named constant RATE_LIMIT_WINDOW_SECONDS |
| 5 | Note | maintainability | redis-sync.ts:1-15 | Good separation of Redis connection management from rate logic | Consider adding JSDoc for the module's public API |
| 6 | Minor | security | rate-limiter.ts:28 | Tenant ID from JWT used directly as Redis key segment | Validate tenant ID format to prevent key injection (e.g., tenant:*:admin) |

## Summary

**Verdict:** Approve with Comments

**Key concerns:**
- The Redis race condition (#1) must be fixed before merge; a Lua script approach is recommended
- The 5-second fallback timeout (#2) is too high for a hot-path middleware

**Positive observations:**
- Clean separation between local bucket and Redis sync layers
- Fallback-to-local design is sound and well-tested
- Good use of Prometheus metrics for observability from day one
- Test coverage is thorough for the happy path

## Follow-Up Actions

| Action | Owner | Status |
|--------|-------|--------|
| Fix Redis race condition with Lua script | Marcus Liu | Done |
| Make fallback timeout configurable | Marcus Liu | Done |
| Add tenant ID validation | Marcus Liu | Done |
| Extract magic numbers to constants | Marcus Liu | Done |
| Add JSDoc to redis-sync module | Marcus Liu | Open |
