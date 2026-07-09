---
name: upload-session-to-proto-box
description: Render a Claude Code session transcript to a shareable HTML site and publish it to proto-box.mercari.in. Use when the user wants to share, publish, or get a link for a Claude Code session/transcript/conversation (this one or a past one).
---

# Upload a Claude Code session to proto-box

Turns a Claude Code session (the JSONL under `~/.claude/projects/`) into a
self-contained, mobile-friendly HTML site via simonw's
[`claude-code-transcripts`](https://github.com/simonw/claude-code-transcripts),
then publishes it to `proto-box.mercari.in` so it has a shareable link.

The transcript is rendered as a **clean, tool-free reading view**: only the human
prompts and Claude's text answers. Tool calls, tool results, thinking blocks, file
edit/write blocks, TODO lists, agent/task notifications, and all per-prompt tool
stats are stripped from every page and from the index. This happens by pre-filtering
the JSONL (`filter-transcript.py`) before rendering, so nothing tool-related leaks
into the body, the index, or the summary counts.

Rendering + filtering are done by `session-tool.sh` (next to this file); publishing
uses the proto-box `upload_site` / `add_site_version` tools.

## Before anything: privacy check

proto-box sites are **permanent** and visible to **anyone with a kouzoh.com login
and the link**. A session transcript can contain source code, file contents,
internal names, tokens/secrets that scrolled by, and customer data. This is a much
bigger surface than a normal prototype upload.

So **always confirm with the user before uploading**, and name what is about to
become visible. If the session touched anything sensitive (prod data, PII,
credentials), say so and let them decide. Do not upload without an explicit go.

## Steps

The helper is bundled with this skill. It derives the session directory from the
*current working directory*, so leave the shell in the project you were working in
(don't `cd` into the plugin dir). For brevity below:

```bash
TOOL="$CLAUDE_PLUGIN_ROOT/skills/upload-session-to-proto-box/session-tool.sh"
```

1. **Pick the session.**
   - Default target is the current session (the most recently modified transcript).
   - If the user is vague about *which* session, or asks for an older one, list
     recent sessions and let them choose:
     ```bash
     bash "$TOOL" list 10
     ```
     Each row shows a number, timestamp, size, session id, and the first prompt.

2. **Confirm** the target session and the privacy implications (see above).

3. **Render** to a static site. Omit the argument for the current session, or pass
   a session id / a `.jsonl` path:
   ```bash
   bash "$TOOL" render [SESSION]
   ```
   The last stdout line is the output directory (contains `index.html` +
   `page-NNN.html`, fully self-contained, tool-free). Note that size — proto-box caps sites at
   25 MiB / 500 files / 100 MiB uncompressed, so a very large session may need
   trimming (uncommon; transcripts paginate and compress well).

4. **Publish** with the proto-box `upload_site` tool, pointing at that directory.
   Suggest a readable `name` such as `cc-session-<short id>` or a few words from the
   first prompt — proto-box derives the real slug itself, so report the URL that
   comes back rather than predicting it.
   - If you are re-publishing a session already uploaded (e.g. the same session
     after more turns), use `add_site_version` against the existing site so the link
     stays the same, instead of creating a new one.

5. **Return the link** on its own line, ready to copy.

## Notes

- First run of `session-tool.sh render` downloads `claude-code-transcripts` via
  `uvx` (cached afterwards). If `uvx` is missing, install `uv`
  (`brew install uv`).
- The current session's transcript is written live, so rendering it captures the
  conversation up to that moment; later turns won't appear until you re-render.
- proto-box auth uses local Google credentials; on an IAP 401/403 the user runs
  `gcloud auth application-default login` once.
