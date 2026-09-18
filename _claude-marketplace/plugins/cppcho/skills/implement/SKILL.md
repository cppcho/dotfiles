---
name: implement
description: Implements the work a spec or ticket describes, slice by slice with tests at agreed seams, runs the repo's gate, reviews the diff and drives it at runtime, has a fresh pair of eyes tighten the comments, and commits — branching, pushing and opening the PR when the work asks for it. Use when building work that has already been specced or ticketed — "build PCE-03", "implement this ticket", "start on the spec", "land the next slice" — and when an epic has a ready ticket and the user asks what to pick up next and to get on with it. When the work isn't decided yet, /cppcho:brainstorm or /cppcho:to-spec comes first.
argument-hint: "[spec-or-ticket-path|ticket-id] [in a worktree] [create a pr]"
---

# Implement

**Skill revision: 2026-09-18b.** Quote it in the close-out; nothing else in a transcript records which version of this skill ran.

Build what a spec or ticket describes, in three phases: plan it, build it slice by slice, then land it. The third phase is where runs go wrong — never by refusing a step, but by treating a green gate or a pushed commit as the finish line. Across 69 runs, none of which ever compacted, a third ended without the comment pass and a quarter without the commit skill while the instruction sat in context the whole time. So the finish line is defined once, at the end: **the run is done when the close-out template is filled**, every slot with evidence or an explicit skip. Copy this into your first response and tick each box as it lands, so the run carries its own record of what's left:

```
- [ ] Plan posted — scope, seams, touch list, landing, commands
- [ ] Slices built, each committed as it went green
- [ ] Gate green
- [ ] Reviewed — findings traced, survivors fixed and pinned by a test
- [ ] Driven — ran the code, or named the files that make it surface-free
- [ ] Comments — check-comments over the session's diff
- [ ] Landed — worktree, push or PR as asked; branch recorded on the ticket
- [ ] Close-out posted
```

## Phase 1 — Plan

### Read the work

- Given a reference — a spec path, a ticket id like `PCE-03`, an issue URL — read its full body. Note landing instructions in the invocation too ("in a worktree", "create a pr", "stack on #5183"): they arrive here and are needed at the very end.
- With no argument, draw the epic with the `cppcho:ticket-dag` skill and take a 🟢 row — blockers done, nothing superseding or parking it. Drawing beats scanning the directory because it makes the pick visible to the user. Several 🟢 rows: show the graph and ask. No epic: work from the conversation.
- Read `.scratch/context.md` if it exists and use its vocabulary in code, tests and commit messages.
- Read the seams and the nearest neighbours, not the whole area. A median run spends a third of its turns before anything compiles, and every turn spent reading ahead makes every later turn dearer; the surface you'll touch is cheaper to learn while building it.

### Write the plan

A list, posted so the user can catch a wrong turn early:

- **Scope** — what this pass delivers and what it leaves
- **Seams** — where each behaviour gets tested. If the spec fixed them, restate; otherwise propose the highest and fewest that work
- **Touch list** — modules you expect to change, plus any prefactor to land first
- **Landing** — the branch, and whether a worktree, push or PR was asked for
- **Commands** — read off `CLAUDE.md`, `Makefile`, `package.json`, pre-commit config: **typecheck** (`tsc --noEmit`, `go build ./...`), **one test file**, and **the gate** CI treats as the bar (`make check`). A guessed command costs a wasted cycle; if the gate is genuinely ambiguous, ask once

Then judge which of three situations you're in:

- **Go ahead** when every line follows from the ticket. A ticket is already an approved plan; re-approving your restatement of it buys nothing.
- **Stop and ask** when a line is your call — an open seam where the options differ in cost, scope you want to cut or add, a criterion with two readings that lead to different code. Ask in the work's own terms, not skill vocabulary.
- **Hand it back** when the ticket isn't decided: you can't write Scope without inventing the decision, or the answer changes which modules you touch. Name `/cppcho:brainstorm` or `/cppcho:to-spec` and **stop**. Five runs entered the build loop on an undecided ticket and became design sessions — 860 turns arguing test parallelism, 276 turns iterating a design doc with no code — and together they are a third of everything this skill has ever spent. A question can't reach them; a different skill can.

Build that scope and stop there; adjacent fixes belong in a follow-up.

## Phase 2 — Build, slice by slice

Get something compiling and running within the first handful of turns — the first test, the prefactor, a typecheck over a stub.

Each slice ships with tests that fail without it. Write them wherever in the cycle they come easiest; what matters is that they pin the behaviour, and a test that passes the first time you run it hasn't shown that it does. Break the line it covers, watch it go red, put it back — if it still passes, make the break bigger before you rewrite the test.

A slice with nothing worth pinning — a mechanical rename, generated code, config nothing reads — is answered by the gate and the drive instead. An awkward test is a design signal, and a new seam changes what the spec committed to, so agree it first.

Write comments under the test the comment pass will apply: keep one only if you can name the wrong conclusion a reader draws without it. Narration, restated field meanings and failure stories don't pass.

Do the work yourself. A subagent editing in parallel, or re-checking what the plan's commands can check, costs more than it returns here.

**Verify tightest loop first:** typecheck after each cycle, the one test file in the loop, then once at the end the suite scoped to changed files and then the gate. Green reached by deleting an assertion, skipping a test, loosening lint or type config, or moving a date into the future hides the failure rather than fixing it. A failure that looks legitimate is a plan change; take it to "When the plan changes mid-build".

**Commit each slice as it goes green** with the `cppcho:commit` skill, ticking the criteria it satisfied in the ticket file. One commit per slice, not a batch at the end. Two things that decide whether that skill is any use to you:

- **Pass the repository's absolute path in its args.** It gathers its own status, diff and branch in the session's directory, which on a worktree or a sibling repo is a different checkout — without a path it gets handed a clean `main` and has nothing to commit.
- **Commit with the repo's pre-commit hook off** — `git -C <path> -c core.hooksPath=/dev/null commit`, which works whatever the repo's hook manager is. A hook that runs the whole suite on every slice is slow and goes red transiently on work that is fine, and you run the gate yourself at the end of this phase, which is the same bar. That makes the gate the thing you owe: skipping the hook is only free because you run it.

### When the plan changes mid-build

- **Contained to this ticket** — amend its unticked criteria to match what's now agreed; say so in the close-out.
- **Wider** — it moves a spec decision, another ticket, or the graph. Finish the current cycle green, commit, stop, and name `/cppcho:to-spec` or `/cppcho:to-tickets`.
- **A reroute doesn't lower the bar.** Code written after a change of direction ships with tests like any other slice — one run rerouted into harness work and seven hours later shipped a sixty-nine-line production package with none, because nothing asked again.
- Don't edit another ticket. Edit `spec.md` only when a criterion tells you to, and say which one in the close-out.

## Phase 3 — Land

A green gate says the code compiles and your tests agree with your code. It says nothing about whether the code is right, whether it runs, whether the comments survive a fresh reader, or whether the work is where the invocation said it goes. Those are this phase's four questions, asked once over everything the session built. Don't report before they're answered: "create a pr", "commit and push" and "check with mcp chrome and verify it end to end" are what the user types when this phase stops early, and three runs in five type one of them.

### Review

Work out the target first, because getting it wrong returns a confident review of nothing. Run `git status --porcelain` and `git rev-parse --abbrev-ref '@{upstream}'`:

- **Dirty tree** — say the work is uncommitted and pass the changed-file list; a range would be empty.
- **All committed, no upstream** — pass `<base>...HEAD` explicitly; `@{upstream}` won't resolve.
- **All committed with upstream** — the default is right.

Pass the repo's absolute path in the args. The review forks, and the fork lands in the session's directory, which on a worktree is a different repository.

Invoke the built-in `code-review` skill through the Skill tool at **low** — a few findings it can stand behind is the right trade for one slice, and the extra budget a higher level spends goes on nitpicks and on code this ticket doesn't own. Ask for "Report the findings only. Post nothing, change nothing." Don't name its posting or fixing flags even to forbid them; it detects them by scanning the argument string. Tell it the comments and the gate are not its job, or it spends a fifth of its budget re-running tests you already have green. Don't poll it — you're re-invoked when it finishes; `Monitor` is for a genuine wait.

The report says which level it ran at; quote that in the close-out rather than the one you asked for, because "reviewed at low" and "reviewed at high" are different claims about how much a clean bill is worth. Pass `high` instead when a slice earns a harder look.

Then run `git diff --name-only <range>` (or `git status --porcelain`) and quote the output against the files the report names. "0 findings" and "reviewed nothing" are the same sentence, and a mis-landed fork cites plausible line numbers too.

A clean review means "this diff introduces nothing new", never "these lines are correct". It reasons about the delta and will clear a pre-existing bug on a touched line as behaviour-preserving.

Trace each finding in the code. It survives only if you can walk the failure step by step; it dies only if you can trace the code doing the right thing. Fix what survives, and pin each fix with a test that fails without it — a finding that survived is by definition a behaviour the existing tests missed. Say in a line why each other one died, then re-run the gate.

Then ask the second question, because a finding can be true and still not yours: name the criterion in *this* ticket that asks for the fix. When none does and a neighbouring ticket's criterion covers it, it dies as out-of-scope with that ticket named. Phase 1's scope ceiling doesn't lift because a reviewer found something real — a fix built here gets tested, commented and pushed before anyone notices nobody asked for it, and then has to be taken back out. One run built three such fixes and reverted all three a hundred turns later; another killed two on these grounds in a sentence each.

### Drive

Run the changed code; the gate and the review only read it. Name the surface:

- **Browser app** — the chrome-devtools MCP tools on the real page, clicking what a user clicks. Starting a dev server is not driving it.
- **Local binary or CLI** — build it and run it against throwaway infrastructure: an emulator, loopback stand-ins, a seeded row. Report the log lines you saw.
- **Remote dev service behind auth** — the real endpoint with real mock user data and a real token. Ask for what's missing rather than substituting a local stub.

The `run` skill can launch things; the evidence is what you watched happen. Don't hand it the suite. A slice once went out with a green gate, a clean review and a clean comment pass, and the first click showed a filter reporting "capped at 2" when the cap wasn't what hid the rows — every function was right and only their combination was wrong.

Skip the drive only when the diff has no runtime surface — tests only, docs, config nothing reads, a mechanical rename — and name the files that make it so.

Review and drive come before the comment pass because fixing findings changes code, and the comment pass describes final state.

### Comments

Read the `cppcho:check-comments` skill and follow it over the session's diff, with the fresh reader on the cheaper model — pass `model: "sonnet"` on the Agent call, which the skill's own `model:` frontmatter can't set for a subagent that merely reads the file. Three fixed rules over a long diff is judgement, not open-ended design, which is what makes the cheap model the right tool here. It delegates to a fresh reader for a reason: the comments you can't audit are your own. Don't brief that reader on the plan or the ticket — every line of that can be laundered back into a comment. Fold its fixes into the slice's commit.

### Land it

Put the work where the invocation said — worktree, push, PR, stack on the named base — plus anything asked since. Don't stop at a local commit waiting to be asked. With nothing asked and no repo convention, commit and say plainly what you didn't do.

Record the branch as the ticket's last header line, below **Spec**, above the criteria:

```
**Branch:** `feat/pc-exchange` [#1234](https://github.com/acme/billing-api/pull/1234)
```

`.scratch` is shared across worktrees, so this line is the only thing that tells the next session which branch a slice's code is on. Append with ` · `, never rewrite; `[owner/repo#1234]` when the PR is in another repo; record identity, never merge state; skip it on the default branch or with no ticket file.

CI is not this skill's to watch. The gate you ran locally is the bar this run answers for; once the branch is pushed, what the checks do with it is the user's to read, and waiting on them costs a run more than it tells it — in practice they don't settle inside the run at all, since the approval gate needs a person. Push, report the PR, and stop.

Redraw the epic with `cppcho:ticket-dag`: your ticks flip rows to ✅ and can release others to 🟢, and a row still 🟡 or 🔴 behind a finished ticket is a bookkeeping error. When every row is ✅, say so and offer `/cppcho:to-tickets` to archive — offer, don't do; this PR is still open.

## The close-out

The run ends with this, filled in. A slot you can't fill is a step still to do, not a line to drop.

```
**Landed:** what changed, in the words of someone who hasn't reopened the ticket
**Left out / diverged:** …
**Gate:** <the command> — green | red because …
**Review:** /code-review at <the level the report said it ran> — N findings, M fixed, rest dead: traced wrong because … / out of scope, <ticket> owns it | skipped because the user said "…"
**Drive:** what you launched and what you saw it do | skipped — surface-free: <files>
**Comments:** check-comments — N edits, folded into <sha>
**Commits:** <shas> on <branch>; PR #… | not pushed because …
**Next:** the ticket the graph points at | epic complete, archive offered
**Skill revision:** 2026-09-18b
```

Write it for someone who has not re-read the ticket: behaviours and files as they'd say them out loud, none of this skill's vocabulary. The measure is whether they can act on it without opening another file.

On a long run, past roughly 150 turns, post two or three lines at each phase boundary saying what's done and what's next. Every "are u done yet" in this skill's history came from a run that had reported nothing since it started.
