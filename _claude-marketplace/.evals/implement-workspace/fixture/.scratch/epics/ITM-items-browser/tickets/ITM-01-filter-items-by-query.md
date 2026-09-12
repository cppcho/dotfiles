# ITM-01 — filter items by query

**Size:** S
**Status:** open
**Blocked by:** —
**Spec:** [spec.md](../spec.md)

Readers browsing `/items` want to narrow the list to one service or one name
prefix without scrolling. Add a `?q=` parameter that keeps only items whose
name or service contains the query as a substring, case-insensitively.

Filtering is a selection rule, so it belongs on `Store.Page` alongside the cap,
per the spec. The handler passes the query through and renders what comes back.

## Acceptance criteria

- [ ] `GET /items?q=billing` returns only the three items whose service is
      `billing`, still sorted by name.
- [ ] `GET /items?q=OLD-SERVICE` returns `delta-worker` — matching ignores case.
- [ ] `GET /items?q=` and a missing `q` both behave as they do today: every
      item, sorted by name.
- [ ] The query and the cap compose correctly, and the cap notice keeps the
      meaning the spec gives it.
