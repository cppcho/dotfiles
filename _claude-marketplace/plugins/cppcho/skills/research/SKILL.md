---
name: research
description: Investigates a question against high-trust primary sources and captures the findings as a Markdown file under `.scratch/research/`. Use when the user wants a topic researched, docs or API facts gathered, or reading legwork delegated to a background agent.
argument-hint: "[question]"
---

Dispatch a **background subagent** with the Agent tool to do the research, so you keep working while it reads. It inherits this conversation, so pass it the question plus anything it needs that the conversation doesn't already carry.

Its job:

1. Investigate the question against **primary sources** — official docs, source code, specs, first-party APIs — not a secondary write-up of them. Follow every claim back to the source that owns it.
2. Write the findings to a single Markdown file, citing each claim's source. Match its length to the question: cover the substance, and leave out filler sections, restated summaries, and boilerplate.
3. Save it to `.scratch/research/<slug>.md`, where `<slug>` is a short dash-case name for the question. Create the directory if it does not exist.
