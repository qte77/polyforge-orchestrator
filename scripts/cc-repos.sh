#!/bin/bash
# cc-repos.sh — tmux session with one window per managed repo
# Usage: ./cc-repos.sh [session-name]
#
# Creates a tmux session with persistent windows for each repo.
# Switch between repos with Ctrl-b <number> or Ctrl-b w (window list).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/repos.conf"

SESSION="${1:-repos}"

# Kill existing session if present
tmux kill-session -t "$SESSION" 2>/dev/null || true

# Create session with first repo
tmux new-session -d -s "$SESSION" -n "${REPO_NAMES[0]}" -c "${REPOS[0]}"

# Add remaining repos as new windows
for i in "${!REPOS[@]}"; do
  [[ "$i" -eq 0 ]] && continue
  path="${REPOS[$i]}"
  name="${REPO_NAMES[$i]}"
  if [[ -d "$path" ]]; then
    tmux new-window -t "$SESSION" -n "$name" -c "$path"
  else
    echo "Warning: $path not found, skipping $name"
  fi
done

# Select first window
tmux select-window -t "$SESSION:0"

# Attach if not already in tmux
if [[ -z "${TMUX:-}" ]]; then
  tmux attach -t "$SESSION"
else
  echo "tmux session '$SESSION' created with ${#REPOS[@]} windows."
  echo "Switch to it with: tmux switch-client -t $SESSION"
fi
