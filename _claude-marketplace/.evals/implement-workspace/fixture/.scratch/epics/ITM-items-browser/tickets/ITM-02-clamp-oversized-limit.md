# ITM-02 — clamp an oversized limit

**Size:** S
**Status:** open
**Blocked by:** —
**Spec:** [spec.md](../spec.md)

A caller can pass `?limit=100000` today and the store happily builds a page
that size. Clamp the effective limit to a maximum of 100, so a caller asking
for more gets 100 and the notice behaves as though 100 were what they asked
for.

## Acceptance criteria

- [ ] A limit above 100 is treated as 100 — the page holds at most 100 items
      and `Limit()` reports 100, not what the caller typed.
- [ ] A limit of 100 or below is passed through unchanged.
- [ ] A negative limit still means "no cap", as it does today.
- [ ] The cap notice, when it appears, names the clamped limit rather than the
      caller's number.
