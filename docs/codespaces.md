# Codespaces

## Devcontainer Lifecycle

polyforge uses two lifecycle hooks in `devcontainer.json`:

- **`onCreateCommand`** (`make setup_all`) — installs shared
  tooling, clones repos, generates workspace file. Runs once
  on container creation.
- **`postAttachCommand`** (`make setup_repos`) — runs each
  repo's `onCreateCommand` + `postCreateCommand` from their
  own `devcontainer.json` inside the host container. This is
  needed because multi-root workspaces only execute the host
  container's devcontainer lifecycle, not the workspace folders'.

Terminal tasks (`runOn: folderOpen`) in `workspace.code-workspace`
auto-open a shell per repo. Controlled by the
`task.allowAutomaticTasks: "on"` setting.

## Rebuild

After changing `devcontainer.json`, rebuild to apply:

```bash
gh codespace rebuild                # rebuild current
gh codespace rebuild --full         # clean rebuild (no cache)
gh codespace rebuild -c <name>      # rebuild specific codespace
```

Or via VS Code command palette:
**Ctrl+Shift+P** → `Codespaces: Rebuild Container`

Note: `Dev Containers: Rebuild Container` works for
local devcontainers, not Codespaces.

## Management

Manage any Codespace from within polyforge-orchestrator using `-c`:

```bash
gh codespace list
gh codespace stop  -c <name>
gh codespace start -c <name>    # (re-)start a stopped codespace
gh codespace ssh   -c <name>
gh codespace delete -c <name>
gh codespace logs  -c <name>
```

## Secrets

Secrets are set at user level and scoped to repos:

```bash
gh secret set GH_PAT --user --repos qte77/polyforge-orchestrator
gh secret list --user
```

Secrets are injected as env vars. Map them in
`devcontainer.json` via `containerEnv`:

```json
"containerEnv": {
    "GH_PAT": "${localEnv:GH_PAT}",
    "GH_TOKEN": "${localEnv:GH_PAT}"
}
```

See `docs/cross-repo-setup.md` for auth details.

## Token scopes

The Codespaces-injected `GITHUB_TOKEN` and fine-grained
PATs (`GH_PAT`) have different scope coverage:

| Operation | `GITHUB_TOKEN` | `GH_PAT` (fine-grained) |
|-----------|:-:|:-:|
| `gh codespace list/rebuild/stop` | Yes | Needs `codespace` scope |
| `gh pr create` | No | Needs `pull_requests:write` |
| `git push` | Scoped to current repo | Needs `contents:write` |
| `git push` (protected branch) | No | Needs `administration:write` |

Set `GH_PAT` scopes to cover `gh` and `git` operations.
Codespace management (`rebuild`, `stop`, etc.) uses the
default `GITHUB_TOKEN` unless `GH_PAT` includes `codespace`.

## Token precedence — what wins when multiple are set

When more than one credential source is present, both `gh` and `git`
follow this precedence:

1. **`GITHUB_TOKEN`** env var — wins outright if set
2. **`GH_TOKEN`** env var — wins over hosts.yml
3. **hosts.yml OAuth token** — used only when neither env var is set

The trap: `GITHUB_TOKEN` or `GH_TOKEN` set in your environment
**silently shadows** the hosts.yml OAuth token. If the env-var token has
narrower scope than the OAuth one, cross-repo writes can fail with `403`
even though `gh auth status` looks healthy.

### Convention: `GH_PAT` as the named override

Standardize on a single named env var, `GH_PAT`, as the *intentional*
override. `containerEnv` in `.devcontainer/devcontainer.json` already
forwards it and aliases `GH_TOKEN=${localEnv:GH_PAT}`:

```json
"containerEnv": {
    "GH_PAT": "${localEnv:GH_PAT}",
    "GH_TOKEN": "${localEnv:GH_PAT}"
}
```

When you want write access through a fine-grained PAT, set `GH_PAT` in
your local environment. Everything else flows from there. No need to set
`GITHUB_TOKEN` or `GH_TOKEN` directly.

### Escape hatch: explicitly drop env precedence

When env-var precedence must be dropped (e.g. third-party install
scripts that fight your token), prefix the command with explicit
clearing:

```bash
GITHUB_TOKEN= GH_TOKEN= some-command
```

This is already the canonical pattern in `Makefile`'s `setup_rtk`
target — see lines around the `curl … rtk install.sh` invocation. Use
it as the example when documenting any new automation that must run
under a different token (or no token at all).

## Ports and Forwarding

```bash
gh codespace ports
gh codespace ports forward 8080:8080
```

## References

- [Codespaces docs](https://docs.github.com/en/codespaces)
- [gh codespace CLI](https://cli.github.com/manual/gh_codespace)
