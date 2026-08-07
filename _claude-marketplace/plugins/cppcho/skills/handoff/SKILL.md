---
name: handoff
description: Hand the current conversation off to a fresh background agent that picks up the work immediately.
argument-hint: "[what the next session is for]"
disable-model-invocation: true
allowed-tools: Bash(claude --bg:*), Bash(claude agents:*)
---

Write a handoff summary of the current conversation so a fresh agent can continue the work. Instead of saving it, launch a background agent seeded with the summary as its prompt: `claude --bg --name "<descriptive name>" "<handoff summary>"`. It starts in the current working directory and returns immediately; the user manages it with `claude agents`.

Always pass `--name` (e.g. `--name "Fix login bug"`) — it sets the display name in the job list, session picker, and terminal title.

Include a "suggested skills" section in the summary, which suggests skills that the agent should invoke.

Do not duplicate content already captured in other artifacts (specs, plans, issues, commits, diffs). Reference them by path or URL instead.

Redact any sensitive information, such as API keys, passwords, or personally identifiable information — the summary becomes the agent's prompt.

If the user passed arguments, treat them as a description of what the next session will focus on and tailor the summary accordingly.
