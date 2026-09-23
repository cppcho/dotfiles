# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Personal dotfiles managed with GNU Stow. Each top-level directory (excluding `_`-prefixed and `.`-prefixed dirs) is a Stow package that gets symlinked into `~`.

This repo is only the public half. The private packages live in the private `cppcho/my-stuff` repo under `dotfiles/`, cloned at `~/dev/my-stuff/dotfiles`. It has its own `stow.sh` and is stowed separately, so `make stow` here does not touch them.

## Commands

```bash
make stow          # Restow all packages (runs stow.sh)
make claude        # Install/update Claude Code marketplace and plugin
make help          # Show available make targets
brew bundle install # Install Homebrew dependencies from Brewfile
git submodule update --init  # Initialize submodules
```

## How Stow Works Here

`stow.sh` iterates over top-level directories, skipping `_`-prefixed and `.`-prefixed ones, and runs `stow -R -t ~` on each.

Package structure: `<package>/.config/foo/bar` becomes `~/.config/foo/bar` via symlink.

## Claude Code Plugin

`_claude-marketplace/` is a local Claude Code marketplace containing the `cppcho` plugin of personal skills. It's `_`-prefixed so Stow ignores it. Run `make claude` to register the marketplace and install/update the plugin.

After any change under `_claude-marketplace/plugins/cppcho/skills/` — adding, editing, renaming, or deleting a skill — run `make claude` to reload it. The installed plugin is a snapshot copied into `~/.claude/plugins/cache/`, so edits to the source have no effect until it is reinstalled.

## Conventions

- **Neovim** (`nvim/.config/nvim/`): lazy.nvim; `lua/config/` for options/keymaps/bootstrap, `lua/plugins/` one file per plugin, LSP configs in `lsp/`
- `vim/` is a legacy `.vimrc` fallback — nvim changes don't need mirroring into it
- All Stow-managed files retain their dot prefix (e.g., `.zshrc`, `.tmux.conf`)
- Local customization via untracked files: `~/.zshrc_local`, `~/.vimrc.local`
- Consistent Catppuccin Mocha theme across nvim, tmux, and terminal
- `_vendor/` holds git submodules
- Zsh aliases go in `zsh/.zshrc_alias` (`~/.zshrc_alias`), not in `.zshrc`
