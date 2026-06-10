---
name: cppcho:slack-e2e
description: Plan and run an end-to-end test of a Slack app against real Slack. Use when the user says "slack e2e", "end-to-end test slack app", "verify slack app on slack", "drive slack to test", or pastes a Slack user token and asks to verify a feature against real Slack.
---

The user wants to verify a Slack app end-to-end against real Slack — you drive the Slack side on their behalf using a user token they provide, watch the app's logs to confirm behavior, and keep a live-updated test-case report. This skill assumes nothing about which app framework is in use (Socket Mode, Events HTTP, slash commands, etc.) but encodes the gotchas that recur regardless.

## Getting started

If the user provided a test scope in their message, acknowledge it and start collecting the rest of the inputs. If not, ask them what behavior they want to verify.

Gather everything you need before drafting the plan. Use `AskUserQuestion` in a single batch where possible. Ask for:

- **Test scope** — what behavior to verify, in plain language. You'll restate it as concrete checks in the next step.
- **Slack user token** (`xoxp-…`) — must be a user token, not a bot token. App-installed `xoxp-` tokens (the `xoxp-<team>-<user>-<install>-<secret>` shape from an installed integration) tag every post with `bot_id` and `bot_profile`, so most bots' echo-loop filters drop them. Pure session tokens (`xoxs-…`) don't. Default to asking the user which type they pasted (see Gotchas).
- **How to start the app locally** — the exact command the user runs (varies by stack: `make run-local`, `npm start`, `python -m app`, `cargo run`, `docker compose up`, etc.) or "already running on port X". You'll launch it as a background Bash task.
- **Where the app's logs go** — stdout from the background task is the default; a file path also works. You'll read this rather than calling `conversations.replies`.
- **Channel ID** — paste preferred over API lookup. Personal tokens often lack `channels:read`/`groups:read`/`usergroups:read`.
- **Any other Slack IDs the checks need** — user IDs, usergroup/subteam IDs, message ts values, app/team IDs. Ask only for the ones the scope actually requires; don't pre-collect generic IDs you might not use.
- **Local bot's user ID** — the `U…` ID of the *locally-started* app, not whatever `@bot-name` resolves to in the workspace. With `link_names=true`, Slack auto-links `@<bot-name>` to whichever bot in the workspace owns that handle — typically the deployed prod instance, not your local one. If the user doesn't know it, see "Bot identity resolution" below.
- **Report file path** — defaults to `./slack-e2e-<YYYYMMDD-HHMMSS>.md` in the working directory. **Always create a fresh file per session.** Never append to or overwrite a prior report, even if one with today's date already exists — bump the timestamp to the current minute. Each run is its own immutable record.

Treat the token as sensitive from the moment you receive it: don't echo it back, don't include it in any file you write, and don't paste it into a Slack message body. Hold it only in shell variables inside individual `Bash` calls.

## Drafting the plan and creating the report file

Translate the scope into concrete observable checks. For each one, name what the app should do (post a card, edit a card, add a reaction, return a JSON response, …) and how you'll observe it (a specific log line, a `chat.update` request body, a curl response).

Flag any check whose behavior is gated on real-world state — wall clock, holidays/calendars, business hours, feature flags, role-or-membership checks, external API responses — that you can't reach from outside. For each such check, decide whether to skip it or to apply a temporary in-code patch (see TEMP-patch discipline below).

Create the report file before executing. Use this layout:

```markdown
# Slack E2E run — <scope summary>

- Started: <YYYY-MM-DD HH:MM TZ>
- Token user: <auth.test user> (<team>)
- App: <start command>
- Channel: <channel ID>

Statuses: ⏳ pending · ▶️ running · ✅ pass · ❌ fail · ⏭ skipped

| # | Test | Expected behavior | Status | Observed | Evidence |
|---|------|-------------------|--------|----------|----------|
| 1 | <short label> | <one or two lines of expected observable behavior> | ⏳ pending | — | — |
```

Every check is a row, all start as `⏳ pending`. Then present the plan to the user and pause for approval before executing. **This approval is required even when auto-mode is active** — the skill explicitly stops here, regardless of auto-mode's "don't pause for clarifying questions" bias.

The user may narrow scope at plan-approval time or mid-run ("just check the language feature, skip the rest"). Honor it — change the dropped rows to `⏭ skipped` with a one-word reason ("descoped") rather than insisting on the original list. The report's value is the truthful record of what ran, not adherence to the first draft.

## Executing

Once the plan is approved:

1. **Token sanity check** — call `auth.test` once. Surface the resolved `team`, `user`, and `user_id` to the user. If `ok: false`, stop and report the `error`/`needed` fields.
2. **Bot identity resolution** — confirm the *local* bot's user ID before any mention-based check. Options, in order of preference: (a) the user pasted it, (b) the app's startup logs already print it, (c) ask the user to grep their config/env for it, (d) add a TEMP log line (e.g. `slog.Info` in Go, `console.log` in Node, `print` in Python) immediately after the app's own `auth.test` call so it surfaces on the next start. Do NOT trust `link_names=true` resolution of `@<bot-name>` — in a workspace with both a deployed and a local instance, this will silently pick the deployed one.
3. **Apply any TEMP patches** — for each patch, add a `// TEMP: <reason> — revert before committing` comment on every changed line. Track every patched file in a list you keep in conversation context (the list also goes into the report's Cleanup section at the end).
4. **Free the port + clear stale processes** — if launching the app, run `lsof -i :PORT` first. If a process is holding the port and *this run* didn't start it, surface its PID and command line to the user and ask before killing — it may be the user's own foreground work, not a stale leftover. Auto-killing is fine for processes this run started itself (e.g. an earlier iteration in the same session). A bot crash from a prior run leaves the port held, and the next start dies with `bind: address already in use`.
5. **Start the app** — launch the start command as a background Bash task. Read its output file periodically until you see an unambiguous ready marker (the user-supplied one, or common defaults: `server started`, `socket connected`, `listening on`).
6. **For each check, in order**:
   - Update the report row to `▶️ running` (use `Edit`, not `Write`, so prior rows stay intact).
   - Send the trigger via `chat.postMessage` (or whatever the check needs). Capture the response `ts`.
   - Tail the app's log file by re-reading it. Look for the expected log line, request body, or response.
   - Update the report row: `Status` → `✅ pass` / `❌ fail` / `⏭ skipped`; `Observed` → one-line summary; `Evidence` → `bot.log:L<line>` or `chat.postMessage ts=<ts>` or `curl /<endpoint> → <status>`.
   - On `❌ fail`, keep going through the rest of the checks unless the failure makes later checks meaningless.

Prefer log-tailing over `conversations.replies`. The latter often hits a missing-scope error (`channels:read`/`groups:read`) and, even when it works, the auto-mode classifier may deny reads on a channel the user didn't literally name in chat. The app's own logs are the authoritative record of what it did.

## Mid-run bug fixes

E2E exists precisely to catch what unit tests can't. When a check fails for a real production-code reason (not a TEMP-patch oversight), don't push past it — fix and re-run:

1. Apply the minimal fix in the production code. This is a real fix the user will want to keep, *not* a TEMP patch — no `// TEMP:` comment, no plan to revert.
2. Kill the app and restart so the new code loads.
3. Re-run the affected check.
4. Annotate the report row with `✅ pass (after bug fix)` and a short fix narrative (file:line + one-sentence explanation).
5. Add a `## Bug found + fixed during the run` section to the report describing what was wrong, why unit tests missed it, what regression test would have caught it, and which file holds the fix in the working tree.

The report then doubles as the artifact the user uses to land the fix in a follow-up commit — they don't need to reconstruct the story from chat history.

## Cleanup (always runs, even on failure)

1. Stop the background app task.
2. Revert every TEMP patch — use the tracking list from step 2 of execution. The reverts must produce the original line content; don't leave behind `// removed` comments.
3. Run `grep -rn "TEMP:"` over the repo. A non-empty result is a hard fail; surface it to the user.
4. Run `git status` and `git diff` to confirm only the changes the user intended remain.
5. Run the project's normal test/lint commands when you know them (e.g. `go test ./...`, `golangci-lint run ./...`, `npm test`).
6. Append a `## Cleanup` section to the report:
   ```markdown
   ## Cleanup

   - TEMP patches applied + reverted:
     - `<file>:<L>` — <reason>
   - `grep -rn "TEMP:"`: clean
   - `git status`: <summary>
   - Tests: <command + result>
   ```

## Final output to the user

- Path to the report file (their canonical record).
- Inline summary: row-by-row pass/fail with evidence.
- TEMP patches applied + confirmation each was reverted.
- Any remaining uncommitted edits, classified as intentional vs leftover.

## TEMP-patch discipline

When you have to touch app source to reach a check:

- Every changed line gets a `// TEMP: <one-line reason> — revert before committing` comment (or `# TEMP:` for Python, `<!-- TEMP: -->` for HTML, etc.).
- Never amend behavior beyond what the check needs. The smallest possible diff.
- **Avoid identity-shaped carve-outs.** A patch that special-cases a specific user ID, role, channel ID, or auth claim (e.g. `if user == "U123…" { allow }`) reads to the auto-mode classifier as an authorization bypass and will get locked. Even if your intent is purely E2E plumbing, the *shape* is the problem. Instead, do a **broad filter relaxation**: drop the entire predicate the test needs gone — e.g. turning a two-condition guard like `if subType != "" || botID != ""` into just `if subType != ""`. Same blast radius for the test run, but reads as test instrumentation, not bypass.
- If the classifier blocks you anyway: revert the patch in full, explain to the user what you were trying to bypass and why, and let them either (a) apply the patch themselves so it comes from their hand, or (b) provide a different driver token that doesn't need the patch at all.
- The patch never gets staged or committed by the skill — only the user does that.
- Track every (file, original lines, patched lines) tuple so the revert is deterministic.
- After running checks, revert; then `grep -rn "TEMP:"` to prove nothing was missed.

## Token-handling discipline

- Hold the token only in a shell variable inside individual `Bash` calls — never in a file, never echoed to stdout, never repeated back in chat.
- Never include the token in a Slack message body.
- If `auth.test` fails because the token is invalid or expired, ask the user for a fresh one rather than retrying.

**Auto-mode classifier may block every Slack API call** even when the token is in a per-call shell variable — once it sees a `xoxp-`/`xoxs-` token in the conversation context, every `curl … slack.com …` variant trips its credential-exfiltration heuristic. Don't waste round-trips trying to rephrase the command. After the first denial, just ask the user to exit auto mode for this session and resume.

Note: `! export FOO=bar` typed in the prompt does **not** persist into the `Bash` tool's subshells — they're separate shells. So `! export SLACK_TOKEN=…` is not a workaround; the variable will be empty in the next `Bash` call. Don't suggest it.

## Gotchas to remember

- **`bot_message` filtering**: `xoxp-` posts via `chat.postMessage` are tagged with `bot_profile` and the `bot_message` subtype **when the token belongs to an installed app integration** (the `xoxp-<team>-<user>-<install>-<secret>` shape). Bare workspace session tokens don't tag posts. App event dispatchers commonly drop messages where the subtype field is non-empty or where a bot identifier is set on the event (the field names vary by SDK: `SubType` / `subtype`, `BotID` / `bot_id`); if the app doesn't react to a driver post, suspect this first. Apply the TEMP-patch as a broad filter relaxation, not a per-user carve-out (see TEMP-patch discipline).
- **Bot identity vs. workspace handle**: `link_names=true` will resolve `@<bot-name>` to whichever bot in the workspace owns that handle. If both a deployed instance and a local one are installed, you'll mention the wrong one. Always use the `<@U…>` form with the *local* bot's user ID resolved via auth.test (see step 2 of Executing).
- **Echo-loop side effects from filter relaxation**: once the bot-id guard is off, the app processes its own posts as message events. Usually harmless (most apps either skip or short-circuit them) but expect unfamiliar log lines; double-check none of the app's paths take destructive action on its own posts before patching.
- **Missing read scopes**: personal tokens often lack `channels:read` / `groups:read` (channel listing), `usergroups:read` (subteam lookup), and `users:read`. Default to asking the user for IDs rather than resolving via API.
- **Auto-mode read denials**: `conversations.replies` on a channel ID the user didn't literally name in chat may be denied by the auto-mode classifier even when the API call would succeed. Use app logs.
- **State-gated branches**: behavior gated on the wall clock (weekends, holidays, business hours), feature flags, or external state usually isn't reachable from outside. TEMP-patch is the right tool — apply, run the check, revert.
- **Persisted app state across runs**: an app backed by any real datastore (Firestore, Postgres, Redis, etc.) remembers config from prior sessions, so checks that assume an "empty" or "inert" starting state may fail purely because of leftover state. Either reset state explicitly before the test (via API, CLI, or DB write), or design checks to be tolerant of pre-existing state and verify the *command's effect* rather than the starting state.
- **Side effects on real users**: if any data the app reads (a watched usergroup, a channel's member list, a database of registered users) contains real workspace members, the app may ping/DM/ephemeral them while you test. Prefer test-only entities; otherwise warn the user up front and treat any `user_not_in_channel`-style warning as expected, not a failure.
- **Inferred IDs**: when `chat.postMessage` returns a `channel` ID for a name-based post, that's a real ID — but reading from it via API may still hit the auto-mode classifier. Reading the app's logs is the cleanest workaround.
- **`auth.test` returns `not_authed` with a known-good token**: Slack's edge sometimes rejects bare Bearer POSTs that carry no body. Retry with the token as a form-encoded body (`curl -d "token=$T" …`) or add `-H "Content-Type: application/x-www-form-urlencoded"`. If the same call works one moment and fails the next, suspect this before assuming the token is expired.
- **Hand-rolled DB write paths drop newly-added struct fields**: a function like `SetChannelConfig` that builds its own `map[string]any` + `firestore.Merge(...)` (or any analogous SQL/NoSQL update builder) often lags behind the struct definition — adding a field to the struct doesn't automatically include it in the write. Unit tests using in-memory mocks don't catch this; the E2E is the safety net. When a check shows "command replied 'set'" but a follow-up read returns the old value, suspect this shape first: grep the store layer for the literal field name and check whether the field appears in *both* the data map and the merge-paths list. This is exactly the kind of bug E2E exists to catch — see "Mid-run bug fixes".
- **Mid-run user commits shift the cleanup baseline**: the user may land a commit (e.g. `git commit -m "wip"`) partway through the run. Afterward, `git status` and `git diff` only show the post-commit delta, which can look like work disappeared. At cleanup time, run `git log --oneline -5` too and call out any new-since-run-start commits by hash in the Cleanup section so the report is unambiguous.
