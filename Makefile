.SILENT:
.ONESHELL:
SHELL := /bin/bash
.PHONY: \
	help setup_all setup_repos setup_vscode setup_gh_auth setup_claude_code \
	setup_claude_sandbox setup_rtk setup_npm_tools setup_lychee \
	generate_tasks clone_repos
.DEFAULT_GOAL := help

# Source colors for all recipes
define _src_colors
source scripts/colors.sh
endef

# Pinned known-good versions (fallback when latest fails)
RTK_VERSION := 0.34.1
LYCHEE_VERSION := 0.23.0
MARKDOWNLINT_VERSION := 0.48.0
JSCPD_VERSION := 4.0.8


# MARK: SETUP


setup_all:  ## Run all setup steps (non-fatal: failures warn, don't abort)
	$(_src_colors)
	for target in setup_gh_auth clone_repos setup_claude_code setup_claude_sandbox \
		setup_npm_tools setup_lychee setup_rtk generate_tasks; do \
		$(MAKE) $$target || warn "$$target failed, continuing..."; \
	done
	success "Setup complete"

setup_gh_auth:  ## Configure gh as git credential helper (uses GH_TOKEN from containerEnv)
	$(_src_colors)
	if command -v gh > /dev/null 2>&1; then gh auth setup-git; \
	else warn "gh cli not installed. skipping auth."; fi

setup_claude_code:  ## Setup claude code CLI
	$(_src_colors)
	if command -v claude > /dev/null 2>&1; then info "claude already installed: $$(claude --version)"; \
	else \
		info "Installing Claude Code CLI..."; \
		curl -fsSL https://claude.ai/install.sh | bash \
		|| warn "claude install failed, skipping"; \
	fi
	command -v claude > /dev/null 2>&1 && success "Claude Code CLI version: $$(claude --version)" || true

setup_claude_sandbox:  ## Install sandbox deps (bubblewrap, socat) for Linux/WSL2
	# Required for Claude Code sandboxing on Linux/WSL2:
	# - bubblewrap: Provides filesystem and process isolation
	# - socat: Handles network socket communication for sandbox proxy
	# Without these, sandbox falls back to unsandboxed execution (security risk)
	# https://code.claude.com/docs/en/sandboxing
	# https://code.claude.com/docs/en/settings#sandbox-settings
	# https://code.claude.com/docs/en/security
	$(_src_colors)
	info "Installing sandbox dependencies ..."
	if command -v apt-get > /dev/null; then
		sudo apt-get update -qq && sudo apt-get install -y bubblewrap socat
	elif command -v dnf > /dev/null; then
		sudo dnf install -y bubblewrap socat
	else
		error "Unsupported package manager. Install bubblewrap and socat manually."
		exit 1
	fi
	success "Sandbox dependencies installed."


setup_rtk:  ## Install RTK CLI for token-optimized LLM output
	$(_src_colors)
	if command -v rtk > /dev/null 2>&1; then info "rtk already installed: $$(rtk --version)"; \
	else \
		info "Installing rtk (trying latest, fallback to v$(RTK_VERSION))..."; \
		GITHUB_TOKEN= GH_TOKEN= curl -fsSL https://raw.githubusercontent.com/rtk-ai/rtk/refs/heads/master/install.sh | GITHUB_TOKEN= GH_TOKEN= sh \
		|| GITHUB_TOKEN= GH_TOKEN= curl -fsSL "https://raw.githubusercontent.com/rtk-ai/rtk/refs/heads/master/install.sh" | GITHUB_TOKEN= GH_TOKEN= RTK_VERSION=$(RTK_VERSION) sh \
		|| warn "rtk install failed, skipping"; \
	fi
	command -v rtk > /dev/null 2>&1 && rtk init -g --auto-patch || true

setup_npm_tools:  ## Setup npm-based dev tools (markdownlint, jscpd) locally
	$(_src_colors)
	info "Setting up npm dev tools (local)..."
	npm install --save-dev markdownlint-cli jscpd \
		|| (warn "latest npm install failed, trying pinned versions..." && \
			npm install --save-dev markdownlint-cli@$(MARKDOWNLINT_VERSION) jscpd@$(JSCPD_VERSION)) \
		|| warn "npm tools install failed, skipping"
	npx markdownlint --version > /dev/null 2>&1 && success "markdownlint version: $$(npx markdownlint --version)" || true
	npx jscpd --version > /dev/null 2>&1 && success "jscpd version: $$(npx jscpd --version)" || true

setup_lychee:  ## Install lychee link checker (Rust binary, requires sudo)
	$(_src_colors)
	if command -v lychee > /dev/null 2>&1; then info "lychee already installed: $$(lychee --version)"; \
	else \
		info "Installing lychee (trying latest, fallback to v$(LYCHEE_VERSION))..."; \
		curl -sL https://github.com/lycheeverse/lychee/releases/latest/download/lychee-x86_64-unknown-linux-gnu.tar.gz | sudo tar xz -C /usr/local/bin lychee \
		|| curl -sL "https://github.com/lycheeverse/lychee/releases/download/lychee-v$(LYCHEE_VERSION)/lychee-x86_64-unknown-linux-gnu.tar.gz" | sudo tar xz -C /usr/local/bin lychee \
		|| warn "lychee install failed, skipping"; \
	fi
	command -v lychee > /dev/null 2>&1 && success "lychee version: $$(lychee --version)" || true


setup_repos:  ## Run each repo's devcontainer setup commands (uv, npm, etc.)
	# In a multi-root workspace only the host container's devcontainer lifecycle
	# runs. This recipe bridges the gap: it reads onCreateCommand and
	# postCreateCommand from each repo's devcontainer.json and executes them
	# inside the host container. Failures are non-fatal.
	$(_src_colors)
	source scripts/load-workspace-repos.sh
	for repo in "$${REPOS[@]:1}"; do \
		dc="$$repo/.devcontainer/devcontainer.json"; \
		if [[ ! -f "$$dc" ]]; then continue; fi; \
		name=$$(basename "$$repo"); \
		oncreate=$$(jq -r '.onCreateCommand // empty' "$$dc" 2>/dev/null); \
		postcreate=$$(jq -r '.postCreateCommand // empty' "$$dc" 2>/dev/null); \
		if [[ -z "$$oncreate" && -z "$$postcreate" ]]; then continue; fi; \
		info "$$name: running devcontainer setup..."; \
		(cd "$$repo" && \
			{ [[ -z "$$oncreate" ]] || eval "$$oncreate"; } && \
			{ [[ -z "$$postcreate" ]] || eval "$$postcreate"; } && \
			success "$$name: setup complete" \
		) || warn "$$name: setup failed, continuing"; \
	done


# MARK: VSCODE


start_workspace:  ## Open workspace in current VS Code window (manual use only)
	$(_src_colors)
	if command -v code > /dev/null 2>&1; then code -r workspace.code-workspace && success "Workspace opened"; \
	else warn "code CLI not available"; fi

clone_repos:  ## Clone all managed repos from config/repos.conf
	$(_src_colors)
	info "Cloning repos..."
	bash scripts/clone-repos.sh

generate_tasks:  ## Generate workspace.code-workspace from config/repos.conf
	$(_src_colors)
	info "Generating vscode tasks..."
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