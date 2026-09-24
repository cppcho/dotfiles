#!/usr/bin/env python3
"""Grades a build-refunds-python run: grade_build.py <run-dir>. Writes <run-dir>/grading.json."""
import json
import os
import subprocess
import sys
import tempfile

REFUND_ONLY = [
    "shop/clients/payment_client.py",
    "shop/service/refund_service.py",
    "shop/domain/order.py",
    "tests/test_order.py",
    "tests/test_payment_client.py",
    "tests/test_refund_service.py",
    "tests/test_order_repository.py",
]
# Refund-only files where the plan may deliberately differ from wip (count_refunds has no caller).
ALLOWED_DEVIATION = {"shop/repository/order_repository.py": "count_refunds"}
SHARED_REFUND_MARKERS = {
    "shop/api/handlers.py": ["post_refund", "get_refunds"],
    "shop/app.py": ["PaymentClient", "/orders/{id}/refunds"],
    ".env.example": ["PAYMENT_API_URL"],
    "tests/test_handlers.py": ["test_post_refund"],
}
NEWSLETTER = ["newsletter", "subscribe", "send_newsletter"]


def git(repo, *args, check=True):
    return subprocess.run(["git", "-C", repo, *args], capture_output=True, text=True, check=check).stdout


def main():
    run = sys.argv[1]
    remote = os.path.join(run, "fixture", "remote.git")
    heads = [l.split("refs/heads/")[1] for l in git(remote, "for-each-ref", "--format=%(refname)", "refs/heads").split()]
    stack = [h for h in heads if h not in ("main", "integration", "wip")]
    ahead = {b: int(git(remote, "rev-list", "--count", f"integration..{b}")) for b in stack}
    stack.sort(key=lambda b: ahead[b])
    results = []

    def check(text, passed, evidence):
        results.append({"text": text, "passed": bool(passed), "evidence": evidence})

    linear = bool(stack) and git(remote, "merge-base", "integration", stack[0]).strip() == git(remote, "rev-parse", "integration").strip()
    for lower, upper in zip(stack, stack[1:]):
        linear = linear and subprocess.run(["git", "-C", remote, "merge-base", "--is-ancestor", lower, upper]).returncode == 0
    check("New branches form one linear stack based on integration and are pushed to origin", linear, f"stack={stack}")

    failures, contents = [], {}
    for b in stack:
        with tempfile.TemporaryDirectory() as d:
            subprocess.run(["git", "clone", "-q", "--branch", b, remote, d], check=True, capture_output=True)
            r = subprocess.run(["python3", "-m", "unittest", "discover", "-s", "tests", "-t", "."], cwd=d, capture_output=True, text=True)
            if r.returncode != 0:
                failures.append(f"{b}: {r.stderr.strip().splitlines()[-1] if r.stderr.strip() else 'fail'}")
            tree = {}
            for root, _, files in os.walk(d):
                if ".git" in root or "__pycache__" in root:
                    continue
                for f in files:
                    p = os.path.relpath(os.path.join(root, f), d)
                    tree[p] = open(os.path.join(root, f)).read()
            contents[b] = tree
    check("Every branch in the stack passes python3 -m unittest discover -s tests -t .", stack and not failures, "; ".join(failures) or f"{len(stack)} branches green")

    tip = contents[stack[-1]] if stack else {}
    diffs = []
    for f in REFUND_ONLY:
        wip = git(remote, "show", f"wip:{f}")
        if tip.get(f) != wip:
            diffs.append(f)
    repo_file = "shop/repository/order_repository.py"
    wip_repo = git(remote, "show", f"wip:{repo_file}")
    stripped = "\n".join(l for l in wip_repo.splitlines() if "count_refunds" not in l and "len(self._refunds" not in l)
    if tip.get(repo_file) not in (wip_repo, None) and tip.get(repo_file, "").replace("\n", "") != stripped.replace("\n", ""):
        diffs.append(repo_file + " (beyond dropping count_refunds)")
    check("The stack tip matches wip for refund-only files", stack and not diffs, f"differ: {diffs}" if diffs else "identical")

    leaks = [f"{b}:{p}" for b in stack for p, body in contents[b].items() if any(w in body for w in NEWSLETTER)]
    check("No newsletter code appears in any branch of the stack", stack and not leaks, f"leaks: {leaks[:6]}" if leaks else "none")

    missing = [f"{f}:{m}" for f, ms in SHARED_REFUND_MARKERS.items() for m in ms if m not in tip.get(f, "")]
    check("The tip's shared files (handlers, app, .env.example, tests) carry the refund hunks", stack and not missing, f"missing: {missing}" if missing else "all present")

    first = contents[stack[0]] if stack else {}
    check(
        "The payment client slice comes first and is not wired into app.py",
        "shop/clients/payment_client.py" in first and "PaymentClient" not in first.get("shop/app.py", ""),
        f"first={stack[0] if stack else None}; client={'shop/clients/payment_client.py' in first}; wired={'PaymentClient' in first.get('shop/app.py', '')}",
    )

    early_handlers = [b for b in stack[:-1] if "post_refund" in contents[b].get("shop/api/handlers.py", "")]
    check("post_refund/get_refunds handlers only appear in the top slice", stack and not early_handlers, f"early: {early_handlers}" if early_handlers else "top only")

    # The caller rule: a domain or repository method only lands in a slice that also has its caller.
    uncalled = []
    for b in stack:
        t = contents[b]
        has_service = "shop/service/refund_service.py" in t
        if "apply_refund" in t.get("shop/domain/order.py", "") and not has_service:
            uncalled.append(f"{b}: Order.apply_refund without RefundService")
        if "save_refund" in t.get("shop/repository/order_repository.py", "") and not has_service:
            uncalled.append(f"{b}: save_refund without RefundService")
        if "list_refunds" in t.get("shop/repository/order_repository.py", "") and "list_refunds" not in t.get("shop/service/refund_service.py", ""):
            uncalled.append(f"{b}: repository list_refunds without its service caller")
        if "count_refunds" in t.get("shop/repository/order_repository.py", ""):
            uncalled.append(f"{b}: count_refunds has no caller anywhere")
    check("No slice adds a domain or repository method without its caller", stack and not uncalled, "; ".join(uncalled) or "every method lands beside its caller")

    prs_path = os.path.join(run, "outputs", "prs.md")
    prs = open(prs_path).read() if os.path.exists(prs_path) else ""
    unlisted = [b for b in stack if b not in prs]
    check("prs.md lists every PR with its base branch", prs and not unlisted and "integration" in prs, f"unlisted: {unlisted}" if unlisted else ("present" if prs else "no prs.md"))

    passed = sum(r["passed"] for r in results)
    json.dump(
        {"expectations": results, "summary": {"passed": passed, "failed": len(results) - passed, "total": len(results), "pass_rate": passed / len(results)}},
        open(os.path.join(run, "grading.json"), "w"),
        indent=2,
    )
    print(f"{passed}/{len(results)}", stack)


if __name__ == "__main__":
    main()
