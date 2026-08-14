---
name: next-actions
description: Lists every outstanding ticket across all `.scratch/*/issues/` sets — what's ready to pick up now, what's in flight, and what's blocked and why. Use when the user asks what's outstanding, what to work on next, what's left, or for a status overview; for one set's full dependency graph, reach for `cppcho:ticket-dag` instead.
argument-hint: "[feature-slug]"
---

# Next Actions

Answer one question: **what can I work on right now, across everything in flight?** Where `cppcho:ticket-dag` draws one set's edges in depth, this skill sweeps every set and returns a flat, prioritised list — the view you want at the start of a session, before you know which feature you're picking up.

## 1. Find the sets

List every `.scratch/*/issues/` directory in the current repo. An argument narrows the sweep to that slug; otherwise take them all. No sets on disk → say so and stop — don't go hunting in other repos or inventing work from the conversation.

## 2. Read the tickets, not the index

Read every `<NN>-*.md` in each set. Status comes from the same rules `cppcho:ticket-dag` uses, so the two views never disagree:

- **Doneness** from the acceptance-criteria checkboxes: none ticked, some ticked, all ticked.
- **Edges** from the `**Blocked by:**` line.
- **Retirement** from a `**Superseded by:**` / `**Superseded:**` line — retired tickets aren't outstanding, skip them.
- **Off-graph parking** from a `**Status:**` line — a ticket whose blockers are all done but which is parked on an environment or another repo is *blocked*, not ready, and the parking reason is the useful fact.
- **Where the work went** from a `**Branch:**` line. Read it as written; never ask `gh` whether a PR merged — this is a glance, not an audit.

**Ready** means what it means to `/cppcho:implement`: nothing ticked, every blocker fully done, nothing outside the graph parking it. That definition is the whole value — the list tells the user exactly what that skill would offer them.

Don't trust `issues/README.md` or a spec's "current state" over the ticket files; when they disagree, report the drift in one line rather than reconciling it silently.

## 3. Report

One compact block per feature, one line per ticket that matters, glyph first — the same glyphs `cppcho:ticket-dag` uses, so nothing needs a legend:

```
vg-exchange
  ● 02 Grant Virtual Giga on development [S] — stack on feat/vg-spend
  ● 03 Count exchanged giga in the monthly quota [S]
  ◐ 04 Exchange VG for RG on an owned line — 3/5 · feat/vg-exchange #1234
  ○ 08 parked on the dev database · 4 more waiting on tickets above

herdr-auth
  ● 01 Log in with a magic link [M]

Pick: vg-exchange 02 — smallest slice, continues the chain in flight.
```

- Within a set: ready rows first, then in flight, then blocked. A ticket line is glyph, number, title, size — plus the branch to stack on for `●` rows whose blocker carries one, and progress (`3/5`) and branch/PR for `◐` rows. Nothing else; every extra clause on a row costs the scan the list exists for.
- Done tickets don't get rows, and a fully-done set doesn't get a block — mention it only in passing (`vg-exchange done`) or not at all. Outstanding work is the subject.
- Blocked tickets waiting only on siblings collapse to a trailing count. Name a `○` row individually only when it's parked on something *outside* the graph — that needs a different action from the reader than "finish the blocker".
- Contradictions (done ticket with an unfinished blocker, README/spec drift) get one line under the set they belong to — they're worth more than any row, but still only a line each.

## 4. Close with the pick

End with a single `Pick:` line naming the ticket you'd start and why — shortest path to a demo, unblocks the most, or continues a chain in flight. Don't restate the list.

Nothing here writes to disk. When the list reveals the set itself is wrong — a dead edge, a stale ticket — hand it to `/cppcho:to-tickets`; when the user wants to see the shape behind one set, hand it to `/cppcho:ticket-dag`.
