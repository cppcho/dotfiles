---
name: code-review
description: "Review the current diff, or a PR number/branch/path target, for correctness bugs (plus reuse/simplification/efficiency cleanups where the model's review recipe covers them) at the given effort level (low|medium|high|xhigh|max: from few high-confidence findings up to many, some of them uncertain); with no level given, it reuses the level you typed last. Pass --comment to post findings as inline PR comments, or --fix to apply the findings to the working tree after the review. Pass --max-findings <n> to report up to n findings, or --max-findings all for every finding. The choice stays until you pass --max-findings default."
argument-hint: "[low|medium|high|xhigh|max] [--fix] [--comment] [<pr#>|<branch>|<path>] [--max-findings <n>|all]"
---

# Code review

The bundled review finds the bugs. This skill only changes how the findings read.

## 1. Run the bundled review

Invoke the Skill tool with skill `review`, the bundled review's alias, and pass `$ARGUMENTS` through unchanged.

The bundled review usually runs as a background subagent, so its findings arrive later as a notification. Wait for them. Don't hunt for findings yourself and don't run the review a second time.

## 2. Read the code behind each finding

The reader has not opened the diff. For each finding, read the code at its location: enough to say what that code is for and to size the fix.

Keep every finding. If the code plainly shows a finding is wrong, take it out of the numbered list and name it under **Dropped** at the end, with a one-line reason.

## 3. Write the report

Open with **Scope**: what was reviewed (target, effort), then what the change does, in two or three plain sentences.

Then list the findings, most severe first. Number them 1…N in one sequence across all severities, so the user can say "fix 2 and 4".

````
### 1 · [High] <the claim in one line>

`path/to/file.go:42`

**Context.** What this code is for, in one or two sentences. Name the function and what calls it.

**Failure scenario.**
1. <the input or state>
2. <what the code does with it>
3. → <the wrong result: crash, data loss, wrong value, leaked secret>

**Fix.** What the fix changes, in one or two sentences. About <N> lines in <M> file(s).
````

With no findings, write the Scope and "No findings."

### Severity

- **High**: data loss, a security hole, a crash, or a wrong result on a normal path.
- **Medium**: a wrong result on an edge case a real user can reach, or a missing error path.
- **Low**: wrong only in rare conditions, or a small behaviour gap.
- **Cleanup**: not a bug. Reuse, simplification or efficiency. Its failure scenario is the cost, for example two copies of the logic that drift apart.

### Fix size

Count the lines added or changed, and round: ~2, ~5, ~10, ~30, ~50+. If the fix needs a decision first (which behaviour is correct, an API change), say that instead of only giving a number.

### Style: about 50% ASD-STE100

- Use short sentences, mostly one idea each. Use active voice and present tense.
- Use common words, and the same word for the same thing every time.
- Explain each project-specific name or term where it first appears. Code names in backticks are fine.
- Plain prose is fine where strict STE reads stiffly. This is a lean, not a word count.

## 4. --fix and --comment

With `--fix`, the bundled review applies the fixes. Afterwards, list each finding number as fixed, skipped or no change needed.

With `--comment`, the bundled review posts its own PR comments. The report above is the terminal copy.
