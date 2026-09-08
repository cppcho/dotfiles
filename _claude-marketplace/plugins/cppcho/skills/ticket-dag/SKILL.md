---
name: ticket-dag
description: Draws a local epic's tickets under `.scratch/epics/` as an emoji dependency graph — one line per ticket with its size, status, target repository and blocking rails, plus every PR carrying a slice — so the frontier and the critical path are visible at a glance. Use whenever the user asks to see the ticket graph, the DAG, the dependency tree, what's blocking what, what to work on next, which repos an epic spans, which PRs it has open, or where a feature's tickets stand; also reach for it after `/cppcho:to-tickets` writes or reshapes an epic, since the graph is the fastest way to check the edges came out right.
argument-hint: "[epic-prefix|tickets-path]"
---

# Ticket DAG

Render a local epic — `.scratch/epics/<PREFIX>-<slug>/tickets/` — as one diagram: rails on the left carrying the blocking edges, one line per ticket carrying its id, title, a one-line summary, the repository it changes when that isn't the epic's own, and a size estimate. Epic and ticket here mean these files on disk, never a Jira or Linear issue.

The point is to answer three questions in a single glance — **what can I start now**, **how deep is the longest chain**, and **did the edges come out the way I meant**. A wall of ticket files answers none of those; a graph answers all three.

## 1. Resolve the epic

Every path depends on which epic you're drawing, so settle it before reading anything. Take the first of these that lands:

1. An argument — a prefix (`PCE`), a slug, or any path inside the epic's directory. A prefix or slug resolves against `.scratch/epics/<PREFIX>-<slug>/` first and `.scratch/epics/_archive/` only when nothing is live under that name.
2. The conversation — a spec or ticket already in play names its epic in its path. This is the common case when the graph is asked for right after a ticketing session.
3. A single `.scratch/epics/[A-Z]*-*/` directory on disk.
4. Several exist → list them by prefix and ask which. Don't guess between sibling epics; drawing the wrong graph wastes the glance the user came for.

**A cancelled epic.** An epic whose `tickets/README.md` opens with a `**Cancelled:** <reason>` line is retired whole. It is out of the running for rules 3 and 4 — never the epic you draw by default, never an option in the list you ask about. Reached deliberately through rule 1 or 2 it still draws, since looking at what was killed is a fair thing to want; name the cancellation and its reason in the footer so the graph is never mistaken for live work. This line is the one thing in `README.md` that step 2's "read the tickets, not the index" does not govern: it is a fact about the epic, not a claim about any ticket's status, so no ticket can contradict it.

**An archived epic.** An epic that shipped has been moved to `.scratch/epics/_archive/<PREFIX>-<slug>/`, which rules 3 and 4 cannot glob, so it is out of the running for both without needing a rule of its own. Reached deliberately through rule 1 it draws normally — looking at how a shipped feature was sliced is a fair thing to want, and usually the reason someone types the slug. Carry its `README.md` `**Shipped:**` line into the footer, so a column of ✅ is never read as work sitting finished-but-unretired.

**An epic that isn't written yet.** `/cppcho:to-tickets` draws the graph during its approval quiz, while the tickets are still a proposal in the conversation and no file exists. Take those rows from the proposal and skip the disk read for them — you don't need a slug to draw what you were handed. When the proposal revises an epic that partly exists, read the written tickets as usual and fold the proposed ones in beside them: how the new work lands against tickets already in flight is the thing the reader is checking.

This needs no notation of its own. A proposed ticket is unstarted by definition, so it draws 🟢 or 🔴, while ✅ and 🟡 can only come from a file whose criteria have been ticked. The glyphs already separate what is frozen from what is still open to argument, which is the distinction the quiz turns on. Do note in the footer that unwritten rows carry **provisional ids** — the numbers are assigned when the files are written, so an id quoted from a proposal graph can move.

## 2. Read the tickets, not the index

Read every `.scratch/epics/<PREFIX>-<slug>/tickets/<NN>-*.md`. From each ticket take:

- **Id and title** from the `# <PREFIX>-<NN> — <title>` heading.
- **Edges** from the `**Blocked by:**` line — the ids it names, or none.
- **Retirement** from a `**Superseded by:** <PREFIX>-<NN>` or `**Superseded:** <reason>` line.
- **Progress** from the acceptance-criteria checkboxes: none ticked, some ticked, all ticked.
- **Where the work went** from a `**Branch:**` line, if it has one — the branch each slice was committed to, and the PR where `/cppcho:implement` found one. Read it as written; never ask `gh` whether a PR is merged. The graph is a glance, and a network call per ticket makes it something you hesitate before drawing.
- **Which repository it changes** from a `**Repo:**` line — one repository, several, or `none` for a slice that changes no code at all.
- **A `**Status:**` line if the ticket has one.** Not every epic uses it, but where it exists it carries what checkboxes cannot — most usefully that a ticket is parked on something outside the graph, like an environment or another repo. `blocked — parked until X` is a fact no amount of counting boxes will tell you.

**The epic's home repository** is the one whose working tree holds `.scratch` — `basename "$(git rev-parse --show-toplevel)"`, once for the whole graph. It is the default every row is read against, which is what keeps a twenty-row single-repo epic from carrying the same token twenty times. Tickets written before the `**Repo:**` line existed won't have one; fall back to the repository their `**Branch:**` line's PR link points at, since an org-qualified link like `kouzoh/platform-proto#28241` names it outright while a bare `#5091` is the home repo by convention. Read that value as a paragraph rather than a line — a slice landing in three repositories wraps, and the link that names the foreign one is routinely on the second line, so a match on the `**Branch:**` line alone misses it and reports the repository as unknown when the ticket says it plainly.

Where neither line exists — an unstarted ticket in an older epic — the repository is genuinely unknown. Don't infer one from the behaviour the ticket describes: "serve the section" reads the same whether it lands in the backend or the BFF, and a row confidently tagged with the wrong repository sends the reader to the wrong checkout. Say so instead, and offer the backfill: `/cppcho:to-tickets` can add the line where it is readable, which is a one-time cost against a guess re-made on every glance.

Checkboxes win on *doneness*, because they are maintained criterion by criterion as work happens while a header label is written once and left. The `**Status:**` line wins on *why* something cannot start. When the two disagree about whether a ticket is finished, draw the checkboxes and report the disagreement — don't pick silently.

Two other records make claims about the same tickets, and both drift. `tickets/README.md` carries the graph as an index. A sibling `spec.md` often carries a "Current state" paragraph naming what has landed. Read both only to compare against the tickets, never to override them, and name any disagreement in the footer — a silently reconciled contradiction means the stale record won an argument nobody knew was happening. Expect drift in either direction: a spec can claim work landed whose boxes are empty, and claim work is still owed that is fully ticked.

**Flag a ticket marked done whose blocker is not.** That combination is impossible if both the edge and the record are right, so one of them is wrong, and it is worth more to the reader than anything else on the diagram. Say which two tickets, and if the ticket text makes the true order obvious, say which way round it must be.

**A blocker carrying another epic's prefix is a real edge.** Read that ticket from its own epic and let it gate this row exactly as a sibling would — ids are written in full precisely so a cross-epic edge is followable. Don't draw the foreign epic's rows; name the blocking id in the footer, so a row sitting 🔴 behind work that isn't on the diagram doesn't read as a mistake.

Drop transitive edges before drawing. If a ticket lists both `PCE-04` and `PCE-01`, and `PCE-04` is already blocked by `PCE-01`, the `PCE-01` edge carries no information and adds a rail that crosses the whole diagram. Say in the footer which edges you collapsed so the user can fix the ticket if they'd rather the graph stayed literal.

## 3. Work out status, size and summary

**Status** decides the glyph:

| Glyph | Meaning |
|---|---|
| ✅ | done — every criterion ticked |
| 🟡 | in flight — some criteria ticked |
| 🟢 | ready — nothing ticked, every blocker is ✅, and nothing outside the graph is holding it |
| 🔴 | blocked — waiting on a blocker that isn't done, or on something outside the graph |
| 🚫 | superseded — retired, a dead end rather than work |

Read the three circles as a traffic light: 🟢 go, 🟡 moving, 🔴 stopped. Colour is the whole point — it is what lets a reader find the frontier in a column of twenty rows without tracing anything, so keep the emoji even where a monochrome symbol would fit the terminal more tidily.

🟢 is the frontier, and it is the same definition `/cppcho:implement` uses to pick up work. Keeping them identical is the whole value: the graph tells you what that skill would offer you. Which is also why 🟢 has to be earned — a ticket the reader picks up and immediately cannot start costs them more than one they were never offered.

An **unmerged PR on a blocker is not off-graph blocking.** A ticket whose blockers are ✅ draws 🟢 whether or not their PRs have landed — worktrees branch off unmerged branches routinely, and the `PRs:` line already tells the reader which one to stack on. Withholding 🟢 until a review finishes would idle the frontier on something no ticket is waiting for.

That is what folds off-graph blocking into 🔴. A ticket whose blockers are all ✅ but whose `**Status:**` parks it on an environment is not startable, however green the graph looks. Draw it 🔴 and **name the cause in the footer**, because otherwise it is indistinguishable from a ticket waiting on a sibling — and the two need completely different actions from the reader. Resist a sixth glyph for it: the vocabulary earns its keep by being small enough to hold in your head, and the footer has room for the explanation.

**Size** is `[S]`, `[M]` or `[L]`. If a ticket declares one, use it. Otherwise infer from what the ticket actually asks for — the number of criteria, how many layers it crosses, whether it needs a new test harness, and what comparable code in the repo costs. Calibrate against a session: `[S]` is one sitting, `[M]` fills a session, `[L]` is at the edge of one and worth flagging as a split candidate.

Say in the footer **which** sizes were inferred rather than that some were — `sizes inferred for PCE-02, PCE-03, PCE-05` tells the reader exactly which ids to distrust, where a blanket note makes them discount all of them including the ones their own tickets declared. When every size was inferred, saying so plainly is the same statement and reads better.

**Summary** is one line, drawn from the ticket's "What to build" — the behaviour, not the layers. Write it so the line still makes sense read alone, since that is how it will be read.

**The repository tag is the exception to a row carrying only what every row carries.** Tag a row only when its repository is not the epic's home one — `· platform-proto`, `· kouzoh-grpc-federation`, `· none` for a slice that changes no code, `· repo unknown` where no ticket line says. An epic predating the `**Repo:**` line is the case to watch: when the unknowns outnumber the rows you could actually read, tagging each of them writes the same sentence seven times and buries the two tags that carry information. Gather them into one footer line there — `repo unrecorded for OTG-02, 08, 09, 10, 11, 12, 13` — and tag individually only while unknowns are the exception. The footer states the home repo once, so an untagged row means "the repo you're standing in" and the tags are the rows that will send you somewhere else. That asymmetry is deliberate: tagging all twenty rows of a single-repo epic spends fourteen cells per row to say nothing, while a proto row sitting unmarked among backend rows is the mistake that costs a session. A slice spanning repositories names them in landing order — `· platform-proto → mercari-mvno-jp` — because the order is the part that decides what you can start.

## 4. Draw it

One row per ticket. Rails occupy the left, the text column starts at a fixed offset, and every ticket's line reads:

```
(PCE-NN) Title of the ticket short description of the behaviour · <repo, if not the home one> [M]
```

Order rows so a ticket never appears above one of its blockers, and so chains stay vertically adjacent: emit the ready ticket that continues the chain you just emitted, and when nothing continues it, emit the ready ticket with the longest path still ahead of it. That keeps the deepest chain on the leftmost rail, which is what makes the critical path visible without tracing anything.

Assign rails the way a git log graph does. A ticket with several children keeps its own rail for the first and opens one new rail to its right for each of the others. A root emitted after rails are already open sits on the leftmost free rail and reaches its target with a horizontal line. Rail glyphs: `│` a rail continuing, `┬` a rail branching right on the parent's own row, `┐` the last rail opened, `▼` directly above a ticket fed from above, `┤` a rail taking a horizontal line from the left, `─` horizontal run.

**Rails sit on a three-cell pitch, and a status emoji eats two of them.** Every emoji in the legend renders double-width, so a node fills its rail's first two cells and leaves one — spend it on `─` when a horizontal run leaves the node and a space when nothing does, while a rail merely passing through the row draws `│` plus two spaces. Count cells, not characters, when padding to the text column too. Get this wrong and every rail right of a node slips by one, which turns the diagram into something harder to read than the ticket files it stands in for.

**Worked example.** Eight tickets: `PCE-01→04`, `04→05`, `04→06`, `04→07`, `04→08`, `02→08`, `03→08`.

```
 ✅                (PCE-01) Spend and restore promo credits across expiry dates draws the earliest-expiring grant first, puts them back on the same dates [M]
 │
 🟡─┬──┬──┐        (PCE-04) Exchange promo credits for store credit on an owned wallet has the pool carve N credits onto the holder's wallet, end to end [L]
 │  │  │  │
 🔴 │  │  │        (PCE-05) Refuse an exchange that cannot proceed covers every rejection that leaves the holder's balance untouched [M]
    │  │  │
    🔴 │  │        (PCE-06) Return the holder's and the pool's credits when the provider refuses makes the holder whole first, reclaims stranded credits second [M]
       │  │
       🔴 │        (PCE-07) Reach the exchange from the app through the BFF makes it callable by clients and closes the balance RPC gap too · billing-bff [S]
          │
 🟢───────┤        (PCE-02) Grant promo credits on development mints a chosen amount through the real grant path [S]
          │
 🟢───────┤        (PCE-03) Count exchanged credits in the wallet's monthly quota stops the home screen reading more remaining than the total [S]
          ▼
          🔴       (PCE-08) Verify the exchange on development end to end grants across two expiry dates, exchanges across both, reads the quota · none [S]
```

Then a footer, only with lines that have something to say:

```
 ✅ done · 🟡 in flight · 🟢 ready · 🔴 blocked · 🚫 superseded
 Frontier: PCE-02, PCE-03 · Critical path: PCE-01 → 04 → 08 · Weight: 1 L, 3 M, 4 S · sizes inferred for PCE-05, PCE-06
 Repo: billing-api · also billing-bff (PCE-07) · PCE-08 changes no repo
 PRs: billing-api PCE-04 feat/pc-exchange #1234, PCE-01 #1198 merged · billing-bff PCE-07 #4276 open
 PCE-08 is 🔴 despite its blockers being done: parked on the dev database, not on a ticket.
 PCE-07 is done while its blocker PCE-04 is not — one of the two records is wrong.
 README lists PCE-03 as blocked by PCE-02, which is superseded; the ticket says PCE-05. Drawn from the ticket.
```

**The `Repo:` line** names the home repository first — the default every untagged row was read against — then enumerates the foreign ones with the ids that go to each, and closes with the repo-less and unknown rows. Without it the tags on the rows are ambiguous: a reader cannot tell whether an untagged row lands where they're standing or simply went unrecorded. Enumerating the foreign rows repeats what their tags already say, and earns it anyway on a thirteen-row epic — "which of these are proto PRs" is a question the reader shouldn't have to answer by scanning a column.

**The `PRs:` line** gathers every ticket carrying a `**Branch:**` line, grouped by repository, in-flight rows first and done ones after. Naming the repo once per group is what makes the numbers readable — `#4276` alone is meaningless when an epic spans three repositories with three numbering spaces, and org-qualifying every entry instead would eat the line. Give a branch name only for rows still in flight: a merged slice's branch is dead and its PR link is the durable record, while an unmerged one's branch is the thing a reader needs in order to stack on it. Carry merge state only where the ticket's own line says it, never by asking `gh`.

Keep it to one line, breaking per repository group with a continuation indent only when it genuinely won't fit — a block of one line per branch crowds out the footer's warnings, which are what the reader actually needs to see. All of this belongs in the footer rather than on the rows because a row already carries title, summary, repo tag and size and is near the terminal's width; and it belongs on the diagram at all because deciding what to pick up is exactly when you need to know whether a blocker's code is on a branch you should stack on.

Only the glyph legend, the summary line and the `Repo:` line are always there. Everything below them is conditional — a cancellation and its reason, a shipped epic's close-out line, where the work went, rows whose repository nothing on disk records, off-graph blocking and its cause, a done-before-blocker contradiction, index or spec drift, collapsed transitive edges, `[L]` tickets that look splittable, a gap in the numbering with no superseded ticket behind it. Include a line when there is something to say and leave it out otherwise; a footer padded with "no drift detected" trains the reader to skip the part that matters. Prune the legend to the glyphs actually used, too — an epic with nothing retired doesn't need 🚫 explained.

**When rails won't lay out cleanly**, don't force them. An epic with several cross edges between middle layers produces rails that weave and a diagram nobody can read — which defeats the purpose. Fall back to layered blocks: a heading per depth, tickets listed under it, and each ticket's blockers named in its line. Losing the drawn edges costs less than losing legibility, and it's worth saying which you chose and why.

## 5. Offer the next move

The graph usually gets drawn because a decision is pending. Close by naming the move it points at rather than restating the diagram — the ready ticket to pick up, the `[L]` that wants splitting, the edge that looks wrong. One or two lines. The user drew the graph to see something; say what you see.

When the move is picking up a ticket whose blocker carries a `**Branch:**` line, name that branch alongside it. Which branch the work continues from is the first thing the next session needs and the last thing it can work out for itself. Name the repository too when the pick is not in the home one — it decides which checkout the session opens in, so a pick that reads as local when it isn't sends the reader to the wrong tree before they have read a line of code.

Nothing here writes to disk. The graph is a view, and the ticket files stay the record — reshaping the epic, superseding a ticket or repointing an edge is `/cppcho:to-tickets` work, so hand it over when the graph reveals the epic is wrong rather than editing tickets from here. When what the graph reveals is a suspicion rather than a mistake — rows that may have gone stale while other epics landed — `/cppcho:reconcile <PREFIX>` is what checks them against the code.
