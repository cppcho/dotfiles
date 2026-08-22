---
name: check-comments
description: Reviews the comments in a diff and fixes what fails three rules — unnecessary comments get deleted, verbose ones get tightened to a concise non-obvious "why", and comments narrating the revision get rewritten to describe the final state. Use when the user asks to check, review, tighten or clean up comments or doc comments, asks to remove unnecessary or obvious comments (e.g. "remove unnecessary comments that describe obvious code"), wonders whether a comment is needed or too verbose, or wants the prose in a diff gone over before it ships; other skills invoke it once their work is green and before it gets committed.
argument-hint: "[diff-range|path]"
---

# Check comments

Hold every comment the diff adds or touches against three questions, in this order:

1. **Should it exist at all? Deletion is the default.** A comment stays only if you can name the specific wrong conclusion a reader would draw without it; if you can't name one, delete it — don't shorten it. Shortening a comment that shouldn't exist still leaves it there. These never survive: restatements of what the code shows, narration of the obvious, a justification for a guard whose error message says the same thing, a restatement of a field's name/type/units, narration of what an assertion asserts, a test doc repeating the test name, and failure stories ("which would otherwise…"). These earn their place: a schema or external constraint behind a literal, why a result is discarded or a value deliberately left unset, a silent-fallback trap a guard prevents, and the contract of an exported function a caller can't infer from the signature.
2. **Is it concise?** Only a comment that survived rule 1 gets tightened: a sentence or two on the non-obvious "why", not paragraphs. When editing near a verbose comment, tighten it rather than matching its length.
3. **Does it describe the final state, not the revision?** Only the last version reaches the base branch, so a comment explaining why something changed explains a change no future reader ever sees. No "changed from X to Y", "now also handles…", "previously this returned…". Rewrite it to describe how the code behaves, as though it had been written that way from the start.

And one check that overrides tightening: if a comment is flat-out wrong — an invariant nothing enforces, a return the function no longer produces — correct it rather than trim it.

The comments that fail rule 1 are author state leaking onto the page: written right after reasoning about the tricky case, so they record the reasoning rather than what a reader lacks. Expect them to feel load-bearing to the author — that feeling is not evidence. The test is the named wrong conclusion, nothing softer.

## Scope

With an argument, take it as given — a range or a path. With none, review the branch: `git diff $(git merge-base HEAD <base-branch>)`, which covers the branch's commits plus uncommitted work. Also check `git status --porcelain` for untracked files and read those in full — new files are where fresh comments are densest, and `git diff` won't show them.

## Fix, don't list

Edit the files directly rather than producing a list for someone else to apply. Two things to leave alone:

- **Directives are not comments.** `//go:build`, `//go:generate`, `//nolint`, `# type: ignore`, `# noqa`, `eslint-disable`, JSDoc types — these are syntax a tool reads, and deleting one changes behaviour or breaks the build.
- **A doc-convention summary line isn't restatement.** godoc's leading sentence, a docstring, a JSDoc summary — that first line is the convention being met. Keep it and judge what follows.

## Second pass

After the edits, sweep the surviving comments once more with rule 1 only. The first pass reliably under-deletes: a comment that was merely tightened still has to name its wrong conclusion, and a borderline keep decided early in the pass often looks like an obvious delete once the whole diff has been read. Anything that survives on "it's short" or "it's harmless" goes.

## Report

State the range reviewed, then per edit: `file:line`, what it said, what it says now, and which rule it failed. Finding nothing to fix is a real answer — say so plainly rather than reaching for a change to justify the pass.

Leave the edits uncommitted; where they land is the caller's call.
