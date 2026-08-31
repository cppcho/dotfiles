---
name: check-comments
description: Reviews the comments in a diff and fixes what fails three rules — unnecessary comments get deleted, verbose ones get tightened to a concise non-obvious "why", and comments narrating the revision get rewritten to describe the final state. Use when the user asks to check, review, tighten or clean up comments or doc comments, asks to remove unnecessary or obvious comments (e.g. "remove unnecessary comments that describe obvious code"), wonders whether a comment is needed or too verbose, or wants the prose in a diff gone over before it ships; other skills invoke it once their work is green and before it gets committed.
argument-hint: "[diff-range|path]"
---

# Check comments

Hold every comment the diff adds or touches against three questions, in this order:

1. **Should it exist at all? Deletion is the default.** A comment stays only if you can name the specific wrong conclusion a reader would draw without it — and then say what breaks when they act on it. Naming the conclusion is the cheap half; the consequence is the half that does the work. If a reader who believed the wrong thing would go on to write working code anyway, the comment was guarding nothing and goes. Judge one sentence at a time: a two-part comment usually has one part carrying the consequence and one part restating the code, and the two come apart cleanly. If you can't name a conclusion at all, delete it — don't shorten it, since shortening a comment that shouldn't exist still leaves it there. These never survive: restatements of what the code shows, narration of the obvious, a justification for a guard whose error message says the same thing, a restatement of a field's name/type/units, narration of what an assertion asserts, a test doc repeating the test name, a restatement of what the called function's own name and doc comment already say, and failure stories ("which would otherwise…"). These earn their place: a schema or external constraint behind a literal, why a result is discarded or a value deliberately left unset, a silent-fallback trap a guard prevents, and the contract of an exported function a caller can't infer from the signature.

   Two shapes are easy to confuse, and they end differently. A comment that **defends a deliberate choice against a reader who would undo it** earns its place — the `nil` argument that looks like an oversight, the discarded error that looks swallowed, the check done once where a neighbouring one is done twice and so looks like a race. Undo any of those and something breaks, which is the consequence the rule is asking for. A comment that merely **asserts a property the code could not violate anyway** does not: if a reader who got it wrong would have broken nothing, there was nothing to warn them about. The question is what happens to the code, not whether the runtime hazard is live — "X cannot happen, because Y" is a keeper precisely when the code's shape invites a reader to think X can.
2. **Is it concise?** Only a comment that survived rule 1 gets tightened: a sentence or two on the non-obvious "why", not paragraphs. When editing near a verbose comment, tighten it rather than matching its length. A comment that has grown to paragraphs is usually answering several questions at once — send each part back through rule 1 on its own rather than trimming a clause and calling the whole thing tightened. And if your first reaction to a comment was "this could be phrased better", that reaction is about prose while rule 1 is still unanswered: a comment that fails rule 1 doesn't need better phrasing.
3. **Does it describe the final state, not the revision?** Only the last version reaches the base branch, so a comment explaining why something changed explains a change no future reader ever sees. No "changed from X to Y", "now also handles…", "previously this returned…". Rewrite it to describe how the code behaves, as though it had been written that way from the start.

And one check that overrides tightening: if a comment is flat-out wrong — an invariant nothing enforces, a return the function no longer produces, a claim the next clause contradicts — correct it rather than trim it. The exception is a comment with nothing left once the false part goes; that one is a rule 1 deletion, not a correction.

The comments that fail rule 1 are author state leaking onto the page: written right after reasoning about the tricky case, so they record the reasoning rather than what a reader lacks. Expect them to feel load-bearing to the author — that feeling is not evidence. If you wrote this code yourself, you are that author, and the comments will read as necessary to you for the same reason they got written. The test is the named wrong conclusion and its consequence, nothing softer.

## What a doc comment may say

Rule 1 lets the contract of an exported function earn its place, and that licence gets over-read. The contract is the semantics of the signature — what the parameters mean, what the return value is, what the function guarantees. It is not the call graph: a doc comment does not name its callers, explain why a caller would reach for it over a sibling, or narrate what the caller does with the answer. Those facts are true of today's callers only, they go stale the moment a second one appears, and the reader who needs them is at the call site, not here.

The two shapes side by side, on the same function:

- Call-graph narration, cut it: `// IsLineActiveAndNonCancelled reports whether the line passes the same gate the spend paths apply through GetActiveNonCancelledLineByID. A read path that has to render the state of a spend control uses this rather than that resolver, whose refusal is an error.`
- The contract, keep it: `// IsLineActiveAndNonCancelled reports whether the line is Active, within its cancel time and free of a completed or MNP-waiting cancellation.`

Same for a parameter: `// canSpend is whether a spend would be accepted on the line at all; false leaves IsSpendable false whatever the line holds` describes the effect on the return value and stays. A second sentence on how a line out of service still shows its balance is the caller's story and goes.

This is usually a trim rather than a deletion — the summary line and the contract clause survive, the caller sentence comes off. That makes it the one place where rule 2's pen is the right tool before rule 1 has finished, so judge the clauses separately: the contract half is a keeper even when the call-graph half is not.

## Scope

With an argument, take it as given — a range or a path. With none, review the branch: `git diff $(git merge-base HEAD <base-branch>)`, which covers the branch's commits plus uncommitted work. Also check `git status --porcelain` for untracked files and read those in full — new files are where fresh comments are densest, and `git diff` won't show them.

Then read each comment where it lives, with the code around it. A grep of the diff's added comment lines is not something you can judge from: rule 1 asks what a reader would conclude from the code alone, and a comment-only listing has stripped out the very code you'd hold the comment against. Two signals only the file shows. A comment warning about a mistake should sit where that mistake would be made — a hazard described on a struct field rather than at the call site that could get it wrong is usually a note the author wrote to themselves. And a comment that is the one documented member among undocumented siblings says the same thing: the surrounding code got along without any.

## How to run the pass

Three stages, and keeping them separate is the point:

1. **Inventory.** List every comment the diff adds or touches, with its file and line. No edits.
2. **Adjudicate.** Keep or delete each one — the named wrong conclusion and what breaks when a reader acts on it. Apply the deletions. Still no rewriting.
3. **Tighten.** Only now pick up the pen, and only on what survived stage 2.

A pass that edits as it reads will quietly reword comments it should have deleted. Rewriting one feels like having judged it, so the effort spent on the wording stands in for the decision about whether it belongs, and the comment is then treated as settled for the rest of the pass. Closing the keep list before touching any wording removes that option — you cannot reach for a better phrasing as an alternative to a verdict you haven't reached.

Edit the files directly rather than producing a list for someone else to apply. Two things to leave alone:

- **Directives are not comments.** `//go:build`, `//go:generate`, `//nolint`, `# type: ignore`, `# noqa`, `eslint-disable`, JSDoc types — these are syntax a tool reads, and deleting one changes behaviour or breaks the build.
- **A doc-convention summary line isn't restatement.** godoc's leading sentence, a docstring, a JSDoc summary — that first line is the convention being met. Keep it and judge what follows.

## Second pass

Run stage 2 again over the survivors, **starting with the ones you tightened in stage 3.** Those are the riskiest, not the safest — a comment you have just improved is the one you are least willing to throw away, and rule 2 never grants a comment its existence. The rest of the first pass under-deletes too: a borderline keep decided early often looks like an obvious delete once the whole diff has been read. Anything that survives on "it's short" or "it's harmless" goes.

## Report

State the range reviewed, then per edit: `file:line`, what it said, what it says now, and which rule it failed. Finding nothing to fix is a real answer — say so plainly rather than reaching for a change to justify the pass.

Leave the edits uncommitted; where they land is the caller's call.
