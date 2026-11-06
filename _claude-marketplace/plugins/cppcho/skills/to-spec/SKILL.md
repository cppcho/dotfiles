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

## Linear mode

Everything above is **local mode**: the epic lives under `.scratch/epics/`. When the user points this skill at Linear, the epic lives in Linear instead and the spec is written into a project or parent issue description. The shared rules — how the modes are told apart, the two epic shapes, where the spec goes, the stamp line, the tools — are in [`references/linear-mode.md`](../../references/linear-mode.md); read it before writing anything in Linear mode. Nothing in local mode changes.

**What the argument decides.** The target names the shape:

- A **team** (name or key: `"Linear Test"`, `MVNOALL`) → a new **project** in that team. A new feature of its own.
- A **project** (URL or `P-TEAM-123`) → a new **parent issue** inside it. A sub-feature of a project the team already plans in.
- An existing **project or parent issue that already holds a spec** → revise that description in place.
- "In Linear" with no target → ask one question — project or parent issue, and in which team or project — and write nothing until it is answered.

Process steps 1 and 2 are unchanged: explore the repo, read `.scratch/context.md`, settle the testing boundary. Step 3 changes:

1. **Say the mode and the home first**, in one line, before any Linear call that writes: `Linear epic as a project in <team>` or `Linear epic as a parent issue under <project>`. Nothing is created under `.scratch/epics/` and no prefix is coined; the epic's id is the project identifier or the parent issue id Linear assigns.
2. **Project.** Read the team's project template (`list_templates` with `type: project` for the team, then `get_template`). Fill its headings from the spec as the reference's §4 says — the "what" heading from Solution, the "why" from Problem Statement, the "notes" from Out of Scope and Further Notes, any deadline or label heading left as the template wrote it — then add `## User Stories` and `## Implementation Decisions` below. Create with `save_project`: `name` is the feature title, `addTeams` the team, `template` the template name, `description` the filled text (a description passed with a template replaces the template body, which is what filling it means). A team with no project template gets the spec's own sections as the description.
3. **Parent issue.** Read the project (`get_project`) for its lead team. Create with `save_issue`: `team` that team, `project` the project, `title` the feature title, `assignee` `me`, `description` the spec as the template above writes it — Problem Statement, Solution, User Stories, Implementation Decisions, Out of Scope, Further Notes — with nothing that only makes sense on disk: no `spec.md` link, no local path, no prefix.
4. **Revise.** When the target already holds a spec, read its description first and treat it as established context exactly as for an existing `spec.md`: carry every decision that still holds, revise only what this conversation changed, write a snapshot with no change notes. Keep a `**Reconciled:**` line at the very top if one is there. Write the whole description back (`save_project` / `save_issue` with `description`), since a spec rewrite is a snapshot, not an edit.
5. Close as in local mode: the URL of what was written and the one line naming the testing boundary. `/cppcho:to-tickets <that URL>` cuts the tickets from it.

A conversation that merely mentions a Linear issue — "related: MVNOALL-1425", a pasted link — with no Linear target in the argument is local mode: write `spec.md` and make no Linear call. When the Linear MCP tools are not available, stop and say so in one line rather than writing a local epic the user did not ask for.

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
