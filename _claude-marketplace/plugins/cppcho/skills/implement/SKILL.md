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
- [ ] Check the comments — `cppcho:check-comments` on the diff
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

Do the work yourself: a subagent editing in parallel, or re-checking work you can check with the commands from step 3, costs more than it returns here. The comment pass in step 6 is the one exception, and for a reason care can't substitute for.

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

## 6. Check the comments

Once the gate is green, read the `cppcho:check-comments` skill and follow it over the diff this session produced. Don't improvise the pass from this step: the rules it applies, the diff range to use, and the guards that stop a fresh reader stripping comments that were pulling their weight all live there.

The one thing to carry in from here is why you don't do it yourself. The comments you can't audit are your own — you believe them, which is exactly what makes them invisible. So let it delegate, and don't brief that reader on the plan, the ticket, or what you tried; every line of that is a line it can launder back into a comment.

Fold its fixes into the slice's commit and name them in the close-out in a line or two.

## 7. Commit

Tick the acceptance criteria you satisfied in the ticket file, then commit to the **current branch** with the `cppcho:commit` skill — one commit per slice as it goes green, not one batch at the end. No new branch, no push.

Then record where the work went, as the ticket's last header line — below **Spec**, above the criteria:

```
**Branch:** `feat/vg-exchange` [#1234](https://github.com/kouzoh/foo/pull/1234)
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
