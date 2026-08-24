---
name: to-spec
description: Synthesizes the current conversation into a spec under `.scratch/` — writes, doesn't ask.
---

This skill takes the current conversation context and codebase understanding and produces a spec. Don't gather new requirements — synthesize only what the conversation and the code already tell you. If something essential is genuinely missing, ask that one question; don't open a round of discovery.

## Process

1. Explore the repo to understand the current state of the codebase, if you haven't already. Read `.scratch/context.md` if it exists and use its domain glossary vocabulary throughout the spec.

2. Sketch out the seams at which you're going to test the feature. A **seam** is a place where you can substitute behaviour without editing the code under test — the boundary a test plugs into. Existing seams should be preferred to new ones. Use the highest seam possible. If new seams are needed, propose them at the highest point you can. The fewer seams across the codebase, the better - the ideal number is one.

   Check with the user that these seams match their expectations before writing. Phrase that question in plain words: name the concrete boundary ("the repository interface", "the gRPC handler") and what a fake replaces there. "Seam" is this skill's internal shorthand, not shared vocabulary — a question that leans on it gets answered with "what is a seam?".

3. Write the spec using the template below to `.scratch/<PREFIX>-<slug>/spec.md`, creating the directory if it does not exist. That directory is a **local epic** — the spec and, later, the tickets `/cppcho:to-tickets` cuts from it. Its `<PREFIX>` is the epic's id, so coin one when the directory is new: the initials of the slug's significant words, uppercased, two letters minimum (`promo-credit-exchange` → `PCE`), checked against `ls .scratch/` for a collision and extended until unique. Every ticket id in the epic is built from it.

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

Do NOT include specific file paths or code snippets. They may end up being outdated very quickly.

Exception: if a prototype produced a snippet that encodes a decision more precisely than prose can (state machine, reducer, schema, type shape), inline it within the relevant decision and note briefly that it came from a prototype. Trim to the decision-rich parts — not a working demo, just the important bits.

## Out of Scope

A description of the things that are out of scope for this spec.

## Further Notes

Any further notes about the feature.

</spec-template>
