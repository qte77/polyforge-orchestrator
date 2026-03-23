<!-- markdownlint-disable MD024 no-duplicate-heading -->

# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

**Types of changes**: `Added`, `Changed`, `Deprecated`, `Removed`, `Fixed`, `Security`

## [Unreleased]

### Added

- `scripts/generate-workspace.sh`: generates `workspace.code-workspace` (folders only) from `repos.conf`; VS Code auto-detects for multi-root sidebar
- WakaTime API key non-interactive setup via `WAKATIME_API_KEY` Codespace secret
- tmux devcontainer feature + `postAttachCommand` runs `cc-repos.sh` for per-repo tmux windows

### Changed

- `scripts/repos.conf`: dynamic `POLYFORGE_ROOT` detection (works at any checkout path)
- `workspace.code-workspace` is now generated (added to `.gitignore`)

### Removed

- `code workspace.code-workspace` from `postAttachCommand` (spawned new VS Code instance; sidebar loads automatically without it)
- Workspace tasks (`runOn: folderOpen`) — do not fire in Codespaces

### Fixed

- Sidebar folders not loading when polyforge is the main Codespace repo (path mismatch)
- Multiple terminals on startup via tmux (`cc-repos.sh`, Ctrl-b + number to switch)

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
