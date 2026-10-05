help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  make %-15s %s\n", $$1, $$2}'

brew: ## Install Homebrew dependencies from Brewfile
	brew bundle install

stow: ## Restow all packages
	@bash stow.sh

install: brew stow claude launchd git-hooks ## Setup everything (brew, stow, claude, launchd, git-hooks)

# Config-based hooks (git 2.54+) run in every repo alongside the repo's own
# hooks, so a husky/lefthook core.hooksPath doesn't shadow them.
git-hooks: ## Register global git hooks
	@git config set --global hook.herdr-pr-status.command \
		'[ "$$3" = 1 ] && { ~/bin/herdr-pr-status --refresh-here >/dev/null 2>&1 & } ; true'
	@git config set --global --all hook.herdr-pr-status.event post-checkout
	@echo "registered herdr-pr-status (post-checkout)"

claude: ## Install/update Claude Code marketplace and plugin
	@if ! claude plugins marketplace list 2>/dev/null | grep -q 'cppcho'; then \
		claude plugins marketplace add "$(CURDIR)/_claude-marketplace"; \
	fi
	@claude plugins uninstall cppcho@cppcho 2>/dev/null; \
	claude plugins install cppcho@cppcho

# launchd user agents (macOS). Templates in _launchd/ are rendered into
# ~/Library/LaunchAgents with real paths, then (re)loaded. Depends on the
# stowed ~/bin scripts, so run `make stow` first (or via `make install`).
BREW_BASH   := $(shell brew --prefix)/bin/bash
AGENTS_DIR  := $(HOME)/Library/LaunchAgents
UID         := $(shell id -u)
AGENTS      := com.cppcho.herdr-tab-autoname com.cppcho.herdr-pr-status

launchd: ## Render & load launchd agents from _launchd/
	@mkdir -p $(AGENTS_DIR) $(HOME)/Library/Logs
	@for a in $(AGENTS); do \
		sed -e 's|__BASH__|$(BREW_BASH)|g' \
		    -e "s|__SCRIPT__|$(HOME)/bin/$${a#com.cppcho.}|g" \
		    -e "s|__LOG__|$(HOME)/Library/Logs/$${a#com.cppcho.}.log|g" \
		    _launchd/$$a.plist > $(AGENTS_DIR)/$$a.plist; \
		launchctl bootout gui/$(UID)/$$a 2>/dev/null || true; \
		launchctl bootstrap gui/$(UID) $(AGENTS_DIR)/$$a.plist; \
		echo "loaded $$a"; \
	done

uninstall-launchd: ## Unload & remove launchd agents
	@for a in $(AGENTS); do \
		launchctl bootout gui/$(UID)/$$a 2>/dev/null || true; \
		rm -f $(AGENTS_DIR)/$$a.plist; \
		echo "removed $$a"; \
	done
