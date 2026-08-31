---
name: review-report-html
description: >-
  Write code-review findings up as a polished self-contained HTML report and
  publish it as a private Claude Artifact link: an orientation block that
  explains the code to a reader who never opened it, severity-grouped cards
  (High/Medium/Low/Cleanup), each with a plain-English problem, a numbered
  walkthrough (steps → failure), a red "current code" snippet and a green "fix
  sketch", every file reference linked to its GitHub permalink, severity +
  "Verified" badges, a clickable table of contents, a tick box on every finding
  plus a "Copy fix prompt" button that turns the ones the reader picked into a
  prompt to paste into a coding agent, and inline light/dark CSS
  with zero external dependencies. Use this whenever
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
  reading the code**, and can act on without retyping any of it.
- Clarity is the whole value: an orientation block so the page reads cold, a
  plain-language problem, a concrete step-by-step walkthrough of the failure,
  the real buggy code, and a fix sketch.
- Every file reference links to GitHub, so a reader with no checkout can still
  reach the line under discussion.
- Reading ends in a decision: the reader ticks the findings worth fixing and
  copies a prompt for a coding agent, so the page is a triage tool, not just a
  document.

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
- Keep the page self-contained — inline `<style>` and the template's inline
  `<script>`, no external CSS/JS/fonts/CDN, no network requests. The artifact
  host's CSP blocks external requests, so anything remote silently doesn't
  load; inline script runs fine, and the triage bar needs it.
- Publish only through the `Artifact` tool, never to a public file host (org
  policy forbids those).
- No `Artifact` tool in this session? Don't stall — leave the file on disk,
  `open` it locally, and say the link isn't available here. A report the user
  can read beats no report.

### Publish and open

1. `Skill(artifact-design)` before writing the file — the Artifact contract
   requires it of every publish. Read it for calibration only: the template has
   already made this report's design decisions, so nothing there should change
   the page.
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
  `__FOOTER__` placeholders, write the orientation card, then replace the
  example cards and TOC with the real findings.
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

### Triage and hand-off

Reading a report is not the point — deciding what to fix is. The template gives
every finding card a tick box in its number, and a sticky bar at the foot of the
page turns whatever the reader ticked into a prompt they paste into a coding
agent. It is the shortest path from "these three are worth fixing" to the fix.

- The bar's `<script>` builds the prompt by **reading the cards out of the
  page** at click time. So there is nothing to author: no per-finding prompt
  text, no JSON blob, no `data-` attributes duplicating the card. Copy the
  `#fixbar` block and its script across unchanged and leave them alone.
- Because the prompt *is* the card, a thin card makes a thin prompt. The
  location, the problem, the walkthrough, the real code, the fix sketch and the
  note all land in it, and so does the orientation block — that's the context an
  agent starting cold needs. A card that reads well is a prompt that works.
- Every finding card needs the tick box, or it can't be picked and quietly
  drops out of the hand-off. `scripts/check_report.py` errors on a card that
  lost it, and on a missing bar or script.
- Tick state is remembered per reader in `localStorage`, so triage can span two
  sittings and each reader keeps their own picks.
- The clipboard can be blocked in a sandboxed viewer; the script falls back to
  showing the prompt in a text box the reader copies by hand. Don't strip that
  path — on some viewers it's the only one that works.

### Write for someone who has not read the code

The reader knows the product but has never opened these files. They are reading
this page **instead of** the diff — a finding they can't follow without a
checkout is a finding they skip.

- **Orientation block, always** — the template has it, right after the legend:
  what this code does, what the change under review does, and a glossary of
  the identifiers the findings lean on. Three or four entries, one line each,
  covering only terms that actually appear below.
- **Define jargon on first use.** A field, RPC, or framework name used in prose
  is either in the glossary or explained in a clause where it appears.
- **State the rule the finding turns on.** When a bug depends on behaviour the
  reader has no reason to know — CEL reads an unset message as empty,
  grpc-federation returns a zero value for an ignored call, this driver retries
  on a nil error — put that rule in the card in one line. Without it the
  walkthrough is an assertion, not an argument.
- **Say what the code is meant to do before what goes wrong.** The problem's
  first clause is the intent; the second is the break.
- **Land the symptom in the reader's world**: a wrong number on a screen, a
  rejected request, a row silently dropped — not "the guard passes".
- No unexplained shorthand: ticket ids, team nicknames, config keys (`if:`,
  `by:`) without a word on what they are.

### Link every file reference to GitHub

A reader with no checkout can't act on `entity.proto:750`. Every file reference
on the page is a link — the `.loc` line, and every mention inside a problem,
walkthrough step, snippet caption, or note.

1. Resolve the base once, before writing any card:
   - repo — `git remote get-url origin`, normalised to `<owner>/<repo>`
     (`git@github.com:acme/api.git` → `acme/api`); `gh repo view --json
     nameWithOwner -q .nameWithOwner` also works when the network is up
   - SHA — `gh pr view <n> --json headRefOid -q .headRefOid` for a PR,
     otherwise `git rev-parse HEAD`
   - base — `https://github.com/<owner>/<repo>/blob/<sha>/`
   - paths are repo-relative: check with `git rev-parse --show-prefix` if you
     are working below the repo root
2. Shape: `<a href="<base>path/to/file.ext#L123">path/to/file.ext:123</a>`, and
   `#L120-L128` for a range. Always pin the SHA — `blob/main` drifts and the
   line numbers stop matching the code you reviewed.
3. Inline mentions get the same treatment, keeping the monospace:
   `<a href="<base>…#L2252"><code>billing.proto:2252</code></a>`.
4. A path outside the repo under review — a vendored dependency, a code
   generator's template — links to *its* repo at the version you read, and
   names that version in the text.
5. Never link inside a `<pre>`; the location line above the snippet carries it.
6. No permalink is possible when the commit isn't pushed (`git branch -r
   --contains HEAD` comes back empty). Then link `blob/<branch>/path#L123` if
   the branch is on the remote, and if nothing is pushed leave the references
   as plain text and say so once in the footer. Never invent a SHA.

`scripts/check_report.py` flags any `path.ext:123` in prose that isn't inside a
link, and errors on it once the page contains at least one GitHub blob link —
if one reference resolved, the rest are oversights.

### Order and grouping

- Severity headings in this order: **High**, **Medium**, **Low**, **Cleanup**.
- Within a group: most-severe / most-reachable first; correctness above
  cleanup.
- Omit a heading whose group is empty.
- Number findings continuously (1, 2, 3 …) across groups so the TOC and the
  card numbers line up.
- Severity order wins over the order the findings arrived in — the page is for
  a reader triaging, not a transcript of the review. The exception is numbers
  that have already been discussed: if the findings came in numbered and the
  user has been talking about "finding 3", keep their numbers, reorder the
  cards around them, and say so in the lede.

### Anatomy of a finding card

Each card uses this shape (see the template for exact markup):

- **Heading**: `N. one-line title` + badges, with the number a
  `<label class="num">` wrapping the triage tick box — keep that shape so the
  finding can be selected for a fix prompt. Severity badge (`b-high` /
  `b-med` / `b-low` / `b-ok` for cleanup) and a `b-ok` "Verified" badge when
  the claim is settled rather than argued — you ran it, or the files in front
  of you prove it outright. A finding resting on how a framework or runtime
  behaves is not Verified until you checked that behaviour; leave the badge off
  and say in the note what would settle it.
- **Location**: `path/to/file.ext:line` in the `.loc` line, always a GitHub
  permalink — see *Link every file reference to GitHub* above.
- **The problem**: one or two jargon-free sentences — what the code is meant to
  do, then what goes wrong and why it matters.
- **Walkthrough**: a numbered `<ol>` telling the concrete story: starting
  state → what the user (or a forged input) does → what the code does → the
  failure. End with a red `❌ Result:` line, and optionally a green
  `✓ Expected:` line. This is the part that makes a finding land, so make the
  example specific (real-looking HTML, values, filenames), not abstract.
- **Current code** (`pre.bad`, red): quote the actual offending line(s). Add a
  short `<span class="c">// why</span>` comment.
- **Fix sketch** (`pre.good`, green): only the lines that change, wrapped in
  `<span class="add">`, with `…` where you cut the unchanged body. It's a
  sketch, not a final patch — and when the honest fix is large or a judgment
  call, say so instead of pretending a one-liner solves it. If the language
  can't express the fix (no `sum` in this CEL build, no such API yet), write
  labelled pseudo-code rather than valid-looking code that wouldn't compile.
- **Note** (optional): reachability, caveats, how it was verified, or links to
  related findings.

Cleanup cards usually need only the problem + a fix sketch (no walkthrough).

### Keep it skimmable

The page is read by someone scanning ten findings, not studying one. A block
of prose gets skipped, and a skipped finding may as well not be in the report.

- **The problem**: one or two short sentences, ~40 words. More than that turns
  into bullets — never a paragraph.
- **Walkthrough steps**: one line each. The story lives in the sequence of
  steps, so a step that runs to three lines is hiding the sequence.
- **Notes**: a single line. If the caveat needs a paragraph, it's a finding of
  its own or it doesn't belong.
- Nothing on the page should exceed ~250 characters of unbroken prose. Use
  `<ul>` inside a `.row` when a point has parts.
- **The fix sketch shows the difference, not the function.** Quote only the
  lines that change plus the minimum anchor around them, and elide the rest
  with `…`. When the green block reads like the red block, the reader has to
  diff them by eye and the sketch has taught them nothing.

`scripts/check_report.py` enforces both — it errors on paragraphs over 400
characters and warns when a fix sketch is ≥70% the same text as the code above
it.

### Writing style

- Prefer a concrete example over a general description.
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
  buggy line in red, a green fix sketch, and a tick box in its number.
- A bar at the foot: tick findings 1 and 3, hit **Copy fix prompt**, paste into
  a coding agent to get those two fixed.
- Published as an Artifact and opened in the browser.
- Reported back in one line: the URL, private until they share it.
