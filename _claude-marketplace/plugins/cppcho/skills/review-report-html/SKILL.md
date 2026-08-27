---
name: review-report-html
description: >-
  Write code-review findings up as a polished self-contained HTML report and
  publish it as a private Claude Artifact link: severity-grouped cards
  (High/Medium/Low/Cleanup), each with a plain-English problem, a numbered
  walkthrough (steps → failure), a red "current code" snippet and a green "fix
  sketch", severity + "Verified" badges, a clickable table of contents, and
  inline light/dark CSS with zero external dependencies. Use this whenever
  findings, bugs, or a review should become something a person reads rather
  than terminal output — "make an HTML review doc", "write these findings up
  as HTML", "turn the review into a shareable page", a report to hand to the
  team, a readable non-technical explanation of a set of bugs, or after a
  /code-review when they ask for a document to read or send. Reach for it even
  when they don't say "HTML": if they want the findings as a page, a doc, or a
  link, this is the skill.
---

# Review report → HTML

- Turn code-review findings into one page a reviewer understands **without
  reading the code**.
- Clarity is the whole value: plain-language problem, a concrete step-by-step
  walkthrough of the failure, the real buggy code, and a fix sketch.

## When there are no findings yet

- This skill formats findings that already exist — a `/code-review` run, a
  `ReportFindings` call, or the analysis in the current conversation.
- Nothing in context? Run the review first, or ask for the findings / diff.
  Don't invent findings — a report built from guesses is worse than no report.

## Output

- One `.html` file → published as a Claude Artifact → opened in the browser.
- The Artifact URL is the deliverable: a private page on claude.ai the user
  shares with a reviewer. The local file is just the source you publish from
  and re-publish after edits.
- File location: the session scratchpad with an obvious name (e.g.
  `<area>-code-review.html`), or the user's path if they named one.
- Keep the page self-contained — inline `<style>`, no external
  CSS/JS/fonts/CDN, no network requests. The artifact host's CSP blocks
  external requests, so anything remote silently doesn't load.
- Publish only through the `Artifact` tool, never to a public file host (org
  policy forbids those).
- No `Artifact` tool in this session? Don't stall — leave the file on disk,
  `open` it locally, and say the link isn't available here. A report the user
  can read beats no report.

### Publish and open

1. `Skill(artifact-design)` before writing the file — the Artifact contract
   requires it. The template already settles this report's design, so read it
   for calibration and don't redesign the page.
2. Lint the finished file: `python3 <this skill dir>/scripts/check_report.py
   <file>`. It catches
   the failures that look fine in the source and are only visible once
   rendered — a `<` in a snippet swallowing the rest of the line, leftover
   template scaffolding, contents links pointing at cards that aren't there.
   Fix the errors, then publish.
3. `Artifact` with `file_path` (the local `.html`), a one-sentence
   `description`, and `favicon: "🔍"`. The `<title>` in the file names it, so
   no `title` parameter is needed.
4. Open the returned URL: `open '<url>'`.
5. Tell the user the URL in one line, and that it is private until they share
   it. Mention the local file path only if they'll want to edit it.

### Re-publishing

- Same report, same session → call `Artifact` with the **same `file_path`**; it
  redeploys to the same URL.
- Report from an earlier session → pass that report's `url` so the link
  survives instead of a second artifact appearing (`action: "list"` finds the
  URL if it's lost).

## How to build it

- Start from `assets/template.html` — full CSS, page shell, legend, TOC
  scaffold, and two example cards (one full correctness finding, one cleanup).
- Copy it to the output path, fill the `__TITLE__` / `__SUBTITLE__` /
  `__FOOTER__` placeholders, then replace the example cards and TOC with the
  real findings.
- Keep `__TITLE__` a short, specific noun phrase — "Auth Handler Review", not
  "Code review of the authentication handler in PR #1234". It also names the
  browser tab and the artifact gallery card, where a sentence truncates to
  nothing useful.
- Reuse the template's classes rather than hand-rolling CSS, so every report
  looks like the same document.
- The template is an Artifact page *body*: no `<!doctype>` / `<html>` /
  `<head>` / `<body>` wrapper (the publisher adds one), and three palettes —
  light on `:root`, a `prefers-color-scheme` dark block, a
  `[data-theme="dark"]` block — so it follows the viewer's theme. Keep it
  that way.

### Order and grouping

- Severity headings in this order: **High**, **Medium**, **Low**, **Cleanup**.
- Within a group: most-severe / most-reachable first; correctness above
  cleanup.
- Omit a heading whose group is empty.
- Number findings continuously (1, 2, 3 …) across groups so the TOC and the
  card numbers line up.

### Anatomy of a finding card

Each card uses this shape (see the template for exact markup):

- **Heading**: `N. one-line title` + badges. Severity badge (`b-high` /
  `b-med` / `b-low` / `b-ok` for cleanup) and, only when you actually
  reproduced or traced it, a `b-ok` "Verified" badge. Don't claim Verified for
  something you reasoned about but didn't check.
- **Location**: `path/to/file.ext:line` in the `.loc` line. For PR findings,
  link it to the blob permalink at the head SHA (`blob/<sha>/path#L123`) — a
  reviewer without a checkout can then jump to the real line, and pinning the
  SHA keeps the link pointing at the code you reviewed.
- **The problem**: one or two jargon-free sentences — what goes wrong and why.
- **Walkthrough**: a numbered `<ol>` telling the concrete story: starting
  state → what the user (or a forged input) does → what the code does → the
  failure. End with a red `❌ Result:` line, and optionally a green
  `✓ Expected:` line. This is the part that makes a finding land, so make the
  example specific (real-looking HTML, values, filenames), not abstract.
- **Current code** (`pre.bad`, red): quote the actual offending line(s). Add a
  short `<span class="c">// why</span>` comment.
- **Fix sketch** (`pre.good`, green): the smallest change that addresses it,
  with added lines wrapped in `<span class="add">`. Label it as illustrative —
  it's a sketch, not a final patch. When the honest fix is large or a judgment
  call, say so instead of pretending a one-liner solves it.
- **Note** (optional): reachability, caveats, how it was verified, or links to
  related findings.

Cleanup cards usually need only the problem + a fix sketch (no walkthrough).

### Writing style

- Explain for a reader who trusts you but may not know this codebase. Prefer a
  concrete example over a general description.
- Be honest about severity and confidence. If a finding is contrived, low
  impact, or a judgment call, say so in the note rather than dressing it up.
- If some incoming findings are wrong or overlap, correct/merge them and note
  it, rather than transcribing them verbatim.

### Escaping code snippets

- Everything inside `<pre>` is still HTML — escape `<`, `>`, `&` as `&lt;`,
  `&gt;`, `&amp;`. An unescaped `<div>` simply vanishes from the rendered
  snippet, which bites hardest on HTML/JSX/generics-heavy code.
- Colour with the helper spans: `.c` (muted comment), `.add` (green, added),
  `.del` (red, removed) — these are the only tags that belong inside a
  snippet.
- `scripts/check_report.py` flags the ones you miss, which is why it's worth
  running before every publish.

## Example

**Input:** "write up the 3 bugs you found in the auth handler as an HTML doc I
can send to the team."

**Output:**

- `auth-handler-review.html` — title, legend, 3-item TOC, severity-grouped
  cards.
- Each card: the problem, a walkthrough ("1. A user logs in with email
  `A@x.com`… 2. … ❌ the session is issued for the wrong account"), the real
  buggy line in red, a green fix sketch.
- Published as an Artifact and opened in the browser.
- Reported back in one line: the URL, private until they share it.
