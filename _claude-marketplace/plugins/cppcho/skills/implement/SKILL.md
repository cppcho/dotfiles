---
name: implement
description: Implements the work a spec or ticket describes, TDD at agreed seams, runs the repo's gate, has a fresh pair of eyes tighten the comments, and commits to the current branch. Use when building work that has already been specced or ticketed.
argument-hint: "[spec-or-ticket-path|ticket-number]"
disable-model-invocation: true
---

# Implement

Build what a spec or ticket describes. Plan before touching code, check the plan with the user only where it rests on a decision the work didn't already make, then run to completion red-green at the agreed seams.

Track progress with this checklist:

```
- [ ] Read the work
- [ ] Plan it — post the plan, stop only if a call in it is yours
- [ ] Find the commands
- [ ] Build it red-green
- [ ] Verify: suite on changed files, then the gate
- [ ] Read the comments with fresh eyes — delegate the diff, no history
- [ ] Commit — tick the criteria, record the branch it went to
```

## 1. Read the work

If the user passed a reference — `.scratch/<feature-slug>/spec.md`, `.scratch/<feature-slug>/issues/03-*.md`, a ticket number, an issue URL — read its full body.

With no argument, draw the ticket set with the `cppcho:ticket-dag` skill and take the **frontier** from it: a `●` row — blockers all done, no **Superseded** line retiring it, nothing outside the graph parking it. Drawing beats scanning the directory yourself because `●` is this frontier rule applied to every ticket at once, so the pick becomes visible to the user instead of a choice made silently in your head. It's also stricter than counting checkboxes: a ticket whose blockers are all `✓` but which is parked on an environment or another repo draws `○`, and picking it up would cost a planning round before discovering it can't start. If several rows are `●`, show the graph and ask which — the sizes and the chain depth behind each are what make that an informed answer rather than a coin toss. With no ticket set at all, work from the conversation.

Read `.scratch/context.md` if it exists and use its vocabulary in code, tests, and commit messages.

Read the code the work touches before planning it. Existing patterns beat new ones.

## 2. Plan it

Write the plan out either way — it's what you build against, and what lets the user catch a wrong turn early:

- **Scope** — the behaviour this pass delivers, and what you are leaving for later
- **Seams** — where each behaviour gets tested (a seam being where behaviour can be substituted without editing the code under test). If the spec fixed them, restate rather than reopen; otherwise propose the highest and fewest that work
- **Touch list** — the modules you expect to change, plus any prefactor to land first
- **Not TDD** — the parts you will build without a failing test first, and how you will verify them instead

Keep it to a list. Then judge whether the plan is yours or the work's, and act on that:

**Go ahead without waiting** when every line follows from what's written: the spec or ticket fixed the seams, the criteria are unambiguous, and the touch list falls out of the code you just read. A ticket is already an approved plan — asking the user to re-approve your restatement of it costs a round trip and buys nothing they didn't already decide. Post the plan and start building. Nothing is lost by moving: the user reads as you go, and the first commit is one green slice rather than the whole ticket.

**Stop and ask** when a line is a call you made rather than one the work handed you — a seam the spec left open where the plausible options differ in cost, scope you want to cut or add, a prefactor reaching outside the ticket, or a criterion with two readings that lead to different code. Name the choice and the options; that question is cheap, and work built on the wrong branch of it is what gets thrown away. If you can't tell which case you're in, that uncertainty *is* the ambiguity — ask.

Either way, build that scope and stop there; adjacent fixes and unrequested refactors belong in a follow-up.

## 3. Find the commands

Read `CLAUDE.md`, `Makefile`, `package.json` scripts, and pre-commit config to find three commands, then tell the user what you found:

- **typecheck** — the fastest whole-project correctness check (`tsc --noEmit`, `go build ./...`, `mypy`)
- **one test file** — how this project runs a single test file
- **the gate** — the one command CI treats as the bar (`make check`, `npm run lint`)

Guessing costs a wasted cycle. If the gate is genuinely ambiguous, ask once rather than assembling your own out of parts.

## 4. Build it red-green

At the agreed seams, for each behaviour:

1. **Red** — write the failing test and run it. Confirm it fails on the assertion you meant, not an import error or typo; a test that never failed proves nothing.
2. **Green** — the smallest change that passes it.
3. **Refactor** — clean up with the test still green.

Skip TDD where it doesn't pay — mechanical refactors, generated code, config, wide renames, a spike whose interface isn't known yet — and say which.

An awkward test is a design signal, not a licence to add a seam mid-flight. A new seam changes what the spec committed to, so agree it with the user first.

Do the work yourself: a subagent editing in parallel, or re-checking work you can check with the commands from step 3, costs more than it returns here. Step 6 is the one exception, and for a reason care can't substitute for.

### When the plan changes mid-build

Decisions move while code is being written — the user changes their mind, or the code proves a decision wrong. Route the change by its blast radius:

- **Contained to this ticket** — the behaviour this slice delivers shifts, but no other ticket, the graph, or a spec decision moves with it. Amend the ticket file directly: rewrite or add **unticked** criteria to match what is now agreed, leaving ticked ones alone — they record work already done. The ticket is already the live record this session ticks as it goes; amending it is the same motion. Say what changed in the close-out.
- **Wider than this ticket** — the change moves a spec decision, another ticket's behaviour, or the blocking graph. Finish the current red-green cycle so the branch is green, commit what's done, and stop: name what changed and hand the reshaping to `/cppcho:to-spec` (decision level) or `/cppcho:to-tickets` (ticket level), which owns superseding in-flight tickets. Building on a plan you know is stale wastes the work; reshaping the plan from inside one slice's context loses the view the reshaping needs.

Either way, never edit `spec.md` or any ticket other than the one being built. That boundary is what keeps a mid-build change graceful instead of sprawling.

## 5. Verify

Tightest loop first:

- **typecheck** after each red-green cycle
- **the one test file** you are working in during the loop, not the suite
- at the end, once: **the suite scoped to your changed files**, then **the gate**

Fix and re-run until both pass. Reaching green by deleting an assertion, skipping a test, or loosening lint and type config hides the failure rather than fixing it. If a failure looks legitimate — the spec is wrong, or an existing test contradicts it — don't code around it: treat it as a plan change and route it by blast radius, as above.

## 6. Read the comments with fresh eyes

Once the gate is green, hand the diff to a general-purpose subagent that has not seen this session and let it fix the comments that don't hold up. It needs to edit, so a read-only explorer won't do.

Delegate rather than rereading your own work, because the failure mode is memory, not inattention, and neither leak is visible from the inside. The obvious one is narration: you write "kept flat because nesting broke the encoder" because you remember trying nesting, and a reader holding only the diff has nowhere to get that sentence from. The subtler one does more damage — your intent hardens into a claim the code never makes. Having decided that construction goes through `NewLog`, you write "every Log must come from NewLog"; it reads as documentation, but nothing enforces it and `Log{}` still compiles. You believe it, so you can't audit it. A fresh reader believes nothing yet, so it checks.

So send the diff and nothing else. No plan, no ticket, no what-you-tried — every line of context you add is a line that can get laundered back into a comment. `git diff $(git merge-base HEAD <base-branch>)` gives it committed slices and working tree in one range; on the default branch, where that range is empty, pass the session's own commits instead. A diff isn't history-free — it shows one step of change, so it can still narrate *that*, and it should be told to describe the code as though it had always been this way. What the diff does hide is the churn inside the branch, which is exactly the history CLAUDE.md calls worthless.

Prompt it roughly like this:

```
Review only the comments in this diff — <diff command>.
You have no context on how this code was written, and you don't need any.

Read the "Code Comments" section of ~/.claude/CLAUDE.md and any comment
conventions in the repo's CLAUDE.md, then hold every comment the diff adds
or sits next to against them — for truth first, then for length. Fix what
breaks them, in the files. Then report each edit as file:line — what it
said, what it says now, and which rule it broke. Finding nothing to fix is
a real answer; say so rather than reaching for a change to justify the pass.
```

It edits directly rather than handing you a list, because the rewrite needs the same fresh eyes the finding did — routing it back through you puts the history-holder in charge of the wording again.

Three things worth telling it, since wordiness isn't the only way a comment fails and a reader with a mandate to cut will otherwise overshoot:

- **A comment can be wrong, not just wordy** — and a false one is worse than a verbose one, because a reader trusts it. An invariant nothing enforces, a bound that stopped matching the constant, a documented return the function no longer produces. It's holding the code the comment describes, so it can settle these by reading rather than guessing. Have it correct the claim rather than cut it where it can: the sentence exists because someone thought the fact mattered, and a true version of it usually still does.
- **A comment carrying a real "why" gets tightened, not deleted.** The rule is against paragraphs and restatement, not against explanation; the load-bearing sentence is the one thing prose can do that code can't. Comments on unchanged lines next to your edits are in scope — CLAUDE.md asks for those tightened rather than matched in length — but code the diff doesn't touch is not.
- **Directives are not comments.** `//go:build`, `//go:generate`, `//nolint`, `# type: ignore`, `# noqa`, `eslint-disable`, JSDoc types, annotation pragmas — these are syntax wearing a comment's clothes, and deleting one changes behaviour or breaks the build. Leave every line that a tool reads exactly as it is.

That last hazard is why the pass ends with **typecheck and the gate again**. Comment edits look inert and mostly are, but a stripped pragma fails loudly and it's cheaper to find here than after the commit. Fold the fixes into the slice's commit and name them in the close-out.

## 7. Commit

Tick the acceptance criteria you satisfied in the ticket file, then commit to the **current branch** with the `cppcho:commit` skill — one commit per slice as it goes green, not one batch at the end. No new branch, no push.

Then record where the work went, as the ticket's last header line — below **Spec**, above the criteria:

```
**Branch:** `feat/pc-exchange` [#1234](https://github.com/acme/billing-api/pull/1234)
```

`.scratch` is symlinked into every worktree, so one shared ticket set is read from every branch and nothing in it otherwise says which branch a slice's code is sitting on. That's the line's job: the next session, handed the ticket downstream of this one, learns whether to stack on this branch or look for merged code.

Read the current branch and append it if it isn't already listed. If it is listed but carries no PR, ask `gh pr view <branch> --json number,url` and fill the PR in — that re-check is what lets the line complete itself on a later slice without a separate motion. Then:

- **Append, never rewrite.** Existing entries stay as written and in order, joined with ` · `. A ticket spanning an expand and its migrate batches carries both branches, and the old entry is the record of work that actually happened.
- **Use `[#1234](url)` — number for reading, URL for clicking.** When the PR sits in a different repo from the ticket set, write `[owner/repo#1234](url)` so the cross-repo hop is visible without following the link.
- **Record identity, never merge state.** A `merged` written once and left is the record that drifts, and it wins arguments it shouldn't; anyone who needs the state asks `gh` when they ask.
- **Say nothing when there's nothing to say.** No PR yet, `gh` unauthed, no network — record the branch alone and move on. The next close-out fixes it for free, so a warning here is noise on the common path.
- **Skip the line entirely** on the default branch, where no PR is coming and the branch name tells the reader nothing, and when the work has no ticket file — the close-out prose already names the branch.

Then redraw the set with the `cppcho:ticket-dag` skill. The ticks you just made flip this ticket to `✓` and can release several others to `●`, and what a finished slice unblocks is the one thing the user can't read off the diff. It's also the cheapest check on your own bookkeeping: a criterion the work satisfied but you forgot to tick leaves the row reading `◐`, and a row still `○` behind a ticket you just finished means an edge is wrong.

Close with the outcome first: what landed, what you left out, where you diverged from the plan, and the ticket the graph points at next.
