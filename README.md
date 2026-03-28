<!-- markdownlint-disable MD033 -->
# polyforge

Polyrepo dev forge for parallel AI agent workflows.

<picture>
  <source media="(prefers-color-scheme: dark)"
    srcset="assets/images/polyforge-dark.svg">
  <source media="(prefers-color-scheme: light)"
    srcset="assets/images/polyforge-light.svg">
  <img alt="polyforge workspace"
    src="assets/images/polyforge-dark.svg"
    width="100%">
</picture>

> **USP**: Orchestrate AI coding agents across N repos
> in parallel — unified status and execution.
>
> **ICP**: Solo devs and small teams running AI agents
> across a polyrepo codebase in Codespaces.
>
> **CTA**: `./scripts/cc-parallel.sh --preset validate`

## Quick Start

### Parallel AI Agent Execution

```bash
./scripts/cc-parallel.sh --preset validate
./scripts/cc-parallel.sh --preset security
./scripts/cc-parallel.sh "Check TODOs" \
  /workspaces/qte77/Agents-eval
```

### Status Dashboard

```bash
./scripts/cc-status.sh
./scripts/cc-status.sh --verbose
```

## Configuration

### Repo List

Edit `workspace.code-workspace` to add/remove repos.
All scripts read from this single file.

### Environment

Codespaces encrypted secrets via `containerEnv` in
`devcontainer.json` (`GH_PAT`, `WAKATIME_API_KEY`).
Alternative: copy `.env.example` to `.env` and
`source .env`.

### Cloud Execution (CC Web)

```bash
claude --remote "Run make validate" \
  --repo github.com/qte77/Agents-eval
```

See `docs/cc-web-cloud-workflows.md` for details.

## Docs

- `docs/cc-web-cloud-workflows.md` — Cloud execution
- `docs/cross-repo-setup.md` — CC multi-repo settings
- `docs/sandbox-friction.md` — Sandbox mitigations
