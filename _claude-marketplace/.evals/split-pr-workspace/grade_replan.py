#!/usr/bin/env python3
"""Grades a replan-drop-refresh-kb run: grade_replan.py <run-dir>. Writes <run-dir>/grading.json."""
import json
import os
import subprocess
import sys
import tempfile

TEST_CMD = ["python3", "-m", "unittest", "discover", "-s", "tests", "-t", "."]
CLIENT_FILES = {"assist/clients/catalog_client.py", "tests/test_catalog_client.py"}
REFRESH_FILES = ["scripts/refresh/crawl.py", "scripts/check_knowledge.py", "tests/test_refresh.py",
                 "tests/test_check_knowledge.py", "tests/fixtures/pages.json", "tests/fixtures/index_bad.jsonl"]
REFRESH_WORDS = ["tmp_cwd", "REFRESH_SOURCE_URL"]


def git(repo, *args):
    return subprocess.run(["git", "-C", repo, *args], capture_output=True, text=True, check=True).stdout


def main():
    run = sys.argv[1]
    remote = os.path.join(run, "fixture", "remote.git")
    heads = [l.split("refs/heads/")[1] for l in git(remote, "for-each-ref", "--format=%(refname)", "refs/heads").split()]
    stack = sorted((h for h in heads if h not in ("main", "integration", "wip")),
                   key=lambda b: int(git(remote, "rev-list", "--count", f"integration..{b}")))
    results = []

    def check(text, passed, evidence):
        results.append({"text": text, "passed": bool(passed), "evidence": evidence})

    linear = len(stack) == 2 and git(remote, "merge-base", "integration", stack[0]).strip() == git(remote, "rev-parse", "integration").strip()
    if linear:
        linear = subprocess.run(["git", "-C", remote, "merge-base", "--is-ancestor", stack[0], stack[1]]).returncode == 0
    check("Two slice branches are pushed as one linear stack on integration", linear, f"stack={stack}")
    if not stack:
        return finish(run, results)

    trees, failures = {}, []
    for b in stack:
        with tempfile.TemporaryDirectory() as d:
            subprocess.run(["git", "clone", "-q", "--branch", b, remote, d], check=True, capture_output=True)
            if subprocess.run(TEST_CMD, cwd=d, capture_output=True).returncode:
                failures.append(b)
        files = git(remote, "ls-tree", "-r", "--name-only", b).split()
        trees[b] = {f: git(remote, "show", f"{b}:{f}") for f in files}
    check("Every slice's test suite passes", not failures, f"failing={failures}" if failures else "all green")

    changed = set(git(remote, "diff", "--name-only", f"integration...{stack[0]}").split())
    check("Slice 1 is the catalog client alone (no helpers, fixtures or env riding along)",
          changed == CLIENT_FILES, f"changed={sorted(changed)}")

    leaks = [f"{b}:{f}" for b in stack for f in REFRESH_FILES if f in trees[b]]
    leaks += [f"{b}:{f}:{w}" for b in stack for f, body in trees[b].items() for w in REFRESH_WORDS if w in body]
    check("Nothing from the dropped refresh tooling survives: no scripts, their fixtures, tmp_cwd or REFRESH_SOURCE_URL",
          not leaks, f"leaks={leaks[:6]}" if leaks else "clean")

    top = trees[stack[-1]]
    wip_index = git(remote, "show", "wip:knowledge/index.jsonl")
    carried = {
        "committed index identical to wip": top.get("knowledge/index.jsonl") == wip_index,
        "assist/knowledge/load.py": "assist/knowledge/load.py" in top,
        "fixture_path in tests/helpers.py": "def fixture_path" in top.get("tests/helpers.py", ""),
        "tests/fixtures/index_small.jsonl": "tests/fixtures/index_small.jsonl" in top,
    }
    missing = [k for k, ok in carried.items() if not ok]
    check("Slice 2 carries the committed index, the loader and the fixture_path helper it needs",
          not missing, f"missing={missing}" if missing else "all present")

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
