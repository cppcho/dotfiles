---
name: to-spec
description: Synthesizes the current conversation into a spec under `.scratch/epics/` — writes, doesn't ask.
---

This skill takes the current conversation context and codebase understanding and produces a spec. Don't gather new requirements — synthesize only what the conversation and the code already tell you. If something essential is genuinely missing, ask that one question; don't open a round of discovery.

## Process

1. Explore the repo to understand the current state of the codebase, if you haven't already. Read `.scratch/context.md` if it exists and use its domain glossary vocabulary throughout the spec.

2. Sketch out the seams at which you're going to test the feature. A **seam** is a place where you can substitute behaviour without editing the code under test — the boundary a test plugs into. Existing seams should be preferred to new ones. Use the highest seam possible. If new seams are needed, propose them at the highest point you can. The fewer seams across the codebase, the better - the ideal number is one.

   Name these seams in the spec's Implementation Decisions, in plain words: the concrete boundary and what stands in for what there ("the repository: a fake returns the rows", "the gRPC handler: a fake client answers"). "Seam" is this skill's internal shorthand, not shared vocabulary — prose that leans on it reads as jargon. Do not stop to confirm them. Write the spec, then say in one line which boundary you chose, so it can be redirected before `/cppcho:to-tickets` cuts tickets from it.

   Name the boundary by what the fake stands in for, not by how a test reaches it. "The library accepts an injected request function" is a claim about the code that only a test reaching it can prove, and this skill writes no tests. One spec made that claim — true of the library, never checked against the app, where no test could reach the argument without editing production code — and two builders then bridged the gap two different ways, a factory in one PR and an optional parameter on a production function in the other. Both had to be undone. So write what stands in for what ("tests stand in for the experiment platform's answers and nothing else"). If you do name an existing hook, say what shows a test can reach it without editing production code. Otherwise leave the mechanism to the one prefactor ticket `/cppcho:to-tickets` cuts to build the fake: a parameter or wrapper added for tests is a new seam, added there once, by agreement, and imported by every other ticket — never once per builder.

3. Write the spec using the template below to `.scratch/epics/<PREFIX>-<slug>/spec.md`, creating the directory if it does not exist. That directory is a **local epic** — the spec and, later, the tickets `/cppcho:to-tickets` cuts from it. Its `<PREFIX>` is the epic's id, so coin one when the directory is new: the initials of the slug's significant words, uppercased, two letters minimum (`promo-credit-exchange` → `PCE`), checked against `ls .scratch/epics/` for a collision and extended until unique. Every ticket id in the epic is built from it.

   If `spec.md` already exists, read it first and treat it as established context: carry forward every decision that still holds and revise only what this conversation changed. Regenerating from the conversation alone silently drops the decisions nobody revisited this session. Write the file as a snapshot of the current state — no change notes, no revision history, no "previously X" asides.

   Two lines under the H1 belong to other skills — a `**Reconciled:**` stamp from `/cppcho:reconcile` and a `**Cancelled:**` marker from `/cppcho:to-tickets`. Carry them through a rewrite untouched; a reconciliation stamp that survives an edit it didn't cover is the one thing here that can mislead a later reader into skipping a check.

Match each section's length to what it carries. The user stories are deliberately exhaustive; everything else covers its substance and stops. Leave out filler sections, restated summaries, and boilerplate.

Stop once the spec is written — don't start implementing it. `/cppcho:to-tickets` breaks it into tickets when the user is ready, and owns reconciling them when a later session revises a decision they were cut from.

<spec-template>

# <PREFIX> — <Feature>

## Problem Statement

The problem that the user is facing, from the user's perspective.

## Solution

The solution to the problem, from the user's perspective.

## User Stories

A LONG, numbered list of user stories. Each user story should be in the format of:

1. As an <actor>, I want a <feature>, so that <benefit>

<user-story-example>
1. As a mobile bank customer, I want to see balance on my accounts, so that I can make better informed decisions about my spending
</user-story-example>

This list of user stories should be extremely extensive and cover all aspects of the feature.

## Implementation Decisions

A list of implementation decisions that were made. This can include:

- The modules that will be built/modified
- The interfaces of those modules that will be modified
- Technical clarifications from the developer
- Architectural decisions
- Schema changes
- API contracts
- Specific interactions

Do NOT include specific file paths or code snippets. They may end up being outdated very quickly. The same goes for a mechanism nobody decided — which module a test replaces, which argument carries a fake: a spec records decisions, and a mechanism written down reads as one.

Exception: if a prototype produced a snippet that encodes a decision more precisely than prose can (state machine, reducer, schema, type shape), inline it within the relevant decision and note briefly that it came from a prototype. Trim to the decision-rich parts — not a working demo, just the important bits.

## Out of Scope

A description of the things that are out of scope for this spec.

## Further Notes

Any further notes about the feature.

</spec-template>
