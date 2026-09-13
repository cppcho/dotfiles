# ITM-03 — cover sort order with table-driven cases

**Size:** S
**Status:** open
**Blocked by:** —
**Spec:** [spec.md](../spec.md)

`TestPageSortsByName` checks two positions in one fixture, so it would still
pass against an implementation that sorted only the ends. Replace it with
table-driven cases over several stores — already sorted, reverse sorted, equal
prefixes, a single item, empty — asserting the full expected order each time.

No production code changes. This ticket is test coverage only.

## Acceptance criteria

- [ ] `TestPageSortsByName` is replaced by a table-driven test asserting the
      complete order for each case, not individual positions.
- [ ] The empty store and the single-item store are both covered.
- [ ] `internal/store/store.go` and `main.go` are untouched by this ticket.
