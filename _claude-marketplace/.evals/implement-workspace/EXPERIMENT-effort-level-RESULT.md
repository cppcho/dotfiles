# Experiment: does `high` catch what `medium` missed?

**Hypothesis.** At `medium`, `/code-review` targets `min(files_changed, 4)`
findings. Iteration 2's eval-0 diff changed 3 files and the review returned
exactly 3 findings, none of them the fail-open query defect. So the cap may have
crowded it out, in which case the fix is "use `high` where recall matters"
rather than more sampling.

**Design.** Six blinded review-only runs over one fixed diff — iteration 2's
final eval-0 tree, which still contains the defect. Three at `medium`, three at
`high`, args and nothing else, no hint what to look for. Isolating the review
from the implement flow made more samples affordable than re-running /implement.

**Result: hypothesis REFUTED.**

- `medium`, all three runs: **0 findings** on the correct diff. Not three
  findings crowding out a fourth — nothing at all.
- `high`: scaled to 8 finder angles. Angle-level returns on the correct diff
  were `[]` for line-by-line, removed-behavior, altitude and conventions. One
  run executed all eight angles itself (nesting depth exhausted) and concluded
  "I could not find a genuine correctness bug", surfacing two low-severity
  findings, neither the fail-open.
- The decisive evidence is a `high` finder's own words about the exact line:
  "the `main.go` refactor to cache `r.URL.Query()` into `params` is
  behavior-preserving."

**Why it is missed.** The review reasons about the DELTA — what this diff
introduces. `r.URL.Query()` has always discarded malformed pairs; the diff only
cached the call. Every angle correctly concluded "nothing introduced here". The
defect is latent at a line the diff merely touched, and that is a blind spot of
the frame, not of the budget. More effort enlarges the fleet and leaves the
frame intact.

**Consequences for the skill.**
1. A quiet review means "this diff introduces nothing new", never "these lines
   are correct". Written into step 5.
2. The runtime drive, not the review, is what caught this defect in iteration 1
   (ten real requests). The `run` half of step 5 is the stronger half.
3. Do not reach for `high` expecting recall on latent defects. Reserve it for
   what it is actually tuned for.

**Caveats.**
- Driven by Sonnet for affordability; the iteration runs inherited Opus.
  Sonnet-medium returned 0 findings where Opus-medium returned 3, so the arms
  are comparable to each other but not to the iteration runs. The refutation
  rests on the `high` finders' explicit reasoning about the line, which is
  model-independent as evidence of framing.
- 4 of 6 driver agents never delivered an aggregate count: subagents are
  blocked from writing report files, and each driver stopped to wait on its
  forked fleet. The finder-level notifications carried better evidence than the
  aggregates would have.
- Every run's first invocation forked to the wrong repository. Passing the
  absolute repo path fixed it, which is now in the skill.

## Additional confirmations (arrived after the conclusion above)

Three more `high` finders reported independently, each having run all eight
angles in-context, each with `go build` / `go vet` / `go test` (one added
`-race` and `gofmt -l`) clean:

- "I could not find a genuine correctness bug" — stated by three runs
  independently, in those words or near enough.
- Findings surfaced instead: the `total` comment narrating the revision
  (3 runs), `matches()` re-lowercasing per item (3 runs), `matches()`'s
  unenforced pre-lowered-query contract (2 runs), and no whitespace trim on the
  query (1 run). All real, all cleanup or low severity. The fail-open is in none
  of them.

Two things this strengthens:

1. **The conventions angle duplicates the comment pass.** Three of three runs
   spent a finding on the `total` comment violating the final-state rule — the
   exact rule `cppcho:check-comments` exists to enforce, quoting the user's own
   CLAUDE.md back. The skill's instruction to tell the review that comments are
   step 6's job is validated: without it, the review burns budget on prose a
   dedicated pass is about to rewrite.

2. **A nesting limit crippled the high arm's fan-out, and the conclusion holds
   anyway.** Each run hit "subagent nesting limit (depth 3 of 3)" because the
   chain was parent session -> driver agent -> code-review, so most of the 8
   parallel finders could not spawn. Each compensated by running every angle
   itself in one context — arguably a *stronger* single-pass review than a
   fan-out, since one reader held the whole diff. It still missed the fail-open.
   In real use /implement sits at depth 1 and the fan-out would work; this
   caveat weakens the "8 parallel angles" claim, not the framing conclusion.

## Final tally

| arm | evidence | findings on the correct diff | fail-open caught |
|---|---|---|---|
| `medium` | 3 driver aggregates | 0, 0, 0 | 0/3 |
| `high`   | finder-level outputs only (see below) | 8 angle returns of `[]`, plus 5 low-severity findings across runs | 0 |

The two arms are not evidenced the same way, and the table should not imply they
are. The `medium` arm produced three clean driver aggregates. The `high` arm's
drivers never delivered one — each stopped waiting on its fleet, and subagents
cannot write report files — so its evidence is the finder agents' own returns,
captured from task notifications: `[]` from line-by-line, removed-behavior,
altitude and conventions angles, plus three runs that executed all eight angles
in-context and each stated they could find no genuine correctness bug.

That is weaker bookkeeping but stronger evidence for the question at hand, since
it shows the angle-level reasoning verbatim rather than a count. It is not a
clean 0/3 in the same sense as the medium column, and is written here as "0"
rather than "0/3" for that reason.

Wrong-directory fork on the FIRST invocation: **6 of 6 runs.** Passing the
absolute repo path fixed it in every case. The bad invocations returned 2-3
confident findings each about the parent session's unrelated working tree.

Combined with iteration 1 and 2's implement runs, the fail-open defect has now
been caught by 1 review out of 8 attempts across two models and two effort
levels. The one catch was Opus at medium during a full implement run. Treat the
review as a low-yield net for latent defects and lean on the runtime drive.

## high-2's late report, and an independence caveat

high-2 eventually delivered: **3 findings, all Low/Cleanup, no High or Medium,
fail-open absent.** Its best finding is real and the sharpest the experiment
produced: `out = out[:limit]` returns a slice whose backing array spans the
whole store, pinning memory for withheld items and exposing them to an appending
caller (`out[:limit:limit]` fixes it). Worth noting that no implement run, at
either effort, found this either.

The driver agent flagged — rather than smoothed — that it could not confirm the
pinned invocation actually ran in the pinned directory: the code-review agent
reported its cwd as .../implement-workspace with the bare range, and denied
issuing the "8 finder-angle agents" status its own Skill call had returned. It
justified the result on all six run repos being byte-identical, which is
verified true (HEAD 1e29b13, diff md5 25d44f5b92350e57453221960e74ec0e in every
run dir). So the findings are valid about this diff, but high-2 and high-3 may
be one review counted twice. The high arm's effective n is below 3, which is a
reason to hold its conclusion more loosely than the medium arm's — while noting
that the framing evidence (a finder clearing the exact line as
"behavior-preserving") does not depend on sample size at all.

## Correction: the wrong-directory fork is mostly a fixture artifact

high-3 delivered findings IDENTICAL to high-2's, confirming the two were one
review, and named the mechanism exactly: the forked review's "cwd resolved to
/Users/cppcho/dotfiles (git toplevel)".

So `/code-review` resolves to the git toplevel of the session's cwd. The eval
repos are nested INSIDE the dotfiles repo, so the toplevel walked outward to the
wrong project. In a real worktree the toplevel IS the worktree root and would
resolve correctly. Earlier notes in this workspace called this the
best-evidenced problem of the exercise and the strongest argument for the
false-clean guard; that overstated it. Correcting:

- The wrong-target fork needs a repo nested inside another repo. Uncommon in
  normal use, near-certain in this fixture. 6 of 6 is a property of the setup.
- The false-clean guard still earns its place, on the two causes that DO occur
  in ordinary work: no upstream on a fresh branch, and HEAD already equal to the
  base when the slice is uncommitted. Both were observed in the implement runs,
  which were not nested.
- Passing the absolute repo path remains good practice and costs nothing, but it
  is insurance against an unusual layout rather than a fix for a common bug.

## Close-out

The high arm's distinct finding sets, after collapsing the duplicate:
- three runs that executed all eight angles in-context: no correctness bug, a
  handful of cleanup findings
- the high-2/high-3 review: 3 findings, all Low/Cleanup
- one further independent correctness pass: "No correctness bugs found. The diff
  is sound."

The fail-open appears in none of them. Across iterations 1-2 and this
experiment, it has been found by 1 review out of 8 attempts. The framing
explanation stands and does not rest on sample size.

## The framing, in four reviewers' own words

Four independent finders cleared the query-handling code, each by reasoning
about the delta rather than the behaviour:

1. "the `main.go` refactor to cache `r.URL.Query()` into `params` is
   behavior-preserving"
2. "The `params := r.URL.Query()` extraction in `main.go:28` is a reasonable,
   harmless simplification (avoids parsing the query string twice), not a
   finding"
3. "this only collapses two separate `r.URL.Query()` calls into one ... the
   `limit` parsing/validation path (including the `strconv.Atoi` error branch)
   is untouched byte-for-byte in logic, so no precondition or error-handling
   regression for the handler's caller (the HTTP client)"
4. "I'm not padding this with low-confidence nitpicks — the diff is correct as
   written."

Number 3 is the sharpest: it went looking at error handling on that very code
and cleared it *because it was unchanged*. Every one of these is a correct
statement about the diff and a wrong conclusion about the endpoint, which is the
whole finding. `/code-review` answers "what did this diff break", and a latent
defect on a touched line is outside that question at any effort level.

## high-1 lands, and the independence worry resolves the useful way

high-1 returned the SAME three findings as high-2 and high-3 — same files, same
lines, same severities. Three separate driver agents, three separate repo
copies, identical output.

This supersedes the earlier caveat that high-2 and high-3 might be one review
counted twice. The likelier reading, given byte-identical inputs, is that the
review is highly reproducible on this diff. That makes the conclusion stronger,
not weaker: the fail-open is not missed by chance in some runs, it is missed
consistently, by every `high` run, with stable output. A systematic blind spot,
not sampling noise.

Revised summary of the evidence: `medium` returns nothing on this diff (3/3);
`high` returns the same three Low/Cleanup findings every time (3/3), none of
them the fail-open. The one historical catch was Opus at medium inside a full
implement run — an outlier against a reproducible miss, rather than one draw
from a coin flip.
