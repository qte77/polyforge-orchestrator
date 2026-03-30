#!/bin/bash
# cc-status.sh — Unified status dashboard across all managed repos
# Usage: ./cc-status.sh [--verbose]
#
# Shows git branch, status, last commit, and Ralph state for each repo.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/load-workspace-repos.sh"
source "${SCRIPT_DIR}/colors.sh"

VERBOSE="${1:-}"

# Header
printf "%-28s %-20s %-7s %s\n" "REPO" "BRANCH" "STATUS" "LAST COMMIT"
printf "%-28s %-20s %-7s %s\n" "----" "------" "------" "-----------"

for repo in "${REPOS[@]}"; do
  if [[ ! -d "$repo/.git" ]]; then
    printf "%-28s %s\n" "$(basename "$repo")" "$(warn '(not found)')"
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

  # Last commit
  last_commit=$(git -C "$repo" log -1 --format='%ar: %s' 2>/dev/null | head -c 70)

  printf "%-28s %-20s %-7s %s\n" "$name" "$branch" "$status" "$last_commit"

  # Verbose: show uncommitted files
  if [[ "$VERBOSE" == "--verbose" && "$status" != "clean" ]]; then
    git -C "$repo" status --porcelain 2>/dev/null | head -5 | sed 's/^/    /'
    echo ""
  fi
done

echo ""
