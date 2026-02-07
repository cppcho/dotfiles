# If you come from bash you might have to change your $PATH.
export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
#ZSH_THEME="robbyrussell"

# Use pure theme: https://github.com/sindresorhus/pure
ZSH_THEME=""

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
HIST_STAMPS="yyyy-mm-dd"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(z kubectl gcloud)

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi
export EDITOR='nvim'
alias vim='nvim'
alias vi='nvim'

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
[ -f ~/.z.sh ] && source ~/.z.sh
[ -f ~/.zshrc_mac ] && source ~/.zshrc_mac
[ -f ~/.zshrc_local ] && source ~/.zshrc_local

alias ta='tmux new-session -A -s cppcho'
alias update='brew update; brew upgrade; brew cleanup'
alias k=kubectl
# git worktree creation
gwt() {
  local new_branch="$1"
  if [[ -z "$new_branch" ]]; then echo "Usage: gwt <new-branch-name>"; return 1; fi

  # Find the main repo path regardless of where we are
  local main_repo
  main_repo=$(git worktree list 2>/dev/null | head -n1 | awk '{print $1}')

  if [[ -z "$main_repo" ]]; then
    echo "Error: Not inside a git repository."
    return 1
  fi

  # Check if branch exists
  if git show-ref --verify --quiet "refs/heads/$new_branch"; then
    echo "Error: Branch '$new_branch' already exists."
    return 1
  fi

  # Detect default branch (main or master)
  local default_branch
  if git show-ref --verify --quiet "refs/heads/main"; then
    default_branch="main"
  elif git show-ref --verify --quiet "refs/heads/master"; then
    default_branch="master"
  else
    echo "Error: Neither 'main' nor 'master' branch exists."
    return 1
  fi

  # Fetch latest from remote
  echo "Fetching latest $default_branch from origin..."
  git fetch origin "$default_branch"

  # Calculate path based on MAIN repo, not current dir
  local repo_name=$(basename "$main_repo")
  local parent_dir=$(dirname "$main_repo")
  local new_dir="$parent_dir/$repo_name-$new_branch"

  echo "Creating worktree from origin/$default_branch..."
  git worktree add --no-track -b "$new_branch" "$new_dir" "origin/$default_branch"

  if [[ $? -eq 0 ]]; then
    cd "$new_dir" || return 1
    echo "\nSwitched to: $new_dir"
  fi
}

# git worktree remove with fzf
gwt-rm() {
  # 1. Validation: Ensure we are inside a git repo
  local repo_root
  repo_root=$(git rev-parse --show-toplevel 2>/dev/null)
  if [ $? -ne 0 ]; then
    echo "Error: You are not inside a git repository."
    return 1
  fi

  # 2. Get the main repo path (always the first line in worktree list)
  local main_repo
  main_repo=$(git worktree list | head -n1 | awk '{print $1}')

  # 3. Select worktree to remove (exclude the main repo with sed '1d')
  local selected_line
  selected_line=$(git worktree list | sed '1d' | fzf --height 40% --reverse)

  if [ -z "$selected_line" ]; then
    echo "No worktree selected."
    return 0
  fi

  # 4. Extract the path from the selected line (1st column)
  local wt_path
  wt_path=$(echo "$selected_line" | awk '{print $1}')

  # 5. Safety Switch: If we are currently inside that worktree, move to main repo
  if [[ "$PWD" == "$wt_path"* ]]; then
    echo "You are inside the worktree to be deleted."
    echo "Switching to main repo: $main_repo"
    cd "$main_repo" || return 1
  fi

  # 6. Remove the worktree
  echo "Removing worktree: $wt_path"
  git worktree remove "$wt_path"
}

# https://github.com/sindresorhus/pure
fpath+=($HOME/dotfiles/_vendor/pure)
autoload -U promptinit; promptinit
PURE_CMD_MAX_EXEC_TIME=10
prompt pure

test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

# The following lines have been added by Docker Desktop to enable Docker CLI completions.
fpath=(/Users/cppcho/.docker/completions $fpath)
autoload -Uz compinit
compinit
# End of Docker CLI completions
