---
name: to-tickets
description: Breaks a plan or spec into tracer-bullet tickets under `.scratch/epics/`, each a vertical slice declaring what blocks it. Also owns the epic afterwards — reshaping it, cancelling it, and archiving it once it ships.
argument-hint: "[spec-path|issue-number|issue-url]"
---

# To Tickets

Break a plan, spec, or conversation into a **local epic** — a directory of **local tickets** under `.scratch/epics/`, each a tracer-bullet vertical slice declaring the tickets that **block** it. Epic and ticket here mean these files on disk, never a Jira or Linear issue. The epic is what `/cppcho:implement` then works through, one ticket per session.

## 1. Gather context

Work from whatever is already in the conversation context. If the user passes a reference (a spec path such as `.scratch/epics/<PREFIX>-<slug>/spec.md`, an issue number or URL) as an argument, fetch it and read its full body and comments.

Settle the epic's **prefix and slug** early, since every path below and every ticket id depends on them. A spec path hands them to you. Otherwise reuse an existing `.scratch/epics/<PREFIX>-<slug>/` that already covers this work rather than opening a sibling beside it, and only coin a new epic when none does — saying which epic you chose rather than asking.

Coin the **prefix** from the initials of the slug's significant words, dropping `in/the/a/of/and/to/on/for`, uppercased, two letters minimum: `promo-credit-exchange` → `PCE`. One `ls .scratch/epics/` lists every prefix in use, because the prefix lives in the directory name and nowhere else — the filesystem is what keeps it unique. On a collision, extend with the next significant word's initial, or take the letter that actually distinguishes this epic: `promo-credit-wallet-scoped-balances` → `PCB` beats `PCWS`, which misreads as its `promo-credit-wallet-statement-view` neighbour.

An epic under `.scratch/epics/_archive/` is not a candidate for reuse. It shipped, and its rows of ✅ are exactly what archiving took out of view. Read it for how the feature was sliced last time, then coin a new prefix and slug for the follow-up and leave the archive where it is.

Then read what is already on disk. If `.scratch/epics/<PREFIX>-<slug>/tickets/` exists, read every ticket in it before drafting anything, because tickets in flight are load-bearing: `/cppcho:implement` ticks acceptance criteria in place as it works, so a ticket file is the only record of what is done. Regenerating the epic from the conversation would erase that.

- A ticket with any criterion ticked, or that the conversation says is underway, is **frozen** — leave its text and its number alone. When a change of direction invalidates a frozen ticket, don't edit it — **supersede** it (see "When the plan changes").
- Revise unstarted tickets freely, but leave a `**Branch:**` line alone if one is there. `/cppcho:implement` writes it to say where a slice's code went, and it is not derivable from anything else once dropped.
- New work becomes new tickets, appended.
- A ticket written before the `**Repo:**` line existed can have one added, frozen or not. It is one of two exceptions to leaving frozen text alone, because it records where the work went rather than what the work is — a frozen ticket's `**Branch:**` line usually names the repository outright, so filling it in is transcription, not a change of plan. Add it where you can read it off the ticket and leave it off where you can't; a guessed repository is worse than an absent one.
- An unticked criterion on a frozen ticket that only the real system can prove (step 3) may move to a verification ticket, frozen or not — the other exception, for the same reason: it moves where the proof happens, not what the work is. Strike it in place with a pointer, `~~<criterion>~~ — moved to <PREFIX>-<NN>`, and write it on the verification ticket under the next free number or an existing one that already runs that walkthrough. A ticked one stays where it is: it was proved, and the box is the record.

## 2. Explore the codebase

If you have not already explored the codebase, do so to understand the current state of the code. Read `.scratch/context.md` if it exists and use its domain glossary vocabulary in ticket titles and descriptions.

Look for opportunities to prefactor the code to make the implementation easier — "make the change easy, then make the easy change." A prefactor becomes its own ticket that blocks the slices needing it.

The fake the spec's boundary calls for is a prefactor too, when more than one ticket tests through it: one ticket builds it and decides, against the code, how a test plugs it in — a new parameter or wrapper, if one is needed, is added here and nowhere else — and its criteria name that mechanism ("a test imports the fake and passes it to …"), so later tickets inherit it instead of inventing one. Every ticket that tests through it is blocked by that one. Left to each ticket, the fake gets built once per session — one epic ended with two fakes of the same service, the second mocking an export the first had renamed.

## 3. Draft vertical slices

Break the work into **tracer bullet** tickets.

<vertical-slice-rules>

- Each slice cuts a narrow but COMPLETE path through every layer (schema, API, UI, tests) — vertical, NOT a horizontal slice of one layer
- A completed slice is demoable or verifiable on its own
- Each slice is sized to fit in a single fresh context window

</vertical-slice-rules>

Give each ticket its **blocking edges** — the other tickets that must complete before it can start. A ticket with no blockers can start immediately.

Draw an edge, or merge the tickets, when two of them would each add or reshape the same piece — the same export, the same fake, the same client wrapper — even when neither behaviour needs the other. Tickets with no edge between them get built in parallel sessions, and two sessions shaping one piece produce one concept under two names and a mock of a symbol the sibling renamed; in one epic the behaviours were independent and the code was not, and both PRs needed a refactor pass before review. Two tickets that only edit lines in one file can stay parallel: vertical slices usually all touch the core handler or store, and chaining them for that alone empties the frontier.

**Implementation tickets and verification tickets are different tickets.** An implementation ticket changes code, and every criterion on it is one the session building it can prove before it stops: against a fixture, in a self-test, or on a local run of the changed code. A verification ticket proves the feature on the real system — a round run on the development environment, a reviewer acting in the real database, a message arriving in the real channel, a second machine picking up where the first stopped, a PR opened because a real result cleared a gate. It has `**Repo:** none — verification on development` and is blocked by the implementation tickets it exercises.

Keep them apart because of what a real-system criterion does to an implementation ticket. `/cppcho:implement` builds one ticket per session and ticks as it goes; a criterion it cannot reach from a fixture is still unticked when the PR merges, so the ticket reads as in flight indefinitely, `cppcho:next-actions` keeps offering it, and whoever eventually ticks it does so from a run nobody can repeat — or ticks it on faith. One epic reached eight such tickets, each with its code merged and one or two boxes open, every box waiting on a real round that a separate ticket already described. The criterion was never wrong, only misfiled: moving it to the ticket that runs the round costs nothing and lets the implementation ticket close with its PR.

The spec usually names the seam — "a test fakes a run directory and never reaches the chat, the database or the channel" — and when it doesn't, draw it once for the epic: what a test fakes, and what only the real system shows. Then write every criterion on its side of that line. Cut verification tickets by the walkthrough that proves them together, not one per implementation ticket: one real round through a loop proves the new columns, the links, the gate and the adopt path at once, while a concern that round will not naturally meet (running with a channel left out) gets a ticket of its own. A verification ticket's criteria read as that walkthrough — who does what on the real system, and what they see — and a one-off operation on live data (republishing the pages that already exist) is a step in it, not a behaviour anyone builds.

**Wide refactors are the exception to vertical slicing.** When one mechanical change — renaming a column, retyping a shared symbol — has a **blast radius** fanning across the whole codebase, a single edit breaks thousands of call sites at once and no vertical slice can land green. Sequence it as **expand–contract** instead: one ticket to **expand** (add the new form beside the old, so nothing breaks), then a **migrate** ticket per batch of call sites sized by blast radius (per package, per directory), each blocked by the expand and green on its own because the old form still exists, then a **contract** ticket blocked by every batch to delete the old form. When even the batches can't stay green alone, keep the sequence but let them share an integration branch that all block a final integrate-and-verify ticket — green is promised only there.

## 4. Settle the shape yourself

Granularity and edges are yours to decide from the rules above — don't stop to have the breakdown approved. A graph is quicker to read than four files, but only once; a breakdown held for approval costs a round trip every time, and reshaping an epic afterwards is a motion this skill already owns.

Where a call could reasonably have gone the other way — a slice that could be one ticket or two, an edge you chose not to draw — make the call, then name it in one line under the graph that closes step 5, so it can be redirected. Two such lines is plenty; a list of open questions is the approval step coming back in disguise.

## 5. Write the tickets

Write one file per ticket under `.scratch/epics/<PREFIX>-<slug>/tickets/<NN>-<ticket-slug>.md`, using the template below — one ticket per file, never a single combined file. Write them with the Write tool, not a shell chain: Write takes an absolute path and creates the directory, so a failed `mkdir` or `cd` cannot land files somewhere else. One shell chain overwrote the repo's README that way.

A ticket's **id** is `<PREFIX>-<NN>` — the directory supplies the prefix, so filenames keep the bare number and everything written *inside* a file spells the id in full. That is what makes `grep -r PCE-02` find every reference to a ticket from anywhere, including other epics.

Number tickets in dependency order the first time you write an epic, blockers first, because it makes the directory readable at a glance. After that the number is **identity, not position**: a ticket added in a later pass takes the next free number even when it belongs early in the order. Renumbering silently invalidates every "Blocked by" reference and every link from work already in flight, and buys only cosmetic tidiness. The blocking edges carry the order; the numbers just name things.

Keep each ticket to the template's parts. A ticket carries the behaviour and its acceptance criteria; leave out restated context, rationale sections, and implementation notes.

<ticket-template>

# <PREFIX>-<NN> — <Ticket title>

**What to build:** the end-to-end behaviour this ticket makes work, from the user's perspective — not a layer-by-layer implementation list.

**Blocked by:** `<PREFIX>-<NN> — <title>` for each ticket that gates this one — a ticket in another epic is named by its own prefix, which is the whole reason ids are written in full. Or "None — can start immediately".

**Spec:** [spec.md](../spec.md) — the seams and implementation decisions this slice inherits. Omit this line when no spec exists.

**Repo:** `<repo>` — the repository this slice's code lands in, or several in the order they land.

- [ ] Acceptance criterion 1
- [ ] Acceptance criterion 2

</ticket-template>

The **Spec** link is what keeps a ticket from becoming an island. `/cppcho:implement` is handed one ticket file and expects to restate the seams the spec already fixed rather than reopen them, which it can only do if the ticket tells it where they are.

The **Repo** line answers the first question anyone picking a ticket up has: which checkout am I working in. A proto contract, a BFF composition and a backend change are three different sessions with three different gates, and none of that is reliably readable off the behaviour the ticket describes — so record it rather than leaving every later glance to guess. Name repositories the way the PR links do, by bare name (`platform-proto`, not the org-qualified path), and list several in the order the work lands when a slice genuinely spans them: `**Repo:** `platform-proto`, then `mercari-mvno-jp``.

Declare it on **every** ticket, including the ones landing in the epic's own repo. It is one line, and it buys the distinction between "this lands here" and "nobody said" — which is what lets `cppcho:ticket-dag` and `cppcho:next-actions` tag only the rows that leave the repo you're standing in, and flag the rest as unknown rather than quietly assuming. A slice that changes no repository at all still gets the line, with what it does instead: `**Repo:** none — verification on development`, `**Repo:** none — a console setting, not in version control`.

A slice spanning three repositories is three PRs and three review waits, so it is worth a second look at whether it wants splitting. Usually it doesn't — a proto field and the consumer that reads it are one tracer bullet, and cutting them apart buys a ticket that demonstrates nothing. When the call is close, name it in step 4's judgement line rather than deciding twice.

Write each **acceptance criterion** as behaviour observable from outside the code — something a test or a demo can check — because `/cppcho:implement` tests against these and ticks them as it goes. A criterion phrased as an implementation step ("add the column", "wire up the handler") can be ticked while nothing actually works; one phrased as an observable outcome cannot.

Observable is not yet provable. A criterion can be perfectly observable and still observable only on the real system, and on an implementation ticket that is the line from step 3 it must not cross. The tells: it names a real dataset or run ("run against it-02, the plan recovers the known clusters"), another person's action ("a reviewer sets the status"), another machine, a browser or a channel ("the link opens the row", "the digest reached Slack"), a real result deciding a side effect ("pushed as a PR only when the gate says adopt"), a first measured value written into the notes, or a one-off operation on live data. Each of those is a step of a verification ticket's walkthrough, so write it there. The fixture-level twin usually already sits next to it on the implementation ticket ("a fixture run yields a plan matching the expected file"); when it doesn't, write that twin and keep it.

Avoid specific file paths or code snippets in tickets — they go stale fast. Exception: if a snippet encodes a decision more precisely than prose can (state machine, reducer, schema, type shape), inline it. Trim to the decision-rich parts — not a working demo, just the important bits.

Finally, write `.scratch/epics/<PREFIX>-<slug>/tickets/README.md` holding the blocking graph and nothing else:

```markdown
# PCE · <Feature> — tickets

- **PCE-01 — <title>** — blocked by: none
- **PCE-02 — <title>** — blocked by: PCE-01
- **PCE-03 — <title>** — blocked by: PCE-01, PCE-02
```

The graph is worth indexing because it changes only when tickets are added or superseded, while status changes constantly — so status stays in the ticket files, and finding the **frontier** means reading this file for the shape, then checking the checkboxes of only the candidates it points at. Putting status here too would mean two records of the same fact, and the stale one always wins an argument it shouldn't.

Finally, draw the epic with the `cppcho:ticket-dag` skill, from the files and the README you just indexed — what you wrote, not what you meant. A blocker typed into the wrong ticket, an edge naming a number that doesn't exist, or a README that already disagrees with the tickets surfaces here — otherwise it waits and surfaces as a session that can't start the ticket it was handed.

The graph is also the handover: it says the tickets exist and where the frontier is. Close with the judgement calls step 4 set aside, one line each, and stop there.

## When the plan changes

Decisions move after tickets are cut — a spec revision, a discovery mid-build, a change of heart, a drift finding handed over by `/cppcho:reconcile`. Reconciling the epic is this skill's job: re-read the spec and every ticket, then route each affected ticket by its state. Unstarted tickets revise freely, as above. For an in-flight ticket the change invalidates, the graceful move is to **supersede** it, never to rewrite it — its ticked criteria are the only record of work actually done, and a session may still be holding its text. A ticket whose PR has merged with boxes still open is a different case and usually not a change of plan at all: the open boxes are real-system criteria that were misfiled, so move them (step 1) and leave the ticket to close on its own.

To supersede a ticket:

1. Add one line to the frozen ticket, directly under **Blocked by**, and change nothing else: `**Superseded by:** <PREFIX>-<NN> — <title>` — or `**Superseded:** <reason>` when the work is dropped outright and nothing replaces it.
2. Write the replacement as a new ticket under the next free number — the old number is retired with its ticket, because a reused number makes every reference to the dead ticket ambiguous. Carry forward the still-valid unticked criteria, add the changed behaviour, and give it the blocking edges that are true now. Leave any `**Branch:**` line behind on the superseded ticket: what carries forward is unfinished intent, and a branch inherited by the replacement would point at code written against a plan that no longer exists. The `**Repo:**` line is the opposite case — it describes intent rather than work done, so the replacement declares its own, which is often not the dead ticket's: a change of direction that moves a slice from the BFF to the backend is exactly the kind that supersedes.
3. Re-point every **Blocked by** that named the superseded ticket — in unstarted tickets and in the README graph — at its replacement, or drop the edge when the work is dropped. An edge into a dead ticket blocks its dependents forever.
4. In `README.md`, strike the entry through and name its successor: `- ~~**PCE-03 — <title>**~~ — superseded by PCE-07`. Keep the line rather than deleting it — the graph is the map of every number ever issued, and a silent gap in the numbering reads as a mistake to the next session.
5. Redraw the epic with the `cppcho:ticket-dag` skill. Step 3 is the easiest thing here to leave half-done, and a missed edge still aims at a dead ticket and blocks its dependents forever — which the graph shows as an edge running into a 🚫, and nothing else shows at all.

The spec must not be left contradicting the reshaped tickets — every ticket's Spec link feeds it to `/cppcho:implement` as established context, so a stale decision there misleads every later session. Update the spec's affected Implementation Decisions in place to match the change, and touch nothing else in it; a change big enough to move user stories or the problem statement deserves a `/cppcho:to-spec` session instead.

Superseding is graph surgery, so only this skill does it. `/cppcho:implement` may amend the unticked criteria of the one ticket it is building when a change is contained there; anything that moves other tickets, the graph, or a spec decision comes back here.

## Cancelling a whole epic

When the entire feature is dropped — deprioritised for good, or the need went away — cancel the **epic** instead of superseding every ticket in it. Add one line directly under the heading of `.scratch/epics/<PREFIX>-<slug>/tickets/README.md`:

```markdown
# PCE · <Feature> — tickets

**Cancelled:** <reason>
```

Leave the tickets themselves alone, ticked criteria and all. Retiring eight tickets one at a time to say one thing costs eight edits and eight chances to leave an edge aimed somewhere dead, and the epic still draws as a wall of 🚫 rows in every later glance. `cppcho:ticket-dag` and `cppcho:next-actions` both read this line and drop the epic, so one line retires the feature.

The **reason** is the load-bearing part, because a cancellation is the one thing a later session cannot reconstruct from the files — the tickets read exactly as they did the day before. A bare marker leaves the next reader unable to tell dropped from forgotten. Reviving the feature is deleting the line.

Carry the same line into `.scratch/epics/<PREFIX>-<slug>/spec.md` when the feature has one, under its heading and worded the same way. The spec is the door someone comes in through a year later, and it reads as live intent no matter how dead the tickets beside it are — where a live spec eventually gets corrected by the session that picks the work up, a cancelled one never does, because nobody picks it up. Add the line and touch nothing else in it: a cancelled spec is the record of a plan rather than a plan, and rewriting it into the past tense destroys the only account of what was intended.

Cancel the epic only when **all** of its outstanding work is dropped. When part of it survives, that is a reshape: supersede what died, keep what lives, and leave the epic in the sweep — a cancelled marker over live tickets hides work that is still owed.

## Archiving a shipped epic

When a feature is done and its code has landed, retire the epic by **moving** it out of the way. Add one line directly under the heading of `.scratch/epics/<PREFIX>-<slug>/tickets/README.md`:

```markdown
# PCE · <Feature> — tickets

**Shipped:** 2026-08-17 · [#1234](https://github.com/acme/billing-api/pull/1234), [#1251](https://github.com/acme/billing-api/pull/1251) — credit exchange live on production
```

Then move the whole directory, creating the archive on first use:

```bash
mkdir -p .scratch/epics/_archive && mv .scratch/epics/<PREFIX>-<slug> .scratch/epics/_archive/<PREFIX>-<slug>
```

**Move rather than mark**, because the move is the part that actually works. `cppcho:next-actions` and `cppcho:ticket-dag` find epics by globbing `.scratch/epics/[A-Z]*-*/`, and an archived epic sits under `_archive/`, which that glob cannot reach — so one `mv` takes the feature out of every default sweep and every "which epic did you mean?" list, which is the whole point. A marker with no move leaves a shipped feature competing with live work for attention in every later glance.

**Move rather than delete**, because the epic is the only surviving record of how the feature was cut and which PR carried each slice. Git has the diffs and none of the reasoning about ordering; `.scratch` is gitignored, so once these files are gone nothing anywhere holds that.

The **date and the PRs** are the load-bearing part of the line, for the same reason a cancellation needs its reason: ticked checkboxes read identically the day before a merge and a year after, so nothing else in the epic says whether it is finished or merely fully written. Reviving the feature is not un-archiving it — see step 1.

Archive only when all of this holds:

- **Every ticket is ✅ or 🚫.** Draw the epic with `cppcho:ticket-dag` and check rather than trusting the conversation; an epic gets archived once and read many times.
- **The code has merged.** All-ticked with PRs still open is not shipped — a review that comes back with changes reopens the last slice, and reopening a slice inside the archive is the one motion nothing here supports. Ask `gh` before archiving; this is the one place in the ticket skills where merge state is worth a network call, because it is a decision rather than a glance.
- **No worktree is holding the epic.** `.scratch` is symlinked into every worktree, so moving the directory out from under a live session breaks every path it holds.

`spec.md` travels with the epic — it lives in the directory being moved, and its `**Shipped:**` line is not needed once the whole thing is out of the sweep. `.scratch/context.md` is **not** archived: the domain glossary is one per repo and outlives every feature in it.

Before you move anything, ask what in the spec is still true about the code and would cost the next reader real time to rediscover — a seam, a constraint, a decision the code embodies but doesn't explain. That belongs in the repo, in `CLAUDE.md`, a design doc, or an ADR. Everything under `.scratch` is gitignored and local to one machine, so archiving is the moment the knowledge either gets promoted into the repo or stops existing for anybody else. Say what you'd promote and let the user decide; don't write into their repo unasked.
