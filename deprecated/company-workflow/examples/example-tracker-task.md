---
name: "Implement Redis backend for rate limit counters"
type: user-story
workflow_type: task
id: "T000099"
status: active
created: "2026-03-03"
updated: "2026-03-09"
url: "https://jira.example.com/browse/PLAT-1045"
parent: "S000099"
repo: "saas-platform"
branch: "feat/api-rate-limiting"
blocked_by: ""
---

## Lifecycle

### Phase 1: Track
- [x] Scope understood from parent work item (parent tracker read)
- [x] Working branch created (`branch` field populated)
- [x] Files section has >=1 entry

### Phase 2: Implement
- [x] Core changes committed (>=1 commit SHA in Log)
- [x] Files section updated with all changed files
- [x] Todos section reflects remaining work (no stale items)

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

## Todos

- [x] Define RedisRateStore interface with increment, get, and reset methods
- [x] Implement sorted set based sliding window storage
- [x] Configure connection pooling with ioredis
- [x] Add TTL-based automatic key expiration
- [x] Write unit tests with Redis mock
- [x] Write integration tests with real Redis
- [ ] Add Prometheus metrics for Redis operation latency
- [ ] Document Redis schema and key naming conventions

## Log

- 2026-03-03: Created. Implement the Redis storage backend for rate limit counters as defined in the architecture doc. Parent story S000099 requires a sliding window implementation backed by Redis sorted sets.
- 2026-03-04: Defined RedisRateStore interface and implemented sorted set operations. Using ZADD for inserts, ZRANGEBYSCORE for window queries, ZREMRANGEBYSCORE for cleanup. `a1b2c3d`
- 2026-03-05: Connection pooling configured. Pool size set to 10 connections per worker process, with 3-second connect timeout and exponential backoff retry. `b7d4e29`
- 2026-03-06: TTL expiration added. Keys auto-expire after 2x the window duration to prevent orphaned keys from accumulating. `c4e5f6a`
- 2026-03-07: Unit tests complete (14 tests, all passing). Integration tests with testcontainers Redis passing (8 tests). `d7f8a9b`
- 2026-03-09: Refactored key naming to use tenant-prefixed format: `rl:{tenant_id}:{endpoint}:{window_start}`. `e2c3d4f`

## PRs

## Files

- src/services/redis-rate-store.ts
- src/services/redis-rate-store.test.ts
- src/services/redis-connection.ts
- src/services/redis-connection.test.ts
- src/types/rate-store.d.ts
- src/config/redis.yaml
- test/integration/redis-rate-store.integration.test.ts
- test/fixtures/redis-test-data.json

## Insights

- Sorted sets with score-as-timestamp provide O(log N) insertions and O(log N + M) range queries where M is the number of elements in the window. For a 1-minute window at 1000 req/min, this means ~1000 entries per key, which Redis handles efficiently.
- Key naming convention `rl:{tenant_id}:{endpoint}:{window_start}` allows efficient SCAN-based cleanup and per-tenant monitoring without secondary indexes.
- ioredis cluster mode requires explicit `natMap` configuration when Redis runs behind a NAT (common in Kubernetes). Without this, the client connects to internal pod IPs that are unreachable from the application namespace.

## Journal

### 2026-03-04 -- decision
**Summary:** Chose Redis sorted sets over simple key-value counters with TTL. Sorted sets support true sliding window semantics -- we can count requests in any arbitrary time range, not just fixed buckets. The memory overhead (~120 bytes per entry) is acceptable given our tenant count. Commit `a1b2c3d`.

### 2026-03-05 -- finding
**Summary:** Connection pool size of 10 per worker gives optimal throughput at our expected load. Below 5 connections, p99 latency spikes during burst traffic. Above 15, we see diminishing returns and risk exhausting Redis maxclients (default 10000) when scaling horizontally. Commit `b7d4e29`.

### 2026-03-06 -- decision
**Summary:** Set key TTL to 2x window duration (e.g., 2 minutes for a 1-minute window) rather than exact window duration. This provides a safety margin for clock skew between application servers and avoids premature key eviction during window boundary transitions. Commit `c4e5f6a`.
