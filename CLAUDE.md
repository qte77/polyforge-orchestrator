# polyforge-orchestrator

Orchestrate parallel AI coding agents across a polyrepo codebase. See `README.md` for usage.

Scripts in `scripts/` manage all repos listed in `config/repos.conf` (single source of truth).
Config in `config/` handles repo list, keybindings, and environment loading.
Docs in `docs/` cover CC settings patterns and sandbox friction mitigations.

Setup: `onCreateCommand` runs `make setup_all` (shared tooling + clone + workspace gen).
`postAttachCommand` runs `make setup_repos setup_dotfiles start_workspace`.
Dirty re-deploy: `make setup_dirty` (force-overwrites stale `~/.claude/settings.json`, re-runs RTK + workspace gen).
