#!/bin/bash
# cc-status.sh — Unified status dashboard across all managed repos
# Usage: ./cc-status.sh [--verbose]
#
# Shows git branch, status, last commit, and Ralph state for each repo.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/repos.conf"

VERBOSE="${1:-}"

# Header
printf "%-28s %-20s %-7s %-8s %s\n" "REPO" "BRANCH" "STATUS" "RALPH" "LAST COMMIT"
printf "%-28s %-20s %-7s %-8s %s\n" "----" "------" "------" "-----" "-----------"

for repo in "${REPOS[@]}"; do
  if [[ ! -d "$repo/.git" ]]; then
    printf "%-28s %s\n" "$(basename "$repo")" "(not found)"
    continue
  fi

  name=$(basename "$repo")

  # Branch
  branch=$(git -C "$repo" branch --show-current 2>/dev/null || echo "detached")

  # Clean/dirty status
  if git -C "$repo" diff --quiet HEAD 2>/dev/null && [[ -z "$(git -C "$repo" status --porcelain 2>/dev/null)" ]]; then
    status="clean"
  else
    changed=$(git -C "$repo" status --porcelain 2>/dev/null | wc -l | tr -d ' ')
    status="${changed}m"
  fi

  # Ralph state
  ralph_state="-"
  if [[ -f "$repo/ralph/docs/prd.json" ]]; then
    total=$(jq -r '[.stories[]] | length' "$repo/ralph/docs/prd.json" 2>/dev/null || echo "?")
    completed=$(jq -r '[.stories[] | select(.status == "done")] | length' "$repo/ralph/docs/prd.json" 2>/dev/null || echo "?")
    ralph_state="${completed}/${total}"
  fi

  # Last commit
  last_commit=$(git -C "$repo" log -1 --format='%ar: %s' 2>/dev/null | head -c 70)

  printf "%-28s %-20s %-7s %-8s %s\n" "$name" "$branch" "$status" "$ralph_state" "$last_commit"

  # Verbose: show uncommitted files
  if [[ "$VERBOSE" == "--verbose" && "$status" != "clean" ]]; then
    git -C "$repo" status --porcelain 2>/dev/null | head -5 | sed 's/^/    /'
    echo ""
  fi
done

echo ""

# Submodule status for Agents-eval
if [[ -f /workspaces/Agents-eval/.gitmodules ]]; then
  echo "=== Submodule Status ==="
  git -C /workspaces/Agents-eval submodule status 2>/dev/null | sed 's/^/ /'
fi
