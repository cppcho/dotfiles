---
name: brainstorm
description: Brainstorms a plan, decision, or idea with the user in rounds, working a design tree until nothing is left silently assumed. Use when the user says brainstorm, wants to stress-test or poke holes in their thinking, asks what they are missing, or is weighing an approach and wants the trade-offs worked through. Produces shared understanding, not a document — once the design tree is settled, /cppcho:to-spec writes it up as a spec.
---

Use the `/cppcho:domain-modeling` skill.

Interview the user until you reach a shared understanding. Map this as a **design tree**: every decision branches into the decisions that hang off it.

Work the tree in **rounds**. The **frontier** is every decision whose prerequisites are already settled — the ones you can resolve _now_ without guessing at answers you haven't heard yet.

## Split the frontier before you ask

Most of the frontier does not deserve the user's attention, and their attention is the scarce resource. A round of twelve questions where nine answers are "your call, the default is fine" buys _less_ shared understanding than a round of three, because the three that mattered got the same tired glance as the nine that didn't. So each round, sort the frontier into two piles:

**Questions** — decisions where you can name what would concretely be built differently under each answer, or that turn on the user's taste, priorities, or context you have no way to look up. Taste counts for more than it sounds like: where the toggle sits in their own header is theirs to pick, not a convention to look up. Ask these.

**Defaults** — everything else: an obvious convention, cheap to reverse later, or you'd genuinely shrug at either answer. Don't ask. Decide it yourself and write it down where the user can see it. Those written-down defaults, accumulated across every round, are the **ledger**.

The test that separates them: try to state the consequence out loud. "If we key it by user instead of by account, the migration has to backfill and the API breaks" is a question. "If we name it `handler` instead of `controller`" is not — that's a default, and asking about it spends the user's patience on nothing.

Two things pull a decision back into the questions pile however settled the convention looks:

- **A severe failure mode.** Cheap to _decide_ is not cheap to be _wrong about_. Fail-open versus fail-closed, exempting a class of traffic from the very thing meant to protect you, anything that quietly loses data or money — the conventional answer can be both obvious and wrong here, and someone who ratifies it by skimming a ✅ line has not actually agreed to it.
- **An unverified fact underneath it.** A default is only as good as what it rests on. "Use the Redis we already run" is a default once you've seen the Redis and a guess wearing a checkmark until you have. Go look; if you can't, that's a question, and say which fact you're missing.

Three questions in a round is about the ceiling of what someone answers carefully. If more than three survive the filter, ask the highest-consequence three and leave the rest for a later round — don't demote a real question to a default just to fit the cap. Most rounds should come in well under three; if yours keep hitting the ceiling, the filter is too loose.

## Go find the facts

Deciding on someone's behalf raises the bar on groundedness rather than lowering it: finding _facts_ is your job, never the user's. When a decision needs a fact from the environment (filesystem, tools, docs), dispatch a sub-agent — don't ask for anything you could look up. Don't block on it: a running exploration is an unsettled prerequisite, so only the decisions downstream of it wait for the report. Take the rest of the frontier now.

Be strict about which decisions those are. If a pending report could reshape a question, narrow it, or delete it outright, the question is not on the frontier — hold it, and don't hedge it into the round with a caveat about the agent still being out. A question asked on a fact you're still fetching is worse than unasked: the user spends their attention on a premise that changes underneath them.

Sometimes that leaves nothing to ask, and an empty frontier with reports still out is a fine place to be: say in one line what you're waiting on, and wait. A round exists to spend the user's attention well, so there is no such thing as owing them one — manufacturing a round to fill the silence is how you end up asking the same question twice.

## One round at a time

A round is open until the user replies to it. While one is open, a returning sub-agent buys you facts, not a turn: write them into your notes and fold them into the next round. Never post a correction, an amendment, or another question against a round the user hasn't answered yet — and if the facts gut the round entirely, say only that in one line and wait. A round that mutates while someone is reading it teaches them that answering carefully is wasted work, and the next thing they say is "re-ask everything" — which costs you the round you were trying to save.

## Format of a round

Defaults first, so the user sees the cheap stuff as a block to skim rather than interleaved with things they have to think about:

```
✅ **<decision>** → <what you chose>
```

One line each, no question marks. A default that's written down is not a silent assumption — that is what makes skipping the question safe rather than sloppy.

Then the questions:

```
❓ **Q1** — **<question title>**: <question body, may be multiple paragraphs, including the options if there are distinct options>

➡️ <your recommended answer>
```

Close the round with the escape hatch, so answering costs two characters when the user has nothing to add:

```
Reply **ok** to take all of the above, or just name what you'd change.
```

## Reading the reply

`ok` — or `go`, `sounds good`, `lgtm` — accepts every recommendation and every default in the round. Treat that as a real answer, not as the user dodging.

A partial reply settles only what it mentions; everything unmentioned stands as you recommended it. Someone who answers Q2 and ignores Q1 and Q3 has told you Q1 and Q3 were fine, so don't re-ask them — re-asking teaches the user that skimming is unsafe and that the escape hatch is a trap, and then you're back to twelve questions a round.

## Finishing

The session is done when the frontier is empty: every branch of the tree visited, nothing left silently assumed.

Before you declare that, replay the whole ledger — every default from every round, in one compact list — so the user gets a single deliberate pass over the decisions you made for them. That one review is what earns you all the questions you didn't ask. Wait for their confirmation, and don't act on the design until you have it.
