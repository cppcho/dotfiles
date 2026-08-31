#!/usr/bin/env python3
"""Lint a review report before publishing it as an Artifact.

Catches the failures that are invisible in the source but wreck the rendered
page: code swallowed by unescaped tags inside <pre>, template scaffolding left
behind, TOC links pointing at cards that don't exist, anything the Artifact
CSP would block, walls of prose nobody reads, fix sketches that just re-quote
the buggy code, and findings that lost the tick box the fix-prompt bar
selects them with.

It also holds the page to its audience — a reader who never opened the code:
a missing orientation block, file references the reader can't click through to
GitHub, and identifiers used in prose that the glossary never defines.

Usage: python3 check_report.py <report.html>
Exit 0 = clean (warnings only), 1 = errors found.
"""

import difflib
import html
import re
import sys

# A reviewer scans a page of findings. Past roughly 250 characters a block stops
# being read; past 400 it may as well not be there.
PROSE_WARN = 250
PROSE_ERROR = 400
STEP_ERROR = 200

PLACEHOLDERS = ("__TITLE__", "__SUBTITLE__", "__FOOTER__")

# Text that only exists in the template's example cards.
SCAFFOLD = (
    "One-line title of the bug",
    "path/to/file.ext",
    "Short title of finding",
    "Duplicated / redundant thing",
    "Starting state, in concrete terms",
    "What goes wrong, in one sentence",
    "Optional: a part of the problem",
    "The feature in plain terms",
    "The intent of the diff under review",
    "What it holds, in plain words",
    "Who calls it, and what it answers",
)

WRAPPER = re.compile(r"<!doctype|<html\b|</html>|<head\b|</head>|<body\b|</body>", re.I)
# Inline colour helpers are the only markup that belongs inside a snippet.
ALLOWED_IN_PRE = re.compile(r"</?span\b[^>]*>")

# `foo/bar.ext:123`, `bar.ext:120–128` — what a reader wants to click.
FILE_REF = re.compile(r"\b[\w.\-/]+\.[A-Za-z][\w]{0,7}:\d+(?:\s*[–-]\s*\d+)?")
# Identifiers that read as code, not English: snake_case, CamelCase, dotted.
JARGON = re.compile(r"^[A-Za-z_][\w]*(?:\.[A-Za-z_][\w]*)*$")
JARGON_LIST = 8


COMMENT = re.compile(r"<!--.*?-->", re.S)
PRE = re.compile(r"<pre\b.*?</pre>", re.S)
STYLE = re.compile(r"<style\b.*?</style>", re.S)
SCRIPT = re.compile(r"<script\b.*?</script>", re.S)
ANCHOR = re.compile(r"<a\b[^>]*>.*?</a>", re.S)
LISTS = re.compile(r"<(ul|ol|dl)\b.*?</\1>", re.S)
WIPE = re.compile(r"[^\n]")


def line_of(text, offset):
    return text.count("\n", 0, offset) + 1


def blank(text, pattern):
    """Blank out matches, leaving every offset and line number intact."""
    return pattern.sub(lambda m: WIPE.sub(" ", m.group(0)), text)


def plain(fragment):
    """Rendered text of an HTML fragment, whitespace collapsed."""
    return re.sub(r"\s+", " ", html.unescape(re.sub(r"<[^>]+>", "", fragment))).strip()


def check(path):
    text = open(path, encoding="utf-8").read()
    errors, warnings = [], []

    def err(offset, msg):
        errors.append(f"{path}:{line_of(text, offset)}: {msg}")

    def warn(offset, msg):
        warnings.append(f"{path}:{line_of(text, offset)}: {msg}")

    for m in WRAPPER.finditer(text):
        err(m.start(), f"{m.group(0)} — publish the page body only; the Artifact publisher adds the wrapper")

    if "<title>" not in text[:8192]:
        errors.append(f"{path}: no <title> in the first 8KB — the artifact would fall back to the filename")

    for name in PLACEHOLDERS:
        i = text.find(name)
        if i != -1:
            err(i, f"{name} never filled in")

    for phrase in SCAFFOLD:
        i = text.find(phrase)
        if i != -1:
            err(i, f"template example content left in the report: {phrase!r}")

    # Unescaped markup inside a snippet: the browser eats it, so the reviewer
    # silently reads code with lines missing.
    for block in re.finditer(r"<pre\b[^>]*>(.*?)</pre>", text, re.S):
        stripped = ALLOWED_IN_PRE.sub("", block.group(1))
        hit = stripped.find("<")
        if hit != -1:
            near = stripped[hit:hit + 40].replace("\n", " ")
            err(block.start(1), f"unescaped '<' inside <pre> — escape it as &lt;, near: {near!r}")

    # The CSP blocks external requests, so a remote asset just doesn't load.
    # Inline <script> is fine and the triage bar needs it — only a fetched one
    # is a problem.
    for pat, what in (
        (r"<link\b", "external <link> stylesheet"),
        (r"<script\b[^>]*\bsrc\s*=", "<script src=…>"),
        (r"url\(\s*['\"]?https?:", "CSS url() to a remote host"),
        (r"<(?:img|iframe|video|audio|source)\b[^>]*\bsrc\s*=\s*['\"](?:https?:|//)", "remote asset"),
    ):
        for m in re.finditer(pat, text, re.I):
            err(m.start(), f"{what} — the artifact CSP blocks it; inline it instead")

    # Walls of prose. The report's whole job is to be skimmable, so an
    # unbroken block is a defect even though it renders fine. Lists don't count
    # toward it — breaking a point into bullets is the remedy, and each <li> is
    # capped on its own below.
    for m in re.finditer(r'<div class="row"[^>]*>(.*?)</div>', text, re.S):
        n = len(plain(LISTS.sub(" ", m.group(1))))
        if n > PROSE_ERROR:
            err(m.start(1), f"{n}-character paragraph — split it into short bullets (<{PROSE_WARN})")
        elif n > PROSE_WARN:
            warn(m.start(1), f"{n}-character paragraph — tighten it or break it into bullets")

    for m in re.finditer(r"<li[^>]*>(.*?)</li>", text, re.S):
        n = len(plain(m.group(1)))
        if n > STEP_ERROR:
            err(m.start(1), f"{n}-character list item — a walkthrough step should read in one line")

    # A fix sketch that re-quotes the buggy code teaches the reader nothing:
    # they have to diff two near-identical blocks by eye to find the change.
    for m in re.finditer(
        r'<pre class="bad">(.*?)</pre>.*?<pre class="good">(.*?)</pre>', text, re.S
    ):
        bad, good = plain(m.group(1)), plain(m.group(2))
        ratio = difflib.SequenceMatcher(None, bad, good).ratio()
        if ratio >= 0.7 and len(good) > 60:
            warn(
                m.start(2),
                f"fix sketch is {int(ratio * 100)}% the same text as the current code — "
                "show only the lines that change, eliding the rest with …",
            )

    ids = {m.group(1) for m in re.finditer(r'\bid\s*=\s*"([^"]+)"', text)}
    for m in re.finditer(r'href\s*=\s*"#([^"]+)"', text):
        if m.group(1) not in ids:
            err(m.start(), f'TOC link #{m.group(1)} points at no card')

    linked = {m.group(1) for m in re.finditer(r'href\s*=\s*"#([^"]+)"', text)}
    for m in re.finditer(r'<div class="card" id="([^"]+)"', text):
        if m.group(1) not in linked and m.group(1) != "orientation":
            warn(m.start(), f"card #{m.group(1)} is missing from the contents list")

    # Triage → hand-off. The tick boxes and the bar are what let a reader say
    # which findings to fix and paste them into a coding agent; a card that
    # lost its box just silently can't be picked.
    if 'id="fixbar"' not in text:
        errors.append(
            f"{path}: no triage bar — keep the template's #fixbar block and the "
            "<script> under it, that's how a reader hands findings to a coding agent"
        )
    elif not SCRIPT.search(text):
        errors.append(
            f"{path}: the triage bar's inline <script> is gone — the tick boxes and "
            "the Copy fix prompt button do nothing without it"
        )
    for m in re.finditer(
        r'<div class="card" id="([^"]+)"(.*?)(?=<div class="card"|<h2\b|\Z)', text, re.S
    ):
        if m.group(1) != "orientation" and 'class="pickbox"' not in m.group(2):
            err(
                m.start(),
                f'card #{m.group(1)} has no tick box — copy the <label class="num"> '
                "heading from the template so it can be selected for a fix prompt",
            )

    # Everything below is about the audience: a reader who never opened the code.
    prose = blank(blank(blank(blank(text, COMMENT), PRE), STYLE), SCRIPT)

    orient = text.find('id="orientation"')
    if orient == -1:
        errors.append(
            f"{path}: no orientation block — the reader has not read the code. Say what "
            "it does, what the change does, and define the terms the findings use."
        )
        glossary, elsewhere = "", prose
    else:
        # Bound the block to the next heading or card. Running to end-of-file
        # would make the whole page count as "defined" and silently disable the
        # jargon check below.
        after = [p for p in (text.find("<h2", orient), text.find('<div class="card"', orient)) if p != -1]
        end = min(after) if after else orient
        glossary = plain(text[orient:end])
        elsewhere = prose[:orient] + WIPE.sub(" ", prose[orient:end]) + prose[end:]

    # A file reference the reader can't click is a dead end for anyone without a
    # checkout. Once one permalink resolved, the rest are oversights.
    has_base = re.search(r'href\s*=\s*"https://github\.com/[^"]+/blob/', text)
    for m in FILE_REF.finditer(blank(prose, ANCHOR)):
        report = err if has_base else warn
        report(
            m.start(),
            f"file reference {m.group(0)!r} isn't a link — point it at the GitHub "
            "permalink for the SHA you reviewed",
        )

    # Jargon the page uses but never explains: the reader meets it cold.
    undefined = {}
    for m in re.finditer(r"<code>(.*?)</code>", elsewhere, re.S):
        term = plain(m.group(1))
        if FILE_REF.search(term) or not JARGON.match(term):
            continue
        if "_" not in term and "." not in term and not re.search(r"[a-z][A-Z]", term):
            continue
        if term not in glossary:
            undefined.setdefault(term, m.start(1))
    if undefined:
        terms = sorted(undefined)
        shown = ", ".join(terms[:JARGON_LIST]) + (" …" if len(terms) > JARGON_LIST else "")
        warn(
            min(undefined.values()),
            f"{len(terms)} identifier(s) used in prose that the orientation glossary "
            f"never defines: {shown}",
        )

    # The number sits inside a <label> with the tick box, so skip any tags
    # between the class and the digits.
    nums = [
        (m.start(), m.group(1))
        for m in re.finditer(r'class="num"[^>]*>(?:\s*<[^>]+>)*\s*(\d+)\.', text)
    ]
    for pos, (offset, n) in enumerate(nums, start=1):
        if int(n) != pos:
            warn(offset, f"finding numbered {n} where {pos} was expected — TOC and cards will disagree")
            break

    return errors, warnings


def main():
    if len(sys.argv) != 2:
        print(__doc__.strip())
        return 2
    errors, warnings = check(sys.argv[1])
    for line in errors + warnings:
        print(line)
    if errors:
        print(f"\n{len(errors)} error(s), {len(warnings)} warning(s) — fix the errors before publishing.")
        return 1
    print(f"clean ({len(warnings)} warning(s))" if warnings else "clean")
    return 0


if __name__ == "__main__":
    sys.exit(main())
