---
name: reconcile
description: Checks a local epic's tickets and spec against the code they describe, and reports the drift — tickets a parallel epic already satisfied, tickets the code invalidated, spec decisions the code no longer follows, and bookkeeping that disagrees with itself. Use when an epic has sat while other work landed, before picking a ticket up, or to sweep every epic for self-contradiction.
argument-hint: "[epic-prefix|ticket-id]"
---

# Reconcile

Answer one question: **is this local epic still true?** Tickets are written once and read for weeks while parallel epics land code underneath them, so an outstanding ticket is a claim about the codebase that nothing has re-checked since the day it was cut.

Epic and ticket here mean the files under `.scratch/epics/<PREFIX>-<slug>/` — never a Jira or Linear issue.

## Modes

The argument picks the depth. All three read only this repo: the tickets, the spec, and the code. A shared design doc elsewhere is downstream of this material, not authoritative over it, so a difference there means that document needs regenerating — not that these tickets are wrong.

| argument | scope |
| --- | --- |
| none | **Sweep** — the bookkeeping pass (step 1) over every epic. File-vs-file only, no code read. |
| `PCE` | **Audit** — steps 1–5 for one epic. |
| `PCE-02` | **Freshness** — step 3 for that one ticket, reported in a line or two. This is the mode `/cppcho:implement` calls before it plans. |

```
- [ ] Bookkeeping — the files against each other
- [ ] Branches — merge state of every recorded PR
- [ ] Verdicts — each outstanding ticket against the code
- [ ] Spec — its decisions against the code
- [ ] Report and route
- [ ] Stamp what was checked
```

## 1. Bookkeeping

Read every ticket and the `tickets/README.md` index, and look for the epic disagreeing with itself. All of these are decidable from the files alone, which is what makes the no-argument sweep cheap enough to run over every epic at once:

- A ticket with ticked criteria whose **blocker** has none — work landed out of order, so either the edge is wrong or the ticks are.
- A **Blocked by** naming an id that no file carries.
- An edge pointing at a ticket carrying a **Superseded** line — dead edges block their dependents forever.
- A README row that disagrees with its ticket's edges, is missing, or is missing the strike-through a superseded ticket should have.
- A heading id that doesn't match its filename or its directory's prefix.
- A **Status** line parking a ticket on something that has since happened.
- An epic whose every ticket is ✅ or 🚫, still sitting outside `_archive/`.

Report these as found. Fixing them is graph surgery, so it belongs to `/cppcho:to-tickets` (step 5).

## 2. Branches

For each `**Branch:**` PR in the epic, ask `gh pr view <url> --json state,mergedAt` once. Merge state is what decides whether the next ticket stacks on that branch or builds on merged code, and a ticket whose PR merged months ago is the likeliest place for the code to have moved out from under its siblings.

This is the one skill in the ticket family that makes network calls. `cppcho:next-actions` deliberately doesn't — it's a glance, this is an audit.

## 3. Verdicts

For each **outstanding** ticket — anything not fully ticked and not superseded — read the code its criteria describe and return one verdict. Done and retired tickets are not re-litigated; they are the record of what happened.

| verdict | what it takes to say it |
| --- | --- |
| `fresh` | The behaviour is absent and the ticket still describes a path through the current code. |
| `already satisfied` | **Every** criterion has a citation — `file:line`, or a test that covers it. |
| `partly satisfied` | Some criteria cited, the rest absent. Name which. |
| `invalidated` | The code moved such that the ticket describes work that can no longer be done as written — a seam gone, a table re-keyed, another epic having solved it differently. |
| `unclear` | Anything else. |

**`already satisfied` fails closed.** Without a citation per criterion the verdict is `unclear — verify by hand`, never a confident guess. The asymmetry is the whole reason: a wrong `unclear` costs ten minutes re-reading code, while a wrong `already satisfied` ships a hole in the feature and leaves a ticked box arguing that nothing is missing.

**Never tick a criterion.** A tick means someone built the thing and watched a test go green; `/cppcho:implement` is the only skill that has done that. Ticking on a read replaces the epic's record of verified work with a guess about it.

Dispatch one subagent per outstanding ticket, handed that ticket file and the spec, returning its verdict with citations. The code reading is the expensive half and none of it needs to enter this session — a ten-ticket epic then costs about what a three-ticket one does. Then read the returned verdicts yourself, as a set: two tickets converging on the same behaviour, or a chain whose first link is already satisfied, is visible in the verdicts and invisible to any single reader.

## 4. Spec

Read the spec's Implementation Decisions against the code that implements them. A decision the code no longer follows is the most expensive kind of drift, because every ticket's **Spec** link feeds it forward to the next session as established context.

Say which side moved when you can tell: the code diverging from a still-good decision is a bug, while a decision the code deliberately outgrew is a stale spec. They route differently.

## 5. Report and route

One block per epic, findings only — a clean epic gets a line saying so, not a table of ✅. Keep the whole report to what fits on a screen; the verdicts carry citations, so anyone who wants the detail has a path to it.

```
PCB · promo-credit-wallet-scoped-balances    reconciled 2026-08-01 · 3 findings

  PCB-04  already satisfied  — zero-balance routing landed in PCG-05 (grant.go:212, grant_test.go:88)
  PCB-07  invalidated        — statement rows now key on balance id (PCS-02), so the
                               per-wallet filter this describes has no column to read
  spec    stale              — "balances never lapse once contracted" was dropped in PCA-03

Route: PCB-04 and PCB-07 → /cppcho:to-tickets (supersede PCB-07, close PCB-04 out)
       spec decision       → /cppcho:to-spec
```

**Reconcile edits nothing on its own.** Every finding names the skill that owns the fix — `/cppcho:to-tickets` for anything touching a ticket, an edge, or the index; `/cppcho:to-spec` for a decision. Keeping diagnosis and surgery apart is what lets an audit be run freely: it cannot make the epic worse. Act on the routed list in the same session if the user says go, by invoking those skills.

Write no report file. An audit is true on the day it runs, and a saved one becomes exactly the kind of stale artifact this skill exists to find.

## 6. Stamp what was checked

After an audit, record it under the spec's H1:

```markdown
**Reconciled:** 2026-08-22 · 18717038f · PCB-03,05,07
```

The date, the commit the code was read at, and **the tickets actually checked**. A bare stamp claims the whole epic is fresh when perhaps three tickets were read; naming the scope makes the line unable to overclaim, and lets the next run scope its reading to what changed since that commit.

The freshness mode stamps nothing — one ticket is not an audit.
