# Sandbox Friction in Devcontainers

## Key Issues

1. **Cross-repo writes blocked** — `allowWrite` defaults
   to CWD. Fix: `allowWrite: ["/workspaces"]` at
   user-level.
1. **Git operations restricted** — Git writes to `.git/`
   outside CWD. `excludedCommands: ["git"]` alone does
   NOT work
   ([#28730](https://github.com/anthropics/claude-code/issues/28730)).
   Need `allowWrite` with repo paths.
1. **Path prefix gotcha** — Misconfigured prefixes
   silently ignored
   ([#32287](https://github.com/anthropics/claude-code/issues/32287)).
   Use `//` for absolute, `~/` for home-relative.
1. **No hot-reload** — Sandbox config loaded at session
   startup only.

## Recommended Config

Hybrid: full filesystem access, network isolation kept.
Container handles filesystem isolation.

```json
{
  "sandbox": {
    "enabled": true,
    "autoAllowBashIfSandboxed": true,
    "filesystem": {
      "allowWrite": ["/workspaces"]
    },
    "network": {
      "allowedDomains": [
        "api.github.com",
        "*.githubusercontent.com"
      ]
    }
  }
}
```

## References

- [CC Sandboxing docs](https://code.claude.com/docs/en/sandboxing)
- [trailofbits/claude-code-devcontainer](https://github.com/trailofbits/claude-code-devcontainer)
