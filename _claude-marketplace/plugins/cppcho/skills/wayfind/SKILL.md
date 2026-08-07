---
name: wayfind
description: Charts work too big for one session as a map of open decisions under `.scratch/`, then resolves them one per session until the way is clear.
argument-hint: "[loose idea | feature-slug]"
disable-model-invocation: true
---

# Wayfind

An idea has arrived that won't fit in one session, and the way to it isn't visible yet. Wayfinding is finding that way — not charging at the destination. This skill writes the route down as a **map** on disk, then works its open questions one at a time, across as many sessions as it takes.

Continuity lives in the map, not in the conversation: every session starts cold, so anything a future one needs that you leave unwritten is lost.

If the whole effort would comfortably fit in one sitting, you don't need a map — say so and use `/cppcho:brainstorm` instead.

The argument picks the mode. A feature slug with a `.scratch/<feature-slug>/map.md` already on disk means **work the next question**; anything else is a loose idea to **chart**. With no argument, look under `.scratch/` — one map means work that one, several means ask which.

## Plan, don't do

Every question on the map resolves to a **decision**, not a slice of shipped work. The urge to just start building is usually the signal you've reached the edge of the map and it's time to hand off rather than a signal to keep going.

## The map

Two files under `.scratch/<feature-slug>/`:

- **`map.md`** — the whole route at low resolution. Loaded in full at the start of every session, so it stays an index: it gists each decision and links to the detail, never restates it.
- **`decisions.md`** — the substance behind each resolved question, appended to as you go. Read on demand, and the main input to `/cppcho:to-spec` later.

Keeping them apart is what makes long efforts affordable: twenty resolved decisions would swamp a session's context if the map carried them inline.

`map.md`:

```markdown
# <effort name>

## Destination

<what reaching the end of this map looks like — the spec, decision, or change this effort is finding its way to. One or two lines; every session orients to it before choosing a question.>

## Notes

<domain; skills every session should consult; standing preferences for this effort>

## Decisions so far

- **<question title>** — <one-line gist of the answer> ([detail](decisions.md#<anchor>))

## Open questions

- [ ] **<title>** · `decide` · blocked by: none
      <the question, sharp enough to act on, in a line or two>
- [ ] **<title>** · `research` → [findings](../research/<slug>.md) · blocked by: <title of the question this one waits on>
      <same, and the file its findings will land in if it has been dispatched>

## Not yet specified

- <a question you can see coming but can't yet phrase sharply>

## Out of scope

- <work ruled beyond the destination> — <why>
```

`decisions.md` grows one section per resolved question — the answer, plus the reasoning that isn't recoverable from the answer alone: constraints discovered, alternatives rejected and why. Match each section to what its decision carries, a few lines for a small call; restated context and boilerplate cost the later sessions that have to read them.

```markdown
## <question title>

<the answer and what shaped it>
```

## Question types

Tag each open question with the type that resolves it. All three land the same way once resolved — a gist on the map, the substance in `decisions.md` — even though `research` and `task` record a fact rather than a choice.

- **`decide`** — a conversation with the user. The default, and the only type where you must not answer for them: a wayfind session that decides on the user's behalf has produced a guess wearing a decision's clothes. Work it in rounds, as below.
- **`research`** — a fact from outside this working directory that a decision waits on: docs, a third-party API, another repo. Hand it to `/cppcho:research`, which dispatches a background subagent and leaves findings in `.scratch/research/<slug>.md`. Link that file as the decision's detail.
- **`task`** — work with nothing to decide that a decision is nonetheless blocked on: signing up for a service so its API can be judged, provisioning access, moving data so its shape can be seen. It earns its place by unblocking a decision, not by delivering the destination. Drive it yourself where you can; otherwise hand the user a precise checklist. Record what was done plus any facts later questions will need — where credentials live, new URLs, row counts.

### Working a `decide` question in rounds

Use `/cppcho:domain-modeling` throughout — fuzzy vocabulary is how decisions get made twice.

A question usually has smaller decisions hanging off it. Ask everything whose prerequisites are already settled in **one round**, numbered, each with your recommended answer:

```
❓ **Q1** - **<question title>**: <question body, including options if there are any>

➡️ <your recommended answer>
```

Then wait. The answers reshape what's askable — recompute and ask the next round. A question whose answer depends on another still open in this round belongs to the next round, not this one.

Append to `decisions.md` as each round settles rather than saving it all for the end — a question worth several rounds can outlive the session working it.

Finding facts is your job, never the user's: when a round needs something the environment can tell you, dispatch a subagent rather than asking. Don't block on it — only the questions downstream of that fact wait; ask the rest of the round now.

## Fog, question, or out of scope

The map is deliberately incomplete. Beyond the open questions lies the **fog**: decisions you can tell are coming but can't yet pin down, because they hang on questions still open. Resolving a question clears the fog ahead of it.

Sort by whether you can state the question precisely *now*, not by whether you can answer it:

- **Open question** when it's already sharp, even if it's blocked and you can't act on it yet.
- **Not yet specified** when you can't phrase it that sharply. Don't pre-slice fog into question-sized pieces; one patch may graduate into several questions, or none, once you reach it.

**Out of scope** is a different axis: scope, not sharpness. The destination fixes the scope, so work beyond it was never fog and never graduates. When an existing question turns out to sit past the destination, drop it from Open questions and leave one line here with the reason — not in Decisions so far, which records the route actually walked, and a scope boundary isn't a step on it.

## Chart the map

The user invokes with a loose idea.

1. **Name the destination.** Settle what this effort is finding its way to before anything else — it fixes the scope, so every later question depends on it.
2. **Find the questions, don't answer them.** Go broad rather than deep: fan out across the whole space surfacing what's undecided. Charting is reconnaissance; resolving even one question here spends the session you'd rather spend on it properly. Keep the ones that stand between here and the destination — a map listing every question imaginable is as unusable as one listing none.
3. **Write `map.md`** to `.scratch/<feature-slug>/`, a short dash-case slug from the destination, creating the directory if it does not exist. Destination and notes filled in, Decisions so far empty, every question you can phrase sharply under Open questions with its blockers, and everything still dim under Not yet specified.
4. **Fire the research.** Dispatch `/cppcho:research` for each `research` question now, in parallel — they run unattended and usually unblock the first `decide` questions. Choose each one's `<slug>` yourself and write the `.scratch/research/<slug>.md` path onto the map beside its question; findings the map doesn't point at are findings the next session won't know exist.
5. **Stop.** Charting is a session's work of its own.

## Work the next question

The user invokes with a feature slug, optionally naming a question. Without one, you choose — that's the point of the map.

1. Read `map.md`. Orient to the destination.
2. Pick the question: the user's, or the first open one whose blockers are all resolved. Zoom into `decisions.md` or a research file only where this question actually needs it.
3. Resolve it by its type.
4. Record it: append the substance to `decisions.md`, add the one-line gist and link to Decisions so far, and remove it from Open questions.
5. Re-chart. Strike this question from the `blocked by` lines that named it, so the next session can see at a glance what is actually workable; add questions the answer has made sharp; graduate fog patches into questions, deleting them from Not yet specified so each lives in exactly one place; rule out of scope anything the answer put past the destination; rewrite or drop questions the answer invalidated.
6. **Stop after one question** — `research` and `task` excepted, since neither consumes the judgement a decision needs. Carrying on costs you twice: the fresh context the map exists to preserve, and the independence of the next decision, which the one you just made will colour before it's been examined.

## When the map is clear

Open questions and Not yet specified are both empty. Say so, and hand off: `/cppcho:to-spec` turns `decisions.md` into the spec, `/cppcho:to-tickets` cuts that into slices, `/cppcho:implement` builds them.
