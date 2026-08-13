---
name: to-tickets
description: Breaks a plan or spec into tracer-bullet tickets under `.scratch/`, each a vertical slice declaring what blocks it.
argument-hint: "[spec-path|issue-number|issue-url]"
disable-model-invocation: true
---

# To Tickets

Break a plan, spec, or conversation into a set of **tickets** — tracer-bullet vertical slices, each declaring the tickets that **block** it. The set is what `/cppcho:implement` then works through, one ticket per session.

## 1. Gather context

Work from whatever is already in the conversation context. If the user passes a reference (a spec path such as `.scratch/<feature-slug>/spec.md`, an issue number or URL) as an argument, fetch it and read its full body and comments.

Settle the **feature slug** early, since every path below depends on it. A spec path hands it to you. Otherwise reuse an existing `.scratch/<slug>/` that already covers this work rather than opening a sibling beside it, and only coin a new short kebab-case slug when none does — confirming a coined slug as part of the step 4 quiz, not as a question of its own.

Then read what is already on disk. If `.scratch/<feature-slug>/issues/` exists, read every ticket in it before drafting anything, because tickets in flight are load-bearing: `/cppcho:implement` ticks acceptance criteria in place as it works, so a ticket file is the only record of what is done. Regenerating the set from the conversation would erase that.

- A ticket with any criterion ticked, or that the conversation says is underway, is **frozen** — leave its text and its number alone. When a change of direction invalidates a frozen ticket, don't edit it — **supersede** it (see "When the plan changes").
- Revise unstarted tickets freely, but leave a `**Branch:**` line alone if one is there. `/cppcho:implement` writes it to say where a slice's code went, and it is not derivable from anything else once dropped.
- New work becomes new tickets, appended.

## 2. Explore the codebase

If you have not already explored the codebase, do so to understand the current state of the code. Read `.scratch/context.md` if it exists and use its domain glossary vocabulary in ticket titles and descriptions.

Look for opportunities to prefactor the code to make the implementation easier — "make the change easy, then make the easy change." A prefactor becomes its own ticket that blocks the slices needing it.

## 3. Draft vertical slices

Break the work into **tracer bullet** tickets.

<vertical-slice-rules>

- Each slice cuts a narrow but COMPLETE path through every layer (schema, API, UI, tests) — vertical, NOT a horizontal slice of one layer
- A completed slice is demoable or verifiable on its own
- Each slice is sized to fit in a single fresh context window

</vertical-slice-rules>

Give each ticket its **blocking edges** — the other tickets that must complete before it can start. A ticket with no blockers can start immediately.

**Wide refactors are the exception to vertical slicing.** When one mechanical change — renaming a column, retyping a shared symbol — has a **blast radius** fanning across the whole codebase, a single edit breaks thousands of call sites at once and no vertical slice can land green. Sequence it as **expand–contract** instead: one ticket to **expand** (add the new form beside the old, so nothing breaks), then a **migrate** ticket per batch of call sites sized by blast radius (per package, per directory), each blocked by the expand and green on its own because the old form still exists, then a **contract** ticket blocked by every batch to delete the old form. When even the batches can't stay green alone, keep the sequence but let them share an integration branch that all block a final integrate-and-verify ticket — green is promised only there.

## 4. Quiz the user

Draw the proposed set with the `cppcho:ticket-dag` skill — rails carrying the blocking edges, one row per ticket with its title, the behaviour it delivers in a line, and its size. It handles a set that isn't on disk yet, and folds in any tickets already written so the new work is visible against work in flight.

Draw it rather than listing it because the edges are what this quiz is really about, and a wrong edge is something you *see* as a rail while a prose "blocked by: 01, 04" reads as plausible either way. The graph also puts the shape in front of the user — a chain five deep where they expected two branches, or a lone ticket gating everything — which is the granularity question answered before it's asked.

Then ask:

- Does the granularity feel right? (too coarse / too fine)
- Are the blocking edges correct — does each ticket only depend on tickets that genuinely gate it?
- Should any tickets be merged or split further?

Redraw after each round of changes instead of describing what moved; the diagram is cheap and a described edit is easy to mis-picture. Iterate until the user approves the breakdown.

## 5. Write the tickets

Write one file per approved ticket under `.scratch/<feature-slug>/issues/<NN>-<slug>.md`, using the template below — one ticket per file, never a single combined file.

Number tickets in dependency order the first time you write a set, blockers first, because it makes the directory readable at a glance. After that the number is **identity, not position**: a ticket added in a later pass takes the next free number even when it belongs early in the order. Renumbering silently invalidates every "Blocked by" reference and every link from work already in flight, and buys only cosmetic tidiness. The blocking edges carry the order; the numbers just name things.

Keep each ticket to the template's parts. A ticket carries the behaviour and its acceptance criteria; leave out restated context, rationale sections, and implementation notes.

<ticket-template>

# <NN> — <Ticket title>

**What to build:** the end-to-end behaviour this ticket makes work, from the user's perspective — not a layer-by-layer implementation list.

**Blocked by:** `<NN> — <title>` for each ticket that gates this one, or "None — can start immediately".

**Spec:** [spec.md](../spec.md) — the seams and implementation decisions this slice inherits. Omit this line when no spec exists.

- [ ] Acceptance criterion 1
- [ ] Acceptance criterion 2

</ticket-template>

The **Spec** link is what keeps a ticket from becoming an island. `/cppcho:implement` is handed one ticket file and expects to restate the seams the spec already fixed rather than reopen them, which it can only do if the ticket tells it where they are.

Write each **acceptance criterion** as behaviour observable from outside the code — something a test or a demo can check — because `/cppcho:implement` drives red-green against these and ticks them as it goes. A criterion phrased as an implementation step ("add the column", "wire up the handler") can be ticked while nothing actually works; one phrased as an observable outcome cannot.

Avoid specific file paths or code snippets in tickets — they go stale fast. Exception: if a snippet encodes a decision more precisely than prose can (state machine, reducer, schema, type shape), inline it. Trim to the decision-rich parts — not a working demo, just the important bits.

Finally, write `.scratch/<feature-slug>/issues/README.md` holding the blocking graph and nothing else:

```markdown
# <Feature> — tickets

- **01 — <title>** — blocked by: none
- **02 — <title>** — blocked by: 01
- **03 — <title>** — blocked by: 01, 02
```

The graph is worth indexing because it changes only when tickets are added or superseded, while status changes constantly — so status stays in the ticket files, and finding the **frontier** means reading this file for the shape, then checking the checkboxes of only the candidates it points at. Putting status here too would mean two records of the same fact, and the stale one always wins an argument it shouldn't.

Finally, draw the set again with the `cppcho:ticket-dag` skill. This isn't a repeat of the quiz diagram: that one drew what you meant, this one draws what you wrote, from the files and the README you just indexed. A blocker typed into the wrong ticket, an edge naming a number that doesn't exist, or a README that already disagrees with the tickets surfaces here — otherwise it waits and surfaces as a session that can't start the ticket it was handed.

## When the plan changes

Decisions move after tickets are cut — a spec revision, a discovery mid-build, a change of heart. Reconciling the set is this skill's job: re-read the spec and every ticket, then route each affected ticket by its state. Unstarted tickets revise freely, as above. For an in-flight ticket the change invalidates, the graceful move is to **supersede** it, never to rewrite it — its ticked criteria are the only record of work actually done, and a session may still be holding its text.

To supersede a ticket:

1. Add one line to the frozen ticket, directly under **Blocked by**, and change nothing else: `**Superseded by:** <NN — title>` — or `**Superseded:** <reason>` when the work is dropped outright and nothing replaces it.
2. Write the replacement as a new ticket under the next free number — the old number is retired with its ticket, because a reused number makes every reference to the dead ticket ambiguous. Carry forward the still-valid unticked criteria, add the changed behaviour, and give it the blocking edges that are true now. Leave any `**Branch:**` line behind on the superseded ticket: what carries forward is unfinished intent, and a branch inherited by the replacement would point at code written against a plan that no longer exists.
3. Re-point every **Blocked by** that named the superseded ticket — in unstarted tickets and in the README graph — at its replacement, or drop the edge when the work is dropped. An edge into a dead ticket blocks its dependents forever.
4. In `README.md`, strike the entry through and name its successor: `- ~~**03 — <title>**~~ — superseded by 07`. Keep the line rather than deleting it — the graph is the map of every number ever issued, and a silent gap in the numbering reads as a mistake to the next session.
5. Redraw the set with the `cppcho:ticket-dag` skill. Step 3 is the easiest thing here to leave half-done, and a missed edge still aims at a dead ticket and blocks its dependents forever — which the graph shows as an edge running into a `⊘`, and nothing else shows at all.

The spec must not be left contradicting the reshaped tickets — every ticket's Spec link feeds it to `/cppcho:implement` as established context, so a stale decision there misleads every later session. Update the spec's affected Implementation Decisions in place to match the change, and touch nothing else in it; a change big enough to move user stories or the problem statement deserves a `/cppcho:to-spec` session instead.

Superseding is graph surgery, so only this skill does it. `/cppcho:implement` may amend the unticked criteria of the one ticket it is building when a change is contained there; anything that moves other tickets, the graph, or a spec decision comes back here.
