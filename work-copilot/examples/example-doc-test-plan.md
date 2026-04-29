---
type: test-plan
parent: T000099
title: "Redis Rate Limit Backend — Regression Test Plan"
date: 2026-03-14
author: Priya Patel
status: In Progress
---

## Scope

This test plan covers the Redis sync layer for the rate limiting feature (T000099).
The following files were added or modified:

- `gateway/lib/redis-sync.ts` -- new file implementing non-blocking Redis INCR
  with connection failure fallback
- `gateway/lib/rate-limiter.ts` -- modified to call Redis sync after local bucket
  check passes
- `gateway/lib/config-cache.ts` -- modified to support webhook-based invalidation
- `gateway/config/redis.ts` -- new file with Redis connection pool configuration

## Regression Test Cases

| # | Test Case | Steps | Expected Result | Status |
|---|-----------|-------|-----------------|--------|
| 1 | Redis INCR increments global counter | Send 5 requests as tenant-01 | Redis key `ratelimit:tenant-01:window:*` has value 5 | Pass |
| 2 | Counter resets after window expiry | Send requests, wait 61 seconds, check Redis | Old window key expired via TTL; new key starts at 0 | Pass |
| 3 | Fallback on Redis connection timeout | Block Redis port via iptables, send request | Request succeeds with local-only limiting; log emits warning | Pass |
| 4 | Fallback on Redis command error | Send INCR to a key with wrong type | Graceful fallback to local bucket; error logged, no 500 | Pass |
| 5 | Reconnection after Redis recovery | Drop Redis, send 10 requests, restore Redis | First requests use local fallback; later requests sync to Redis | Pending |
| 6 | Multiple pods converge on global count | Send 50 requests to pod A, 50 to pod B | Redis global counter shows ~100 (within +/-2 for race) | Pass |
| 7 | Config cache invalidation on webhook | Change tier via admin API, check cache | Cache entry evicted within 1 second; next request uses new limit | Pass |
| 8 | Redis latency does not block request | Add 500ms latency to Redis via toxiproxy | Request completes in < 10ms; Redis sync happens asynchronously | Pending |

## Verification Steps

- [x] Local build succeeds (macOS + Linux CI)
- [x] L1 regression suite passes (48/48 tests green)
- [x] Manual reproduction of original bug confirms fix
- [x] Redis sync is non-blocking (confirmed via request timing under load)
- [ ] 48-hour soak test in staging environment
- [ ] Toxiproxy chaos tests for latency and partition scenarios

## Environments Tested

| Environment | Build | Result |
|------------|-------|--------|
| macOS 15.3, Node 20.11 | feature/F000099-rate-limiting@a3f7c21 | Pass |
| Ubuntu 24.04 (CI), Node 20.11 | feature/F000099-rate-limiting@a3f7c21 | Pass |
| Staging cluster (3 pods) | gateway:3.3.0-rc1 | Pass (manual tests) |
| Production canary (1 pod) | gateway:3.3.0-rc1 | Pending |
