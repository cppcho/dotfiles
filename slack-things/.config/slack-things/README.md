# slack-things

React to a Slack message with an emoji (default `:bookmark:`) and it lands as a
to-do in the macOS [Things](https://culturedcode.com/things/) app, with the
message text and a permalink back to the original.

Runs locally over **Socket Mode** (outbound WebSocket), so there is no public
URL, tunnel, or server to host.

> Why a reaction and not Slack's native "Save for later"? Slack retired the
> stars/saved-items APIs in 2023 — the `star_added` event is no longer emitted
> and `stars.list` cannot see Later items. Channel bookmarks (`bookmarks.*`)
> have read/write methods but **no event** to subscribe to. A reaction is the
> only per-message trigger Slack still pushes in real time.

## 1. Create the Slack app

1. Go to <https://api.slack.com/apps> → **Create New App** → **From a manifest**.
2. Pick your workspace and paste the contents of [`manifest.yaml`](./manifest.yaml).
3. **Install to Workspace** (OAuth & Permissions), then copy the **Bot User
   OAuth Token** (`xoxb-…`).
4. **Basic Information → App-Level Tokens → Generate Token**, add the
   `connections:write` scope, and copy the token (`xapp-…`).

## 2. Configure secrets

```bash
cd ~/.config/slack-things
cp secrets.env.example secrets.env
$EDITOR secrets.env   # paste the xoxb- and xapp- tokens
```

`secrets.env` is gitignored. Optional knobs (emoji, list, tags, restricting to
your own reactions) are documented in the example file.

## 3. Run it

```bash
uv run ~/.config/slack-things/app.py
```

`uv` installs `slack-bolt` into an isolated, cached environment automatically
(declared inline in `app.py`). You should see `Listening for :bookmark:
reactions…`.

## 4. Run on login (launchd)

The LaunchAgent plist is stowed to `~/Library/LaunchAgents/`. Load it with:

```bash
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.cppcho.slack-things.plist
launchctl enable gui/$(id -u)/com.cppcho.slack-things
```

Logs go to `/tmp/slack-things.log`. To stop / reload:

```bash
launchctl bootout gui/$(id -u)/com.cppcho.slack-things
```

## Usage

Invite the bot to any channel you want to use (`/invite @things-sync`) — Slack
only delivers `reaction_added` for channels the bot is in. Then react to a
message with `:bookmark:` (or your `THINGS_EMOJI`). A to-do appears in your
Things Inbox.

## Notes

- The bot must be a channel member to read message text; without history access
  the to-do is still created from the permalink alone.
- For DMs, the bot needs to be in the conversation and `im:history` applies.
