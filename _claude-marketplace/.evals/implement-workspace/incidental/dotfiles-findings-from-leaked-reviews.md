# Incidental: findings on ~/dotfiles from wrong-cwd review forks

Not part of the skill evaluation. Three finder agents belonging to the
effort-level experiment's `code-review` invocations forked into
/Users/cppcho/dotfiles and reviewed the live uncommitted nvim/herdr work.
Captured here so the work isn't lost; the user has not asked for these to be
acted on.

Reported twice, independently, each with an empirical reproduction:

- `bin/bin/herdr-open-dir:65-71` — `git rev-parse --show-toplevel` returns a
  symlink-resolved path while `dir=$(cd "$dir" && pwd)` preserves symlinks, so
  `toplevel == dir` is false for any worktree reached through a symlinked
  ancestor. Falls through to `herdr workspace create` instead of
  `herdr worktree open`: no badge, not in the worktree list, no clean removal.

- `nvim/.config/nvim/lua/config/git-base.lua:112` — when `git write-tree` fails
  (unmerged index entries), `staged` is nil, so the drift check reports
  "changes were staged during base mode" regardless of the real cause, hiding a
  conflicted index behind a misleading prompt.

Reported once each:

- `bin/bin/herdr-code:17` — if `herdr-root` exits non-zero, `set -e` aborts
  before `code -r` runs. Detached shell command, no terminal, so the failure is
  completely invisible — the exact problem the script's leading comment claims
  to solve.

- `git-base.lua:125` (and `:84`) — `base_off()` / `abort()` ignore
  `git read-tree`'s result, delete the recovery state file, and report success.
  A concurrent git process holding `.git/index.lock` loses the staged snapshot
  with no error and no recovery path, while `base_on`'s equivalent risk IS
  error-checked.

- `nvim/.config/nvim/lua/config/nav.lua:46,97` — mutual exclusion hand-rolled
  in four openers rather than one `close_others(except)`; `zoom()` closes the
  explorer before `:only` but not Oil.

- `nvim/.config/nvim/lua/plugins/tpope.lua:54` — `open_keep_status` and the
  fugitive diff maps call `topleft 12split | 0Git` directly, bypassing nav.lua's
  single-owner invariant. Currently unreachable except via toggle_git_status.

Refuted on inspection of vendored sources, worth recording so they aren't
re-raised: `Snacks.picker.get()[1]` nil-indexing (get() always returns a table),
oil's "window survives close" claim, and fugitive/oil buftype assumptions.
