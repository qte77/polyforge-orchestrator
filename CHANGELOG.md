<!-- markdownlint-disable MD024 no-duplicate-heading -->

# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

**Types of changes**: `Added`, `Changed`, `Deprecated`, `Removed`, `Fixed`, `Security`

## [Unreleased]

### Added

- `scripts/generate-workspace.sh`: generates `workspace.code-workspace` with folders and per-repo split terminal tasks from `repos.conf`
- WakaTime API key non-interactive setup via `WAKATIME_API_KEY` Codespace secret
- tmux devcontainer feature for `cc-repos.sh` (CLI/SSH usage)

### Changed

- `scripts/repos.conf`: dynamic `POLYFORGE_ROOT` detection (works at any checkout path)
- `workspace.code-workspace` is now generated (added to `.gitignore`)
- `postAttachCommand`: replaced `code workspace.code-workspace` with user instruction echo; removed `cc-repos.sh` (VS Code terminals handled by workspace tasks)

### Fixed

- Sidebar folders not loading when polyforge is the main Codespace repo (path mismatch)
- Only one terminal on startup — workspace tasks now auto-open one split terminal per repo

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
