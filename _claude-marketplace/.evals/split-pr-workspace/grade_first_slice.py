#!/usr/bin/env python3
"""Grades a first-slice-assist run: grade_first_slice.py <run-dir>. Writes <run-dir>/grading.json."""
import json
import os
import re
import subprocess
import sys
import tempfile

CLIENT = "assist/clients/catalog_client.py"
TEST = "tests/test_catalog_client.py"
TEST_CMD = ["python3", "-m", "unittest", "discover", "-s", "tests", "-t", "."]
# Each mutant breaks the slice's contract with the gateway; the slice's tests should notice.
MUTANTS = [
    ("list path", r"""(["'])v1/list_tools\1""", '"v1/list_tool"'),
    ("call path", r"""(["'])v1/call_tool\1""", '"v1/call_tools"'),
    ("parameters sent unencoded", r"json\.dumps\(\s*parameters\s*\)", "parameters"),
]


def git(repo, *args):
    return subprocess.run(["git", "-C", repo, *args], capture_output=True, text=True, check=True).stdout


def green(d):
    return subprocess.run(TEST_CMD, cwd=d, capture_output=True, text=True).returncode == 0


def main():
    run = sys.argv[1]
    remote = os.path.join(run, "fixture", "remote.git")
    heads = [l.split("refs/heads/")[1] for l in git(remote, "for-each-ref", "--format=%(refname)", "refs/heads").split()]
    stack = sorted((h for h in heads if h not in ("main", "integration", "wip")),
                   key=lambda b: int(git(remote, "rev-list", "--count", f"integration..{b}")))
    results = []

    def check(text, passed, evidence):
        results.append({"text": text, "passed": bool(passed), "evidence": evidence})

    first = stack[0] if stack else None
    on_base = bool(first) and git(remote, "merge-base", "integration", first).strip() == git(remote, "rev-parse", "integration").strip()
    check("One slice branch is pushed, based on integration's tip", on_base and len(stack) == 1, f"branches={stack}")
    if not first:
        return finish(run, results)

    changed = git(remote, "diff", "--name-only", f"integration...{first}").split()
    extra = [f for f in changed if f not in (CLIENT, TEST)]
    check("The slice changes only the catalog client and its test (no helpers, settings, env, wiring)",
          CLIENT in changed and not extra, f"changed={changed}")

    with tempfile.TemporaryDirectory() as d:
        subprocess.run(["git", "clone", "-q", "--branch", first, remote, d], check=True, capture_output=True)
        check("The slice's test suite passes", green(d), "python3 -m unittest discover")
        read = lambda p: open(os.path.join(d, p)).read() if os.path.exists(os.path.join(d, p)) else ""
        client, test = read(CLIENT), read(TEST)

        token = [w for w in ("customer_token", "debug_headers", "ASSIST_DEBUG_URL", "os.environ", "import os", "import Session") if w in client]
        token += [f"test:{w}" for w in ("with_env", "ASSIST_DEBUG_URL", "_token_session") if w in test]
        check("No trace of the customer-token path is left in the client or its test (imports, env reads, helpers)",
              not token, f"found={token}" if token else "clean")

        forward = [w for w in ("ToolCatalog", "catalog.py", "assist/service", "assist.service") if w in client]
        check("No comment in the client explains it by code in a later slice (the ToolCatalog cache)",
              not forward, f"found={forward}" if forward else "clean")

        released = re.search(r"from assist_contracts import[^\n]*ToolSpec", client) and "class ToolSpec" not in client
        check("The client uses assist_contracts.ToolSpec, released on the base, instead of the hand-written copy",
              released, "imports ToolSpec" if released else "hand-written ToolSpec or no import")

        killed, missed = [], []
        for name, pattern, repl in MUTANTS:
            mutated, n = re.subn(pattern, repl, client, count=1)
            if not n:
                missed.append(f"{name} (pattern not found)")
                continue
            open(os.path.join(d, CLIENT), "w").write(mutated)
            (missed if green(d) else killed).append(name)
            open(os.path.join(d, CLIENT), "w").write(client)
        check("The slice's tests fail on a wrong list path, a wrong call path, or unencoded parameters",
              not missed, f"killed={killed}; survived={missed}")

    plan = os.path.join(run, "outputs", "plan.md")
    prs = os.path.join(run, "outputs", "prs.md")
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
