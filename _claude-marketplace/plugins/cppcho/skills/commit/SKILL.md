---
name: commit
description: Creates one git commit from the current changes in Conventional Commits format, with no scope and no footers. Use when the user says commit, asks to commit or check in the changes, or wants the current work recorded; other skills invoke it to commit work they just finished.
allowed-tools: Bash(git add:*), Bash(git status:*), Bash(git commit:*), Bash(git diff:*), Bash(git branch:*), Bash(git log:*)
---

## Context

- Current git status: !`git status`
- Current git diff (staged and unstaged changes): !`git diff HEAD`
- Current branch: !`git branch --show-current`
- Recent commits: !`git log --oneline -10`

## Your task

Based on the above changes, create a single git commit using Conventional Commits format.

### Commit message format

```
<type>: <description>
```

Types: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert`

- Do NOT include a scope (e.g., use `feat: ...` not `feat(scope): ...`)
- Do NOT add any Co-Authored-By or other footers
- Keep the description concise and lowercase

You have the capability to call multiple tools in a single response. Stage and create the commit using a single message. Do not use any other tools or do anything else. Do not send any other text or messages besides these tool calls.
