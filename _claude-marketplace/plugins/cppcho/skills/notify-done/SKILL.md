---
name: cppcho:notify-done
description: Send me a notification (Slack DM + macOS banner + tmux bell) when the current task finishes, so I can walk away during a long session. Invoke when the user says "notify me when done", "ping me when finished", "let me know when this is done", or runs /notify-done before/with a long-running request.
allowed-tools: Bash(~/bin/notify:*), Bash(notify:*)
---

## Your Task

The user wants to be pinged when the work they asked for is complete, so they can step away during a long session.

1. **Carry out whatever the user asked.** If they passed a task with the skill (in the arguments or the same message), do that. If they invoked this skill on its own, the request is whatever they ask next — continue the session as normal.

2. **As your very last action before you stop**, send the notification:
   ```bash
   ~/bin/notify "<one-line summary of what you finished>"
   ```
   Examples:
   - `~/bin/notify "refactor done, all tests green"`
   - `~/bin/notify "PR #123 opened, CI running"`
   - `~/bin/notify "blocked: need your input on the migration"` (notify even if you stop early needing input)

## Notes

- `~/bin/notify` fires a Slack DM, a macOS banner, and the tmux bell. It is fire-and-forget and never blocks.
- Keep the summary to one short line — it shows up in a Slack DM and a desktop banner.
- Send the notification whether the task succeeded, failed, or you're stopping to ask the user something. The whole point is to reclaim their attention.
- Do not notify on intermediate progress — only once, when you are actually done and about to hand control back.
