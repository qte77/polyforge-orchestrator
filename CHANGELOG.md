<!-- markdownlint-disable MD024 no-duplicate-heading -->

# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

**Types of changes**: `Added`, `Changed`, `Deprecated`, `Removed`, `Fixed`, `Security`

## [Unreleased]

## [0.1.0] - 2026-09-23

### Changed

- `scripts/link-claude-home.sh`: replaced the hand-rolled `setup_claude_home` symlink logic with a
  vendored copy of `qte77/claude-code-plugins`' `workspace-setup` plugin script (1.5.1) — the plugin's
  own README documents "copy into your repo" as the intended distribution model, so this repo is now an
  actual consumer of that pattern instead of a second implementation to keep in sync by hand. Also
  picks up that version's target-verification fix (a stale symlink pointing elsewhere no longer reads
  as "already linked"). `docs/codespaces.md` updated: `qte77/dotfiles`'s own README confirms dotfiles
  installation only applies to new codespaces, not rebuilds of existing ones — `setup_claude_home` is
  the actual mechanism keeping `~/.claude` linked across a rebuild, not a backstop.

### Added

- `docs/codespaces.md`: "Contributing to external/untrusted repos" section — the two-layer
  credential-scoping model (Codespaces-secret `--repos` gates *injection*, the PAT's own
  repository-access list gates *reach*) and the safe pattern: a separate codespace with no secrets
  added, relying on GitHub's auto-injected `ghu_` token. Caveat on the "Escape hatch" section:
  unsetting `GH_TOKEN`/`GITHUB_TOKEN` is not privilege reduction or isolation — `hosts.yml` holds a
  second, equally broad `gho_` token. Matching `AGENT_LEARNINGS.md` entry (#86)
- `Makefile`: `setup_claude_home` target, run first in `setup_all` — idempotently re-links `~/.claude` to
  `/workspaces/.claude-files` on every container create/rebuild (the symlink itself lives outside
  `/workspaces` and is wiped on rebuild along with everything else there). `docs/codespaces.md`
  persistence-boundary section: what survives rebuild (`/workspaces`) vs. what doesn't (`$HOME`,
  including the symlink and `~/.claude.json`, which has no fix yet — see
  qte77/claude-code-plugins#199).

### Security

- `package-lock.json`: `smol-toml` 1.7.0 → 1.7.2 — fixes high-severity DoS via malformed TOML
  documents (Dependabot alert #7) (#85)
- `package-lock.json`: `js-yaml` 5.2.1 → 5.2.3 (advisory affecting the range left by the prior bump),
  `brace-expansion` 5.0.7 → 5.0.9 (newer advisory bypassing the prior 5.0.7 mitigation) — `npm audit`
  now reports 0 vulnerabilities.

### Fixed

- `clone-repos.sh`: seed `~/.wakatime.cfg` with tracking-safe defaults — `include_only_with_project_file` and `exclude_unknown_project` silently block all heartbeats when `true` (closes #30)

### Added

- `README.md`: "Engineering-practice baseline" Docs link → the qte77 estate note mapping the dev-loop presets (DevOps / testing / RCA) onto the Startup CTO Handbook
- `docs/codespaces.md`: token format prefix table (`ghu_` / `github_pat_` / etc., 1p-cited); GPG-signing diagnostics audit one-liner; reset/rebuild scope table; inherited-git-config subsection covering `commit.template` per-repo override; expanded References block with 1p `docs.github.com/en/codespaces/...` URLs. Absorbs research that was previously kept in `qte77/polyfetch-scrape/docs/codespaces-*.md` (now removed there in favour of this canonical home).
- `docs/codespaces.md` "Caveat: `GH_TOKEN=$GH_PAT` mapping may break `gh-gpgsign`" subsection — unverified hypothesis with side-by-side reproduction, confirming probe, and small fix path. Tracked under #64.
- `scripts/generate-workspace.sh`: generates `workspace.code-workspace` (folders only) from `repos.conf` for multi-root sidebar
- WakaTime API key non-interactive setup via `WAKATIME_API_KEY` Codespace secret
- tmux installed via `apt-get` in `onCreateCommand`; `cc-repos.sh` creates detached session with per-repo windows
- tmux auto-attach via `.bashrc` — every new terminal opens into the repos session

### Changed

- `scripts/repos.conf`: dynamic `POLYFORGE_ROOT` detection (works at any checkout path)
- `workspace.code-workspace` tracked in git (Codespaces auto-detects for multi-root sidebar)
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
