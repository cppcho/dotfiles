---
name: split-pr
description: Carves a chosen feature out of a work-in-progress branch or PR into a stack of small, self-contained, reviewable PRs onto a base (integration) branch — rebuilt from the WIP branch's final state rather than cherry-picked, sliced by layer so every PR builds, tests and reads on its own, planned and approved before anything is pushed, and restacked in place when the split changes. Use whenever the user wants to split a big or messy branch into PRs, pull the ready parts of a WIP branch into an integration or feature branch, "extract", "carve out", "upstream" or "land" one feature from a branch that holds several, make atomic or stacked PRs out of existing work, or rethink/re-slice a stack that already exists — even if they only say "make PRs for the backend part of my branch".
argument-hint: "<wip-branch|pr> <base-branch> <feature to pick>"
---

# Split PR

A WIP branch records how the work evolved: false starts, reverts, two features interleaved, commits that only make sense together. Reviewers need the opposite — the final design, one concern at a time, each piece small enough to judge. So this skill never replays the WIP history. It reads the WIP branch's **final state** for the picked feature, decides how that final state divides into slices, and rebuilds each slice as a fresh commit on top of the one before. The stack's tip ends up identical to the WIP branch for every file that is wholly the feature's, and identical minus the other work's hunks for files it shares.

```
- [ ] Inputs resolved: WIP ref, base branch, the feature to pick
- [ ] The feature's changes isolated from everything else on the WIP branch
- [ ] The repo's layers identified and the feature's call graph drawn
- [ ] Slice plan presented, approved
- [ ] Slices built bottom-up, each one gated
- [ ] Tip verified against the WIP branch
- [ ] Branches pushed, PRs opened as a stack
```

## 1. Resolve the inputs

The user gives three things; ask only for what is missing.

- **The WIP ref** — a branch, or a PR number/URL (`gh pr view <n> --json headRefName,baseRefName` resolves it).
- **The base** — the branch the new PRs target, usually an integration branch. If it does not exist on the remote, say so and ask; do not create it unasked.
- **The feature** — "the backend", "the refund flow", "everything under `api/`", a ticket. When the WIP branch holds several features that share files, this is the boundary everything else depends on. If it is ambiguous, show the candidate file list and ask.

`git fetch` both refs. Diff with three dots, `git diff <base>...<wip>`: the WIP branch has usually fallen behind the base, and a two-dot diff would attribute every commit the base gained since to the feature.

Check what the base already has. Open PRs into it (`gh pr list --base <base>`) and earlier slices that merged are work you must not carve twice.

## 2. Isolate the feature

List the files the feature touches, and for files it shares with other work — a router, a DI container, an error list, a lockfile, config — the specific hunks that are the feature's. Commit messages and the bodies of PRs squashed into the WIP branch are good leads; the code is the authority.

Note, while reading, anything the final state carries that no longer has a reason: a dependency nothing imports, a pre-release version pin where a release now exists, a config entry for code that was dropped. The extraction is the natural moment to fix those, and they go in the plan as explicit deviations from the WIP branch.

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

Then draw the feature's call graph: for each symbol the feature adds or changes, which of the feature's other symbols call it. The plan is read off this graph.

## 4. Plan the slices

Slice bottom-up along the call graph, one concern per PR, by these rules. Each has a reason, and the reason is what to apply when a case does not fit.

**Core-model and persistence methods land with a real caller in the same PR.** A domain rule or a query can only be judged against how it is used, and code nobody calls is the easiest to get wrong unnoticed. This includes declared structure — a field nothing reads yet, an interface method nothing calls. An intermediate slice therefore often holds a *reduced* version of a file: the entity without the field a later slice needs, the repository without the lookup nothing calls yet.

**Orchestration methods may land without a caller.** A service or use case is an entry point for review in its own right, exercised by its own tests. So one capability's model, persistence and orchestration go together, and a second capability can be the next slice.

**An external adapter is its own PR, at the bottom of the stack, unwired.** It is reviewed against someone else's contract, not against the feature, and it is the piece most worth reading in isolation. Wiring it in would make the service need its configuration before anything calls it, so the wiring waits for the first caller.

**Entrypoints come last, together.** Handlers, routes, commands and jobs for the feature go in one final PR, with the contract or generated-client bump that exposes them. That is where the feature becomes a commitment to callers, and a reviewer should see the whole surface at once.

**Wiring rides with the change that forces it.** When a slice changes a constructor or signature, the call site in the bootstrap moves in the same PR, or that PR does not build. Configuration a slice's wiring needs at startup (an env var, a config key) rides with that slice too — including test and preview-environment config — and deploy-side config that lives in another repo goes in the PR description as a precondition.

**Dependencies arrive with their first importer.** Each slice adds only what its own code imports, pinned to a released version where one exists, with lockfiles regenerated by the package manager, never hand-edited.

**Tests travel with the code they test.** A slice's tests cover that slice's state — a trimmed test for a trimmed file — not the final one.

**No scaffolding to satisfy the rules.** No stubs, placeholder implementations, or tests you will throw away. When the caller rule forces a slice past a comfortable size, say so in the plan and let the user decide; do not invent seams.

**Size.** Aim for what one reviewer reads in one sitting — a few hundred changed lines, generated code excluded — and one concern. Do not split below that just to be small: two slices that only make sense read together are one slice.

**Order.** One linear stack, each PR based on the one below. Slices that do not depend on each other still go in one line (independent ones at the bottom), because a single chain is what reviewers and stacking tools handle best. Offer parallel PRs only if the user asks.

These rules are defaults. The user will often have their own preferences about where the line falls, stated as they react to the plan. Adopt them, restate the rule you are now following, and re-plan from it rather than patching the one slice they pointed at.

### Present the plan

Stop and show it before creating anything:

| # | PR title | Base | Contents | ~Lines (tests) |
|---|---|---|---|---|

Under the table, only what the user needs to decide: why a boundary falls where it does when it is not obvious, any slice that breaks the size guidance and why, deviations from the WIP branch (step 2), preconditions (deploy config, an unreleased dependency), and the WIP files deliberately left out because they belong to another feature. Then ask to proceed. Approval of the plan covers building, pushing the branches and opening the PRs.

## 5. Build

Work in a new git worktree off the base, so the user's WIP checkout is never touched. Branch each slice off the previous one.

For each slice:

1. **Files at their final state** — copy them from the WIP branch exactly: `git show <wip>:<path> > <path>`. That is what guarantees the tip matches.
2. **Files in a reduced state** — write the trimmed version by hand. Comments in it describe *this* slice's code, not what is coming; a comment about a field that does not exist yet is wrong in this PR.
3. **Shared files** — apply only this slice's hunks.
4. **Generated code** — regenerate with the repo's generator. Copying generated output from the WIP branch is only safe for the slice where the generator's input is already final.
5. **Dependencies** — through the package manager, then its tidy/lock step.
6. **Gate** — build, lint and the tests for what changed, using the repo's own commands (README, Makefile, `package.json` scripts, agent rules). A slice that does not build on its own is not self-contained, whatever its diff looks like. Report plainly what you could not run locally and why.
7. **Commit** in the repo's convention, one commit per slice.

Then **verify the tip.** List the feature's files and diff them between the top slice and the WIP branch: `git diff <tip> <wip> -- <files>`. Name the files explicitly — the base has usually moved since the WIP branch forked, and an unrestricted diff mixes that drift in. Files wholly the feature's must come out empty. Shared files must differ only by the other work's hunks. Anything else must be a deviation the plan listed.

## 6. Publish

Push each branch and open the PRs bottom-up, each against the one below it and the lowest against the base, so later bodies can cite earlier numbers; edit the earlier bodies afterwards if they should cite later ones. Use the repo's PR template if it has one. Keep each description to what the slice is for, where it sits in the stack, and anything a reviewer or deployer must know (a precondition, a decision they would otherwise stop and question). The per-file walkthrough is the diff's job.

End with the stack as a table (number, base, size) and every PR's URL.

## 7. Re-slicing an existing stack

The user often reshapes the split after seeing the PRs. Restack in place rather than starting over:

- Keep a PR where its slice still exists, even if its contents change: its number, review history and links survive. Rewrite its title and body to match.
- Rebuild a changed slice, then move everything above it with `git rebase --onto <new-parent> <old-parent-sha>`. Record the old SHAs before you start. A conflict there is almost always between two versions of a file where the upper slice's version is the more final one: take it, re-apply the change you are propagating, continue.
- Push with `git push --force-with-lease`. Never a bare `--force`: the lease is what stops you overwriting a commit someone else pushed to the slice.
- Close a PR whose slice disappeared only with the user's go-ahead, and delete its branch only once it is closed.
- Re-run the gate on every rebuilt slice and re-verify the tip.

If a change makes the stack's tip differ from the WIP branch on purpose — a rename the user asked for, a cleanup — say so. The WIP branch is the user's; do not commit to it unasked. The difference reaches it when the stack merges.
