---
name: review-pr
description: Reviews a GitHub PR by number or URL — reads the PR body and every stacked parent before the diff, runs the built-in `/code-review` over it, drops findings the description or the stack already answers, and prints one severity-ranked report where each finding is a failure scenario and a fix. Posting to GitHub is a separate opt-in step, off by default. Use when the user gives a PR number or URL and asks for a review, a strict or high-effort review, a second pass before approving, or asks what in a PR is worth fixing. For the local working diff with no PR involved, plain `/code-review` is enough; to render findings that already exist as an HTML page, use `/cppcho:review-report-html`.
argument-hint: "[pr-number|url] [effort] [--post]"
allowed-tools: Bash(gh pr view:*), Bash(gh pr diff:*), Bash(gh pr list:*), Bash(gh stack view:*), Bash(git merge-base:*), Bash(git log:*), Bash(go mod tidy), Skill, AskUserQuestion
---

# Review PR

The built-in `/code-review` does the finding-hunting. This skill is the wrapper that makes its output trustworthy: context first, the stack accounted for, findings filtered, and nothing posted to GitHub unless asked.

```
- [ ] PR body and metadata read
- [ ] Stack mapped, parents read
- [ ] /code-review run at the chosen effort
- [ ] Findings filtered against body + stack
- [ ] Report written
- [ ] Posting offered, not assumed
```

## 1. Context, before the diff

```
gh pr view <n> --json title,body,url,baseRefName,headRefName,headRefOid,commits,files
```

Read the body in full and write down, for yourself, three lists: what the author says is **intentional**, what is **deferred** to a follow-up ticket or later slice, and what is **out of scope**. That is the filter in step 4 — a finding the description already answers is worse than no finding, because it makes the reviewer re-read what they wrote.

Keep `headRefOid`. Everything downstream is a claim about that SHA.

## 2. The stack

`gh stack view`; if there is no local stack state, match `baseRefName`/`headRefName` across `gh pr list --json number,title,baseRefName,headRefName`.

If the base is not the default branch, `gh pr view <base>` on each ancestor and read those bodies too. Then judge every candidate finding against the **stack tip**, not this slice: a missing guard, compensation path, idempotency check or test is very often the next slice's job, and the diff's own comments frequently say so.

## 3. Run the official review

Invoke the built-in `code-review` skill through the Skill tool with the PR number and an effort level — `high` by default here, or whatever level the user typed. Do not pass `--comment` or `--fix`; posting is step 7 and this skill never edits the working tree.

Hand it the context from steps 1–2 in the invocation, so its own pass starts already knowing what the author called intentional and which parent owns what.

## 4. Filter

Drop, and say how many you dropped and why:

- anything the PR body acknowledges as intentional, deferred, or out of scope
- anything that belongs to a parent PR, or that a later slice in the stack resolves
- working-tree `go.sum` churn — run `go mod tidy` and re-check before treating it as a finding at all
- anything you cannot state as a concrete failure: named trigger → wrong outcome. "Consider extracting this" is not a finding; it is a preference.

## 5. Confirm the branch hasn't moved

`gh pr view <n> --json headRefOid`. If it differs from step 1, the diff you reviewed is stale: re-read the diff for the files your findings touch and drop the ones whose code is gone.

## 6. Report

One card per finding, grouped by severity, most reachable first. This shape, not prose:

```
### [High] internal/credits/store.go:118 — the query returns expired grants

- Failure: The batch job runs after the expiry time. `ListLive` returns the expired row. The account gets a second grant.
- Fix: Filter on `expires_at IS NULL OR expires_at > @now` in the query. Do not filter in the caller.
```

- The severity tag opens the heading: **[High]**, **[Medium]**, **[Low]**, **[Cleanup]** — the same scale `/cppcho:review-report-html` groups by. Unranked findings make a data-loss bug read like a naming nit.
- Two bullets is the target. Add a third only when the mechanism needs an intermediate step to be believable.
- No code blocks unless one line of code is the shortest way to say the fix. No restating what the diff does.

Close with a single line: which one finding is worth fixing, and why that one.

### Language

Write everything the reader sees — the cards, the closing line, and, if you post, the review summary and the inline comments — in plain technical English that a non-native reader can follow:

- One idea per sentence, roughly 20 words or fewer. Split a failure chain into consecutive short sentences rather than one long one.
- Active voice, simple tenses: "the handler drops the error", not "the error is dropped".
- Write a fix as a command: "Move the check into the query."
- No idioms ("bites you", "falls over") and no symbols as connectives — write "then", "and", "or", not "→" or "/".
- Domain terms come verbatim from the diff and the repository, even multi-word ones. Never coin a new name for a thing the code already names; use that one term for it in every card. Quote file paths, identifiers, command names and error strings exactly as they are.

The constraint is on the prose, not on the rigour. If a finding needs a mechanism explained, use three short sentences — do not drop the mechanism to stay short.

## 7. Posting is opt-in

**Default: do not post.** After the report, ask once whether to post it — `--post` in the invocation skips the question and posts; `--no-post` skips it and doesn't.

When posting, it is one grouped review — never standalone comments, which arrive as unrelated notifications and can't be dismissed together:

```
gh api repos/{owner}/{repo}/pulls/<n>/reviews \
  -f event=COMMENT -f body='<one-paragraph summary, same language rules>' \
  -f 'comments[][path]=internal/credits/store.go' \
  -f 'comments[][line]=118' -f 'comments[][side]=RIGHT' \
  -f "comments[][body]=**[High]** the query returns expired grants

- Failure: …
- Fix: …"
```

Each `line` must exist on the right side of the diff or the API rejects the whole review; for a finding about deleted code, anchor it to the nearest changed line and say so in the body. Post only the findings that survived steps 4–5, with the card text unchanged — the inline comment and the report should read the same.
