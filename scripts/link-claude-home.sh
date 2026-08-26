#!/usr/bin/env bash
set -euo pipefail
# Vendored from qte77/claude-code-plugins workspace-setup plugin
# (plugins/workspace-setup/scripts/link-claude-home.sh, 1.5.1) — a copyable
# snippet, not a plugin-managed file. Update by re-copying if the upstream
# script changes.
#
# Symlinks $HOME/.claude to a directory that survives container rebuilds
# (everything outside /workspaces is cleared on rebuild, everything inside it
# persists). Idempotent: seeds the persisted directory from an existing
# ~/.claude on first run, re-links on every later run, and relinks if the
# existing symlink points somewhere other than the configured target.
#
# Override paths with CLAUDE_HOME_DIR / CLAUDE_HOME_PERSIST_DIR if your
# platform's persisted mount isn't /workspaces.

home="${CLAUDE_HOME_DIR:-$HOME/.claude}"
target="${CLAUDE_HOME_PERSIST_DIR:-/workspaces/.claude-files}"

if [ -L "$home" ]; then
  current="$(readlink "$home")"
  if [ "$current" = "$target" ]; then
    echo "[link-claude-home] already linked: $home -> $target"
    exit 0
  fi
  echo "[link-claude-home] relinking: $home was -> $current, now -> $target"
  rm "$home"
  ln -s "$target" "$home"
  exit 0
fi

if [ -e "$target" ]; then
  rm -rf "$home"
else
  mv "$home" "$target" 2>/dev/null || mkdir -p "$target"
fi

ln -s "$target" "$home"
echo "[link-claude-home] linked $home -> $target"
