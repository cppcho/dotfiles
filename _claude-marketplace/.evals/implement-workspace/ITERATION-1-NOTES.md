# Iteration 1 — known defects in the harness

1. **`.scratch` absent from the clones.** `~/.gitignore_global:29` excludes
   `.scratch`, so the epic was never committed to the fixture and `git clone`
   produced repos without it. Two runs (ITM-02 baseline, ITM-03 baseline)
   reported copying it in themselves; the others' handling is unknown until
   their notes land. Adds variance to the bookkeeping assertions (ticking
   criteria, the `**Branch:**` line). Does not affect the behavioural checks:
   whether code-review ran, its ordering against check-comments, the HTTP probe
   on ITM-01, or the clamp mutation on ITM-02.
   Fixed for later iterations by `setup_runs.sh`, which copies `.scratch` into
   each clone untracked — matching the symlinked-epic shape of real sessions.

2. **`cppcho:commit`'s injected git context pointed at the wrong repo.** The
   commit skill reads harness-injected `git status` from the session's primary
   cwd, which for a subagent is the parent session's directory, not the eval
   repo. Both finished runs noticed and committed explicitly in the right repo.
   This is an artifact of driving the skill from a subagent, not a skill defect
   — a real session's cwd is the repo.

3. **The red-guard's delta may not be measurable on ITM-02.** Both baseline
   runs improvised a mutation check without being told to: ITM-03's baseline
   no-op'd `sort.Slice` to prove its table test bit, and ITM-02's baseline
   mutated the clamp twice after two of three tests passed first-run. The
   instinct is already there some of the time; what the new step buys is
   reliability, which three runs cannot show. Treat a null result here as
   "not demonstrated", not "no effect".

4. **ITM-01's criterion 5 gives the bug away, so eval-0 cannot isolate the
   review step.** The criterion reads "returns one item and ends with **no**
   cap notice: ... the rows missing from the page were removed by the query,
   not by the cap." That is the defect, described. The baseline run found and
   fixed it without any review or verify step, and drove real HTTP off its own
   initiative because the criterion is phrased as an HTTP observation. Its own
   words: "Criterion 5 is the only assertion that separates correct from
   broken."
   For iteration 2, cut criteria 4 and 5 down to "filtering and the cap compose
   correctly" without naming the notice behaviour, so that separating correct
   from broken requires driving the endpoint rather than reading the ticket.
   Until then, read eval-0's with/old comparison as measuring process
   compliance (did the review run, in the right order) and not defect capture.

5. **The don't-poll instruction did not take.** ITM-03's with-skill run left
   "wait loops from the review/comment-pass waits" still draining after it had
   reported, and ITM-02's with-skill run took 642s against the baseline's 421s.
   The instruction sits in step 3 ("When you are waiting on one of those, don't
   poll for it"), which is read long before step 5 and 6 create the wait. Move
   it to the point of use — next to each delegation — rather than stating it
   once up front.

6. **A second silent-false-clean cause, worth more than the one I guarded.**
   ITM-03's with-skill run: /code-review "first executed against the wrong cwd
   ..., found an empty diff and reported '0 findings'". The no-upstream cause
   was already covered; this one is a different mechanism with an identical
   symptom. Generalised in the skill to: confirm the files the review names are
   the files you changed, before believing a quiet result.

7. **Test-only diffs are the strongest case for the review, not the weakest.**
   Three real findings on ITM-03's coverage-only diff, all surviving tracing.
   The sharpest: the cap was applied before the sort and no test could observe
   it, because every case used Page(0) against an already-sorted fixture.
   I had assumed a coverage ticket would be where the review earned least.
