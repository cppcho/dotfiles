"""Grade gemini-prompting eval runs. Usage: python grade.py <iteration-dir>

Writes grading.json into each <eval>/<config>/ run directory. Checks are regex
heuristics over the output files; judgement-only checks are left to a human.
"""
import json
import re
import sys
from pathlib import Path

CAPS = re.compile(r"\b(IMPORTANT|MUST|CRITICAL|NEVER|ALWAYS)\b")
COT = re.compile(r"step[- ]by[- ]step|<thinking>|ステップバイステップ|段階的に考え", re.I)
FALLBACK = re.compile(r"記載(が|は)?(ない|ありません|されていない)|見つから|見当た[らり]|含まれていない|載っていない|not (found|in|covered)")
EXAMPLE = re.compile(r"(?mi)^\s*(inquiry|input|user|customer|ユーザー|お客様|質問|q)\s*[:：]|<example\b|example \d")
SAMPLING = re.compile(r"\b(temperature|topP|topK|top_p|top_k|Temperature|TopP|TopK)\s*[:=]")


def prompt_text(src: str) -> str:
    """Template literals and Go raw/quoted strings — the text the model reads."""
    parts = re.findall(r"`([^`]*)`", src, re.S)
    parts += re.findall(r'"((?:[^"\\]|\\.){40,})"', src)
    return "\n".join(parts)


def mixed_delimiters(text: str) -> bool:
    xml = re.search(r"<(?!\$|/?(?:br|p)\b)[a-z_]+>", text)
    md = re.search(r"(?m)^\s*#{1,4} \S", text)
    return bool(xml and md)


def check(name, passed, evidence):
    return {"text": name, "passed": bool(passed), "evidence": evidence}


def common(src):
    pt = prompt_text(src)
    caps = CAPS.findall(pt)
    cot = COT.findall(pt)
    samp = SAMPLING.findall(re.sub(r"(?m)//.*$", "", src))
    return [
        check("No temperature/topP/topK set", not samp, f"found {samp}" if samp else "none set"),
        check("No caps emphasis (IMPORTANT/MUST/CRITICAL/NEVER/ALWAYS) in prompt text", not caps, f"found {caps}" if caps else "none"),
        check("No step-by-step / <thinking> scaffolding", not cot, f"found {cot}" if cot else "none"),
        check("Few-shot examples included in the prompt", len(EXAMPLE.findall(pt)) >= 2, f"{len(EXAMPLE.findall(pt))} example markers"),
        check("One delimiter style (not XML tags and Markdown headings mixed)", not mixed_delimiters(pt), "mixed" if mixed_delimiters(pt) else "single style"),
    ]


def grade_faq(out: Path):
    f = out / "route.ts"
    if not f.exists():
        return [check("route.ts written", False, "missing")]
    src = f.read_text()
    res = common(src)
    res.append(check("Grounding fallback reply defined for answers not in the FAQ",
                     FALLBACK.search(src), "fallback phrasing present" if FALLBACK.search(src) else "no fallback phrasing"))
    res.append(check("Current date injected at runtime", re.search(r"new Date\(|Date\.now\(|toLocaleDateString|Intl\.DateTimeFormat", src), "date code present" if re.search(r"new Date\(|Date\.now\(|toLocaleDateString|Intl\.DateTimeFormat", src) else "no date code"))
    res.append(check("Uses gemini-3.8-flash via @ai-sdk/google", "gemini-3.8-flash" in src and "@ai-sdk/google" in src, "ok" if "gemini-3.8-flash" in src else "model id missing"))
    return res


def grade_go(out: Path):
    f = out / "tools.go"
    if not f.exists():
        return [check("tools.go written", False, "missing")]
    src = f.read_text()
    res = common(src)
    consts = dict(re.findall(r'(\w+)\s*=\s*"([^"]*)"', src))
    names = [n.strip('"') if n.startswith('"') else consts.get(n, n) for n in re.findall(r'\bName:\s*("[^"]+"|\w+)', src)]
    res.append(check("Three function names, all snake_case", len(names) >= 3 and all(re.fullmatch(r"[a-z][a-z0-9_]*", n) for n in names), f"names={names}"))
    enums = re.findall(r"Enum:\s*\[\]string\{([^}]*)\}", src)
    res.append(check("unit and plan declared as enums", len(enums) >= 2 and any("GB" in e for e in enums) and any("standard" in e for e in enums), f"enums={enums}"))
    res.append(check("Required set on every declaration", len(re.findall(r"Required:", src)) >= 3, f"{len(re.findall(r'Required:', src))} Required fields"))
    res.append(check("Formats described (YYYY-MM month, MM + 10 digit account ID)", "YYYY-MM" in src and re.search(r"MM.{0,40}10|\\d\{10\}|MM0123456789", src), "both present" if "YYYY-MM" in src else "YYYY-MM missing"))
    res.append(check("Plan change gated on user confirmation", re.search(r"confirm", src, re.I), "mentions confirmation" if re.search(r"confirm", src, re.I) else "no confirmation"))
    return res


def grade_rewrite(out: Path):
    f = out / "classify-inquiry.ts"
    if not f.exists():
        return [check("classify-inquiry.ts written", False, "missing")]
    src = f.read_text()
    res = common(src)
    res.append(check("category and urgency are z.enum", len(re.findall(r"\.enum\(", src)) >= 2, f"{len(re.findall(r'[.]enum[(]', src))} enum calls"))
    res.append(check("Every schema field has .describe()", len(re.findall(r"\.describe\(", src)) >= 4, f"{len(re.findall(r'[.]describe[(]', src))} describe calls"))
    res.append(check("JSON shape not restated in the prompt", not re.search(r"Return JSON|JSON like", src), "restated" if re.search(r"Return JSON|JSON like", src) else "not restated (JSON in few-shot outputs is fine)"))
    res.append(check("All five categories preserved", all(c in src for c in ["billing", "plan", "mnp", "device", "other"]), "ok"))
    res.append(check("notes.md written", (out / "notes.md").exists(), "present" if (out / "notes.md").exists() else "missing"))
    return res


GRADERS = {
    "nextjs-grounded-faq-assistant": grade_faq,
    "go-function-declarations": grade_go,
    "rewrite-claude-style-classifier": grade_rewrite,
}


def main(it: Path):
    for eval_dir in sorted(it.glob("eval-*")):
        grader = GRADERS[eval_dir.name.split("-", 2)[2]]
        for run in sorted(eval_dir.glob("*/run-*")):
            exps = grader(run / "outputs")
            n = sum(e["passed"] for e in exps)
            grading = {"expectations": exps, "summary": {"passed": n, "failed": len(exps) - n, "total": len(exps), "pass_rate": round(n / len(exps), 3)}}
            (run / "grading.json").write_text(json.dumps(grading, indent=2, ensure_ascii=False))
            print(f"{eval_dir.name}/{run.parent.name}: {n}/{len(exps)}")
            for e in exps:
                if not e["passed"]:
                    print(f"   FAIL {e['text']}: {e['evidence']}")


if __name__ == "__main__":
    main(Path(sys.argv[1]))
