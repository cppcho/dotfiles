# /// script
# requires-python = ">=3.10"
# dependencies = ["slack-bolt>=1.18"]
# ///
"""Sync Slack message reactions into the macOS Things app.

React to any Slack message with the configured emoji (default :bookmark:)
and a to-do is created in Things containing the message text and a permalink
back to the original message. Runs locally over Socket Mode, so no public
URL is required.
"""
from __future__ import annotations

import logging
import os
import subprocess
import urllib.parse
from pathlib import Path

from slack_bolt import App
from slack_bolt.adapter.socket_mode import SocketModeHandler


def load_env_file(path: Path) -> None:
    """Load simple KEY=VALUE lines into the environment (does not override)."""
    if not path.exists():
        return
    for raw in path.read_text().splitlines():
        line = raw.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, _, value = line.partition("=")
        os.environ.setdefault(key.strip(), value.strip().strip('"').strip("'"))


load_env_file(Path(__file__).parent / "secrets.env")

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")
log = logging.getLogger("slack-things")

TRIGGER_EMOJI = os.environ.get("THINGS_EMOJI", "bookmark")
ONLY_USER = os.environ.get("SLACK_USER_ID")  # optional: only react to your own reactions
THINGS_LIST = os.environ.get("THINGS_LIST")  # optional Things list/project name
THINGS_TAGS = os.environ.get("THINGS_TAGS")  # optional comma-separated tag names

app = App(token=os.environ["SLACK_BOT_TOKEN"])


def fetch_message(client, channel: str, ts: str) -> dict | None:
    """Return the message at `ts`, handling both top-level and threaded replies."""
    resp = client.conversations_history(
        channel=channel, latest=ts, oldest=ts, inclusive=True, limit=1
    )
    msgs = resp.get("messages", [])
    if msgs and msgs[0].get("ts") == ts:
        return msgs[0]

    resp = client.conversations_replies(channel=channel, ts=ts, limit=1, inclusive=True)
    for msg in resp.get("messages", []):
        if msg.get("ts") == ts:
            return msg
    return None


def add_to_things(title: str, notes: str) -> None:
    params = {"title": title, "notes": notes}
    if THINGS_LIST:
        params["list"] = THINGS_LIST
    if THINGS_TAGS:
        params["tags"] = THINGS_TAGS
    url = "things:///add?" + urllib.parse.urlencode(params, quote_via=urllib.parse.quote)
    subprocess.run(["open", url], check=True)


@app.event("reaction_added")
def on_reaction(event, client):
    if event.get("reaction") != TRIGGER_EMOJI:
        return
    if ONLY_USER and event.get("user") != ONLY_USER:
        return

    item = event.get("item", {})
    if item.get("type") != "message":
        return

    channel = item["channel"]
    ts = item["ts"]

    msg = fetch_message(client, channel, ts)
    text = (msg or {}).get("text", "").strip()

    try:
        permalink = client.chat_getPermalink(
            channel=channel, message_ts=ts
        ).get("permalink", "")
    except Exception as exc:  # noqa: BLE001 - log and still create the to-do
        log.warning("chat.getPermalink failed: %s", exc)
        permalink = ""

    title = text.splitlines()[0][:200] if text else "Slack message"
    notes_parts = []
    if text and (len(text) > 200 or "\n" in text):
        notes_parts.append(text)
    if permalink:
        notes_parts.append(permalink)

    add_to_things(title, "\n\n".join(notes_parts))
    log.info("Added to Things: %s", title)


def main() -> None:
    handler = SocketModeHandler(app, os.environ["SLACK_APP_TOKEN"])
    log.info("Listening for :%s: reactions over Socket Mode…", TRIGGER_EMOJI)
    handler.start()


if __name__ == "__main__":
    main()
