---
title: Agent Learning Documentation
description: Non-obvious patterns that prevent repeated mistakes across sprints
---

## Template

- **Context**: When/where this applies
- **Problem**: What issue this solves
- **Solution**: Implementation approach
- **Example**: Working code
- **References**: Related files

## Learned Patterns

- **Context**: Contributing to an external/untrusted repo from a
  Codespaces-based dev environment that already holds broad,
  multi-repo push credentials (this orchestrator's `GH_PAT`).
- **Problem**: Two things look like scoping mechanisms and neither
  is. (1) "Create the codespace on a repo we own" doesn't limit
  reach — the Codespaces-secret `--repos` allow-list only gates which
  codespaces *receive* `GH_PAT`, not what the PAT can *reach* once
  injected (set separately, at PAT creation). (2) Unsetting
  `GH_TOKEN`/`GITHUB_TOKEN` doesn't reduce privilege either — verified
  2026-09-04 that this codespace's `~/.config/gh/hosts.yml` holds a
  second, equally-broad classic OAuth token (`gho_*`, cross-org
  `repo` scope) used deliberately as a fallback, so unsetting the env
  vars just switches which broad credential `gh`/`git` use next. Worse,
  it's not a container isolation boundary — the credential stays on
  disk regardless, readable by anything else executing in the same
  container.
- **Solution**: Use a separate codespace for external/untrusted work:
  fork the repo, don't add the fork to `GH_PAT`'s secret allow-list,
  don't manually authenticate with any of this repo's credential
  patterns there, and verify with `gh auth status` before touching git
  (expect only the GitHub-auto-injected `ghu_` token, repo-scoped by
  GitHub itself — a real container-level boundary, not a config one).
  Push with that default token; open cross-repo PRs via the browser
  since the default token lacks `pull_requests:write` on upstream.
- **Example**: See `docs/codespaces.md` → "Contributing to
  external/untrusted repos" and the "Escape hatch" caveat above it.
- **References**: `docs/codespaces.md`, `docs/cross-repo-setup.md`.
