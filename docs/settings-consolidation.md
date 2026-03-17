# Settings Consolidation (DRY)

## Problem

Both user-level and project-level CC settings had `sandbox.filesystem.allowWrite: ["/workspaces"]`. Since `allowWrite` merges across scopes (additive), the project-level entry is redundant.

## Solution

Remove `sandbox.filesystem` from project-level settings entirely. User-level `~/.claude/settings.json` is the single source of truth for sandbox config.

### What Stays User-Level

- `permissions.additionalDirectories` — scope of Read/Write/Edit tools
- `sandbox.filesystem.allowWrite` — Bash sandbox write access
- `sandbox.network` — network isolation (shared across all repos)
- `model` — default model preference
- `enabledPlugins` — global plugins (e.g., pyright-lsp)

### What Stays Project-Level

- `env` — project-specific environment variables
- `permissions.allow/deny/ask` — project-specific tool permissions
- `enabledPlugins` — project-specific plugins
- `statusLine` — project-specific status display
- `attribution` — commit/PR attribution settings
- `sandbox.network.allowedHosts` — project-specific allowed hosts (additive)

### Applied To

- `/workspaces/Agents-eval/.claude/settings.json` — removed redundant `sandbox.filesystem` block
- `/workspaces/qte77/claude-code-research/.claude/settings.json` — removed redundant `sandbox.filesystem` block
- User-level `~/.claude/settings.json` — single source of truth for `additionalDirectories` + `allowWrite`
- Reference docs: `polyforge/docs/cross-repo-setup.md`, `polyforge/docs/sandbox-friction.md`
