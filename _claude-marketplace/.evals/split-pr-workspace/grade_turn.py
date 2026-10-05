#!/usr/bin/env python3
"""Grades a turn-fixture run: grade_turn.py <run-dir> thin|subset. Writes <run-dir>/grading.json.

thin   — thin-path-turn: the first two slices of a fresh plan.
subset — subset-approval-turn: slices 1, 3 and 4 of plan_v1, with 2 (the off-topic refusal) left out.
"""
import json
import os
import subprocess
import sys
import tempfile

TEST_CMD = ["python3", "-m", "unittest", "discover", "-s", "tests", "-t", "."]
# Each behaviour on top of the thin path, and a marker only its code carries.
BEHAVIOURS = {
    "off-topic refusal": "off_topic",
    "answer clipping": "MAX_ANSWER_CHARS",
    "citation retry": "has_citation",
    "suggestions": "def suggest",
    "figures metric": "count_figures",
    "debug override": "system_prompt",
}
DIAGNOSTICS = {"figures metric", "debug override"}
POLICY_FNS = ["off_topic", "clip", "has_citation"]


def git(repo, *args):
    return subprocess.run(["git", "-C", repo, *args], capture_output=True, text=True, check=True).stdout


def behaviours(tree):
    code = "\n".join(body for path, body in tree.items() if path.startswith("chat/"))
    return {name for name, marker in BEHAVIOURS.items() if marker in code}


def main():
    run, mode = sys.argv[1], sys.argv[2]
    remote = os.path.join(run, "fixture", "remote.git")
    heads = [l.split("refs/heads/")[1] for l in git(remote, "for-each-ref", "--format=%(refname)", "refs/heads").split()]
    stack = sorted((h for h in heads if h not in ("main", "integration", "wip")),
                   key=lambda b: int(git(remote, "rev-list", "--count", f"integration..{b}")))
    results = []

    def check(text, passed, evidence):
        results.append({"text": text, "passed": bool(passed), "evidence": evidence})

    want = 2 if mode == "thin" else 3
    linear = len(stack) == want and git(remote, "merge-base", "integration", stack[0]).strip() == git(remote, "rev-parse", "integration").strip()
    for lower, upper in zip(stack, stack[1:]):
        linear = linear and subprocess.run(["git", "-C", remote, "merge-base", "--is-ancestor", lower, upper]).returncode == 0
    check(f"{want} slice branches are pushed as one linear stack on integration", linear, f"stack={stack}")
    if not stack:
        return finish(run, results)

    trees, failures = {}, []
    for b in stack:
        with tempfile.TemporaryDirectory() as d:
            subprocess.run(["git", "clone", "-q", "--branch", b, remote, d], check=True, capture_output=True)
            if subprocess.run(TEST_CMD, cwd=d, capture_output=True).returncode:
                failures.append(b)
        trees[b] = {f: git(remote, "show", f"{b}:{f}") for f in git(remote, "ls-tree", "-r", "--name-only", b).split()}
    check("Every slice's test suite passes", not failures, f"failing={failures}" if failures else "all green")

    first = trees[stack[0]]
    routed = '("POST", "/turn")' in first.get("chat/app.py", "") and "def run_turn" in first.get("chat/turn/run.py", "")
    check("Slice 1 answers a turn end to end: run_turn behind a routed POST /turn", routed,
          f"routed={routed}")
    extra = behaviours(first)
    check("Slice 1 is bare: none of the rules, suggestions or diagnostics ride along", not extra,
          f"extra={sorted(extra)}" if extra else "bare")

    uncalled = [f"{b}: policy.{fn}" for b in stack for fn in POLICY_FNS
                if f"def {fn}" in trees[b].get("chat/turn/policy.py", "") and f"{fn}(" not in trees[b].get("chat/turn/run.py", "")]
    check("No policy rule lands without run_turn calling it", not uncalled, "; ".join(uncalled) or "every rule is called")

    early_diag = [f"{b}: {sorted(behaviours(trees[b]) & DIAGNOSTICS)}" for b in stack if behaviours(trees[b]) & DIAGNOSTICS]
    check("No built slice carries the diagnostics (debug override, figures metric)", not early_diag,
          "; ".join(early_diag) or "none")

    topics_stray = [b for b in stack if "knowledge/topics.json" in trees[b]
                    and not behaviours(trees[b]) & {"off-topic refusal", "suggestions"}]
    check("knowledge/topics.json only lands in a slice whose code reads it", not topics_stray,
          f"stray={topics_stray}" if topics_stray else "clean")

    if mode == "thin":
        added = sorted(behaviours(trees[stack[-1]]) - extra) if len(stack) > 1 else []
        check("Slice 2 adds exactly one behaviour", len(added) == 1, f"added={added}")
    else:
        refused = [b for b in stack if "off-topic refusal" in behaviours(trees[b]) or "REFUSAL" in trees[b].get("chat/turn/run.py", "")]
        check("The off-topic refusal the user held back is in no slice", not refused, f"in={refused}" if refused else "absent")
        got = [sorted(behaviours(trees[b]) - behaviours(trees[a])) for a, b in zip(stack, stack[1:])]
        check("Slices 2 and 3 add clipping, then suggestions", got == [["answer clipping"], ["suggestions"]], f"added={got}")
        top = trees[stack[-1]]
        check("The suggestions slice carries topics.json and its loader, which the dropped slice used to bring",
              "knowledge/topics.json" in top and "chat/turn/topics.py" in top,
              f"topics.json={'knowledge/topics.json' in top} topics.py={'chat/turn/topics.py' in top}")
        notes = "".join(open(os.path.join(run, "outputs", n)).read() for n in ("plan.md", "prs.md")
                        if os.path.exists(os.path.join(run, "outputs", n)))
        check("plan.md or prs.md says topics.json moved because slice 2 was left out", "topics.json" in notes,
              "mentioned" if "topics.json" in notes else "not mentioned")

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
