# Linear mode

The ticket skills — `to-spec`, `to-tickets`, `implement`, `next-actions`, `ticket-dag`, `reconcile` — give an **epic** one home. By default that home is a directory under `.scratch/epics/` in the repo (a **local epic**). When the user puts a feature in Linear, the home is a Linear **project** or a Linear **parent issue** (a **Linear epic**), and the skills work in **Linear mode**: the spec is a description, the tickets are issues, the blocking edges are relations, Linear status is the truth, and nothing is written to disk for that epic. An epic is never in both places.

This file holds the rules every skill shares in Linear mode. Each skill's `SKILL.md` says only what differs for that skill. Nothing here names a team, a status, a label or a title prefix as a fact: every one of those is read from the target team at run time, so the same rules serve any team.

## 1. Telling the modes apart

A skill is in Linear mode when either holds:

- Its argument is a Linear URL (`linear.app/...`), an issue identifier (`TEAM-123`), or a project identifier (`P-TEAM-123`).
- The Linear project or issue is the **subject** of the session — the thing the user handed over to be specced, broken down, built or audited.

A Linear link that is merely mentioned ("related: TEAM-45", a URL in a pasted note) does not switch the mode. The repository never decides the mode: a repo whose team plans in Linear still gets a local epic unless the user points at Linear.

Otherwise the skill is in local mode, which is exactly the behaviour its `SKILL.md` describes without this section.

## 2. Saying the mode before writing

Before `to-spec` or `to-tickets` creates anything, it says in one line which mode it is in and where the epic will live:

- `Linear epic as a project in <team>`
- `Linear epic as a parent issue under <project>`
- `local epic <PREFIX> in .scratch/epics/`

A misread then costs the user one word of correction before anything exists in the team's tracker. Skills that only read (`ticket-dag`, `next-actions`, `reconcile`) name the epic they resolved in their footer instead.

## 3. The shape of a Linear epic

An epic is one of two things, chosen by the user per feature:

| Shape | The epic is | A ticket is | The spec is |
|---|---|---|---|
| **Project** | a Linear project | a top-level issue in that project | the project description |
| **Parent issue** | a Linear issue | a sub-issue of it | the parent issue's description |

A feature of its own is usually a project. A sub-feature of a project the team already plans in is usually a parent issue inside it, so it does not become a project nobody else wants in the overview.

**Resolving the epic from an argument.** A project URL or `P-TEAM-123` is the epic. An issue id resolves upward: an issue with a parent resolves to that parent; a top-level issue with sub-issues is itself a parent-issue epic; any other top-level issue resolves to its project. Say which epic the argument resolved to. `reconcile` is the one exception: there a lone ticket id means a freshness check of that ticket, so it does not resolve upward — pass the project or the parent to audit.

**Other people's issues.** Every issue in the project, or under the parent, belongs to the epic in whatever state it is in — including ones QA or a PdM filed by hand. They draw and list like any ticket, usually as roots with no edges. The epic is what Linear holds, not only what the skills wrote.

**Sub-issues inside a project.** `list_issues` filtered by project also returns the sub-issues of every parent issue in it. A project-shaped epic reads only the **top-level** issues (`parentId` empty); a top-level issue that has sub-issues is a nested parent-issue epic, drawn as one row with its sub-issue count and named in the footer as an epic that draws on its own. A parent-issue-shaped epic reads only the issues whose `parentId` is that issue.

## 4. The spec in Linear

**Project.** The description follows the team's project template, read with `list_templates` / `get_template` for the target team. Its headings are filled from the spec: the "what" heading from Solution, the "why" heading from Problem Statement, the "notes" heading from Out of Scope and Further Notes, and any deadline or label heading left as the template wrote it when the spec says nothing. Below the template's headings, the spec's User Stories and Implementation Decisions follow under their own headings. A team with no project template gets the spec sections as `to-spec` writes them.

**Parent issue.** The description is the spec as `to-spec` writes it today — Problem Statement, Solution, User Stories, Implementation Decisions, Out of Scope, Further Notes — minus anything that only makes sense on disk (the `spec.md` link, local paths, the local-epic prefix).

**Stamps.** The `**Reconciled:**` line `/cppcho:reconcile` writes sits at the top of the description, before the first heading, exactly where it sits under the H1 of `spec.md`. There is no `**Cancelled:**` or `**Shipped:**` marker: status carries those (§8).

**Revising.** A later `to-spec` run updates the description in place, carrying every decision that still holds and the stamp line, as it would a `spec.md`.

## 5. The ticket body

An issue's description is the ticket body in this order, the same parts a local ticket file has:

```markdown
**What to build:** …

**Repo:** `<repo>` — or `none — verification on development`

**Size:** `[S]` | `[M]` | `[L]`

## Acceptance criteria

- [ ] …
- [ ] …
```

The size sits in backticks because Linear's Markdown normaliser escapes a bare `[M]` to `\[M\]`. Checkboxes are written `- [ ]` and come back unchanged, which is what lets a tick be a one-line patch.

No `**Blocked by:**` line: the relations carry the edges (§6). No `**Spec:**` line: the parent or project is the spec. No `**Branch:**` line: PR attachments carry where the code went (§10). No `**Linear:**` line: the issue is the ticket. Size is text, not Linear's estimate field, so a team that does not estimate is not pushed into it.

The title is the ticket title. **Prefix style is read from the siblings:** look at the open issues already in the target project (or under the parent); when they carry a leading `[XX]` tag — `[BE]`, `[FE]`, `[QA]` and the like — give each new title the tag that fits the layers it touches, and give a verification ticket (`Repo: none`) the tag the siblings use for QA work. When no sibling carries one, titles stay plain. Titles stay in the language the ticket was written in.

## 6. Creating tickets

- One issue per ticket, in the project (shape: project) or as a sub-issue of the parent (shape: parent issue).
- **Created in the team's unstarted state** (`Todo` in most teams). `save_issue` and `save_project` accept a state *type* as `state` — `"unstarted"`, `"canceled"`, `"completed"` — and resolve it to the team's state of that type, so no name lookup is needed; `list_issue_statuses` is for reading a team's names and order, as §7 needs. A cut ticket is an approved plan; the team's `backlog`-type state holds the unplanned and is left alone.
- **Assigned to the running user** (`whoami`). The Linear sweep in `next-actions` lists issues assigned to me, so an unassigned ticket would vanish from it. The user reassigns in Linear when handing one over.
- **Blocking edges are `blocks` relations.** Create tickets in dependency order, blockers first, so every relation can be written as the dependent is created. A blocker in another epic is an ordinary relation to that issue; Linear relations are global.
- No estimate, no milestone, no label beyond what the team's template applies. Those are the team's to set by hand.
- No index file. The relations are the graph, and Linear draws them itself.

## 7. Status and glyphs

Linear status is the truth about a ticket's lifecycle. Acceptance checkboxes show **progress** inside a ticket and never decide its status.

| Linear state (by type, from `list_issue_statuses`) | Glyph | Meaning |
|---|---|---|
| `canceled`, `duplicate` | 🚫 | retired — a dead end, not work |
| `completed` | ✅ | done |
| any `started`-type state (In Progress, In Review, QA states, …) | 🟡 | in flight — show `ticked/total` boxes beside it |
| `unstarted`, `backlog`, with every blocker **satisfied** | 🟢 | ready |
| `unstarted`, `backlog`, with a blocker not yet satisfied | 🔴 | blocked |
| `triage` | 🔴 | not yet accepted; name it in the footer |

A blocker is **satisfied** when it is `completed`, or when it is in a `started`-type state at or past the team's review state (the state named `In Review`, or the one the team uses for "PR open, code complete"). This mirrors the local rule that an unmerged PR does not hold the frontier: a dependent of a ticket in review draws 🟢 and its `PRs:` line says which branch to stack on. A blocker that is 🚫 is a dead edge: report it, never treat it as satisfied.

The glyph vocabulary is the one `ticket-dag` defines, so the two modes read alike.

## 8. Frozen, supersede, cancel, shipped

**Frozen.** A ticket in any `started`-type state, or with any acceptance box ticked, is frozen: its title and description text are never rewritten. Change of direction supersedes it.

**Supersede.** Set the dead ticket to the `canceled`-type state and add a comment: `Superseded by TEAM-NNN — <title>` (or `Superseded: <reason>` when nothing replaces it). Create the replacement as a new issue carrying the still-valid unticked criteria plus the changed behaviour. Re-point every `blocks` relation that aimed at the dead ticket to the replacement, or drop it when the work is dropped. The dead ticket keeps its text, its ticks and its attachments.

**Cancel an epic.** Set the project to its `canceled` status, or the parent issue to the `canceled`-type state, and add a comment with the reason. Leave the tickets alone. `ticket-dag` and `next-actions` drop a cancelled epic from their default views and name it, with the reason, when asked for it directly.

**Shipped.** A project in a `completed` status, or a parent issue in a `completed`-type state, is the record that the epic shipped. There is nothing to archive and nothing to move; a skill asked to archive a Linear epic says so and changes nothing.

## 9. Ticking progress

`/cppcho:implement` ticks acceptance boxes as each slice goes green, in the issue description, with a **patch** (`save_issue` with `patch`) that flips `- [ ]` to `- [x]` on the matching line and touches nothing else. Never resend the whole description to tick a box: a rewrite races with anyone editing the issue and loses their words.

Read the description back before patching and match the stored text, not the text that was sent: Linear normalises Markdown on save — a ticked box comes back as `- [X]` (capital), a bare `[M]` as `\[M\]`, a `-` bullet outside a task list as `*`, and a bare issue identifier (`LT-2`) becomes an `<issue … />` mention embed. Progress counts treat `[x]` and `[X]` alike. Identifiers that must stay plain text — the stamp line's ticket list, a `Repo:` value — go in backticks; identifiers that should link, as in a supersede comment, stay bare. To replace a line whose stored form you cannot predict (the stamp, once it holds embeds), patch with `replace_range` from the line's opening marker to the heading that follows it, rather than matching the whole line.

## 10. PRs and status moves

Nothing in these skills moves an issue's status by hand. The team's GitHub integration moves it when a branch or PR names the issue, so:

- `/cppcho:implement` puts the issue identifier in the PR title (`[TEAM-123] …`), which is what the integration keys on, and leaves the branch name as the repo's convention wants it.
- The integration attaches the PR to the issue. At close-out, if the issue carries no attachment for the PR yet, `implement` adds one as a link (`save_issue` with `links: [{url, title}]`) so the issue always links to the code that carries it. `create_attachment` is for file uploads and is not used.
- `ticket-dag`'s `PRs:` line and `reconcile`'s branch step read PR attachments. Who asks `gh` for merge state follows the local rules unchanged: `reconcile` always, `next-actions` only with `--verify` or when merge state is the question, `ticket-dag` never.

## 11. Tools

The skills use the `linear` plugin's MCP tools: `whoami`, `get_team`, `list_issues`, `get_issue` (with relations and attachments), `save_issue` (create, update, `patch`, `blocks` / `blockedBy`, `links`), `save_project` (create, update, `patch`, `template`), `get_project`, `list_templates` / `get_template`, `list_issue_statuses`, `list_issue_labels`, `save_comment`. Issue identifiers, project identifiers, team names and `me` are accepted as references, so ids rarely need looking up first. A skill loads only the tools it calls (`ToolSearch` with `select:`) rather than the whole set.

When those tools are not available in the session, a skill in Linear mode **stops and says so** in one line. It never falls back to writing a local epic the user did not ask for.

## 12. What stays local

- `.scratch/context.md`, the domain glossary, is per repo and is owned by `domain-modeling`. It is read in both modes and never published.
- Everything under `.scratch/epics/` is local epics only. A Linear epic has no directory there; a local epic moved into Linear (`to-tickets`) is archived under `_archive/` with a `**Moved:** <url>` line, not deleted.
