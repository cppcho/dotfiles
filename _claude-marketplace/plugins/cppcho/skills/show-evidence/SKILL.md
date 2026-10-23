---
name: show-evidence
description: Shows a change working in the running app — reads the PR or diff, lists every variant the change can render or return (including the "nothing shown" ones), gets the app running in its most predictable mode, gets past whatever gates the changed code (feature flags, experiments, login, missing deps), makes every variant appear in one session with a marked local-only data tweak, drives the real surface in a visible browser or terminal, and leaves the app open for the person to touch and try themselves, with an HTML report published as a private Artifact that puts a screenshot of each variant beside what was observed against what was expected. Scope defaults to the PR; it asks when no PR is clear. Use when the user asks to open a change in the browser, show or prove that a PR works, demo it, "show me all the variations", get evidence or screenshots for a PR, verify a change end to end, or asks how to reproduce what a change does — in any repo, any stack. For writing PR verification steps without running anything, or for reviewing the code itself, this is not the skill.
argument-hint: "[pr-number|url|branch] [only <variant>]"
---

# Show evidence

**Skill revision: 2026-10-23.** Quote it in the report.

The point is evidence a person can trust because they can touch it: the running app, open in front of them, where they can watch the change do each thing it claims and then try it themselves. A green test suite, a headless run, a started dev server or a description of what "should" appear is not that, and neither is a text report on its own. The report backs up the app; it doesn't replace it. The run is done when every variant has been seen or has a stated reason it can't be, and the person has the app open on the result in a window they can use.

This skill works in any repo and any stack. Take start commands, gates and fixtures from the repo in front of you, not from memory of another project.

Keep the user posted in a line at each phase. Builds and installs take minutes, and silence during them reads as a hang.

## 1. Know what you're proving

The scope is the PR: what its diff changes is what you prove, and nothing more. Take the PR from the argument, or from the current branch (`gh pr view`). If there is no PR, or the context leaves it unclear which change is meant (several open PRs, uncommitted work on top, a branch with no PR), ask the user what to prove before doing anything else. Guessing the scope wrong wastes the whole run.

Read the PR body and the diff: `gh pr view --json url,title,body,baseRefName`, then `git fetch origin <baseRefName>` and `git diff origin/<baseRefName>...HEAD`. Diff against the PR's real base, not `main`: a stacked PR diffed against `main` drags in every PR below it. The PR's own "how to verify" is a starting point, not the list: derive the variants from the code's branching, because that is what can actually happen. For each branch the change adds or alters, write one line: the input or state that reaches it, and what should be observable. Take that input from the mock or scripted layer the build will run (the text a fake model matches, the fixture field that decides), not from the UI. A button that starts the flow against live services can do nothing against a scripted one, and every wait after it times out. Include the negative cases — "this kind of user sees no button" is a variant, and it is the one most often broken.

Note anything the change makes reachable that wasn't before, such as a new link out of a screen. Those are where the "try to break it" check goes.

## 2. Get it running, predictably

Read `<repo root>/.cppcho/evidence/RUNBOOK.md` first if it exists. Earlier runs left it there: the start command and the env it needs, the gate override, the viewport, and which inputs reach which code. Trust it, but check it against the repo when a step fails. At the end of the run, add what you learned the hard way, so the next run doesn't find it again.

Prefer the mode the repo's own end-to-end tests run in: a test or integration build with scripted or mocked dependencies. It gives the same output every time, so a variant you show can be shown again. A dev server against live services gives answers that vary between runs and needs credentials. Use it only when the change is about that live integration. In mocked mode, don't check credentials (cloud tokens, logins): the build doesn't need them, and the check can be refused as credential handling.

Find the start command in the repo's docs, its `package.json` / `Makefile`, and the e2e config (`playwright.config.*`, CI workflow). Apply any env setup that the PR's own "how to verify" or the repo's docs give (a variable to unset, a file to copy) before the first launch, not after it fails. If the checkout is outside the session's working directory, run the build and server unsandboxed from the start.

Launch it with the tool's own background mode, one attempt at a time, each with its own log, and tag the exit so a crash can't hide: `<start cmd> > <log> 2>&1; echo "__EXITED $?" >> <log>`. Wait with an until-loop on the ready line or `__EXITED`, capped at two or three minutes per wait; then read the log and wait again if it is still building. A list of failure patterns never covers every stack, and a loop that misses the crash blocks until its timeout. Read the log rather than guessing.

Before you launch again after a failure, `curl` the port. An earlier attempt may already be serving, and a new launch overwrites the evidence of it.

Fix what blocks it in place:

- **Dependencies missing** (fresh clone or worktree): install with the repo's package manager.
- **Private registry or other credential** the session wasn't given: stop and tell the user the exact command to run. Don't go find a token on the machine.
- **Build fails on lint or format** of a file you touched: format it and lint it alone before rebuilding. A full rebuild to find the next lint error costs minutes each time.
- **Port taken**: look at what holds it. Under this skill you may restart a local server, including one the user started, but say that you did. If it belongs to another checkout or session, use a different port instead. Then also move any URLs the build bakes in (public env vars, API base URLs, callback URLs). Otherwise requests quietly go to whatever still holds the old port.
- **Restart without rebuilding** when only runtime state needs resetting and the code is unchanged. Read the start script once and copy the env vars it exports, then run only its final serve step with them. Skip the build step.
- **Stopping a server you started in the background ends that task.** Keep track of which task now owns the port, so the report states correctly what is left running.

## 3. Reach the changed code

A "not found" page, a redirect or an empty screen on the first load is almost always a gate, not a bug. Before concluding anything, find what gates the screen: a feature flag, an experiment assignment, an auth check, an env var. Look at how the repo's e2e tests turn it on (a cookie, a header, an env var, a debug override) and do the same thing in the browser. Don't edit the gating code: then you'd be proving a different app.

A debug menu or flag panel may exist yet be compiled out of test builds. Check its render condition before telling the user to use it.

## 4. Make every variant appear

Tests usually stub data per test, through hooks a normal browser can't reach. To show all variants in one session, change the data layer locally: the mock fixture, seed or stub the app reads.

The person will try it by hand after you, so build a stub they can steer.

- **Key by input** by default: let the request choose the variant, through a marker the person can type or set (a query param, a header, a word in the input, a test account ID). Then they can bring back any variant in any order, and a reload or a second tab doesn't break anything. Give them the list of markers in the report.
- **Rotate per call** only when nothing in the request can carry a marker: a list of variants and a counter, so each request returns the next one. Write down the order of actions that lines up with the list, and give a way to reset the counter that doesn't need you (a reset route, or a restart command they can run).
- Mark the edit at the top as `LOCAL ONLY — do not commit`, keep it lint-clean so the build accepts it, and never commit it.
- Save it as a patch, `git diff -- <stub files> > <repo root>/.cppcho/evidence/<pr>/local-only.patch`, once it builds. Then `git apply -R` reverts it and `git apply` brings it back, so the working tree can be clean before anyone commits in it.
- A counter lives in the server process, so a restart resets it. Every request from any tab moves it on. If a step goes out of order, reset and start over rather than reasoning about where the counter is.

You may make these edits and restarts without asking. Anything outside the working tree, or any commit, still needs the user.

## 5. Drive the real surface

- **Browser**: use the chrome-devtools MCP tools on the real page, doing what a user does. Its window is visible, so the person can watch each step and take over afterwards. That visibility is the point, so a headless browser or a scripted test runner doesn't count, even when it reads the same DOM.
  - If the MCP can't start because another Chrome holds its profile ("browser is already running"), find that process and ask the user to close it, or offer to use their own Chrome (the `claude-in-chrome` skill) instead. Do this before driving anything. Don't switch to headless without asking. Silent headless evidence is what makes a person ask "where did you test this?".
  - Open your own page with `new_page` and an `isolatedContext` named for the PR and port (`pr5648-8000`). Other sessions can share this browser. Leave pages you didn't open alone.
  - Set the viewport the product is used at before the first screenshot. Mobile web gets phone emulation (`emulate` with `390x844x2,mobile,touch`); a desktop app keeps the window size. The screenshots and the person's view then match what users see.
  - Find controls in the accessibility snapshot by role and accessible name, and act on them with `fill` / `click` by uid. A button labelled through `aria-labelledby` or an icon has no text for a DOM text search to find.
  - If you must type from a script, a framework-controlled input (React and the like) ignores a plain `.value =`. Set it through the native setter, `Object.getOwnPropertyDescriptor(HTMLTextAreaElement.prototype, 'value').set.call(el, v)` (or `HTMLInputElement`), then dispatch a bubbling `input` event.
  - After each action, wait on a condition that only the new result satisfies, such as the count of result elements reaching N. Waiting for text or an element that an earlier step already rendered returns at once and lets steps overlap.
  - When a tool reports that a click failed but the page changed, trust what the page shows.
  - The tools' `sourcePath` and screenshot `filePath` only accept paths inside the MCP's workspace roots, so the scratchpad and `/tmp` are refused. Pass scripts inline, and when you need a helper across many calls, define it once on `window`.
- **API or CLI**: make the real call. Keep the exact command and the trimmed real response or log lines. Leave the server running and give the person the command to run, so they can try it themselves.

Then **read the result back** from the page or output: which elements exist, their text, which ones hold the new control. Compare that with the expected line for each variant. What you read back is the evidence. Don't report what you expected to see.

**Screenshot every variant the moment it is on screen**, including the negative ones (the screen without the button is the proof the button is absent). Do it before the next action, because a reload or the next step takes it away, and a variant you only read from the accessibility tree has no picture in the report. Save each one with `filePath` to `<repo root>/.cppcho/evidence/<pr>/NN-<variant-slug>.png`, numbered in the order of the variant list. `.cppcho/` is in the global gitignore, so the files stay out of `git status`, and they sit inside the MCP's roots. A screenshot without `filePath` lands only in the session's tool-result cache under an opaque name, which nobody can find later. Frame the part that differs: scroll it into view, or pass `fullPage: true` when the change spans more than one screen. For an API or CLI variant, keep the command and the trimmed output as text instead.

When something fails once, such as a hang, an error or a wrong result, keep what you captured: the URL, the network requests and their statuses, console errors. Then retry the same path twice, starting from the same state. If it doesn't come back, report it as "seen once, not reproduced", with that capture. Don't drop it, and don't call it a bug in the change.

Some variants are visible only for a short time by design, for example "shown only on the newest item" or "hidden while loading". Capture them while they're visible, or say how to bring them back.

Do one "try to break it" action near the change: a disallowed user, doing the action twice, leaving and coming back. Report what happened even when it isn't a bug in the change. Say whether it predates the change, and whether this change made it easier to hit.

Leave the app open on the result, scrolled to the first variant. If you can't leave a window the person can use, the run isn't done: say what blocks it and ask.

## 6. Report

The person has the app in front of them, so the report is a guide to it, not a substitute for it. It is an HTML page with the screenshots in it, published as a private Artifact, because a page with a picture beside each verdict can be read and passed to a reviewer, and terminal text can't.

Build it from [assets/report-template.html](assets/report-template.html):

1. Make `<scratchpad>/evidence-<pr>/` and copy the screenshots into its `shots/` folder. The Artifact tool reads sources only from the working directory or the scratchpad.
2. Copy the template to `report.html` there. Fill it in, repeat the variant card per variant, and delete the sections with nothing to say. It already meets the artifact page contract (title, light and dark tokens, phone width), so you don't need the `artifact-design` skill for it.
3. Publish it with the Artifact tool: `file_path` the report, `root` the evidence folder, `files` mapping each `shots/NN-….png` to itself, `icon: "camera"`, and a one-sentence `description`. Republish to the same file path after any fix.

If the session has no Artifact tool, leave `report.html` on disk, give its absolute path, and say the link isn't available here. Never upload the page or the screenshots anywhere else.

The page holds, after the PR link:

- **Where it ran**: one line. The checkout and commit, the build mode, the URL or port, the backend (mocked or live), the browser (the visible MCP window or the person's own Chrome), and the viewport.
- **Try it yourself**: how to bring up each variant in the open window (the marker or action order), which inputs do nothing in this build (a chip the scripted model ignores), and how to reset. Then what stops when this session ends (background servers it owns, the MCP's Chrome) and how to get back in without it: the URL to open in any Chrome, plus a one-line console snippet that sets the gate override.
- **Each variant**: its screenshot, the action that produced it, what was expected, and what was observed. Mark any mismatch plainly. A variant with no screenshot says why in its place.
- **Not shown, and why**: a variant only visible for a moment, an unreachable state, or anything that needs a real backend or credentials you didn't have.
- **Seen on the way, not this change's**: design drift or a pre-existing bug the run noticed. Give each a one-line cause, and keep them separate from the change's own results so nobody mixes them up.
- **Left running or changed**: which servers are running on which ports, which ones you restarted, each local-only edit, and the `git apply -R` / `git apply` commands for its patch. Include the screenshot folder under `.cppcho/evidence/`.
- **How to reproduce from scratch**: the shortest steps to start the app again later, including the gate override.
- **Skill revision**.

In the terminal, reply with the PR link, the Artifact link, one line per variant (as expected, mismatch, or not shown), and what is left running. The detail lives on the page.

Keep it to what the person needs to trust it and to redo it. A clear failure, such as an unmet credential or a variant that wouldn't appear, is a finished report too. Don't keep looking for a workaround.
