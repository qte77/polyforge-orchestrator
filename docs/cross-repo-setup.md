# Cross-Repo Setup

## User-Level Settings

Use `additionalDirectories` + `allowWrite` in
`~/.claude/settings.json` to give any CC session cross-repo
access without per-project config.

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

- **additionalDirectories**: Expands Read/Write/Edit
  tool scope beyond CWD
- **allowWrite**: Expands Bash sandbox write access
  (additive across scopes)

Since `allowWrite` merges across scopes, project-level
`sandbox.filesystem` is redundant. User-level is the
single source of truth for sandbox config.

## Credentials

### Primary: `containerEnv` + `gh auth setup-git`

1. Set `GH_PAT` as a Codespace encrypted secret
2. `devcontainer.json` maps it to both `GH_PAT` and
   `GH_TOKEN` via `containerEnv`
3. `make setup_all` runs `gh auth setup-git`, configuring
   `gh` as the git credential helper
4. Both `gh` CLI and `git push` use the PAT automatically

### Fallbacks

**`source` + `export`** — for current session without rebuild:
```bash
source ~/.gh_pat && export GH_TOKEN="$GH_PAT"
```

**PAT-in-URL** — per-repo override:
```bash
git remote set-url origin "https://${GH_PAT}@github.com/org/repo.git"
```

**`gh auth login`** — re-authenticate stored credentials:
```bash
unset GITHUB_TOKEN && gh auth login --with-token <<< "$GH_PAT"
gh auth setup-git
```

Note: `GITHUB_TOKEN` is auto-injected by Codespaces.
`GH_TOKEN` takes precedence in `gh` CLI, which is why
`containerEnv` maps `GH_PAT` to `GH_TOKEN`.
