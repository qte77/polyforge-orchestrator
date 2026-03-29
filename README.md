<!-- markdownlint-disable MD033 -->
# polyforge-orchestrator

Orchestrate parallel AI coding agents across
a polyrepo codebase from a single Codespace
or devcontainer.

**For** teams running Claude Code (or other AI agents)
across multiple repos simultaneously.
**Run** `./scripts/cc-parallel.sh --preset validate`
to validate all repos in one command.

## Quick Start

```bash
./scripts/cc-parallel.sh --preset validate
./scripts/cc-parallel.sh --preset security
./scripts/cc-status.sh
```

Repos: edit `config/repos.conf`. Credentials:
set `GH_PAT` as Codespace secret.

<details>
  <summary>Workspace preview — multi-repo IDE layout with parallel terminals</summary>
  <img alt="polyforge-orchestrator workspace"
    src="assets/images/polyforge.svg"
    width="100%">
</details>

## Docs

- [Codespaces](docs/codespaces.md) — rebuild, secrets, management
- [Cross-repo setup](docs/cross-repo-setup.md) — auth, sandbox, settings
- [Cloud workflows](docs/cc-web-cloud-workflows.md) — remote execution
- [Sandbox friction](docs/sandbox-friction.md) — known issues, mitigations
