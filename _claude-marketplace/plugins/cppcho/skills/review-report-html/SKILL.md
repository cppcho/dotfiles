---
name: review-report-html
description: >-
  Render code-review findings into a polished, self-contained HTML report:
  severity-grouped cards (High/Medium/Low/Cleanup), each with a plain-English
  problem, a numbered walkthrough (steps → failure), a red "current code"
  snippet and a green "fix sketch" snippet, severity + "Verified" badges, a
  clickable table of contents, and inline light/dark CSS with zero external
  dependencies. Use this whenever the user wants review findings, bugs, or a
  code review written up as an HTML doc / report / page — e.g. "make an HTML
  review doc", "write these findings up as HTML", "turn the review into a
  shareable page", or after a /code-review when they ask for a document to
  read or hand off. Also use it when someone wants a readable, non-technical
  explanation of a set of bugs with concrete examples.
---

# Review report → HTML

Turn a set of code-review findings into one self-contained HTML file a
reviewer can open in a browser and understand without reading the code. The
value is clarity: every finding is explained in plain language, shown with a
concrete step-by-step walkthrough of how it fails, and paired with the real
buggy code and a fix sketch.

## When there are no findings yet

This skill formats findings that already exist — from a `/code-review` run,
a `ReportFindings` call, or the analysis in the current conversation. If there
are no findings in context, don't invent them: run the review first (or ask
the user for the findings / diff), then format the result. A report built from
guesses is worse than no report.

## Output

Write ONE `.html` file. Default location: the repo working tree with an
obvious throwaway name (e.g. `<area>-code-review.html`), or the user's chosen
path. Confirm the path if it's ambiguous. Tell the user it's an untracked
artifact they can delete, and how to open it (`open <file>`).

The file MUST be self-contained: inline `<style>`, no external CSS/JS/fonts/CDN
links, no network requests. It should render offline and adapt to light/dark
via `prefers-color-scheme`. **Never upload it anywhere** (org policy forbids
public file hosts); it is a local artifact only.

## How to build it

Start from `assets/template.html` — it holds the full CSS, the page shell, a
legend, a table-of-contents scaffold, and two example cards (one full
correctness finding, one cleanup finding). Copy it to the output path, replace
the `__TITLE__` / `__SUBTITLE__` / `__FOOTER__` placeholders, then replace the
example cards and TOC with the real findings. Don't hand-roll new CSS — reuse
the template's classes so every report looks consistent.

### Order and grouping

Group findings under severity headings in this order: **High**, **Medium**,
**Low**, **Cleanup**. Within a group, most-severe / most-reachable first.
Correctness bugs always rank above cleanup. Omit a heading if that group is
empty. Number findings continuously (1, 2, 3 …) across all groups so the TOC
and card numbers line up.

### Anatomy of a finding card

Each card uses this shape (see the template for exact markup):

- **Heading**: `N. one-line title` + badges. Severity badge (`b-high` /
  `b-med` / `b-low` / `b-ok` for cleanup) and, only when you actually
  reproduced or traced it, a `b-ok` "Verified" badge. Don't claim Verified for
  something you reasoned about but didn't check.
- **Location**: `path/to/file.ext:line` in the `.loc` line.
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

Everything inside `<pre>` is HTML — escape `<`, `>`, and `&` as `&lt;`,
`&gt;`, `&amp;`. This matters most for HTML/JSX/generic-heavy code; an
unescaped `<div>` will vanish from the rendered snippet. Use the helper
`<span>` classes for coloring: `.c` (muted comment), `.add` (green, added),
`.del` (red, removed).

## Example

**Input:** the user says "write up the 3 bugs you found in the auth handler as
an HTML doc I can send to the team."

**Output:** a file `auth-handler-review.html` with a title, legend, a 3-item
TOC, severity-grouped cards — each with the problem, a walkthrough (e.g. "1. A
user logs in with email `A@x.com`… 2. … ❌ the session is issued for the wrong
account"), the real buggy line in red, and a green fix sketch — and a footer
noting it's a local artifact. Then a one-line message telling the user the
path and `open` command.
