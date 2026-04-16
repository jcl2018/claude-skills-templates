---
name: "Code review: API rate limiting middleware and Redis backend"
type: review
workflow_type: review
id: "R000099"
status: active
created: "2026-03-12"
updated: "2026-03-14"
deadline: "2026-03-15"
url: "https://github.com/example-org/saas-platform/pull/487"
repo: "saas-platform"
branch: "feat/api-rate-limiting"
blocked_by: ""
---

## Lifecycle

### Phase 1: Track
- [x] Review scoped (acceptance criteria defined)
- [x] Working branch created (`branch` field populated)
- [x] Review materials gathered

### Phase 2: Implement
- [x] Review conducted
- [x] Feedback documented in Journal
- [ ] All review items addressed or deferred

### Phase 3: Review
- [ ] Review notes finalized
- [ ] Feedback captured (suggestions + resolutions in Journal)

### Phase 4: Ship
- [ ] Review completed
- [ ] PR created (PR link in PRs section)
- [ ] Merged to target branch

## Todos

- [x] Review rate-limiter.ts middleware implementation
- [x] Review redis-rate-store.ts sorted set operations
- [x] Review redis-connection.ts pooling and failover config
- [x] Review rate-limits.yaml tier configuration
- [ ] Verify test coverage for edge cases (window boundary, Redis timeout, failover)
- [ ] Check for security concerns in JWT decode path
- [ ] Sign off on final changes after author addresses feedback

## Log

- 2026-03-12: Created. Code review for API rate limiting feature (F000099). Reviewer: M. Chen. PR #487 contains 14 files changed, 1,247 additions, 83 deletions across middleware, Redis backend, and configuration.
- 2026-03-12: Initial review pass complete. Found 3 suggestions, 1 potential issue, 0 blockers. `review-pass-1`
- 2026-03-13: Author addressed 2 of 3 suggestions. Pending: error handling in Redis timeout path. `review-pass-2`
- 2026-03-14: Second review pass. Redis timeout handling updated. One new suggestion on connection pool sizing documentation. `review-pass-3`

## PRs

- https://github.com/example-org/saas-platform/pull/487 (open)

## Files

- src/middleware/rate-limiter.ts
- src/middleware/rate-limiter.test.ts
- src/services/redis-rate-store.ts
- src/services/redis-rate-store.test.ts
- src/services/redis-connection.ts
- src/services/redis-connection.test.ts
- src/config/rate-limits.yaml
- src/api/headers/rate-limit-headers.ts
- src/types/rate-store.d.ts
- test/integration/redis-rate-store.integration.test.ts
- test/integration/redis-failover.test.ts
- test/e2e/rate-limiting.e2e.test.ts
- infra/terraform/redis-cluster.tf
- docs/api/rate-limiting.md

## Meetings

- 2026-03-13 standup: Discussed GraphQL batched query rate limiting approach with the team. Agreed to count by operation count for now, defer complexity-based counting to a follow-up.

## Insights

- The lightweight JWT decode (without verification) in the rate limiter is acceptable because the auth middleware downstream performs full verification. If the token is malformed, the rate limiter falls back to IP-based limiting, and the request is rejected at the auth layer anyway.
- Connection pool size of 10 is appropriate for current scale but should be revisited when the service exceeds 20 worker processes. Added a comment in redis-connection.ts documenting the sizing rationale.
- The ZREMRANGEBYSCORE cleanup runs inline with each request. At high throughput this could become a bottleneck. Suggested moving cleanup to a periodic background job for tenants with more than 5000 requests per window.

## Journal

### 2026-03-12 -- finding
**Summary:** Suggestion: the rate limiter catches Redis connection errors and falls through (allows the request). This is the correct fail-open behavior for availability, but the fallback should log at WARN level and increment a `rate_limiter.redis_fallback` counter so ops can detect prolonged Redis outages. Currently it logs at DEBUG.

### 2026-03-12 -- finding
**Summary:** Suggestion: the sorted set cleanup (ZREMRANGEBYSCORE) runs synchronously on every request. For high-traffic tenants this adds unnecessary latency. Consider running cleanup asynchronously via setImmediate or moving to a periodic background sweep.

### 2026-03-12 -- finding
**Summary:** Suggestion: rate-limits.yaml uses raw numbers (e.g., `limit: 1000`) without units. Add a `window` field with explicit duration (e.g., `window: 60s`) to make the config self-documenting and reduce misconfiguration risk.

### 2026-03-13 -- decision
**Summary:** Author updated Redis fallback logging from DEBUG to WARN and added the Prometheus counter. Agreed to keep synchronous cleanup for now since p99 impact is under 1ms at current traffic levels, but added a TODO for the background sweep optimization. Rate config updated with explicit window field.

### 2026-03-14 -- finding
**Summary:** Second pass found that the connection pool sizing rationale is not documented in the code. Suggested adding a comment explaining why pool size is 10 and under what conditions it should be adjusted. Author agreed and added the documentation in redis-connection.ts.
