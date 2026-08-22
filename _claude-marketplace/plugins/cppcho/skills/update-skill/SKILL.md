---
name: update-skill
description: Reviews and rewrites a SKILL.md against Anthropic's skill-authoring and current-model prompting guidance — cutting what Claude already knows, fixing descriptions that under-trigger, and removing instructions that backfire. Use when writing a new skill, improving or reviewing an existing one, or when a skill isn't triggering or isn't being followed.
argument-hint: "[skill-md-path|skill-name]"
disable-model-invocation: true
---

# Update Skill

Make a SKILL.md do more with fewer tokens. Applies to a fresh draft as much as to an existing file.

For eval harnesses, trigger benchmarking, and packaging, use the official `skill-creator` skill — this one is the writing pass.

## Process

Track progress with this checklist:

```
- [ ] Read the target and two or three siblings
- [ ] Diagnose against the rules below
- [ ] Report the findings, then apply them
- [ ] Reinstall if it came from a marketplace
```

1. **Read the target** — the SKILL.md, its bundled files, and two or three siblings in the same collection, so the edit lands in the house style rather than a generic one. Read them yourself; a subagent hands back a summary when what you need is the wording you are about to edit.
2. **Diagnose** against the rules below. Note what's missing and, more often, what isn't pulling its weight. Check the two hard limits with `wc -l` and `wc -c` rather than eyeballing them.
3. **Report, then edit** — one line per finding, then apply them. Where a finding turns on the author's intent, ask rather than guess. Rewrite the target's own sections in place: no new structure it didn't ask for, no splitting into `references/` unless it is over-length, and no edits to the siblings you read for style.
4. **Reinstall if needed** — a skill installed from a marketplace runs from a cached copy, so edits to the source do nothing until it is reinstalled (in this repo: `make claude`, which copies the working tree as-is — no commit required). Session-start auto-update only triggers on a new commit, so an edit left uncommitted reaches no other machine until it is committed. Either way, running sessions keep the old listing; the change appears in sessions started afterwards.

## Cut first

The most common improvement is deletion. Once a skill loads, every paragraph competes with conversation history, so challenge each one: does Claude already know this? Would the skill be worse without it? Explaining what a PDF is, what TDD stands for, or why tests matter is budget spent for nothing.

Length follows from that. Keep the body under 500 lines; past that, split into `references/*.md` linked directly from SKILL.md — one level deep, because Claude partially reads files reached through a chain of links. Give reference files over ~100 lines a table of contents.

## Frontmatter

- **The description is the trigger** — for a model-invocable skill. It needs what the skill does *and* when to use it, in third person, using the words a user would actually type. Under-triggering is the common failure, so lean pushy: name the situations, including ones where the user won't say the skill's name. `description` plus `when_to_use` are truncated together at 1,536 characters in the listing.
- **A `disable-model-invocation: true` skill's description never enters context** — it only labels the `/` menu, so spend the effort on the body instead. Don't grade a manual skill's description as if it had to trigger.
- **Keep all "when to use" wording in the description.** A body that explains when to invoke is talking to nobody — it is only read after invocation.
- **Where skills overlap, make each description say what the others are for.** Two skills that both interview-then-write leave Claude nothing to choose on; a clause naming the sibling and its territory fixes it without merging them.
- `name`: lowercase, hyphens, ≤64 characters, no `claude` or `anthropic`. In a plugin, `name` sets only the last segment and the plugin prefix is added automatically, so write it bare (`code-review`, not `myplugin:code-review`). Match the collection's existing naming pattern over the docs' gerund preference.
- Manual-only skills set `disable-model-invocation: true`; a skill that takes a path or ticket number gets `argument-hint`, in `[bracket-form]` since it renders in autocomplete.
- `allowed-tools` **pre-approves** for one turn, it does not restrict — so list every tool the body actually reaches for, including the ones consumed by `` !`command` `` injection, and drop the ones it never calls. To genuinely remove a tool, use `disallowed-tools`. Reach for `context: fork` when the skill is a self-contained task that should run as a background subagent, and `paths` when it only applies to certain files.

## Body

- **Match freedom to fragility.** Exact commands where a wrong move breaks something; direction only where many paths work. Mismatches read as brittle over-specification, or as vagueness at the one dangerous step.
- **Explain why, don't shout.** ALL-CAPS MUST/NEVER is a yellow flag — a model that understands the reason generalizes to the cases the rule didn't cover. Save emphatic phrasing for the one or two genuinely load-bearing rules.
- **Positive examples beat prohibitions.** Show the shape you want; a list of don'ts leaves the target unspecified.
- **Multi-step work gets numbered steps and a copyable checklist.** Quality-critical work gets a feedback loop: run the check, fix, re-run, proceed only when it passes.
- **One default with an escape hatch**, not a menu of options.
- **Consistent terminology.** One word per concept throughout; mixed synonyms make the model wonder whether you meant something different.
- **No dates or "as of now"** — and for the same reason, no pinned model names. "Use a Haiku agent for the cheap pass" goes stale the way a date does; say what the step needs instead. Put superseded guidance in a collapsed "old patterns" section, or delete it.
- **Concrete over abstract** — real paths, real commands, input/output pairs where style matters.
- **A reference to a sibling skill uses its invocable name.** `/domain-modeling` does not resolve when the skill ships in a plugin as `/cppcho:domain-modeling`.
- **Numbered steps that cross-reference each other drift.** When a step says "the files from step 2", check that it is step 2.
- Forward slashes in paths, fully qualified MCP tool names (`Server:tool_name`), and say whether a script is to be run or read.

## Instructions that backfire

Current models already do some of what older prompts asked for, so these now cost tokens or actively misfire:

- **"Double-check", "re-verify", "verify with a subagent"** — self-correction already happens, and the instruction compounds into over-verification. Delete it. Tool-based checks (run the tests, run the linter) are a different thing and worth keeping.
- **No scope constraint** — models widen tasks on their own, so a skill that produces work should say where to stop.
- **Unbounded delegation** — subagents get spawned readily. Say when delegation earns its cost, and that it doesn't for work the model can finish itself.
- **No length calibration** — replies and written files both run long by default. If the skill produces a document, say how long, or it will pad.
- **"Only report high-severity issues"** in a review skill — followed literally, it suppresses real findings. Ask for everything and filter in a later pass.

Close with the outcome in a few lines: what you cut, what you added, and anything you left alone because it was the author's deliberate choice.
