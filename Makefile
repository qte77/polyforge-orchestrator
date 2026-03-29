.SILENT:
.ONESHELL:
.PHONY: \
	help setup_all setup_vscode setup_gh_auth setup_claude_code \
	setup_claude_sandbox setup_rtk setup_npm_tools setup_lychee \
	generate_tasks clone_repos
.DEFAULT_GOAL := help


# MARK: SETUP


setup_all: \
	setup_gh_auth clone_repos setup_claude_code setup_claude_sandbox \
	setup_npm_tools setup_lychee setup_rtk generate_tasks start_workspace

setup_gh_auth:  ## Configure gh as git credential helper (uses GH_TOKEN from containerEnv)
	if command -v gh > /dev/null 2>&1; then gh auth setup-git; \
	else echo "gh cli not installed. skipping auth."; fi

setup_claude_code:  ## Setup claude code CLI
	echo "Setting up Claude Code CLI ..."
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


setup_rtk:  ## Install RTK CLI for token-optimized LLM output
	if command -v rtk > /dev/null 2>&1; then echo "rtk already installed: $$(rtk --version)"; \
	else GITHUB_TOKEN= GH_TOKEN= curl -fsSL https://raw.githubusercontent.com/rtk-ai/rtk/refs/heads/master/install.sh | GITHUB_TOKEN= GH_TOKEN= sh; fi
	rtk init -g --auto-patch

setup_npm_tools:  ## Setup npm-based dev tools (markdownlint, jscpd). Requires node.js and npm
	echo "Setting up npm dev tools ..."
	npm install -gs markdownlint-cli jscpd
	echo "markdownlint version: $$(markdownlint --version)"
	echo "jscpd version: $$(jscpd --version)"

setup_lychee:  ## Install lychee link checker (Rust binary, requires sudo)
	if command -v lychee > /dev/null 2>&1; then echo "lychee already installed: $$(lychee --version)"; \
	else curl -sL https://github.com/lycheeverse/lychee/releases/latest/download/lychee-x86_64-unknown-linux-gnu.tar.gz | sudo tar xz -C /usr/local/bin lychee; fi
	echo "lychee version: $$(lychee --version)"


# MARK: VSCODE


start_workspace:  ## Open workspace in current VS Code window and merge keybindings
	code_user="$$HOME/.config/Code/User"
	mkdir -p "$$code_user"
	if command -v jq > /dev/null 2>&1 && [ -f "$$code_user/keybindings.json" ]; then \
		jq -s 'add | unique_by(.command)' "$$code_user/keybindings.json" config/keybindings.json \
			> "$$code_user/keybindings.tmp" && mv "$$code_user/keybindings.tmp" "$$code_user/keybindings.json"; \
	else \
		cp -n config/keybindings.json "$$code_user/keybindings.json" 2>/dev/null || true; \
	fi
	if command -v code > /dev/null 2>&1; then code -r workspace.code-workspace; fi

clone_repos:  ## Clone all managed repos from config/repos.conf
	echo "Cloning repos..."
	bash scripts/clone-repos.sh

generate_tasks:  ## Generate workspace.code-workspace from config/repos.conf
	echo "Generating vscode tasks..."
	bash scripts/generate-tasks.sh


# MARK: HELP


help:  ## Show available recipes grouped by section
	echo "Usage: make [recipe]"
	echo ""
	awk '/^# MARK:/ { \
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