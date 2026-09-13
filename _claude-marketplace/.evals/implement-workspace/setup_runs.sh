#!/bin/zsh
# Build the six isolated run repos for one iteration.
#
# The fixture is a plain directory, not a repo: an embedded repo inside dotfiles
# stages as a broken gitlink. So each run repo is copied and initialised here.
#
# `.scratch` is then removed from the run repo's first commit and left on disk
# untracked, because that is the state a real session starts from -- the epic
# reaches a worktree through a symlink, and ~/.gitignore_global excludes it.
# Iteration 1 missed this and two runs had to copy the epic in themselves.
set -e

W=${0:A:h}
F=$W/fixture
ITER=${1:?usage: setup_runs.sh <iteration-dir-name>}

names=(0-runtime-bug-behind-green-gate 1-weak-test-passes-first-run 2-no-runtime-surface-skips-verify)
tickets=(itm-01 itm-02 itm-03)

rm -rf "$W/$ITER"
for i in 1 2 3; do
  n=$names[$i]; t=$tickets[$i]
  for cfg in with_skill old_skill; do
    D=$W/$ITER/eval-$n/$cfg
    mkdir -p "$D/outputs"
    cp -R "$F" "$D/repo"
    R=$D/repo
    git -C "$R" init -q -b main
    git -C "$R" config user.email cppcho@mercari.com
    git -C "$R" config user.name cppcho
    # Commit everything except the epic, then leave the epic on disk untracked.
    mv "$R/.scratch" "$R/../.scratch-hold"
    git -C "$R" add -A
    git -C "$R" commit -q -m "chore: items browser fixture"
    mv "$D/.scratch-hold" "$R/.scratch"
    git -C "$R" checkout -q -b feat/$t
    echo "ready: $R ($t, $(git -C "$R" ls-files | wc -l | tr -d ' ') tracked files, epic present untracked)"
  done
done
