---
name: check-comments
description: Reviews the comments in a diff and fixes what fails three rules — unnecessary comments get removed, verbose ones get tightened to a concise non-obvious "why", and comments narrating the revision get rewritten to describe the final state. Use when the user asks to check, review, tighten or clean up comments or doc comments, wonders whether a comment is needed or too verbose, or wants the prose in a diff gone over before it ships; other skills invoke it once their work is green and before it gets committed.
argument-hint: "[diff-range|path]"
---

# Check comments

Hold every comment the diff adds or touches against three questions, in this order:

1. **Is it really necessary?** If the code would read just as well without it, remove it. Most comments fail here: restatements of what the code shows, narration of the obvious, rationale nobody would question.
2. **Is it concise?** A sentence or two on the non-obvious "why", not paragraphs. When editing near a verbose comment, tighten it rather than matching its length.
3. **Does it describe the final state, not the revision?** Only the last version reaches the base branch, so a comment explaining why something changed explains a change no future reader ever sees. No "changed from X to Y", "now also handles…", "previously this returned…". Rewrite it to describe how the code behaves, as though it had been written that way from the start.

And one check that overrides tightening: if a comment is flat-out wrong — an invariant nothing enforces, a return the function no longer produces — correct it rather than trim it.

## Scope

With an argument, take it as given — a range or a path. With none, review the branch: `git diff $(git merge-base HEAD <base-branch>)`, which covers the branch's commits plus uncommitted work. Also check `git status --porcelain` for untracked files and read those in full — new files are where fresh comments are densest, and `git diff` won't show them.

## Fix, don't list

Edit the files directly rather than producing a list for someone else to apply. Two things to leave alone:

- **Directives are not comments.** `//go:build`, `//go:generate`, `//nolint`, `# type: ignore`, `# noqa`, `eslint-disable`, JSDoc types — these are syntax a tool reads, and deleting one changes behaviour or breaks the build.
- **A doc-convention summary line isn't restatement.** godoc's leading sentence, a docstring, a JSDoc summary — that first line is the convention being met. Keep it and judge what follows.

## Report

State the range reviewed, then per edit: `file:line`, what it said, what it says now, and which rule it failed. Finding nothing to fix is a real answer — say so plainly rather than reaching for a change to justify the pass.

Leave the edits uncommitted; where they land is the caller's call.
