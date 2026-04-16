---
name: "List command crashes on empty JSON file"
type: rca
parent: "D000001_empty_json_crash"
created: "2026-03-12"
updated: "2026-03-12"
author: "chjiang"
---

## Summary

`reading-list list` panics with `unexpected end of JSON input` when
~/.reading-list.json is empty (0 bytes) or contains truncated JSON.

## Root Cause

`store.Load()` at store.go:42 calls `json.Unmarshal(data, &books)` without
checking if `data` is empty. `json.Unmarshal` on a zero-length byte slice
returns an error, but the error is not checked. Instead, the code proceeds
to iterate over the nil `books` slice, which doesn't panic, but a subsequent
`len(books)` comparison in the table formatter at list.go:28 receives the
unmarshal error as a panic in a deferred function.

```go
// store.go:42 — the bug
func Load() ([]Book, error) {
    data, err := os.ReadFile(filepath)
    if err != nil {
        return nil, err
    }
    var books []Book
    json.Unmarshal(data, &books)  // ← error not checked
    return books, nil
}
```

## Contributing Factors

1. No input validation on file contents before parsing
2. Error from `json.Unmarshal` silently discarded
3. No test case for empty file scenario
4. Interrupted writes (Ctrl+C during `add`) leave truncated files

## Fix

```go
func Load() ([]Book, error) {
    data, err := os.ReadFile(filepath)
    if err != nil {
        if os.IsNotExist(err) {
            return []Book{}, nil  // no file = empty list
        }
        return nil, err
    }
    if len(data) == 0 {
        return []Book{}, nil  // empty file = empty list
    }
    var books []Book
    if err := json.Unmarshal(data, &books); err != nil {
        // Corrupt file: backup and start fresh
        os.Rename(filepath, filepath+".bak")
        return []Book{}, fmt.Errorf("corrupt data file backed up to %s.bak: %w", filepath, err)
    }
    return books, nil
}
```

## Prevention

- Add empty-file and corrupt-file test cases to store_test.go
- Lint rule: all json.Unmarshal calls must check the returned error
