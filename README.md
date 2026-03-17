# polyforge

Polyrepo dev forge for parallel AI agent workflows across multiple repositories.

> **USP**: Orchestrate AI coding agents across N repos in parallel — unified credentials, status, and execution from one place.
>
> **ICP**: Solo devs and small teams running AI agents (Claude Code, Cursor) across a polyrepo codebase in Codespaces/devcontainers.
>
> **CTA**: `./scripts/cc-parallel.sh --preset validate` — validate all your repos in one command.

## Quick Start

### VS Code Multi-Root Workspace

```bash
code workspace.code-workspace    # All repos in sidebar + auto-terminal panes
```

### Parallel AI Agent Execution

```bash
./scripts/cc-parallel.sh --preset status     # Git status across all repos
./scripts/cc-parallel.sh --preset validate   # Run make validate everywhere
./scripts/cc-parallel.sh --preset security   # Security audit all repos
./scripts/cc-parallel.sh "Check for TODO comments" /workspaces/Agents-eval
```

### tmux Sessions

```bash
./scripts/cc-repos.sh          # One tmux window per repo
```

### Status Dashboard

```bash
./scripts/cc-status.sh             # Branch, status, Ralph state per repo
./scripts/cc-status.sh --verbose   # Include uncommitted file list
```

### Credential Setup

```bash
./scripts/cc-credential-setup.sh   # Unify git credentials, clean embedded PATs
```

## Configuration

### Repo List

Edit `scripts/repos.conf` to add/remove managed repos. All scripts source this single file.

### Environment

Copy `.env.example` to `.env` and fill in credentials. Scripts source `config/env-loader.sh` which resolves from `.env` -> `~/.gh_pat` -> env vars.

Best long-term approach: Codespaces encrypted secrets via `containerEnv` in `devcontainer.json`.

### Claude Code Settings

See `config/settings.user.json` for a reference template. Key pattern: `additionalDirectories` + `allowWrite` at user level covers all repos without per-project config.

## Docs

- `docs/cross-repo-setup.md` — additionalDirectories + allowWrite pattern
- `docs/sandbox-friction.md` — 4 friction points with mitigations
- `docs/settings-consolidation.md` — DRY: user-level as single source of truth
