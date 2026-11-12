---
name: review-pr
description: Reviews a GitHub PR by number or URL with the built-in `/code-review`, re-checks in the code any finding that looks doubtful, and posts the surviving findings to GitHub as a pending review — a draft only the user can see until they submit it themselves. Use when the user gives a PR number or URL and asks for a review, or wants review comments drafted on GitHub as a pending or unsubmitted review. Pass `--no-post` to only print the findings. For the local working diff with no PR, plain `/code-review` is enough.
argument-hint: "<pr-number|url> [effort] [--no-post]"
disable-model-invocation: true
allowed-tools: Bash(gh pr view:*), Bash(gh pr diff:*), Bash(gh api:*), Read, Write, Grep, Glob, Skill, AskUserQuestion
---

# Review PR

## 1. Run `/code-review`

```
gh pr view <n> --json url,headRefOid
```

Keep `headRefOid`. The pending review gets pinned to it.

Invoke the built-in `code-review` skill through the Skill tool with the PR number and the effort level the user typed, if any. Add nothing else to the args. Its output is the review. Keep its findings, wording and order.

**Never write the names of its post or fix flags in the args, even to say "don't".** It looks for them anywhere in the args string, so naming one turns it on. It would then post each finding as its own public comment before you have checked it.

## 2. Check findings, if needed

Most findings need no extra work. Re-check one only when it is doubtful: it depends on a guess about runtime behaviour, a caller, or another file, or the PR body says the case is intentional or handled elsewhere. Open the code and trace that path. Drop the finding only if the code shows it is wrong, and say which ones you dropped and why.

## 3. Post as a pending review

Skip this step with `--no-post`, or when no findings remain. Otherwise post without asking. A pending review is a draft: only its author sees it, and nobody gets a notification.

GitHub allows one pending review per user per PR, so check first:

```
gh api repos/{owner}/{repo}/pulls/<n>/reviews --jq '.[] | select(.state=="PENDING") | {id, html_url}'
```

If one exists, it holds the user's own draft comments. Ask whether to delete it (`gh api -X DELETE repos/{owner}/{repo}/pulls/<n>/reviews/<id>`) or to skip posting.

Write the payload to a JSON file in the scratchpad, one inline comment per finding with the `/code-review` text as the body. **Leave out `event`.** Setting `event` submits the review publicly, and leaving it out keeps the review `PENDING`.

```json
{
  "commit_id": "<headRefOid>",
  "comments": [
    { "path": "src/store.go", "line": 118, "side": "RIGHT", "body": "**[High]** …" }
  ]
}
```

```
gh api repos/{owner}/{repo}/pulls/<n>/reviews --input <payload.json> --jq '{id, state, html_url}'
```

- `line` must be a line in the diff on that `side`. If it is not, the whole request fails with `422 ... Line could not be resolved`. Use `"side": "LEFT"` with the old line number for deleted code. If a finding's line is not in the diff, move that finding into a top-level `"body"` instead of dropping it.
- The response must say `"state": "PENDING"`. If it does not, tell the user straight away that the review is public.

End with the PR URL at the top, the number of comments posted, and: "To publish it, open Files changed on the PR, click Finish your review, then click Submit review."
