---
name: next-actions
description: Lists every outstanding ticket across all the local epics under `.scratch/epics/` — what's ready to pick up now, what's in flight, and what's blocked and why. Use when the user asks what's outstanding, what to work on next, what's left, whether a ticket's PR is done and merged, or for a status overview; for one epic's full dependency graph reach for `cppcho:ticket-dag`, and to check an epic's tickets against the code reach for `cppcho:reconcile`.
argument-hint: "[epic-prefix] [--verify]"
---

# Next Actions

Answer one question: **what can I work on right now, across everything in flight?** Where `cppcho:ticket-dag` draws one epic's edges in depth, this skill sweeps every **local epic** — the ticket directories under `.scratch/epics/`, never Jira or Linear — and returns a flat, prioritised list: the view you want at the start of a session, before you know which epic you're picking up.

## 1. Find the epics

List every `.scratch/epics/[A-Z]*-*/tickets/` directory in the current repo — the prefix in the directory name is the epic's id, and the `epics/` subdirectory is what keeps other scratch material out of the sweep. An argument narrows it to that prefix or slug; otherwise take them all. No epics on disk → say so and stop — don't go hunting in other repos or inventing work from the conversation.

Shipped epics live at `.scratch/epics/_archive/<PREFIX>-<slug>/`, which that glob cannot reach, so they are already out of the sweep — don't widen it to find them. An argument naming an archived slug gets its `**Shipped:**` line and nothing else: it has no outstanding work, and a screen of ✅ rows answers a question nobody asked.

An epic whose `tickets/README.md` opens with a `**Cancelled:** <reason>` line is retired whole and leaves the sweep — it has no outstanding work by definition. An argument naming a cancelled slug gets the reason and nothing else, rather than a list of tickets nobody is going to pick up. That line is the one thing in `README.md` that step 2's "read the tickets, not the index" does not govern: it is a fact about the epic, not a claim about any ticket's status, so no ticket can contradict it.

## 2. Read the tickets, not the index

Read every `<NN>-*.md` in each epic, taking each ticket's id from its `# <PREFIX>-<NN> — <title>` heading. Status comes from the same rules `cppcho:ticket-dag` uses, so the two views never disagree:

- **Doneness** from the acceptance-criteria checkboxes: none ticked, some ticked, all ticked.
- **Edges** from the `**Blocked by:**` line.
- **Retirement** from a `**Superseded by:**` / `**Superseded:**` line — retired tickets aren't outstanding, skip them.
- **Off-graph parking** from a `**Status:**` line — a ticket whose blockers are all done but which is parked on an environment or another repo is *blocked*, not ready, and the parking reason is the useful fact.
- **Where the work went** from a `**Branch:**` line. Read it as written; the default sweep never asks `gh` whether a PR merged — this is a glance, not an audit. The one exception is when merge state *is* the question — the user asks "is it merged?", "did PCE-03 ship?", or passes `--verify`: then, for the epics the question names, run `gh pr view <url> --json state` once per PR on a Branch line and annotate those rows (`#1234 merged`/`open`/`closed`) instead of inferring state from the ticks.

- **What kind of change** from the `**What to build:**` paragraph — enough to say whether the slice is a migration, a refactor, a new batch, a proto contract, a guard on an RPC, or a manual verification.

**Ready** means what it means to `/cppcho:implement`: nothing ticked, every blocker fully done, nothing outside the graph parking it. That definition is the whole value — the list tells the user exactly what that skill would offer them.

Don't trust `tickets/README.md` or a spec's "current state" over the ticket files; when they disagree, report the drift in one line rather than reconciling it silently.

All of this reads the files against each other. Whether a ticket is still true *of the code* is a different and much more expensive question — `/cppcho:reconcile` answers that one, and this sweep only points at it.

## 3. Report

One compact block per epic, one line per ticket that matters, glyph first — the same glyphs `cppcho:ticket-dag` uses, so nothing needs a legend:

```
PCE · promo-credit-exchange
  🟢 PCE-02 Grant promo credits on development [S] — stack on feat/pc-spend
        Debug command behind a dev-only guard; no production path.
  🟢 PCE-03 Count exchanged credits in the monthly quota [S]
        Read side only: fold exchange rows into the existing quota sum.
  🟡 PCE-04 Exchange promo credits on an owned wallet — 3/5 · feat/pc-exchange #1234
        Usecase + carrier adapter: spend the ledger, deliver from the pool.
  🔴 PCE-08 parked on the dev database · 4 more waiting on tickets above

HA · herdr-auth
  🟢 HA-01 Log in with a magic link [M]
        New RPC, a token table migration, and the mail template behind it.

Pick: PCE-02 — smallest slice, continues the chain in flight.
```

- Within an epic: ready rows first, then in flight, then blocked. A ticket line is glyph, full id, title, and the size the ticket declares — plus the branch to stack on for 🟢 rows whose blocker carries one, and progress (`3/5`) and branch/PR for 🟡 rows. Nothing else on that line; every extra clause costs the scan the list exists for. Don't infer a size the ticket doesn't give: a judgement per ticket is what `cppcho:ticket-dag` is for, and this sweep is a glance.
- Under each 🟢 and 🟡 row, one indented line saying **what kind of change it is** — the layers it touches, in under fifteen words, no wrapping: `Spanner migration only: two dormant columns, no behaviour`, `Prefactor: two constants plus the test arithmetic around them`, `shared-proto field, false-by-default, nothing populates it`. This is deliberately not `cppcho:ticket-dag`'s summary: that one says what the slice does for the user, this one says what you would be editing, which is what decides whether you have an hour for it. Rows nobody can pick up don't get one — a parked 🔴 row's useful fact is its parking reason, and a collapsed count has no room.
- Done tickets don't get rows, and a fully-done epic doesn't get a block — mention it only in passing (`PCE done — archive it?`) or not at all. That mention is the one place archiving gets offered, because a finished epic stays in this sweep until somebody moves it, and this is where its being finished is visible. A cancelled epic gets the same passing mention with its reason (`HA cancelled — vendor SDK covers it`); don't drop it silently, since an epic that vanishes from the list reads as missing files. Outstanding work is the subject.
- Blocked tickets waiting only on siblings collapse to a trailing count. Name a 🔴 row individually only when it's parked on something *outside* the graph — that needs a different action from the reader than "finish the blocker".
- Contradictions (done ticket with an unfinished blocker, README/spec drift) get one line under the epic they belong to — they're worth more than any row, but still only a line each.

## 4. Close with the pick

End with a single `Pick:` line naming the ticket you'd start and why — shortest path to a demo, unblocks the most, or continues a chain in flight. Don't restate the list.

Nothing here writes to disk. When the list reveals the epic itself is wrong — a dead edge, a contradiction — hand it to `/cppcho:to-tickets`; when the user wants the shape behind one epic, hand it to `/cppcho:ticket-dag`; when rows look like they may have gone stale while other epics landed, name `/cppcho:reconcile <PREFIX>` and leave the checking to it.
