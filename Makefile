
.SILENT:
.ONESHELL:
.PHONY: \

	help update
.DEFAULT_GOAL := help

setup_all: \
	setup_gh_auth clone_repos setup_claude_code setup_claude_sandbox \
	setup_npm_tools setup_lychee setup_rtk generate


# MARK: SETUP


setup_gh_auth:  ## Configure gh as git credential helper (uses GH_TOKEN from containerEnv)
	gh auth setup-git

setup_claude_code:  ## Setup claude code CLI
	echo "Setting up Claude Code CLI ..."
	cp -r .claude/.claude.json ~/.claude.json
	if command -v claude > /dev/null 2>&1; then echo "claude already installed: $$(claude --version)"; \
	else curl -fsSL https://claude.ai/install.sh | bash; fi
	echo "Claude Code CLI version: $$(claude --version)"

setup_claude_sandbox:  ## Install sandbox deps (bubblewrap, socat) for Linux/WSL2
	# Required for Claude Code sandboxing on Linux/WSL2:
	# - bubblewrap: Provides filesystem and process isolation
	# - socat: Handles network socket communication for sandbox proxy
	# Without these, sandbox falls back to unsandboxed execution (security risk)
	# https://code.claude.com/docs/en/sandboxing
	# https://code.claude.com/docs/en/settings#sandbox-settings
	# https://code.claude.com/docs/en/security
	echo "Installing sandbox dependencies ..."
	if command -v apt-get > /dev/null; then
		sudo apt-get update -qq && sudo apt-get install -y bubblewrap socat
	elif command -v dnf > /dev/null; then
		sudo dnf install -y bubblewrap socat
	else
		echo "Unsupported package manager. Install bubblewrap and socat manually."
		exit 1
	fi
	echo "Sandbox dependencies installed."


setup_rtk:  ## Install RTK CLI for token-optimized LLM output (run outside CC session)
	if command -v rtk > /dev/null 2>&1; then echo "rtk already installed: $$(rtk --version)"; \
	else curl -fsSL https://raw.githubusercontent.com/rtk-ai/rtk/refs/heads/master/install.sh | sh; fi
	rtk init -g --auto-patch

# TODO: evaluate Python-native alternatives (pymarkdownlnt, mdformat, pylint R0801) to reduce npm dependency
setup_npm_tools:  ## Setup npm-based dev tools (markdownlint, jscpd). Requires node.js and npm
	echo "Setting up npm dev tools ..."
	npm install -gs markdownlint-cli jscpd
	echo "markdownlint version: $$(markdownlint --version)"
	echo "jscpd version: $$(jscpd --version)"

setup_lychee:  ## Install lychee link checker (Rust binary, requires sudo)
	if command -v lychee > /dev/null 2>&1; then echo "lychee already installed: $$(lychee --version)"; \
	else curl -sL https://github.com/lycheeverse/lychee/releases/latest/download/lychee-x86_64-unknown-linux-gnu.tar.gz | sudo tar xz -C /usr/local/bin lychee; fi
	echo "lychee version: $$(lychee --version)"


# MARK: GENERATE


generate:  ## Generate .vscode/tasks.json from workspace.code-workspace
	bash scripts/generate-tasks.sh


clone_repos:  ## Clone all managed repos from workspace.code-workspace
	bash scripts/clone-repos.sh


# MARK: HELP


help:  ## Show available recipes grouped by section
	@echo "Usage: make [recipe]"
	@echo ""
	@awk '/^# MARK:/ { \
		section = substr($$0, index($$0, ":")+2); \
		printf "\n\033[1m%s\033[0m\n", section \
	} \
	/^[a-zA-Z0-9_-]+:.*?##/ { \
		helpMessage = match($$0, /## (.*)/); \
		if (helpMessage) { \
			recipe = $$1; \
			sub(/:/, "", recipe); \
			printf "  \033[36m%-22s\033[0m %s\n", recipe, substr($$0, RSTART + 3, RLENGTH) \
		} \
	}' $(MAKEFILE_LIST)