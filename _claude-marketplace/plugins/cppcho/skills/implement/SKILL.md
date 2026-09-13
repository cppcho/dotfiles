---
name: implement
description: Implements the work a spec or ticket describes, TDD at agreed seams, runs the repo's gate, reviews the diff and drives it at runtime, has a fresh pair of eyes tighten the comments, and commits — branching, pushing and opening the PR when the work asks for it. Use when building work that has already been specced or ticketed.
argument-hint: "[spec-or-ticket-path|ticket-id] [in a worktree] [create a pr]"
---

# Implement

**Skill revision: 2026-09-13b.** Say this revision in the close-out. Nothing else in a transcript records which snapshot of this skill actually ran, and an audit that can't tell a broken instruction from an uninstalled one is worth nothing — the review step below spent twelve hours committed but uninstalled, and six runs in that window looked like they were ignoring it.

Build what a spec or ticket describes. Plan before touching code, check the plan with the user only where it rests on a decision the work didn't already make, then run to completion red-green at the agreed seams.

**Write this checklist out with `TodoWrite` as your first action, and tick each item as you finish it.** Not as prose you read once — as the actual list, because that is the only form of it that survives. Left in the prose, these seven lines get read at invocation and never again, and the late steps quietly evaporate as the run grows: measured across 118 runs, the review, the comment pass and the commit skill each went missing in a third to a half of them, while nothing in the transcript ever showed a step being refused. They weren't refused. They were forgotten.

```
- [ ] Read the work — check the ticket is still true, and note what the invocation asks for
- [ ] Plan it — commands included; ask if a call is yours, hand back if the ticket isn't decided
- [ ] Build it red-green — get something compiling early
- [ ] Verify: suite on changed files, then the gate
- [ ] Review it — `/code-review medium`, trace each finding, then drive it with `run`
- [ ] Check the comments — `cppcho:check-comments` on the diff
- [ ] Commit — tick the criteria, record the branch, then push and open the PR if asked
```

## 1. Read the work

If the user passed a reference — `.scratch/epics/<PREFIX>-<slug>/spec.md`, a ticket id like `PCE-03`, an issue URL — read its full body.

**Read the rest of the invocation too, and carry it to step 7.** "in a worktree", "create a pr", "onto main", "stack on #5183" are instructions about where the work lands, and they arrive here but are needed at the end. Note them in the plan so they don't get lost across a long run; two runs in three carry one.

With no argument, draw the local epic with the `cppcho:ticket-dag` skill and take the **frontier** from it: a 🟢 row — blockers all done, no **Superseded** line retiring it, nothing outside the graph parking it. Drawing beats scanning the directory yourself because 🟢 is this frontier rule applied to every ticket at once, so the pick becomes visible to the user instead of a choice made silently in your head. If several rows are 🟢, show the graph and ask which — the sizes and the chain depth behind each are what make that an informed answer rather than a coin toss. With no epic at all, work from the conversation.

Then check the ticket is still true before planning against it: `/cppcho:reconcile <ticket-id>`. A ticket is a claim about the codebase made on the day it was cut, and parallel epics land code underneath it — the expensive failure is planning and building a slice another epic already delivered. Anything but a `fresh` verdict stops here: report it and hand the reshaping to `/cppcho:to-tickets`.

Read `.scratch/context.md` if it exists and use its vocabulary in code, tests, and commit messages.

**Read enough of the code to plan, not all of it.** Existing patterns beat new ones, so you do need to see how this area works — but the surface you'll touch is cheaper to learn while building it than to survey first. A median run spends sixty turns, more than a third of its length, before the first thing compiles; cost here is turns multiplied by context, so every turn spent reading ahead of the plan also makes every later turn dearer. Read the seams and the nearest neighbours; leave the rest for step 3.

## 2. Plan it

Write the plan out either way — it's what you build against, and what lets the user catch a wrong turn early:

- **Scope** — the behaviour this pass delivers, and what you are leaving for later
- **Seams** — where each behaviour gets tested (a seam being where behaviour can be substituted without editing the code under test). If the spec fixed them, restate rather than reopen; otherwise propose the highest and fewest that work
- **Touch list** — the modules you expect to change, plus any prefactor to land first
- **Not TDD** — the parts you will build without a failing test first, and how you will verify them instead
- **Landing** — the branch this goes to, and whether a worktree, a push or a PR was asked for (from the invocation, per step 1)
- **Commands** — the three you will build against, read off `CLAUDE.md`, `Makefile`, `package.json` scripts and pre-commit config: **typecheck**, the fastest whole-project correctness check (`tsc --noEmit`, `go build ./...`, `mypy`); **one test file**, how this project runs a single one; and **the gate**, the one command CI treats as the bar (`make check`, `npm run lint`). Guessing one costs a wasted cycle, and they belong in the plan because the plan is where the user can see a wrong one before it burns that cycle. If the gate is genuinely ambiguous, ask once rather than assembling your own out of parts

Keep it to a list. Then judge which of three situations you are in, and act on it:

**Go ahead without waiting** when every line follows from what's written: the spec or ticket fixed the seams, the criteria are unambiguous, and the touch list falls out of the code you just read. A ticket is already an approved plan — asking the user to re-approve your restatement of it costs a round trip and buys nothing they didn't already decide. Post the plan and start building.

**Stop and ask** when a line is a call you made rather than one the work handed you — a seam the spec left open where the plausible options differ in cost, scope you want to cut or add, a prefactor reaching outside the ticket, or a criterion with two readings that lead to different code. Name the choice and the options in the work's own terms — concrete modules and behaviours, not skill vocabulary like "seam"; that question is cheap, and work built on the wrong branch of it is what gets thrown away.

**Hand it back** when the ticket isn't decided yet. This is the third case and the one that costs the most when it's missed: not a ticket that's *stale* — step 1's reconcile pass catches those — but one whose criteria rest on a question nobody has answered, so there is no single build that satisfies them. The tell is that you can't write the Scope line without inventing the decision, or that the answer would change which modules you touch rather than how you touch them. Say what's undecided, name `/cppcho:brainstorm` (open question) or `/cppcho:to-spec` (a decision to record), and **stop**. Don't open the build loop and negotiate from inside it.

That instruction is written against the most expensive failure in this skill's history. Five runs entered the build loop on an undecided ticket and turned into design sessions — 860 turns arguing test parallelism against runner memory and ending with the ticket parked; 276 turns iterating a design document with no implementation in it at all. Those five runs and their kin are a third of everything this skill has ever spent. "Stop and ask" cannot reach them, because it asks one question and then builds; the answer to an undecided ticket isn't a question, it's a different skill.

Either way, build that scope and stop there; adjacent fixes and unrequested refactors belong in a follow-up.

## 3. Build it red-green

**Get something compiling and running inside the first handful of turns** — the first red test, or the prefactor, or the typecheck over a stub. Not a fully read codebase and a perfect plan first. The point of a tracer bullet is that it flies early and tells you where it lands.

At the agreed seams, for each behaviour:

1. **Red** — write the failing test and run it. Confirm it fails on the assertion you meant, not an import error or typo; a test that never failed proves nothing.
2. **Green** — the smallest change that passes it.
3. **Refactor** — clean up with the test still green.

**A test that passes the first time you run it is unproven**, and it's easy to miss because it looks like success. Either you wrote the code before the test, or the assertion doesn't reach the behaviour — and an unproven test will sit there reporting green over a regression. Break the line of production code it's supposed to be pinning — return the zero value, delete the call, invert the whole condition — confirm it goes red on the assertion you meant, then put it back. If it still passes, suspect your break before the test: make the mutation bigger rather than rewriting a test that was fine.

Skip TDD where it doesn't pay — mechanical refactors, generated code, config, wide renames, a spike whose interface isn't known yet — and say which.

An awkward test is a design signal, not a licence to add a seam mid-flight. A new seam changes what the spec committed to, so agree it with the user first.

Write comments under the same test step 6 will apply: a comment stays only if you can name the specific wrong conclusion a reader draws without it. Narration of what the code does, restated field meanings, guard justifications the error message already states, and failure stories ("which would otherwise…") fail that test — they just feed the step-6 delete pass, so don't write them in the first place.

Do the work yourself: a subagent editing in parallel, or re-checking work you can check with the commands from the plan, costs more than it returns here. The review in step 5 and the comment pass in step 6 are the exceptions, and each for a reason care can't substitute for.

### When the plan changes mid-build

Decisions move while code is being written — the user changes their mind, or the code proves a decision wrong. Route the change by its blast radius:

- **Contained to this ticket** — the behaviour this slice delivers shifts, but no other ticket, the graph, or a spec decision moves with it. Amend the ticket file directly: rewrite or add **unticked** criteria to match what is now agreed, leaving ticked ones alone. Say what changed in the close-out.
- **Wider than this ticket** — the change moves a spec decision, another ticket's behaviour, or the blocking graph. Finish the current red-green cycle so the branch is green, commit what's done, and stop: name what changed and hand the reshaping to `/cppcho:to-spec` (decision level) or `/cppcho:to-tickets` (ticket level).

**Re-declare Not-TDD whenever you reroute.** The declaration in step 2 covered the plan you had then, and a reroute can quietly carry you from config plumbing into production code the original declaration was never about. One run declared Not-TDD for harness work, then seven hours later wrote a new sixty-nine-line production package, committed it with no tests, and never revisited the declaration — because nothing asked it to. So when the plan moves, say again which parts go without a failing test first and how you'll verify them instead, or write the test.

**Don't edit another ticket, and edit `spec.md` only when a criterion tells you to.** The boundary is what keeps a mid-build change graceful instead of sprawling — but it is not absolute, because a ticket can legitimately carry a criterion like "record the accommodation in the spec", and then the spec write *is* the deliverable rather than a plan reshape. When that happens, do it, and say in the close-out which criterion authorised it. What stays forbidden is editing `spec.md` to change a decision; that's `/cppcho:to-spec`'s job, and reaching for it yourself is how a slice turns into a reshape nobody reviewed.

## 4. Verify

Tightest loop first:

- **typecheck** after each red-green cycle
- **the one test file** you are working in during the loop, not the suite
- at the end, once: **the suite scoped to your changed files**, then **the gate**

Fix and re-run until both pass. Reaching green by deleting an assertion, skipping a test, loosening lint or type config, or **moving a date into the future so a time-dependent test stops failing** hides the failure rather than fixing it — that last one has shipped from here, and the test set it left behind starts failing again in 2029. If a failure looks legitimate — the spec is wrong, or an existing test contradicts it — don't code around it: treat it as a plan change and route it by blast radius, as above.

**The gate is not CI.** It's the closest local proxy, and once this work is pushed the real bar is the remote run — see step 7.

## 5. Review it

A green gate answers a narrower question than it feels like it answers: the code compiles and the tests you wrote agree with the code you wrote. It says nothing about whether the code is right, and nothing about whether it runs. Both of those have to be asked separately, and this step asks them — once per invocation, over everything the session built.

Once, not per slice. A single pass at the end covers every slice this session committed and anything still uncommitted. Reviewing each slice as it lands would re-read the same diff three times for one ticket, and the tax is what makes a step like this quietly get skipped.

**Work out what to hand it, because getting this wrong returns a confident review of nothing.** Check `git status --porcelain` and `git rev-parse --abbrev-ref '@{upstream}'` first, then:

- **Working tree dirty** — the normal case for a single-slice ticket, since step 7 commits as each slice goes green and the last slice hasn't been committed yet. Tell it the work is uncommitted and give it the changed file list; don't pass a range, because `<base>...HEAD` will be empty and it will review the void.
- **Everything committed, no upstream** — pass `<base-branch>...HEAD` explicitly. A branch that was never pushed has no `@{upstream}` to resolve, so the default finds nothing.
- **Everything committed with an upstream** — the default target is right.

**Pass the absolute path of the repo in the args, alongside whatever range or file list you settled on.** The review forks to run, and the fork does not reliably inherit your working directory — it lands in the session's own, which on a worktree or a nested checkout is a different repository. Naming the path is what pins it.

**Then run `git diff --name-only <range>` (or `git status --porcelain`) and quote its output against the files the report named.** Quote it — don't assert it. "0 findings" and "reviewed nothing" are the same sentence, and left unpinned the fork reviews whatever tree it landed in and returns confident, specific, correct-looking findings **about that other repository**. Reading the report and feeling reassured because it cites plausible line numbers is exactly the check failing: a mis-landed review cites plausible line numbers too. The first run to reach this step wrote "I confirmed it saw my diff — it cites my hunks by line" without ever running the command. Three causes produce the same quiet symptom: no upstream to resolve, `HEAD` already equal to the base, and the fork landing elsewhere.

### The diff reads right

Invoke the built-in `code-review` skill through the Skill tool at **medium**. Medium is tuned for precision — it targets a handful of findings it can stand behind — and that is the right trade for one tracer-bullet slice, where a recall-tuned pass would hand back a page of maybes on a three-file diff and you would learn to ignore it. Reach for `high` when the slice touches money, persisted state, concurrency, or anything whose failure is silent.

**Ask for the findings and nothing else: "Report the findings only. Post nothing, change nothing."** Say it positively like that. The built-in skill decides whether its posting and fixing flags were passed by scanning the whole argument string for their names, so a sentence telling it not to post is what turns posting on. Don't name those flags anywhere in the invocation — not even to forbid them.

Tell it two things are not its job: the comments, which step 6 owns, and the gate, which step 4 already banked. One of its angles reads `CLAUDE.md`, where the comment rules live, so left alone it spends findings on prose a dedicated pass is about to rewrite. And left alone it also re-runs `go test ./...` and the linter itself — a fifth of its token budget on the one question you already have a green answer to.

While it runs, don't poll it. You are re-invoked when it finishes, so a `sleep`, a watch loop, or a turn spent saying you are still waiting costs tokens and buys nothing — and the loops outlive the wait, still draining after you have reported. **When you genuinely need to wait on a condition, that's what `Monitor` is for**; naming it here because the measured failure isn't refusal but reaching for the wrong tool — nearly half of all runs have slept, and fewer than one in ten has used `Monitor`. Better still, spend the time on the drive below, which doesn't depend on the findings.

**Know what a clean review does and doesn't tell you.** It reasons about the delta — what this diff introduces — so it is good at catching what you just broke and weak at catching what was already broken on a line you merely touched. Measured: on a handler where the query parser silently discarded malformed input and served every row to a caller who asked to narrow the list, the review looked straight at the line and cleared it as "behavior-preserving" — true of the refactor and useless about the bug. Higher effort doesn't fix this; the fleet gets bigger, the frame stays the same. So a quiet review means "this diff introduces nothing new", never "these lines are correct".

Then trace each finding in the code before you touch anything. A finding survives only when you can walk the failure step by step — which branch runs, what the call returns, what runs first — and it dies only when you can trace the code doing the right thing. Neither "it sounds plausible" nor "I meant to do that" settles it. Fix what survives, and for what doesn't, say which and why in a line each. Then re-run the gate, because you just changed code.

### The diff runs right

Now drive it, with the `run` skill. The gate and the review both read the code; this step runs it — it launches the app and drives it to where the changed code executes, so what you report is something you watched happen rather than something the tests imply. Don't hand it the suite; tests are step 4's job.

**Name the surface, because "drive it" alone reaches for a local process and these repos mostly aren't one.** Three shapes come up:

- **A local binary or CLI** — build it and run it against throwaway infrastructure: an ephemeral emulator, stand-in servers on loopback so nothing reaches a real third party, a seeded row. Report the log lines you actually saw.
- **A browser app** — drive it with the chrome-devtools MCP tools, on the real page, clicking what a user clicks. `run` will happily start a dev server and call that driving; it isn't. Every time this was left vague the user came back with "check with mcp chrome and verify it end to end" — one of them three times in a row.
- **A remote dev service behind auth** — hit the real endpoint in the dev environment with correct mock user data, not a port-forward and not a local stub. This needs the service router hostname for the PR's deployment and a real token; ask for what you're missing rather than substituting something local and calling it end to end.

This is the step that earns its place on evidence. A slice went out with a green gate, a clean review and a clean comment pass, and driving the UI immediately showed that filtering a list reported "capped at 2" when the cap was not what hid the rows — a real bug the unit tests and a `curl` both missed, because each tested function was right and only their combination was wrong. A different slice shipped a shared-client design with a green gate and a green CI, and seven hours later the user rejected its shape — the route had been agreed, the shape had never been put in front of anyone.

Reach for `run` and not `/verify`. `/verify` covers the same ground better, but it is user-invocable only — the Skill tool refuses it and tells you not to replicate it, so a step built on it silently does nothing. When the change deserves that deeper pass, say so in the close-out and let the user type `/verify` themselves.

Skip the drive — and only it — when the diff has no runtime surface: tests only, docs only, config with nothing reading it, a mechanical rename. A change to product source always has a surface. Say you skipped it and name the files that make the diff surface-free, so the close-out doesn't read as though it ran.

### Why this comes before the comments

Fixing a review finding changes code. The comment pass in step 6 rewrites comments to describe the **final** state, so running it before the last code change guarantees some of its work describes a state that no longer exists — and those are the comments least likely to get a second look, because they were just carefully tightened. Review first, fix, re-gate, then comments.

## 6. Check the comments

Once the review is settled and the gate is green again, read the `cppcho:check-comments` skill and follow it over the diff this session produced. Don't improvise the pass from this step: the rules it applies, the diff range to use, and the guards that stop a fresh reader stripping comments that were pulling their weight all live there.

The one thing to carry in from here is why you don't do it yourself. The comments you can't audit are your own — you believe them, which is exactly what makes them invisible. So let it delegate, and don't brief that reader on the plan, the ticket, or what you tried; every line of that is a line it can launder back into a comment.

Fold its fixes into the slice's commit and name them in the close-out in a line or two.

## 7. Commit, and land it

Tick the acceptance criteria you satisfied in the ticket file, then commit to the **current branch** with the `cppcho:commit` skill — one commit per slice as it goes green, not one batch at the end.

**Then land the work where the invocation said it goes.** Create the worktree, push the branch, open the PR, stack it on the base it named — whatever step 1 recorded in the plan's **Landing** line, plus anything the user has asked for since. Don't stop at a local commit and wait to be asked: `create pr` and `commit and push` are the most common things typed after this skill runs, three runs in five want one of them, and "wheres the pr" is what it sounds like when this step holds back. With nothing asked and no convention in the repo pointing one way, commit and say plainly what you didn't do, so the next instruction is one word rather than a discovery.

Then record where the work went, as the ticket's last header line — below **Spec**, above the criteria:

```
**Branch:** `feat/pc-exchange` [#1234](https://github.com/acme/billing-api/pull/1234)
```

`.scratch` is symlinked into every worktree, so one shared epic is read from every branch and nothing in it otherwise says which branch a slice's code is sitting on. That's the line's job: the next session, handed the ticket downstream of this one, learns whether to stack on this branch or look for merged code.

Read the current branch and append it if it isn't already listed. If it is listed but carries no PR, ask `gh pr view <branch> --json number,url` and fill the PR in. Then:

- **Append, never rewrite.** Existing entries stay as written and in order, joined with ` · `. A ticket spanning an expand and its migrate batches carries both branches, and the old entry is the record of work that actually happened.
- **Use `[#1234](url)` — number for reading, URL for clicking.** When the PR sits in a different repo from the epic, write `[owner/repo#1234](url)` so the cross-repo hop is visible without following the link.
- **Record identity, never merge state.** A `merged` written once and left is the record that drifts, and it wins arguments it shouldn't; anyone who needs the state asks `gh` when they ask.
- **Skip the line entirely** on the default branch, where no PR is coming, and when the work has no ticket file — the close-out prose already names the branch.

**If you pushed, the gate has been superseded — watch the real one.** Step 4's green was a local proxy. Ask `gh run list --branch <branch>` (or `gh pr checks`) once the push has landed, and if it's still running, use `Monitor` rather than sleeping. A red CI on work you just reported as done is the most common way this skill's close-out turns out to have been wrong. When a PR exists and a review bot has commented, read those comments and say which you think are worth acting on — that conversation starts whether or not anyone is here for it.

Then redraw the epic with the `cppcho:ticket-dag` skill. The ticks you just made flip this ticket to ✅ and can release several others to 🟢, and what a finished slice unblocks is the one thing the user can't read off the diff. It's also the cheapest check on your own bookkeeping: a criterion the work satisfied but you forgot to tick leaves the row reading 🟡, and a row still 🔴 behind a ticket you just finished means an edge is wrong.

When the redraw comes back with **every** row ✅, say so and offer to close the epic out — `/cppcho:to-tickets` archives it once the PRs have merged. Offer rather than do: this slice's PR is almost certainly still open. But make the offer here, because this is the last moment the epic's being finished is in front of anyone.

### The close-out

Lead with the outcome: what landed, what you left out, where you diverged from the plan, and the ticket the graph points at next. Then name this skill's revision, `/code-review` by literal name with whether it ran, and for the drive, what you actually launched and what you saw it do — or that you skipped it, and which files make the diff surface-free. Your own tests, the typecheck and the gate are not a substitute for either. A token budget, a background run, or a request to ship quickly is not a reason to skip one; the user saying "don't review this" is, and then quote them. This line exists because the two most expensive defects these sessions produced were both found after a close-out that read as though the work was verified.

**Write it for someone who has not re-read the ticket.** They wrote it, days ago, and they are not going to open it before reading you — so a close-out leaning on the ticket's own vocabulary, or on this skill's ("the seam", "blast radius", "the 🟢 frontier"), lands as something they have to decode. Name behaviours and files the way they'd describe them out loud. The measure that matters: could they act on this without opening another file? "i don't understand assume i don't read the ticket or spec" is what it reads like when the answer is no, and one close-out got quoted straight back with "explain what this means".

On a long run, don't go silent — past roughly 150 turns, post two or three lines saying what's done and what's next when you cross a step boundary. Every "are u done yet" and "whats the status" in this skill's history came from a run past 266 turns that had reported nothing since it started.

Offer `/verify` here when the change earns a deeper runtime pass than you could drive yourself — anything touching money, persisted state, or a flow with several services in it. One line, and the user decides.
