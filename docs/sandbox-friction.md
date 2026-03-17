# Sandbox Friction Points in Devcontainer/Codespaces

## Research Sources

- anthropics/claude-code #24546 — sandbox blocks git commit in devcontainer
- anthropics/claude-code #28730 — excludedCommands doesn't bypass bwrap filesystem restrictions
- anthropics/claude-code #32287 — allowWrite/denyWrite silently ignores misconfigured path prefixes
- anthropics/claude-code #927 — --dangerously-skip-permissions in devcontainer
- trailofbits/claude-code-devcontainer (536 stars) — bypass mode inside container
- trailofbits/claude-code-config (1613 stars) — opinionated sandbox config
- bjorn.now TIL — excludedCommands requires BOTH permission + exclusion
- codewithandrea.com — safe autonomous execution in devcontainer
- CC Sandboxing docs, CC Settings docs

## Friction 1: Cross-Repo Operations Blocked

**Root cause**: `write.allowOnly` defaults to CWD.

**Fix**: `allowWrite: ["/workspaces"]` + `additionalDirectories` at user-level.

**Gotcha** (#32287): Path prefixes silently ignored if misconfigured. Use `//` for absolute, `~/` for home-relative.

## Friction 2: Git/gh Operations Restricted

**Root cause**: Git writes to `.git/` and temp dirs outside CWD.

**Important**: `excludedCommands: ["git"]` does NOT work per #28730 — bwrap still blocks filesystem access.

**Fix**: `allowWrite` with repo paths + permissions.

Per bjorn.now: Need BOTH `permissions.allow` (grants permission) AND `excludedCommands` (runs unsandboxed).

## Friction 3: Credential Sourcing Blocked

**Root cause**: `Bash(source:*)` may be in deny list. `.env` reading blocked by `Read(.env)` deny rule.

**Best approach for Codespaces**: `devcontainer.json` -> `containerEnv` -> always available, no sourcing needed.

**Alternative**: `apiKeyHelper` CC setting (designed for credential scripts).

## Friction 4: No Hot-Reload for Sandbox Settings

**Root cause**: Sandbox config loaded at session startup only.

**Fix**: Get config right in user-level `~/.claude/settings.json` (applies to all future sessions).

`/sandbox` command re-checks status but doesn't reload config.

## Strategic Options

| Option | Description | Use when |
|--------|-------------|----------|
| A: Sandbox ON + ergonomics | `allowWrite` + `additionalDirectories` | Default |
| B: Sandbox OFF (Trail of Bits) | `sandbox.enabled: false` | Container IS the sandbox, CC sandbox redundant |
| C: Hybrid (network only) | Full filesystem access, network isolation kept | Best of both worlds for Codespaces |

**Recommended: Option C** — keeps network isolation (prevents prompt injection exfiltration) while eliminating all filesystem friction. Container handles filesystem isolation.

```json
{
  "sandbox": {
    "enabled": true,
    "autoAllowBashIfSandboxed": true,
    "filesystem": { "allowWrite": ["/workspaces"] },
    "network": { "allowedDomains": ["api.github.com", "*.githubusercontent.com"] }
  }
}
```
