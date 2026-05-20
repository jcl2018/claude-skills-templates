# TODOS

## Active work

### Build a new caching layer for tracker reads (P3, L)

The current tracker read path opens every YAML frontmatter on every /CJ_suggest
invocation. With 50+ trackers this gets noticeable. Adding a caching layer
keyed by mtime would help. This is sized L deliberately because there are
multiple touch points (suggest, scaffold, qa) and the cache invalidation logic
matters. Body has no sensitive surface and no design-needed keywords; the only
gate this should hit is the size-L cap.
