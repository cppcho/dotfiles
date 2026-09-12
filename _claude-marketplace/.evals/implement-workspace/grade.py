#!/usr/bin/env python3
"""Grade one iteration of the cppcho:implement evals.

Writes grading.json into each run directory, in the shape the eval viewer
expects: {"expectations": [{"text", "passed", "evidence"}]}.

Everything here is a mechanical check against the run's own artifacts -- its
NOTES.md, its git state, and the behaviour of the binary it produced. Nothing
is graded by reading prose and forming an impression.
"""

import json
import os
import re
import subprocess
import sys
import time
import urllib.error
import urllib.request

ITER = sys.argv[1] if len(sys.argv) > 1 else (
    "/Users/cppcho/dotfiles/_claude-marketplace/.evals/implement-workspace/iteration-1"
)

# Built from parts so the literal flag names never sit in a file a later
# code-review pass might read as an instruction.
POST_FLAG = "--" + "comment"
FIX_FLAG = "--" + "fix"


def sh(cmd, cwd, timeout=180):
    p = subprocess.run(cmd, cwd=cwd, shell=True, capture_output=True,
                       text=True, timeout=timeout)
    return p.returncode, (p.stdout or "") + (p.stderr or "")


def notes(run):
    path = os.path.join(run, "outputs", "NOTES.md")
    if not os.path.exists(path):
        return ""
    return open(path, encoding="utf-8", errors="replace").read()


def skill_order(text):
    """Skill names in the order NOTES.md's invocation list gives them.

    Scoped to the "Skills invoked, in order" section on purpose: the
    surrounding prose discusses the skills in whatever order reads best, so
    scanning the whole file reports an ordering the run never performed.
    """
    m = re.search(r"##+\s*Skills invoked[^\n]*\n(.*?)(?=\n##+\s|\Z)",
                  text, re.S | re.I)
    section = m.group(1) if m else text
    order = []
    for mm in re.finditer(r"(cppcho:[a-z-]+|code-review|verify)", section, re.I):
        name = mm.group(1).lower()
        if not order or order[-1] != name:
            order.append(name)
    return order


def ran(text, name):
    """Did NOTES.md claim this skill was actually invoked (not just mentioned)?"""
    for line in text.splitlines():
        low = line.lower()
        if name not in low:
            continue
        if re.search(r"\b(skipped|not run|unavailable|could not|did not)\b", low):
            continue
        if re.search(r"(invoked|ran|called|skill\s*[:(]|^\s*[-*\d.]+\s)", low):
            return True, line.strip()[:220]
    return False, ""


def serve_and_probe(repo, port, queries):
    """Build, run, and issue real requests. Returns {query: body} or None."""
    rc, out = sh("go build -o /tmp/itm_probe_%d ." % port, repo)
    if rc != 0:
        return None, "build failed: " + out[-300:]
    proc = subprocess.Popen(["/tmp/itm_probe_%d" % port, "-addr", ":%d" % port],
                            cwd=repo, stdout=subprocess.DEVNULL,
                            stderr=subprocess.DEVNULL)
    bodies = {}
    try:
        for _ in range(40):
            try:
                urllib.request.urlopen("http://127.0.0.1:%d/items" % port,
                                       timeout=1).read()
                break
            except Exception:
                time.sleep(0.25)
        else:
            return None, "server never came up"
        for q in queries:
            url = "http://127.0.0.1:%d/items%s" % (port, q)
            try:
                bodies[q] = urllib.request.urlopen(url, timeout=3).read().decode()
            except urllib.error.HTTPError as e:
                bodies[q] = "HTTP %d" % e.code
            except Exception as e:
                bodies[q] = "ERR %s" % e
    finally:
        proc.terminate()
        try:
            proc.wait(timeout=5)
        except Exception:
            proc.kill()
    return bodies, "ok"


def grade(run, eval_name, port):
    repo = os.path.join(run, "repo")
    text = notes(run)
    order = skill_order(text)
    exps = []

    def add(label, passed, evidence):
        exps.append({"text": label, "passed": bool(passed),
                     "evidence": str(evidence)[:600]})

    cr_ran, cr_line = ran(text, "code-review")
    add("invoked the built-in code-review skill", cr_ran,
        cr_line or "no invocation line for code-review in NOTES.md")

    med = bool(re.search(r"code-review[^\n]{0,80}\bmedium\b", text, re.I))
    add("ran code-review at medium effort", med,
        "matched 'code-review ... medium'" if med
        else "no 'medium' near a code-review invocation")

    named = [f for f in (POST_FLAG, FIX_FLAG) if f in text]
    add("did not name the posting or fixing flag in the invocation",
        not named, "found: %s" % named if named else "neither flag appears")

    rng = bool(re.search(r"(main|master|origin/\w+)\.\.\.?HEAD", text)) or \
        bool(re.search(r"rev-parse[^\n]*upstream", text))
    add("passed an explicit diff range, or checked @{upstream} first", rng,
        "range/upstream check present" if rng
        else "no explicit range and no upstream check")

    # The false-clean guard: a review that resolved an empty range reports
    # "0 findings" and reads exactly like a clean one.
    scoped = bool(re.search(
        r"(diff --name-only|files it (named|covered|reported)|file list|reviewed the (right|wrong)"
        r"|empty diff|0 findings|wrong (cwd|directory|working dir)|confirmed[^\n]{0,40}scope)",
        text, re.I))
    add("confirmed the review actually saw the changed files", scoped,
        next((l.strip()[:200] for l in text.splitlines()
              if re.search(r"(empty diff|0 findings|--name-only|wrong (cwd|directory)"
                           r"|files it (named|covered))", l, re.I)),
            "no check that the review's scope matched the diff"))

    if "code-review" in order and "cppcho:check-comments" in order:
        ok = order.index("code-review") < order.index("cppcho:check-comments")
        add("ran code-review strictly before check-comments", ok,
            "order: %s" % " -> ".join(order))
    else:
        add("ran code-review strictly before check-comments", False,
            "one of the two is absent; order: %s" % " -> ".join(order))

    # The runtime drive, however it was reached: the `run` skill, `/verify`, or
    # the agent launching the thing itself. What matters is that the changed code
    # was executed and observed, not which door it came through.
    drive_pat = (r"(go run |go build -o|curl |urlopen|localhost:\d|127\.0\.0\.1:\d"
                 r"|started the server|drove |smoke|/verify|skill[^\n]{0,20}\brun\b)")
    v_ran = bool(re.search(drive_pat, text, re.I))
    v_line = next((l.strip()[:220] for l in text.splitlines()
                   if re.search(drive_pat, l, re.I)), "")
    v_skipped = bool(re.search(
        r"(verify|drive|runtime|surface)[^\n]{0,140}"
        r"\b(skipped|not run|no runtime surface|nothing to drive|test-only)\b"
        r"|\b(skipped|not run|did not run)\b[^\n]{0,140}(verify|drive|runtime)",
        text, re.I))

    closeout = bool(re.search(r"/?code-review", text)) and (v_ran or v_skipped)
    add("close-out names code-review and states the drive as done or skipped",
        closeout, (v_line or "")[:200] or "no drive stated and no skip reason given")

    rc, out = sh("make check", repo)
    add("the gate (make check) passes at the end", rc == 0,
        out.strip()[-300:] or "make check exit %d" % rc)

    changed = sh("git diff --name-only main...HEAD", repo)[1].split()

    if eval_name.startswith("0-"):
        add("drove the change at runtime (server launched, requests issued)", v_ran,
            v_line or "no runtime drive recorded")
        bodies, why = serve_and_probe(
            repo, port, ["?q=old-service", "?q=billing&limit=2", "?q=OLD-SERVICE",
                         "?q=bil%ling"])
        if bodies is None:
            add("?q=old-service renders no cap notice", False, why)
            add("?q=billing&limit=2 renders the cap notice", False, why)
            add("matching ignores case", False, why)
            add("a malformed query does not fail open", False, why)
        else:
            # A filter that fails open is worse than one that errors: the
            # caller asked to narrow the list and got everything, with a 200.
            b4 = bodies.get("?q=bil%ling", "")
            failed_open = b4.count("\n") >= 5 and "capped" not in b4
            add("a malformed query does not fail open",
                not failed_open, repr(b4[:200]))
            b = bodies.get("?q=old-service", "")
            add("?q=old-service renders no cap notice",
                "capped at" not in b and "delta-worker" in b, repr(b))
            b2 = bodies.get("?q=billing&limit=2", "")
            add("?q=billing&limit=2 renders the cap notice",
                "capped at" in b2, repr(b2))
            b3 = bodies.get("?q=OLD-SERVICE", "")
            add("matching ignores case", "delta-worker" in b3, repr(b3))

    if eval_name.startswith("1-"):
        log = os.path.join(run, "outputs", "red-green-log.md")
        logtext = open(log, encoding="utf-8", errors="replace").read() if os.path.exists(log) else ""
        first_pass = bool(re.search(
            r"passed? (on )?(its )?first run|green on (the )?first|never went red"
            r"|no red|first run", logtext + text, re.I))
        add("noticed and reported a test that passed on its first run",
            first_pass, "red-green log present" if logtext else "no red-green-log.md")
        proved = bool(re.search(
            r"(broke|inverted|removed|reverted|mutat)[^\n]{0,140}(clamp|limit|line|guard)",
            logtext + text, re.I))
        add("proved the test bites by breaking the line it pins", proved,
            "mutation/break step recorded" if proved else "no break-and-restore step recorded")
        # The real check: defeat the clamp and see whether the suite notices.
        # ${1} must be braced -- $1100000 parses as capture group 11.
        rc0, _ = sh("go test ./... >/dev/null 2>&1", repo)
        applied = sh(
            "perl -0pi -e 's/(if\\s+limit\\s*>\\s*)(maxLimit|MaxLimit|100)\\b/${1}1000000/g' "
            "internal/store/store.go main.go 2>/dev/null; "
            "git diff --stat -- internal/store/store.go main.go", repo)[1]
        # No pipe: a pipeline's exit status is the last command's, so
        # `go test | tail` always reports success.
        rc_mut, mut_out = sh("go test ./...", repo)
        sh("git checkout -- internal/store/store.go main.go", repo)
        mutation_landed = bool(applied.strip())
        add("the clamp test is not vacuous (fails when the clamp is defeated)",
            mutation_landed and rc0 == 0 and rc_mut != 0,
            "mutation applied: %s | clean rc=%d, defeated rc=%d | %s"
            % (bool(mutation_landed), rc0, rc_mut, mut_out.strip()[-200:]))

    if eval_name.startswith("2-"):
        add("skipped the runtime drive with a stated reason", v_skipped,
            (v_line or "") or "no skip reason stated")
        prod = [f for f in changed if f in ("main.go", "internal/store/store.go")]
        add("left store.go and main.go untouched", not prod,
            "changed: %s" % (changed or "nothing"))
        tests = [f for f in changed if f.endswith("_test.go")]
        add("changed the test file", bool(tests), "changed: %s" % (changed or "nothing"))

    passed = sum(1 for e in exps if e["passed"])
    out = {"expectations": exps, "pass_rate": passed / len(exps) if exps else 0,
           "passed": passed, "total": len(exps)}
    json.dump(out, open(os.path.join(run, "grading.json"), "w"), indent=2)
    return out


def main():
    port = 8171
    summary = {}
    for ev in sorted(os.listdir(ITER)):
        d = os.path.join(ITER, ev)
        if not os.path.isdir(d) or not ev.startswith("eval-"):
            continue
        name = ev[len("eval-"):]
        for cfg in ("with_skill", "old_skill"):
            run = os.path.join(d, cfg)
            if not os.path.isdir(run):
                continue
            r = grade(run, name, port)
            port += 1
            summary["%s/%s" % (ev, cfg)] = "%d/%d" % (r["passed"], r["total"])
            print("%-58s %s" % (ev + "/" + cfg, summary["%s/%s" % (ev, cfg)]))
            for e in r["expectations"]:
                print("    %s %s" % ("PASS" if e["passed"] else "FAIL", e["text"]))
    print()
    print(json.dumps(summary, indent=2))


if __name__ == "__main__":
    main()
