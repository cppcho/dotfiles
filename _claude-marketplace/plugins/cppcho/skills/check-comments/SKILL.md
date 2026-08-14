---
name: check-comments
description: Audits the comments in a diff with a fresh pair of eyes — for truth first, then for length — against the code-comment rules in CLAUDE.md, and fixes what doesn't hold up. Use when the user asks to check, review, tighten or clean up comments or doc comments, wonders whether a comment is still accurate or too verbose, or wants the prose in a diff gone over before it ships; other skills invoke it once their work is green and before it gets committed.
argument-hint: "[diff-range|path]"
---

# Check comments

Hold every comment a diff adds or touches against two questions, in this order: **is it true**, and **is it carrying its weight**. Fix the ones that fail. A false comment is the more urgent of the two, because a reader trusts it — a verbose one only costs them time.

The rules being applied are the "Code Comments" section of `~/.claude/CLAUDE.md`, plus any comment conventions in the repo's own `CLAUDE.md`. Read both rather than working from memory of them; the repo's may add conventions of its own.

## 1. Work out who reads

**If you wrote or edited this code in this session, delegate.** Spawn a general-purpose subagent that hasn't seen the session and give it the diff and nothing else. It needs to edit, so a read-only explorer won't do.

That delegation is the point of this skill, not ceremony. The failure mode in your own comments is memory, not inattention, and neither way it leaks is visible from the inside:

- **Narration.** You write "kept flat because nesting broke the encoder" because you remember trying nesting. The attempt isn't in the diff, so a reader who only has the diff has nowhere to get the sentence from.
- **Intent hardening into a claim the code never makes.** You meant callers to hold the mutex before calling, so you write "callers must hold mu" — and it reads as documentation, though nothing enforces it and two call sites don't. You believe it, so you can't audit it. A fresh reader believes nothing yet, so it checks.

Send the diff and nothing else — no plan, no ticket, no what-you-tried. Every line of context you add is a line that can get laundered back into a comment.

**If you're coming to this code cold, you are the fresh reader.** Do it yourself; spawning a subagent to re-derive what you can already see plainly is just latency.

## 2. Scope the diff

With an argument, take it as given — a range, a path, a branch name.

With none, `git diff $(git merge-base HEAD <base-branch>)` is usually right: it covers committed work and the working tree in one range, so a session that already committed a slice or two is still fully in scope. On the default branch, where that range is empty, use the session's own commits instead.

A diff isn't history-free — it shows one step of change, so a reader can still narrate *that*. Whoever reviews should describe the code as though it had always been this way. What the diff does hide is the churn inside the branch, and that's exactly the history CLAUDE.md calls worthless.

## 3. Review, and fix in the files

Edit directly rather than producing a list for someone else to apply. When the review is delegated, the rewrite needs the same fresh eyes the finding did; handing a list back to the author puts the history-holder in charge of the wording again.

Three things to hold onto, since wordiness isn't the only way a comment fails and a reader with a mandate to cut will otherwise overshoot:

- **A comment can be wrong, not just wordy.** An invariant nothing enforces, a bound that stopped matching the constant, a documented return the function no longer produces. You're holding the code the comment describes, so settle these by reading it rather than guessing — and where a claim is cheap to test, test it. Correct the claim rather than cut it where you can: the sentence exists because someone thought the fact mattered, and a true version of it usually still does.
- **A comment carrying a real "why" gets tightened, not deleted.** The rule is against paragraphs and restatement, not against explanation; the load-bearing sentence is the one thing prose can do that code can't. Comments on unchanged lines next to the edits are in scope — CLAUDE.md asks for those tightened rather than matched in length — but code the diff doesn't touch is not.
- **Directives are not comments.** `//go:build`, `//go:generate`, `//nolint`, `# type: ignore`, `# noqa`, `eslint-disable`, JSDoc types, annotation pragmas — these are syntax wearing a comment's clothes, and deleting one changes behaviour or breaks the build. Leave every line a tool reads exactly as it is.

Identifiers carry claims too — a test named `TestRoundsUp` against a function that truncates is the same bug in a different place. Renaming is a code change rather than a comment fix, so flag it instead of doing it.

## 4. Re-run the gate

Comment edits look inert and mostly are, but a stripped pragma fails loudly, and it's cheaper to find here than after the commit. Re-run the project's gate — `make check`, `npm run lint`, whatever CI treats as the bar — or at minimum the formatter and typecheck. A build tag that gates a file out of the default build hides that file from the check, so build it the way the tag asks (`go vet -tags=integration ./...`) before calling it clean.

## 5. Report

Per edit: `file:line`, what it said, what it says now, and which of the two questions it failed. Then what you deliberately left alone and why — that half is what shows the pass had judgment rather than a quota.

Finding nothing to fix is a real answer. Say so plainly rather than reaching for a change to justify the pass.

Leave the edits uncommitted; where they land is the caller's call. `cppcho:implement` folds them into the slice it's about to commit. Invoked on your own, they sit in the working tree until the user says otherwise — `cppcho:commit` records them.
