# If you come from bash you might have to change your $PATH.
export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
#ZSH_THEME="robbyrussell"
ZSH_THEME="agnoster"

# Agnoster Color Settings

# https://github.com/sainnhe/everforest/blob/master/autoload/lightline/colorscheme/everforest.vim
EVERFOREST_BG0=8
EVERFOREST_BG1=9
EVERFOREST_BG3=10
EVERFOREST_ORANGE=11
EVERFOREST_GREY0=12
EVERFOREST_GREY1=13
EVERFOREST_GREY2=14

# color combinations (fg / bg):
# - bg0 / green
# - bg0 / white
# - bg0 / red
# - bg0 / orange
# - bg0 / cyan
# - bg0 / magenta
# - grey1 / bg1
# - grey2 / bg3
# - white / bg1
# - white / bg3

CURRENT_FG=$EVERFOREST_BG0
CURRENT_DEFAULT_FG=$EVERFOREST_BG0
AGNOSTER_DIR_FG=$EVERFOREST_BG0
AGNOSTER_DIR_BG=blue
AGNOSTER_CONTEXT_FG=white
AGNOSTER_CONTEXT_BG=$EVERFOREST_BG1
AGNOSTER_GIT_CLEAN_FG=$EVERFOREST_BG0
AGNOSTER_GIT_CLEAN_BG=green
AGNOSTER_GIT_DIRTY_FG=$EVERFOREST_BG0
AGNOSTER_GIT_DIRTY_BG=yellow
AGNOSTER_VENV_FG=$EVERFOREST_BG0
AGNOSTER_VENV_BG=cyan
AGNOSTER_AWS_PROD_FG=$EVERFOREST_BG0
AGNOSTER_AWS_PROD_BG=red
AGNOSTER_AWS_FG=$EVERFOREST_BG0
AGNOSTER_AWS_BG=cyan
AGNOSTER_STATUS_FG=white
AGNOSTER_STATUS_BG=$EVERFOREST_BG1

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
plugins=(git z kubectl asdf uv)

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
alias t=task

test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

