help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  make %-15s %s\n", $$1, $$2}'

stow: ## Restow all packages
	@bash stow.sh

claude: stow ## Install/update Claude Code marketplace and plugin
	@if ! claude plugins marketplace list 2>/dev/null | grep -q 'cppcho'; then \
		claude plugins marketplace add "$(CURDIR)/_claude-marketplace"; \
	fi
	@claude plugins uninstall cppcho@cppcho 2>/dev/null; \
	claude plugins install cppcho@cppcho
