# Dotfiles update check - alerts once per day about unpulled/unpushed changes
# Inspired by oh-my-zsh's update checking mechanism

() {
  local dotfiles_dir="$HOME/dotfiles"
  local cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/dotfiles"
  local cache_file="$cache_dir/.dotfiles-update"
  local check_frequency=1  # days between checks

  # Only check if dotfiles dir exists and is a git repo
  [[ -d "$dotfiles_dir/.git" ]] || return 0

  # Only check in interactive shells with a TTY
  [[ -t 1 ]] || return 0

  # Ensure cache directory exists
  [[ -d "$cache_dir" ]] || mkdir -p "$cache_dir"

  # Current epoch in days
  local current_epoch=$(( EPOCHSECONDS / 60 / 60 / 24 ))

  # Read last check epoch
  local last_epoch=0
  if [[ -f "$cache_file" ]]; then
    source "$cache_file" 2>/dev/null
    local LAST_EPOCH=${LAST_EPOCH:-0}
    last_epoch=$LAST_EPOCH
  fi

  # Skip if checked recently
  if (( current_epoch - last_epoch < check_frequency )); then
    return 0
  fi

  # Update the cache file immediately to avoid repeated checks on multiple shells
  echo "LAST_EPOCH=$current_epoch" >| "$cache_file"

  # Run the check in a subshell to avoid polluting the environment
  local unpulled=0
  local unpushed=0
  local branch

  branch=$(git -C "$dotfiles_dir" symbolic-ref --short HEAD 2>/dev/null) || return 0
  local remote
  remote=$(git -C "$dotfiles_dir" config "branch.$branch.remote" 2>/dev/null) || return 0

  # Fetch with a timeout to avoid blocking shell startup
  git -C "$dotfiles_dir" fetch "$remote" "$branch" --quiet 2>/dev/null &
  local fetch_pid=$!

  # Wait up to 5 seconds for fetch
  local waited=0
  while kill -0 "$fetch_pid" 2>/dev/null && (( waited < 5 )); do
    sleep 1
    (( waited++ ))
  done

  if kill -0 "$fetch_pid" 2>/dev/null; then
    # Fetch is taking too long, skip this check
    kill "$fetch_pid" 2>/dev/null
    wait "$fetch_pid" 2>/dev/null
    return 0
  fi
  wait "$fetch_pid" 2>/dev/null

  # Count unpulled commits (remote ahead of local)
  unpulled=$(git -C "$dotfiles_dir" rev-list --count "$branch..$remote/$branch" 2>/dev/null)
  unpulled=${unpulled:-0}

  # Count unpushed commits (local ahead of remote)
  unpushed=$(git -C "$dotfiles_dir" rev-list --count "$remote/$branch..$branch" 2>/dev/null)
  unpushed=${unpushed:-0}

  # Auto-pull if there are unpulled commits and no conflicts
  if (( unpulled > 0 )); then
    # Check if a fast-forward merge is possible (no local divergence)
    local merge_base
    merge_base=$(git -C "$dotfiles_dir" merge-base "$branch" "$remote/$branch" 2>/dev/null)
    local local_head
    local_head=$(git -C "$dotfiles_dir" rev-parse "$branch" 2>/dev/null)

    if [[ "$merge_base" == "$local_head" ]]; then
      # Fast-forward is possible, auto-pull
      print -P "%F{green}[dotfiles]%f Auto-pulling $unpulled commit(s) from $remote/$branch..."
      if git -C "$dotfiles_dir" merge --ff-only "$remote/$branch" --quiet 2>/dev/null; then
        print -P "%F{green}[dotfiles]%f Pull successful. Running make stow and make claude..."
        (cd "$dotfiles_dir" && make stow 2>&1 | sed 's/^/  /')
        (cd "$dotfiles_dir" && make claude 2>&1 | sed 's/^/  /')
        print -P "%F{green}[dotfiles]%f Update complete."
        unpulled=0
      else
        print -P "%F{red}[dotfiles]%f Auto-pull failed. Run manually: %F{cyan}git -C ~/dotfiles pull%f"
      fi
    else
      # Local and remote have diverged, cannot fast-forward
      print -P "%F{yellow}[dotfiles]%f $unpulled unpulled commit(s) from $remote/$branch (cannot fast-forward, local has diverged). Run: %F{cyan}git -C ~/dotfiles pull%f"
    fi
  fi

  if (( unpushed > 0 )); then
    print -P "%F{yellow}[dotfiles]%f $unpushed unpushed commit(s) on $branch. Run: %F{cyan}git -C ~/dotfiles push%f"
  fi
}
