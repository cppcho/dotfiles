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

- A ticket with any criterion ticked, or that the conversation says is underway, is **frozen** — leave its text and its number alone.
- Revise unstarted tickets freely.
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

Present the proposed breakdown as a numbered list. For each ticket, show:

- **Title**: short descriptive name
- **Blocked by**: which other tickets (if any) must complete first
- **What it delivers**: the end-to-end behaviour this ticket makes work

Ask the user:

- Does the granularity feel right? (too coarse / too fine)
- Are the blocking edges correct — does each ticket only depend on tickets that genuinely gate it?
- Should any tickets be merged or split further?

Iterate until the user approves the breakdown.

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

The graph is worth indexing because it changes only when tickets are added, while status changes constantly — so status stays in the ticket files, and finding the **frontier** means reading this file for the shape, then checking the checkboxes of only the candidates it points at. Putting status here too would mean two records of the same fact, and the stale one always wins an argument it shouldn't.
