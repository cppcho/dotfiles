---
name: implement
description: Implements the work a spec or ticket describes, TDD at agreed seams, then runs the repo's gate and commits to the current branch. Use when building work that has already been specced or ticketed.
argument-hint: "[spec-or-ticket-path|ticket-number]"
disable-model-invocation: true
---

# Implement

Build what a spec or ticket describes. Agree the plan before touching code, then run to completion red-green at the agreed seams.

Track progress with this checklist:

```
- [ ] Read the work
- [ ] Agree the plan — no edits before this
- [ ] Find the commands
- [ ] Build it red-green
- [ ] Verify: suite on changed files, then the gate
- [ ] Commit
```

## 1. Read the work

If the user passed a reference — `.scratch/<feature-slug>/spec.md`, `.scratch/<feature-slug>/issues/03-*.md`, a ticket number, an issue URL — read its full body. With no argument, look under `.scratch/*/issues/` for the **frontier**: a ticket whose blockers are all done. If several qualify, ask which. Otherwise work from the conversation.

Read `.scratch/context.md` if it exists and use its vocabulary in code, tests, and commit messages.

Read the code the work touches before planning it. Existing patterns beat new ones.

## 2. Agree the plan

Present this and stop. No edits until the user agrees.

- **Scope** — the behaviour this pass delivers, and what you are leaving for later
- **Seams** — where each behaviour gets tested (a seam being where behaviour can be substituted without editing the code under test). If the spec fixed them, restate rather than reopen; otherwise propose the highest and fewest that work
- **Touch list** — the modules you expect to change, plus any prefactor to land first
- **Not TDD** — the parts you will build without a failing test first, and how you will verify them instead

Keep it to a list, and iterate until approved. Then build that scope and stop there; adjacent fixes and unrequested refactors belong in a follow-up.

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

Do the work yourself: a subagent editing in parallel, or re-checking work you can check with the commands from step 3, costs more than it returns here.

## 5. Verify

Tightest loop first:

- **typecheck** after each red-green cycle
- **the one test file** you are working in during the loop, not the suite
- at the end, once: **the suite scoped to your changed files**, then **the gate**

Fix and re-run until both pass. Reaching green by deleting an assertion, skipping a test, or loosening lint and type config hides the failure rather than fixing it. If a failure looks legitimate — the spec is wrong, or an existing test contradicts it — stop and say so.

## 6. Commit

Tick the acceptance criteria you satisfied in the ticket file, then commit to the **current branch** with the `cppcho:commit` skill — one commit per slice as it goes green, not one batch at the end. No new branch, no push.

Close with the outcome first: what landed, what you left out, and where you diverged from the plan.
