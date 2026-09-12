# items-browser

A small HTTP service that lists items from an in-memory store.

## Commands

```bash
make build   # go build ./...
make test    # go test ./...
make lint    # go vet ./...
make check   # the gate CI treats as the bar
make run     # serve on :8099
```

## Conventions

- Rendering stays in `main.go`; paging and selection logic stays in `internal/store`.
- `Page` is the only type the handler reads. Add fields to it rather than
  returning extra values alongside it.
