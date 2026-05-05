---
name: "Enforce per-tenant API rate limits at the gateway layer"
type: user-story
workflow_type: user-story
id: "S000099"
status: active
created: "2026-03-01"
updated: "2026-03-10"
url: "https://jira.example.com/browse/PLAT-1043"
repo: "saas-platform"
branch: "feat/api-rate-limiting"
blocked_by: ""
---

## Lifecycle

### Phase 1: Track
- [x] Story scoped (acceptance criteria defined)
- [x] Working branch created (`branch` field populated)
- [x] Tasks broken down (child task items created if needed)

### Phase 2: Implement
- [x] Core implementation committed (>=1 commit SHA in Log)
- [ ] Acceptance criteria met
- [x] Files section updated with all changed files

### Phase 3: Review
- [ ] Code review requested (reviewer noted)
- [ ] Review feedback captured (suggestions + resolutions in Journal)
- [ ] All review suggestions resolved or marked won't-fix

### Phase 4: Ship
- [ ] Linux branch build passes
- [ ] Regression tests pass
- [ ] Code review completed (reviewer noted in Journal)
- [ ] PR description generated
- [ ] PR created (PR link in PRs section)
- [ ] Merged to target branch

## Acceptance Criteria

- [x] As a platform operator, I can configure rate limits per pricing tier in a YAML config file
- [x] As an API consumer, I receive standard rate limit headers (X-RateLimit-Limit, X-RateLimit-Remaining, X-RateLimit-Reset) in every response
- [ ] As an API consumer, I receive a 429 response with a Retry-After header when my rate limit is exceeded
- [ ] As a platform operator, I can see rate limit metrics per tenant in the monitoring dashboard
- [ ] As an API consumer, rate limiting does not add more than 5ms p99 latency to my requests

## Todos

- [x] Create child task T000099: Implement Redis backend for rate limit counters
- [x] Create child task T000100: Build rate limit middleware for Express gateway
- [x] Create child task T000101: Add rate limit response headers
- [ ] Create child task T000102: Build monitoring dashboard widgets
- [ ] Verify all acceptance criteria pass end-to-end
- [ ] Run load test with production-like traffic patterns

## Log

- 2026-03-01: Created. As a platform operator, I need per-tenant API rate limiting so that no single tenant can monopolize shared resources and degrade service for others.
- 2026-03-03: Tasks broken down into four child tasks: Redis backend (T000099), middleware (T000100), headers (T000101), and dashboard (T000102). Architecture doc reviewed and approved. `a3f8c12`
- 2026-03-07: T000099 (Redis backend) implementation complete. Sliding window counters working with sorted sets. `d7f8a9b`
- 2026-03-08: T000100 (middleware) implementation complete. Rate limit middleware integrated into Express gateway pipeline. `c91fa34`
- 2026-03-10: T000101 (headers) partially complete. REST endpoint headers working, GraphQL endpoint pending. `e42c7a1`

## PRs

## Files

- src/middleware/rate-limiter.ts
- src/middleware/rate-limiter.test.ts
- src/services/redis-rate-store.ts
- src/services/redis-rate-store.test.ts
- src/services/redis-connection.ts
- src/api/headers/rate-limit-headers.ts
- src/config/rate-limits.yaml
- src/types/rate-store.d.ts
- test/integration/redis-rate-store.integration.test.ts
- test/e2e/rate-limiting.e2e.test.ts

## Insights

- The gateway middleware position matters: rate limiting must execute before authentication to prevent auth-layer DoS, but after request parsing to access the tenant ID from the JWT. Settled on placing it between body parsing and auth in the Express middleware chain.
- GraphQL endpoints need special handling because a single HTTP request can contain multiple operations. The rate limiter counts query complexity (field count) rather than raw request count for GraphQL.
- Tier-based configuration in YAML allows ops to adjust limits without code changes or redeployment. The config file is watched with chokidar for hot reload.

## Journal

### 2026-03-01 -- decision
**Summary:** Scoped the story to gateway-layer enforcement only. Database-layer throttling (e.g., per-tenant query limits) is deferred to a separate story. Gateway enforcement covers 90% of the abuse cases reported by the ops team.

### 2026-03-03 -- decision
**Summary:** Broke the story into four child tasks aligned with system boundaries: storage (T000099), middleware (T000100), response formatting (T000101), and observability (T000102). Each task can be implemented and tested independently.

### 2026-03-08 -- finding
**Summary:** Middleware placement between body parsing and auth requires the tenant ID to be extracted from the raw JWT without full auth validation. Added a lightweight JWT decode (not verify) step in the rate limiter to read the `tenant_id` claim. Full verification still happens in the auth middleware downstream. Commit `c91fa34`.

### 2026-03-10 -- blocker
**Summary:** GraphQL rate limiting is more complex than anticipated. A single POST to /graphql can contain batched queries. Need to decide whether to count by request, by operation, or by estimated query complexity. Blocked pending team discussion scheduled for 2026-03-13.
