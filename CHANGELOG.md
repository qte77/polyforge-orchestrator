<!-- markdownlint-disable MD024 no-duplicate-heading -->

# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

**Types of changes**: `Added`, `Changed`, `Deprecated`, `Removed`, `Fixed`, `Security`

## [Unreleased]

### Added

- `scripts/generate-workspace.sh`: generates `workspace.code-workspace` (folders only) from `repos.conf` for multi-root sidebar
- WakaTime API key non-interactive setup via `WAKATIME_API_KEY` Codespace secret
- tmux installed via `apt-get` in `onCreateCommand`; `cc-repos.sh` creates detached session with per-repo windows
- tmux auto-attach via `.bashrc` — every new terminal opens into the repos session

### Changed

- `scripts/repos.conf`: dynamic `POLYFORGE_ROOT` detection (works at any checkout path)
- `workspace.code-workspace` is now generated (added to `.gitignore`)
- `onCreateCommand` uses `;` separators (each step runs independently)
- `cc-repos.sh`: creates detached session only (no `tmux attach` — `.bashrc` handles it)

### Removed

- `ghcr.io/devcontainers-contrib/features/tmux:1` — registry unavailable, crashes container build
- `code workspace.code-workspace` from `postAttachCommand` (spawned new VS Code instance)
- Workspace tasks (`runOn: folderOpen`) — do not fire in Codespaces
- tmux default terminal profile — crashes VS Code workbench if tmux not ready

### Fixed

- Sidebar folders not loading when polyforge is the main Codespace repo (path mismatch)
- Container recovery mode from `set -e` in `clone-repos.sh` and `&&` chain in `onCreateCommand`
- tmux auto-attach on every new terminal via `.bashrc` hook

## [0.0.1] - 2026-03-17

### Added

- `scripts/cc-repos.sh`: tmux session with one window per managed repo
- `scripts/cc-parallel.sh`: parallel `claude -p` across repos with presets (validate, status, security)
- `scripts/cc-credential-setup.sh`: unified git credential store, embedded PAT cleanup
- `scripts/cc-status.sh`: status dashboard (branch, dirty state, Ralph progress, last commit)
- `scripts/repos.conf`: single source of truth for managed repo list
- `config/env-loader.sh`: auth resolution (.env -> ~/.gh_pat -> env vars)
- `config/settings.user.json`: reference template for user-level CC settings
- `workspace.code-workspace`: VS Code multi-root workspace with all repos
- `.devcontainer/`: Codespace setup with repo cloning, dotfiles, tmux auto-start
- `docs/cross-repo-setup.md`: additionalDirectories + allowWrite pattern
- `docs/sandbox-friction.md`: 4 friction points with mitigations and research sources
- `docs/settings-consolidation.md`: DRY settings — user-level as single source of truth
