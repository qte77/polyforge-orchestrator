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

## Token format prefixes

Per [GitHub's auth-token reference](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/about-authentication-to-github), each token kind has a distinct prefix:

| Prefix | Meaning |
|---|---|
| `ghp_` | Personal access token (classic) |
| `github_pat_` | Fine-grained personal access token |
| `gho_` | OAuth access token |
| `ghu_` | User access token for a GitHub App |
| `ghs_` | Installation access token for a GitHub App |
| `ghr_` | Refresh token for a GitHub App |

Codespaces auto-injects a `ghu_*` (user access token for the Codespaces GitHub App, scoped to the codespace's repo) as `GITHUB_TOKEN`. This is **not documented explicitly** by GitHub but is empirically observable. The token rotates periodically; per the [security docs](https://docs.github.com/en/codespaces/reference/security-in-github-codespaces): *"Every time a codespace is created or restarted, it's assigned a new GitHub token with an automatic expiry period."*

`GH_PAT` (Codespaces user secret) is `github_pat_*` (fine-grained PAT). The two token kinds are not interchangeable — see the caveat below.

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

### Caveat: `GH_TOKEN=$GH_PAT` mapping may break `gh-gpgsign` (unverified, 2026-05)

The `containerEnv` mapping `"GH_TOKEN": "${localEnv:GH_PAT}"` aliases a `github_pat_*` (user fine-grained PAT) onto `GH_TOKEN`. Empirical observation in the qte77 ecosystem suggests this can break the Codespaces commit-signing helper `/.codespaces/bin/gh-gpgsign`, which appears to require the auto-injected `ghu_*` token specifically.

Symptom: `git commit` fails with `gpg: skipped "GitHub <noreply@github.com>": No secret key`.

Side-by-side reproduction (same codespace, identical config from the diagnostic audit below):

- Shell where `GH_TOKEN` is unset or `ghu_*` (auto-injected) → `gh-gpgsign` works → commit signed with RSA `B5690EEEBB952194` ✓
- Shell where `GH_TOKEN=$GH_PAT` (a `github_pat_*`) → `gh-gpgsign` fails with "No secret key" ✗

**Hypothesis**: `gh-gpgsign` follows gh's standard token precedence (`GH_TOKEN` → `GITHUB_TOKEN`) when authenticating to the Codespaces identity service. The service rejects user PATs (only accepts the `ghu_*` GitHub App token), `gh-gpgsign` falls through to gpg's default keyring, finds nothing, reports the missing local key.

**Confirming probe** (run in the failing shell):

```bash
for v in GH_PAT GH_TOKEN GITHUB_TOKEN; do
  val="${!v}"
  case "$val" in
    "")            echo "$v: <unset>" ;;
    ghu_*)         echo "$v: ghu_ (auto-injected, short-lived)" ;;
    github_pat_*)  echo "$v: github_pat_ (user fine-grained PAT)" ;;
    *)             echo "$v: prefix=${val:0:5}..." ;;
  esac
done
```

If output shows `GH_TOKEN: github_pat_*` while `GITHUB_TOKEN: <unset>` (or also `github_pat_*`), the hypothesis stands. The fix would be: drop the `GH_TOKEN` mapping from `containerEnv` (keep `GH_PAT` available for tools that read it explicitly), letting `GH_TOKEN`/`GITHUB_TOKEN` revert to Codespaces auto-injection. Tools that need PAT scopes can opt-in per-call: `GH_TOKEN=$GH_PAT gh pr merge ...`.

This issue is tracked at [#64](https://github.com/qte77/polyforge-orchestrator/issues/64). **Do not amend the convention** until the probe confirms or refutes.

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

## Diagnostics

When something auth- or signing-related goes sideways, run the audit one-liner first to capture the **real** state of git config across all four scopes (system / global / local / worktree). The labelled output makes dotfiles overrides obvious:

```bash
for k in commit.gpgsign gpg.program gpg.format user.signingkey credential.helper user.name user.email; do
  printf '%-22s %s\n' "$k" "$(git config --show-origin --get "$k" 2>/dev/null || echo '<unset>')"
done
```

Healthy Codespaces output looks like:

```
commit.gpgsign         file:/home/vscode/.gitconfig    true
gpg.program            file:/etc/gitconfig             /.codespaces/bin/gh-gpgsign
gpg.format             file:/home/vscode/.gitconfig    openpgp
user.signingkey        <unset>
credential.helper      file:/etc/gitconfig             /.codespaces/bin/gitcredential_github.sh
user.name              file:/etc/gitconfig             qte77
user.email             file:/etc/gitconfig             ...@users.noreply.github.com
```

What to look for:

- `gpg.program` and `credential.helper` **must** come from `/etc/gitconfig` (system-level, set by Codespaces). If they come from `~/.gitconfig` or `.git/config` instead, your dotfiles are clobbering them — that's [GitHub's documented cause #2](https://docs.github.com/en/codespaces/troubleshooting/troubleshooting-gpg-verification-for-github-codespaces) for `gpg failed to sign`.
- `user.signingkey` should be `<unset>` — `gh-gpgsign` signs via the Codespaces identity, not a local GPG key.
- `commit.gpgsign` can come from any scope; only its value matters.

## Inherited git config defaults (and per-repo overrides)

Codespaces also bakes some non-auth git config defaults into `~/.gitconfig` that you may want to override per-repo.

`commit.template=/home/vscode/.gitmessage` is set globally so every repo gets a default commit-message scaffold. Repos that ship their own `.gitmessage` at the root **don't get it used automatically** until they opt in:

```bash
git config --local commit.template .gitmessage      # use this repo's template
git config --local commit.template ""               # disable template for this repo
```

Setting local to empty string is required to actually disable; plain `--unset` only removes the local key, which causes the global value to resurface.

A `.devcontainer/devcontainer.json` `postCreateCommand` is the natural place for repos that want this automatic on rebuild:

```json
"postCreateCommand": "[ -f .gitmessage ] && git config --local commit.template .gitmessage || true"
```

## Reset / rebuild scope

| Goal | Operation | Effect |
|---|---|---|
| Clear `GH_TOKEN` in current shell only | `unset GH_TOKEN` | One-shell scope; subsequent commands in *this* shell only |
| Pick up newly added Codespaces user secrets | Stop + start codespace | Per [secrets docs](https://docs.github.com/en/codespaces/managing-your-codespaces/managing-secrets-for-your-codespaces) — restart re-injects current secret values |
| Regenerate auto-injected `GITHUB_TOKEN` | Stop + start codespace | Per [security docs](https://docs.github.com/en/codespaces/reference/security-in-github-codespaces): *"a new GitHub token … each time a codespace is created or restarted"* |
| Apply changes to `.devcontainer/devcontainer.json` | **Rebuild container** (`gh codespace rebuild` or *Codespaces: Rebuild Container*) | Stop+start alone is **not** enough; rebuild re-runs `containerEnv`, `onCreateCommand`, `postCreateCommand` |

Stop+start is cheap and rotates the auto-injected token. Rebuild is heavier and required for any devcontainer change.

## Ports and Forwarding

```bash
gh codespace ports
gh codespace ports forward 8080:8080
```

## References

- [Codespaces docs](https://docs.github.com/en/codespaces) — overview
- [Security in Codespaces](https://docs.github.com/en/codespaces/reference/security-in-github-codespaces) — auto-injected token lifecycle
- [Managing GPG verification](https://docs.github.com/en/codespaces/managing-your-codespaces/managing-gpg-verification-for-github-codespaces) — enabling and trusted-repo list
- [Troubleshooting GPG verification](https://docs.github.com/en/codespaces/troubleshooting/troubleshooting-gpg-verification-for-github-codespaces) — three documented `gpg failed to sign` causes
- [Org/repo Codespaces secrets](https://docs.github.com/en/codespaces/managing-codespaces-for-your-organization/managing-development-environment-secrets-for-your-repository-or-organization) — libsodium sealed-box encryption
- [Token format prefixes](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/about-authentication-to-github) — `ghu_` / `ghp_` / `github_pat_` / etc.
- [`gh codespace` CLI](https://cli.github.com/manual/gh_codespace)
