#!/usr/bin/env python3
"""Filter a Claude Code session JSONL into a clean, tool-free reading transcript.

simonw's claude-code-transcripts renders whatever is in the JSONL, so the cleanest
way to strip "all tool related stuff" everywhere (body pages AND the index/counts)
is to remove it at the source rather than surgically editing the generated HTML.

We drop:
  - tool_result turns (user messages whose content is a tool result)
  - tool_use blocks inside assistant messages (bash/read/edit/write/TodoWrite/agent...)
  - meta / injected / control turns that are not real human prompts:
    isMeta turns, slash-command wrappers, task/agent notifications, local-command
    caveats/output, system reminders, and "[Request interrupted...]" markers

We keep:
  - real human text prompts
  - assistant text blocks (thinking blocks are dropped too)
  - non-message bookkeeping lines (mode, snapshots, summaries) pass through untouched

Usage: filter-transcript.py IN.jsonl OUT.jsonl
"""
import json
import re
import sys

# User-turn text starting with one of these wrapper tags is control/injected noise,
# not a human prompt.
NOISE_TAGS = re.compile(
    r"^<(task-notification|command-name|command-message|command-args"
    r"|local-command-caveat|local-command-stdout|local-command-stderr"
    r"|bash-input|bash-stdout|bash-stderr|system-reminder|user-memory-input)\b"
)

KEEP_BLOCKS = {"text"}


def block_text(content):
    """Joined text of a message's content (string or block list)."""
    if isinstance(content, str):
        return content
    if isinstance(content, list):
        return " ".join(
            b.get("text", "")
            for b in content
            if isinstance(b, dict) and b.get("type") == "text"
        )
    return ""


def has_tool_result(content):
    return isinstance(content, list) and any(
        isinstance(b, dict) and b.get("type") == "tool_result" for b in content
    )


def is_noise_user_text(text):
    t = text.strip()
    if not t:
        return True
    if t.startswith("[Request interrupted"):
        return True
    if NOISE_TAGS.match(t):
        return True
    return False


def filter_user(obj, msg):
    """Return the (possibly unchanged) obj to keep, or None to drop the turn."""
    content = msg.get("content")
    if obj.get("isMeta"):
        return None
    if has_tool_result(content):
        return None
    if is_noise_user_text(block_text(content)):
        return None
    return obj


def filter_assistant(obj, msg):
    """Keep only text blocks (drop tool_use and thinking); drop empty turns."""
    content = msg.get("content")
    if isinstance(content, list):
        kept = [
            b
            for b in content
            if isinstance(b, dict) and b.get("type") in KEEP_BLOCKS
        ]
        if not kept:
            return None
        msg["content"] = kept
    return obj


def main():
    src, dst = sys.argv[1], sys.argv[2]
    with open(src, encoding="utf-8") as fin, open(dst, "w", encoding="utf-8") as fout:
        for line in fin:
            line = line.rstrip("\n")
            if not line.strip():
                continue
            try:
                obj = json.loads(line)
            except Exception:
                fout.write(line + "\n")  # pass through anything unparseable
                continue

            typ = obj.get("type")
            msg = obj.get("message")
            if typ == "user" and isinstance(msg, dict) and msg.get("role") == "user":
                obj = filter_user(obj, msg)
            elif typ == "assistant" and isinstance(msg, dict):
                obj = filter_assistant(obj, msg)
            # else: mode / file-history-snapshot / system / summary ... pass through

            if obj is not None:
                fout.write(json.dumps(obj, ensure_ascii=False) + "\n")


if __name__ == "__main__":
    main()
