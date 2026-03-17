# Cross-Repo Setup

## User-Level Settings Pattern

Use `permissions.additionalDirectories` + `sandbox.filesystem.allowWrite` in `~/.claude/settings.json` (user-level, not per-project). This gives any CC session cross-repo access without per-project config or session restarts.

```json
{
  "permissions": {
    "additionalDirectories": ["/workspaces"]
  },
  "sandbox": {
    "filesystem": {
      "allowWrite": ["/workspaces"]
    }
  }
}
```

### What Each Setting Does

- **additionalDirectories**: Expands Read/Write/Edit tool scope beyond CWD
- **allowWrite** (additive): Expands Bash sandbox write access. Merges across scopes (user + project)

### DRY Consolidation

Since `allowWrite` merges across scopes, project-level `sandbox.filesystem` is redundant when user-level already covers `/workspaces`. Remove `sandbox.filesystem` from project-level settings entirely. User-level is the single source of truth for sandbox config.

Project-level settings should only contain project-specific concerns: `env` vars, `permissions` (allow/deny/ask), `plugins`, `statusLine`, `network.allowedHosts`.

### Scope Alignment

`additionalDirectories: ["/workspaces"]` matches `allowWrite: ["/workspaces"]` — both cover all repos under `/workspaces/`.

## Credential Management

### Best Approach: Codespaces Encrypted Secrets

Use Codespaces encrypted secrets (Settings -> Secrets -> Codespaces). The PAT is injected as `containerEnv` at container start — visible to all processes including CC sandbox. No `source`, no `.env`, no read permission issues.

```json
// devcontainer.json (already configured via Codespaces Settings -> Secrets)
{
  "containerEnv": {
    "GH_PAT": "${localEnv:GH_PAT}"
  }
}
```

### Fallback: env-loader.sh

For non-Codespaces environments, use `config/env-loader.sh` which resolves from `.env` -> `~/.gh_pat` -> env vars (precedence order).
