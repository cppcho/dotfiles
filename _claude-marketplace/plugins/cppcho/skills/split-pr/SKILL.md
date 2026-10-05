---
name: split-pr
description: Carves a chosen feature out of a work-in-progress branch or PR into a stack of small, self-contained, reviewable PRs onto a base (integration) branch — rebuilt from the WIP branch's final state rather than cherry-picked, starting from the thinnest end-to-end working path and adding one behaviour per PR so every PR builds, runs, tests and reads on its own, planned and approved before anything is pushed, and restacked in place when the split changes. Use whenever the user wants to split a big or messy branch into PRs, pull the ready parts of a WIP branch into an integration or feature branch, "extract", "carve out", "upstream" or "land" one feature from a branch that holds several, make atomic or stacked PRs out of existing work, "split the current branch onto <PR or branch>" or "on top of #1234" (never answer that with one combined PR), add the next slice to a stack already in flight, or rethink/re-slice a stack that already exists — even if they only say "make PRs for the backend part of my branch".
argument-hint: "<wip-branch|pr> <base-branch> <feature to pick>"
---

# Split PR

A WIP branch records how the work evolved: false starts, reverts, two features interleaved, commits that only make sense together. Reviewers need the opposite — the final design, one concern at a time, each piece small enough to judge. So this skill never replays the WIP history. It reads the WIP branch's **final state** for the picked feature, decides how that final state divides into slices, and rebuilds each slice as a fresh commit on top of the one before. The stack's tip ends up identical to the WIP branch for every file that is wholly the feature's, and identical minus the other work's hunks for files it shares.

```
- [ ] Inputs resolved: WIP ref, base branch, the feature to pick, earlier decisions recovered
- [ ] The feature's changes isolated from everything else on the WIP branch
- [ ] The repo's layers identified and the feature's call graph drawn
- [ ] Slice plan presented, approved (all of it, or the slices the user named), saved
- [ ] Approved slices built bottom-up, each one gated
- [ ] Tip verified against the WIP branch
- [ ] Branches pushed, PRs opened as a stack
```

## 1. Resolve the inputs

The user gives three things; ask only for what is missing.

- **The WIP ref** — a branch, or a PR number/URL (`gh pr view <n> --json headRefName,baseRefName` resolves it). Read it from the remote (`origin/<branch>`): the local checkout is often behind.
- **The base** — the branch the new PRs target, usually an integration branch, or the top of a stack already in flight. If it does not exist on the remote, say so and ask; do not create it unasked. If it is an unmerged PR's branch, say so in the plan.
- **The feature** — "the backend", "the refund flow", "everything under `api/`", a ticket. When the WIP branch holds several features that share files, this is the boundary everything else depends on. If it is ambiguous, show the candidate file list and ask. Parts the user calls unsettled ("still needs refinement") stay out until they say otherwise.

`git fetch` both refs. Diff with three dots, `git diff <base>...<wip>`: the WIP branch has usually fallen behind the base, and a two-dot diff would attribute every commit the base gained since to the feature.

Check what the base already has. Open PRs into it (`gh pr list --base <base>`) and earlier slices that merged are work you must not carve twice. When this continues a stack an earlier session started, recover what that session decided before planning anything: read the saved plan (`.scratch/split-pr/<feature>.md`, see step 4) and the body of every PR in the stack. A part the user scoped out last time is still out.

## 2. Isolate the feature

List the files the feature touches, and for files it shares with other work — a router, a DI container, an error list, a lockfile, config — the specific hunks that are the feature's. Commit messages and the bodies of PRs squashed into the WIP branch are good leads; the code is the authority.

**When the WIP branch has merged the base** — or the stack's earlier slices, which is usual once a stack is in flight — the three-dot diff measures from that merge, and whatever its conflict resolution kept from the WIP's older side shows up as the feature reverting the base: a review fix undone, a comment back to its draft wording, a test gone. Nothing else flags it: after the merge, `git diff <wip>...<base>` is empty, and `git blame` credits the stale line to the WIP commit that first wrote it. So for each hunk that removes or rewrites lines the base has, ask which commit made the change. `git log --oneline -S'<base line>' <base>..<wip>` lists the WIP's own commits that touched it; add `-m` to include merges. A change only the `-m` run finds came from a merge's resolution, not from the feature. The slice keeps the base's version, and the plan lists it as a deviation. Run this check now, before planning. Found during the build, it costs rebuilding every slice it reached.

Note, while reading, anything the final state carries that no longer has a reason: a dependency nothing imports, a pre-release version pin where a release now exists, a config entry for code that was dropped, a value that restates its default (an env entry equal to the code's fallback, a timeout equal to the client's). Look hardest at stand-ins whose own comments say they are waiting on something — hand-written types "until the proto merges", a stub "until the client ships", a TODO naming a PR. The WIP branch was written before that thing landed; check the base and the package registry for it now, and if it has shipped, the slice uses the real thing. Compare each new file with its nearest sibling on the base too — how requests are typed, constants named, errors and timeouts handled — since the WIP may predate a convention the base settled on. The extraction is the natural moment to fix all of these, and they go in the plan as explicit deviations from the WIP branch.

Also list the WIP branch's **supporting changes** — hunks that are not the feature's code but that some of it needs: test setup and test-environment declarations, build or framework flags, env switches, shared test helpers, lint config. Each one belongs to the slice whose code first fails without it, and you will need that mapping in step 4.

Set apart what is neither the feature's runtime code nor something it needs: **developer tooling** (local-run scripts, dev-only ports and proxies, run instructions), **project docs and agent rules** (ADRs, CLAUDE.md sections, `.claude/rules`), **diagnostics** (debug overrides, log-only metrics, tracing), and **seed or placeholder content** (sample data, knowledge files, fixtures standing in for real content). No slice's gate needs them, which is exactly why they drift into whichever PR is open. Step 4 says where they go.

## 3. Map the layers

Every codebase has layers, whatever it calls them. Find this repo's names for them from the directory layout, its README or architecture docs, and its lint or agent rules. The roles are generic:

| Role | Typical names |
|---|---|
| **Core model** — entities, value types, domain rules | `domain/`, `models/`, `entities/`, `core/` |
| **Persistence** — repositories, queries, DAOs | `repository/`, `db/`, `store/`, `dao/` |
| **External adapter** — client for another service, API or SDK | `clients/`, `integrations/`, `infrastructure/`, `gateway/` |
| **Orchestration** — services, use cases, application logic | `service/`, `usecase/`, `application/`, `lib/` |
| **Entrypoint** — what the outside world calls | HTTP/gRPC handlers, routes, CLI commands, jobs, UI routes, `api/`, `presentation/` |
| **Wiring** — construction and configuration | DI container, server bootstrap, `main`, `app.*`, env/config |
| **Contract & dependencies** — schemas, generated clients, manifests | proto/OpenAPI, `go.mod`, `package.json`, lockfiles |

A small repo may fold several roles into one file; the roles still apply to the symbols in it.

Then draw the feature's call graph: for each symbol the feature adds or changes, which of the feature's other symbols call it. The plan is read off this graph: the thin path (step 4) is the shortest route through it from one entrypoint down to the code that does the work, and each later slice is a behaviour that branches off that route.

## 4. Plan the slices

Slice along the feature's paths, not its layers. The bottom PR is the **thinnest working path**: the smallest piece of the feature that does one real thing end to end — one entrypoint, the orchestration behind it, the model, persistence and adapter calls it makes, and the wiring and contract bump that connect them. Every PR above it adds **one behaviour** to that path: a validation, a branch, an option, a second capability, across whatever layers that behaviour touches, with its tests. From the first PR the feature runs, every line has a caller the moment it lands, and each later PR answers a single question for its reviewer: what does this behaviour change? This holds whether the feature spans every layer or sits in one; when the base already has the lower layers, the thin path is simply shorter. Apply these rules; each has a reason, and the reason is what to apply when a case does not fit.

**The thin path carries only what it executes.** No field a later behaviour reads, no rule or type nothing checks yet, no error case the path cannot reach, no option nobody passes. Those arrive with their behaviour. The thin path therefore usually holds a *reduced* version of most of its files — the entity without the later field, the policy without the later rules, the request without the debug-only parameter — and so does every slice below the one that completes a file.

**The thin path must be safe to run.** Thin means fewest behaviours, not fewest guards. Whatever stops the path from doing harm when it runs for real — an amount limit on a refund, a throttle on a sender, an auth or ownership check, idempotency on a retry — rides in the thin path, because the PR is judged as code that could run, and a reviewer should never have to approve "this spams every customer until PR 3". Ask of each check the WIP applies: if the path ran without it, would something wrong happen to a real user, record or bill? If yes, it is part of the path; if it only makes the answer nicer, it is a later behaviour.

**Everything lands with its caller.** Domain rules, queries, policy and validator modules, helpers, declared structure such as an interface method or a field: code is judged against how it is used, and code nobody calls is the easiest to get wrong unnoticed. A slice's new code must be reachable from an entrypoint in that same PR. Do not split one behaviour by layer — its handler change and its model change go together.

**One behaviour per PR above the path.** Order them by dependency first, then by what the user most wants working early. A behaviour that only makes sense beside another is one slice with it.

**Diagnostics, tooling and docs go last or alone.** Debug overrides and log-only metrics are behaviours like any other but nobody's path depends on them, so they sit at the top of the stack — together with every field and parameter they need in lower files. Developer tooling and project docs or agent rules get their own PR, or stay out, unless the user asks for them in a feature slice. Seed and placeholder content rides with the first slice that reads it, listed in the plan with its size so the user can trim it.

**When the thin path is too big to review.** First make it thinner — usually the path through fewer branches or a simpler case. If it still far exceeds the size guidance, peel the external adapter off into its own PR beneath it: it is reviewed against someone else's contract rather than against the feature, and it stays unwired until the path above calls it. Say so in the plan; peel off further layers only when the user agrees.

**Wiring rides with the change that forces it.** When a slice changes a constructor or signature, the call site in the bootstrap moves in the same PR, or that PR does not build. Configuration a slice's wiring needs at startup (an env var, a config key) rides with that slice too — including test and preview-environment config — and deploy-side config that lives in another repo goes in the PR description as a precondition.

**Supporting changes land with their first dependent, and no earlier.** A test-setup guard, a test-environment declaration, a build flag or a helper that a later slice needs is noise in an earlier one: the reviewer has to ask why it is there, and the answer lives in a PR they have not seen. "It is small and harmless" is not a reason to land it early; "this slice's own code or tests fail without it" is the only one. A lint or boundary rule cannot fail that way, so it rides with the first slice whose code it constrains.

**The dependent is a slice, not a position.** When the plan changes — a slice dropped, moved, or left out of what the user approved — everything the missing slice brought is re-homed to whichever kept slice now needs it first: supporting changes, but also data, content and shared code. Equally, a kept slice that relied on the missing one's *behaviour* (a check it assumed ran, content it expected) is a consequence to state before building, not after.

**Dependencies arrive with their first importer.** Each slice adds only what its own code imports, pinned to a released version where one exists, with lockfiles regenerated by the package manager, never hand-edited.

**Tests travel with the code they test.** A slice's tests cover that slice's state — a trimmed test for a trimmed file — not the final one.

**No scaffolding to satisfy the rules.** No stubs, placeholder implementations, or tests you will throw away. When the caller rule forces a slice past a comfortable size, say so in the plan and let the user decide; do not invent seams.

**Size.** Aim for what one reviewer reads in one sitting — a few hundred changed lines, generated code excluded — and one concern. Count trimmed files and their rewritten tests at their real size; they run larger than the WIP diff suggests. Do not split below that just to be small: two slices that only make sense read together are one slice.

**Order.** One linear stack, each PR based on the one below, the thin path at the bottom. Behaviours that do not depend on each other still go in one line, because a single chain is what reviewers and stacking tools handle best. Offer parallel PRs only if the user asks.

These rules are defaults. The user will often have their own preferences about where the line falls, stated as they react to the plan. Adopt them, restate the rule you are now following, and re-plan from it rather than patching the one slice they pointed at.

### Present the plan

Stop and show it before creating anything:

| # | PR title | Base | Contents | ~Lines (tests) |
|---|---|---|---|---|

Under the table, only what the user needs to decide: what the thin path does end to end, why a boundary falls where it does when it is not obvious, any slice that breaks the size guidance and why, deviations from the WIP branch (step 2), each supporting change and the slice that first needs it, preconditions (deploy config, an unreleased dependency), and the WIP files deliberately left out because they belong to another feature or the user scoped them out. Then ask to proceed.

Approval covers building, pushing and opening PRs for the slices it names. "Do 1 and 2" approves those two: build them, stop, and leave the rest as the plan for later. When the user picks a subset that is not the bottom of the stack ("1, 7 and 8"), re-show the reduced table first with what each kept slice gains or loses from the missing ones — the re-homing rule above. A question in the plan that the approval does not answer ("…with the ADR in PR 1?") is not a yes: take the conservative option, leave the thing out, and say so.

Save the approved plan, what was scoped out and why, and the deviations to `.scratch/split-pr/<feature>.md` in the WIP checkout. The next session that extends or re-slices this stack starts from it (step 1).

## 5. Build

Work in a new git worktree off the base, so the user's WIP checkout is never touched. Install its dependencies with the repo's package manager before the first gate, or link the WIP checkout's where installs are slow, in a way git ignores. Integration and end-to-end tests may need a port or service another worktree already holds; check before blaming the slice. Branch each slice off the previous one.

For each slice:

1. **Files at their final state** — copy them from the WIP branch exactly: `git show "<wip>:<path>" > <path>`. That is what guarantees the tip matches. Do not cherry-pick, not even a squashed PR commit that looks exactly like the slice: it carries that PR's version of each file, from before the WIP's later commits changed it, and its conflicts tempt you into resolving by hand what a copy gets right. Three things make the WIP's version wrong to copy: the base changed the file since the WIP forked (`git diff <wip>...<base> -- <path>` is non-empty), a merge of the base into the WIP kept stale lines in it (step 2), and fixes made on slice branches during review never reached the WIP (`git merge-base --is-ancestor <previous-slice> <wip>` fails). In each case start from the base's or the slice's version and apply the WIP's hunks, or the copy silently reverts that work.
2. **Files in a reduced state** — write the trimmed version with the Edit and Write tools, not scripted string replacement, then audit what the removed code was holding up. The WIP version's other lines were written to fit the whole file, and some of them only make sense beside the part you cut:
   - **Declared structure** — a field, parameter, schema key, option or export whose only reader is in a later slice goes, even when the file otherwise looks final. Grep for each one's readers in this slice.
   - **Comments** describe *this* slice's code, not what is coming. A comment about a field that does not exist yet, or one that justifies a value by how a later slice's code uses it, is wrong in this PR.
   - **File-level declarations and imports** — a test-environment pragma, module-level setup, an import — stay only if the trimmed code still needs them. Drop one and see whether the slice's gate still passes.
   - **Tests** must still fail when this slice's code is wrong. A test whose point was to tell the kept branch from the removed one ("takes path A, not path B") shrinks to counting calls once path B is gone, and then pins nothing. Rewrite it against what the slice does — the path, the payload, the contract — rather than trimming it until it passes.

   A file copied at its final state (item 1) can carry the same leftovers when it describes code in a later slice; apply the structure and comment checks to it too. Finish this audit before building the next slice on top: a fix found later costs a rebase of everything above.
3. **Shared files** — apply only this slice's hunks.
4. **Generated code** — regenerate with the repo's generator. Copying generated output from the WIP branch is only safe for the slice where the generator's input is already final.
5. **Dependencies** — through the package manager, then its tidy/lock step.
6. **Gate** — build, lint and the tests for what changed, using the repo's own commands (README, Makefile, `package.json` scripts, agent rules), with commit hooks running: never `--no-verify`. A slice that does not build on its own is not self-contained, whatever its diff looks like. Report plainly what you could not run locally and why. Then three checks, each with its result in the slice's build notes:
   - **Each behaviour has a guard.** For every behaviour the slice adds, name the test that fails when it breaks, and break the slice's key line once to confirm one does. Write the missing test before moving on.
   - **Each supporting file earns its place.** Revert it to the base and re-run: "reverted `jest.setup.js` → red". A file whose revert leaves the gate green moves to the slice that needs it. Env or config a file reads directly at runtime stays with its reader even though no test fails without it — unless its value only restates the code's default, in which case it has no reason to exist (step 2).
   - **Nothing changed that the plan did not say.** A test rewritten to new semantics, a planned entry dropped, a file moved between slices, a WIP behaviour you had to alter: stop and tell the user before pushing, rather than in the final report.
7. **Commit** in the repo's convention, one commit per slice.

Then **verify the tip.** List the feature's files and diff them between the top slice and the WIP branch: `git diff <tip> <wip> -- <files>`. Name the files explicitly — the base has usually moved since the WIP branch forked, and an unrestricted diff mixes that drift in. Files wholly the feature's must come out empty. Shared files must differ only by the other work's hunks. Anything else must be a deviation the plan listed. When only part of the plan was built, the comparison is against the WIP minus the unbuilt slices.

## 6. Publish

Push each branch and open the PRs bottom-up, each against the one below it and the lowest against the base, so later bodies can cite earlier numbers; edit the earlier bodies afterwards if they should cite later ones. Match the draft status of the PR below unless the user says otherwise. Use the repo's PR template if it has one. Keep each description to what the slice is for, where it sits in the stack, and anything a reviewer or deployer must know (a precondition, a decision they would otherwise stop and question). The per-file walkthrough is the diff's job.

End with the stack as a table (number, base, size), every PR's URL, the worktree path, and the slices of the plan still unbuilt. The user usually reviews each new slice straight away; name the PR, not the WIP checkout, as the thing to review.

## 7. Re-slicing an existing stack

The user often reshapes the split after seeing the PRs. Restack in place rather than starting over:

- The final state is now the stack's tip, not the WIP branch, wherever the two differ on purpose — review fixes, a scope cut, a rename. List those differences before rebuilding, and keep them.
- Keep a PR where its slice still exists, even if its contents change: its number, review history and links survive. Rewrite its title and body to match.
- Rebuild a changed slice, then move everything above it with `git rebase --onto <new-parent> <old-parent-sha>`, or `git rebase --update-refs` to carry every slice branch along at once. Record the old SHAs before you start. A conflict there is almost always between two versions of a file where the upper slice's version is the more final one: take it, re-apply the change you are propagating, continue.
- Push with `git push --force-with-lease`. Never a bare `--force`: the lease is what stops you overwriting a commit someone else pushed to the slice.
- Close a PR whose slice disappeared only with the user's go-ahead, and delete its branch only once it is closed.
- Re-run the gate on every rebuilt slice and re-verify the tip. When the user scopes the restack to some slices ("only update the first 3"), rebuild those and report which PRs above are now stale.

**When the WIP branch moves** after slices are open, diff the old WIP against the new for the feature's files and put each hunk in the lowest slice that owns the code it touches. A slice nobody has reviewed yet is amended and restacked; one under review gets a new commit, so the reviewer can see what changed since they looked.

Update the saved plan after any re-slice. If a change makes the stack's tip differ from the WIP branch on purpose — a rename the user asked for, a cleanup — say so. The WIP branch is the user's; do not commit to it unasked. The difference reaches it when the stack merges.
