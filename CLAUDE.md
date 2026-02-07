# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Personal dotfiles managed with GNU Stow. Each top-level directory (excluding `_`-prefixed and `.`-prefixed dirs) is a Stow package that gets symlinked into `~`.

The `_private` submodule (`dotfiles-private`) contains additional packages and its own CLAUDE.md with extended documentation.

## Commands

```bash
make stow          # Restow all packages (runs stow.sh)
make help          # Show available make targets
brew bundle install # Install Homebrew dependencies from Brewfile
git submodule update --init  # Initialize submodules (pure prompt, _private)
```

## How Stow Works Here

`stow.sh` iterates over top-level directories, skipping `_`-prefixed and `.`-prefixed ones, and runs `stow -R -t ~` on each. Then it runs `_private/stow.sh` if present.

Package structure: `<package>/.config/foo/bar` becomes `~/.config/foo/bar` via symlink.

Current public packages: `ghostty`, `nvim`, `tmux`, `vim`, `zsh`

## Key Architecture

- **Neovim** (`nvim/.config/nvim/`): Uses lazy.nvim for plugin management. Config split into `lua/config/` (options, keymaps, lazy bootstrap) and `lua/plugins/` (one file per plugin). LSP configs in `lsp/`. Leader key is Space.
- **Zsh** (`zsh/`): Oh-my-zsh with Pure prompt theme (from `_vendor/pure` submodule). Sources `~/.zshrc_alias`, `~/.zshrc_private`, `~/.zshrc_local` if they exist.
- **Tmux** (`tmux/`): Prefix is `C-a`. Uses TPM with catppuccin theme. vim-tmux-navigator for seamless pane/split navigation with `C-h/j/k/l`.
- **Ghostty** (`ghostty/.config/ghostty/`): IosevkaTerm Nerd Font, minimal config.
- **Vim** (`vim/`): Legacy `.vimrc` fallback.

## Conventions

- All Stow-managed files retain their dot prefix (e.g., `.zshrc`, `.tmux.conf`)
- Local customization via untracked files: `~/.zshrc_local`, `~/.vimrc.local`
- Consistent Catppuccin Mocha theme across nvim, tmux, and terminal
- `_vendor/` holds git submodules (currently: pure prompt)
- `.gitignore` patterns: `.DS_Store`, `.vscode/`, `bin/`, `*.local.*`
