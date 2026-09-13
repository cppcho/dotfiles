# implement-workspace

Evaluation harness for `cppcho:implement`, built while adding the review step
(step 5) to the skill. What is tracked here is the durable part: the fixture
source, the scripts, and the findings. The run directories are not — they are
six git clones per iteration and `setup_runs.sh` rebuilds them.

## Rebuilding

```sh
./setup_runs.sh iteration-3
```

That copies the fixture into six run directories and initialises each as its own
repo on a feature branch with no upstream — the state a real first slice starts
from, and the one that makes `/code-review`'s default `@{upstream}...HEAD` range
resolve to nothing.

The fixture itself is a plain directory, not a repo: an embedded repo inside
dotfiles stages as a broken gitlink. Each run repo commits everything except
`.scratch`, then the epic is put back on disk untracked, because that is how a
real session sees it — reached through a symlink, and excluded by
`~/.gitignore_global`. Iteration 1 missed that and two runs had to copy the epic
in themselves.

The fixture's `.scratch` is tracked here only because it had to be force-added
past that same global ignore; it is test data, not a live epic.

## The fixture

A small Go HTTP service listing items from an in-memory store, with three
tickets under `.scratch/epics/ITM-items-browser/`:

- **ITM-01** adds `?q=` filtering. `Page.Truncated()` counts against the whole
  store, so it is correct today and wrong the moment a filter lands — the SV-01
  bug shape, seeded as a latent defect.
- **ITM-02** clamps an oversized limit. The 5-item seed makes the obvious clamp
  test pass vacuously.
- **ITM-03** is coverage-only, with no runtime surface. The negative case: the
  review should run and the drive should be skipped.

## Files

| path | what |
|---|---|
| `fixture/` | the repo under test |
| `skill-snapshot/` | the pre-review skill, used as the eval baseline |
| `evals.json` | prompts, expected outputs, assertions |
| `setup_runs.sh` | builds one iteration's six run repos |
| `grade.py` | mechanical grading; writes `grading.json` per run |
| `build_benchmark.py` | assembles `benchmark.json` for the eval viewer |
| `score_experiment.py` | scores the medium-vs-high experiment |
| `ITERATION-1-NOTES.md` | 7 harness defects and null results |
| `ITERATION-2-NOTES.md` | 13 findings, including why the fail-open is missed |
| `EXPERIMENT-effort-level-RESULT.md` | the medium-vs-high result |
| `incidental/` | findings on this repo's own live work, from review forks that landed in the wrong directory |

## What the evals concluded

Read `EXPERIMENT-effort-level-RESULT.md` first. The short version: the runtime
drive and the false-clean guard earn their place; `/code-review` reasons about
what a diff *introduces*, so it reproducibly misses a latent defect on a line
the diff merely touches, at any effort level.

Two results are null and worth not re-deriving: the red-green guard shows no
delta because capable baselines already mutate to prove their tests, and the
polling measurement was contaminated by the `## Waiting` deliverable that was
supposed to measure it.
