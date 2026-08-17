---
name: ticket-dag
description: Draws the ticket set under `.scratch/` as an ASCII dependency graph — one line per ticket with its size, status and blocking rails — so the frontier and the critical path are visible at a glance. Use whenever the user asks to see the ticket graph, the DAG, the dependency tree, what's blocking what, what to work on next, or where a feature's tickets stand; also reach for it after `/cppcho:to-tickets` writes or reshapes a set, since the graph is the fastest way to check the edges came out right.
argument-hint: "[feature-slug|issues-path]"
---

# Ticket DAG

Render a `.scratch/<feature-slug>/issues/` ticket set as one ASCII diagram: rails on the left carrying the blocking edges, one line per ticket carrying its number, title, a one-line summary and a size estimate.

The point is to answer three questions in a single glance — **what can I start now**, **how deep is the longest chain**, and **did the edges come out the way I meant**. A wall of ticket files answers none of those; a graph answers all three.

## 1. Resolve the feature slug

Every path depends on the slug, so settle it before reading anything. Take the first of these that lands:

1. An argument — either a bare slug, or any path inside `.scratch/<slug>/`. A bare slug resolves against `.scratch/<slug>/` first and `.scratch/_archive/<slug>/` only when nothing is live under that name.
2. The conversation — a spec or ticket already in play names its slug in its path. This is the common case when the graph is asked for right after a ticketing session.
3. A single `.scratch/*/issues/` directory on disk.
4. Several exist → list them and ask which. Don't guess between sibling features; drawing the wrong graph wastes the glance the user came for.

**A cancelled set.** A set whose `issues/README.md` opens with a `**Cancelled:** <reason>` line is retired whole. It is out of the running for rules 3 and 4 — never the set you draw by default, never an option in the list you ask about. Reached deliberately through rule 1 or 2 it still draws, since looking at what was killed is a fair thing to want; name the cancellation and its reason in the footer so the graph is never mistaken for live work. This line is the one thing in `README.md` that step 2's "read the tickets, not the index" does not govern: it is a fact about the set, not a claim about any ticket's status, so no ticket can contradict it.

**An archived set.** A set that shipped has been moved to `.scratch/_archive/<slug>/`, a level deeper than rules 3 and 4 glob, so it is out of the running for both without needing a rule of its own. Reached deliberately through rule 1 it draws normally — looking at how a shipped feature was sliced is a fair thing to want, and usually the reason someone types the slug. Carry its `README.md` `**Shipped:**` line into the footer, so a column of `✓` is never read as work sitting finished-but-unretired.

**A set that isn't written yet.** `/cppcho:to-tickets` draws the graph during its approval quiz, while the tickets are still a proposal in the conversation and no file exists. Take those rows from the proposal and skip the disk read for them — you don't need a slug to draw what you were handed. When the proposal revises a set that partly exists, read the written tickets as usual and fold the proposed ones in beside them: how the new work lands against tickets already in flight is the thing the reader is checking.

This needs no notation of its own. A proposed ticket is unstarted by definition, so it draws `●` or `○`, while `✓` and `◐` can only come from a file whose criteria have been ticked. The glyphs already separate what is frozen from what is still open to argument, which is the distinction the quiz turns on. Do note in the footer that unwritten rows carry **provisional numbers** — they're assigned when the files are written, so a number quoted from a proposal graph can move.

## 2. Read the tickets, not the index

Read every `.scratch/<slug>/issues/<NN>-*.md`. From each ticket take:

- **Number and title** from the `# <NN> — <title>` heading.
- **Edges** from the `**Blocked by:**` line — the numbers it names, or none.
- **Retirement** from a `**Superseded by:** <NN>` or `**Superseded:** <reason>` line.
- **Progress** from the acceptance-criteria checkboxes: none ticked, some ticked, all ticked.
- **Where the work went** from a `**Branch:**` line, if it has one — the branch each slice was committed to, and the PR where `/cppcho:implement` found one. Read it as written; never ask `gh` whether a PR is merged. The graph is a glance, and a network call per ticket makes it something you hesitate before drawing.
- **A `**Status:**` line if the ticket has one.** Not every set uses it, but where it exists it carries what checkboxes cannot — most usefully that a ticket is parked on something outside the graph, like an environment or another repo. `blocked — parked until X` is a fact no amount of counting boxes will tell you.

Checkboxes win on *doneness*, because they are maintained criterion by criterion as work happens while a header label is written once and left. The `**Status:**` line wins on *why* something cannot start. When the two disagree about whether a ticket is finished, draw the checkboxes and report the disagreement — don't pick silently.

Two other records make claims about the same tickets, and both drift. `issues/README.md` carries the graph as an index. A sibling `spec.md` often carries a "Current state" paragraph naming what has landed. Read both only to compare against the tickets, never to override them, and name any disagreement in the footer — a silently reconciled contradiction means the stale record won an argument nobody knew was happening. Expect drift in either direction: a spec can claim work landed whose boxes are empty, and claim work is still owed that is fully ticked.

**Flag a ticket marked done whose blocker is not.** That combination is impossible if both the edge and the record are right, so one of them is wrong, and it is worth more to the reader than anything else on the diagram. Say which two tickets, and if the ticket text makes the true order obvious, say which way round it must be.

Drop transitive edges before drawing. If a ticket lists both `04` and `01`, and `04` is already blocked by `01`, the `01` edge carries no information and adds a rail that crosses the whole diagram. Say in the footer which edges you collapsed so the user can fix the ticket if they'd rather the graph stayed literal.

## 3. Work out status, size and summary

**Status** decides the glyph. Filled means actionable, hollow means waiting:

| Glyph | Meaning |
|---|---|
| `✓` | done — every criterion ticked |
| `◐` | in flight — some criteria ticked |
| `●` | ready — nothing ticked, every blocker is `✓`, and nothing outside the graph is holding it |
| `○` | blocked — waiting on a blocker that isn't done, or on something outside the graph |
| `⊘` | superseded — retired, a dead end rather than work |

`●` is the frontier, and it is the same definition `/cppcho:implement` uses to pick up work. Keeping them identical is the whole value: the graph tells you what that skill would offer you. Which is also why `●` has to be earned — a ticket the reader picks up and immediately cannot start costs them more than one they were never offered.

An **unmerged PR on a blocker is not off-graph blocking.** A ticket whose blockers are `✓` draws `●` whether or not their PRs have landed — worktrees branch off unmerged branches routinely, and the `Branches:` line already tells the reader which one to stack on. Withholding `●` until a review finishes would idle the frontier on something no ticket is waiting for.

That is what folds off-graph blocking into `○`. A ticket whose blockers are all `✓` but whose `**Status:**` parks it on an environment is not startable, however green the graph looks. Draw it `○` and **name the cause in the footer**, because otherwise it is indistinguishable from a ticket waiting on a sibling — and the two need completely different actions from the reader. Resist a sixth glyph for it: the vocabulary earns its keep by being small enough to hold in your head, and the footer has room for the explanation.

**Size** is `[S]`, `[M]` or `[L]`. If a ticket declares one, use it. Otherwise infer from what the ticket actually asks for — the number of criteria, how many layers it crosses, whether it needs a new test harness, and what comparable code in the repo costs. Calibrate against a session: `[S]` is one sitting, `[M]` fills a session, `[L]` is at the edge of one and worth flagging as a split candidate.

Say in the footer **which** sizes were inferred rather than that some were — `sizes inferred for 02, 03, 05` tells the reader exactly which numbers to distrust, where a blanket note makes them discount all of them including the ones their own tickets declared. When every size was inferred, saying so plainly is the same statement and reads better.

**Summary** is one line, drawn from the ticket's "What to build" — the behaviour, not the layers. Write it so the line still makes sense read alone, since that is how it will be read.

## 4. Draw it

One row per ticket. Rails occupy the left, the text column starts at a fixed offset, and every ticket's line reads:

```
(NN) Title of the ticket short description of the behaviour [M]
```

Order rows so a ticket never appears above one of its blockers, and so chains stay vertically adjacent: emit the ready ticket that continues the chain you just emitted, and when nothing continues it, emit the ready ticket with the longest path still ahead of it. That keeps the deepest chain on the leftmost rail, which is what makes the critical path visible without tracing anything.

Assign rails the way a git log graph does. A ticket with several children keeps its own rail for the first and opens one new rail to its right for each of the others. A root emitted after rails are already open sits on the leftmost free rail and reaches its target with a horizontal line. Glyphs: `│` a rail continuing, `┬` a rail branching right on the parent's own row, `┐` the last rail opened, `▼` directly above a ticket fed from above, `┤` a rail taking a horizontal line from the left, `─` horizontal run.

**Worked example.** Eight tickets: `01→04`, `04→05`, `04→06`, `04→07`, `04→08`, `02→08`, `03→08`.

```
 ✓                 (01) Spend and restore Virtual Giga across expiry dates draws MB earliest-expiry-first, puts them back on the same dates [M]
 │
 ◐──┬──┬──┐        (04) Exchange Virtual Giga for Real Giga on an owned line has the pool carve N GB onto the holder's line, end to end [L]
 │  │  │  │
 ○  │  │  │        (05) Refuse an exchange that cannot proceed covers every rejection that leaves the holder's balance untouched [M]
    │  │  │
    ○  │  │        (06) Return the holder's and the pool's giga when IIJ refuses makes the holder whole first, reclaims stranded giga second [M]
       │  │
       ○  │        (07) Reach the exchange from the app through the BFF makes it callable by clients and closes the balance RPC gap too [S]
          │
 ●────────┤        (02) Grant Virtual Giga on development mints a chosen amount through the real grant path [S]
          │
 ●────────┤        (03) Count exchanged giga in the line's monthly quota stops the home screen reading more remaining than the total [S]
          ▼
          ○        (08) Verify the exchange on development end to end grants across two expiry dates, exchanges across both, reads the quota [S]
```

Then a footer, only with lines that have something to say:

```
 ✓ done · ◐ in flight · ● ready · ○ blocked · ⊘ superseded
 Frontier: 02, 03 · Critical path: 01 → 04 → 08 · Weight: 1 L, 3 M, 4 S · sizes inferred for 05, 06
 Branches: 04 feat/vg-exchange #1234 · 01 feat/vg-spend #1198
 08 is ○ despite its blockers being done: parked on the dev database, not on a ticket.
 07 is done while its blocker 04 is not — one of the two records is wrong.
 README lists 03 as blocked by 02, which is superseded; ticket 03 says 05. Drawn from the ticket.
```

**The `Branches:` line** gathers every ticket carrying a `**Branch:**` line into one run, in-flight rows first, then done ones. Keep it to one line however many there are — a block of one line per branch crowds out the footer's warnings, which are what the reader actually needs to see. It belongs in the footer rather than on the rows because a row already carries title, summary and size and is near the terminal's width; and it belongs on the diagram at all because deciding what to pick up is exactly when you need to know whether a blocker's code is on a branch you should stack on.

Only the glyph legend and the summary line are always there. Everything below them is conditional — a cancellation and its reason, a shipped set's close-out line, where the work went, off-graph blocking and its cause, a done-before-blocker contradiction, index or spec drift, collapsed transitive edges, `[L]` tickets that look splittable, a numbering gap with no superseded ticket behind it. Include a line when there is something to say and leave it out otherwise; a footer padded with "no drift detected" trains the reader to skip the part that matters. Prune the legend to the glyphs actually used, too — a set with nothing retired doesn't need `⊘` explained.

**When rails won't lay out cleanly**, don't force them. A set with several cross edges between middle layers produces rails that weave and a diagram nobody can read — which defeats the purpose. Fall back to layered blocks: a heading per depth, tickets listed under it, and each ticket's blockers named in its line. Losing the drawn edges costs less than losing legibility, and it's worth saying which you chose and why.

## 5. Offer the next move

The graph usually gets drawn because a decision is pending. Close by naming the move it points at rather than restating the diagram — the ready ticket to pick up, the `[L]` that wants splitting, the edge that looks wrong. One or two lines. The user drew the graph to see something; say what you see.

When the move is picking up a ticket whose blocker carries a `**Branch:**` line, name that branch alongside it. Which branch the work continues from is the first thing the next session needs and the last thing it can work out for itself.

Nothing here writes to disk. The graph is a view, and the ticket files stay the record — reshaping the set, superseding a ticket or repointing an edge is `/cppcho:to-tickets` work, so hand it over when the graph reveals the set is wrong rather than editing tickets from here.
