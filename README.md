<!-- markdownlint-disable MD033 -->
# polyforge-orchestrator

Orchestrate parallel AI coding agents across a polyrepo codebase from a single
devcontainer or vscode workspace.

[![License: Apache-2.0][license-badge]](LICENSE)
[![Version][version-badge]](CHANGELOG.md)
[![CodeFactor][codefactor-badge]][codefactor]

## What

- Run one Claude Code prompt across every repo in the workspace, in parallel
- Presets for repo-wide validation, a repo-wide security audit, and a
  diff-scoped review of untrusted PRs
- One multi-root VS Code workspace with a terminal task per repo, opened
  automatically
- Each sibling repo's own devcontainer setup replayed inside the host container
- One repo list (`config/repos.conf`) drives cloning, workspace generation and
  runs

<details>
  <summary>Workspace preview — multi-repo IDE layout with parallel terminals</summary>
  <img alt="polyforge-orchestrator workspace"
    src="assets/images/polyforge_screenshot.png"
    width="100%">
</details>

## How

```bash
./scripts/cc-parallel.sh --preset validate
./scripts/cc-parallel.sh --preset security-all  # repo-wide audit (all repos)
./scripts/cc-parallel.sh --preset security-pr   # diff-scoped, untrusted PRs
./scripts/cc-status.sh
```

Repos: edit `config/repos.conf`. Credentials: set `GH_PAT` as Codespace secret.
Setup lifecycle (`make setup_all` on create, `make setup_repos` on attach): see
[Codespaces](docs/codespaces.md).

## Why

A VS Code multi-root workspace only runs the host container's devcontainer
lifecycle, and an agent session works one repo at a time. For teams running
Claude Code (or other AI agents) across many repos at once, polyforge replays
each repo's setup in one container and fans a prompt out to all of them.

## Refs

- [Codespaces](docs/codespaces.md) — rebuild, secrets, management
- [Cross-repo setup](docs/cross-repo-setup.md) — auth, sandbox, settings
- [Cloud workflows](docs/cc-web-cloud-workflows.md) — remote execution
- [Sandbox friction](docs/sandbox-friction.md) — known issues, mitigations
- [Engineering-practice baseline][cto-mapping] — dev-loop presets mapped to the
  Startup CTO Handbook

## License

[Apache-2.0](LICENSE)

[license-badge]: https://img.shields.io/badge/License-Apache--2.0-blue.svg
[version-badge]: https://img.shields.io/badge/Version-0.1.0-blue.svg
[codefactor-badge]: https://www.codefactor.io/repository/github/qte77/polyforge-orchestrator/badge
[codefactor]: https://www.codefactor.io/repository/github/qte77/polyforge-orchestrator
[cto-mapping]: https://github.com/qte77/qte77/blob/main/docs/cto-handbook-mapping.md
