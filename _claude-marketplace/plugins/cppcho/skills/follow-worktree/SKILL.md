---
name: follow-worktree
description: Puts this session in the git worktree the work has moved to and moves its herdr pane into that worktree's workspace, opening the space if none is live — prefix+f's switch, made from inside the agent pane. Use when the session started in one checkout and the work belongs in another worktree, or when the user asks to switch, jump or follow to a worktree's space or pane in herdr.
argument-hint: "[worktree-path|branch]"
model: sonnet
---

# Follow the worktree in herdr

## Context

- Session working directory: !`pwd`
- Checkout root of it: !`git rev-parse --show-toplevel 2>/dev/null || echo "(not a git checkout)"`
- This pane / space: !`echo "pane ${HERDR_PANE_ID:-none}, space ${HERDR_WORKSPACE_ID:-none}"`
- Worktrees of this repo: !`git worktree list 2>/dev/null || true`

## Your task

Pick the target worktree, put this session's own working directory there, then
move the pane. Two steps, in that order.

### 1. Pick the target

Pick the target checkout in this order:

1. The path in the arguments, if any.
2. A branch or worktree name in the arguments: match it against the worktree
   list above and pass the checkout path. If nothing matches, stop and say so —
   creating a worktree is `gwt` / prefix+shift+g, not this skill.
3. Otherwise the worktree the work of this conversation has moved into — the
   checkout being edited, not necessarily the session's own directory.
4. Otherwise the session's working directory, shown above.

### 2. Enter it, then move the pane

Unless the working directory above is already the target, call `EnterWorktree`
with `path` set to it — always `path`, never `name`, which would create a
worktree instead of entering the one that was asked for. This is what makes the
move mean anything: moving a pane cannot change a directory, so without it the
pane sits in the worktree's space while the session keeps reading and writing
the checkout it started in. Entering also chdirs the process herdr watches, so
the pane reports the worktree as its foreground cwd.

`EnterWorktree` refuses a target that `git worktree list` does not show for the
repository the session launched in — a worktree of an unrelated repo, or a
second switch in one session to anywhere outside `.claude/worktrees/`. Take the
refusal at its word: do not retry it, do not reach for `name`, and do not try to
`cd` instead. Move the pane anyway and say the working directory stayed behind.

Then run `~/bin/herdr-follow-worktree <target>` once, with the path spelled out
rather than relying on the cwd.

Report where the pane went and, when it applies, that the session is now working
in the worktree — a line each, nothing more. The script reports its no-ops too
(pane already in that space, directory not a checkout, not running under herdr);
none of them is a failure worth working around.
