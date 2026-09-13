---
name: implement
description: Implements the work a spec or ticket describes, TDD at agreed seams, runs the repo's gate, reviews the diff and drives it at runtime, has a fresh pair of eyes tighten the comments, and commits to the current branch. Use when building work that has already been specced or ticketed.
argument-hint: "[spec-or-ticket-path|ticket-id]"
---

# Implement

Build what a spec or ticket describes. Plan before touching code, check the plan with the user only where it rests on a decision the work didn't already make, then run to completion red-green at the agreed seams.

Track progress with this checklist:

```
- [ ] Read the work — and check the ticket is still true of the code
- [ ] Plan it — commands included; stop only if a call in it is yours
- [ ] Build it red-green
- [ ] Verify: suite on changed files, then the gate
- [ ] Review it — `/code-review medium`, trace each finding, then drive it with `run`
- [ ] Check the comments — `cppcho:check-comments` on the diff
- [ ] Commit — tick the criteria, record the branch it went to
```

## 1. Read the work

If the user passed a reference — `.scratch/epics/<PREFIX>-<slug>/spec.md`, a ticket id like `PCE-03`, an issue URL — read its full body.

With no argument, draw the local epic with the `cppcho:ticket-dag` skill and take the **frontier** from it: a 🟢 row — blockers all done, no **Superseded** line retiring it, nothing outside the graph parking it. Drawing beats scanning the directory yourself because 🟢 is this frontier rule applied to every ticket at once, so the pick becomes visible to the user instead of a choice made silently in your head. It's also stricter than counting checkboxes: a ticket whose blockers are all ✅ but which is parked on an environment or another repo draws 🔴, and picking it up would cost a planning round before discovering it can't start. If several rows are 🟢, show the graph and ask which — the sizes and the chain depth behind each are what make that an informed answer rather than a coin toss. With no epic at all, work from the conversation.

Then check the ticket is still true before planning against it: `/cppcho:reconcile <ticket-id>`. A ticket is a claim about the codebase made on the day it was cut, and parallel epics land code underneath it — the expensive failure is planning and building a slice another epic already delivered. Anything but a `fresh` verdict stops here: report it and hand the reshaping to `/cppcho:to-tickets` rather than building against a ticket you now know is stale. One ticket's worth of checking, at the one moment it pays for itself.

Read `.scratch/context.md` if it exists and use its vocabulary in code, tests, and commit messages.

Read the code the work touches before planning it. Existing patterns beat new ones.

## 2. Plan it

Write the plan out either way — it's what you build against, and what lets the user catch a wrong turn early:

- **Scope** — the behaviour this pass delivers, and what you are leaving for later
- **Seams** — where each behaviour gets tested (a seam being where behaviour can be substituted without editing the code under test). If the spec fixed them, restate rather than reopen; otherwise propose the highest and fewest that work
- **Touch list** — the modules you expect to change, plus any prefactor to land first
- **Not TDD** — the parts you will build without a failing test first, and how you will verify them instead
- **Commands** — the three you will build against, read off `CLAUDE.md`, `Makefile`, `package.json` scripts and pre-commit config: **typecheck**, the fastest whole-project correctness check (`tsc --noEmit`, `go build ./...`, `mypy`); **one test file**, how this project runs a single one; and **the gate**, the one command CI treats as the bar (`make check`, `npm run lint`). Guessing one costs a wasted cycle, and they belong in the plan because the plan is where the user can see a wrong one before it burns that cycle. If the gate is genuinely ambiguous, ask once rather than assembling your own out of parts

Keep it to a list. Then judge whether the plan is yours or the work's, and act on that:

**Go ahead without waiting** when every line follows from what's written: the spec or ticket fixed the seams, the criteria are unambiguous, and the touch list falls out of the code you just read. A ticket is already an approved plan — asking the user to re-approve your restatement of it costs a round trip and buys nothing they didn't already decide. Post the plan and start building. Nothing is lost by moving: the user reads as you go, and the first commit is one green slice rather than the whole ticket.

**Stop and ask** when a line is a call you made rather than one the work handed you — a seam the spec left open where the plausible options differ in cost, scope you want to cut or add, a prefactor reaching outside the ticket, or a criterion with two readings that lead to different code. Name the choice and the options in the work's own terms — concrete modules and behaviours, not skill vocabulary like "seam"; that question is cheap, and work built on the wrong branch of it is what gets thrown away. If you can't tell which case you're in, that uncertainty *is* the ambiguity — ask.

Either way, build that scope and stop there; adjacent fixes and unrequested refactors belong in a follow-up.

## 3. Build it red-green

At the agreed seams, for each behaviour:

1. **Red** — write the failing test and run it. Confirm it fails on the assertion you meant, not an import error or typo; a test that never failed proves nothing.
2. **Green** — the smallest change that passes it.
3. **Refactor** — clean up with the test still green.

**A test that passes the first time you run it is the failure mode to catch here**, and it is easy to miss because it looks like success. It means one of two things: you wrote the code before the test, or the assertion doesn't reach the behaviour. Either way the test is now unproven, and an unproven test is worse than no test — it will sit there reporting green over a regression. So don't accept it and move on. Break the line of production code the test is supposed to be pinning — invert the comparison, return the zero value, drop the guard — and confirm the test goes red on the assertion you meant, then put it back. That is one command, and it buys the red you skipped.

When you break the line and the test *still* passes, suspect your break before you suspect the test. A mutation that didn't change behaviour — an aliased slice you edited a copy of, a constant that feeds two paths, a branch the fixture never enters — proves nothing either way, and reading it as "the test is weak" sends you rewriting a test that was fine. Make the mutation big enough to be obvious: return the zero value, delete the call, invert the whole condition.

Say so plainly when it happens. Three weak tests got through a green gate this way: one asserted a batch size against the same constant the code used, one asserted ordering against a fixture that was already sorted, and one asserted a button was disabled by matching a string that a CSS rule also contained. All three passed on the first run.

Skip TDD where it doesn't pay — mechanical refactors, generated code, config, wide renames, a spike whose interface isn't known yet — and say which.

An awkward test is a design signal, not a licence to add a seam mid-flight. A new seam changes what the spec committed to, so agree it with the user first.

Write comments under the same test step 6 will apply: a comment stays only if you can name the specific wrong conclusion a reader draws without it. Narration of what the code does, restated field meanings, guard justifications the error message already states, and failure stories ("which would otherwise…") fail that test — they just feed the step-6 delete pass, so don't write them in the first place.

Do the work yourself: a subagent editing in parallel, or re-checking work you can check with the commands from the plan, costs more than it returns here. The review in step 5 and the comment pass in step 6 are the exceptions, and each for a reason care can't substitute for.

### When the plan changes mid-build

Decisions move while code is being written — the user changes their mind, or the code proves a decision wrong. Route the change by its blast radius:

- **Contained to this ticket** — the behaviour this slice delivers shifts, but no other ticket, the graph, or a spec decision moves with it. Amend the ticket file directly: rewrite or add **unticked** criteria to match what is now agreed, leaving ticked ones alone — they record work already done. The ticket is already the live record this session ticks as it goes; amending it is the same motion. Say what changed in the close-out.
- **Wider than this ticket** — the change moves a spec decision, another ticket's behaviour, or the blocking graph. Finish the current red-green cycle so the branch is green, commit what's done, and stop: name what changed and hand the reshaping to `/cppcho:to-spec` (decision level) or `/cppcho:to-tickets` (ticket level), which owns superseding in-flight tickets. Building on a plan you know is stale wastes the work; reshaping the plan from inside one slice's context loses the view the reshaping needs.

Either way, never edit `spec.md` or any ticket other than the one being built. That boundary is what keeps a mid-build change graceful instead of sprawling.

## 4. Verify

Tightest loop first:

- **typecheck** after each red-green cycle
- **the one test file** you are working in during the loop, not the suite
- at the end, once: **the suite scoped to your changed files**, then **the gate**

Fix and re-run until both pass. Reaching green by deleting an assertion, skipping a test, or loosening lint and type config hides the failure rather than fixing it. If a failure looks legitimate — the spec is wrong, or an existing test contradicts it — don't code around it: treat it as a plan change and route it by blast radius, as above.

## 5. Review it

A green gate answers a narrower question than it feels like it answers: the code compiles and the tests you wrote agree with the code you wrote. It says nothing about whether the code is right, and nothing about whether it runs. Both of those have to be asked separately, and this step asks them — once per invocation, over everything the session built, immediately before the last commit.

Once, not per slice. `/code-review`'s default target is `@{upstream}...HEAD` plus a sweep of the working tree, so a single pass at the end already covers every slice this session committed and anything still uncommitted. Reviewing each slice as it lands would re-read the same diff three times for one ticket, and the tax is what makes a step like this quietly get skipped.

**Hand it an explicit range whenever the branch has no upstream**, which is the normal case for a first slice: `<base-branch>...HEAD`, the same range the comment pass uses. A branch that was never pushed has no `@{upstream}` to resolve, and by this point the slices are committed, so the working tree is clean too — leaving the default to find an empty diff and report nothing. Check with `git rev-parse --abbrev-ref '@{upstream}'` and pass the range when it errors.

**Pass the absolute path of the repo in the args, alongside the range.** The review forks to run, and the fork does not reliably inherit your working directory — it lands in the session's own, which on a worktree or a nested checkout is a different repository. Naming the path is what pins it.

**Then check the review actually saw your diff, because "0 findings" and "reviewed nothing" are the same sentence.** Confirm the files it names are the files you changed — `git diff --name-only <range>` against what the report covered. This is not a formality. Left unpinned, the fork reviews whatever tree it landed in and returns confident, specific, correct-looking findings **about that other repository** — file, line, and a plausible failure scenario, none of it about your work. That is worse than an empty result, because an empty result at least looks like nothing happened. Three separate causes produce the same quiet symptom: no upstream to resolve, `HEAD` already equal to the base, and the fork landing elsewhere.

### The diff reads right

Invoke the built-in `code-review` skill through the Skill tool at **medium**. Medium is tuned for precision — it targets a handful of findings it can stand behind — and that is the right trade for one tracer-bullet slice, where a recall-tuned pass would hand back a page of maybes on a three-file diff and you would learn to ignore it. Reach for `high` when the slice touches money, persisted state, concurrency, or anything whose failure is silent.

**Ask for the findings and nothing else: "Report the findings only. Post nothing, change nothing."** Say it positively like that. The built-in skill decides whether its posting and fixing flags were passed by scanning the whole argument string for their names, so a sentence telling it not to post is what turns posting on. Don't name those flags anywhere in the invocation — not even to forbid them.

Tell it the comments are not its job; step 6 owns those. One of its angles reads `CLAUDE.md`, which is where the comment rules live, so left alone it will spend findings on prose that a dedicated pass is about to rewrite anyway.

While it runs, don't poll it. You are re-invoked when it finishes, so a `sleep`, a watch loop, or a turn spent saying you are still waiting costs tokens and buys nothing — and the loops outlive the wait, still draining after you have reported. Either spend the time on something that doesn't depend on the findings, or stop and let the notification wake you.

**Know what a clean review does and doesn't tell you.** It reasons about the delta — what this diff introduces — so it is good at catching what you just broke and weak at catching what was already broken on a line you merely touched. Measured behaviour, not speculation: on a handler where the query parser silently discarded malformed input and served every row to a caller who asked to narrow the list, the review looked straight at the line and cleared it as "behavior-preserving" — which was true of the refactor and useless about the bug. Running the review at a higher effort does not fix this; the fleet gets bigger, the frame stays the same. So a quiet review means "this diff introduces nothing new", never "these lines are correct". The lines being correct is what the next half of this step is for.

Then trace each finding in the code before you touch anything. This is the half that makes the pass worth running: a finding survives only when you can walk the failure step by step — which branch runs, what the call returns, what runs first — and it dies only when you can trace the code doing the right thing. Neither "it sounds plausible" nor "I meant to do that" settles it. Fix what survives, and for what doesn't, say which and why in a line each; don't argue with a dead finding at length. Then re-run the gate, because you just changed code.

### The diff runs right

Now drive it, with the `run` skill. The gate and the review both read the code; this step runs it — it launches the app and drives it to where the changed code executes, so what you report is something you watched happen rather than something the tests imply. Don't hand it the suite; tests are step 4's job and re-running them here buys nothing the gate didn't already give you.

Reach for `run` and not `/verify`. `/verify` covers the same ground and covers it better, but it is user-invocable only — the Skill tool refuses it and tells you not to replicate it, so a step built on it silently does nothing. When the change deserves that deeper pass, say so in the close-out and let the user type `/verify` themselves; that is a one-line offer, not a blocked step.

This is the step that earns its place on evidence. A slice went out with a green gate, a clean review and a clean comment pass, and driving the UI immediately showed that filtering a list reported "capped at 2" when the cap was not what hid the rows — a real bug that the unit tests and a `curl` both missed, because each tested function was right and only their combination was wrong. Another slice passed a green local gate and then failed CI three times on environment and build-ordering faults the gate never touched.

Skip it — and only it — when the diff has no runtime surface to drive: tests only, docs only, config with nothing reading it, a mechanical rename. A change to product source always has a surface. Say you skipped it and name the files that make the diff surface-free, so the close-out doesn't read as though it ran.

`/code-review` may try to chain into `/verify` itself when it judges the diff has a runtime surface, and hit the same refusal. That's not a failure to work around — it just means the drive is yours to do here. State plainly whether you drove the code and what you observed, because a verification everyone assumes happened is worse than one nobody claims.

### Why this comes before the comments

Fixing a review finding changes code. The comment pass in step 6 rewrites comments to describe the **final** state, so running it before the last code change guarantees some of its work describes a state that no longer exists — and those are the comments least likely to get a second look, because they were just carefully tightened. Review first, fix, re-gate, then comments. That order is the whole reason these are two steps and not one.

## 6. Check the comments

Once the review is settled and the gate is green again, read the `cppcho:check-comments` skill and follow it over the diff this session produced. Don't improvise the pass from this step: the rules it applies, the diff range to use, and the guards that stop a fresh reader stripping comments that were pulling their weight all live there.

Same rule as the review while it runs: no `sleep`, no watch loop, no turn spent narrating the wait. The notification wakes you.

The one thing to carry in from here is why you don't do it yourself. The comments you can't audit are your own — you believe them, which is exactly what makes them invisible. So let it delegate, and don't brief that reader on the plan, the ticket, or what you tried; every line of that is a line it can launder back into a comment.

Fold its fixes into the slice's commit and name them in the close-out in a line or two.

## 7. Commit

Tick the acceptance criteria you satisfied in the ticket file, then commit to the **current branch** with the `cppcho:commit` skill — one commit per slice as it goes green, not one batch at the end. No new branch, no push.

Then record where the work went, as the ticket's last header line — below **Spec**, above the criteria:

```
**Branch:** `feat/pc-exchange` [#1234](https://github.com/acme/billing-api/pull/1234)
```

`.scratch` is symlinked into every worktree, so one shared epic is read from every branch and nothing in it otherwise says which branch a slice's code is sitting on. That's the line's job: the next session, handed the ticket downstream of this one, learns whether to stack on this branch or look for merged code.

Read the current branch and append it if it isn't already listed. If it is listed but carries no PR, ask `gh pr view <branch> --json number,url` and fill the PR in — that re-check is what lets the line complete itself on a later slice without a separate motion. Then:

- **Append, never rewrite.** Existing entries stay as written and in order, joined with ` · `. A ticket spanning an expand and its migrate batches carries both branches, and the old entry is the record of work that actually happened.
- **Use `[#1234](url)` — number for reading, URL for clicking.** When the PR sits in a different repo from the epic, write `[owner/repo#1234](url)` so the cross-repo hop is visible without following the link.
- **Record identity, never merge state.** A `merged` written once and left is the record that drifts, and it wins arguments it shouldn't; anyone who needs the state asks `gh` when they ask.
- **Say nothing when there's nothing to say.** No PR yet, `gh` unauthed, no network — record the branch alone and move on. The next close-out fixes it for free, so a warning here is noise on the common path.
- **Skip the line entirely** on the default branch, where no PR is coming and the branch name tells the reader nothing, and when the work has no ticket file — the close-out prose already names the branch.

Then redraw the epic with the `cppcho:ticket-dag` skill. The ticks you just made flip this ticket to ✅ and can release several others to 🟢, and what a finished slice unblocks is the one thing the user can't read off the diff. It's also the cheapest check on your own bookkeeping: a criterion the work satisfied but you forgot to tick leaves the row reading 🟡, and a row still 🔴 behind a ticket you just finished means an edge is wrong.

When the redraw comes back with **every** row ✅, say so and offer to close the epic out — `/cppcho:to-tickets` archives it once the PRs have merged. Offer rather than do: this slice's PR is almost certainly still open, and an epic archived before review comes back has to be dragged out again. But make the offer here, because this is the last moment the epic's being finished is in front of anyone; miss it and it lingers in every later sweep, competing with live work.

Close with the outcome first: what landed, what you left out, where you diverged from the plan, and the ticket the graph points at next.

Name the review and the drive in that close-out: `/code-review` by literal name with whether it ran, and for the drive, what you actually launched and what you saw it do — or that you skipped it, and which files make the diff surface-free. Your own tests, the typecheck and the gate are not a substitute for either, and neither is the belief that the diff looked fine. A token budget, a background run, or a request to ship quickly is not a reason to skip one; the user saying "don't review this" is, and then quote them. This line exists because the two most expensive defects these sessions produced were both found after a close-out that read as though the work was verified.

Offer `/verify` here when the change earns a deeper runtime pass than you could drive yourself — anything touching money, persisted state, or a flow with several services in it. One line, and the user decides.
