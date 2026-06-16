<!-- markdownlint-disable MD033 -->
# polyforge-orchestrator

Orchestrate parallel AI coding agents across a polyrepo codebase from a single devcontainer or vscode workspace.

Run Claude Code (or any AI coding agent) in parallel across every repo in a polyrepo workspace from a single devcontainer. Generates a multi-root VS Code workspace with per-repo terminal tasks, bridges each repo's `devcontainer.json` lifecycle into the host container, and ships validate/security/test presets plus a contribution-task registry. Driven by `config/repos.conf` + `config/contributions.json`.

**For** teams running Claude Code (or other AI agents) across multiple repos simultaneously.
**Run** `./scripts/cc-parallel.sh --preset validate` to validate all repos in one command.

## Quick Start

```bash
./scripts/cc-parallel.sh --preset validate
./scripts/cc-parallel.sh --preset security-all   # repo-wide audit (all repos)
./scripts/cc-parallel.sh --preset security-pr    # diff-scoped, untrusted inbound PRs
./scripts/cc-status.sh
```

Repos: edit `config/repos.conf`. Credentials:
set `GH_PAT` as Codespace secret.

<details>
  <summary>Workspace preview — multi-repo IDE layout with parallel terminals</summary>
  <img alt="polyforge-orchestrator workspace"
    src="assets/images/polyforge_screenshot.png"
    width="100%">
</details>

## How It Works

On codespace creation (`make setup_all`), polyforge installs
shared tooling (Claude Code, RTK, lychee, markdownlint),
clones all repos from `config/repos.conf`, and generates
`workspace.code-workspace` with terminal tasks per repo.

On attach (`make setup_repos`), polyforge reads each
sibling repo's `devcontainer.json` and replays their
`onCreateCommand` / `postCreateCommand` inside the host
container. VS Code multi-root workspaces only honor the
host container's lifecycle, so sibling hooks would
otherwise be silently dropped — per-repo setup (deps,
tooling, hooks) would never run.

Terminal tasks auto-open via `runOn: folderOpen` in both
VS Code Desktop and Web.

## Docs

- [Codespaces](docs/codespaces.md) — rebuild, secrets, management
- [Cross-repo setup](docs/cross-repo-setup.md) — auth, sandbox, settings
- [Cloud workflows](docs/cc-web-cloud-workflows.md) — remote execution
- [Sandbox friction](docs/sandbox-friction.md) — known issues, mitigations
