# ITM — items browser

The `/items` endpoint lists every item in the store, sorted by name, capped by
`?limit=`. When the cap withholds rows, the response ends with a notice naming
the cap.

## Decisions

- **Paging logic lives in `internal/store`.** The handler renders `Page` and
  reads nothing else. Selection rules that change which rows appear belong on
  `Store.Page`, not in `main.go`.
- **The notice is about the cap only.** It tells the reader that rows exist
  which the cap kept off this page. It is not a general "some rows are missing"
  signal.
- **One in-memory store.** No database, no persistence. The seed list in
  `main.go` is the data.
