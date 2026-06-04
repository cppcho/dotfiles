#!/usr/bin/env bash
# Open the TODO file in a tmux window, or focus the window that already has it open.
# Auto-saves the buffer on InsertLeave and TextChanged (nvim/vim).
set -euo pipefail

dir="${1:-$PWD}"
session="${2:-}"

# Resolve target TODO file (project-local takes precedence over global), absolute path.
if [ -f "$dir/TODO.md" ]; then
  file="$dir/TODO.md"
else
  file="$HOME/Documents/TODO.md"
fi
file="$(cd "$(dirname "$file")" 2>/dev/null && pwd)/$(basename "$file")"

# If a window in the current session already has this exact file open, focus it.
# Scoped to the current session so we never switch sessions.
existing="$(tmux list-windows ${session:+-t "$session"} \
  -f "#{==:#{@todo_file},$file}" \
  -F '#{window_index}' | head -n1)"

if [ -n "$existing" ]; then
  tmux select-window -t "${session:+$session:}$existing"
  exit 0
fi

# Otherwise open a new window, auto-save the buffer, and tag the window.
editor="${EDITOR:-nvim}"
win="$(tmux new-window -P -F '#{window_id}' -c "$dir" \
  "$editor '+autocmd InsertLeave,TextChanged <buffer> silent write' '$file'")"
tmux set-option -w -t "$win" @todo_file "$file"
tmux set-option -w -t "$win" automatic-rename off
tmux rename-window -t "$win" TODO
