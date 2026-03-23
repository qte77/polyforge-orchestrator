#!/bin/bash
# cc-repos.sh — tmux session with one window per managed repo
# Usage: ./cc-repos.sh [session-name]
#
# Creates a detached tmux session with windows for each repo.
# The tmux default terminal profile (devcontainer.json) auto-attaches.
# Manual: tmux attach -t repos, or Ctrl-b w for window list.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/repos.conf"

SESSION="${1:-repos}"

# Kill existing session if present
tmux kill-session -t "$SESSION" 2>/dev/null || true

# Create session — use first existing repo directory
created=false
for i in "${!REPOS[@]}"; do
  path="${REPOS[$i]}"
  name="${REPO_NAMES[$i]}"
  if [[ -d "$path" ]]; then
    if [[ "$created" == false ]]; then
      tmux new-session -d -s "$SESSION" -n "$name" -c "$path"
      created=true
    else
      tmux new-window -t "$SESSION" -n "$name" -c "$path"
    fi
  else
    echo "Warning: $path not found, skipping $name"
  fi
done

if [[ "$created" == false ]]; then
  echo "Error: no repo directories found"
  exit 1
fi

tmux select-window -t "$SESSION:0"
echo "tmux session '$SESSION' ready ($(tmux list-windows -t "$SESSION" | wc -l) windows)"
