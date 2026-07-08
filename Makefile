help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  make %-15s %s\n", $$1, $$2}'

brew: ## Install Homebrew dependencies from Brewfile
	brew bundle install

stow: ## Restow all packages
	@bash stow.sh

install: brew stow claude launchd ## Setup everything (brew, stow, claude, launchd)

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
AGENTS      := com.cppcho.herdr-tab-autoname

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
