#!/usr/bin/env python3
"""Lint a review report before publishing it as an Artifact.

Catches the failures that are invisible in the source but wreck the rendered
page: code swallowed by unescaped tags inside <pre>, template scaffolding left
behind, TOC links pointing at cards that don't exist, anything the Artifact
CSP would block, walls of prose nobody reads, and fix sketches that just
re-quote the buggy code.

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
)

WRAPPER = re.compile(r"<!doctype|<html\b|</html>|<head\b|</head>|<body\b|</body>", re.I)
# Inline colour helpers are the only markup that belongs inside a snippet.
ALLOWED_IN_PRE = re.compile(r"</?span\b[^>]*>")


def line_of(text, offset):
    return text.count("\n", 0, offset) + 1


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
    for pat, what in (
        (r"<link\b", "external <link> stylesheet"),
        (r"<script\b", "<script> tag"),
        (r"url\(\s*['\"]?https?:", "CSS url() to a remote host"),
        (r"<(?:img|iframe|video|audio|source)\b[^>]*\bsrc\s*=\s*['\"](?:https?:|//)", "remote asset"),
    ):
        for m in re.finditer(pat, text, re.I):
            err(m.start(), f"{what} — the artifact CSP blocks it; inline it instead")

    # Walls of prose. The report's whole job is to be skimmable, so an
    # unbroken block is a defect even though it renders fine.
    for m in re.finditer(r'<div class="row"[^>]*>(.*?)</div>', text, re.S):
        n = len(plain(m.group(1)))
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
        if m.group(1) not in linked:
            warn(m.start(), f"card #{m.group(1)} is missing from the contents list")

    nums = [(m.start(), m.group(1)) for m in re.finditer(r'<span class="num">(\d+)\.', text)]
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
