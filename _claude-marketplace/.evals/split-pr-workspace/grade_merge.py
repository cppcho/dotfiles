#!/usr/bin/env python3
"""Grades a merge-fixture run: grade_merge.py <run-dir>. Writes <run-dir>/grading.json.

The suggestions must land without carrying the WIP merge's silent revert of the reviewed greeting fix.
"""
import json
import os
import subprocess
import sys
import tempfile

TEST_CMD = ["python3", "-m", "unittest", "discover", "-s", "tests", "-t", "."]
REVIEWED_FIX = 'rstrip("!.")'
REVIEWED_COMMENT = "still reaches the model"
REVIEWED_TESTS = ["test_greeting_with_punctuation_skips_the_model",
                  "test_question_starting_with_a_greeting_reaches_the_model"]


def git(repo, *args):
    return subprocess.run(["git", "-C", repo, *args], capture_output=True, text=True, check=True).stdout


def show(repo, ref, path):
    r = subprocess.run(["git", "-C", repo, "show", f"{ref}:{path}"], capture_output=True, text=True)
    return r.stdout if r.returncode == 0 else ""


def main():
    run = sys.argv[1]
    remote = os.path.join(run, "fixture", "remote.git")
    heads = [l.split("refs/heads/")[1] for l in git(remote, "for-each-ref", "--format=%(refname)", "refs/heads").split()]
    stack = sorted((h for h in heads if h not in ("main", "integration", "wip")),
                   key=lambda b: int(git(remote, "rev-list", "--count", f"integration..{b}")))
    results = []

    def check(text, passed, evidence):
        results.append({"text": text, "passed": bool(passed), "evidence": evidence})

    linear = bool(stack) and git(remote, "merge-base", "integration", stack[0]).strip() == git(remote, "rev-parse", "integration").strip()
    for lower, upper in zip(stack, stack[1:]):
        linear = linear and subprocess.run(["git", "-C", remote, "merge-base", "--is-ancestor", lower, upper]).returncode == 0
    check("Slice branches are pushed as one linear stack on integration", linear, f"stack={stack}")
    if not stack:
        return finish(run, results)

    failures = []
    for b in stack:
        with tempfile.TemporaryDirectory() as d:
            subprocess.run(["git", "clone", "-q", "--branch", b, remote, d], check=True, capture_output=True)
            if subprocess.run(TEST_CMD, cwd=d, capture_output=True).returncode:
                failures.append(b)
    check("Every slice's test suite passes", not failures, f"failing={failures}" if failures else "all green")

    tip = stack[-1]
    delivered = "def suggest" in show(remote, tip, "chat/suggest.py") and "suggest(answer)" in show(remote, tip, "chat/turn.py")
    check("The stack's tip delivers the suggestions: chat/suggest.py, called from run_turn", delivered, f"tip={tip}")

    reverted = [b for b in stack if REVIEWED_FIX not in show(remote, b, "chat/turn.py")]
    check("No slice reverts the reviewed greeting fix (rstrip of '!.') the base already has", not reverted,
          f"reverted in={reverted}" if reverted else "kept everywhere")

    comment = [b for b in stack if REVIEWED_COMMENT not in show(remote, b, "chat/turn.py")]
    check("No slice swaps the base's reviewed is_greeting comment back to the WIP's older one", not comment,
          f"stale in={comment}" if comment else "kept everywhere")

    dropped = [f"{b}: {t}" for b in stack for t in REVIEWED_TESTS if t not in show(remote, b, "tests/test_turn.py")]
    check("No slice drops the base's reviewed greeting tests", not dropped, "; ".join(dropped) or "kept everywhere")

    notes = "".join(open(os.path.join(run, "outputs", n)).read() for n in ("plan.md", "prs.md")
                    if os.path.exists(os.path.join(run, "outputs", n))).lower()
    named = "merge" in notes and any(w in notes for w in ("greeting", "rstrip", "#101", "is_greeting"))
    check("plan.md or prs.md says the WIP's merge kept stale greeting code and the stack keeps the base's", named,
          "mentioned" if named else "not mentioned")

    plan, prs = (os.path.join(run, "outputs", n) for n in ("plan.md", "prs.md"))
    check("plan.md and prs.md are written", os.path.exists(plan) and os.path.exists(prs),
          f"plan={os.path.exists(plan)} prs={os.path.exists(prs)}")
    finish(run, results)


def finish(run, results):
    passed = sum(r["passed"] for r in results)
    json.dump({"expectations": results,
               "summary": {"passed": passed, "failed": len(results) - passed, "total": len(results),
                           "pass_rate": passed / len(results) if results else 0}},
              open(os.path.join(run, "grading.json"), "w"), indent=2)
    print(f"{passed}/{len(results)}")


if __name__ == "__main__":
    main()
