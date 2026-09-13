#!/usr/bin/env python3
"""Score the medium-vs-high experiment on one question only.

Did the review report the fail-open defect: `r.URL.Query()` discards malformed
pairs, so `?q=bil%ling` drops `q` entirely and the filter vanishes, serving every
row with a 200 to a caller who asked to narrow the list?

A finding counts only if it is about the query string being silently dropped or
unvalidated. Findings about calling Query() twice, about lowercasing the query
once instead of per item, or about the format width are different findings and do
not count -- iteration 2's run reported exactly those and still shipped the
defect. Keyword matching decides nothing on its own: every candidate is printed
in full so the call can be checked by eye.
"""

import os
import re
import sys

EXP = sys.argv[1] if len(sys.argv) > 1 else (
    "/Users/cppcho/dotfiles/_claude-marketplace/.evals/implement-workspace/"
    "experiment-effort-level"
)

# The defect is about losing the parameter, not about how it is used.
HIT = re.compile(
    r"(fail(s|ing)?[ -]open"
    r"|silently (drop|discard|ignore|swallow)"
    r"|drop(s|ped|ping)? (the )?(malformed|invalid|unparseable|bad|the q\b)"
    r"|ParseQuery"
    r"|(malformed|invalid|unparseable|bad|escaped|percent)[^\n.]{0,40}"
    r"(quer(y|ystring)|escape|param)"
    r"|url\.?Query\(\)[^\n.]{0,60}(error|err\b|ignor|discard|drop)"
    r"|returns (all|every) (row|item)[^\n.]{0,40}(instead|rather|when)"
    r"|no error[^\n.]{0,40}quer)",
    re.I)
# Findings that touch the same lines but are a different defect.
NEAR_MISS = re.compile(
    r"(twice|two (calls|parses)|duplicate[^\n.]{0,20}Query"
    r"|lowercas|ToLower[^\n.]{0,30}(per|each|loop)"
    r"|%0\d*d|format width)", re.I)


def split_findings(text):
    """Split a findings.md into numbered finding blocks."""
    parts = re.split(r"\n(?=\s{0,3}(?:\d+[.)]\s|[-*]\s*\*\*|###\s))", text)
    return [p.strip() for p in parts if p.strip()]


rows = []
for lvl in ("medium", "high"):
    for n in (1, 2, 3):
        d = os.path.join(EXP, f"{lvl}-{n}")
        f = os.path.join(d, "outputs", "findings.md")
        if not os.path.exists(f):
            rows.append((lvl, n, None, [], []))
            continue
        text = open(f, encoding="utf-8", errors="replace").read()
        blocks = split_findings(text)
        hits = [b for b in blocks if HIT.search(b) and not
                (NEAR_MISS.search(b) and not HIT.search(
                    NEAR_MISS.sub("", b)))]
        nears = [b for b in blocks if NEAR_MISS.search(b) and b not in hits]
        rows.append((lvl, n, len(blocks), hits, nears))

print("=" * 78)
print("Did the review report the fail-open query defect?")
print("=" * 78)
tally = {"medium": 0, "high": 0}
seen = {"medium": 0, "high": 0}
for lvl, n, nblocks, hits, nears in rows:
    if nblocks is None:
        print(f"\n{lvl}-{n}: (no findings.md yet)")
        continue
    seen[lvl] += 1
    caught = bool(hits)
    tally[lvl] += 1 if caught else 0
    print(f"\n{lvl}-{n}: {'CAUGHT' if caught else 'MISSED'}  "
          f"({nblocks} blocks parsed)")
    for h in hits:
        print("   HIT  | " + h.replace("\n", "\n        | ")[:500])
    for nm in nears[:2]:
        print("   near | " + nm.replace("\n", "\n        | ")[:220])

print("\n" + "=" * 78)
for lvl in ("medium", "high"):
    if seen[lvl]:
        print(f"{lvl:7s}: {tally[lvl]}/{seen[lvl]} caught the fail-open defect")
print("=" * 78)
print("\nNote: these runs were driven by Sonnet to make six parallel reviews")
print("affordable; the iteration-1/2 implement runs inherited Opus. The")
print("medium-vs-high contrast is internally valid, but neither arm is")
print("directly comparable to iteration 1's catch.")
