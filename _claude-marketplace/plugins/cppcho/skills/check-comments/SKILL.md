---
name: check-comments
description: Reviews the comments in a diff and fixes what doesn't earn its place — redundant comments get deleted, verbose ones get tightened to the non-obvious "why", and comments narrating the revision get rewritten to describe the final state. Use when the user asks to check, review, tighten or clean up comments or doc comments, asks to remove unnecessary or obvious comments (e.g. "remove unnecessary comments that describe obvious code"), wonders whether a comment is needed or too verbose, or wants the prose in a diff gone over before it ships; other skills invoke it once their work is green and before it gets committed.
argument-hint: "[diff-range|path]"
model: sonnet
---

# Check comments

Three questions per comment the diff adds or touches:

1. **Does it tell the reader something the code doesn't?** If a reader would reach the right conclusion from the code alone, delete it. Usual cuts: restatements of what the code shows, a justification a guard's own error message already gives, a field's name/type/units repeated back, a test doc repeating the test name, narration of what an assertion asserts. Usual keepers: the schema or external constraint behind a literal, why a result is discarded or a value deliberately left unset, a silent-fallback trap a guard prevents, a deliberate-looking-like-an-oversight choice a reader would otherwise undo, the contract of an exported function a caller can't read off the signature.
2. **Is it concise?** A sentence or two on the non-obvious "why", not paragraphs. Tighten what survived rule 1 rather than matching a verbose neighbour's length. A comment that runs to paragraphs is usually answering several questions — judge each part on its own.
3. **Does it describe the final state, not the revision?** Only the last version reaches the base branch, so drop "changed from X to Y", "now also handles…", "previously this returned…". Rewrite it to read as though the code had always been that way.

A comment that is flat-out wrong — an invariant nothing enforces, a return the function no longer produces — gets corrected rather than trimmed, unless nothing is left once the false part goes; then it's a deletion.

Borderline calls go to the comment: a short, accurate line that some reader might want is not worth an edit. Spend the pass on the ones that clearly fail. A doc comment is the one place worth a second look — the contract belongs there, the call graph doesn't, so trim the sentence about who calls this and why and keep the one about what it guarantees.

Two things are not comments and stay untouched:

- **Directives.** `//go:build`, `//go:generate`, `//nolint`, `# type: ignore`, `# noqa`, `eslint-disable`, JSDoc types — a tool reads these, and deleting one changes behaviour.
- **A doc-convention summary line.** godoc's leading sentence, a docstring, a JSDoc summary — that first line is the convention being met. Keep it and judge what follows.

## Scope

With an argument, take it as given — a range or a path. With none, review the branch: `git diff $(git merge-base HEAD <base-branch>)`, which covers the branch's commits plus uncommitted work. Also check `git status --porcelain` for untracked files and read those in full; `git diff` won't show them, and new files are where fresh comments are densest.

Read each comment where it lives, with the code around it — rule 1 asks what a reader would conclude from the code alone, so a grep of added comment lines isn't something you can judge from. Decide before you rewrite: a pass that edits as it reads rewords comments it should have deleted, because polishing the wording feels like having judged it.

Edit the files directly rather than handing back a list to apply. Leave the edits uncommitted; where they land is the caller's call.

## Report

State the range reviewed, then per edit: `file:line`, what it said, what it says now, and which rule it failed. Finding nothing to fix is a real answer — say so plainly rather than reaching for a change to justify the pass.
