# Iteration 2 — observations

1. **Softening ITM-01's criteria did not isolate defect capture.** The baseline
   found the `Truncated()` defect anyway, by reasoning from the remaining
   criterion ("the cap notice keeps the meaning the spec gives it") back to the
   spec's "the notice is about the cap only" decision. It then drove the server
   unprompted to confirm. So for this defect the honest conclusion is: a good
   spec plus the existing skill is sufficient, and the review step adds nothing
   on the primary bug. To measure capture of a defect the ticket cannot lead you
   to, the defect has to be unrelated to the ticket's subject — which is exactly
   what the fail-open filter is, and why that probe is the load-bearing one.

2. **`cppcho:commit` reads harness-injected git context from the session cwd,
   not the repo being worked on.** Second run to report it, and this one is
   sharper: it "injected the parent dotfiles repo's git context and would have
   committed unrelated nvim/herdr work to main". Mostly an artifact of driving
   the skill from a subagent whose cwd is the parent session's. But it is a real
   hazard wherever cwd is not the repo, and the failure is silent and
   destructive (a commit of unrelated work to the default branch). Worth a guard
   in cppcho:commit: confirm the injected status describes the repo you mean to
   commit to before staging anything.

3. **The commit-context hazard is systematic, not incidental: 3 of 3.** Every
   iteration-2 baseline run so far reported `cppcho:commit` injecting the parent
   dotfiles repo's git context instead of the repo under work. All three caught
   it; none were told to look. That they all caught it is luck of capable
   agents, not a property of the skill.

4. **The red-green guard's delta is zero again, and more decisively.**
   Iteration-2's ITM-02 baseline did everything the guard asks for and more:
   4 of 6 subcases passed first run, it mutated the production line twice
   (unconditional assignment, then a shifted ceiling to kill the boundary case
   that survived the first mutation), reverted both, and independently sized its
   fixture to 150 items so `wantLen: 100` could not pass vacuously against the
   repo's 5-item store. The existing skill already produces this behaviour in a
   capable run. Keep the guard for the runs that are not capable, but stop
   expecting it to show a delta on three samples.

5. **The polling waste is now quantified, by the baseline itself.** ITM-03's
   baseline: "I polled both subagents in `sleep` loops (~300 s wall clock,
   ~215 s of it pure waste) instead of letting the completion notifications wake
   me; the old skill says nothing about waiting." That is a measured number to
   compare the with_skill runs' "## Waiting" sections against — the first
   assertion in this eval set with a real baseline rather than a definitional
   zero.

6. **Commit-context hazard: now 4 of 4.** Same report every time, including the
   detail that the injected context named branch `main` with unrelated
   nvim/herdr changes staged-adjacent. A guard in cppcho:commit is warranted.

7. **False-clean guard validated on an unanticipated cause.** ITM-02
   with_skill: "no upstream and HEAD == main, so main...HEAD was empty; I
   pointed it at the working tree instead, and it came back naming exactly
   store.go/store_test.go". The commit had not happened yet, so the range was
   empty for a reason unrelated to upstream. Three distinct causes of the same
   silent symptom are now on record (no upstream, wrong cwd, HEAD == base).
   The generalised wording — confirm the files named are the files you changed —
   covers all three; the original upstream-specific wording covered one.

8. **`**Status:** open` on a fully-ticked ticket is NOT a defect.** ITM-02
   with_skill flagged it. Checked: ticket-dag says "Checkboxes win on doneness
   ... When the two disagree about whether a ticket is finished, draw the
   checkboxes and report the disagreement — don't pick silently", and
   to-tickets defines no Status lifecycle at all. The field is advisory, for
   off-graph blocking. The fixture's tickets carry a Status line they did not
   need; that is the artifact. No skill change.

9. **The wrong-cwd fork, caught in the act and with its output captured.**
   A finder subagent from one of the effort-level experiment's reviews reported
   back having audited ~/dotfiles' uncommitted nvim work (nav.lua, git-base.lua,
   herdr-code, herdr-open-dir) — not the repo it was pointed at. medium-1
   independently reported the same thing: "the first call (`medium main...HEAD`)
   forked into a different working directory and reviewed an unrelated diff (the
   dotfiles repo's uncommitted changes)". Passing the ABSOLUTE REPO PATH in the
   args fixed it in both cases.
   This is now the single best-evidenced problem in the whole exercise, and the
   skill's false-clean guard is the part that catches it. Consider strengthening
   the skill from "confirm the files named are the files you changed" to also
   "pass the absolute repo path in the args", since that is the fix that worked.

10. **Subagents cannot write report files.** The Write tool refused with
    "Subagents should return findings as text, not write report files." So the
    findings.md deliverable is unobtainable from a subagent; the parent session
    has to transcribe from the agent's text response. A harness constraint to
    design around in future eval setups, not a skill defect.

11. **Model confound in the effort-level experiment.** Driven by Sonnet for
    affordability, Sonnet-medium returned ZERO findings on the same diff where
    Opus-medium returned three. The two arms are comparable to each other but
    not to the iteration runs. If the high arm also lands near zero, the
    experiment says nothing about the Opus behaviour that actually matters and
    should be re-run without the model override.

12. **The wrong-cwd fork reviews the PARENT session's working tree, and reports
    real findings about it.** Two leaked finder agents returned substantive
    findings on ~/dotfiles' live uncommitted work (git-base.lua's unchecked
    read-tree before deleting the recovery state file; herdr-open-dir's
    physical-vs-logical path comparison failing under symlinked ancestors).
    So the failure is not merely "reviews nothing" — it reviews the WRONG THING
    and returns confident, plausible findings about it. A caller who did not
    check the file list would act on findings for a repo they are not working
    in. That is strictly worse than an empty result, and it is the strongest
    argument for the false-clean guard being mandatory rather than advisory.

13. **Why the fail-open was missed — it is NOT the finding cap.** A `high`
    finder on the correct diff reported: "the `main.go` refactor to cache
    `r.URL.Query()` into `params` is behavior-preserving." It looked straight at
    the line and cleared it. The review reasons about the DELTA — what this diff
    introduces — not the absolute correctness of a line the diff happens to
    touch. The fail-open predates the diff (`r.URL.Query()` has always discarded
    malformed pairs); the diff only cached the call. So every angle correctly
    concluded "nothing introduced here", and the defect survived.
    Consequences:
    - The crowding-out hypothesis is refuted. `high` does not fix this, because
      the miss is a framing property, not a budget one.
    - Iteration 1's catch was a finder stepping outside that frame, which is why
      it did not reproduce.
    - `/code-review` is therefore a poor net for LATENT defects at touched
      lines, which is exactly the class the runtime drive DOES catch (iteration
      1 found the fail-open via ten real requests, not via the review).
      That strengthens the `run` half of step 5 relative to the review half.
