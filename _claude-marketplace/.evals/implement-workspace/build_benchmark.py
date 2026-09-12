#!/usr/bin/env python3
"""Assemble benchmark.json from this workspace's layout.

scripts/aggregate_benchmark.py expects eval-*/<config>/run-N/grading.json; these
runs have no run-N level (one run per config per eval), so the aggregate comes
from here instead. The baseline directory is `old_skill` on disk but is emitted
as `without_skill`, which is the literal string the viewer groups and colours by.
"""

import datetime
import json
import os
import statistics
import sys

W = "/Users/cppcho/dotfiles/_claude-marketplace/.evals/implement-workspace"
ITER = sys.argv[1] if len(sys.argv) > 1 else os.path.join(W, "iteration-1")
CONFIG = {"with_skill": "with_skill", "old_skill": "without_skill"}


def spread(values):
    if not values:
        return {"mean": 0, "stddev": 0, "min": 0, "max": 0}
    return {
        "mean": round(statistics.mean(values), 4),
        "stddev": round(statistics.stdev(values), 4) if len(values) > 1 else 0.0,
        "min": round(min(values), 4),
        "max": round(max(values), 4),
    }


runs = []
by_cfg = {"with_skill": [], "without_skill": []}

for ev in sorted(os.listdir(ITER)):
    d = os.path.join(ITER, ev)
    if not (ev.startswith("eval-") and os.path.isdir(d)):
        continue
    meta_path = os.path.join(d, "eval_metadata.json")
    meta = json.load(open(meta_path)) if os.path.exists(meta_path) else {}
    for disk_cfg, out_cfg in CONFIG.items():
        run_dir = os.path.join(d, disk_cfg)
        gpath = os.path.join(run_dir, "grading.json")
        if not os.path.exists(gpath):
            continue
        g = json.load(open(gpath))
        tpath = os.path.join(run_dir, "timing.json")
        t = json.load(open(tpath)) if os.path.exists(tpath) else {}
        secs = t.get("total_duration_seconds", 0)
        toks = t.get("total_tokens", 0)
        total = g.get("total", len(g.get("expectations", [])))
        passed = g.get("passed", sum(1 for e in g["expectations"] if e["passed"]))
        rate = passed / total if total else 0.0
        runs.append({
            "eval_id": meta.get("eval_id", 0),
            "eval_name": meta.get("eval_name", ev[len("eval-"):]),
            "configuration": out_cfg,
            "run_number": 1,
            "result": {
                "pass_rate": round(rate, 4),
                "passed": passed,
                "failed": total - passed,
                "total": total,
                "time_seconds": secs,
                "tokens": toks,
                "errors": 0,
            },
            "expectations": g["expectations"],
            "notes": [],
        })
        by_cfg[out_cfg].append((rate, secs, toks))

summary = {}
for cfg, rows in by_cfg.items():
    summary[cfg] = {
        "pass_rate": spread([r[0] for r in rows]),
        "time_seconds": spread([r[1] for r in rows]),
        "tokens": spread([r[2] for r in rows]),
    }

d_rate = summary["with_skill"]["pass_rate"]["mean"] - summary["without_skill"]["pass_rate"]["mean"]
d_time = summary["with_skill"]["time_seconds"]["mean"] - summary["without_skill"]["time_seconds"]["mean"]
d_tok = summary["with_skill"]["tokens"]["mean"] - summary["without_skill"]["tokens"]["mean"]
summary["delta"] = {
    "pass_rate": "%+.2f" % d_rate,
    "time_seconds": "%+.1f" % d_time,
    "tokens": "%+d" % round(d_tok),
}

# Sort so each eval's with_skill row precedes its baseline counterpart.
runs.sort(key=lambda r: (r["eval_id"], r["configuration"] != "with_skill"))

notes_path = os.path.join(ITER, "notes.json")
if os.path.exists(notes_path):
    notes = json.load(open(notes_path))
else:
    notes = [
        "'did not name the posting or fixing flag' passes in both configurations: "
        "the baseline skill never invokes code-review, so it cannot name a flag. "
        "Non-discriminating as written -- it is a safety guard on the new step, not "
        "a measure of it.",
        "'the gate (make check) passes' passes in both configurations. The baseline "
        "skill already runs the gate; this assertion confirms the new step does not "
        "break what worked, and differentiates nothing.",
        "Five of the six per-run assertions the baseline fails are process-compliance "
        "checks for a step the baseline skill does not contain (code-review invoked, "
        "at medium, with a range, before the comment pass, named in the close-out). "
        "Read the 0.53 pass-rate delta as mostly definitional. The behavioural "
        "deltas are the ones that carry weight: the fail-open filter on eval-0, and "
        "the runtime-drive skip on eval-2.",
        "eval-0's decisive result is behavioural, not definitional: on '?q=bil%ling' "
        "the with_skill build returns HTTP 400 while the baseline returns every row "
        "in the store with a 200. The caller asked to narrow the list and got "
        "everything. Only the reviewed run caught it.",
        "eval-0 cannot measure capture of the ticket's primary defect: criterion 5 "
        "describes that defect in observable terms, and both configurations fixed it. "
        "Cut criteria 4 and 5 back for iteration 2.",
        "The red-green guard shows no delta on eval-1: both configurations noticed "
        "first-run-green tests and mutated to prove them. Both baselines did this "
        "unprompted, so the instinct is already present some of the time; what the "
        "guard buys is reliability, which three runs cannot demonstrate.",
        "Cost: the review step roughly doubles wall-clock (with_skill mean "
        "%.0fs vs baseline %.0fs) for +%d tokens per run. Whether that is worth it "
        "rests on the fail-open class of defect, not on the pass-rate number."
        % (summary["with_skill"]["time_seconds"]["mean"],
           summary["without_skill"]["time_seconds"]["mean"], round(d_tok)),
    ]

out = {
    "metadata": {
        "skill_name": "cppcho:implement",
        "skill_path": "/Users/cppcho/dotfiles/_claude-marketplace/plugins/cppcho/skills/implement",
        "executor_model": "claude-opus-5[1m]",
        "analyzer_model": "claude-opus-5[1m]",
        "timestamp": datetime.datetime.now(datetime.timezone.utc)
        .strftime("%Y-%m-%dT%H:%M:%SZ"),
        "evals_run": [r["eval_name"] for r in runs if r["configuration"] == "with_skill"],
        "runs_per_configuration": 1,
    },
    "runs": runs,
    "run_summary": summary,
    "notes": notes,
}

path = os.path.join(ITER, "benchmark.json")
json.dump(out, open(path, "w"), indent=2)
print("wrote", path)
print("with_skill    pass_rate %.3f  time %.0fs  tokens %d"
      % (summary["with_skill"]["pass_rate"]["mean"],
         summary["with_skill"]["time_seconds"]["mean"],
         summary["with_skill"]["tokens"]["mean"]))
print("without_skill pass_rate %.3f  time %.0fs  tokens %d"
      % (summary["without_skill"]["pass_rate"]["mean"],
         summary["without_skill"]["time_seconds"]["mean"],
         summary["without_skill"]["tokens"]["mean"]))
print("delta", summary["delta"])
