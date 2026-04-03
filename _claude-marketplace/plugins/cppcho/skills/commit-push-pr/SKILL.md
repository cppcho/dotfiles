---
name: cppcho:commit-push-pr
description: Commit, push, and open a PR
allowed-tools: Bash(git checkout --branch:*), Bash(git status:*), Bash(git push:*), Bash(gh pr create:*), Skill(cppcho:commit)
---

## Context

- Current git status: !`git status`
- Current git diff (staged and unstaged changes): !`git diff HEAD`
- Current branch: !`git branch --show-current`

## Your task

Based on the above changes:

1. Create a new branch if on main
2. Create a commit using the `/cppcho:commit` skill
3. Push the branch to origin. IMPORTANT: Always use `git push -u origin <branch>` to set upstream tracking
4. Create a draft pull request using `gh pr create --draft`
5. You have the capability to call multiple tools in a single response. You MUST do all of the above in a single message. Do not use any other tools or do anything else. Do not send any other text or messages besides these tool calls.
