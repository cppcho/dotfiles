---
name: cppcho:spec-interview
description: Interview the user about a feature or product idea they want to build, asking deep technical and design questions, then write a complete spec to SPEC.md. Use when the user says "interview me", "help me spec out", "I want to build", "flesh out this idea", "write a spec for", or wants structured requirements gathering for a new project or feature.
---

The user wants to build something. Your job is to conduct a thorough product and technical interview to deeply understand what they want to build, then produce a written spec.

## Getting started

If the user provided a description of what they want to build (via arguments or in conversation), acknowledge it and jump straight into your first probing question. If not, ask them to describe what they want to build.

## Interview approach

Ask one question at a time using the AskUserQuestion tool. Wait for each answer before asking the next question.

Focus your questions on the areas that matter most and that the user is least likely to have thought through:

- **Technical implementation**: Architecture, data model, key algorithms, infrastructure, third-party dependencies
- **UI/UX**: User flows, states (loading, empty, error), interaction patterns, accessibility
- **Edge cases**: Concurrency, failure modes, data migration, backwards compatibility
- **Security & performance**: Auth model, rate limiting, data sensitivity, expected scale, latency requirements
- **Tradeoffs**: Build vs buy, consistency vs availability, flexibility vs simplicity
- **Scope**: What's MVP vs future, what can be cut, what's non-negotiable

Don't ask questions the user has already answered. Don't ask obvious questions or ones that don't meaningfully shape the implementation. Your value is in surfacing the hard problems the user hasn't considered yet — the things that would bite them two weeks into building.

Adapt your depth to the complexity of the project. A simple CLI tool needs fewer questions than a distributed system. Read the room — if the user gives short answers, they may want to move faster. If they give detailed answers, dig deeper.

When you feel you've covered the important ground (or the user signals they're ready to move on), tell them you have enough to write the spec.

## Writing the spec

Synthesize everything into a clear, actionable spec and write it to `SPEC.md` in the current working directory. Use this structure:

```markdown
# [Project Name]

## Overview
Brief description of what this is and why it exists.

## Goals
What this project aims to achieve. Be specific.

## Non-goals
What this project explicitly does NOT aim to do. This is just as important as goals — it prevents scope creep.

## Technical Design
Architecture, data model, key components, technology choices, and how they fit together. Include diagrams (mermaid) if the architecture warrants it.

## UI/UX
User flows, key screens/interactions, states to handle. Skip this section if there's no user-facing interface.

## Edge Cases
Known edge cases and how they should be handled.

## Open Questions
Things that still need to be decided or investigated.

## MVP Scope
The minimum viable version — what to build first, and what to defer.
```

Omit sections that don't apply. Add sections if the project needs them (e.g., "Security Model", "Migration Plan", "API Design").

After writing the spec, give the user a brief summary of what you wrote and ask if anything needs to be revised.
